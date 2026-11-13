import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/rendering.dart' show RenderImage;
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/widgets/fork_pause_when_out_of_view.dart';

/// Fork: an image of a fixed size whose animation frames only repaint
/// (tyne-chat/tyne#624).
///
/// An `Image` rebuilds on every animation frame. Under a `LayoutBuilder` that
/// rebuild runs during layout, and the `LayoutBuilder` asks its relayout
/// boundary to lay out again: the animated persona tag icon in a message header
/// had the whole message list laid out again about ten times a second. Here
/// the first frame builds as usual, and later frames are handed straight to the
/// `RenderImage`, which with a fixed size only repaints, behind a
/// `RepaintBoundary` of its own. Like `Image`, it shows the first frame and
/// then pauses while `TickerMode` is off or animations are turned off (reduced
/// motion).
class ForkRepaintOnlyImage extends StatefulWidget {
  const ForkRepaintOnlyImage({
    required this.image,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
    super.key,
  });

  final ImageProvider image;
  final double width;
  final double height;
  final BoxFit fit;

  /// Shown when the image fails to load; an empty box of the image's size
  /// when null.
  final WidgetBuilder? errorBuilder;

  @override
  State<ForkRepaintOnlyImage> createState() => _ForkRepaintOnlyImageState();
}

class _ForkRepaintOnlyImageState extends State<ForkRepaintOnlyImage> {
  ImageStream? _stream;
  ImageInfo? _info;
  ImageStreamListener? _listener;
  ImageStreamCompleterHandle? _keepAlive;
  RenderImage? _renderImage;
  bool _listening = false;
  bool _failed = false;

  // As `Image` decides it: paused while `TickerMode` is off or animations are
  // turned off (reduced motion), but only once a first frame is shown.
  bool _paused = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
    _paused =
        !TickerMode.valuesOf(context).enabled ||
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    if (_paused && _info != null) {
      _stopListening(keepAlive: true);
    } else {
      _listen();
    }
  }

  @override
  void didUpdateWidget(ForkRepaintOnlyImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.image != oldWidget.image) {
      _resolve();
    }
  }

  void _resolve() {
    final ImageStream stream = widget.image.resolve(
      createLocalImageConfiguration(
        context,
        size: Size(widget.width, widget.height),
      ),
    );
    if (stream.key == _stream?.key) {
      return;
    }
    final bool wasListening = _listening;
    _stopListening();
    _keepAlive?.dispose();
    _keepAlive = null;
    _failed = false;
    _stream = stream;
    if (wasListening) {
      _listen();
    }
  }

  ImageStreamListener get _imageListener =>
      _listener ??= ImageStreamListener(_onImage, onError: _onError);

  void _onImage(ImageInfo info, bool synchronousCall) {
    final ImageInfo? previous = _info;
    _info = info;
    final RenderImage? renderImage = _renderImage;
    if (synchronousCall) {
      // Called while building: the build that follows draws it.
    } else if (renderImage != null && !_failed) {
      renderImage.image = info.image.clone();
    } else if (mounted) {
      setState(() => _failed = false);
    }
    previous?.dispose();
    if (_paused) {
      _stopListening(keepAlive: true);
    }
  }

  void _onError(Object error, StackTrace? stackTrace) {
    if (mounted) {
      setState(() => _failed = true);
    }
  }

  void _listen() {
    if (_listening) {
      return;
    }
    _stream!.addListener(_imageListener);
    _keepAlive?.dispose();
    _keepAlive = null;
    _listening = true;
  }

  void _stopListening({bool keepAlive = false}) {
    if (!_listening) {
      return;
    }
    if (keepAlive && _keepAlive == null) {
      _keepAlive = _stream!.completer?.keepAlive();
    }
    _stream!.removeListener(_imageListener);
    _listening = false;
  }

  @override
  void dispose() {
    _stopListening();
    _keepAlive?.dispose();
    _keepAlive = null;
    _info?.dispose();
    _info = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return widget.errorBuilder?.call(context) ??
          SizedBox(width: widget.width, height: widget.height);
    }
    return RepaintBoundary(
      child: _CapturedRawImage(
        image: _info?.image,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        onRenderObject: (RenderImage? renderImage) =>
            _renderImage = renderImage,
      ),
    );
  }
}

/// A `RawImage` that hands its render object to the state that owns it.
class _CapturedRawImage extends RawImage {
  const _CapturedRawImage({
    required super.image,
    required super.width,
    required super.height,
    required super.fit,
    required this.onRenderObject,
  });

  final ValueChanged<RenderImage?> onRenderObject;

  @override
  RenderImage createRenderObject(BuildContext context) {
    final RenderImage renderImage = super.createRenderObject(context);
    onRenderObject(renderImage);
    return renderImage;
  }

  @override
  void didUnmountRenderObject(RenderImage renderObject) {
    super.didUnmountRenderObject(renderObject);
    onRenderObject(null);
  }
}

/// Fork: a persona tag icon of [size] (tyne-chat/tyne#624, #625): repaint-only
/// frames, paused while out of view when the icon is animated.
Widget forkPersonaTagIcon({
  required String url,
  required double size,
  WidgetBuilder? errorBuilder,
}) {
  final Widget image = ForkRepaintOnlyImage(
    image: CachedNetworkImageProvider(url),
    width: size,
    height: size,
    errorBuilder: errorBuilder,
  );
  return url.contains('animated=true')
      ? ForkPauseWhenOutOfView(child: image)
      : image;
}
