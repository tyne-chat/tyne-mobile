// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluxer_app/core/router/route_names.dart';

/// Fork: a push for a message in a DM thread is a DM push for the parent DM
/// (`channel_id` is the DM, so older apps open it), with the thread in
/// `fork_thread_id` and its name in `fork_thread_name`. Tapping it opens the
/// thread, at the message when the push names one (tyne-chat/tyne#699).
/// Null for every other push.
String? forkDmThreadPushPath(Map<String, String> payload) {
  final String? threadId = _nonEmpty(payload['fork_thread_id']);
  if (threadId == null) {
    return null;
  }
  final String? messageId = _nonEmpty(payload['message_id']);
  return messageId == null
      ? RoutePaths.dmChannel(threadId)
      : RoutePaths.dmChannelMessage(threadId, messageId);
}

String? _nonEmpty(String? value) {
  final String? trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

/// The DM thread a push is for, or null for every other push.
String? forkDmThreadPushChannelId(Map<String, String> payload) =>
    _nonEmpty(payload['fork_thread_id']);

/// Tags a DM thread's push by the thread instead of its DM, in place, as a
/// community thread's push is tagged by the thread: reading the thread (an
/// ack, `notification_clear`) clears `channel:<thread>`, and the DM's own
/// pushes stay a conversation of their own. `channel_id` stays the DM, for
/// the conversation's name and picture. The server tags the push by the DM
/// for apps that predate DM threads (tyne-chat/tyne#699).
void forkRetagDmThreadPush(Map<String, String> enriched) {
  final String? threadId = forkDmThreadPushChannelId(enriched);
  final String? dmId = _nonEmpty(enriched['channel_id']);
  if (threadId == null || dmId == null) {
    return;
  }
  final String dmTag = 'channel:$dmId';
  final String threadTag = 'channel:$threadId';
  for (final String key in <String>['notification_tag', 'tag']) {
    final String? tag = _nonEmpty(enriched[key]);
    if (tag == dmTag || (tag?.startsWith('$dmTag:') ?? false)) {
      enriched[key] = threadTag + tag!.substring(dmTag.length);
    }
  }
}
