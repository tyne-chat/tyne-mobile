// Fork: a push for a DM thread's message is a DM push for the parent DM with
// fork_thread_id added; the app opens the thread and replies in it
// (tyne-chat/tyne#699). Kept apart from upstream's
// push_notification_path_resolver_test.dart.
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/push/notification/path_resolver.dart';
import 'package:fluxer_app/core/push/notification/reply.dart';
import 'package:fluxer_app/core/router/route_names.dart';

const Map<String, String> _dmThreadPush = <String, String>{
  'channel_id': 'dm-1',
  'message_id': 'msg-9',
  'target_user_id': 'user-b',
  'fork_thread_id': 'thread-4',
  'fork_thread_name': 'Plans',
};

void main() {
  test('a DM thread push opens the thread at its message', () {
    expect(
      resolvePushNotificationPath(_dmThreadPush),
      RoutePaths.dmChannelMessage('thread-4', 'msg-9'),
    );
  });

  test('the thread wins over a url naming the DM', () {
    expect(
      resolvePushNotificationPath(<String, String>{
        ..._dmThreadPush,
        'url': '/channels/@me/dm-1/msg-9',
      }),
      RoutePaths.dmChannelMessage('thread-4', 'msg-9'),
    );
  });

  test('without a message it opens the thread', () {
    expect(
      resolvePushNotificationPath(<String, String>{
        'channel_id': 'dm-1',
        'fork_thread_id': 'thread-4',
      }),
      RoutePaths.dmChannel('thread-4'),
    );
  });

  test('a DM push without a thread still opens the DM', () {
    expect(
      resolvePushNotificationPath(<String, String>{
        'channel_id': 'dm-1',
        'message_id': 'msg-9',
        'fork_thread_id': ' ',
      }),
      RoutePaths.dmChannelMessage('dm-1', 'msg-9'),
    );
  });

  test('a reply to a DM thread push is posted in the thread', () async {
    PushReplySend? sent;
    final PushReplyResult result = await sendPushNotificationReply(
      payload: _dmThreadPush,
      text: 'on it',
      lookupAccount: (String userId) async => const PushReplyAccount(
        token: 't',
        apiBaseUrl: 'https://example.test',
      ),
      post: (PushReplySend send) async {
        sent = send;
      },
      resolveReplyMention: (Map<String, String> payload) async => false,
    );

    expect(result, PushReplyResult.sent);
    expect(sent?.channelId, 'thread-4');
  });
}
