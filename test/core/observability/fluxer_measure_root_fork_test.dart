import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/build/app_build_config.dart';
import 'package:fluxer_app/core/observability/fluxer_measure_root.dart';
import 'package:fluxer_app/core/observability/fork_measure_tap_tracking.dart';
import 'package:measure_flutter/measure_flutter.dart';

// tyne-chat/tyne#620: Measure's tap tracking walks the whole widget tree on
// every tap, so the app root leaves MeasureWidget out unless a build turns tap
// tracking back on.
void main() {
  testWidgets('the root leaves MeasureWidget out on a crash-reporting build', (
    WidgetTester tester,
  ) async {
    // The case that matters: a phone build that sends crash reports.
    expect(AppBuildConfig.hasObservabilityConfig, isTrue);
    expect(forkMeasureTapTracking, isFalse);

    await tester.pumpWidget(
      const FluxerMeasureRoot(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text('app'),
        ),
      ),
    );

    expect(find.text('app'), findsOneWidget);
    expect(find.byType(MeasureWidget), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
