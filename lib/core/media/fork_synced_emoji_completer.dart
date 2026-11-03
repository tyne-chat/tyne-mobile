// Fork: an animated custom emoji that shows the frame its loop length's clock
// gives (tyne-chat/tyne#91).
//
// Upstream's completers (Flutter's and `cached_network_image_ce`'s) count
// frames from when each image starts, pause while nothing shows it and resume
// from the same frame, so two emoji started apart stay apart for the whole
// session. This one decodes a full loop once to learn the frame durations, then
// at every frame shows the frame its loop length's clock gives for that
// frame's timestamp, decoding forward to reach it. Emoji drawn in the same
// frame read the same timestamp, so equal loops cannot drift.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';
import 'package:fluxer_app/core/media/fork_synced_emoji_clock.dart';
import 'package:fluxer_app/core/media/fork_synced_emoji_timeline.dart';

class ForkSyncedEmojiCompleter extends ImageStreamCompleter {
  ForkSyncedEmojiCompleter({
    required Stream<ui.Codec> codecs,
    required this._scale,
    this._minimumFrameDuration = const Duration(milliseconds: 100),
    ForkSyncedEmojiClock? clock,
    this._informationCollector,
    this._onLoadFailed,
  }) : _clock = clock ?? ForkSyncedEmojiClock.instance {
    _subscription = codecs.listen(
      _handleCodec,
      onError: _handleLoadError,
      cancelOnError: true,
    );
  }

  final double _scale;
  final Duration _minimumFrameDuration;
  final ForkSyncedEmojiClock _clock;
  final InformationCollector? _informationCollector;
  final VoidCallback? _onLoadFailed;
  StreamSubscription<ui.Codec>? _subscription;

  ui.Codec? _codec;
  // A codec that arrived while a decode was running (the cache manager can
  // yield a refreshed file after the cached one); installed when it ends.
  ui.Codec? _queuedCodec;
  ForkSyncedEmojiTimeline? _timeline;
  // The frame the codec returns from its next `getNextFrame`: codecs only
  // decode forward, wrapping to frame 0 after the last.
  int _nextDecodeIndex = 0;
  ui.FrameInfo? _ready;
  int _readyIndex = -1;
  int? _shownIndex;
  // The origin of an animation that does not loop forever: its first frame.
  Duration? _ownOrigin;

  bool _decoding = false;
  // A frame was asked for while a decode was running.
  bool _frameWanted = false;
  bool _frameScheduled = false;
  Timer? _timer;
  // The loop length this image is counted as shown under, if it is.
  Duration? _countedLoop;
  bool _isDisposed = false;

  @override
  void addListener(ImageStreamListener listener) {
    final bool wasIdle = !hasListeners;
    super.addListener(listener);
    if (!wasIdle || _isDisposed) {
      return;
    }
    _updateShown();
    _scheduleFrame();
  }

  @override
  void removeListener(ImageStreamListener listener) {
    super.removeListener(listener);
    if (hasListeners) {
      return;
    }
    _timer?.cancel();
    _timer = null;
    _updateShown();
  }

  @override
  void onDisposed() {
    _isDisposed = true;
    _timer?.cancel();
    _timer = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
    _queuedCodec?.dispose();
    _queuedCodec = null;
    if (!_decoding) {
      _releaseCodec();
    }
    _updateShown();
    super.onDisposed();
  }

  // Counts the image as shown under its loop length's clock while a widget
  // listens to it and its loop is known; a play-once animation or a still
  // image follows no clock.
  void _updateShown() {
    final ForkSyncedEmojiTimeline? timeline = _timeline;
    final Duration? loop =
        !_isDisposed &&
            hasListeners &&
            timeline != null &&
            timeline.loopsForever
        ? timeline.loopDuration
        : null;
    final Duration? counted = _countedLoop;
    if (loop == counted) {
      return;
    }
    _countedLoop = loop;
    if (counted != null) {
      _clock.markHidden(counted);
    }
    if (loop != null) {
      _clock.markShown(loop);
    }
  }

  void _handleCodec(ui.Codec codec) {
    if (_isDisposed) {
      codec.dispose();
      return;
    }
    if (_decoding) {
      _queuedCodec?.dispose();
      _queuedCodec = codec;
      return;
    }
    _install(codec);
  }

  void _handleLoadError(Object error, StackTrace stack) {
    if (_isDisposed) {
      return;
    }
    reportError(
      context: ErrorDescription('resolving an image codec'),
      exception: error,
      stack: stack,
      informationCollector: _informationCollector,
      silent: true,
    );
    _onLoadFailed?.call();
  }

  void _install(ui.Codec codec) {
    _releaseCodec();
    _codec = codec;
    _timeline = null;
    _updateShown();
    _nextDecodeIndex = 0;
    _shownIndex = null;
    _ownOrigin = null;
    _decoding = true;
    unawaited(_prepare(codec));
  }

  void _releaseCodec() {
    _ready?.image.dispose();
    _ready = null;
    _readyIndex = -1;
    _codec?.dispose();
    _codec = null;
  }

  bool _isCurrent(ui.Codec codec) => !_isDisposed && identical(_codec, codec);

