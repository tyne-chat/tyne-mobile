// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: the pieces of the thread UI that threads in DMs add, and the unread
// counts the Threads button, the thread chip and the thread browser show in
// DMs and communities alike (tyne-chat/tyne#699).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/media/fluxer_media_url.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/channels/domain/unread_state.dart';
import 'package:fluxer_app/features/channels/providers/channel_providers.dart';
import 'package:fluxer_app/features/channels/utils/navigation/navigate_to_channel_content.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/channel/header/channel_header_icon_button.dart';
import 'package:fluxer_app/features/chat/utils/channel_header_utils.dart';
import 'package:fluxer_app/features/dm/domain/dm_conversation.dart';
import 'package:fluxer_app/features/dm/presentation/widgets/group_dm_avatar.dart';
import 'package:fluxer_app/features/dm/providers/dm_view_model.dart';
import 'package:fluxer_app/features/mature_content/providers/mature_content_agreements_provider.dart';
import 'package:fluxer_app/features/shell/navigation/shell_chat_back.dart';
import 'package:fluxer_app/features/threads/data/threads_repository.dart';
import 'package:fluxer_app/features/threads/fork_dm_threads/dm_thread_providers.dart';
import 'package:fluxer_app/features/threads/fork_dm_threads/dm_threads.dart';
import 'package:fluxer_app/features/threads/presentation/thread_browser_sheet.dart';
import 'package:fluxer_app/features/threads/presentation/thread_header_buttons.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/icons/phosphor.dart';

/// A red count pinned to the top corner of a round header button.
class ForkThreadsButtonCount extends StatelessWidget {
  const ForkThreadsButtonCount({
    required this.count,
    required this.child,
    super.key,
  });

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return child;
    }
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        child,
        PositionedDirectional(
          end: -4,
          top: -4,
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: FluxerBadge.count(
                count: count,
                cutoutColor: shellChannelHeaderBackgroundColor(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The phone header's Threads button for a DM: there once the app knows of
/// a thread in the DM, with the unread count of the threads it follows.
/// Never folded away.
class ForkDmThreadsHeaderButton extends ConsumerWidget {
  const ForkDmThreadsHeaderButton({required this.dmId, super.key});

  final String dmId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!watchForkDmShowsThreadsButton(ref, dmId)) {
      return const SizedBox.shrink();
    }
    final Channel? parent = ref.watch(forkDmThreadParentProvider(dmId));
    if (parent == null) {
      return const SizedBox.shrink();
    }
    final int count = watchForkDmThreadsUnread(ref, dmId).mentionCount;
    return ForkThreadsButtonCount(
      count: count,
      child: FluxerButton.circle(
        icon: PhosphorIconsFill.chatsCircle,
        variant: FluxerButtonVariant.secondary,
        size: FluxerButtonSize.small,
        iconSize: 20,
        semanticLabel: FluxerLocalizations.of(context).threadBrowserTitle,
        onPressed: () =>
            unawaited(showThreadBrowserSheet(context, ref, parent)),
      ),
    );
  }
}

/// The wide header's Threads button for a DM, as [ForkDmThreadsHeaderButton].
class ForkDmThreadsToolbarButton extends ConsumerWidget {
  const ForkDmThreadsToolbarButton({required this.dmId, super.key});

  final String dmId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!watchForkDmShowsThreadsButton(ref, dmId)) {
      return const SizedBox.shrink();
    }
    final Channel? parent = ref.watch(forkDmThreadParentProvider(dmId));
    if (parent == null) {
      return const SizedBox.shrink();
    }
    return ForkThreadsButtonCount(
      count: watchForkDmThreadsUnread(ref, dmId).mentionCount,
      child: ChannelHeaderIconButton(
        icon: PhosphorIconsFill.chatsCircle,
        label: FluxerLocalizations.of(context).threadBrowserTitle,
        onPressed: () =>
            unawaited(showThreadBrowserSheet(context, ref, parent)),
      ),
    );
  }
}

