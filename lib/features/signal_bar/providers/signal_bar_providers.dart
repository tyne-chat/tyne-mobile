import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/signal_bar/data/signal_bar_repository.dart';
import 'package:fluxer_app/features/signal_bar/data/signal_bar_snapshot.dart';
import 'package:fluxer_app/features/signal_bar/domain/signal_bar_models.dart';

/// The device's copy of [userId]'s signal bar, if it has one (tyne-chat/tyne#645).
SignalBarSnapshot? _snapshotOf(Ref ref, String? userId) => userId == null
    ? null
    : ref.read(signalBarSnapshotStoreProvider).read(userId);

/// The configured bar. Starts from the device's copy, loaded lazily, refetched
/// when the gateway or a channel snapshot reports a newer version, and after a
/// new gateway session.
class SignalBarConfigNotifier extends Notifier<SignalBarConfig> {
  Future<void>? _request;

  /// Whether the bar came from the server since the app started; the device's
  /// copy does not count.
  bool _loaded = false;

  @override
  SignalBarConfig build() {
    _request = null;
    _loaded = false;
    ref.listen<String?>(currentUserIdProvider, (String? before, String? now) {
      if (before != now) {
        _loaded = false;
        state = _snapshotOf(ref, now)?.config ?? SignalBarConfig.empty;
      }
    });
    return _snapshotOf(ref, ref.read(currentUserIdProvider))?.config ??
        SignalBarConfig.empty;
  }

  Future<void> refresh() {
    return _request ??= _fetch().whenComplete(() => _request = null);
  }

  Future<void> _fetch() async {
    try {
      state = await ref.read(signalBarRepositoryProvider).fetchBar();
      _loaded = true;
    } on Exception catch (err) {
      debugPrint('[SignalBar] Failed to load the bar: $err');
    }
    // As on the web: with a bar, the account's signals everywhere load with
    // it (after READY too), so the profile menu knows them without a strip.
    if (state.signals.isNotEmpty) {
      ref.read(mySignalsProvider.notifier).ensureLoaded();
    }
  }

  void ensureLoaded() {
    if (!_loaded) {
      unawaited(refresh());
    }
  }

  void ensureVersion(int version) {
    if (version > state.version) {
      unawaited(refresh());
    }
  }
}

final NotifierProvider<SignalBarConfigNotifier, SignalBarConfig>
signalBarConfigProvider =
    NotifierProvider<SignalBarConfigNotifier, SignalBarConfig>(
      SignalBarConfigNotifier.new,
    );

/// How a channel's load ended.
enum SignalChannelLoad {
  /// The answer is current: the channel is confirmed.
  current,

  /// A new gateway session began while the request was on its way: the answer
  /// is shown but not confirmed, and the strip asks again.
  outdated,

  /// The request failed; what was shown stays.
  failed,
}

/// The state a tap on a signal in an unconfirmed channel asked for, and the
/// persona to light it as.
typedef _WantedSignal = ({bool on, String? personaId});

/// What the server holds for one of the account's signals after a write it
/// accepted: lit as the persona, or off.
typedef _ExpectedSignal = ({bool on, String? personaId});

/// Entering a channel asks for it again once this long has passed since its
/// last request, so switching back and forth between chats sends at most one
/// request per chat in this time (tyne-chat/tyne#447). The same as the web's
/// `FRESH_CHANNEL_ANSWER_MS`.
const Duration kSignalChannelRefetchCooldown = Duration(seconds: 10);

/// How long after the server accepted a write the strip may go on without
/// showing it before the channel is asked for again (tyne-chat/tyne#729).
const Duration kSignalWriteEventWait = Duration(seconds: 2);

/// Active signal entries for every channel loaded this session, and the
/// device's copy of the chats loaded last (tyne-chat/tyne#645).
///
/// A channel is *confirmed* once the server has answered for it since the
/// last READY. Until then it shows what the device kept, or what was loaded
/// before READY: nothing is dropped on a new gateway session
/// (tyne-chat/tyne#644), and a tap there is remembered ([want]) instead of
/// being sent against a copy that may be out of date.
class ChannelSignalsNotifier extends Notifier<Map<String, List<SignalEntry>>> {
  final Set<String> _disabledChannels = <String>{};
  final Set<String> _confirmed = <String>{};
  final Set<String> _loading = <String>{};

