import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/utils/attachments/attachment_display_utils.dart';
import 'package:fluxer_app/features/chat/utils/media/fork_media_proxy_sizing.dart';
import 'package:fluxer_app/features/chat/utils/media/fork_rendered_thumbnail_registry.dart';
import 'package:fluxer_app/features/chat/utils/media/hdr_aware_image_url.dart';
import 'package:fluxer_app/features/mature_content/domain/mature_content_types.dart';
import 'package:fluxer_app/features/mature_content/providers/mature_content_agreements_provider.dart';
import 'package:fluxer_app/features/settings/providers/preferences/appearance_preferences_provider.dart';
import 'package:fluxer_app/features/ui/media_viewer/attachment_media_viewer.dart';

bool _isTransformedFluxerUrl(String url, {String? mediaEndpoint}) {
  return forkIsTransformableMediaUrl(url, mediaEndpoint: mediaEndpoint) &&
      forkHasProxyTransformParams(url);
}

/// Resolves the original untransformed download URL for [attachment], returning
/// `null` if expired or if only a transformed Fluxer proxy URL exists without
/// an untransformed original source.
///
/// External URLs carrying their own query parameters (e.g. `format` or `width`
/// on third-party CDNs) are preserved verbatim.
String? forkResolveOriginalDownloadUrl(
  Attachment attachment, {
  String? mediaEndpoint,
}) {
  if (attachment.expired ?? false) {
    return null;
  }
  final String? trimmedProxy = attachment.proxyUrl?.trim();
  if (trimmedProxy != null &&
      trimmedProxy.isNotEmpty &&
      !_isTransformedFluxerUrl(trimmedProxy, mediaEndpoint: mediaEndpoint)) {
    return trimmedProxy;
  }
  final String trimmedUrl = attachment.url.trim();
  if (trimmedUrl.isNotEmpty &&
      !_isTransformedFluxerUrl(trimmedUrl, mediaEndpoint: mediaEndpoint)) {
    return trimmedUrl;
  }
  final String? preservedOriginal = forkOriginalDownloadUrlOf(
    attachment,
  )?.trim();
  if (preservedOriginal != null &&
      preservedOriginal.isNotEmpty &&
      !_isTransformedFluxerUrl(
        preservedOriginal,
        mediaEndpoint: mediaEndpoint,
      )) {
    return preservedOriginal;
  }
  return null;
}

/// Resolves the URL sent to external reverse-image search providers for [item].
///
/// When [item] is served via a Fluxer `proxyUrl` while `item.downloadUrl` holds
/// a preserved external origin URL (e.g. a grouped embed whose proxy URL was
/// transformed), returns `proxyUrl` so the raw external URL and any query
/// access signatures are not leaked to third-party search providers.
String forkResolveReverseImageSearchUrl(AttachmentMediaViewerItem item) {
  final String? dl = item.downloadUrl?.trim();
  final String? proxy = item.proxyUrl?.trim();
  if (proxy != null &&
      proxy.isNotEmpty &&
      dl != null &&
      dl.isNotEmpty &&
      dl != proxy &&
      dl != item.url.trim()) {
    return proxy;
  }
  return item.downloadUrl ?? item.url;
}

/// Single shared viewer full-resolution URL builder used by both
/// `_buildMediaPage` and `ForkMediaViewerPreloader` so both target the exact
/// same URL and disk cache key.
String forkViewerImageUrl(AttachmentMediaViewerItem item, HdrDisplayMode mode) {
  return buildHdrAwareDisplayImageUrl(
    url: item.url,
    proxyUrl: item.proxyUrl,
    mode: mode,
    contentType: item.contentType,
    animated: item.animated,
  );
}

bool _urlPathEndsWithGif(String? rawUrl) {
  if (rawUrl == null || rawUrl.isEmpty) {
    return false;
  }
  final Uri? uri = Uri.tryParse(rawUrl);
  return uri != null && uri.path.toLowerCase().endsWith('.gif');
}

