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
