// Fork: tests the fork adds, kept out of upstream's
// media_viewer_dismissible_test.dart so that file stays as upstream has it.
//
// tyne-chat/tyne#865: swipe-to-close only claims a swipe that moves mostly up
// or down (ForkMediaViewerVerticalAxisLock). That rule only matters while
// another listener stays undecided, as the zoom handler does on an image.
// Where the other listeners are taps, as in fullscreen video, they drop out
// once the finger moves, swipe-to-close is left alone in the gesture arena and
// wins by default, as it did before the fork's change.
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/ui/media_viewer/media_viewer_dismissible.dart';
import 'package:fluxer_app/features/ui/media_viewer/media_viewer_interactive_viewer_fork.dart';
import 'package:material_ui/material_ui.dart';

/// Shows MediaViewerDismissible around [child] with Android's 8 px touch
/// slop, swipes from its middle in eight moves of [step], 8 ms apart, and
/// returns whether it closed.
Future<bool> _swipeCloses(
  WidgetTester tester,
  Offset step, {
  required Widget child,
}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  tester.view.gestureSettings = const ui.GestureSettings(physicalTouchSlop: 8);
  addTearDown(tester.view.reset);
  bool closed = false;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MediaViewerDismissible(
          onDismissProgress: (_) {},
          onClose: () => closed = true,
          child: child,
        ),
      ),
    ),
  );
  final TestGesture gesture = await tester.createGesture();
  Duration time = const Duration(seconds: 1);
  await gesture.down(
    tester.getCenter(find.byType(MediaViewerDismissible)),
    timeStamp: time,
  );
  for (int i = 0; i < 8; i++) {
    time += const Duration(milliseconds: 8);
    await gesture.moveBy(step, timeStamp: time);
    await tester.pump(const Duration(milliseconds: 8));
  }
  await gesture.up(timeStamp: time + const Duration(milliseconds: 8));
  await tester.pumpAndSettle();
  return closed;
}

/// A tap target over the whole area, as fullscreen video has one to show its
/// controls.
Widget _tapTarget() => GestureDetector(
  behavior: HitTestBehavior.translucent,
  onTap: () {},
  child: const SizedBox.expand(),
);

/// Unzoomed media as the image viewer shows it: the zoom handler stays
/// undecided while one finger moves.
Widget _unzoomedMedia() => const ForkMediaViewerInteractiveViewer(
  panEnabled: false,
  child: SizedBox.expand(),
);

void main() {
  testWidgets('beside a tap target, a fast swipe down that drifts sideways '
      'closes', (WidgetTester tester) async {
    expect(
      await _swipeCloses(tester, const Offset(12, 30), child: _tapTarget()),
      isTrue,
    );
  });

  testWidgets('beside unzoomed media, a fast swipe down that drifts sideways '
      'closes', (WidgetTester tester) async {
    expect(
      await _swipeCloses(tester, const Offset(12, 30), child: _unzoomedMedia()),
      isTrue,
    );
  });

  testWidgets('beside only a tap target, as in fullscreen video, a swipe more '
      'sideways than down still closes as before', (WidgetTester tester) async {
    expect(
      await _swipeCloses(tester, const Offset(30, 20), child: _tapTarget()),
      isTrue,
    );
  });

  testWidgets('beside unzoomed media, a swipe more sideways than down does not '
      'close', (WidgetTester tester) async {
    expect(
      await _swipeCloses(tester, const Offset(30, 20), child: _unzoomedMedia()),
      isFalse,
    );
  });
}
