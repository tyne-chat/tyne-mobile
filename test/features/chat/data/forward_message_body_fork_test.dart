// Fork: a forward goes out as a persona like any other message
// (tyne-chat/tyne#209).
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/data/message_repository.dart';

void main() {
  test('names the persona by id', () {
    final Map<String, dynamic> body = buildForwardMessageBody(
      sourceChannelId: 'chan_1',
      sourceMessageId: 'msg_1',
      personaId: 'persona_1',
    );

    expect(body['persona_id'], 'persona_1');
  });

  test('sends no persona field for the account', () {
    expect(
      buildForwardMessageBody(
        sourceChannelId: 'chan_1',
        sourceMessageId: 'msg_1',
      ).containsKey('persona_id'),
      isFalse,
    );
  });
}
