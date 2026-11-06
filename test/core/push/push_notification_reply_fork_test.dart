// Fork: a reply typed in a notification is posted without the app's persona
// selection, so it asks the server to send it as the persona selected in the
// channel, or the one a tag in the text names (tyne-chat/tyne#343). The text
// goes as typed: the server takes the tag out.
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/push/notification/reply.dart';

void main() {
  test('a reply asks the server for the selected persona', () async {
    PushReplySend? sent;
    final PushReplyResult result = await sendPushNotificationReply(
      payload: <String, String>{
        'channel_id': 'c',
        'message_id': 'm',
        'target_user_id': 'user-b',
      },
      text: 'F: hello',
      lookupAccount: (String userId) async => const PushReplyAccount(
        token: 't',
        apiBaseUrl: 'https://example.test',
      ),
      post: (PushReplySend send) async {
        sent = send;
      },
    );

    expect(result, PushReplyResult.sent);
    expect(sent?.body['use_persona_selection'], isTrue);
    expect(sent?.body['content'], 'F: hello');
    expect(sent?.body.containsKey('persona_id'), isFalse);
  });
}
