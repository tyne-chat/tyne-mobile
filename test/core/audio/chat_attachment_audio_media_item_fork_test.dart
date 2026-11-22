// Fork: tests of the lock screen's media item for an audio attachment (tyne-chat/tyne#873,
// tyne-chat/tyne#874).

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/audio/chat_attachment/chat_attachment_audio_media_item.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/utils/attachments/attachment_cover_fork.dart';

Attachment _attachment({int? duration, int flags = 0}) {
  return Attachment(
    id: 'attachment-audio',
    url: 'https://cdn.example/attachments/1/2/clip.mp3',
    proxyUrl: 'https://media.example/attachments/1/2/clip.mp3?ex=1&is=2&hm=abc',
    filename: 'clip.mp3',
    contentType: 'audio/mpeg',
    size: 1024,
    duration: duration,
    flags: flags,
  );
}

void main() {
  test(
    'reads the attachment duration in seconds until the player knows the length',
    () {
      expect(
        buildChatAttachmentAudioMediaItem(
          attachment: _attachment(duration: 7),
          title: 'clip.mp3',
        ).duration,
        const Duration(seconds: 7),
      );
    },
  );

  test('prefers the length the player measured', () {
    expect(
      buildChatAttachmentAudioMediaItem(
        attachment: _attachment(duration: 7),
        title: 'clip.mp3',
        duration: const Duration(milliseconds: 6850),
      ).duration,
      const Duration(milliseconds: 6850),
    );
  });

  test('has no length without one', () {
    expect(
      buildChatAttachmentAudioMediaItem(
        attachment: _attachment(),
        title: 'clip.mp3',
      ).duration,
      isNull,
    );
  });

  test('shows the cover as the artwork when the server kept one', () {
    final Uri? art = buildChatAttachmentAudioMediaItem(
      attachment: _attachment(flags: kForkAttachmentFlagHasCover),
      title: 'clip.mp3',
    ).artUri;
    expect(art?.queryParameters['cover'], '1');
  });
}
