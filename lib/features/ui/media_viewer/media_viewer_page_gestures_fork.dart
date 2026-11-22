// Fork: tyne-chat/tyne#865. Takes the place of upstream's FluxerGestureDetector
// call in TouchMediaViewerPage. Double tap stays with FluxerGestureDetector; the
// long press goes to ForkMediaViewerLongPressGestureRecognizer, which gives way
// to a second finger (a pinch) as the viewer's drags do. Screen readers get the
// same long-press action GestureDetector gave them.
import 'package:flutter/gestures.dart';
import 'package:fluxer_app/features/ui/media_viewer/media_viewer_drag_recognizers.dart';
import 'package:fluxer_app/features/ui/tappable/fluxer_gesture_detector.dart';
import 'package:fluxer_app/material_ui.dart';

class ForkMediaViewerPageGestures extends StatelessWidget {
  const ForkMediaViewerPageGestures({
    required this.child,
    this.behavior,
    this.onDoubleTapDown,
    this.onLongPress,
    super.key,
  });

  final Widget child;
  final HitTestBehavior? behavior;
  final GestureTapDownCallback? onDoubleTapDown;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onLongPress = this.onLongPress;
    final DeviceGestureSettings? gestureSettings =
        MediaQuery.maybeGestureSettingsOf(context);
    return FluxerGestureDetector(
      behavior: behavior,
      onDoubleTapDown: onDoubleTapDown,
      child: RawGestureDetector(
        behavior: behavior,
        semantics: _LongPressSemantics(onLongPress),
        gestures: <Type, GestureRecognizerFactory>{
          if (onLongPress != null)
            ForkMediaViewerLongPressGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                  ForkMediaViewerLongPressGestureRecognizer
                >(
                  () => ForkMediaViewerLongPressGestureRecognizer(
                    debugOwner: this,
                  ),
                  (ForkMediaViewerLongPressGestureRecognizer instance) {
                    instance
                      ..onLongPress = onLongPress
                      ..gestureSettings = gestureSettings;
                  },
                ),
        },
        child: child,
      ),
    );
  }
}

class _LongPressSemantics extends SemanticsGestureDelegate {
  const _LongPressSemantics(this.onLongPress);

  final VoidCallback? onLongPress;

  @override
  void assignSemantics(RenderSemanticsGestureHandler renderObject) {
    renderObject.onLongPress = onLongPress;
  }
}
