// Fork: the clocks animated custom emoji follow (tyne-chat/tyne#91).
//
// There is one clock per loop length: emoji with different loop lengths drift
// apart within a loop whatever their start, so only equal loops (a left and a
// right wing) are kept in step. Each clock has an origin, the frame timestamp
// of a frame 1. An emoji that starts while others with its loop length are on
// screen joins at the frame the clock gives, in step with them. When none is
// on screen at the end of a frame, the origin is cleared, and the next one to
// show starts the clock again at its own frame 1: restarting then cannot put
// anything out of step, and an emoji with a long last frame does not arrive
// in the middle of it.

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class ForkSyncedEmojiClock {
  ForkSyncedEmojiClock();

  /// The clocks the app's emoji share.
  static final ForkSyncedEmojiClock instance = ForkSyncedEmojiClock();

  final Map<Duration, _LoopClock> _clocks = <Duration, _LoopClock>{};

  /// How many animated emoji images with this loop length are on screen:
  /// listened to by a widget that is not paused (an `Image` stops listening
  /// while `TickerMode` is off), once their loop is known.
  int shownCount(Duration loop) => _clocks[loop]?.shown ?? 0;

  /// The frame timestamp of frame 1 for this loop length, or null until the
  /// next emoji with it to show sets it.
  Duration? originOf(Duration loop) => _clocks[loop]?.origin;

  /// The origin for this loop length, set to [timestamp] when there is none:
  /// the caller is about to show its frame 1 in the frame at [timestamp].
  Duration claimOrigin(Duration loop, Duration timestamp) =>
      (_clocks[loop] ??= _LoopClock()).origin ??= timestamp;

  void markShown(Duration loop) {
    (_clocks[loop] ??= _LoopClock()).shown += 1;
  }

  void markHidden(Duration loop) {
    final _LoopClock? clock = _clocks[loop];
    assert(clock != null && clock.shown > 0, 'markHidden without markShown.');
    if (clock == null) {
      return;
    }
    clock.shown -= 1;
    if (clock.shown > 0 || clock.resetCheckScheduled) {
      return;
    }
    // Checked at the end of the frame: a rebuild that replaces one emoji
    // widget with another (an edited message) passes through zero for a
    // moment, and must not restart the emoji that stay.
    clock.resetCheckScheduled = true;
    SchedulerBinding.instance
      ..addPostFrameCallback((Duration _) {
        clock.resetCheckScheduled = false;
        if (clock.shown == 0 && identical(_clocks[loop], clock)) {
          _clocks.remove(loop);
        }
      }, debugLabel: 'ForkSyncedEmojiClock.reset')
      ..ensureVisualUpdate();
  }

  @visibleForTesting
  void debugReset() {
    _clocks.clear();
  }
}

class _LoopClock {
  int shown = 0;
  Duration? origin;
  bool resetCheckScheduled = false;
}
