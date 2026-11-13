import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/widgets/fork_pause_when_out_of_view.dart';

// tyne-chat/tyne#625: a mounted animated image out of view kept animating.
// ForkPauseWhenOutOfView turns TickerMode off for its child while none of it
// is visible. (flutter_test_config.dart reports visibility without delay.)
void main() {
  testWidgets('pauses its child while it is scrolled out of view', (
    WidgetTester tester,
  ) async {
    final ScrollController controller = ScrollController();
    addTearDown(controller.dispose);
    const Key target = ValueKey<String>('target');
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SingleChildScrollView(
          controller: controller,
          child: const Column(
            children: <Widget>[
              SizedBox(height: 2000),
              ForkPauseWhenOutOfView(
                child: SizedBox(key: target, width: 40, height: 40),
              ),
            ],
          ),
        ),
      ),
    );
    // The visibility report comes after a frame, and its setState needs one.
    await tester.pump();
    await tester.pump();
    bool enabled() =>
        TickerMode.valuesOf(tester.element(find.byKey(target))).enabled;
    expect(enabled(), isFalse);

    controller.jumpTo(1800);
    await tester.pump();
    await tester.pump();
    expect(enabled(), isTrue);

    controller.jumpTo(0);
    await tester.pump();
    await tester.pump();
    expect(enabled(), isFalse);
  });

  testWidgets('an ancestor TickerMode still turns it off when in view', (
    WidgetTester tester,
  ) async {
    const Key target = ValueKey<String>('target');
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: TickerMode(
          enabled: false,
          child: ForkPauseWhenOutOfView(
            child: SizedBox(key: target, width: 40, height: 40),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      TickerMode.valuesOf(tester.element(find.byKey(target))).enabled,
      isFalse,
    );
  });
}
