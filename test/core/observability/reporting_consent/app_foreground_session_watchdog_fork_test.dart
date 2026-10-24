// Fork: tests the fork adds for app_foreground_session_watchdog.dart, kept out of upstream's
// app_foreground_session_watchdog_test.dart (tyne-chat/tyne#210).
//
// The marker file says "a process is on screen". A process that dies with it present is taken for a
// crash on the next start, and the crash-report prompt may follow. The full app can start without a
// screen (Android has started it for a media service), and Android routinely ends such processes for
// memory: that must not count as a crash. (Upstream's watchdog has kept the marker only while the
// app is on screen since 2026-11-04; these tests hold it to that.)
//
// One test plays several processes in a row: `startProcess` is what a new process does at start-up,
// and a process "dies" by simply not reaching paused or detached before the next start.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/observability/reporting_consent/app_foreground_session_watchdog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;

  bool markerExists() =>
      File('${directory.path}/$kAppForegroundSessionMarkerName').existsSync();

  void setMarker({required bool present}) {
    final File marker = File(
      '${directory.path}/$kAppForegroundSessionMarkerName',
    );
    if (present) {
      marker.createSync(recursive: true);
    } else if (marker.existsSync()) {
      marker.deleteSync();
    }
  }

  Future<bool> startProcess() async {
    final AppForegroundSessionBootstrapResult result =
        await bootstrapAppForegroundSession(directory: directory);
    return result.hadForegroundCrash;
  }

  /// Moves the app to [state], then leaves the marker as a previous process left it.
  ///
  /// The lifecycle observer writes the marker on some changes, so the change comes first and the
  /// marker is set after it.
  Future<void> arrange(
    AppLifecycleState state, {
    bool markerPresent = false,
  }) async {
    WidgetsBinding.instance.handleAppLifecycleStateChanged(state);
    await pumpEventQueue();
    setMarker(present: markerPresent);
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'fork_foreground_session',
    );
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  // Runs first: the only test that sees the binding before any lifecycle state arrived, as in an
  // engine that no activity has attached to.
  test(
    'a start before any lifecycle state does not mark the session active',
    () async {
      expect(WidgetsBinding.instance.lifecycleState, isNull);

      expect(await startProcess(), isFalse);
      expect(markerExists(), isFalse);

      expect(await startProcess(), isFalse);
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
        await arrange(noScreen);

        expect(await startProcess(), isFalse);
        expect(markerExists(), isFalse);

        // The process dies without another lifecycle change; the next one starts.
        expect(await startProcess(), isFalse);
      },
    );
  }

  test('a process that dies on screen is still reported', () async {
    await arrange(AppLifecycleState.resumed);

    expect(await startProcess(), isFalse);
    expect(markerExists(), isTrue);

    expect(await startProcess(), isTrue);
  });

  test(
    'a process started without a screen, then opened, that dies on screen is reported',
    () async {
      await arrange(AppLifecycleState.detached);
      expect(await startProcess(), isFalse);
      expect(markerExists(), isFalse);

      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await pumpEventQueue();
      expect(markerExists(), isTrue);

      expect(await startProcess(), isTrue);
    },
  );

  test(
    'a process opened and then left before Android ends it is not a crash',
    () async {
      await arrange(AppLifecycleState.resumed);
      expect(await startProcess(), isFalse);

      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.paused,
      );
      await pumpEventQueue();
      expect(markerExists(), isFalse);

      // The next process starts without a screen (a push, a media service).
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.detached,
      );
      await pumpEventQueue();
      expect(await startProcess(), isFalse);
    },
  );

  test(
    'a crash is reported once, not again by the next start without a screen',
    () async {
      await arrange(AppLifecycleState.detached, markerPresent: true);

      expect(await startProcess(), isTrue);
      expect(markerExists(), isFalse);

      expect(await startProcess(), isFalse);
    },
  );
}
