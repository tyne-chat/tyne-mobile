// Fork: per-conversation state of the alert policy (tyne-chat/tyne#468).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:fluxer_app/core/push/android/conversation/fork_alert_policy.dart';
import 'package:path_provider/path_provider.dart';

/// Stores [ForkPushAlertState] per conversation tag, on disk, because pushes
/// are handled in a background isolate whose memory does not survive.
///
/// [update] runs one read-decide-write at a time. The queue is in memory: a
/// file lock would not help, because Dart's file locks belong to the process
/// and every isolate of the app runs in the same one.
final class ForkPushAlertStore {
  ForkPushAlertStore._();

  static const String _fileName = 'push_alert_state_fork.json';

  /// Entries whose last push is older than this are dropped on the next write.
  static const Duration _keepFor = Duration(days: 1);

  @visibleForTesting
  static Directory? testRoot;

  static Future<void> _queue = Future<void>.value();

  /// Reads the state of [conversationTag], runs [action] with it, and stores
  /// the state [action] returns. Returns [action]'s value.
  static Future<T> update<T>(
    String conversationTag, {
    required int nowMs,
    required Future<(T, ForkPushAlertState)> Function(
      ForkPushAlertState? previous,
    )
    action,
  }) {
    final Completer<T> result = Completer<T>();
    _queue = _queue.then((_) async {
      try {
        final Map<String, ForkPushAlertState> store = await _read();
        final (T value, ForkPushAlertState next) = await action(
          store[conversationTag],
        );
        store[conversationTag] = next;
        store.removeWhere(
          (String _, ForkPushAlertState state) =>
              nowMs - state.lastReceivedAtMs > _keepFor.inMilliseconds,
        );
        await _write(store);
        result.complete(value);
      } on Object catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }

  @visibleForTesting
  static Future<ForkPushAlertState?> read(String conversationTag) async =>
      (await _read())[conversationTag];

  static Future<Map<String, ForkPushAlertState>> _read() async {
    final File file = await _file();
    if (!file.existsSync()) {
      return <String, ForkPushAlertState>{};
    }
    try {
      final Object? decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) {
        return <String, ForkPushAlertState>{};
      }
      final Map<String, ForkPushAlertState> store =
          <String, ForkPushAlertState>{};
      for (final MapEntry<Object?, Object?> entry in decoded.entries) {
        final ForkPushAlertState? state = ForkPushAlertState.fromJson(
          entry.value,
        );
        if (state != null) {
          store[entry.key.toString()] = state;
        }
      }
      return store;
    } on Object {
      return <String, ForkPushAlertState>{};
    }
  }

  static Future<void> _write(Map<String, ForkPushAlertState> store) async {
    final File file = await _file();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode(<String, Object?>{
        for (final MapEntry<String, ForkPushAlertState> entry in store.entries)
          entry.key: entry.value.toJson(),
      }),
    );
  }

  static Future<File> _file() async {
    final Directory dir = testRoot ?? await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }
}
