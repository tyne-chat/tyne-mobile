// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: state for threads in DMs, and the unread counts of a parent's
// threads in DMs and communities (tyne-chat/tyne#699). Nothing here sends a
// request: DM threads arrive with READY and gateway events, and the counts
// read the local read states.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/core/permissions/thread_permissions.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/router/route_kind.dart';
import 'package:fluxer_app/core/router/route_state_providers.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/channels/providers/channel_providers.dart';
import 'package:fluxer_app/features/channels/providers/unread_provider.dart';
import 'package:fluxer_app/features/dm/domain/dm_conversation.dart';
import 'package:fluxer_app/features/dm/providers/dm_view_model.dart';
import 'package:fluxer_app/features/threads/domain/thread_channel.dart';
import 'package:fluxer_app/features/threads/fork_dm_threads/dm_threads.dart';
import 'package:fluxer_app/features/threads/providers/thread_ui_providers.dart';
import 'package:fluxer_app/shared/utils/chat_context_utils.dart';

/// Whether this account may start threads in DMs (READY's switch).
final Provider<bool> forkDmThreadsEnabledProvider = Provider.autoDispose<bool>((
  Ref ref,
) {
  final String? userId = ref.watch(currentUserIdProvider);
  void changed() => ref.invalidateSelf();
  forkDmThreadsSwitchChanges.addListener(changed);
  ref.onDispose(() => forkDmThreadsSwitchChanges.removeListener(changed));
  return forkDmThreadsEnabledFor(userId);
});

/// The DM or group DM with this id, as the DM list has it.
final ProviderFamily<DmConversation?, String> forkDmConversationProvider =
    Provider.autoDispose.family<DmConversation?, String>(
      (Ref ref, String dmId) => ref.watch(
        dmViewModelProvider.select(
          (DmViewState state) => findDmById(state.conversations, dmId),
        ),
      ),
    );

/// A DM as upstream's thread parent, or null while it is unknown.
final ProviderFamily<Channel?, String> forkDmThreadParentProvider = Provider
    .autoDispose
    .family<Channel?, String>((Ref ref, String dmId) {
      final DmConversation? dm = ref.watch(forkDmConversationProvider(dmId));
      if (dm == null || dm.isPersonalNotes) {
        return null;
      }
      return forkDmThreadParentChannel(
        dmId: dm.id,
        isGroup: dm.isGroup,
        name: dm.rawDisplayName,
      );
    });

/// Who the account is in a DM's threads: a member, the owner of a group DM,
/// and allowed to start threads only with READY's switch on.
ThreadActor? forkDmThreadActorFor({
  required DmConversation? dm,
  required String? currentUserId,
  required bool canStart,
}) {
  if (dm == null || dm.isPersonalNotes) {
    return null;
  }
  return ThreadActor(
    permissions:
        forkDmThreadMemberPermissions |
        (canStart ? Permission.createPublicThreads.value : 0),
    isOwner: dm.isGroup && currentUserId != null && dm.ownerId == currentUserId,
  );
}

/// The account in the threads of a DM, by the DM's id.
final ProviderFamily<ThreadActor?, String> forkDmParentThreadActorProvider =
    Provider.autoDispose.family<ThreadActor?, String>(
      (Ref ref, String dmId) => forkDmThreadActorFor(
        dm: ref.watch(forkDmConversationProvider(dmId)),
        currentUserId: ref.watch(currentUserIdProvider),
        canStart: ref.watch(forkDmThreadsEnabledProvider),
      ),
    );

