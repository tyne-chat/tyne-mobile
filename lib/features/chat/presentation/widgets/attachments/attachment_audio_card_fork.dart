// Fork (tyne-chat/tyne#873): the audio attachment card with the file's cover art and its waveform.
//
// It takes the place of upstream's card body in `attachment_audio.dart` (one hand-over line), with the
// same controller, play and download callbacks, so playback and downloads stay upstream's.
//
// - A title row: the round play button and the file name, on up to two lines, its extension never cut
//   off. Tapping anywhere in the row plays or pauses; the play button stays the control screen readers
//   use. Long-press still reaches the message's menu.
// - Below it, the sound's waveform as the seek bar (seeking works while it plays, as upstream's bar),
//   lit in the accent colour while playing and grey while paused. A link to an audio attachment
//   (an embed) loads the linked file's waveform once (`attachment_linked_waveform_fork.dart`).
// - On the right, the cover, spanning the title row and the waveform, when the server kept one
//   (`kForkAttachmentFlagHasCover` in `attachment_cover_fork.dart`). Tapping it opens the cover full screen.
// - At the bottom, the time on the left, then speed and download; phones have volume buttons, and
//   the row has no room for upstream's volume control on a narrow phone.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/api/attachment_request_auth.dart';
import 'package:fluxer_app/core/audio/chat_attachment/chat_attachment_audio_controller.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/media/chat_network_image.dart';
import 'package:fluxer_app/features/chat/utils/attachments/attachment_cover_fork.dart';
import 'package:fluxer_app/features/chat/utils/attachments/attachment_display_utils.dart';
import 'package:fluxer_app/features/chat/utils/attachments/attachment_linked_waveform_fork.dart';
import 'package:fluxer_app/features/chat/utils/attachments/voice_message_constants.dart';
import 'package:fluxer_app/features/chat/utils/attachments/voice_message_waveform.dart';
import 'package:fluxer_app/features/chat/utils/media/fork_media_proxy_sizing.dart';
import 'package:fluxer_app/features/chat/utils/media/fork_rendered_thumbnail_registry.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/icons/phosphor.dart';
import 'package:fluxer_app/shared/widgets/playback_seek_gesture_target.dart';
import 'package:fluxer_app/shared/widgets/rebuild_safe_layout_builder.dart';

const double _kCoverSize = 76;
const double _kWaveformHeight = 26;
const double _kBarPitch = 4;

/// The longest start of [stem] that, followed by `…` and [extension], [fits]; [stem] itself when
/// it fits whole.
String forkTruncateAudioStem(
  String stem,
  String extension,
  bool Function(String text) fits,
) {
  if (fits('$stem$extension')) {
    return stem;
  }
  int low = 0;
  int high = stem.length;
  while (low < high) {
    final int middle = (low + high + 1) ~/ 2;
    if (fits('${stem.substring(0, middle)}…$extension')) {
      low = middle;
    } else {
      high = middle - 1;
    }
  }
  return '${stem.substring(0, low)}…';
}

/// [values] (0 to 255) drawn as [count] bars, each the average of the values it covers.
List<int> forkResampleWaveform(List<int> values, int count) {
  if (count <= 0 || values.isEmpty) {
    return const <int>[];
  }
  final List<int> bars = List<int>.filled(count, 0);
  for (int bar = 0; bar < count; bar++) {
    final double start = bar * values.length / count;
    final double end = (bar + 1) * values.length / count;
    double sum = 0;
    double weight = 0;
    for (
      int point = start.floor();
      point < end.ceil() && point < values.length;
      point++
    ) {
      final double share =
          math.min(end, point + 1.0) - math.max(start, point.toDouble());
      if (share <= 0) {
        continue;
      }
      sum += values[point] * share;
      weight += share;
    }
    bars[bar] = weight > 0 ? (sum / weight).round() : 0;
  }
  return bars;
}

class ForkAttachmentAudioCard extends StatelessWidget {
  const ForkAttachmentAudioCard({
    required this.controller,
    required this.attachment,
    required this.onTogglePlayback,
    required this.onDownload,
    super.key,
  });

