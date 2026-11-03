import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/push/android/conversation/fork_alert_policy.dart';

const int _t0 = 1000000000;
const int _second = 1000;
const int _minute = 60 * _second;

ForkPushAlertDecision _decide({
  ForkPushAlertState? previous,
  int nowMs = _t0,
  bool showing = true,
  bool alreadyStored = false,
  bool oneToOne = false,
  bool mention = false,
  bool everyMessage = false,
}) => decideForkPushAlert(
  previous: previous,
  nowMs: nowMs,
  showing: showing,
  alreadyStored: alreadyStored,
  oneToOneDirectMessage: oneToOne,
  directMention: mention,
  alertEveryMessage: everyMessage,
);

ForkPushAlertState _state({
  int lastReceivedAtMs = _t0,
  int? lastAlertAtMs = _t0,
}) => ForkPushAlertState(
  lastReceivedAtMs: lastReceivedAtMs,
  lastAlertAtMs: lastAlertAtMs,
);

void main() {
  group('a new burst', () {
    test('the first message alerts', () {
      final ForkPushAlertDecision decision = _decide(showing: false);
      expect(decision.alert, isTrue);
      expect(decision.newBurst, isTrue);
      expect(decision.state.lastAlertAtMs, _t0);
    });

    test('a dismissed notification starts a new burst that alerts', () {
      final ForkPushAlertDecision decision = _decide(
        previous: _state(),
        nowMs: _t0 + 10 * _minute,
        showing: false,
      );
      expect(decision.alert, isTrue);
      expect(decision.newBurst, isTrue);
    });

    test('a message just after an alert counts as on screen before Android '
        'lists the notification', () {
      final ForkPushAlertDecision decision = _decide(
        previous: _state(),
        nowMs: _t0 + 2 * _second,
        showing: false,
      );
      expect(decision.alert, isFalse);
      expect(decision.newBurst, isFalse);
    });

    test('the grace period ends after three seconds', () {
      final ForkPushAlertDecision decision = _decide(
        previous: _state(),
        nowMs: _t0 + 3 * _second,
        showing: false,
      );
      expect(decision.newBurst, isTrue);
    });
  });

  group('while the notification is on screen', () {
    test('a further message is silent', () {
      final ForkPushAlertDecision decision = _decide(
        previous: _state(),
        nowMs: _t0 + _minute,
      );
      expect(decision.alert, isFalse);
      expect(decision.state.lastReceivedAtMs, _t0 + _minute);
      expect(decision.state.lastAlertAtMs, _t0);
    });

    test('a channel quiet for an hour still does not alert', () {
      final ForkPushAlertDecision decision = _decide(
        previous: _state(),
        nowMs: _t0 + 60 * _minute,
      );
      expect(decision.alert, isFalse);
    });

    test('a one-to-one DM alerts after 30 minutes of quiet', () {
      final ForkPushAlertDecision decision = _decide(
        previous: _state(),
        nowMs: _t0 + 30 * _minute,
        oneToOne: true,
      );
      expect(decision.alert, isTrue);
      expect(decision.state.lastAlertAtMs, _t0 + 30 * _minute);
    });

    test('a one-to-one DM does not alert after 29 minutes', () {
      final ForkPushAlertDecision decision = _decide(
        previous: _state(),
        nowMs: _t0 + 29 * _minute,
        oneToOne: true,
      );
      expect(decision.alert, isFalse);
    });

    test('a steady flood in a one-to-one DM never alerts again', () {
      ForkPushAlertState state = _state();
      for (int minute = 10; minute <= 120; minute += 10) {
        final ForkPushAlertDecision decision = _decide(
          previous: state,
          nowMs: _t0 + minute * _minute,
          oneToOne: true,
        );
        expect(decision.alert, isFalse, reason: 'minute $minute');
        state = decision.state;
      }
    });

    test('a direct mention alerts', () {
      final ForkPushAlertDecision decision = _decide(
        previous: _state(),
        nowMs: _t0 + 2 * _minute,
        mention: true,
      );
      expect(decision.alert, isTrue);
      expect(decision.state.lastAlertAtMs, _t0 + 2 * _minute);
    });

    test(
      'a mention right behind the alert that started the burst is silent',
      () {
        final ForkPushAlertDecision decision = _decide(
          previous: _state(),
          nowMs: _t0 + 50,
          mention: true,
        );
        expect(decision.alert, isFalse);
      },
    );

    test('a mention within a minute of a mention alert is silent', () {
      final ForkPushAlertDecision decision = _decide(
        previous: _state(lastAlertAtMs: _t0 + 2 * _minute),
        nowMs: _t0 + 2 * _minute + 59 * _second,
        mention: true,
      );
      expect(decision.alert, isFalse);
    });

    test('alert for every message alerts on every message', () {
      final ForkPushAlertDecision decision = _decide(
        previous: _state(),
        nowMs: _t0 + 10 * _second,
        everyMessage: true,
      );
      expect(decision.alert, isTrue);
    });

    test('a time set back counts as elapsed', () {
      final ForkPushAlertDecision decision = _decide(
        previous: _state(lastReceivedAtMs: _t0 + 60 * _minute),
        nowMs: _t0 + _minute,
        oneToOne: true,
      );
      expect(decision.alert, isTrue);
    });
  });

  group('a message already stored', () {
    test('is silent and does not move the clock', () {
      final ForkPushAlertDecision decision = _decide(
        previous: _state(),
        nowMs: _t0 + 31 * _minute,
        alreadyStored: true,
        oneToOne: true,
      );
      expect(decision.alert, isFalse);
      expect(decision.duplicate, isTrue);
      expect(decision.state.lastReceivedAtMs, _t0);
    });
  });

  test('the state survives a JSON round trip', () {
    final ForkPushAlertState state = _state(lastReceivedAtMs: _t0 + 5);
    final ForkPushAlertState? decoded = ForkPushAlertState.fromJson(
      state.toJson(),
    );
    expect(decoded?.lastReceivedAtMs, _t0 + 5);
    expect(decoded?.lastAlertAtMs, _t0);
    expect(ForkPushAlertState.fromJson('nonsense'), isNull);
  });
}
