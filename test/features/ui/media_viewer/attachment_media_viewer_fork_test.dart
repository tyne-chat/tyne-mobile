// Fork: tests the fork adds, kept out of upstream's
// attachment_media_viewer_test.dart so that file stays as upstream has it.
//
// tyne-chat/tyne#865: fast one-finger swipes in the touch media viewer did
// nothing. On Android the touch slop is the system's (8 dp), and a fast swipe
// reaches the recognizers in large steps (one move per resampled frame), so
// these tests swipe with an 8 px slop in steps of up to 50 px. Upstream's
// tester.fling moves in 6 px steps with Flutter's default 18 px slop, which
// never showed the problem.
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/mature_content/presentation/widgets/mature_media_overlay.dart';
import 'package:fluxer_app/features/ui/media_viewer/attachment_media_viewer.dart';
import 'package:fluxer_app/features/ui/media_viewer/media_viewer_dismissible.dart';
import 'package:fluxer_app/features/ui/media_viewer/touch_media_viewer_page.dart';
import 'package:fluxer_app/material_ui.dart';

import 'attachment_media_viewer_test.dart' hide main;

const double _androidTouchSlop = 8;
const Duration _moveInterval = Duration(milliseconds: 8);
const ValueKey<String> _hostKey = ValueKey<String>('host');

Duration _eventTime = Duration.zero;

void _useAndroidSurface(WidgetTester tester, {double? touchSlop}) {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  if (touchSlop != null) {
    tester.view.gestureSettings = ui.GestureSettings(
      physicalTouchSlop: touchSlop,
    );
  }
  addTearDown(tester.view.reset);
}

Future<void> _openViewer(
  WidgetTester tester, {
  int initialIndex = 0,
  double? touchSlop = _androidTouchSlop,
}) async {
  _useAndroidSurface(tester, touchSlop: touchSlop);
  await tester.pumpWidget(forkUpstream.touchApp(const SizedBox(key: _hostKey)));
  unawaited(
    showAttachmentMediaViewer(
      tester.element(find.byKey(_hostKey)),
      items: <AttachmentMediaViewerItem>[
        forkUpstream.landscapePhoto,
        forkUpstream.landscapePhoto,
        forkUpstream.landscapePhoto,
      ],
      initialIndex: initialIndex,
    ),
  );
  await tester.pumpAndSettle();
  expect(find.byType(AttachmentMediaViewerShell), findsOneWidget);
}

PageController _controller(WidgetTester tester) =>
    tester.widget<PageView>(find.byType(PageView)).controller!;

double _page(WidgetTester tester) => _controller(tester).page!;

bool _viewerOpen() =>
    find.byType(AttachmentMediaViewerShell).evaluate().isNotEmpty;

/// How far the swipe-to-close gesture has moved the media up or down.
double _dismissOffset(WidgetTester tester) {
  double offset = 0;
  final Finder dismissibles = find.byType(MediaViewerDismissible);
  for (int i = 0; i < dismissibles.evaluate().length; i++) {
    // The outermost Transform under MediaViewerDismissible is its translation;
    // the zoom's Transform sits further down.
    final Transform translation = tester.widget<Transform>(
      find
          .descendant(of: dismissibles.at(i), matching: find.byType(Transform))
          .first,
    );
    final double dy = translation.transform.getTranslation().y.abs();
    if (dy > offset) {
      offset = dy;
    }
  }
  return offset;
}

double _zoomTranslationX(WidgetTester tester) => tester
    .widget<InteractiveViewer>(find.byType(InteractiveViewer).first)
    .transformationController!
    .value
    .getTranslation()
    .x;

double _zoomScale(WidgetTester tester) => tester
    .widget<InteractiveViewer>(find.byType(InteractiveViewer).first)
    .transformationController!
    .value
    .getMaxScaleOnAxis();

/// Double-taps the middle of the viewer, which zooms in or back out.
Future<void> _doubleTap(WidgetTester tester) async {
  final Offset center = tester.getCenter(find.byType(PageView));
  await tester.tapAt(center);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tapAt(center);
  await tester.pumpAndSettle();
}

/// Puts one finger down at the middle of the viewer, moves it [distance] px
/// in equal moves of [step], 8 ms apart, lifts it and, unless [settle] is
/// false, lets the viewer settle. Returns the largest offset the
/// swipe-to-close gesture gave the media, and the largest distance the pages
/// moved, while the finger was down.
Future<({double dismissOffset, double pageTravel})> _swipe(
  WidgetTester tester,
  Offset step, {
  double distance = 150,
  bool settle = true,
}) async {
  final TestGesture gesture = await tester.createGesture();
  _eventTime += const Duration(seconds: 1);
  final double startPixels = _controller(tester).position.pixels;
  await gesture.down(
    tester.getCenter(find.byType(PageView)),
    timeStamp: _eventTime,
  );
  double maxDismissOffset = 0;
  double maxPageTravel = 0;
  final int moves = (distance / step.distance).ceil();
  for (int i = 0; i < moves; i++) {
    _eventTime += _moveInterval;
    await gesture.moveBy(step, timeStamp: _eventTime);
    await tester.pump(_moveInterval);
    maxDismissOffset = math.max(maxDismissOffset, _dismissOffset(tester));
    if (_viewerOpen()) {
      maxPageTravel = math.max(
        maxPageTravel,
        (_controller(tester).position.pixels - startPixels).abs(),
      );
    }
  }
  _eventTime += _moveInterval;
  await gesture.up(timeStamp: _eventTime);
  if (settle) {
    await tester.pumpAndSettle();
  }
  return (dismissOffset: maxDismissOffset, pageTravel: maxPageTravel);
}

