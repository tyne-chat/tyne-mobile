// Fork: tyne-chat/tyne#865. The media viewer's page swipe (horizontal) and
// swipe-to-close (vertical) recognizers each count only their own axis
// against the touch slop. A fast swipe on a thumb's arc passes the slop on
// both axes in the same move event, and the gesture arena then goes to
// whichever recognizer sees that event first: the one deeper in the tree,
// swipe-to-close. A mostly sideways swipe closed the viewer.
//
// With these mixins a recognizer also needs the finger's whole travel since
// it went down to lie mostly along its axis: horizontal when |dx| >= |dy|,
// vertical when |dy| > |dx|. At any moment at most one of the two can accept,
// so the direction of the swipe decides, not the order of the widget tree or
// how far apart the move events are.
//
// Flutter's DragGestureRecognizer is sealed, so there is one mixin per axis.
import 'package:flutter/gestures.dart';

mixin ForkMediaViewerHorizontalAxisLock on HorizontalDragGestureRecognizer {
  final _ForkSwipeTravel _forkTravel = _ForkSwipeTravel(horizontal: true);

  @override
  void handleEvent(PointerEvent event) =>
      _forkTravel.track(event, super.handleEvent);

  @override
  bool hasSufficientGlobalDistanceToAccept(
    PointerDeviceKind pointerDeviceKind,
    double? deviceTouchSlop,
  ) =>
      super.hasSufficientGlobalDistanceToAccept(
        pointerDeviceKind,
        deviceTouchSlop,
      ) &&
      _forkTravel.isAlongAxis;

  @override
  void didStopTrackingLastPointer(int pointer) {
    _forkTravel.clear();
    super.didStopTrackingLastPointer(pointer);
  }
}

mixin ForkMediaViewerVerticalAxisLock on VerticalDragGestureRecognizer {
  final _ForkSwipeTravel _forkTravel = _ForkSwipeTravel(horizontal: false);

  @override
  void handleEvent(PointerEvent event) =>
      _forkTravel.track(event, super.handleEvent);

  @override
  bool hasSufficientGlobalDistanceToAccept(
    PointerDeviceKind pointerDeviceKind,
    double? deviceTouchSlop,
  ) =>
      super.hasSufficientGlobalDistanceToAccept(
        pointerDeviceKind,
        deviceTouchSlop,
      ) &&
      _forkTravel.isAlongAxis;

  @override
  void didStopTrackingLastPointer(int pointer) {
    _forkTravel.clear();
    super.didStopTrackingLastPointer(pointer);
  }
}

/// How far each pointer has travelled since it went down, and which pointer
/// the recognizer is handling an event for right now.
class _ForkSwipeTravel {
  _ForkSwipeTravel({required this.horizontal});

  final bool horizontal;
  final Map<int, Offset> _travel = <int, Offset>{};
  int? _eventPointer;

  void track(PointerEvent event, void Function(PointerEvent) handleEvent) {
    if (event is PointerDownEvent || event is PointerPanZoomStartEvent) {
      _travel[event.pointer] = Offset.zero;
    } else if (event is PointerMoveEvent) {
      _travel[event.pointer] =
          (_travel[event.pointer] ?? Offset.zero) + event.delta;
    } else if (event is PointerPanZoomUpdateEvent) {
      _travel[event.pointer] = event.pan;
    }
    _eventPointer = event.pointer;
    try {
      handleEvent(event);
    } finally {
      _eventPointer = null;
      if (event is PointerUpEvent ||
          event is PointerCancelEvent ||
          event is PointerPanZoomEndEvent) {
        _travel.remove(event.pointer);
      }
    }
  }

  /// Whether the pointer of the event being handled has moved mostly along
  /// this recognizer's axis. True when there is nothing to judge by.
  bool get isAlongAxis {
    final int? pointer = _eventPointer;
    final Offset? travel = pointer == null ? null : _travel[pointer];
    if (travel == null) {
      return true;
    }
    return horizontal
        ? travel.dx.abs() >= travel.dy.abs()
        : travel.dy.abs() > travel.dx.abs();
  }

  void clear() => _travel.clear();
}
