import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/features/dm/domain/dm_channel_types.dart';
import 'package:fluxer_app/features/dm/domain/dm_conversation.dart';
import 'package:fluxer_app/features/dm/providers/dm_view_model.dart';
import 'package:fluxer_app/features/friends/providers/friend_providers.dart';
import 'package:fluxer_app/shared/utils/chat_context_utils.dart';
import 'package:fluxer_app/shared/utils/display_name.dart';

// Fork imports.
// ignore: directives_ordering
import 'package:fluxer_app/features/threads/fork_dm_threads/dm_thread_providers.dart';

typedef ComposerWatch = ({
  bool forkImportedRecipient,
  bool isSystemDm,
  bool isPersonalNotes,
  bool isGroup,
  String recipientId,
  String recipientName,
  String recipientDisplayName,
  String? name,
});

ComposerWatch? composerWatchFor(
  DmConversation? conversation, {
  String? friendNickname,
}) {
  if (conversation == null) {
    return null;
  }
  return (
    forkImportedRecipient: conversation.forkImportedRecipient,
    isSystemDm: isSystemDmConversation(conversation),
    isPersonalNotes: conversation.isPersonalNotes,
    isGroup: conversation.isGroup,
    recipientId: conversation.recipientId,
    recipientName: conversation.recipientName,
    recipientDisplayName: resolveDisplayName(
      username: conversation.recipientName,
      friendNickname: friendNickname,
    ),
    name: conversation.name,
  );
}

//
// ignore: specify_nonobvious_property_types
final composerWatchProvider = Provider.autoDispose.family<ComposerWatch?, String>(
  (Ref ref, String channelId) {
    final List<DmConversation> conversations = ref.watch(
      dmViewModelProvider.select((DmViewState state) => state.conversations),
    );
    // Fork: a DM thread's composer follows its DM's rules (tyne-chat/tyne#699).
    final String dmId =
        ref.watch(forkDmThreadParentOfProvider(channelId)) ?? channelId;
    final DmConversation? conversation = findDmById(conversations, dmId);
    final String? friendNickname =
        conversation == null ||
            conversation.isGroup ||
            conversation.isPersonalNotes
        ? null
        : ref.watch(friendNicknameProvider(conversation.recipientId)).value;
    return composerWatchFor(conversation, friendNickname: friendNickname);
  },
);
