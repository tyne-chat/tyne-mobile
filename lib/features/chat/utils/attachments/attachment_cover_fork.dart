// Fork (tyne-chat/tyne#873): an audio attachment's cover.
//
// The server keeps the cover embedded in an audio upload, flags the attachment and serves the cover
// from the attachment's own URL with `cover=1`, resized like any image by the media proxy.

import 'package:fluxer_app/core/api/attachment_request_auth.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/utils/attachments/attachment_display_utils.dart';
import 'package:fluxer_app/features/chat/utils/media/media_proxy_url.dart';

/// The attachment flag the server sets on audio whose embedded cover it kept (the server's
/// `ForkMessageAttachmentFlags.HAS_COVER`, a fork bit in the middle of the Int32 range: upstream
/// uses both ends, its internal `EMBED_MEDIA_OWNED_ATTACHMENT_FLAG` being `1 << 30`).
const int kForkAttachmentFlagHasCover = 1 << 21;

/// The query parameter that makes the media proxy serve an attachment's cover instead of the file.
const String kForkAttachmentCoverParameter = 'cover';

/// The lock screen's and the notification's artwork size, in pixels.
const int _kArtworkSize = 512;

bool forkAttachmentHasCover(Attachment attachment) {
  return (attachment.flags & kForkAttachmentFlagHasCover) != 0;
}

/// The URL of [attachment]'s cover: resized to [width] pixels as a WebP, or as stored.
String forkAttachmentCoverUrl(Attachment attachment, {int? width}) {
  final Uri? parsed = Uri.tryParse(attachmentEffectiveUrl(attachment));
  if (parsed == null || !parsed.hasScheme) {
    return '';
  }
  final Map<String, String> query = Map<String, String>.from(
    parsed.queryParameters,
  )..[kForkAttachmentCoverParameter] = '1';
  final String coverUrl = parsed.replace(queryParameters: query).toString();
  if (width == null) {
    return coverUrl;
  }
  return buildMediaProxyUrl(coverUrl, width: width, format: 'webp');
}

/// The lock screen's artwork for [attachment]: its cover, or null to keep the app icon.
Uri? forkAttachmentAudioArtUri(Attachment attachment) {
  if (!forkAttachmentHasCover(attachment)) {
    return null;
  }
  final String url = forkAttachmentCoverUrl(attachment, width: _kArtworkSize);
  return url.isEmpty ? null : Uri.tryParse(url);
}

/// The headers the artwork's request needs (an instance that serves attachments through its API).
Map<String, String>? forkAttachmentAudioArtHeaders(Attachment attachment) {
  final Uri? art = forkAttachmentAudioArtUri(attachment);
  return art == null ? null : AttachmentRequestAuth.headersFor(art.toString());
}
