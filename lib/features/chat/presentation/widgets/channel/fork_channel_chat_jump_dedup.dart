// Fork: tyne-chat/tyne#940. Once a channel jump target has been consumed or
// superseded, `buildChannelChatSyncRequest` drops `targetMessageId` from the
// request. Without treating that consumed target as equivalent to `null` for
// deduplication on the same loaded channel, unrelated sync triggers (such as
// closing a message bottom sheet or popup via `shellHasPopupOverlayProvider`)
// look like a brand-new `switchChannel(channelId, targetMessageId: null)` and
// kick off a spurious network resync.
import 'package:fluxer_app/core/router/route_state_providers.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/chat/utils/messages/message_page_sync.dart';

typedef ChannelChatSwitchRequest = ({
  String channelId,
  String? targetMessageId,
  bool loadMessages,
});

/// Returns [lastRequest] with `targetMessageId` cleared once `(channelId,
/// messageId)` is marked consumed, keeping it aligned with what
/// `buildChannelChatSyncRequest` emits while preserving repeat-tap behaviour.
ChannelChatSwitchRequest? forkNormalizeConsumedSwitchRequest(
  ChannelChatSwitchRequest? lastRequest, {
  required String channelId,
  required String messageId,
}) {
  if (lastRequest == null ||
      lastRequest.channelId != channelId ||
      lastRequest.targetMessageId != messageId) {
    return lastRequest;
  }
  return (
    channelId: channelId,
    targetMessageId: null,
    loadMessages: lastRequest.loadMessages,
  );
}

/// Whether [request] only drops a consumed/superseded jump target on an
/// already-loaded matching channel window and should be adopted without
/// triggering another `switchChannel(..., targetMessageId: null)`.
bool forkShouldAdoptConsumedJumpTarget({
  required ChannelChatSwitchRequest? lastRequest,
  required ChannelChatSwitchRequest request,
  required String? routeTarget,
  required ChannelJumpTargetConsumption consumption,
  required ChatViewState state,
}) {
  if (lastRequest == null || routeTarget == null || routeTarget.isEmpty) {
    return false;
  }
  if (lastRequest.channelId != request.channelId ||
      lastRequest.loadMessages != request.loadMessages) {
    return false;
  }
  if (lastRequest.targetMessageId != routeTarget ||
      request.targetMessageId != null) {
    return false;
  }
  final bool targetRetired =
      consumption.isConsumed(
        channelId: request.channelId,
        messageId: routeTarget,
      ) ||
      consumption.isSuperseded(
        channelId: request.channelId,
        messageId: routeTarget,
      );
  if (!targetRetired) {
    return false;
  }
  if (state.channelId != request.channelId ||
      state.messageLoadFailed ||
      state.messages.isEmpty ||
      chatWindowMismatchesChannel(
        expectedChannelId: request.channelId,
        channelId: state.channelId,
        messages: state.messages,
      )) {
    return false;
  }
  return true;
}
