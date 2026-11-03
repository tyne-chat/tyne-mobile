// Fork: where an animated custom emoji stands at a given time (tyne-chat/tyne#91).
//
// Every animated emoji works out its frame from the clock of its loop length
// instead of counting frames from when it happened to start, so two emoji with
// the same loop (a left and a right wing) always show the same frame.

import 'package:flutter/foundation.dart';

/// The frame to show at some point of an animation, and how long until the
/// next one is due. `untilNext` is null once an animation that does not loop
/// forever has finished on its last frame.
typedef ForkSyncedEmojiPosition = ({int index, Duration? untilNext});

/// The frame durations of one animation, known in full.
@immutable
class ForkSyncedEmojiTimeline {
  /// Builds the timeline from the codec's frame durations. Durations of 10 ms
  /// or less become [minimumFrameDuration], as `cached_network_image_ce` and
  /// browsers treat them. [repetitionCount] is the codec's: -1 loops forever,
  /// otherwise the animation plays `repetitionCount + 1` times.
  factory ForkSyncedEmojiTimeline(
    List<Duration> durations, {
    required Duration minimumFrameDuration,
    int repetitionCount = -1,
  }) {
    assert(durations.isNotEmpty, 'An animation has at least one frame.');
    final List<int> ends = <int>[];
    int end = 0;
    for (final Duration duration in durations) {
      final Duration clamped = duration <= const Duration(milliseconds: 10)
          ? minimumFrameDuration
          : duration;
      end += clamped.inMicroseconds;
      ends.add(end);
    }
    return ForkSyncedEmojiTimeline._(
      List<int>.unmodifiable(ends),
      repetitionCount,
    );
  }

  const ForkSyncedEmojiTimeline._(this._endsMicros, this.repetitionCount);

  /// Where each frame ends, from the start of the loop, in microseconds.
  final List<int> _endsMicros;

  /// The codec's repetition count: -1 loops forever.
  final int repetitionCount;

  int get frameCount => _endsMicros.length;

  /// Whether the animation loops forever. Only those follow a shared clock;
  /// one that plays a set number of times starts when it is first shown.
  bool get loopsForever => repetitionCount < 0;

  Duration get loopDuration => Duration(microseconds: _endsMicros.last);

  /// The frame due [elapsed] after the animation's origin.
  ForkSyncedEmojiPosition positionAt(Duration elapsed) {
    final int loop = _endsMicros.last;
    final int micros = elapsed.isNegative ? 0 : elapsed.inMicroseconds;
    if (!loopsForever && micros >= loop * (repetitionCount + 1)) {
      return (index: frameCount - 1, untilNext: null);
    }
    final int inLoop = micros % loop;
    int index = 0;
    while (_endsMicros[index] <= inLoop) {
      index += 1;
    }
    return (
      index: index,
      untilNext: Duration(microseconds: _endsMicros[index] - inLoop),
    );
  }
}
