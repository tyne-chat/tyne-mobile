// Fork: tyne-chat/tyne#865. While panning is off (the media is not zoomed in),
// InteractiveViewer can do nothing with one finger, yet Flutter still enters
// its ScaleGestureRecognizer in the gesture arena for every touch. That
// recognizer claims a one-finger gesture once the finger has moved twice the
// touch slop in any direction, and it sits deeper in the tree than the
// viewer's page and swipe-to-close recognizers, so it sees every move first.
// A fast swipe, whose first move is already past twice the slop, went to it
// and nothing happened.
//
// ForkMediaViewerInteractiveViewer takes the place of upstream's
// InteractiveViewer call. While panning is off it gives InteractiveViewer's
// own gesture detector an infinite touch slop, so that recognizer only claims
// two-finger gestures: a pinch is recognized by the change in the fingers'
// span, which the touch slop does not affect. The media inside gets the
// original gesture settings back.
import 'package:flutter/gestures.dart';
import 'package:fluxer_app/material_ui.dart';

class ForkMediaViewerInteractiveViewer extends StatelessWidget {
  const ForkMediaViewerInteractiveViewer({
    required this.child,
    this.transformationController,
    this.minScale = 0.8,
    this.maxScale = 2.5,
    this.panEnabled = true,
    this.scaleEnabled = true,
    this.boundaryMargin = EdgeInsets.zero,
    this.clipBehavior = Clip.hardEdge,
    this.onInteractionEnd,
    super.key,
  });

  static const DeviceGestureSettings _noOneFingerGestures =
      DeviceGestureSettings(touchSlop: double.infinity);

  final Widget child;
  final TransformationController? transformationController;
  final double minScale;
  final double maxScale;
  final bool panEnabled;
  final bool scaleEnabled;
  final EdgeInsets boundaryMargin;
  final Clip clipBehavior;
  final GestureScaleEndCallback? onInteractionEnd;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    // The same widgets whether panning is on or off: a pinch that zooms in
    // turns panning on mid-gesture, and InteractiveViewer keeps its state.
    return MediaQuery(
      data: panEnabled
          ? mediaQuery
          : mediaQuery.copyWith(gestureSettings: _noOneFingerGestures),
      child: InteractiveViewer(
        transformationController: transformationController,
        minScale: minScale,
        maxScale: maxScale,
        panEnabled: panEnabled,
        scaleEnabled: scaleEnabled,
        boundaryMargin: boundaryMargin,
        clipBehavior: clipBehavior,
        onInteractionEnd: onInteractionEnd,
        child: MediaQuery(data: mediaQuery, child: child),
      ),
    );
  }
}
