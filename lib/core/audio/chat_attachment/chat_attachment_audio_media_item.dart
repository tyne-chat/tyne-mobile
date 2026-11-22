import 'package:audio_service/audio_service.dart';
import 'package:fluxer_app/core/audio/chat_attachment/chat_attachment_audio_artwork.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/utils/attachments/attachment_display_utils.dart';

// Fork imports.
// ignore: directives_ordering
import 'package:fluxer_app/features/chat/utils/attachments/attachment_cover_fork.dart';

MediaItem buildChatAttachmentAudioMediaItem({
  required Attachment attachment,
  required String title,
  Duration? duration,
}) {
  final String mediaId = attachmentEffectiveUrl(attachment);
  // Fork: an attachment's duration is in seconds, as the API documents it (tyne-chat/tyne#874).
  final Duration? resolvedDuration =
      duration ??
      (attachment.duration != null && attachment.duration! > 0
          ? Duration(seconds: attachment.duration!)
          : null);
  // Fork: the attachment's cover as the artwork, when the server kept one (tyne-chat/tyne#873).
  return MediaItem(
    artHeaders: forkAttachmentAudioArtHeaders(attachment),
    id: mediaId.isNotEmpty ? mediaId : attachment.filename,
    title: title,
    duration: resolvedDuration,
    artUri: forkAttachmentAudioArtUri(attachment) ?? chatAttachmentAudioArtUri,
  );
}
