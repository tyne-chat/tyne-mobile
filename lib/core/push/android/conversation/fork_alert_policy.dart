// Fork: when an Android conversation notification alerts (tyne-chat/tyne#468).
//
// A conversation alerts once per burst: when its notification is not on screen.
// While it is on screen, new messages update it silently, with two exceptions:
// a direct mention, unless the conversation alerted in the last minute, and, in a
// one-to-one DM, a message after 30 minutes of quiet. The "alert for every
// message" setting turns the policy off.

import 'package:flutter/foundation.dart';

/// How long after an alert a conversation counts as on screen although Android
/// does not list its notification yet: the notification is posted a moment
/// after the decision.
const Duration kForkPushAlertPostGrace = Duration(seconds: 3);

/// A direct mention alerts only when its conversation has not alerted for this
/// long, so a mention right behind the alert that started a burst stays quiet.
const Duration kForkPushMentionAlertGap = Duration(minutes: 1);

/// In a one-to-one DM, a message after this much quiet alerts again although
/// the notification is still on screen.
const Duration kForkPushDirectMessagePause = Duration(minutes: 30);

/// What the policy remembers about one conversation between pushes.
@immutable
class ForkPushAlertState {
  const ForkPushAlertState({
    required this.lastReceivedAtMs,
    required this.lastAlertAtMs,
  });

  /// Device time of the last push received for the conversation.
  final int lastReceivedAtMs;

  /// Device time of the conversation's last alert, if any.
  final int? lastAlertAtMs;

  Map<String, Object?> toJson() => <String, Object?>{
    'lastReceivedAtMs': lastReceivedAtMs,
    if (lastAlertAtMs != null) 'lastAlertAtMs': lastAlertAtMs,
  };

  static ForkPushAlertState? fromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final Object? received = raw['lastReceivedAtMs'];
    final Object? alerted = raw['lastAlertAtMs'];
    if (received is! int) {
      return null;
    }
    return ForkPushAlertState(
      lastReceivedAtMs: received,
      lastAlertAtMs: alerted is int ? alerted : null,
    );
  }
}

@immutable
class ForkPushAlertDecision {
  const ForkPushAlertDecision({
    required this.alert,
    required this.newBurst,
    required this.duplicate,
    required this.state,
  });

  final bool alert;

  /// The notification is not on screen: the message starts a new burst, and
  /// lines stored for an earlier one are stale.
  final bool newBurst;

  /// The message is already stored, so it is not a new message.
  final bool duplicate;

  final ForkPushAlertState state;
}

/// Decides whether a push alerts, and what to remember for the next one.
ForkPushAlertDecision decideForkPushAlert({
  required ForkPushAlertState? previous,
  required int nowMs,
  required bool showing,
  required bool alreadyStored,
  required bool oneToOneDirectMessage,
  required bool directMention,
  required bool alertEveryMessage,
}) {
  final int? lastAlertAtMs = previous?.lastAlertAtMs;
  final bool justAlerted =
      lastAlertAtMs != null &&
      _within(nowMs, lastAlertAtMs, kForkPushAlertPostGrace);
  if (!showing && !justAlerted) {
    return ForkPushAlertDecision(
      alert: true,
      newBurst: true,
      duplicate: false,
      state: ForkPushAlertState(lastReceivedAtMs: nowMs, lastAlertAtMs: nowMs),
    );
  }
  if (alreadyStored) {
    return ForkPushAlertDecision(
      alert: alertEveryMessage,
      newBurst: false,
      duplicate: true,
      state: ForkPushAlertState(
        lastReceivedAtMs: previous?.lastReceivedAtMs ?? nowMs,
        lastAlertAtMs: alertEveryMessage ? nowMs : lastAlertAtMs,
      ),
    );
  }
  final bool afterPause =
      oneToOneDirectMessage &&
      (previous == null ||
          !_within(
            nowMs,
            previous.lastReceivedAtMs,
            kForkPushDirectMessagePause,
          ));
  final bool mentionAlert =
      directMention &&
      (lastAlertAtMs == null ||
          !_within(nowMs, lastAlertAtMs, kForkPushMentionAlertGap));
  final bool alert = alertEveryMessage || afterPause || mentionAlert;
  return ForkPushAlertDecision(
    alert: alert,
    newBurst: false,
    duplicate: false,
    state: ForkPushAlertState(
      lastReceivedAtMs: nowMs,
      lastAlertAtMs: alert ? nowMs : lastAlertAtMs,
    ),
  );
}

/// Whether [thenMs] lies less than [window] before [nowMs]. A time in the
/// future (the clock was set back) does not count as within.
bool _within(int nowMs, int thenMs, Duration window) {
  final int elapsed = nowMs - thenMs;
  return elapsed >= 0 && elapsed < window.inMilliseconds;
}
