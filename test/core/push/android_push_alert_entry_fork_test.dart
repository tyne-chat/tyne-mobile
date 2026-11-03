import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/push/android/conversation/fork_alert_entry.dart';
import 'package:fluxer_app/core/push/android/conversation/fork_alert_store.dart';
import 'package:fluxer_app/core/push/android/conversation/history.dart';

const String _channelTag = 'channel:1';
const String _dmTag = 'channel:2';
const Map<String, String> _channelPayload = <String, String>{
  'channel_id': '1',
  'guild_id': '99',
};
const Map<String, String> _dmPayload = <String, String>{
  'channel_id': '2',
  'guild_id': '@me',
};
const int _t0 = 1000000000;
const int _minute = 60 * 1000;

/// One push as upstream handles it: the fork's preparation, then `appendLine`
/// with the same payload map.
Future<({bool alert, PushConversationState state})> _push(
  String messageId, {
  required bool showing,
  String tag = _channelTag,
  Map<String, String> payload = _channelPayload,
  String title = 'Alice (#general, Server)',
  int nowMs = _t0,
  bool everyMessage = false,
}) async {
  final Map<String, String> map = Map<String, String>.from(payload);
  final bool alert = await forkPreparePushConversationWith(
    map,
    conversationTag: tag,
    messageId: messageId,
    title: title,
    alert: true,
    nowMs: nowMs,
    isShowing: (String _) async => showing,
    alertEveryMessage: () async => everyMessage,
  );
  final PushConversationState state =
      await AndroidPushConversationHistoryStore.appendLine(
        conversationTag: tag,
        line: PushConversationLine(
          messageId: messageId,
          senderName: 'Alice',
          senderKey: 'alice',
          body: 'message $messageId',
          timestampMs: nowMs,
        ),
        payload: map,
      );
  return (alert: alert, state: state);
}

List<String> _ids(PushConversationState state) => state.lines
    .map((PushConversationLine line) => line.messageId)
    .toList(growable: false);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fork_push_alert_');
    AndroidPushConversationHistoryStore.testRoot = tempDir;
    ForkPushAlertStore.testRoot = tempDir;
    await AndroidPushConversationHistoryStore.clearAll();
  });

  tearDown(() async {
    AndroidPushConversationHistoryStore.testRoot = null;
    ForkPushAlertStore.testRoot = null;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('a channel burst alerts once and shows the newest three', () async {
    final List<bool> alerts = <bool>[];
    late PushConversationState state;
    for (int id = 1; id <= 5; id++) {
      final ({bool alert, PushConversationState state}) result = await _push(
        '$id',
        showing: id > 1,
        nowMs: _t0 + id * _minute,
      );
      alerts.add(result.alert);
      state = result.state;
    }
    expect(alerts, <bool>[true, false, false, false, false]);
    expect(_ids(state), <String>['3', '4', '5']);
  });

  test(
    'a dismissed notification starts a burst without the old lines',
    () async {
      for (int id = 1; id <= 3; id++) {
        await _push('$id', showing: id > 1, nowMs: _t0 + id * _minute);
      }
      final ({bool alert, PushConversationState state}) result = await _push(
        '4',
        showing: false,
        nowMs: _t0 + 30 * _minute,
      );
      expect(result.alert, isTrue);
      expect(_ids(result.state), <String>['4']);
    },
  );

  test("a one-to-one DM keeps upstream's ten lines", () async {
    late PushConversationState state;
    for (int id = 1; id <= 12; id++) {
      final ({bool alert, PushConversationState state}) result = await _push(
        '$id',
        tag: _dmTag,
        payload: _dmPayload,
        title: 'Alice',
        showing: id > 1,
        nowMs: _t0 + id * _minute,
      );
      state = result.state;
    }
    expect(state.lines, hasLength(kPushConversationHistoryMaxLines));
    expect(state.lines.first.messageId, '3');
  });

  test('a group DM is trimmed like a channel', () async {
    late PushConversationState state;
    for (int id = 1; id <= 4; id++) {
      final ({bool alert, PushConversationState state}) result = await _push(
        '$id',
        tag: _dmTag,
        payload: _dmPayload,
        title: 'Alice (Group DM)',
        showing: id > 1,
        nowMs: _t0 + id * _minute,
      );
      state = result.state;
    }
    expect(_ids(state), <String>['2', '3', '4']);
  });

  test('a message delivered twice keeps three lines', () async {
    for (int id = 1; id <= 5; id++) {
      await _push('$id', showing: id > 1, nowMs: _t0 + id * _minute);
    }
    final ({bool alert, PushConversationState state}) result = await _push(
      '5',
      showing: true,
      nowMs: _t0 + 6 * _minute,
    );
    expect(result.alert, isFalse);
    expect(_ids(result.state), <String>['3', '4', '5']);
  });

  test('lines stored out of order keep the two newest ids', () async {
    await _push('1', showing: false, nowMs: _t0 + _minute);
    await _push('3', showing: true, nowMs: _t0 + 2 * _minute);
    await _push('2', showing: true, nowMs: _t0 + 3 * _minute);
    final ({bool alert, PushConversationState state}) result = await _push(
      '4',
      showing: true,
      nowMs: _t0 + 4 * _minute,
    );
    expect(_ids(result.state), <String>['3', '2', '4']);
  });

  test('alert for every message alerts but still trims', () async {
    final List<bool> alerts = <bool>[];
    late PushConversationState state;
    for (int id = 1; id <= 4; id++) {
      final ({bool alert, PushConversationState state}) result = await _push(
        '$id',
        showing: id > 1,
        nowMs: _t0 + id * _minute,
        everyMessage: true,
      );
      alerts.add(result.alert);
      state = result.state;
    }
    expect(alerts, everyElement(isTrue));
    expect(_ids(state), <String>['2', '3', '4']);
  });

  test('a direct mention from the server alerts while on screen', () async {
    await _push('1', showing: false);
    final ({bool alert, PushConversationState state}) result = await _push(
      '2',
      payload: <String, String>{
        ..._channelPayload,
        kForkPushDirectMentionKey: 'true',
      },
      showing: true,
      nowMs: _t0 + 2 * _minute,
    );
    expect(result.alert, isTrue);
  });

  test("an error leaves upstream's alert unchanged", () async {
    final bool alert = await forkPreparePushConversationWith(
      Map<String, String>.from(_channelPayload),
      conversationTag: _channelTag,
      messageId: '1',
      title: 'Alice (#general, Server)',
      alert: true,
      nowMs: _t0,
      isShowing: (String _) async => throw StateError('no notifications'),
      alertEveryMessage: () async => false,
    );
    expect(alert, isTrue);
  });
}
