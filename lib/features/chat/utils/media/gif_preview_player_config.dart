import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

// Fork imports.
// ignore: directives_ordering
import 'package:fluxer_app/core/instance/instance_constants.dart';
import 'package:media_kit_video/media_kit_video.dart' as mkv;

const int gifPreviewPlayerBufferSize = 4 * 1024 * 1024;

// Fork: media_kit's name for the player's process, which desktop volume mixers
// show; not text inside the app.
// i18n-ignore: a process name, as above.
const String _forkGifPreviewPlayerTitle =
    '${InstanceConstants.defaultProductName} GIF preview';

const PlayerConfiguration gifPreviewPlayerConfiguration = PlayerConfiguration(
  muted: true,
  bufferSize: gifPreviewPlayerBufferSize,
  title: _forkGifPreviewPlayerTitle,
);

mkv.VideoControllerConfiguration gifPreviewVideoControllerConfiguration() =>
    gifPreviewVideoControllerConfigurationFor(defaultTargetPlatform);

mkv.VideoControllerConfiguration gifPreviewVideoControllerConfigurationFor(
  TargetPlatform platform,
) => switch (platform) {
  TargetPlatform.android => const mkv.VideoControllerConfiguration(
    vo: 'gpu',
    hwdec: 'auto-safe',
  ),
  _ => const mkv.VideoControllerConfiguration(),
};