/// The account in one DM thread. In a 1:1 DM either person may rename and
/// close a thread, which upstream's rules give its starter, so both count as
/// its starter here; locking, deleting and removing members stay with
/// moderators, which in a DM is only a group's owner. Deleting by the
/// starter of a 1:1 DM thread is [forkDmStarterMayDelete].
ThreadActorContext forkDmThreadActorContext({
  required ThreadActor actor,
  required Channel thread,
  required DmConversation? dm,
  required String? currentUserId,
  required bool isMember,
}) => ThreadActorContext(
  permissions: actor.permissions,
  isOwner: actor.isOwner,
  timedOut: actor.timedOut,
  thread: threadFactsOf(thread),
  isThreadOwner:
      (dm != null && !dm.isGroup) ||
      (currentUserId != null && thread.ownerId == currentUserId),
  isMember: isMember,
);

/// [forkDmThreadActorContext] for a stored thread, watched.
ThreadActorContext? watchForkDmThreadActorContext(
  Ref ref,
  Channel thread,
  ThreadActor actor,
) {
  final String? parentId = thread.parentId;
  return forkDmThreadActorContext(
    actor: actor,
    thread: thread,
    dm: parentId == null
        ? null
        : ref.watch(forkDmConversationProvider(parentId)),
    currentUserId: ref.watch(currentUserIdProvider),
    isMember: ref.watch(threadMembershipProvider(thread.id)).value != null,
  );
}

/// Whether the account started [thread] in a 1:1 DM, where the starter may
/// delete it as long as nobody else has written in it. The server checks
/// that; the menu just offers it to the starter.
bool forkDmStarterMayDeleteFor({
  required Channel thread,
  required DmConversation? dm,
  required String? currentUserId,
}) =>
    forkIsDmThread(thread) &&
    dm != null &&
    !dm.isGroup &&
    currentUserId != null &&
    thread.ownerId == currentUserId;

/// [forkDmStarterMayDeleteFor], watched.
bool forkDmStarterMayDelete(WidgetRef ref, Channel thread) {
  final String? parentId = thread.parentId;
  if (!forkIsDmThread(thread) || parentId == null) {
    return false;
  }
  return forkDmStarterMayDeleteFor(
    thread: thread,
    dm: ref.watch(forkDmConversationProvider(parentId)),
    currentUserId: ref.watch(currentUserIdProvider),
  );
}

/// Whether [thread] is in a 1:1 DM (not a group DM), watched.
bool watchForkIsOneToOneDmThread(WidgetRef ref, Channel thread) {
  final String? parentId = thread.parentId;
  if (!forkIsDmThread(thread) || parentId == null) {
    return false;
  }
  final DmConversation? dm = ref.watch(forkDmConversationProvider(parentId));
  return dm != null && !dm.isGroup;
}

/// The unread state of the threads a parent has that the account follows.
@immutable
class ForkThreadsUnread {
  const ForkThreadsUnread({this.threadsWithNews = 0, this.mentionCount = 0});

  /// Followed threads with unread messages.
  final int threadsWithNews;

  /// Unread mentions across them; every message in a DM thread counts.
  final int mentionCount;

  bool get hasNews => threadsWithNews > 0;

  @override
  bool operator ==(Object other) =>
      other is ForkThreadsUnread &&
      other.threadsWithNews == threadsWithNews &&
      other.mentionCount == mentionCount;

  @override
  int get hashCode => Object.hash(threadsWithNews, mentionCount);
}

/// Adds up the unread states of followed, unmuted threads.
ForkThreadsUnread forkSumThreadsUnread(
  Iterable<({UnreadState? unread, ThreadMembership? membership})> threads,
) {
  int withNews = 0;
  int mentions = 0;
  for (final ({UnreadState? unread, ThreadMembership? membership}) thread
      in threads) {
    final UnreadState? unread = thread.unread;
    final ThreadMembership? membership = thread.membership;
    if (unread == null || membership == null || membership.muted) {
      continue;
    }
    if (unread.hasUnread) {
      withNews++;
    }
    mentions += unread.mentionCount;
  }
  return ForkThreadsUnread(threadsWithNews: withNews, mentionCount: mentions);
}

