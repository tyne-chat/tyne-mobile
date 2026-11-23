// Fork: tests the fork adds, kept out of upstream's
// attachment_media_viewer_test.dart so that file stays as upstream has it.
//
// tyne-chat/tyne#865: fast one-finger swipes in the touch media viewer did
// nothing. On Android the touch slop is the system's (8 dp), and a fast swipe
// reaches the recognizers in large steps (one move per resampled frame), so
// these tests swipe with an 8 px slop in steps of up to 50 px. Upstream's
// tester.fling moves in 6 px steps with Flutter's default 18 px slop, which
// never showed the problem.
//
// tyne-chat/tyne#866: on touch the viewer opens with its controls hidden, and
// a single tap on the media shows or hides them.
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/mature_content/presentation/widgets/mature_media_overlay.dart';
import 'package:fluxer_app/features/ui/media_viewer/attachment_media_viewer.dart';
import 'package:fluxer_app/features/ui/media_viewer/media_viewer_controls_fork.dart';
import 'package:fluxer_app/features/ui/media_viewer/media_viewer_dismissible.dart';
import 'package:fluxer_app/features/ui/media_viewer/touch_media_viewer_page.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
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

FluxerLocalizations _l10n(WidgetTester tester) => FluxerLocalizations.of(
  tester.element(find.byType(AttachmentMediaViewerShell)),
);

/// Taps the media once, at the middle of the viewer unless [at] is given, and
/// waits until the tap counts as a single tap (the double-tap time has passed
/// without a second tap) and the controls have faded in or out.
Future<void> _tapMedia(WidgetTester tester, {Offset? at}) async {
  await tester.tapAt(at ?? tester.getCenter(find.byType(PageView)));
  await tester.pump(kDoubleTapTimeout);
  await tester.pumpAndSettle();
}

/// Expects the touch viewer's controls to be drawn and tappable, or neither.
void _expectControls(WidgetTester tester, {required bool shown}) {
  final AnimatedOpacity fade = tester.widget<AnimatedOpacity>(
    find
        .descendant(
          of: find.byType(ForkMediaViewerTouchControls),
          matching: find.byType(AnimatedOpacity),
        )
        .first,
  );
  expect(fade.opacity, shown ? 1 : 0);
  final FluxerLocalizations l10n = _l10n(tester);
  for (final String tooltip in <String>[
    l10n.mediaViewerClose,
    l10n.mediaViewerOptions,
    l10n.mediaViewerNextAttachment,
  ]) {
    expect(
      find.byTooltip(tooltip).hitTestable(),
      shown ? findsOneWidget : findsNothing,
      reason: tooltip,
    );
  }
}

/// The semantics node whose label starts with [label].
FinderBase<SemanticsNode> _semanticsLabelled(String label) => find.semantics
    .byPredicate((SemanticsNode node) => node.label.startsWith(label));

FinderBase<SemanticsNode> _semanticsWithTooltip(String tooltip) =>
    find.semantics.byPredicate((SemanticsNode node) => node.tooltip == tooltip);

/// Shows one TouchMediaViewerPage under a ForkMediaViewerControlsStack, as
/// the viewer has it, and returns its zoom controller.
Future<TransformationController> _pumpPageUnderControls(
  WidgetTester tester, {
  required VoidCallback onLongPress,
}) async {
  _useAndroidSurface(tester, touchSlop: _androidTouchSlop);
  final TransformationController controller = TransformationController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    forkUpstream.touchApp(
      ForkMediaViewerControlsStack(
        fit: StackFit.expand,
        children: <Widget>[
          TouchMediaViewerPage(
            transformationController: controller,
            isCurrentPage: true,
            onDismissProgress: (_) {},
            onClose: () {},
            onZoomChanged: (_) {},
            onLongPress: onLongPress,
            child: const SizedBox.expand(),
          ),
        ],
      ),
    ),
  );
  return controller;
}

bool _controlsVisible(WidgetTester tester) => tester
    .widget<ForkMediaViewerControls>(find.byType(ForkMediaViewerControls))
    .visible;