  /// Loaded channels, the one loaded last at the end.
  final Set<String> _recent = <String>{};
  final Map<String, Map<String, _WantedSignal>> _wanted =
      <String, Map<String, _WantedSignal>>{};

  /// When each channel was last asked for since the last READY
  /// (tyne-chat/tyne#447).
  final Map<String, DateTime> _askedAt = <String, DateTime>{};

  /// The account's writes the server accepted, per channel and signal, that
  /// the strip is to show by the time [_checks] runs (tyne-chat/tyne#729).
  final Map<String, Map<String, _ExpectedSignal>> _expected =
      <String, Map<String, _ExpectedSignal>>{};

  /// One check per channel, [kSignalWriteEventWait] after its last accepted
  /// write.
  final Map<String, Timer> _checks = <String, Timer>{};

  /// Bumped by every READY and account change: an answer to a request sent
  /// before is not current.
  int _session = 0;

  /// Bumped by every account change: an answer to a request sent before
  /// belongs to the previous account and is dropped.
  int _account = 0;

  @override
  Map<String, List<SignalEntry>> build() {
    ref
      ..listen<String?>(currentUserIdProvider, (String? before, String? now) {
        if (before != now) {
          _clear();
          state = _seed(now);
        }
      })
      ..onDispose(_dropChecks);
    _clear();
    return _seed(ref.read(currentUserIdProvider));
  }

  void _clear() {
    _disabledChannels.clear();
    _confirmed.clear();
    _loading.clear();
    _recent.clear();
    _wanted.clear();
    _askedAt.clear();
    _dropChecks();
    _session++;
    _account++;
  }

  void _dropChecks() {
    for (final Timer check in _checks.values) {
      check.cancel();
    }
    _checks.clear();
    _expected.clear();
  }

  Map<String, List<SignalEntry>> _seed(String? userId) {
    final SignalBarSnapshot? snapshot = _snapshotOf(ref, userId);
    if (snapshot == null) {
      return const <String, List<SignalEntry>>{};
    }
    for (final SignalBarSnapshotChat chat in snapshot.chats) {
      if (!chat.enabled) {
        _disabledChannels.add(chat.channelId);
      }
      _recent.add(chat.channelId);
    }
    return <String, List<SignalEntry>>{
      for (final SignalBarSnapshotChat chat in snapshot.chats)
        chat.channelId: chat.entries,
    };
  }

  void _setChannel(String channelId, List<SignalEntry> entries) {
    state = <String, List<SignalEntry>>{...state, channelId: entries};
  }

  /// What the device keeps: the [kSignalBarSnapshotChats] channels loaded
  /// last, the oldest first.
  List<SignalBarSnapshotChat> snapshotChats() {
    final List<String> ids = <String>[
      for (final String id in _recent)
        if (state.containsKey(id)) id,
    ];
    return <SignalBarSnapshotChat>[
      for (final String id in ids.skip(
        ids.length > kSignalBarSnapshotChats
            ? ids.length - kSignalBarSnapshotChats
            : 0,
      ))
        SignalBarSnapshotChat(
          channelId: id,
          enabled: !_disabledChannels.contains(id),
          entries: state[id]!,
        ),
    ];
  }

