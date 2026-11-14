import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/features/signal_bar/domain/signal_bar_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The device's copy of the signal bar (tyne-chat/tyne#645): the bar, the
// chats loaded last and the account's signals everywhere, per account and not
// synced, so that a strip has something to show from its first frame after a
// restart. The providers show it as unconfirmed until the server answers.

const String _kSnapshotKey = 'signal_bar_snapshot_v1';

/// How many chats the copy keeps: the ones loaded last.
const int kSignalBarSnapshotChats = 50;

/// How long after a change the copy is written.
const Duration kSignalBarSnapshotWriteDelay = Duration(seconds: 1);

/// One chat in the copy.
@immutable
class SignalBarSnapshotChat {
  const SignalBarSnapshotChat({
    required this.channelId,
    required this.enabled,
    required this.entries,
  });

  factory SignalBarSnapshotChat.fromJson(Map<String, dynamic> json) {
    return SignalBarSnapshotChat(
      channelId: json['channel_id'] as String,
      enabled: json['enabled'] as bool? ?? false,
      entries: <SignalEntry>[
        for (final Object? item
            in json['entries'] as List<dynamic>? ?? const [])
          SignalEntry.fromJson(item! as Map<String, dynamic>),
      ],
    );
  }

  final String channelId;
  final bool enabled;
  final List<SignalEntry> entries;

  Map<String, Object?> toJson() => <String, Object?>{
    'channel_id': channelId,
    'enabled': enabled,
    'entries': <Map<String, Object?>>[
      for (final SignalEntry entry in entries) entry.toJson(),
    ],
  };
}

/// What the device keeps of one account's signal bar.
@immutable
class SignalBarSnapshot {
  const SignalBarSnapshot({
    required this.config,
    required this.chats,
    this.summary,
  });

  /// Reads a stored copy; null when there is none or it cannot be read.
  static SignalBarSnapshot? decode(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
      final Map<String, dynamic>? summary =
          json['summary'] as Map<String, dynamic>?;
      return SignalBarSnapshot(
        config: SignalBarConfig.fromJson(
          json['config'] as Map<String, dynamic>,
        ),
        chats: <SignalBarSnapshotChat>[
          for (final Object? item
              in json['chats'] as List<dynamic>? ?? const [])
            SignalBarSnapshotChat.fromJson(item! as Map<String, dynamic>),
        ],
        summary: summary == null ? null : UserSignalsSummary.fromJson(summary),
      );
    } on Object catch (err) {
      debugPrint('[SignalBar] Ignoring an unreadable device copy: $err');
      return null;
    }
  }

  final SignalBarConfig config;

  /// The chats loaded last, the oldest first.
  final List<SignalBarSnapshotChat> chats;
  final UserSignalsSummary? summary;

  String encode() => jsonEncode(<String, Object?>{
    'config': config.toJson(),
    'chats': <Map<String, Object?>>[
      for (final SignalBarSnapshotChat chat in chats) chat.toJson(),
    ],
    'summary': summary?.toJson(),
  });
}

SharedPreferences? _preloaded;

/// Fork: loads the stored preferences at start-up, so the providers can read
/// the device's copy as they are built, before a strip's first frame.
Future<void> preloadSignalBarSnapshots() async {
  try {
    _preloaded = await SharedPreferences.getInstance();
  } on Object catch (err) {
    debugPrint('[SignalBar] Could not load the device copy: $err');
  }
}

/// Reads and writes the device's copy, one per account.
class SignalBarSnapshotStore {
  SignalBarSnapshotStore({
    this._preferences,
    this.writeDelay = kSignalBarSnapshotWriteDelay,
  });

  SharedPreferences? _preferences;
  final Duration writeDelay;
  final Map<String, Timer> _pending = <String, Timer>{};
  final Map<String, SignalBarSnapshot> _latest = <String, SignalBarSnapshot>{};

  static String _key(String userId) => '${_kSnapshotKey}_$userId';

  /// The account's copy, if the preferences are loaded and it has one.
  SignalBarSnapshot? read(String userId) =>
      SignalBarSnapshot.decode(_preferences?.getString(_key(userId)));

  /// Writes [snapshot] as [userId]'s copy after [writeDelay]: one write for
  /// any number of changes meanwhile, the last one winning.
  void schedule(String userId, SignalBarSnapshot snapshot) {
    _latest[userId] = snapshot;
    _pending[userId] ??= Timer(writeDelay, () => unawaited(_write(userId)));
  }

  Future<void> _write(String userId) async {
    _pending.remove(userId);
    final SignalBarSnapshot? snapshot = _latest.remove(userId);
    if (snapshot == null) {
      return;
    }
    try {
      final SharedPreferences preferences = _preferences ??=
          await SharedPreferences.getInstance();
      await preferences.setString(_key(userId), snapshot.encode());
    } on Object catch (err) {
      debugPrint('[SignalBar] Could not keep the device copy: $err');
    }
  }

  /// Drops the account's copy and any write still waiting for it (sign-out).
  Future<void> forget(String userId) async {
    _pending.remove(userId)?.cancel();
    _latest.remove(userId);
    try {
      final SharedPreferences preferences = _preferences ??=
          await SharedPreferences.getInstance();
      await preferences.remove(_key(userId));
    } on Object catch (err) {
      debugPrint('[SignalBar] Could not drop the device copy: $err');
    }
  }

  void dispose() {
    for (final Timer timer in _pending.values) {
      timer.cancel();
    }
    _pending.clear();
    _latest.clear();
  }
}

/// The store, reading the preferences [preloadSignalBarSnapshots] loaded.
final Provider<SignalBarSnapshotStore> signalBarSnapshotStoreProvider =
    Provider<SignalBarSnapshotStore>((Ref ref) {
      final SignalBarSnapshotStore store = SignalBarSnapshotStore(
        preferences: _preloaded,
      );
      ref.onDispose(store.dispose);
      return store;
    });
