import 'package:fluxer_app/core/build/app_build_config.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:measure_flutter/measure_flutter.dart';

// Fork imports.
// ignore: directives_ordering
import 'package:fluxer_app/core/observability/fork_measure_tap_tracking.dart';

class FluxerMeasureRoot extends StatelessWidget {
  const FluxerMeasureRoot({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!AppBuildConfig.hasObservabilityConfig) {
      return child;
    }
    // Fork: no tap tracking, which stalls every tap (tyne-chat/tyne#620).
    if (!forkMeasureTapTracking) {
      return child;
    }
    return MeasureWidget(child: child);
  }
}