/// Shows one TouchMediaViewerPage on its own, puts one finger down at its
/// middle and, if [secondFinger] is given, a second finger that follows that
/// path, 16 ms per point; holds both for 700 ms and returns how many times
/// the page's long press fired.
Future<int> _longPressesWhileHolding(
  WidgetTester tester, {
  List<Offset> Function(Offset firstFinger)? secondFinger,
}) async {
  _useAndroidSurface(tester, touchSlop: _androidTouchSlop);
  int longPresses = 0;
  final TransformationController controller = TransformationController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: TouchMediaViewerPage(
        transformationController: controller,
        isCurrentPage: true,
        onDismissProgress: (_) {},
        onClose: () {},
        onZoomChanged: (_) {},
        onLongPress: () => longPresses++,
        child: const SizedBox.expand(),
      ),
    ),
  );
  final Offset anchor = tester.getCenter(find.byType(TouchMediaViewerPage));
  final TestGesture first = await tester.startGesture(anchor, pointer: 1);
  TestGesture? second;
  if (secondFinger != null) {
    final List<Offset> path = secondFinger(anchor);
    second = await tester.startGesture(path.first, pointer: 2);
    for (final Offset point in path.skip(1)) {
      await second.moveTo(point);
      await tester.pump(const Duration(milliseconds: 16));
    }
  }
  await tester.pump(const Duration(milliseconds: 700));
  await second?.up();
  await first.up();
  await tester.pumpAndSettle();
  return longPresses;
}