  Future<SignalChannelLoad> loadChannel(String channelId) async {
    final int session = _session;
    final int account = _account;
    _loading.add(channelId);
    _askedAt[channelId] = clock.now();
    try {
      final result = await ref
          .read(signalBarRepositoryProvider)
          .fetchChannel(channelId);
      if (!ref.mounted || account != _account) {
        return SignalChannelLoad.failed;
      }
      final bool current = session == _session;
      if (!current && _confirmed.contains(channelId)) {
        // A newer answer is already shown.
        return SignalChannelLoad.outdated;
      }
      if (current) {
        _loading.remove(channelId);
      }
      final Map<String, _WantedSignal>? wanted = current
          ? _wanted.remove(channelId)
          : null;
      final String? userId = ref.read(currentUserIdProvider);
      if (result.enabled) {
        _disabledChannels.remove(channelId);
      } else {
        _disabledChannels.add(channelId);
      }
      if (current) {
        _confirmed.add(channelId);
      }
      _recent
        ..remove(channelId)
        ..add(channelId);
      // A turned-off signal stays off on screen while its DELETE goes out.
      _setChannel(
        channelId,
        wanted == null || userId == null
            ? result.entries
            : applySignalUpdate(
                result.entries,
                added: const <SignalEntry>[],
                removed: <({String signalId, String userId})>[
                  for (final MapEntry<String, _WantedSignal> want
                      in wanted.entries)
                    if (!want.value.on) (signalId: want.key, userId: userId),
                ],
              ),
      );
      ref
          .read(signalBarConfigProvider.notifier)
          .ensureVersion(result.barVersion);
      if (wanted != null && userId != null) {
        _sendWanted(channelId, wanted, userId: userId, answer: result.entries);
      }
      return current ? SignalChannelLoad.current : SignalChannelLoad.outdated;
    } on Exception catch (err) {
      debugPrint('[SignalBar] Failed to load signals for $channelId: $err');
      if (ref.mounted && session == _session) {
        _loading.remove(channelId);
        final Map<String, _WantedSignal>? wanted = _wanted.remove(channelId);
        final String? userId = ref.read(currentUserIdProvider);
        if (wanted != null && userId != null) {
          // The routes are idempotent: what was asked for goes out as it is.
          _sendWanted(channelId, wanted, userId: userId);
        }
      }
      return SignalChannelLoad.failed;
    }
  }

  /// Sends what taps in an unconfirmed channel asked for: with the server's
  /// [answer], only what differs from it; without one, all of it.
  void _sendWanted(
    String channelId,
    Map<String, _WantedSignal> wanted, {
    required String userId,
    List<SignalEntry>? answer,
  }) {
    for (final MapEntry<String, _WantedSignal> want in wanted.entries) {
      final bool lit =
          answer?.any(
            (SignalEntry e) => e.signalId == want.key && e.userId == userId,
          ) ??
          !want.value.on;
      if (want.value.on && !lit) {
        unawaited(
          activate(channelId, want.key, personaId: want.value.personaId),
        );
      } else if (!want.value.on && lit) {
        unawaited(deactivate(channelId, want.key, userId: userId));
      }
    }
  }

  /// A tap on [signalId] in a channel that is not confirmed: remembered as
  /// the state wanted, the last tap winning, and sent once the channel's
  /// answer arrives, if that differs. Turning off shows at once; lighting
  /// waits for the event, as always. A channel not being loaded is asked for.
  void want(
    String channelId,
    String signalId, {
    required bool on,
    required String userId,
    String? personaId,
  }) {
    (_wanted[channelId] ??= <String, _WantedSignal>{})[signalId] = (
      on: on,
      personaId: personaId,
    );
    final List<SignalEntry>? current = state[channelId];
    if (!on && current != null) {
      _setChannel(
        channelId,
        applySignalUpdate(
          current,
          added: const <SignalEntry>[],
          removed: <({String signalId, String userId})>[
            (signalId: signalId, userId: userId),
          ],
        ),
      );
    }
    if (!_loading.contains(channelId)) {
      unawaited(loadChannel(channelId));
    }
  }

  /// Whether the server has answered for [channelId] since the last READY.
  bool isConfirmed(String channelId) => _confirmed.contains(channelId);

  /// Whether a request for [channelId] sent since the last READY is on its way.
  bool isLoading(String channelId) => _loading.contains(channelId);

