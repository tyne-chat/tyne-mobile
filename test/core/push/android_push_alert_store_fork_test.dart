import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/push/android/conversation/fork_alert_policy.dart';
import 'package:fluxer_app/core/push/android/conversation/fork_alert_store.dart';

const int _t0 = 1000000000;
const int _day = 24 * 60 * 60 * 1000;

ForkPushAlertState _state(int receivedAtMs) =>
    ForkPushAlertState(lastReceivedAtMs: receivedAtMs, lastAlertAtMs: null);

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fork_push_alert_store_');
    ForkPushAlertStore.testRoot = tempDir;
  });

  tearDown(() async {
    ForkPushAlertStore.testRoot = null;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('stores the state an update returns', () async {
    final String value = await ForkPushAlertStore.update<String>(
      'channel:1',
      nowMs: _t0,
      action: (ForkPushAlertState? previous) async {
        expect(previous, isNull);
        return ('done', _state(_t0 + 3));
      },
    );
    expect(value, 'done');
    final ForkPushAlertState? stored = await ForkPushAlertStore.read(
      'channel:1',
    );
    expect(stored?.lastReceivedAtMs, _t0 + 3);
  });

  test('runs overlapping updates one after another', () async {
    Future<void> increment() => ForkPushAlertStore.update<void>(
      'channel:1',
      nowMs: _t0,
      action: (ForkPushAlertState? previous) async {
        final int received = previous?.lastReceivedAtMs ?? _t0;
        await Future<void>.delayed(Duration.zero);
        return (null, _state(received + 1));
      },
    );
    await Future.wait(<Future<void>>[increment(), increment(), increment()]);
    final ForkPushAlertState? stored = await ForkPushAlertStore.read(
      'channel:1',
    );
    expect(stored?.lastReceivedAtMs, _t0 + 3);
  });

  test('a failed update does not block the next one', () async {
    await expectLater(
      ForkPushAlertStore.update<void>(
        'channel:1',
        nowMs: _t0,
        action: (ForkPushAlertState? previous) async =>
            throw StateError('failed'),
      ),
      throwsStateError,
    );
    await ForkPushAlertStore.update<void>(
      'channel:1',
      nowMs: _t0,
      action: (ForkPushAlertState? previous) async => (null, _state(_t0)),
    );
    expect(await ForkPushAlertStore.read('channel:1'), isNotNull);
  });

  test('drops conversations without a push for a day', () async {
    await ForkPushAlertStore.update<void>(
      'channel:old',
      nowMs: _t0,
      action: (ForkPushAlertState? previous) async => (null, _state(_t0)),
    );
    await ForkPushAlertStore.update<void>(
      'channel:new',
      nowMs: _t0 + _day + 1,
      action: (ForkPushAlertState? previous) async =>
          (null, _state(_t0 + _day + 1)),
    );
    expect(await ForkPushAlertStore.read('channel:old'), isNull);
    expect(await ForkPushAlertStore.read('channel:new'), isNotNull);
  });
}