  // Decodes one full loop to learn the durations; the codec wraps back to
  // frame 0, which is kept ready.
  Future<void> _prepare(ui.Codec codec) async {
    ui.FrameInfo? first;
    try {
      final int frameCount = codec.frameCount;
      if (frameCount <= 1) {
        final ui.FrameInfo frame = await codec.getNextFrame();
        if (!_isCurrent(codec)) {
          frame.image.dispose();
          return;
        }
        setImage(ImageInfo(image: frame.image.clone(), scale: _scale));
        frame.image.dispose();
        _codec = null;
        codec.dispose();
        return;
      }
      final List<Duration> durations = <Duration>[];
      for (int index = 0; index < frameCount; index += 1) {
        final ui.FrameInfo frame = await codec.getNextFrame();
        if (!_isCurrent(codec)) {
          frame.image.dispose();
          return;
        }
        durations.add(frame.duration);
        if (index == 0) {
          first = frame;
        } else {
          frame.image.dispose();
        }
      }
      _timeline = ForkSyncedEmojiTimeline(
        durations,
        minimumFrameDuration: _minimumFrameDuration,
        repetitionCount: codec.repetitionCount,
      );
      _ready = first;
      _readyIndex = 0;
      first = null;
      _nextDecodeIndex = 0;
      _updateShown();
    } on Object catch (error, stack) {
      _reportFrameError(error, stack);
    } finally {
      first?.image.dispose();
      _decoding = false;
      _afterDecode(scheduleFrame: true);
    }
  }

  void _scheduleFrame() {
    if (_frameScheduled || _isDisposed || !hasListeners) {
      return;
    }
    _frameScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback(_handleFrame);
  }

  void _handleFrame(Duration timestamp) {
    _frameScheduled = false;
    final ForkSyncedEmojiTimeline? timeline = _timeline;
    if (_isDisposed || !hasListeners || timeline == null) {
      return;
    }
    Duration? origin = timeline.loopsForever
        ? _clock.originOf(timeline.loopDuration)
        : _ownOrigin;
    if (origin == null) {
      // Starting from frame 1: wait until it is decoded, so the origin is the
      // frame it is actually shown in.
      if (_ready == null || _readyIndex != 0) {
        _decodeTo(0, scheduleFrame: true);
        return;
      }
      origin = timeline.loopsForever
          ? _clock.claimOrigin(timeline.loopDuration, timestamp)
          : (_ownOrigin = timestamp);
    }
    final ForkSyncedEmojiPosition position = timeline.positionAt(
      timestamp - origin,
    );
    if (position.index != _shownIndex) {
      if (_ready == null || _readyIndex != position.index) {
        _decodeTo(position.index, scheduleFrame: true);
        return;
      }
      _emitReady();
      // Listeners are told synchronously; one may have left.
      if (_isDisposed || !hasListeners) {
        return;
      }
    }
    final Duration? untilNext = position.untilNext;
    if (untilNext == null) {
      return;
    }
    _decodeTo((position.index + 1) % timeline.frameCount, scheduleFrame: false);
    _timer?.cancel();
    _timer = Timer(untilNext * timeDilation, _scheduleFrame);
  }

  void _emitReady() {
    final ui.FrameInfo frame = _ready!;
    _ready = null;
    _shownIndex = _readyIndex;
    _readyIndex = -1;
    setImage(ImageInfo(image: frame.image.clone(), scale: _scale));
    frame.image.dispose();
  }

  // Decodes forward to frame [target] and keeps it ready. With
  // [scheduleFrame], a frame is scheduled when it is ready to be shown.
  void _decodeTo(int target, {required bool scheduleFrame}) {
    if (_decoding) {
      // The running decode schedules a frame when it ends.
      _frameWanted = _frameWanted || scheduleFrame;
      return;
    }
    if (_ready != null && _readyIndex == target) {
      if (scheduleFrame) {
        _scheduleFrame();
      }
      return;
    }
    final ui.Codec? codec = _codec;
    final ForkSyncedEmojiTimeline? timeline = _timeline;
    if (codec == null || timeline == null) {
      return;
    }
    _decoding = true;
    unawaited(
      _decodeForward(
        codec,
        frameCount: timeline.frameCount,
        target: target,
        scheduleFrame: scheduleFrame,
      ),
    );
  }

  Future<void> _decodeForward(
    ui.Codec codec, {
    required int frameCount,
    required int target,
    required bool scheduleFrame,
  }) async {
    try {
      _ready?.image.dispose();
      _ready = null;
      _readyIndex = -1;
      while (_nextDecodeIndex != target) {
        final ui.FrameInfo skipped = await codec.getNextFrame();
        skipped.image.dispose();
        _nextDecodeIndex = (_nextDecodeIndex + 1) % frameCount;
        if (!_isCurrent(codec)) {
          return;
        }
      }
      final ui.FrameInfo frame = await codec.getNextFrame();
      _nextDecodeIndex = (_nextDecodeIndex + 1) % frameCount;
      if (!_isCurrent(codec)) {
        frame.image.dispose();
        return;
      }
      _ready = frame;
      _readyIndex = target;
    } on Object catch (error, stack) {
      _reportFrameError(error, stack);
    } finally {
      _decoding = false;
      _afterDecode(scheduleFrame: scheduleFrame);
    }
  }

  void _afterDecode({required bool scheduleFrame}) {
    if (_isDisposed) {
      _releaseCodec();
      _queuedCodec?.dispose();
      _queuedCodec = null;
      return;
    }
    final ui.Codec? queued = _queuedCodec;
    if (queued != null) {
      _queuedCodec = null;
      _install(queued);
      return;
    }
    if (scheduleFrame || _frameWanted) {
      _frameWanted = false;
      _scheduleFrame();
    }
  }

  void _reportFrameError(Object error, StackTrace stack) {
    if (_isDisposed) {
      return;
    }
    reportError(
      context: ErrorDescription('resolving an image frame'),
      exception: error,
      stack: stack,
      informationCollector: _informationCollector,
      silent: true,
    );
  }
}