  /// Whether something showing [channelId] should ask for it now: not while a
  /// request for it is on its way or one went out less than
  /// [kSignalChannelRefetchCooldown] ago, whatever its answer; then while it
  /// is not confirmed, or, when [entering] it, also when it is
  /// (tyne-chat/tyne#447): a session can miss its events (tyne-chat/tyne#313),
  /// so a chat is not trusted until the next READY.
  bool shouldLoad(String channelId, {required bool entering}) {
    if (_loading.contains(channelId)) {
      return false;
    }
    final DateTime? askedAt = _askedAt[channelId];
    if (askedAt != null &&
        clock.now().difference(askedAt) < kSignalChannelRefetchCooldown) {
      return false;
    }
    return entering || !_confirmed.contains(channelId);
  }

  /// [isConfirmed] for selectors, which must not read `state`; a change of
  /// what is confirmed always comes with a new state.
  bool isConfirmedIn(
    Map<String, List<SignalEntry>> channels,
    String channelId,
  ) => _confirmed.contains(channelId);

  /// A new gateway session (READY): what is loaded stays on screen, no longer
  /// confirmed, and every mounted strip asks for its channel again
  /// (tyne-chat/tyne#644). The account's signals everywhere do the same.
  void invalidate() {
    _confirmed.clear();
    _loading.clear();
    // Every channel is asked for again anyway: no cooldown, no checks.
    _askedAt.clear();
    _dropChecks();
    _session++;
    state = <String, List<SignalEntry>>{...state};
    ref.read(mySignalsProvider.notifier).markStale();
  }

  void handleChannelUpdate(Map<String, dynamic> data) {
    final String? channelId = data['channel_id'] as String?;
    if (channelId == null) {
      return;
    }
    ref
        .read(signalBarConfigProvider.notifier)
        .ensureVersion((data['bar_version'] as num?)?.toInt() ?? 0);
    final List<SignalEntry> added = <SignalEntry>[
      for (final Object? item in data['added'] as List<dynamic>? ?? const [])
        SignalEntry.fromJson(item! as Map<String, dynamic>),
    ];
    final List<({String signalId, String userId})> removed =
        <({String signalId, String userId})>[
          for (final Object? item
              in data['removed'] as List<dynamic>? ?? const [])
            (
              signalId: (item! as Map<String, dynamic>)['signal_id'] as String,
              userId: (item as Map<String, dynamic>)['user_id'] as String,
            ),
        ];
    // The account's own signals everywhere follow every channel's events,
    // loaded here or not.
    ref
        .read(mySignalsProvider.notifier)
        .applyChannelUpdate(channelId, added: added, removed: removed);
    final List<SignalEntry>? current = state[channelId];
    if (current == null) {
      return;
    }
    _setChannel(
      channelId,
      applySignalUpdate(current, added: added, removed: removed),
    );
  }

  Future<void> activate(
    String channelId,
    String signalId, {
    String? personaId,
  }) async {
    final int account = _account;
    _expected[channelId]?.remove(signalId);
    try {
      await ref
          .read(signalBarRepositoryProvider)
          .activate(channelId, signalId, personaId: personaId);
    } on Exception catch (err) {
      debugPrint('[SignalBar] Failed to give signal: $err');
      unawaited(loadChannel(channelId));
      return;
    }
    // Lighting still waits for the event, which is then checked for.
    _expect(account, channelId, signalId, on: true, personaId: personaId);
  }

  Future<void> deactivate(
    String channelId,
    String signalId, {
    required String userId,
  }) async {
    final int account = _account;
    _expected[channelId]?.remove(signalId);
    final List<SignalEntry>? current = state[channelId];
    if (current != null) {
      _setChannel(
        channelId,
        applySignalUpdate(
          current,
          added: const <SignalEntry>[],
          removed: <({String signalId, String userId})>[
            (signalId: signalId, userId: userId),
          ],
        ),
      );
    }
    try {
      await ref
          .read(signalBarRepositoryProvider)
          .deactivate(channelId, signalId);
    } on Exception catch (err) {
      debugPrint('[SignalBar] Failed to withdraw signal: $err');
      unawaited(loadChannel(channelId));
      return;
    }
    // An answer to a request sent before the DELETE can bring it back.
    _expect(account, channelId, signalId, on: false);
  }