/// Upstream's phone Threads/Members button, with the unread count of the
/// followed threads on a channel's Threads button, and no Members button in
/// a 1:1 DM's thread (the two people in it are the DM's; in a group DM's
/// thread, Members opens the group's own list).
class ForkThreadHeaderMobileButton extends ConsumerWidget {
  const ForkThreadHeaderMobileButton({required this.channel, super.key});

  final Channel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (channel.isThread) {
      if (watchForkIsOneToOneDmThread(ref, channel)) {
        return const SizedBox.shrink();
      }
      return ThreadHeaderMobileButton(channel: channel);
    }
    if (watchMatureContentGateUp(ref, channel.id)) {
      return ThreadHeaderMobileButton(channel: channel);
    }
    final ForkThreadsUnread unread = ref.watch(
      forkParentThreadsUnreadProvider((
        guildId: channel.guildId,
        parentId: channel.id,
      )),
    );
    return ForkThreadsButtonCount(
      count: unread.mentionCount,
      child: ThreadHeaderMobileButton(channel: channel),
    );
  }
}

/// The DM list's mark for a DM whose followed threads have news: the
/// threads icon at half size and the red count of their unread mentions.
class ForkDmThreadsMark extends ConsumerWidget {
  const ForkDmThreadsMark({required this.dmId, super.key});

  final String dmId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!watchForkDmHasThreads(ref, dmId)) {
      return const SizedBox.shrink();
    }
    final ForkThreadsUnread unread = watchForkDmThreadsUnread(ref, dmId);
    if (!unread.hasNews) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 4, end: 4),
      child: Semantics(
        label: FluxerLocalizations.of(context).threadBrowserTitle,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            PhosphorIcon(
              PhosphorIconsFill.chatsCircle,
              size: 12,
              color: context.colors.textSecondary,
            ),
            if (unread.mentionCount > 0) ...<Widget>[
              const SizedBox(width: 2),
              ExcludeSemantics(
                child: FluxerBadgeEntrance(
                  child: FluxerBadge.count(count: unread.mentionCount),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The DM row's own count with the threads mark beside it.
class ForkDmRowCountsWithThreads extends StatelessWidget {
  const ForkDmRowCountsWithThreads({
    required this.dmId,
    required this.children,
    super.key,
  });

  final String dmId;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      ForkDmThreadsMark(dmId: dmId),
      ...children,
    ],
  );
}

/// A thread's red count of unread mentions, for its chip under the starter
/// message.
class ForkThreadChipCount extends ConsumerWidget {
  const ForkThreadChipCount({required this.threadId, super.key});

  final String threadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int count = watchForkThreadUnread(ref, threadId)?.mentionCount ?? 0;
    if (count <= 0) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6),
      child: ExcludeSemantics(child: FluxerBadge.count(count: count)),
    );
  }
}

/// Adds a thread's red count, as on its chip, to the end of its "started a
/// thread" notice: a thread started from the + menu has no chip. The count is a
/// widget, so it follows the read state and takes no room at zero.
void forkAddThreadCreatedCount(List<InlineSpan> spans, Message message) {
  final String? threadId = message.messageReference?.channelId;
  if (message.type != messageTypeThreadCreated || threadId == null) {
    return;
  }
  spans.add(
    WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: ForkThreadChipCount(threadId: threadId),
    ),
  );
}

/// A thread browser row's unread state: a red count for unread mentions,
/// otherwise a dot for unread messages.
class ForkThreadRowUnread extends ConsumerWidget {
  const ForkThreadRowUnread({required this.threadId, super.key});

  final String threadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UnreadState? unread = watchForkThreadUnread(ref, threadId);
    if (unread == null || !unread.hasUnread) {
      return const SizedBox.shrink();
    }
    if (unread.mentionCount > 0) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(start: 6),
        child: ExcludeSemantics(
          child: FluxerBadge.count(count: unread.mentionCount),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.colors.textPrimary,
        ),
      ),
    );
  }
}