void main() {
  group('one-finger swipes of any speed (tyne-chat/tyne#865)', () {
    for (final double? slop in <double?>[_androidTouchSlop, null]) {
      final String slopName = slop == null ? 'default' : '${slop.round()} px';
      for (final double step in <double>[4, 12, 17, 30, 50]) {
        testWidgets('swiping left in ${step.round()} px steps turns the page '
            '($slopName touch slop)', (WidgetTester tester) async {
          await _openViewer(tester, touchSlop: slop);
          final swipe = await _swipe(tester, Offset(-step, 0));
          expect(_page(tester), 1);
          expect(swipe.dismissOffset, 0);
          expect(_viewerOpen(), isTrue);
        });
      }
    }

    testWidgets('a fast swipe right goes back a page', (
      WidgetTester tester,
    ) async {
      await _openViewer(tester, initialIndex: 1);
      await _swipe(tester, const Offset(30, 0));
      expect(_page(tester), 0);
      expect(_viewerOpen(), isTrue);
    });

    for (final Offset step in const <Offset>[
      Offset(-30, -14),
      Offset(-30, 14),
    ]) {
      testWidgets('a fast swipe on a thumb arc ($step per move) turns the page '
          'and leaves the media where it is', (WidgetTester tester) async {
        await _openViewer(tester);
        final swipe = await _swipe(tester, step);
        expect(_page(tester), 1);
        expect(swipe.dismissOffset, 0);
        expect(_viewerOpen(), isTrue);
      });
    }

    testWidgets('a fast swipe at exactly 45 degrees turns the page', (
      WidgetTester tester,
    ) async {
      await _openViewer(tester);
      final swipe = await _swipe(tester, const Offset(-20, 20));
      expect(_page(tester), 1);
      expect(swipe.dismissOffset, 0);
      expect(_viewerOpen(), isTrue);
    });

    for (final Offset step in const <Offset>[
      Offset(0, 30),
      Offset(0, -30),
      Offset(12, 30),
    ]) {
      testWidgets('a fast swipe of $step per move closes the viewer', (
        WidgetTester tester,
      ) async {
        await _openViewer(tester);
        await _swipe(tester, step, distance: 240);
        expect(_viewerOpen(), isFalse);
      });
    }

    testWidgets('a fast swipe while the previous page change is still '
        'animating moves the page', (WidgetTester tester) async {
      await _openViewer(tester);
      await _swipe(tester, const Offset(-30, 0), settle: false);
      await tester.pump(const Duration(milliseconds: 30));
      expect(_page(tester), allOf(greaterThan(0), lessThan(1)));

      final swipe = await _swipe(tester, const Offset(-30, 0), settle: false);

      expect(swipe.pageTravel, greaterThan(100));
      await tester.pumpAndSettle();
      expect(_viewerOpen(), isTrue);
    });

    testWidgets('a fast pinch still zooms', (WidgetTester tester) async {
      await _openViewer(tester);
      final Offset center = tester.getCenter(find.byType(PageView));
      _eventTime += const Duration(seconds: 1);
      final TestGesture anchor = await tester.createGesture();
      await anchor.down(center - const Offset(30, 30), timeStamp: _eventTime);
      final TestGesture mover = await tester.createGesture();
      await mover.down(center + const Offset(30, 30), timeStamp: _eventTime);
      for (int i = 0; i < 3; i++) {
        _eventTime += _moveInterval;
        await mover.moveBy(const Offset(30, 30), timeStamp: _eventTime);
        await tester.pump(_moveInterval);
      }
      final double scale = _zoomScale(tester);
      await mover.up(timeStamp: _eventTime);
      await anchor.up(timeStamp: _eventTime);
      await tester.pumpAndSettle();
      expect(scale, greaterThan(1.2));
      expect(_page(tester), 0);
      expect(_viewerOpen(), isTrue);
    });

    testWidgets('when zoomed in, a fast one-finger drag pans the media and '
        'does not turn the page', (WidgetTester tester) async {
      await _openViewer(tester);
      await _doubleTap(tester);
      expect(_zoomScale(tester), greaterThan(2));
      final double translationBefore = _zoomTranslationX(tester);

      final swipe = await _swipe(tester, const Offset(-30, 0));

      expect(_zoomTranslationX(tester), lessThan(translationBefore - 50));
      expect(_page(tester), 0);
      expect(swipe.dismissOffset, 0);
      expect(_viewerOpen(), isTrue);
    });

    testWidgets('after zooming in and back out, a fast swipe turns the page '
        'again', (WidgetTester tester) async {
      await _openViewer(tester);
      await _doubleTap(tester);
      expect(_zoomScale(tester), greaterThan(2));
      await _doubleTap(tester);
      expect(_zoomScale(tester), 1);

      final swipe = await _swipe(tester, const Offset(-30, 0));

      expect(_page(tester), 1);
      expect(swipe.dismissOffset, 0);
      expect(_viewerOpen(), isTrue);
    });

    testWidgets('only the zoom gesture detector loses its touch slop, and only '
        'while the media is not zoomed in', (WidgetTester tester) async {
      await _openViewer(tester);
      double? zoomDetectorSlop() => MediaQuery.gestureSettingsOf(
        tester.element(
          find
              .descendant(
                of: find.byType(InteractiveViewer).first,
                matching: find.byType(GestureDetector),
              )
              .first,
        ),
      ).touchSlop;
      double? mediaSlop() => MediaQuery.gestureSettingsOf(
        tester.element(find.byType(MatureMediaOverlay).first),
      ).touchSlop;

      expect(zoomDetectorSlop(), double.infinity);
      expect(mediaSlop(), _androidTouchSlop);

      await _doubleTap(tester);
      expect(zoomDetectorSlop(), _androidTouchSlop);
      expect(mediaSlop(), _androidTouchSlop);
    });
  });

  group('the long press gives way to a second finger (tyne-chat/tyne#865)', () {
    testWidgets('one finger held still opens it', (WidgetTester tester) async {
      expect(await _longPressesWhileHolding(tester), 1);
    });

    testWidgets('screen readers can still long-press', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      _useAndroidSurface(tester, touchSlop: _androidTouchSlop);
      int longPresses = 0;
      final TransformationController controller = TransformationController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: TouchMediaViewerPage(
            transformationController: controller,
            isCurrentPage: true,
            onDismissProgress: (_) {},
            onClose: () {},
            onZoomChanged: (_) {},
            onLongPress: () => longPresses++,
            child: const SizedBox.expand(),
          ),
        ),
      );
      tester.semantics.longPress(
        find.semantics.byAction(ui.SemanticsAction.longPress),
      );
      await tester.pumpAndSettle();
      expect(longPresses, 1);
      semantics.dispose();
    });

    testWidgets('two fingers held still do not', (WidgetTester tester) async {
      expect(
        await _longPressesWhileHolding(
          tester,
          secondFinger: (Offset first) => <Offset>[first + const Offset(60, 0)],
        ),
        0,
      );
    });

    testWidgets('a second finger turning round the first does not', (
      WidgetTester tester,
    ) async {
      expect(
        await _longPressesWhileHolding(
          tester,
          secondFinger: (Offset first) => <Offset>[
            for (int i = 0; i <= 6; i++)
              first +
                  Offset(
                    60 * math.cos(i * math.pi / 18),
                    60 * math.sin(i * math.pi / 18),
                  ),
          ],
        ),
        0,
      );
    });

    testWidgets('a second finger spreading too little to zoom does not', (
      WidgetTester tester,
    ) async {
      expect(
        await _longPressesWhileHolding(
          tester,
          secondFinger: (Offset first) => <Offset>[
            for (int i = 0; i <= 6; i++) first + Offset(60 + i * 34 / 6, 0),
          ],
        ),
        0,
      );
    });
  });
}