  /// Remembers what the server now holds for the account's [signalId] in
  /// [channelId], and checks [kSignalWriteEventWait] after the channel's last
  /// accepted write that the strip shows it.
  ///
  /// Lighting shows only with its `CHANNEL_SIGNAL_UPDATE`. A session can miss
  /// that event (tyne-chat/tyne#313), and the server sends none for a signal
  /// already lit as that persona, so once the strip had missed one, every
  /// further tap was accepted and nothing ever showed it until a restart
  /// (tyne-chat/tyne#729).
  void _expect(
    int account,
    String channelId,
    String signalId, {
    required bool on,
    String? personaId,
  }) {
    if (!ref.mounted || account != _account) {
      return;
    }
    (_expected[channelId] ??= <String, _ExpectedSignal>{})[signalId] = (
      on: on,
      personaId: personaId,
    );
    _checks[channelId]?.cancel();
    _checks[channelId] = Timer(kSignalWriteEventWait, () => _check(channelId));
  }

  /// Asks for [channelId] once when the strip does not show what the
  /// account's accepted writes there left on the server; a request on its way
  /// will show it instead. A channel not loaded shows nothing to correct.
  void _check(String channelId) {
    _checks.remove(channelId);
    final Map<String, _ExpectedSignal>? expected = _expected.remove(channelId);
    if (!ref.mounted || expected == null || _loading.contains(channelId)) {
      return;
    }
    final String? userId = ref.read(currentUserIdProvider);
    final List<SignalEntry>? shown = state[channelId];
    if (userId == null || shown == null) {
      return;
    }
    final bool differs = expected.entries.any((
      MapEntry<String, _ExpectedSignal> want,
    ) {
      final SignalEntry? mine = shown
          .where(
            (SignalEntry e) => e.signalId == want.key && e.userId == userId,
          )
          .firstOrNull;
      return want.value.on
          ? mine == null || mine.personaId != want.value.personaId
          : mine != null;
    });
    if (differs) {
      debugPrint('[SignalBar] No event for a write in $channelId; reloading');
      unawaited(loadChannel(channelId));
    }
  }

  /// Switches the bar on or off in a DM or group DM (tyne-chat/tyne#743).
  /// The server's answer is the switch's new state, so it shows at once, as
  /// its `CHANNEL_SIGNAL_BAR_UPDATE` would: the server sends none when the
  /// switch was already so, and a session can miss one. Switching on a chat
  /// not loaded asks for it, since it may already have signals lit. A failure
  /// asks for the chat once. Returns whether the server accepted it.
  Future<bool> setDmEnabled(String channelId, {required bool enabled}) async {
    final int account = _account;
    try {
      await ref
          .read(signalBarRepositoryProvider)
          .setDmEnabled(channelId, enabled: enabled);
    } on Exception catch (err) {
      debugPrint('[SignalBar] Failed to switch the bar in $channelId: $err');
      if (ref.mounted && account == _account) {
        unawaited(loadChannel(channelId));
      }
      return false;
    }
    if (!ref.mounted || account != _account) {
      return true;
    }
    if (enabled && !state.containsKey(channelId)) {
      unawaited(loadChannel(channelId));
    } else {
      handleEnabledUpdate(<String, dynamic>{
        'channel_id': channelId,
        'enabled': enabled,
      });
    }
    return true;
  }

  /// Turns off the account's [signalIds] in [channelId] at once, locally if the
  /// channel is loaded, with one DELETE each. Returns whether every one went
  /// through; a failure reloads a loaded channel once.
  Future<bool> withdrawOwn(
    String channelId,
    List<String> signalIds, {
    required String userId,
  }) async {
    final List<SignalEntry>? current = state[channelId];
    if (current != null) {
      _setChannel(
        channelId,
        applySignalUpdate(
          current,
          added: const <SignalEntry>[],
          removed: <({String signalId, String userId})>[
            for (final String signalId in signalIds)
              (signalId: signalId, userId: userId),
          ],
        ),
      );
    }
    final List<bool> results = await Future.wait(<Future<bool>>[
      for (final String signalId in signalIds)
        ref
            .read(signalBarRepositoryProvider)
            .deactivate(channelId, signalId)
            .then(
              (_) => true,
              onError: (Object err) {
                debugPrint('[SignalBar] Failed to withdraw signal: $err');
                return false;
              },
            ),
    ]);
    final bool ok = results.every((bool done) => done);
    if (!ok && state.containsKey(channelId)) {
      unawaited(loadChannel(channelId));
    }
    return ok;
  }