/// The unread state of the active threads of a parent (a community
/// channel, or a DM under [forkDmThreadGuildKey]) the account follows.
final ProviderFamily<ForkThreadsUnread, ({String guildId, String parentId})>
forkParentThreadsUnreadProvider = Provider.autoDispose
    .family<ForkThreadsUnread, ({String guildId, String parentId})>((
      Ref ref,
      ({String guildId, String parentId}) parent,
    ) {
      final List<Channel> threads =
          ref
              .watch(parentThreadsProvider(parent.guildId, parent.parentId))
              .value ??
          const <Channel>[];
      return forkSumThreadsUnread(<
        ({UnreadState? unread, ThreadMembership? membership})
      >[
        for (final Channel thread in threads)
          if (!thread.isArchivedThread)
            (
              unread: ref.watch(channelUnreadProvider(thread.id)).value,
              membership: ref.watch(threadMembershipProvider(thread.id)).value,
            ),
      ]);
    });

/// The unread threads of the DM [dmId].
ForkThreadsUnread watchForkDmThreadsUnread(WidgetRef ref, String dmId) =>
    ref.watch(
      forkParentThreadsUnreadProvider((
        guildId: forkDmThreadGuildKey,
        parentId: dmId,
      )),
    );

/// Whether the app knows of at least one thread in the DM [dmId].
bool watchForkDmHasThreads(WidgetRef ref, String dmId) =>
    ref.watch(forkDmHasKnownThreadsProvider(dmId));

/// The unread state of one thread, for its chip and its browser row.
UnreadState? watchForkThreadUnread(WidgetRef ref, String threadId) =>
    ref.watch(channelUnreadProvider(threadId)).value;

/// The parent a DM thread was started in, as the DM list has it.
DmConversation? watchForkDmThreadParent(WidgetRef ref, String threadId) {
  final Channel? thread = ref.watch(channelByIdProvider(threadId)).value;
  final String? parentId = thread?.parentId;
  if (!forkIsDmThread(thread) || parentId == null) {
    return null;
  }
  return ref.watch(forkDmConversationProvider(parentId));
}

/// The guild key of the thread started from message [messageId] (the
/// thread has the message's id) when it is a known thread of the DM
/// [channelId], otherwise null.
String? watchForkDmThreadGuildKey(
  WidgetRef ref, {
  required String channelId,
  required String messageId,
}) => ref.watch(forkDmThreadParentOfProvider(messageId)) == channelId
    ? forkDmThreadGuildKey
    : null;

/// Whether the chat on screen is a DM thread, which Back always leaves for
/// its DM (upstream does that for a thread only when it was opened from its
/// channel).
bool forkIsDmThreadChatForShell(WidgetRef ref) {
  final String location = ref.read(shellLocationProvider);
  if (classifyRoute(location) != RouteKind.chat) {
    return false;
  }
  final String? channelId = extractChannelId(location);
  return channelId != null && forkDmThreadParentOf(channelId) != null;
}

/// The DM a known DM thread belongs to, from the in-memory index; null for
/// any other channel. Reads no database.
final ProviderFamily<String?, String> forkDmThreadParentOfProvider = Provider
    .autoDispose
    .family<String?, String>((Ref ref, String threadId) {
      void changed() => ref.invalidateSelf();
      forkDmThreadIndexChanges.addListener(changed);
      ref.onDispose(() => forkDmThreadIndexChanges.removeListener(changed));
      return forkDmThreadParentOf(threadId);
    });

/// Whether a thread is known in the DM, from the in-memory index.
final ProviderFamily<bool, String> forkDmHasKnownThreadsProvider = Provider
    .autoDispose
    .family<bool, String>((Ref ref, String dmId) {
      void changed() => ref.invalidateSelf();
      forkDmThreadIndexChanges.addListener(changed);
      ref.onDispose(() => forkDmThreadIndexChanges.removeListener(changed));
      return forkDmHasKnownThreads(dmId);
    });
