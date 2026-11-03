// Fork: animated custom emoji follow the clock of their loop length
// (tyne-chat/tyne#91).

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/media/fork_synced_emoji_clock.dart';
import 'package:fluxer_app/core/media/fork_synced_emoji_completer.dart';
import 'package:fluxer_app/core/media/fork_synced_emoji_timeline.dart';

import 'fork_synced_emoji_test_support.dart';

// The wings' rhythm, shortened: frames end at 30, 50, 120 and 160 ms.
const List<int> _wingsMs = <int>[30, 20, 70, 40];

final ForkSyncedEmojiTimeline _wings = ForkSyncedEmojiTimeline(const <Duration>[
  Duration(milliseconds: 30),
  Duration(milliseconds: 20),
  Duration(milliseconds: 70),
  Duration(milliseconds: 40),
], minimumFrameDuration: const Duration(milliseconds: 100));

final Duration _wingsLoop = _wings.loopDuration;

// A sleeping cat: two quick frames, then a long rest on the last one.
const List<int> _nekoMs = <int>[40, 40, 600];

/// The timestamp of the last frame drawn, as frame callbacks see it.
Duration _lastFrame = Duration.zero;

/// The emoji of the running test.
final List<_Emoji> _live = <_Emoji>[];

void _disposeAll() {
  for (final _Emoji emoji in _live) {
    emoji.dispose();
  }
  _live.clear();
}

/// A widget test whose emoji are disposed when it ends: before the check for
/// pending timers when it passes, and in a tear-down when it fails, so
/// nothing it scheduled runs in the next test.
void _emojiTest(
  String description,
  Future<void> Function(WidgetTester tester) body,
) {
  testWidgets(description, (WidgetTester tester) async {
    addTearDown(_disposeAll);
    await body(tester);
    _disposeAll();
  });
}

/// One emoji image as the image cache holds it: a completer, a keep-alive
/// handle (the cache's), and a recorder that is listening or not.
class _Emoji {
  _Emoji(this.clock, {FakeSyncedEmojiCodec? codec, Stream<ui.Codec>? codecs})
    : codec = codec ?? FakeSyncedEmojiCodec(_wingsMs) {
    completer = ForkSyncedEmojiCompleter(
      codecs: codecs ?? Stream<ui.Codec>.value(this.codec),
      scale: 1,
      clock: clock,
      onLoadFailed: () => loadFailures += 1,
    );
    handle = completer.keepAlive();
    _live.add(this);
  }

  final ForkSyncedEmojiClock clock;
  final FakeSyncedEmojiCodec codec;
  late final ForkSyncedEmojiCompleter completer;
  late final ImageStreamCompleterHandle handle;
  final SyncedEmojiFrameRecorder recorder = SyncedEmojiFrameRecorder();
  int loadFailures = 0;
  bool _listening = false;
  bool _disposed = false;

  void show() {
    _listening = true;
    completer.addListener(recorder.listener);
  }

  void hide() {
    _listening = false;
    completer.removeListener(recorder.listener);
  }

  int? get frame => recorder.last;

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    if (_listening) {
      hide();
    }
    handle.dispose();
  }
}