  /// Whether the bar is switched on in a loaded channel. Channels that are
  /// not loaded yet count as off.
  bool isEnabled(String channelId) => isEnabledIn(state, channelId);

  /// [isEnabled] against a given snapshot of the state. Selectors must use
  /// this one: reading `state` inside a selector trips a Riverpod assertion.
  bool isEnabledIn(Map<String, List<SignalEntry>> channels, String channelId) =>
      channels.containsKey(channelId) && !_disabledChannels.contains(channelId);

  /// CHANNEL_SIGNAL_BAR_UPDATE: a manager switched the bar on or off.
  void handleEnabledUpdate(Map<String, dynamic> data) {
    final String? channelId = data['channel_id'] as String?;
    if (channelId == null) {
      return;
    }
    final bool enabled = data['enabled'] as bool? ?? false;
    if (!state.containsKey(channelId)) {
      // Switched on or off just now, with nothing lit: current as it is.
      _confirmed.add(channelId);
      _recent.add(channelId);
    }
    if (enabled) {
      _disabledChannels.remove(channelId);
      _setChannel(channelId, state[channelId] ?? const <SignalEntry>[]);
    } else {
      _disabledChannels.add(channelId);
      _setChannel(channelId, const <SignalEntry>[]);
      // Switching off clears the channel's signals with no
      // CHANNEL_SIGNAL_UPDATE, so the summary drops the chat here.
      ref.read(mySignalsProvider.notifier).dropChat(channelId);
    }
  }

  /// A manager turns one account's signal off.
  Future<void> removeUser(
    String channelId,
    String signalId, {
    required String userId,
  }) async {
    final List<SignalEntry>? current = state[channelId];
    if (current != null) {
      _setChannel(
        channelId,
        applySignalUpdate(
          current,
          added: const <SignalEntry>[],
          removed: <({String signalId, String userId})>[
            (signalId: signalId, userId: userId),
          ],
        ),
      );
    }
    try {
      await ref
          .read(signalBarRepositoryProvider)
          .removeUser(channelId, signalId, userId);
    } on Exception catch (err) {
      debugPrint('[SignalBar] Failed to turn off a signal: $err');
      unawaited(loadChannel(channelId));
    }
  }

  Future<void> reset(String channelId, String signalId) async {
    try {
      await ref.read(signalBarRepositoryProvider).reset(channelId, signalId);
    } on Exception catch (err) {
      debugPrint('[SignalBar] Failed to reset signal: $err');
      unawaited(loadChannel(channelId));
    }
  }

  /// Shows the account's lit signals in [channelId] as [persona], or as the
  /// account itself when it is null, and updates the badge locally straight
  /// away.
  ///
  /// Call it only for something the person did in that channel: typing there,
  /// picking a persona in its composer, sending a message. Everyone in the
  /// channel sees a signal, so it must not change because the active persona
  /// changed in another channel or on another device, or because the channel
  /// was opened.
  void affirmPersona(
    String channelId, {
    required String userId,
    required SignalPersona? persona,
  }) {
    final List<SignalEntry>? current = state[channelId];
    // A copy that may be out of date is not re-pointed: the next change of
    // text after the channel's answer does it.
    if (current == null || !_confirmed.contains(channelId)) {
      return;
    }
    final List<SignalEntry> stale = <SignalEntry>[
      for (final SignalEntry entry in current)
        if (entry.userId == userId && entry.personaId != persona?.id) entry,
    ];
    if (stale.isEmpty) {
      return;
    }
    _setChannel(channelId, <SignalEntry>[
      for (final SignalEntry entry in current)
        if (stale.contains(entry))
          entry.withPersona(
            personaId: persona?.id,
            personaName: persona?.name,
            personaAvatar: persona?.avatar,
          )
        else
          entry,
    ]);
    for (final SignalEntry entry in stale) {
      unawaited(activate(channelId, entry.signalId, personaId: persona?.id));
    }
  }
}

