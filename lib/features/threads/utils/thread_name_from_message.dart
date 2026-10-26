import 'package:fluxer_app/features/chat/utils/messages/message_content_stripper.dart';

/// Fork: the text a thread started from a message suggests as its name, on one
/// line, with each custom emoji as `:name:` rather than its markup, as the web
/// does (tyne-chat/tyne#100). Upstream used the message's raw text.
String threadNameFromMessageContent(String content) => content
    .replaceAllMapped(
      MessageContentPatterns.customEmoji,
      (Match match) => ':${match.group(1)}:',
    )
    .trim()
    .replaceAll('\n', ' ');
