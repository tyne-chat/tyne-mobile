// Fork: tests for fork_measure_start_on_resume.dart (tyne-chat/tyne#210).
//
// A start without a screen cannot reach `fluxer_app/measure_reporting`: `MainActivity` registers it
// when it attaches. The native start here is scripted to fail like that and then succeed, and the
// tests count how often it is tried.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/build/app_build_config.dart';
import 'package:fluxer_app/core/observability/fluxer_observability.dart';
import 'package:fluxer_app/core/observability/fork_measure_start_on_resume.dart';
import 'package:fluxer_app/core/observability/observability_reporting_provider.dart';
import 'package:fluxer_app/core/observability/reporting_consent/observability_reporting_prompt_provider.dart';
import 'package:fluxer_app/core/providers/app_runtime_info_provider.dart';
import 'package:measure_flutter/measure_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'observability_reporting_provider_test.dart' hide main;

/// Upstream's provider wiring, with a native start that answers `nativeResults` in turn (the last
/// answer repeats).
class _Harness {
  _Harness({required List<bool> nativeResults}) {
    observability = FluxerObservability.forTesting(measure, () async {
      nativeStarts++;
      final int last = nativeResults.length - 1;
      return nativeResults[nativeStarts - 1 < last ? nativeStarts - 1 : last];
    });
    container = ProviderContainer(
      overrides: [
        fluxerObservabilityProvider.overrideWithValue(observability),
        appRuntimeInfoProvider.overrideWith(
          (Ref ref) => AppRuntimeInfo(
            packageName: 'chat.tyne.app',
            version: '1.0.0',
            buildNumber: '1',
            environment: AppBuildConfig.environment,
            pushProvider: AppBuildConfig.pushProvider,
            buildTimestamp: '',
          ),
        ),
      ],
    );
  }

  final MeasureApi measure = forkUpstream.fakeMeasure();
  late final FluxerObservability observability;
  late final ProviderContainer container;
  int nativeStarts = 0;

  int get sdkStarts => forkUpstream.startsOf(measure);

  ObservabilityReporting get reporting =>
      container.read(observabilityReportingProvider.notifier);

  bool get state => container.read(observabilityReportingProvider);

  /// What `loadObservabilityReportingPrompt` does in `main` when the previous process died on
  /// screen and reporting looked off.
  void requestCrashReportPrompt() => container
      .read(observabilityReportingPromptProvider.notifier)
      .requestPrompt();

  bool get promptWaiting =>
      container.read(observabilityReportingPromptProvider);
}

Map<String, Object> get _reportingOn => <String, Object>{
  'flutter.$kObservabilityReportingEnabledKey': true,
};

