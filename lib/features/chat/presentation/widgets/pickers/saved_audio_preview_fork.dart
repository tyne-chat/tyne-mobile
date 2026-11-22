// Fork (tyne-chat/tyne#879): a saved audio file in the Media tab shows its cover art, or else its
// waveform, instead of upstream's music note.
//
// It takes the place of upstream's `_AudioPreview` (one hand-over line in
// `favorite_media_picker_content.dart`), which keeps drawing the saved item's name along the bottom
// of the tile.
//
// - With a cover: the cover fills the tile, with the file's format and length on top of it.
// - Without one: the waveform, with the length, format and file name under it.
//
// A saved item does not say whether it has a cover or a waveform, so a tile on screen asks the media
// proxy (one off screen loads nothing):
// the cover from the saved file's own URL with `cover=1`, the waveform with `waveform=1`
// (`attachment_linked_waveform_fork.dart`, once per file). A cover that is not there is remembered for
// as long as the app runs, so each file costs at most one cover request and, without a cover, one
// waveform request. They go to the media proxy, not the API.

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/api/attachment_request_auth.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/domain/favorite_meme.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/attachments/attachment_audio_card_fork.dart';
import 'package:fluxer_app/features/chat/utils/attachments/attachment_cover_fork.dart';
import 'package:fluxer_app/features/chat/utils/attachments/attachment_linked_waveform_fork.dart';
import 'package:fluxer_app/features/chat/utils/attachments/voice_message_waveform.dart';
import 'package:fluxer_app/features/chat/utils/media/media_proxy_url.dart';
import 'package:fluxer_app/material_ui.dart';

/// The cover is fetched this wide; tiles are at most about half the screen.
const int _kCoverWidth = 320;
const int _kWaveformBars = 32;

final Set<String> _missingCovers = <String>{};

String _fileKey(String url) {
  final Uri? parsed = Uri.tryParse(url);
  return parsed == null ? url : parsed.replace(query: '').toString();
}

/// Whether the saved file at [url] was found to have no cover while the app runs.
bool forkSavedAudioCoverMissing(String url) =>
    _missingCovers.contains(_fileKey(url));

/// Remembers that the saved file at [url] has no cover, so it is not asked for again.
void forkMarkSavedAudioCoverMissing(String url) =>
    _missingCovers.add(_fileKey(url));

/// For tests: forgets the covers found missing.
@visibleForTesting
void forkForgetMissingSavedAudioCovers() => _missingCovers.clear();

/// The URL of the cover of the saved file at [url], [width] pixels wide as a WebP.
String forkSavedAudioCoverUrl(String url, {int width = _kCoverWidth}) {
  final Uri? parsed = Uri.tryParse(url);
  if (parsed == null || !parsed.hasScheme) {
    return '';
  }
  final Map<String, String> query = Map<String, String>.from(
    parsed.queryParameters,
  )..[kForkAttachmentCoverParameter] = '1';
  return buildMediaProxyUrl(
    parsed.replace(queryParameters: query).toString(),
    width: width,
    format: 'webp',
  );
}

/// The file's format as a badge shows it: its extension, upper case, or the content type's subtype.
String forkSavedAudioFormat(FavoriteMeme meme) {
  final int dot = meme.filename.lastIndexOf('.');
  if (dot > 0 && dot < meme.filename.length - 1) {
    return meme.filename.substring(dot + 1).toUpperCase();
  }
  final int slash = meme.contentType.indexOf('/');
  return (slash >= 0 ? meme.contentType.substring(slash + 1) : meme.contentType)
      .toUpperCase();
}

String _formatLength(double seconds) {
  final int total = seconds.round();
  return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
}

class ForkSavedAudioPreview extends StatelessWidget {
  const ForkSavedAudioPreview({
    required this.meme,
    required this.isVisible,
    super.key,
  });

  final FavoriteMeme meme;

  /// Whether the tile is on or near the screen; one that is not loads nothing.
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return _ForkSavedAudioWaveformTile(meme: meme, load: false);
    }
    if (forkSavedAudioCoverMissing(meme.url)) {
      return _ForkSavedAudioWaveformTile(meme: meme);
    }
    final String coverUrl = forkSavedAudioCoverUrl(meme.url);
    if (coverUrl.isEmpty) {
      return _ForkSavedAudioWaveformTile(meme: meme);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: coverUrl,
          httpHeaders: AttachmentRequestAuth.headersFor(coverUrl),
          fit: BoxFit.cover,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          placeholder: (_, _) =>
              ColoredBox(color: context.colors.backgroundModifierSelected),
          errorBuilder: (_, _, _) {
            forkMarkSavedAudioCoverMissing(meme.url);
            return _ForkSavedAudioWaveformTile(meme: meme);
          },
        ),
        PositionedDirectional(
          start: 8,
          end: 8,
          top: 8,
          child: Row(
            children: [
              _ForkAudioBadge(label: forkSavedAudioFormat(meme)),
              const Spacer(),
              if (meme.duration != null)
                _ForkAudioBadge(label: _formatLength(meme.duration!)),
            ],
          ),
        ),
      ],
    );
  }
}

/// The waveform, then the length, format and file name under it.
class _ForkSavedAudioWaveformTile extends ConsumerWidget {
  const _ForkSavedAudioWaveformTile({required this.meme, this.load = true});

  final FavoriteMeme meme;

  /// Whether to load the waveform; a flat line otherwise.
  final bool load;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<String?>? loaded = load
        ? ref.watch(forkLinkedWaveformProvider(meme.url))
        : null;
    final String? waveform = loaded is AsyncData<String?> ? loaded.value : null;
    final List<int> points = waveform == null || waveform.isEmpty
        ? const <int>[]
        : forkResampleWaveform(
            decodeVoiceMessageWaveform(waveform),
            _kWaveformBars,
          );
    final TextStyle detail = context.textStyles.smallText.copyWith(
      color: Colors.white,
    );
    return Container(
      color: context.colors.brandPrimary,
      // The bottom is left for the saved item's name, which upstream's tile draws over it.
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: SizedBox(
              height: 32,
              child: _ForkSavedAudioBars(points: points),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (meme.duration != null) ...[
                Flexible(
                  child: Text(
                    _formatLength(meme.duration!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: detail.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: _ForkAudioBadge(label: forkSavedAudioFormat(meme)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            meme.filename,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: detail,
          ),
        ],
      ),
    );
  }
}

/// The waveform's bars, or a flat line until it is loaded or when there is none.
class _ForkSavedAudioBars extends StatelessWidget {
  const _ForkSavedAudioBars({required this.points});

  final List<int> points;

  @override
  Widget build(BuildContext context) {
    final Color color = Colors.white.withValues(alpha: 0.85);
    if (points.isEmpty) {
      return Center(
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      );
    }
    return Row(
      children: [
        for (final int point in points)
          Expanded(
            child: Center(
              child: FractionallySizedBox(
                widthFactor: 0.55,
                heightFactor: (point / 255).clamp(0.08, 1.0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ForkAudioBadge extends StatelessWidget {
  const _ForkAudioBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.62),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textStyles.smallText.copyWith(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}
