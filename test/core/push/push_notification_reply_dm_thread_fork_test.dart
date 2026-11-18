// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: a reply from the notification of a DM thread's message goes to the
// thread, where the message is (tyne-chat/tyne#699).

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/push/notification/reply.dart';

void main() {
  test('the Android reply target of a DM thread push is the thread', () {
    final AndroidNotificationReplyTarget? target =
        androidNotificationReplyTarget(<String, String>{
          'channel_id': 'dm-1',
          'fork_thread_id': 'thread-1',
          'message_id': 'm-1',
          'target_user_id': 'me',
        });

    expect(target?.channelId, 'thread-1');
    expect(target?.messageId, 'm-1');
  });

  test('without a thread it is the channel, as before', () {
    expect(
      androidNotificationReplyTarget(<String, String>{
        'channel_id': 'dm-1',
        'message_id': 'm-1',
        'target_user_id': 'me',
      })?.channelId,
      'dm-1',
    );
  });
}
