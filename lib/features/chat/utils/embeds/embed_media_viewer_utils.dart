import 'dart:async';

import 'package:fluxer_app/features/chat/domain/chat_fullscreen_video_launch_context.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/sheets/forward_message_sheet.dart';
import 'package:fluxer_app/features/chat/utils/embeds/embed_animated_image_url.dart';
import 'package:fluxer_app/features/ui/media_viewer/attachment_media_viewer.dart';
import 'package:fluxer_app/material_ui.dart';

// Fork imports.
// ignore: directives_ordering
import 'package:fluxer_app/features/chat/utils/media/fork_rendered_thumbnail_registry.dart';

String embedMediaEffectiveUrl(EmbedMedia media) {
  return media.proxyUrl ?? media.url;
}

String embedMediaShareableUrl({
  required EmbedMedia media,
  String? embedPageUrl,
}) {
  final String pageUrl = embedPageUrl?.trim() ?? '';
  if (pageUrl.isNotEmpty) {
    return pageUrl;
  }
  final String mediaUrl = media.url.trim();
  if (mediaUrl.isNotEmpty) {
    return mediaUrl;
  }
  return embedMediaEffectiveUrl(media);
}

bool canOpenEmbedMediaViewer(EmbedMedia media) {
  return embedMediaEffectiveUrl(media).isNotEmpty;
}

bool isPlayableEmbedAudio(EmbedMedia? media) {
  if (media == null || media.url.trim().isEmpty) {
    return false;
  }
  final String? proxyUrl = media.proxyUrl?.trim();
  return proxyUrl != null && proxyUrl.isNotEmpty;
}

void openEmbedMediaViewer(
  BuildContext context, {
  required EmbedMedia media,
  bool forkIsMatureMedia = false,
  ForkThumbnailDescriptor? forkTappedPreview,
  String? title,
  String? embedPageUrl,
  bool animated = false,
  int? embedIndex,
  String? channelId,
  String? messageId,
  MessageMediaActionScope? actionScope,
  List<EmbedMedia>? gallery,
  int initialIndex = 0,
}) {
  final List<EmbedMedia> images = (gallery ?? <EmbedMedia>[media])
      .where(canOpenEmbedMediaViewer)
      .toList();
  if (images.isEmpty) {
    return;
  }
  final int clampedInitialIndex = initialIndex.clamp(0, images.length - 1);
  final List<AttachmentMediaViewerItem> items = <AttachmentMediaViewerItem>[
    for (int i = 0; i < images.length; i++)
      buildEmbedMediaViewerItem(
        forkIsMatureMedia: forkIsMatureMedia,
        forkPreview: i == clampedInitialIndex ? forkTappedPreview : null,
        media: images[i],
        title: title,
        embedPageUrl: embedPageUrl,
        animated: animated || images[i].isAnimated,
        embedIndex: embedIndex,
      ),
  ];
  unawaited(
    showAttachmentMediaViewer(
      context,
      items: items,
      initialIndex: clampedInitialIndex,
      channelId: channelId,
      onForward: (channelId != null && messageId != null && embedIndex != null)
          ? (int _) => showForwardMediaSheet(
              context,
              sourceChannelId: channelId,
              sourceMessageId: messageId,
              embedIndices: <int>[embedIndex],
            )
          : null,
      actionScope: actionScope,
    ),
  );
}

AttachmentMediaViewerItem buildEmbedMediaViewerItem({
  required EmbedMedia media,
  bool forkIsMatureMedia = false,
  ForkThumbnailDescriptor? forkPreview,
  String? title,
  String? embedPageUrl,
  bool animated = false,
  int? embedIndex,
}) {
  final String url = animated
      ? animatedEmbedImageUrl(embedMediaEffectiveUrl(media))
      : embedMediaEffectiveUrl(media);
  final ForkThumbnailDescriptor? resolvedPreview =
      forkPreview ??
      (media.placeholder != null && media.placeholder!.isNotEmpty
          ? ForkThumbnailDescriptor(url: '', thumbHash: media.placeholder)
          : null);
  return AttachmentMediaViewerItem(
    forkPreview: resolvedPreview,
    url: url,
    linkUrl: embedMediaShareableUrl(media: media, embedPageUrl: embedPageUrl),
    filename: resolveEmbedMediaViewerFilename(url: url, title: title),
    width: media.width,
    height: media.height,
    isMatureMedia: forkIsMatureMedia,
    embedIndex: embedIndex,
    proxyUrl: media.proxyUrl,
    contentType: media.contentType,
    contentHash: media.contentHash,
    animated: animated,
  );
}

String resolveEmbedMediaViewerFilename({required String url, String? title}) {
  if (title != null && title.isNotEmpty) {
    return title;
  }
  final Uri? uri = Uri.tryParse(url);
  final List<String> segments = uri?.pathSegments ?? const <String>[];
  if (segments.isNotEmpty) {
    return segments.last;
  }
  return 'image';
}