/// The frame the clock gives at the last frame drawn.
int _clockFrame(ForkSyncedEmojiClock clock) =>
    _wings.positionAt(_lastFrame - clock.originOf(_wingsLoop)!).index;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized().addPersistentFrameCallback((
    Duration timestamp,
  ) {
    _lastFrame = timestamp;
  });

  setUpAll(createSyncedEmojiFrameImages);

  // A pump draws a frame only when one was scheduled before it started; a
  // frame an emoji asks for once its codec or a decoded frame arrives is drawn
  // by the next pump. On a phone that is the next screen refresh.
  Future<void> settle(WidgetTester tester) => tester.pump();

  _emojiTest('starts at frame 1 and follows the frame durations', (
    WidgetTester tester,
  ) async {
    final ForkSyncedEmojiClock clock = ForkSyncedEmojiClock();
    final _Emoji emoji = _Emoji(clock)..show();

    await tester.pump();
    expect(emoji.frame, 0);
    expect(clock.originOf(_wingsLoop), _lastFrame);

    final List<int> seen = <int>[];
    for (final int step in <int>[29, 1, 20, 70, 40, 30]) {
      await tester.pump(Duration(milliseconds: step));
      seen.add(emoji.frame!);
    }
    // 29 ms: still 0; 30: 1; 50: 2; 120: 3; 160: 0 again; 190: 1.
    expect(seen, <int>[0, 1, 2, 3, 0, 1]);
  });

  _emojiTest('an emoji that starts later shows the same frame as the first', (
    WidgetTester tester,
  ) async {
    final ForkSyncedEmojiClock clock = ForkSyncedEmojiClock();
    final _Emoji left = _Emoji(clock)..show();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 370));

    final _Emoji right = _Emoji(clock)..show();
    await tester.pump();
    await settle(tester);
    expect(right.recorder.shown.first, isNot(0));

    for (int step = 0; step < 40; step += 1) {
      await tester.pump(const Duration(milliseconds: 7));
      expect(right.frame, left.frame, reason: 'step $step');
      expect(left.frame, _clockFrame(clock), reason: 'step $step');
    }
  });

  _emojiTest('an emoji that comes back joins the one still on screen', (
    WidgetTester tester,
  ) async {
    final ForkSyncedEmojiClock clock = ForkSyncedEmojiClock();
    final _Emoji left = _Emoji(clock)..show();
    final _Emoji right = _Emoji(clock)..show();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 45));
    final Duration origin = clock.originOf(_wingsLoop)!;

    right.hide();
    await tester.pump(const Duration(milliseconds: 2500));
    right.show();
    await tester.pump();
    await settle(tester);

    expect(clock.originOf(_wingsLoop), origin);
    for (int step = 0; step < 30; step += 1) {
      await tester.pump(const Duration(milliseconds: 11));
      expect(right.frame, left.frame, reason: 'step $step');
      expect(left.frame, _clockFrame(clock), reason: 'step $step');
    }
  });

  _emojiTest('with nothing on screen, the next emoji starts at frame 1', (
    WidgetTester tester,
  ) async {
    final ForkSyncedEmojiClock clock = ForkSyncedEmojiClock();
    final _Emoji emoji = _Emoji(clock)..show();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));
    await settle(tester);
    expect(emoji.frame, 2);

    emoji.hide();
    await tester.pump();
    expect(clock.shownCount(_wingsLoop), 0);
    expect(clock.originOf(_wingsLoop), isNull);

    await tester.pump(const Duration(seconds: 1));
    emoji.show();
    await tester.pump();
    await settle(tester);

    expect(emoji.frame, 0);
    expect(clock.originOf(_wingsLoop), _lastFrame);
  });

  _emojiTest('a swap within one frame does not restart the clock', (
    WidgetTester tester,
  ) async {
    final ForkSyncedEmojiClock clock = ForkSyncedEmojiClock();
    final _Emoji kept = _Emoji(clock)..show();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));
    await settle(tester);
    final Duration origin = clock.originOf(_wingsLoop)!;

    // An edit rebuilds the row: the old widget stops listening and the new
    // one starts before the frame ends.
    kept.hide();
    final _Emoji added = _Emoji(clock)..show();
    kept.show();
    await tester.pump();
    await settle(tester);

    expect(clock.originOf(_wingsLoop), origin);
    for (int step = 0; step < 20; step += 1) {
      await tester.pump(const Duration(milliseconds: 13));
      expect(kept.frame, _clockFrame(clock), reason: 'step $step');
      expect(added.frame, kept.frame, reason: 'step $step');
    }
  });

  _emojiTest('an emoji with another loop length starts at frame 1 while '
      'others play, and one with its loop length joins it', (
    WidgetTester tester,
  ) async {
    final ForkSyncedEmojiClock clock = ForkSyncedEmojiClock();
    final _Emoji wings = _Emoji(clock)..show();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));
    await settle(tester);
    final Duration wingsOrigin = clock.originOf(_wingsLoop)!;

    final _Emoji neko = _Emoji(clock, codec: FakeSyncedEmojiCodec(_nekoMs))
      ..show();
    await tester.pump();
    expect(neko.frame, 0);
    expect(clock.originOf(_wingsLoop), wingsOrigin);
    expect(wings.frame, _clockFrame(clock));

    for (final int step in <int>[40, 40, 220]) {
      await tester.pump(Duration(milliseconds: step));
    }
    expect(neko.recorder.shown, <int>[0, 1, 2]);

    // A second cat, 300 ms in: it joins the first on its long last frame.
    final _Emoji second = _Emoji(clock, codec: FakeSyncedEmojiCodec(_nekoMs))
      ..show();
    await tester.pump();
    await settle(tester);
    expect(second.frame, 2);
    for (int step = 0; step < 50; step += 1) {
      await tester.pump(const Duration(milliseconds: 17));
      expect(second.frame, neko.frame, reason: 'step $step');
      expect(wings.frame, _clockFrame(clock), reason: 'step $step');
    }
  });

  _emojiTest('each loop length restarts on its own', (
    WidgetTester tester,
  ) async {
    final ForkSyncedEmojiClock clock = ForkSyncedEmojiClock();
    final _Emoji wings = _Emoji(clock)..show();
    final _Emoji neko = _Emoji(clock, codec: FakeSyncedEmojiCodec(_nekoMs))
      ..show();
    await tester.pump();
    final Duration nekoLoop = ForkSyncedEmojiTimeline(<Duration>[
      for (final int ms in _nekoMs) Duration(milliseconds: ms),
    ], minimumFrameDuration: const Duration(milliseconds: 100)).loopDuration;
    final Duration nekoOrigin = clock.originOf(nekoLoop)!;

    wings.hide();
    await tester.pump();

    expect(clock.originOf(_wingsLoop), isNull);
    expect(clock.shownCount(_wingsLoop), 0);
    expect(clock.originOf(nekoLoop), nekoOrigin);
    expect(clock.shownCount(nekoLoop), 1);
    expect(neko.frame, isNotNull);
  });

  _emojiTest(
    'the clock starts when frame 1 is shown, not when loading starts',
    (WidgetTester tester) async {
      final ForkSyncedEmojiClock clock = ForkSyncedEmojiClock();
      final StreamController<ui.Codec> codecs = StreamController<ui.Codec>();
      addTearDown(codecs.close);
      final FakeSyncedEmojiCodec codec = FakeSyncedEmojiCodec(_wingsMs);
      final _Emoji emoji = _Emoji(clock, codec: codec, codecs: codecs.stream)
        ..show();

      await tester.pump(const Duration(milliseconds: 500));
      expect(emoji.frame, isNull);
      expect(clock.originOf(_wingsLoop), isNull);

      codecs.add(codec);
      await tester.pump();
      await settle(tester);
      expect(emoji.frame, 0);
      expect(clock.originOf(_wingsLoop), _lastFrame);
    },
  );

  _emojiTest('an animation that plays once starts on its own and stays on its '
      'last frame', (WidgetTester tester) async {
    final ForkSyncedEmojiClock clock = ForkSyncedEmojiClock();
    _Emoji(clock).show();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));

    final _Emoji once = _Emoji(
      clock,
      codec: FakeSyncedEmojiCodec(_wingsMs, repetitionCount: 0),
    )..show();
    await tester.pump();
    expect(once.frame, 0);

    for (final int step in <int>[30, 20, 70]) {
      await tester.pump(Duration(milliseconds: step));
    }
    expect(once.frame, 3);
    await tester.pump(const Duration(milliseconds: 500));
    expect(once.frame, 3);
    expect(once.recorder.shown, <int>[0, 1, 2, 3]);
  });

  _emojiTest('a still image is shown once', (WidgetTester tester) async {
    final ForkSyncedEmojiClock clock = ForkSyncedEmojiClock();
    final FakeSyncedEmojiCodec codec = FakeSyncedEmojiCodec(<int>[0]);
    final _Emoji emoji = _Emoji(clock, codec: codec)..show();

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(emoji.recorder.shown, <int>[0]);
    expect(codec.decodes, 1);
    expect(codec.disposed, isTrue);
  });

  _emojiTest('disposed while a frame decodes: the codec is released and '
      'nothing is shown', (WidgetTester tester) async {
    final ForkSyncedEmojiClock clock = ForkSyncedEmojiClock();
    final FakeSyncedEmojiCodec codec = FakeSyncedEmojiCodec(_wingsMs)
      ..gate = Completer<void>();
    final _Emoji emoji = _Emoji(clock, codec: codec)..show();
    await tester.pump();

    emoji.dispose();
    expect(codec.disposed, isFalse);

    codec.gate!.complete();
    await tester.pump();

    expect(codec.disposed, isTrue);
    expect(emoji.recorder.shown, isEmpty);
    expect(clock.shownCount(_wingsLoop), 0);
  });

  _emojiTest('a failed load is reported and asks to be evicted', (
    WidgetTester tester,
  ) async {
    final ForkSyncedEmojiClock clock = ForkSyncedEmojiClock();
    final _Emoji emoji = _Emoji(
      clock,
      codecs: Stream<ui.Codec>.error(StateError('download failed')),
    )..show();

    await tester.pump();

    expect(emoji.recorder.errors, hasLength(1));
    expect(emoji.loadFailures, 1);
    expect(emoji.recorder.shown, isEmpty);
  });
}
