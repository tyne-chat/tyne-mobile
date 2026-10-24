// Fork: tests the fork adds for app_foreground_session_watchdog.dart, kept out of upstream's
// app_foreground_session_watchdog_test.dart (tyne-chat/tyne#210).
//
// The flag says "a process is on screen". A process that dies with it set is taken for a crash on
// the next start, and the crash-report prompt may follow. The full app can start without a screen
// (Android has started it for a media service), and Android routinely ends such processes for
// memory: that must not count as a crash.
//
// One test plays several processes in a row: `startProcess` is what a new process does at start-up,
// and a process "dies" by simply not reaching paused or detached before the next start.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/observability/reporting_consent/app_foreground_session_watchdog.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> _startProcess() async {
  final AppForegroundSessionBootstrapResult result =
      await bootstrapAppForegroundSession();
  return result.hadForegroundCrash;
}

Future<bool?> _storedFlag() async {
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  return preferences.getBool(kAppForegroundSessionActiveKey);
}

/// Moves the app to [state], then starts the next test's stored preferences from [initial].
///
/// The lifecycle observer writes the flag on some changes, so the change comes first and the
/// stored values are set after it, as a previous process left them.
Future<void> _arrange(
  AppLifecycleState state, {
  Map<String, Object> initial = const <String, Object>{},
}) async {
  WidgetsBinding.instance.handleAppLifecycleStateChanged(state);
  await pumpEventQueue();
  SharedPreferences.setMockInitialValues(initial);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(installAppForegroundSessionLifecycleBinding);

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  // Runs first: the only test that sees the binding before any lifecycle state arrived, as in an
  // engine that no activity has attached to.
  test(
    'a start before any lifecycle state does not mark the session active',
    () async {
      expect(WidgetsBinding.instance.lifecycleState, isNull);

      expect(await _startProcess(), isFalse);
      expect(await _storedFlag(), isFalse);

      expect(await _startProcess(), isFalse);
    },
  );

  for (final AppLifecycleState noScreen in <AppLifecycleState>[
    AppLifecycleState.detached,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.inactive,
  ]) {
    test(
      'Android ending a process that started ${noScreen.name} is not a crash',
      () async {
        await _arrange(noScreen);

        expect(await _startProcess(), isFalse);
        expect(await _storedFlag(), isFalse);

        // The process dies without another lifecycle change; the next one starts.
        expect(await _startProcess(), isFalse);
      },
    );
  }

  test('a process that dies on screen is still reported', () async {
    await _arrange(AppLifecycleState.resumed);

    expect(await _startProcess(), isFalse);
    expect(await _storedFlag(), isTrue);

    expect(await _startProcess(), isTrue);
  });

  test(
    'a process started without a screen, then opened, that dies on screen is reported',
    () async {
      await _arrange(AppLifecycleState.detached);
      expect(await _startProcess(), isFalse);
      expect(await _storedFlag(), isFalse);

      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await pumpEventQueue();
      expect(await _storedFlag(), isTrue);

      expect(await _startProcess(), isTrue);
    },
  );

  test(
    'a process opened and then left before Android ends it is not a crash',
    () async {
      await _arrange(AppLifecycleState.resumed);
      expect(await _startProcess(), isFalse);

      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.paused,
      );
      await pumpEventQueue();
      expect(await _storedFlag(), isFalse);

      // The next process starts without a screen (a push, a media service).
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.detached,
      );
      await pumpEventQueue();
      expect(await _startProcess(), isFalse);
    },
  );

  test(
    'a crash is reported once, not again by the next start without a screen',
    () async {
      await _arrange(
        AppLifecycleState.detached,
        initial: <String, Object>{kAppForegroundSessionActiveKey: true},
      );

      expect(await _startProcess(), isTrue);
      expect(await _storedFlag(), isFalse);

      expect(await _startProcess(), isFalse);
    },
  );
}
