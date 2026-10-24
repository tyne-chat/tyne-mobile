// Fork: starts Measure once the app is on screen when an earlier start without a screen could not
// (tyne-chat/tyne#210).
//
// The Dart side starts Measure through the `fluxer_app/measure_reporting` channel, which only
// `MainActivity.configureFlutterEngine` registers. When the full app starts before the activity
// exists (Android has started it for audio_service's media service), that start fails with
// `MissingPluginException` and upstream's `ObservabilityReporting` turns its state off. When the
// activity later attaches to the same engine, nothing tries again, so reporting stayed off for the
// whole process although the person had opted in.
//
// This tries once, at the first resume: only if Measure is not running, and through
// `ObservabilityReporting.load`, which reads the stored choice again, so a person who turned
// reporting off in the meantime is left alone.
//
// The crash-report prompt is decided in `main`, before the resume, and reporting looked off then.
// If an earlier process died on screen, a prompt is waiting to ask someone who already opted in. Once
// reporting runs, that request is withdrawn; upstream asks only when reporting is off. A sheet
// already showing is not touched, because showing it clears the request.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/observability/observability_reporting_provider.dart';
import 'package:fluxer_app/core/observability/reporting_consent/observability_reporting_prompt_provider.dart';

/// Arranges the retry; call once, after `ObservabilityReporting.load` has finished.
void installForkMeasureStartOnResume(ProviderContainer container) {
  final WidgetsBinding binding = WidgetsBinding.instance;
  if (binding.lifecycleState == AppLifecycleState.resumed) {
    unawaited(retryForkMeasureStart(container));
    return;
  }
  binding.addObserver(_ForkMeasureStartOnResume(container));
}

/// Starts Measure again if it is not running and the stored choice is on, and then withdraws a
/// crash-report prompt that is still waiting.
@visibleForTesting
Future<void> retryForkMeasureStart(ProviderContainer container) async {
  if (container.read(fluxerObservabilityProvider).isEnabled) {
    return;
  }
  await container.read(observabilityReportingProvider.notifier).load();
  if (container.read(observabilityReportingProvider) &&
      container.read(observabilityReportingPromptProvider)) {
    container.invalidate(observabilityReportingPromptProvider);
  }
}

class _ForkMeasureStartOnResume extends WidgetsBindingObserver {
  _ForkMeasureStartOnResume(this._container);

  final ProviderContainer _container;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    WidgetsBinding.instance.removeObserver(this);
    unawaited(retryForkMeasureStart(_container));
  }
}