final NotifierProvider<ChannelSignalsNotifier, Map<String, List<SignalEntry>>>
channelSignalsProvider =
    NotifierProvider<ChannelSignalsNotifier, Map<String, List<SignalEntry>>>(
      ChannelSignalsNotifier.new,
    );

/// The account's own signals in every chat (`GET /users/@me/signals`), kept up
/// to date by the channel events that name the account. Null until loaded.
@immutable
class MySignalsState {
  const MySignalsState({this.summary, this.busy = false});

  final UserSignalsSummary? summary;

  /// A change everywhere is on its way; the sheet's buttons wait for it.
  final bool busy;
}

/// After a failed load, mounted strips wait this long before asking again.
const Duration kMySignalsRetryDelay = Duration(minutes: 1);

class MySignalsNotifier extends Notifier<MySignalsState> {
  Future<void>? _request;
  DateTime? _failedAt;

  /// Whether the summary shown is the device's copy or one from before the
  /// last READY, to be loaded again (tyne-chat/tyne#644, #645).
  bool _stale = false;

  /// The clock, for tests.
  @visibleForTesting
  DateTime Function() now = DateTime.now;

  @override
  MySignalsState build() {
    ref.listen<String?>(currentUserIdProvider, (String? before, String? now) {
      if (before != now) {
        _request = null;
        _failedAt = null;
        state = _seed(now);
      }
    });
    _request = null;
    _failedAt = null;
    return _seed(ref.read(currentUserIdProvider));
  }

  MySignalsState _seed(String? userId) {
    final UserSignalsSummary? summary = _snapshotOf(ref, userId)?.summary;
    _stale = summary != null;
    return MySignalsState(summary: summary);
  }

  /// After a new gateway session the summary stays on screen, and the next
  /// strip, sheet or bar load asks for it again.
  void markStale() {
    _failedAt = null;
    _stale = true;
  }

  /// Loads the summary, sharing a request in flight. A failure is logged.
  Future<void> refresh() {
    return _request ??= _fetch().whenComplete(() => _request = null);
  }

  Future<void> _fetch() async {
    try {
      final UserSignalsSummary summary = await ref
          .read(signalBarRepositoryProvider)
          .fetchMySignals();
      _failedAt = null;
      _stale = false;
      state = MySignalsState(summary: summary, busy: state.busy);
    } on Exception catch (err) {
      _failedAt = now();
      debugPrint('[SignalBar] Failed to load signals everywhere: $err');
    }
  }

  /// For a mounting strip: loads the summary once, and after a failure not
  /// again for [kMySignalsRetryDelay].
  void ensureLoaded() {
    if ((state.summary != null && !_stale) || _request != null) {
      return;
    }
    final DateTime? failedAt = _failedAt;
    if (failedAt != null && now().difference(failedAt) < kMySignalsRetryDelay) {
      return;
    }
    unawaited(refresh());
  }

  /// Forgets the account's signals in one chat, which the server has cleared.
  void dropChat(String channelId) {
    final UserSignalsSummary? summary = state.summary;
    if (summary == null ||
        !summary.chats.any((UserSignalChat c) => c.channelId == channelId)) {
      return;
    }
    state = MySignalsState(
      summary: UserSignalsSummary(
        chats: <UserSignalChat>[
          for (final UserSignalChat c in summary.chats)
            if (c.channelId != channelId) c,
        ],
        restoreAvailable: summary.restoreAvailable,
      ),
      busy: state.busy,
    );
  }

