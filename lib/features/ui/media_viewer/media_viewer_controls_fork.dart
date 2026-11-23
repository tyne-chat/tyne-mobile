// Fork: tyne-chat/tyne#866. On touch, the media viewer opens with its controls
// hidden (the close, favourite and options buttons, the alt text, the
// thumbnail strip, the arrows and the "1/3" count), so they do not cover the
// media. A single tap on the media shows them and the next one hides them
// again. Nothing hides them by itself: the choice stays while paging and
// zooming, and every viewer starts hidden again.
//
// The visibility lives in ForkMediaViewerControlsStack, in the place of the
// Stack call in upstream's AttachmentMediaViewerShell, the one widget above
// both the pages and the controls. ForkMediaViewerTouchControls, in the place
// of the touch layout's TabletopHingeColumn call, hides the controls, and the
// tap that toggles them is the page's (ForkMediaViewerPageGestures in
// media_viewer_page_gestures_fork.dart), where double-tap zoom already is: a
// single tap fires once the double-tap time has passed without a second tap,
// and never for a double tap, a drag, a pinch or a long press. With the mouse
// as the main input nothing changes, as that layout never builds
// ForkMediaViewerTouchControls.
//
// Hidden controls stay built (the thumbnails keep loading, so showing them is
// instant) but are transparent, let taps through to the media and are left
// out of the semantics tree. With a screen reader on, the viewer starts with
// the controls shown: hidden, they would only hide the buttons and the alt
// text from it. The media reads as "Show controls" or "Hide controls" and its
// tap action toggles them. The viewer's "Dismiss" backdrop and the system back
// gesture close it whether the controls are shown or not.
//
// Hiding the controls also hides the status and navigation bars (immersive
// sticky: a swipe from the edge shows them for a moment), so nothing but the
// media is on screen. Showing the controls, or closing the viewer, brings the
// bars back the way upstream's voice call screen does
// (voice_call_system_ui_sync.dart).
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:fluxer_app/features/shell/foldable/tabletop_hinge_column.dart';
import 'package:fluxer_app/material_ui.dart';

/// Whether the touch media viewer's controls are shown, and how to toggle
/// them. Provided by [ForkMediaViewerControlsStack].
class ForkMediaViewerControls extends InheritedWidget {
  const ForkMediaViewerControls._({
    required this.visible,
    required this.toggle,
    required super.child,
  });

  final bool visible;
  final VoidCallback toggle;

  static ForkMediaViewerControls? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ForkMediaViewerControls>();

  @override
  bool updateShouldNotify(ForkMediaViewerControls oldWidget) =>
      visible != oldWidget.visible || toggle != oldWidget.toggle;
}

/// A [Stack] that also holds whether the media viewer's controls are shown,
/// for the pages and the controls below it. Takes the place of the Stack call
/// in upstream's AttachmentMediaViewerShell.
class ForkMediaViewerControlsStack extends StatefulWidget {
  const ForkMediaViewerControlsStack({
    this.fit = StackFit.loose,
    this.children = const <Widget>[],
    super.key,
  });

  final StackFit fit;
  final List<Widget> children;

  @override
  State<ForkMediaViewerControlsStack> createState() =>
      _ForkMediaViewerControlsStackState();
}

class _ForkMediaViewerControlsStackState
    extends State<ForkMediaViewerControlsStack> {
  bool? _visible;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decided once, when the viewer opens.
    _visible ??= MediaQuery.accessibleNavigationOf(context);
  }

  void _toggle() {
    setState(() {
      _visible = !(_visible ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ForkMediaViewerControls._(
      visible: _visible ?? false,
      toggle: _toggle,
      child: Stack(fit: widget.fit, children: widget.children),
    );
  }
}

/// The touch media viewer's controls, shown or hidden as
/// [ForkMediaViewerControls] says, with the system bars hidden while they are.
/// Takes the place of the touch layout's TabletopHingeColumn call in
/// upstream's AttachmentMediaViewerShell. Without a
/// [ForkMediaViewerControlsStack] above it, the controls stay shown and the
/// system bars are left alone.
class ForkMediaViewerTouchControls extends StatefulWidget {
  const ForkMediaViewerTouchControls({
    required this.upper,
    required this.lower,
    super.key,
  });

  static const Duration fadeDuration = Duration(milliseconds: 150);

  final Widget upper;
  final Widget lower;

  @override
  State<ForkMediaViewerTouchControls> createState() =>
      _ForkMediaViewerTouchControlsState();
}

class _ForkMediaViewerTouchControlsState
    extends State<ForkMediaViewerTouchControls> {
  bool _systemBarsHidden = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ForkMediaViewerControls? controls = ForkMediaViewerControls.maybeOf(
      context,
    );
    _syncSystemBars(hide: controls != null && !controls.visible);
  }

  @override
  void dispose() {
    _syncSystemBars(hide: false);
    super.dispose();
  }

  void _syncSystemBars({required bool hide}) {
    if (hide == _systemBarsHidden) {
      return;
    }
    _systemBarsHidden = hide;
    unawaited(
      hide
          ? SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)
          : SystemChrome.setEnabledSystemUIMode(
              SystemUiMode.manual,
              overlays: SystemUiOverlay.values,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool visible =
        ForkMediaViewerControls.maybeOf(context)?.visible ?? true;
    return IgnorePointer(
      ignoring: !visible,
      child: ExcludeSemantics(
        excluding: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : ForkMediaViewerTouchControls.fadeDuration,
          curve: Curves.easeOut,
          child: TabletopHingeColumn(upper: widget.upper, lower: widget.lower),
        ),
      ),
    );
  }
}
