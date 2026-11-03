// Fork: the app's binding installs the image cache that keeps animated custom
// emoji in step (tyne-chat/tyne#91). Without it, the emoji fall back to
// upstream's timing and drift apart, with nothing else failing.

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/media/fork_synced_emoji_image_cache.dart';
import 'package:fluxer_app/core/zoom/fluxer_app_zoom.dart';

void main() {
  test('the app binding installs the synced emoji image cache', () {
    FluxerAppZoomBinding.ensureInitialized();

    expect(
      PaintingBinding.instance.imageCache,
      isA<ForkSyncedEmojiImageCache>(),
    );
  });
}
