import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:fluxer_app/material_ui.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Fork: pauses the animations under it while none of its own area is in
/// view (tyne-chat/tyne#625).
///
/// An `Image` stops animating only when `TickerMode` is off. One that is
/// mounted but out of view keeps going: the avatar at the top of a long message
/// whose bottom is on screen, for example, is part of a visible list item, so it
/// is painted (and clipped away) and animates. Each of its image frames costs
/// two app frames (tyne-chat/tyne#619). This turns `TickerMode` off for [child]
/// while its visible fraction is 0, measured by the same `VisibilityDetector`
/// upstream uses for embedded GIFs (`embed_animated_image.dart`). Each one adds
/// a layer and a visibility check, so wrap only animated images in it.
class ForkPauseWhenOutOfView extends StatefulWidget {
  const ForkPauseWhenOutOfView({required this.child, super.key});

  final Widget child;

  @override
  State<ForkPauseWhenOutOfView> createState() => _ForkPauseWhenOutOfViewState();
}

class _ForkPauseWhenOutOfViewState extends State<ForkPauseWhenOutOfView> {
  final Key _detectorKey = UniqueKey();

  // In view for the first frame, so an image in view starts as it would
  // without this widget.
  bool _inView = true;
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    // VisibilityDetector reports nothing for a widget that is out of view from
    // the start, only changes once it has been seen. So the first look is
    // taken here, after the first frame: outside the nearest scroll view's
    // visible area, it pauses until VisibilityDetector reports it in view.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFirstView());
  }

  void _checkFirstView() {
    if (!mounted || _reported) {
      return;
    }
    final RenderObject? box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) {
      return;
    }
    final RenderObject? viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport is! RenderBox) {
      return;
    }
    final Rect area = MatrixUtils.transformRect(
      box.getTransformTo(viewport),
      Offset.zero & box.size,
    );
    if (!area.overlaps(Offset.zero & viewport.size)) {
      setState(() => _inView = false);
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    _reported = true;
    final bool inView = info.visibleFraction > 0;
    if (inView != _inView && mounted) {
      setState(() => _inView = inView);
    }
  }

  @override
  Widget build(BuildContext context) => VisibilityDetector(
    key: _detectorKey,
    onVisibilityChanged: _onVisibilityChanged,
    child: TickerMode(enabled: _inView, child: widget.child),
  );
}
