// Fork: fakes for the synced emoji tests (tyne-chat/tyne#91).

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// One test image per frame index, `index + 1` pixels wide, so a shown frame
/// tells which index it is.
final List<ui.Image> _frameImages = <ui.Image>[];

/// Creates the frame images; call from `setUpAll`.
Future<void> createSyncedEmojiFrameImages({int count = 8}) async {
  for (int index = _frameImages.length; index < count; index += 1) {
    _frameImages.add(await createTestImage(width: index + 1, cache: false));
  }
}

/// The frame index an image shown by a fake codec stands for.
int syncedEmojiFrameIndexOf(ui.Image image) => image.width - 1;

class FakeSyncedEmojiFrame implements ui.FrameInfo {
  FakeSyncedEmojiFrame(this.duration, this.image);

  @override
  final Duration duration;

  @override
  final ui.Image image;
}

/// A codec that decodes forward and wraps after the last frame, like the
/// engine's. A [gate] holds every decode until it completes.
class FakeSyncedEmojiCodec implements ui.Codec {
  FakeSyncedEmojiCodec(this.durationsMs, {this.repetitionCount = -1});

  final List<int> durationsMs;

  @override
  final int repetitionCount;

  int _next = 0;
  int decodes = 0;
  bool disposed = false;
  Completer<void>? gate;

  @override
  int get frameCount => durationsMs.length;

  @override
  Future<ui.FrameInfo> getNextFrame() async {
    final Completer<void>? held = gate;
    if (held != null) {
      await held.future;
    }
    final int index = _next;
    _next = (_next + 1) % frameCount;
    decodes += 1;
    return FakeSyncedEmojiFrame(
      Duration(milliseconds: durationsMs[index]),
      _frameImages[index].clone(),
    );
  }

  @override
  void dispose() {
    disposed = true;
  }
}

/// Records the frame indices an image stream shows.
class SyncedEmojiFrameRecorder {
  final List<int> shown = <int>[];
  final List<Object> errors = <Object>[];

  late final ImageStreamListener listener = ImageStreamListener((
    ImageInfo info,
    bool synchronousCall,
  ) {
    shown.add(syncedEmojiFrameIndexOf(info.image));
    info.dispose();
  }, onError: (Object error, StackTrace? stack) => errors.add(error));

  int? get last => shown.isEmpty ? null : shown.last;
}
