import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/widgets/fork_repaint_only_image.dart';

// tyne-chat/tyne#624: an animated image under a LayoutBuilder made its relayout
// boundary lay out again on every frame. ForkRepaintOnlyImage hands frames
// after the first straight to its RenderImage, so they only repaint.

class _Completer extends ImageStreamCompleter {
  int listeners = 0;

  @override
  void addListener(ImageStreamListener listener) {
    listeners += 1;
    super.addListener(listener);
  }

  @override
  void removeListener(ImageStreamListener listener) {
    listeners -= 1;
    super.removeListener(listener);
  }

  void emit(ui.Image image) => setImage(ImageInfo(image: image));
}

class _Provider extends ImageProvider<_Provider> {
  _Provider(this.completer);

  final _Completer completer;

  @override
  Future<_Provider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_Provider>(this);

  @override
  ImageStreamCompleter loadImage(_Provider key, ImageDecoderCallback decode) =>
      completer;
}

/// Counts the layouts of the render object above the LayoutBuilder: the
/// relayout boundary that an animated Image made lay out again.
class _LayoutCounter extends SingleChildRenderObjectWidget {
  const _LayoutCounter({super.child});

  @override
  _RenderLayoutCounter createRenderObject(BuildContext context) =>
      _RenderLayoutCounter();
}

class _RenderLayoutCounter extends RenderProxyBox {
  int layouts = 0;

  @override
  void performLayout() {
    layouts += 1;
    super.performLayout();
  }
}

Widget _underLayoutBuilder(Widget image) => Directionality(
  textDirection: TextDirection.ltr,
  child: Center(
    child: _LayoutCounter(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) => image,
      ),
    ),
  ),
);

void main() {
  late ui.Image first;
  late ui.Image second;

  setUp(() async {
    first = await createTestImage(width: 4, height: 4);
    second = await createTestImage(width: 4, height: 4);
  });

  tearDown(() {
    imageCache
      ..clear()
      ..clearLiveImages();
  });

  int layouts(WidgetTester tester) => tester
      .renderObject<_RenderLayoutCounter>(find.byType(_LayoutCounter))
      .layouts;

  testWidgets('a later frame repaints without laying out above it', (
    WidgetTester tester,
  ) async {
    final _Completer completer = _Completer();
    await tester.pumpWidget(
      _underLayoutBuilder(
        ForkRepaintOnlyImage(
          image: _Provider(completer),
          width: 16,
          height: 16,
        ),
      ),
    );
    completer.emit(first);
    await tester.pump();
    final RenderImage renderImage = tester.renderObject(
      find.byWidgetPredicate((Widget widget) => widget is RawImage),
    );
    expect(renderImage.image!.isCloneOf(first), isTrue);
    final int before = layouts(tester);

    completer.emit(second);
    await tester.pump();

    expect(renderImage.image!.isCloneOf(second), isTrue);
    expect(layouts(tester), before);
  });

  testWidgets("control: Flutter's Image lays out above it on a later frame", (
    WidgetTester tester,
  ) async {
    final _Completer completer = _Completer();
    await tester.pumpWidget(
      _underLayoutBuilder(
        Image(image: _Provider(completer), width: 16, height: 16),
      ),
    );
    completer.emit(first);
    await tester.pump();
    final int before = layouts(tester);

    completer.emit(second);
    await tester.pump();

    expect(layouts(tester), greaterThan(before));
  });

  testWidgets('stops listening while TickerMode is off', (
    WidgetTester tester,
  ) async {
    final _Completer completer = _Completer();
    final _Provider provider = _Provider(completer);
    Widget build({required bool enabled}) => Directionality(
      textDirection: TextDirection.ltr,
      child: TickerMode(
        enabled: enabled,
        child: ForkRepaintOnlyImage(image: provider, width: 16, height: 16),
      ),
    );

    await tester.pumpWidget(build(enabled: true));
    // The image cache listens too until the first image arrives.
    completer.emit(first);
    await tester.pump();
    expect(completer.listeners, 1);

    await tester.pumpWidget(build(enabled: false));
    expect(completer.listeners, 0);

    await tester.pumpWidget(build(enabled: true));
    expect(completer.listeners, 1);
  });

  testWidgets(
    'paused from the start (reduced motion), it shows the first frame and '
    'then stops listening',
    (WidgetTester tester) async {
      final _Completer completer = _Completer();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: ForkRepaintOnlyImage(
              image: _Provider(completer),
              width: 16,
              height: 16,
            ),
          ),
        ),
      );
      completer.emit(first);
      await tester.pump();

      final RenderImage renderImage = tester.renderObject(
        find.byWidgetPredicate((Widget widget) => widget is RawImage),
      );
      expect(renderImage.image!.isCloneOf(first), isTrue);
      expect(completer.listeners, 0);
    },
  );

  testWidgets('shows the error widget when the image fails', (
    WidgetTester tester,
  ) async {
    final _Completer completer = _Completer();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ForkRepaintOnlyImage(
          image: _Provider(completer),
          width: 16,
          height: 16,
          errorBuilder: (BuildContext context) => const Text('broken'),
        ),
      ),
    );
    completer.reportError(exception: StateError('no image'), silent: true);
    await tester.pump();

    expect(find.text('broken'), findsOneWidget);
  });
}