/// Explicit animation predicate for the progressive swap and preloader paths.
///
/// Unlike upstream's conservative `_mayBeAnimated`, static `.webp` and `.avif`
/// photos return `false` so they still get cached-thumbnail -> full-res swap
/// and preloading.
bool forkIsExplicitlyAnimatedViewerItem(AttachmentMediaViewerItem item) {
  final String? contentType = item.contentType
      ?.toLowerCase()
      .split(';')
      .first
      .trim();
  return item.animated ||
      mediaProxyUrlIsAnimated(item.url) ||
      (item.proxyUrl != null && mediaProxyUrlIsAnimated(item.proxyUrl!)) ||
      contentType == 'image/gif' ||
      item.filename.toLowerCase().endsWith('.gif') ||
      _urlPathEndsWithGif(item.url) ||
      _urlPathEndsWithGif(item.proxyUrl);
}

/// Builds viewer items from [attachments] while attaching each tile's exact
/// cached [ForkThumbnailDescriptor], original download URL, and byte size.
List<AttachmentMediaViewerItem> forkViewerItemsFromAttachments(
  List<Attachment> attachments, {
  Map<String, ForkThumbnailDescriptor>? tileDescriptors,
  int? tappedIndex,
  ForkThumbnailDescriptor? tappedPreview,
  Object? registryScope,
}) {
  return <AttachmentMediaViewerItem>[
    for (int i = 0; i < attachments.length; i++)
      forkViewerItemFromAttachment(
        attachments[i],
        preview:
            (tappedIndex != null && i == tappedIndex && tappedPreview != null)
            ? tappedPreview
            : _lookupDescriptor(
                attachments[i],
                tileDescriptors: tileDescriptors,
                registryScope: registryScope,
              ),
      ),
  ];
}

ForkThumbnailDescriptor? _lookupDescriptor(
  Attachment attachment, {
  Map<String, ForkThumbnailDescriptor>? tileDescriptors,
  Object? registryScope,
}) {
  final String sourceKey = attachmentEffectiveUrl(attachment);
  final ForkThumbnailDescriptor? fromMap = tileDescriptors?[sourceKey];
  if (fromMap != null) {
    return fromMap;
  }
  if (registryScope != null) {
    final ForkThumbnailDescriptor? fromRegistry =
        ForkRenderedThumbnailRegistry.lookup(
          scopeToken: registryScope,
          sourceKey: sourceKey,
        );
    if (fromRegistry != null) {
      return fromRegistry;
    }
  }
  if (attachment.placeholder != null && attachment.placeholder!.isNotEmpty) {
    return ForkThumbnailDescriptor(url: '', thumbHash: attachment.placeholder);
  }
  return null;
}

/// Builds a single [AttachmentMediaViewerItem] from [attachment] with fork
/// preview metadata, original download resolution, and attachment byte size.
AttachmentMediaViewerItem forkViewerItemFromAttachment(
  Attachment attachment, {
  ForkThumbnailDescriptor? preview,
}) {
  final ForkThumbnailDescriptor? effectivePreview =
      preview ??
      (attachment.placeholder != null && attachment.placeholder!.isNotEmpty
          ? ForkThumbnailDescriptor(url: '', thumbHash: attachment.placeholder)
          : null);
  return AttachmentMediaViewerItem(
    forkPreview: effectivePreview,
    forkSizeBytes: attachment.size,
    url: attachment.url,
    filename: attachment.filename,
    width: attachment.width,
    height: attachment.height,
    isMatureMedia: attachment.isMatureMedia,
    attachmentId: attachment.id,
    proxyUrl: attachment.proxyUrl,
    contentType: attachment.contentType,
    downloadUrl: forkResolveOriginalDownloadUrl(attachment),
    contentHash: attachment.contentHash,
    description: attachment.description,
    animated: attachment.isAnimated,
  );
}

/// Fail-closed mature-media visibility check for the viewer shell's `build()`.
///
/// Withholds media (and its toolbar/options actions) whenever [isMatureMedia]
/// is true and either [channelId] is null, the policy is unresolved, the policy
/// blocks it, or the policy blurs it and the user has not yet revealed it.
bool forkWatchViewerMatureHidden(
  WidgetRef ref, {
  required String? channelId,
  required bool isMatureMedia,
  required bool revealed,
}) {
  if (!isMatureMedia) {
    return false;
  }
  if (channelId == null) {
    return true;
  }
  final MatureMediaPolicy? policy = ref
      .watch(
        matureMediaPolicyProvider(
          MatureMediaPolicyRequest(channelId: channelId, isMatureMedia: true),
        ),
      )
      .value;
  if (policy == null || policy.shouldBlock) {
    return true;
  }
  if (!policy.shouldBlur) {
    return false;
  }
  return !(revealed && policy.canReveal);
}
