// Fork: prepares a conversation push before upstream stores and shows it
// (tyne-chat/tyne#468). Called from `_showAndroidConversationPush`, after the
// media downloads and just before `appendLine`, so nothing slow sits between
// this decision and the post.

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluxer_app/core/push/android/conversation/fork_alert_policy.dart';
import 'package:fluxer_app/core/push/android/conversation/fork_alert_store.dart';
import 'package:fluxer_app/core/push/android/conversation/history.dart';
import 'package:fluxer_app/core/push/android/conversation/messaging_style.dart';
import 'package:fluxer_app/core/push/notification/fork_alert_every_message.dart';
import 'package:fluxer_app/core/push/notification/ids.dart'
    show pushGroupSummaryNotificationId;
import 'package:fluxer_app/core/push/notification/payload.dart'
    show pushMessageIsCoveredByAck;

/// Payload key the server sets when the message mentions the recipient
/// directly (themselves, one of their personas, a role of theirs, or a reply
/// that pings them). Absent until the server sends it.
const String kForkPushDirectMentionKey = 'fork_direct_mention';

/// Lines a server channel or group DM keeps before upstream appends the new
/// one, so the notification shows the newest three. One-to-one DMs keep
/// upstream's own limit.
const int _kChannelLinesBeforeAppend = 2;

/// Decides whether the push alerts, and trims the stored lines for it.
///
/// Returns the `alert` value upstream should use. On any error it returns
/// [alert] unchanged, which is upstream's behaviour.
Future<bool> forkPreparePushConversation(
  Map<String, String> payload, {
  required String conversationTag,
  required String messageId,
  required String title,
  required bool alert,
}) => forkPreparePushConversationWith(
  payload,
  conversationTag: conversationTag,
  messageId: messageId,
  title: title,
  alert: alert,
  nowMs: DateTime.now().millisecondsSinceEpoch,
  isShowing: _conversationNotificationShowing,
  alertEveryMessage: readForkPushAlertEveryMessage,
);

@visibleForTesting
Future<bool> forkPreparePushConversationWith(
  Map<String, String> payload, {
  required String conversationTag,
  required String messageId,
  required String title,
  required bool alert,
  required int nowMs,
  required Future<bool> Function(String conversationTag) isShowing,
  required Future<bool> Function() alertEveryMessage,
}) async {
  try {
    return await ForkPushAlertStore.update<bool>(
      conversationTag,
      nowMs: nowMs,
      action: (ForkPushAlertState? previous) async {
        final bool showing = await isShowing(conversationTag);
        final bool everyMessage = await alertEveryMessage();
        final PushConversationState? stored =
            await AndroidPushConversationHistoryStore.readState(
              conversationTag,
            );
        final List<PushConversationLine> lines =
            stored?.lines ?? const <PushConversationLine>[];
        final bool oneToOne = !resolvePushGroupConversation(
          payload,
          title: title,
        );
        final ForkPushAlertDecision decision = decideForkPushAlert(
          previous: previous,
          nowMs: nowMs,
          showing: showing,
          alreadyStored: lines.any(
            (PushConversationLine line) => line.messageId == messageId,
          ),
          oneToOneDirectMessage: oneToOne,
          directMention: _isDirectMention(payload),
          alertEveryMessage: everyMessage,
        );
        if (decision.newBurst) {
          if (lines.isNotEmpty) {
            await AndroidPushConversationHistoryStore.trimAck(
              conversationTag: conversationTag,
            );
          }
        } else if (!decision.duplicate && !oneToOne) {
          // A duplicate replaces its own line, so trimming would shrink the
          // notification.
          await _keepNewest(conversationTag, lines);
        }
        return (alert && decision.alert, decision.state);
      },
    );
  } on Object catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('[ForkPushAlert] prepare failed: $error\n$stackTrace');
    }
    return alert;
  }
}

/// Trims the stored lines to the [_kChannelLinesBeforeAppend] newest ids.
///
/// Lines are stored in arrival order but `trimAck` removes by id, so the cut
/// is taken from the ids in numeric order, with upstream's own comparison.
Future<void> _keepNewest(
  String conversationTag,
  List<PushConversationLine> lines,
) async {
  if (lines.length <= _kChannelLinesBeforeAppend) {
    return;
  }
  final List<String> newestFirst =
      lines.map((PushConversationLine line) => line.messageId).toList()..sort(
        (String a, String b) =>
            a == b ? 0 : (pushMessageIsCoveredByAck(a, b) ? 1 : -1),
      );
  await AndroidPushConversationHistoryStore.trimAck(
    conversationTag: conversationTag,
    upToMessageId: newestFirst[_kChannelLinesBeforeAppend],
  );
}

bool _isDirectMention(Map<String, String> payload) {
  final String? value = payload[kForkPushDirectMentionKey];
  return value == 'true' || value == '1';
}

/// Whether the conversation's notification is on screen. Only Android knows:
/// a swipe or an inline reply removes it without telling the app's Dart side.
/// An error counts as not on screen, so a failure errs towards alerting.
Future<bool> _conversationNotificationShowing(String conversationTag) async {
  try {
    final int id = pushGroupSummaryNotificationId(conversationTag);
    final List<ActiveNotification> active =
        await FlutterLocalNotificationsPlugin().getActiveNotifications();
    return active.any(
      (ActiveNotification notification) =>
          notification.id == id && notification.tag == conversationTag,
    );
  } on Object {
    return false;
  }
}