// Records each SystemChrome.setEnabledSystemUIMode call as its mode, with
// " all" when every overlay is asked for.
List<String> _recordSystemUiModes(WidgetTester tester) {
  final List<String> modes = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (MethodCall call) async {
      if (call.method == 'SystemChrome.setEnabledSystemUIMode') {
        modes.add(call.arguments as String);
      } else if (call.method == 'SystemChrome.setEnabledSystemUIOverlays') {
        final List<Object?> overlays = call.arguments as List<Object?>;
        modes.add(
          'SystemUiMode.manual${overlays.length == SystemUiOverlay.values.length ? ' all' : ''}',
        );
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return modes;
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

  group('controls hidden until a tap (tyne-chat/tyne#866)', () {
    testWidgets('the controls start hidden', (WidgetTester tester) async {
      await _openViewer(tester);
      _expectControls(tester, shown: false);
    });

    testWidgets('a single tap shows them and the next one hides them', (
      WidgetTester tester,
    ) async {
      await _openViewer(tester);
      await _tapMedia(tester);
      _expectControls(tester, shown: true);
      await _tapMedia(tester);
      _expectControls(tester, shown: false);
      expect(_viewerOpen(), isTrue);
      expect(_zoomScale(tester), 1);
    });

    testWidgets('they do not hide again by themselves', (
      WidgetTester tester,
    ) async {
      await _openViewer(tester);
      await _tapMedia(tester);
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();
      _expectControls(tester, shown: true);
    });

    testWidgets('a tap where a hidden button is shows the controls and does '
        'not press it', (WidgetTester tester) async {
      await _openViewer(tester);
      final Finder close = find.byTooltip(_l10n(tester).mediaViewerClose);
      await _tapMedia(tester, at: tester.getCenter(close));
      expect(_viewerOpen(), isTrue);
      _expectControls(tester, shown: true);

      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(_viewerOpen(), isFalse);
    });

    testWidgets('a double tap zooms and leaves the controls as they are', (
      WidgetTester tester,
    ) async {
      await _openViewer(tester);
      await _doubleTap(tester);
      await tester.pump(kDoubleTapTimeout);
      await tester.pumpAndSettle();
      expect(_zoomScale(tester), greaterThan(2));
      _expectControls(tester, shown: false);

      await _tapMedia(tester);
      _expectControls(tester, shown: true);

      await _doubleTap(tester);
      await tester.pump(kDoubleTapTimeout);
      await tester.pumpAndSettle();
      expect(_zoomScale(tester), 1);
      _expectControls(tester, shown: true);
    });

    testWidgets('paging keeps the choice, and swipes do not toggle', (
      WidgetTester tester,
    ) async {
      await _openViewer(tester);
      await _swipe(tester, const Offset(-30, 0));
      expect(_page(tester), 1);
      _expectControls(tester, shown: false);

      await _tapMedia(tester);
      await _swipe(tester, const Offset(30, 0));
      expect(_page(tester), 0);
      _expectControls(tester, shown: true);

      await tester.tap(find.byTooltip(_l10n(tester).mediaViewerNextAttachment));
      await tester.pumpAndSettle();
      expect(_page(tester), 1);
      _expectControls(tester, shown: true);

      // A short drag down that snaps back.
      await _swipe(tester, const Offset(0, 4), distance: 40);
      expect(_viewerOpen(), isTrue);
      _expectControls(tester, shown: true);
    });

    testWidgets('every viewer starts with the controls hidden', (
      WidgetTester tester,
    ) async {
      await _openViewer(tester);
      await _tapMedia(tester);
      await tester.tap(find.byTooltip(_l10n(tester).mediaViewerClose));
      await tester.pumpAndSettle();
      expect(_viewerOpen(), isFalse);

      await _openViewer(tester);
      _expectControls(tester, shown: false);
    });

    testWidgets('a long press opens the options and does not toggle', (
      WidgetTester tester,
    ) async {
      int longPresses = 0;
      await _pumpPageUnderControls(tester, onLongPress: () => longPresses++);
      await tester.longPress(find.byType(TouchMediaViewerPage));
      await tester.pump(kDoubleTapTimeout);
      await tester.pumpAndSettle();
      expect(longPresses, 1);
      expect(_controlsVisible(tester), isFalse);

      await tester.tap(find.byType(TouchMediaViewerPage));
      await tester.pump(kDoubleTapTimeout);
      expect(_controlsVisible(tester), isTrue);
    });

    testWidgets('a pinch zooms and does not toggle', (
      WidgetTester tester,
    ) async {
      final TransformationController zoom = await _pumpPageUnderControls(
        tester,
        onLongPress: () {},
      );
      final Offset center = tester.getCenter(find.byType(TouchMediaViewerPage));
      final TestGesture anchor = await tester.startGesture(
        center - const Offset(30, 0),
        pointer: 1,
      );
      final TestGesture mover = await tester.startGesture(
        center + const Offset(30, 0),
        pointer: 2,
      );
      for (int i = 0; i < 6; i++) {
        await mover.moveBy(const Offset(15, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      final double scale = zoom.value.getMaxScaleOnAxis();
      await mover.up();
      await anchor.up();
      await tester.pump(kDoubleTapTimeout);
      await tester.pumpAndSettle();
      expect(scale, greaterThan(1.2));
      expect(_controlsVisible(tester), isFalse);
    });

    testWidgets('screen readers read the media as "Show controls" or "Hide '
        'controls", and its tap action toggles them', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await _openViewer(tester);
      final FluxerLocalizations l10n = _l10n(tester);
      expect(_semanticsLabelled(l10n.fork.mediaViewerShowControls), findsOne);
      expect(_semanticsWithTooltip(l10n.mediaViewerClose), findsNothing);

      tester.semantics.tap(
        _semanticsLabelled(l10n.fork.mediaViewerShowControls),
      );
      await tester.pumpAndSettle();
      _expectControls(tester, shown: true);
      expect(_semanticsLabelled(l10n.fork.mediaViewerHideControls), findsOne);
      expect(_semanticsWithTooltip(l10n.mediaViewerClose), findsOne);

      tester.semantics.tap(
        _semanticsLabelled(l10n.fork.mediaViewerHideControls),
      );
      await tester.pumpAndSettle();
      _expectControls(tester, shown: false);
      semantics.dispose();
    });

    testWidgets('with the controls hidden, screen readers can still close the '
        'viewer', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await _openViewer(tester);
      _expectControls(tester, shown: false);
      tester.semantics.tap(
        _semanticsLabelled(_l10n(tester).mediaViewerDismissBackdrop),
      );
      await tester.pumpAndSettle();
      expect(_viewerOpen(), isFalse);
      semantics.dispose();
    });

    testWidgets('with a screen reader on, the controls start shown', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await _openViewer(tester);
      _expectControls(tester, shown: true);
      await _tapMedia(tester);
      _expectControls(tester, shown: false);
    });

    testWidgets('the system bars hide with the controls and come back with '
        'them and on closing', (WidgetTester tester) async {
      final List<String> modes = _recordSystemUiModes(tester);
      await _openViewer(tester);
      expect(modes, <String>['SystemUiMode.immersiveSticky']);
      await _tapMedia(tester);
      expect(modes.last, 'SystemUiMode.manual all');
      await _tapMedia(tester);
      expect(modes.last, 'SystemUiMode.immersiveSticky');
      // Closed while the controls are hidden, through the backdrop's action.
      final SemanticsHandle semantics = tester.ensureSemantics();
      tester.semantics.tap(
        _semanticsLabelled(_l10n(tester).mediaViewerDismissBackdrop),
      );
      await tester.pumpAndSettle();
      semantics.dispose();
      expect(_viewerOpen(), isFalse);
      expect(modes.last, 'SystemUiMode.manual all');
      expect(modes, hasLength(4));
    });

    testWidgets('with the mouse as the main input, nothing is hidden', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        forkUpstream.mouseApp(
          AttachmentMediaViewerShell(
            items: <AttachmentMediaViewerItem>[
              forkUpstream.landscapePhoto,
              forkUpstream.landscapePhoto,
            ],
            initialIndex: 0,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ForkMediaViewerTouchControls), findsNothing);
      final FluxerLocalizations l10n = _l10n(tester);
      for (final String tooltip in <String>[
        l10n.mediaViewerClose,
        l10n.mediaViewerOptions,
        l10n.mediaViewerNextAttachment,
      ]) {
        expect(
          find.byTooltip(tooltip).hitTestable(),
          findsOneWidget,
          reason: tooltip,
        );
      }
    });
  });
}
