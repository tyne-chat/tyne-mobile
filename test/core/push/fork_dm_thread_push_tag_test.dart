// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: a DM thread's push is its own conversation, cleared when the thread
// is read (tyne-chat/tyne#699).

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/push/notification/payload.dart';

void main() {
  test('a DM thread push is tagged by the thread, and keeps its DM', () {
    final Map<String, String> enriched = enrichPushPayload(<String, String>{
      'channel_id': 'dm-1',
      'fork_thread_id': 'thread-1',
      'message_id': 'm-1',
      'tag': 'channel:dm-1',
    });

    expect(enriched['tag'], 'channel:thread-1');
    expect(enriched['notification_tag'], 'channel:thread-1');
    expect(enriched['channel_id'], 'dm-1');
    expect(resolvePushGroupTag(enriched), 'channel:thread-1');
  });

  test('a DM push stays tagged by the DM', () {
    final Map<String, String> enriched = enrichPushPayload(<String, String>{
      'channel_id': 'dm-1',
      'message_id': 'm-1',
    });

    expect(enriched['notification_tag'], 'channel:dm-1');
  });
}