/// Moves the threads with unread messages to the front of [threads],
/// keeping the order within each part.
void forkSortThreadsWithNewsFirst(WidgetRef ref, List<Channel> threads) {
  final List<Channel> withNews = <Channel>[];
  final List<Channel> rest = <Channel>[];
  for (final Channel thread in threads) {
    final bool news = watchForkThreadUnread(ref, thread.id)?.hasUnread ?? false;
    (news ? withNews : rest).add(thread);
  }
  threads
    ..clear()
    ..addAll(withNews)
    ..addAll(rest);
}

/// Under a DM thread's title: who the DM is with (or the group), small;
/// tapping it opens the DM.
class ForkDmThreadParentLine extends ConsumerWidget {
  const ForkDmThreadParentLine({required this.thread, super.key});

  final Channel thread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!forkIsDmThread(thread)) {
      return const SizedBox.shrink();
    }
    final DmConversation? dm = watchForkDmThreadParent(ref, thread.id);
    if (dm == null) {
      return const SizedBox.shrink();
    }
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final String name = resolveChannelHeaderTitle(
      ref,
      channelId: dm.id,
      l10n: l10n,
      channel: null,
      dm: dm,
      isPersonalNotes: false,
    );
    const double avatarSize = 16;
    final Color color = context.colors.textPrimaryMuted;
    return Semantics(
      button: true,
      label: l10n.userProfileOpenDm,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => unawaited(
          navigateToDmChannelContent(
            context: context,
            ref: ref,
            channelId: dm.id,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (dm.isGroup)
                GroupDmAvatar.conversation(dm, size: avatarSize)
              else
                FluxerAvatar.user(
                  userId: dm.recipientId,
                  imageUrl: FluxerMediaUrl.userAvatar(
                    userId: dm.recipientId,
                    hash: dm.recipientAvatar,
                  ),
                  fallbackText: dm.recipientName,
                  size: avatarSize,
                  showStatus: false,
                ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  name,
                  style: context.textStyles.timestamp.copyWith(
                    color: color,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fetches the DM thread [channelId] when it is opened by id and the device
/// does not have it (a push tap, a link, a closed or imported thread), as
/// upstream's ThreadRouteGate does for a community's threads. It asks only
/// once the DM list has loaded and the id is neither a DM, a stored channel
/// nor a known DM thread, once per id, and never again on failure: one
/// request per opening. Draws nothing.
class ForkDmThreadRouteFetch extends ConsumerStatefulWidget {
  const ForkDmThreadRouteFetch({required this.channelId, super.key});

  final String channelId;

  @override
  ConsumerState<ForkDmThreadRouteFetch> createState() =>
      _ForkDmThreadRouteFetchState();
}

class _ForkDmThreadRouteFetchState
    extends ConsumerState<ForkDmThreadRouteFetch> {
  final Set<String> _asked = <String>{};

  @override
  Widget build(BuildContext context) {
    final String channelId = widget.channelId;
    final bool dmsLoaded = ref.watch(
      dmViewModelProvider.select(
        (DmViewState state) => state.hasReceivedInitialConversations,
      ),
    );
    final bool isDm = ref.watch(forkDmConversationProvider(channelId)) != null;
    final AsyncValue<Channel?> row = ref.watch(channelByIdProvider(channelId));
    final bool known =
        ref.watch(forkDmThreadParentOfProvider(channelId)) != null;
    if (dmsLoaded &&
        !isDm &&
        !known &&
        row.hasValue &&
        row.value == null &&
        _asked.add(channelId)) {
      unawaited(
        ref
            .read(threadsRepositoryProvider)
            .fetch(guildId: forkDmThreadGuildKey, threadId: channelId)
            .then<void>((_) {}, onError: (Object _) {}),
      );
    }
    return const SizedBox.shrink();
  }
}