Future<void> _moveTo(AppLifecycleState state) async {
  WidgetsBinding.instance.handleAppLifecycleStateChanged(state);
  await pumpEventQueue();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  // Runs first: no lifecycle state has arrived yet, as in an engine no activity has attached to.
  test(
    'a start without a screen that could not start Measure starts it at the first resume',
    () async {
      expect(WidgetsBinding.instance.lifecycleState, isNull);
      SharedPreferences.setMockInitialValues(_reportingOn);
      final _Harness harness = _Harness(nativeResults: <bool>[false, true]);
      addTearDown(harness.container.dispose);

      await harness.reporting.load();
      expect(harness.state, isFalse);
      expect(harness.observability.isEnabled, isFalse);
      expect(harness.nativeStarts, 1);

      installForkMeasureStartOnResume(harness.container);
      await pumpEventQueue();
      expect(harness.nativeStarts, 1, reason: 'nothing happens before resume');

      await _moveTo(AppLifecycleState.resumed);

      expect(harness.nativeStarts, 2);
      expect(harness.sdkStarts, 1);
      expect(harness.observability.isEnabled, isTrue);
      expect(harness.state, isTrue);
    },
  );

  test('it tries once: later resumes do not start native again', () async {
    await _moveTo(AppLifecycleState.paused);
    SharedPreferences.setMockInitialValues(_reportingOn);
    final _Harness harness = _Harness(nativeResults: <bool>[false]);
    addTearDown(harness.container.dispose);

    await harness.reporting.load();
    installForkMeasureStartOnResume(harness.container);
    await _moveTo(AppLifecycleState.resumed);
    expect(harness.nativeStarts, 2);

    await _moveTo(AppLifecycleState.paused);
    await _moveTo(AppLifecycleState.resumed);
    await _moveTo(AppLifecycleState.paused);
    await _moveTo(AppLifecycleState.resumed);

    expect(harness.nativeStarts, 2);
    expect(harness.sdkStarts, 0);
    expect(harness.state, isFalse);
  });

  test('with reporting off, the first resume starts nothing', () async {
    await _moveTo(AppLifecycleState.paused);
    final _Harness harness = _Harness(nativeResults: <bool>[true]);
    addTearDown(harness.container.dispose);

    await harness.reporting.load();
    installForkMeasureStartOnResume(harness.container);
    await _moveTo(AppLifecycleState.resumed);

    expect(harness.nativeStarts, 0);
    expect(harness.sdkStarts, 0);
    expect(harness.state, isFalse);
    expect(harness.observability.isEnabled, isFalse);
  });

  test('reporting turned off before the first resume stays off', () async {
    await _moveTo(AppLifecycleState.paused);
    SharedPreferences.setMockInitialValues(_reportingOn);
    final _Harness harness = _Harness(nativeResults: <bool>[false, true]);
    addTearDown(harness.container.dispose);

    await harness.reporting.load();
    await harness.reporting.setEnabled(value: false);
    installForkMeasureStartOnResume(harness.container);
    await _moveTo(AppLifecycleState.resumed);

    expect(harness.nativeStarts, 1);
    expect(harness.sdkStarts, 0);
    expect(harness.state, isFalse);
    expect(harness.observability.isEnabled, isFalse);
  });

  test(
    'when Measure already runs, the first resume does nothing more',
    () async {
      await _moveTo(AppLifecycleState.paused);
      SharedPreferences.setMockInitialValues(_reportingOn);
      final _Harness harness = _Harness(nativeResults: <bool>[true]);
      addTearDown(harness.container.dispose);

      await harness.reporting.load();
      expect(harness.observability.isEnabled, isTrue);
      installForkMeasureStartOnResume(harness.container);
      await _moveTo(AppLifecycleState.resumed);

      expect(harness.nativeStarts, 1);
      expect(harness.sdkStarts, 1);
      expect(harness.state, isTrue);
    },
  );

  test('installed while already on screen, it tries at once', () async {
    await _moveTo(AppLifecycleState.resumed);
    SharedPreferences.setMockInitialValues(_reportingOn);
    final _Harness harness = _Harness(nativeResults: <bool>[false, true]);
    addTearDown(harness.container.dispose);

    await harness.reporting.load();
    expect(harness.observability.isEnabled, isFalse);

    installForkMeasureStartOnResume(harness.container);
    await pumpEventQueue();

    expect(harness.nativeStarts, 2);
    expect(harness.sdkStarts, 1);
    expect(harness.observability.isEnabled, isTrue);

    // No observer was left behind to try again.
    await _moveTo(AppLifecycleState.paused);
    await _moveTo(AppLifecycleState.resumed);
    expect(harness.nativeStarts, 2);
  });

  group('a crash-report prompt waiting from before the resume', () {
    test('is withdrawn once reporting runs', () async {
      await _moveTo(AppLifecycleState.paused);
      SharedPreferences.setMockInitialValues(_reportingOn);
      final _Harness harness = _Harness(nativeResults: <bool>[false, true]);
      addTearDown(harness.container.dispose);

      await harness.reporting.load();
      harness.requestCrashReportPrompt();
      expect(harness.promptWaiting, isTrue);

      installForkMeasureStartOnResume(harness.container);
      await _moveTo(AppLifecycleState.resumed);

      expect(harness.observability.isEnabled, isTrue);
      expect(harness.promptWaiting, isFalse);
    });

    test('stays when Measure still cannot start', () async {
      await _moveTo(AppLifecycleState.paused);
      SharedPreferences.setMockInitialValues(_reportingOn);
      final _Harness harness = _Harness(nativeResults: <bool>[false]);
      addTearDown(harness.container.dispose);

      await harness.reporting.load();
      harness.requestCrashReportPrompt();

      installForkMeasureStartOnResume(harness.container);
      await _moveTo(AppLifecycleState.resumed);

      expect(harness.observability.isEnabled, isFalse);
      expect(harness.promptWaiting, isTrue);
    });

    test('stays when reporting is off', () async {
      await _moveTo(AppLifecycleState.paused);
      final _Harness harness = _Harness(nativeResults: <bool>[true]);
      addTearDown(harness.container.dispose);

      await harness.reporting.load();
      harness.requestCrashReportPrompt();

      installForkMeasureStartOnResume(harness.container);
      await _moveTo(AppLifecycleState.resumed);

      expect(harness.nativeStarts, 0);
      expect(harness.promptWaiting, isTrue);
    });
  });
}