  final ChatAttachmentAudioController controller;
  final Attachment attachment;
  final VoidCallback onTogglePlayback;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final bool hasCover = forkAttachmentHasCover(attachment);
    return RepaintBoundary(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.only(right: 12, left: 12, top: 12, bottom: 6),
        decoration: BoxDecoration(
          color: colors.backgroundSecondary,
          border: Border.all(color: colors.backgroundModifierAccent),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ValueListenableBuilder<Duration>(
          valueListenable: controller.position.notifier,
          builder: (BuildContext context, Duration position, Widget? child) {
            final double progress = controller.duration.inMilliseconds <= 0
                ? 0
                : (position.inMilliseconds / controller.duration.inMilliseconds)
                      .clamp(0, 1)
                      .toDouble();
            final String timeText = formatAttachmentElapsedTotalMmSs(
              elapsed: position,
              total: controller.duration,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onTogglePlayback,
                            child: Row(
                              children: [
                                FluxerButton.circle(
                                  onPressed: onTogglePlayback,
                                  size: FluxerButtonSize.compact,
                                  isLoading: controller.isLoading,
                                  icon: controller.isPlaying
                                      ? PhosphorIconsFill.pause
                                      : PhosphorIconsFill.play,
                                  semanticLabel: controller.isPlaying
                                      ? l10n.uiPause
                                      : l10n.uiPlay,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ForkAudioName(
                                    filename: attachment.filename,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          PlaybackSeekGestureTarget(
                            enabled: controller.isPlaying,
                            onSeekFraction: (double fraction) {
                              unawaited(
                                controller.seekToRelativePosition(fraction),
                              );
                            },
                            child: forkAttachmentHasLinkedWaveform(attachment)
                                ? _ForkLinkedAudioWaveform(
                                    attachment: attachment,
                                    progress: progress,
                                    playing: controller.isPlaying,
                                  )
                                : _ForkAudioWaveform(
                                    waveform: attachment.waveform,
                                    progress: progress,
                                    playing: controller.isPlaying,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    if (hasCover) ...[
                      const SizedBox(width: 10),
                      _ForkAudioCover(attachment: attachment),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        timeText,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: context.textStyles.smallText.copyWith(
                          color: colors.textTertiary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: controller.cyclePlaybackRate,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(44, 28),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(
                        '${controller.playbackRate}x',
                        style: context.textStyles.smallText.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: l10n.uiDownload,
                      child: FluxerButton.circle(
                        onPressed: onDownload,
                        variant: FluxerButtonVariant.ghost,
                        size: FluxerButtonSize.compact,
                        icon: PhosphorIconsBold.downloadSimple,
                        semanticLabel: l10n.uiDownload,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The file name on up to two lines, its extension always showing: when the name is too long, its
/// end is cut and `…` put before the extension. The first line uses the full width.
class _ForkAudioName extends StatelessWidget {
  const _ForkAudioName({required this.filename});

  final String filename;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (String stem, String extension) =
        splitAttachmentFilenameStemAndExtension(filename);
    final TextStyle stemStyle = context.textStyles.bodySmall.copyWith(
      color: colors.textPrimary,
      fontWeight: FontWeight.w600,
    );
    final TextStyle extensionStyle = context.textStyles.bodySmall.copyWith(
      color: colors.textTertiary,
      fontWeight: FontWeight.w500,
    );
    final TextScaler textScaler = MediaQuery.textScalerOf(context);
    final TextDirection textDirection = Directionality.of(context);
    return RebuildSafeLayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        String shown = stem;
        if (constraints.hasBoundedWidth) {
          shown = forkTruncateAudioStem(stem, extension, (String text) {
            final int split = text.length - extension.length;
            final TextPainter painter = TextPainter(
              text: TextSpan(
                children: [
                  TextSpan(text: text.substring(0, split), style: stemStyle),
                  TextSpan(text: extension, style: extensionStyle),
                ],
              ),
              maxLines: 2,
              textDirection: textDirection,
              textScaler: textScaler,
            )..layout(maxWidth: constraints.maxWidth);
            final bool fits = !painter.didExceedMaxLines;
            painter.dispose();
            return fits;
          });
        }
        return Text.rich(
          TextSpan(
            children: [
              TextSpan(text: shown, style: stemStyle),
              TextSpan(text: extension, style: extensionStyle),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.clip,
        );
      },
    );
  }
}

/// The seek bar of a link to an audio attachment: its waveform once loaded, a plain bar until then
/// or when it cannot be (`attachment_linked_waveform_fork.dart`).
class _ForkLinkedAudioWaveform extends ConsumerWidget {
  const _ForkLinkedAudioWaveform({
    required this.attachment,
    required this.progress,
    required this.playing,
  });

  final Attachment attachment;
  final double progress;
  final bool playing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<String?> loaded = ref.watch(
      forkLinkedWaveformProvider(forkLinkedWaveformKey(attachment)),
    );
    return _ForkAudioWaveform(
      waveform: loaded is AsyncData<String?> ? loaded.value : null,
      progress: progress,
      playing: playing,
    );
  }
}

/// The seek bar drawn as the waveform; a plain bar when the attachment has none.
class _ForkAudioWaveform extends StatelessWidget {
  const _ForkAudioWaveform({
    required this.waveform,
    required this.progress,
    required this.playing,
  });

  final String? waveform;
  final double progress;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color played = playing ? colors.brandPrimary : colors.textSecondary;
    final Color unplayed = colors.textTertiary.withValues(alpha: 0.45);
    final List<int> points = waveform == null || waveform!.isEmpty
        ? const <int>[]
        : decodeVoiceMessageWaveform(waveform!);
    if (points.isEmpty) {
      return SizedBox(
        height: _kWaveformHeight,
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: unplayed,
              valueColor: AlwaysStoppedAnimation<Color>(played),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: _kWaveformHeight,
      child: RebuildSafeLayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final int count = constraints.hasBoundedWidth
              ? (constraints.maxWidth / _kBarPitch).floor().clamp(12, 120)
              : 48;
          final List<int> bars = forkResampleWaveform(points, count);
          return Row(
            textDirection: TextDirection.ltr,
            children: List<Widget>.generate(bars.length, (int index) {
              final double ratio = math.max(
                kVoiceMessagePlayerMinBarHeightRatio,
                bars[index] / 255,
              );
              final bool isPlayed = (index + 0.5) / bars.length <= progress;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0.75),
                  child: Align(
                    child: SizedBox(
                      height: _kWaveformHeight * ratio,
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: isPlayed ? played : unplayed,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// The cover, which opens full screen. A cover that fails to load shows nothing, once: the image
/// widget backs off its retries itself.
class _ForkAudioCover extends StatelessWidget {
  const _ForkAudioCover({required this.attachment});

  final Attachment attachment;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final double pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final String fullCoverUrl = forkAttachmentCoverUrl(attachment);
    final bool isApiRoute = AttachmentRequestAuth.isApiAttachmentUrl(
      fullCoverUrl,
    );
    final int? snappedWidth = isApiRoute
        ? null
        : forkSnapMediaProxyImageSize(_kCoverSize, pixelRatio);
    final String thumbnail = forkAttachmentCoverUrl(
      attachment,
      width: snappedWidth,
    );
    final int memCacheWidth = (_kCoverSize * pixelRatio).ceil();
    return Semantics(
      button: true,
      label: FluxerLocalizations.of(context).fork.chatAudioViewCover,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          unawaited(
            showAttachmentMediaViewer(
              context,
              items: [
                AttachmentMediaViewerItem(
                  forkPreview: isApiRoute
                      ? null
                      : ForkThumbnailDescriptor(
                          url: thumbnail,
                          memCacheWidth: memCacheWidth,
                        ),
                  url: fullCoverUrl,
                  filename: attachment.filename,
                  contentType: 'image/webp',
                ),
              ],
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox.square(
            dimension: _kCoverSize,
            child: ColoredBox(
              color: colors.backgroundTertiary,
              child: ChatNetworkImage(
                imageUrl: thumbnail,
                filename: attachment.filename,
                contentType: 'image/webp',
                width: _kCoverSize,
                height: _kCoverSize,
                fit: BoxFit.cover,
                memCacheWidth: memCacheWidth,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
