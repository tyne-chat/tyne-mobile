// Fork: the people of a DM's thread are the DM's (tyne-chat/tyne#699).
// Thread member lists come per community over the gateway, and the server's
// thread-members route is for bots, so a DM thread's Members opens its DM's
// own member list, which the app holds without a request.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/chat/presentation/sheets/channel_details_sheet.dart';
import 'package:fluxer_app/features/dm/domain/dm_conversation.dart';
import 'package:fluxer_app/features/threads/fork_dm_threads/dm_thread_providers.dart';
import 'package:fluxer_app/material_ui.dart';

Future<void> forkShowDmThreadPeople(
  BuildContext context,
  Channel thread,
) async {
  final ProviderContainer container = ProviderScope.containerOf(context);
  final String? parentId = thread.parentId;
  final DmConversation? dm = parentId == null
      ? null
      : container.read(forkDmConversationProvider(parentId));
  if (dm == null) {
    return;
  }
  await showChannelDetailsSheetAndJump(
    context,
    container: container,
    channel: null,
    dm: dm,
  );
}
