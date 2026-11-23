// Fork: tyne-chat/tyne#865. Takes the place of upstream's FluxerGestureDetector
// call in TouchMediaViewerPage. Double tap stays with FluxerGestureDetector; the
// long press goes to ForkMediaViewerLongPressGestureRecognizer, which gives way
// to a second finger (a pinch) as the viewer's drags do. Screen readers get the
// same long-press action GestureDetector gave them.
//
// tyne-chat/tyne#866: under a ForkMediaViewerControlsStack, a single tap shows
// or hides the viewer's controls (media_viewer_controls_fork.dart). It sits on
// the same detector as the double tap, so it fires once the double-tap time
// has passed without a second tap, and never for a double tap. Screen readers
// read the page as "Show controls" or "Hide controls", with that tap action.
import 'package:flutter/gestures.dart';
import 'package:fluxer_app/features/ui/media_viewer/media_viewer_controls_fork.dart';
import 'package:fluxer_app/features/ui/media_viewer/media_viewer_drag_recognizers.dart';
import 'package:fluxer_app/features/ui/tappable/fluxer_gesture_detector.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
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
    final ForkMediaViewerControls? controls = ForkMediaViewerControls.maybeOf(
      context,
    );
    final Widget gestures = FluxerGestureDetector(
      behavior: behavior,
      onTap: controls?.toggle,
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
    if (controls == null) {
      return gestures;
    }
    final ForkLocalizations l10n = FluxerLocalizations.of(context).fork;
    return Semantics(
      container: true,
      button: true,
      label: controls.visible
          ? l10n.mediaViewerHideControls
          : l10n.mediaViewerShowControls,
      child: gestures,
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