  void applyChannelUpdate(
    String channelId, {
    required List<SignalEntry> added,
    required List<({String signalId, String userId})> removed,
  }) {
    final UserSignalsSummary? summary = state.summary;
    final String? userId = ref.read(currentUserIdProvider);
    if (summary == null || userId == null) {
      return;
    }
    final UserSignalsSummary next = summary.withChannelUpdate(
      channelId,
      userId: userId,
      added: added,
      removed: removed,
    );
    if (!identical(next, summary)) {
      state = MySignalsState(summary: next, busy: state.busy);
    }
  }

  /// Sets [signalId] in every chat where the account has a signal on, and in
  /// [channelId] as [personaId]; with [signalId] null, turns every signal of
  /// the account's off. One request; the chats follow through their events.
  Future<void> setEverywhere(
    String? signalId, {
    String? channelId,
    String? personaId,
  }) {
    return _send(
      () => ref
          .read(signalBarRepositoryProvider)
          .setEverywhere(
            signalId: signalId,
            channelId: signalId == null ? null : channelId,
            personaId: signalId == null || channelId == null ? null : personaId,
          ),
    );
  }

  Future<void> restore() {
    return _send(() => ref.read(signalBarRepositoryProvider).restore());
  }

  /// Turns off the account's signals in one chat, from the sheet: the chat
  /// leaves the summary at once, one DELETE goes out per signal, and a failure
  /// reloads the summary once.
  Future<void> turnOffChat(String channelId) async {
    final UserSignalsSummary? summary = state.summary;
    final String? userId = ref.read(currentUserIdProvider);
    final UserSignalChat? chat = summary?.chats
        .where((UserSignalChat c) => c.channelId == channelId)
        .firstOrNull;
    if (summary == null || userId == null || chat == null) {
      return;
    }
    state = MySignalsState(
      summary: UserSignalsSummary(
        chats: <UserSignalChat>[
          for (final UserSignalChat c in summary.chats)
            if (c.channelId != channelId) c,
        ],
        restoreAvailable: summary.restoreAvailable,
      ),
      busy: state.busy,
    );
    final bool ok = await ref.read(channelSignalsProvider.notifier).withdrawOwn(
      channelId,
      <String>[for (final UserSignalRef ref in chat.signals) ref.signalId],
      userId: userId,
    );
    if (!ok) {
      unawaited(refresh());
    }
  }

  /// What Restore would change; null when it could not be loaded.
  Future<UserSignalsRestorePreview?> fetchRestorePreview() async {
    try {
      return await ref.read(signalBarRepositoryProvider).fetchRestorePreview();
    } on Exception catch (err) {
      debugPrint('[SignalBar] Failed to load the restore preview: $err');
      return null;
    }
  }

  Future<void> _send(Future<UserSignalsSummary> Function() send) async {
    if (state.busy) {
      return;
    }
    state = MySignalsState(summary: state.summary, busy: true);
    try {
      final UserSignalsSummary summary = await send();
      _stale = false;
      state = MySignalsState(summary: summary);
      return;
    } on Exception catch (err) {
      debugPrint('[SignalBar] Failed to change signals everywhere: $err');
    }
    state = MySignalsState(summary: state.summary);
    // Once, to show what did happen; the change itself is not sent again.
    unawaited(refresh());
  }
}

final NotifierProvider<MySignalsNotifier, MySignalsState> mySignalsProvider =
    NotifierProvider<MySignalsNotifier, MySignalsState>(MySignalsNotifier.new);

/// Routes the two signal bar gateway events to their notifiers.
void handleSignalBarGatewayEvent(
  Ref ref,
  String eventType,
  Map<String, dynamic> data,
) {
  if (eventType == 'CHANNEL_SIGNAL_UPDATE') {
    ref.read(channelSignalsProvider.notifier).handleChannelUpdate(data);
  } else if (eventType == 'CHANNEL_SIGNAL_BAR_UPDATE') {
    ref.read(channelSignalsProvider.notifier).handleEnabledUpdate(data);
  } else if (eventType == 'SIGNAL_BAR_UPDATE') {
    ref
        .read(signalBarConfigProvider.notifier)
        .ensureVersion((data['version'] as num?)?.toInt() ?? 0);
  }
}
