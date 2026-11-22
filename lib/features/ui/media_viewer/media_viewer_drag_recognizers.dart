import 'package:flutter/gestures.dart';

// Fork imports.
import 'package:fluxer_app/features/ui/media_viewer/media_viewer_drag_recognizers_fork.dart';

mixin _YieldsToPinch on OneSequenceGestureRecognizer {
  final Set<int> _trackedPointers = <int>{};
  bool _accepted = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _trackedPointers.add(event.pointer);
    if (_trackedPointers.length > 1 && !_accepted) {
      resolve(GestureDisposition.rejected);
    }
  }

  @override
  void acceptGesture(int pointer) {
    _accepted = true;
    super.acceptGesture(pointer);
  }

  @override
  void stopTrackingPointer(int pointer) {
    _trackedPointers.remove(pointer);
    super.stopTrackingPointer(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _trackedPointers.clear();
    _accepted = false;
    super.didStopTrackingLastPointer(pointer);
  }
}

class MediaViewerVerticalDragGestureRecognizer
    extends VerticalDragGestureRecognizer
    with ForkMediaViewerVerticalAxisLock, _YieldsToPinch {
  MediaViewerVerticalDragGestureRecognizer({super.debugOwner});
}

class MediaViewerHorizontalDragGestureRecognizer
    extends HorizontalDragGestureRecognizer
    with ForkMediaViewerHorizontalAxisLock, _YieldsToPinch {
  MediaViewerHorizontalDragGestureRecognizer({
    super.debugOwner,
    super.supportedDevices,
  });
}

// Fork: tyne-chat/tyne#865. The viewer's long press gives way to a pinch as the
// drags above do: a second finger down before the long press is accepted means
// a pinch. Without it, two fingers resting on unzoomed media, or one turning
// round the other (which zooms nothing), opened the options sheet after
// 500 ms. Used by media_viewer_page_gestures_fork.dart; it lives here to share
// _YieldsToPinch.
class ForkMediaViewerLongPressGestureRecognizer
    extends LongPressGestureRecognizer
    with _YieldsToPinch {
  ForkMediaViewerLongPressGestureRecognizer({super.debugOwner});
}
