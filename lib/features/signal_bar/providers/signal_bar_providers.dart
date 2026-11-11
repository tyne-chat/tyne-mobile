import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/signal_bar/data/signal_bar_repository.dart';
import 'package:fluxer_app/features/signal_bar/domain/signal_bar_models.dart';

/// The configured bar. Loaded lazily, refetched when the gateway or a channel
/// snapshot reports a newer version, and after a new gateway session.
class SignalBarConfigNotifier extends Notifier<SignalBarConfig> {
  Future<void>? _request;

  @override
  SignalBarConfig build() => SignalBarConfig.empty;

  Future<void> refresh() {
    return _request ??= _fetch().whenComplete(() => _request = null);
  }

  Future<void> _fetch() async {
    try {
      state = await ref.read(signalBarRepositoryProvider).fetchBar();
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
    if (state.version < 0) {
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

/// Active signal entries for every channel loaded this session.
class ChannelSignalsNotifier extends Notifier<Map<String, List<SignalEntry>>> {
  final Set<String> _disabledChannels = <String>{};

  @override
  Map<String, List<SignalEntry>> build() => const <String, List<SignalEntry>>{};

  void _setChannel(String channelId, List<SignalEntry> entries) {
    state = <String, List<SignalEntry>>{...state, channelId: entries};
  }

  Future<void> loadChannel(String channelId) async {
    try {
      final result = await ref
          .read(signalBarRepositoryProvider)
          .fetchChannel(channelId);
      if (result.enabled) {
        _disabledChannels.remove(channelId);
      } else {
        _disabledChannels.add(channelId);
      }
      _setChannel(channelId, result.entries);
      ref
          .read(signalBarConfigProvider.notifier)
          .ensureVersion(result.barVersion);
    } on Exception catch (err) {
      debugPrint('[SignalBar] Failed to load signals for $channelId: $err');
    }
  }

  /// Drops everything after a new gateway session; mounted bars reload.
  void invalidate() {
    _disabledChannels.clear();
    state = const <String, List<SignalEntry>>{};
    ref.read(mySignalsProvider.notifier).forget();
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
    try {
      await ref
          .read(signalBarRepositoryProvider)
          .activate(channelId, signalId, personaId: personaId);
    } on Exception catch (err) {
      debugPrint('[SignalBar] Failed to give signal: $err');
      unawaited(loadChannel(channelId));
    }
  }

  Future<void> deactivate(
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
          .deactivate(channelId, signalId);
    } on Exception catch (err) {
      debugPrint('[SignalBar] Failed to withdraw signal: $err');
      unawaited(loadChannel(channelId));
    }
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
    if (current == null) {
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

  /// The clock, for tests.
  @visibleForTesting
  DateTime Function() now = DateTime.now;

  @override
  MySignalsState build() {
    _request = null;
    _failedAt = null;
    return const MySignalsState();
  }

  /// Drops the summary after a new gateway session; the next strip or sheet
  /// loads it again.
  void forget() {
    _failedAt = null;
    state = MySignalsState(busy: state.busy);
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
      state = MySignalsState(summary: summary, busy: state.busy);
    } on Exception catch (err) {
      _failedAt = now();
      debugPrint('[SignalBar] Failed to load signals everywhere: $err');
    }
  }

  /// For a mounting strip: loads the summary once, and after a failure not
  /// again for [kMySignalsRetryDelay].
  void ensureLoaded() {
    if (state.summary != null || _request != null) {
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
