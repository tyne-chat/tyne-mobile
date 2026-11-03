// Fork: the timing maths behind synced animated emoji (tyne-chat/tyne#91).

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/media/fork_synced_emoji_timeline.dart';

ForkSyncedEmojiTimeline _timeline(
  List<int> durationsMs, {
  int repetitionCount = -1,
}) => ForkSyncedEmojiTimeline(
  <Duration>[for (final int ms in durationsMs) Duration(milliseconds: ms)],
  minimumFrameDuration: const Duration(milliseconds: 100),
  repetitionCount: repetitionCount,
);

void main() {
  test('gives the frame due and the time until the next', () {
    final ForkSyncedEmojiTimeline timeline = _timeline(<int>[30, 20, 70, 40]);

    expect(timeline.frameCount, 4);
    expect(timeline.loopDuration, const Duration(milliseconds: 160));
    expect(timeline.positionAt(Duration.zero), (
      index: 0,
      untilNext: const Duration(milliseconds: 30),
    ));
    expect(timeline.positionAt(const Duration(milliseconds: 29)).index, 0);
    expect(timeline.positionAt(const Duration(milliseconds: 30)), (
      index: 1,
      untilNext: const Duration(milliseconds: 20),
    ));
    expect(timeline.positionAt(const Duration(milliseconds: 119)).index, 2);
    expect(timeline.positionAt(const Duration(milliseconds: 150)), (
      index: 3,
      untilNext: const Duration(milliseconds: 10),
    ));
  });

  test('loops forever and wraps', () {
    final ForkSyncedEmojiTimeline timeline = _timeline(<int>[30, 20, 70, 40]);

    expect(timeline.loopsForever, isTrue);
    expect(timeline.positionAt(const Duration(milliseconds: 160)).index, 0);
    // 1650 ms is 50 ms into the eleventh loop.
    expect(timeline.positionAt(const Duration(milliseconds: 1650)), (
      index: 2,
      untilNext: const Duration(milliseconds: 70),
    ));
  });

  test('two emoji with the same frames agree at any time', () {
    final ForkSyncedEmojiTimeline left = _timeline(<int>[30, 20, 30, 70]);
    final ForkSyncedEmojiTimeline right = _timeline(<int>[30, 20, 30, 70]);

    for (int ms = 0; ms < 2000; ms += 7) {
      final Duration at = Duration(milliseconds: ms);
      expect(right.positionAt(at), left.positionAt(at), reason: '$ms ms');
    }
  });

  test(
    '10 ms or less counts as the minimum frame duration, as browsers do',
    () {
      final ForkSyncedEmojiTimeline timeline = _timeline(<int>[0, 10, 11]);

      expect(timeline.loopDuration, const Duration(milliseconds: 211));
      expect(timeline.positionAt(const Duration(milliseconds: 150)).index, 1);
    },
  );

  test('an animation that plays a set number of times stops on its last '
      'frame', () {
    final ForkSyncedEmojiTimeline timeline = _timeline(<int>[
      30,
      20,
    ], repetitionCount: 1);

    expect(timeline.loopsForever, isFalse);
    expect(timeline.positionAt(const Duration(milliseconds: 60)).index, 0);
    expect(timeline.positionAt(const Duration(milliseconds: 99)).index, 1);
    expect(timeline.positionAt(const Duration(milliseconds: 100)), (
      index: 1,
      untilNext: null,
    ));
    expect(timeline.positionAt(const Duration(seconds: 5)), (
      index: 1,
      untilNext: null,
    ));
  });

  test('a time before the origin counts as the origin', () {
    final ForkSyncedEmojiTimeline timeline = _timeline(<int>[30, 20]);

    expect(timeline.positionAt(const Duration(milliseconds: -5)).index, 0);
  });
}
