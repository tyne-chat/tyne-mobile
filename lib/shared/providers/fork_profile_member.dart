// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: a profile fetched for a community brings the person's member there;
// upstream showed it in the profile sheet but did not store it, so the chat
// could keep an older nickname next to a sheet showing the new one
// (tyne-chat/tyne#614). Storing it costs no request.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/gateway/fork_member_confirmation.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/shared/services/guild_member_hydration_service.dart';
import 'package:fluxer_app/shared/utils/sdk_converters.dart';
import 'package:fluxer_dart/export.dart';

/// Stores what [profile], fetched for [guildId], says about the person's
/// member there: the member when it has one, and no member when the viewer is
/// in the guild and the person is not (the server leaves the member out only
/// then, or when the viewer is not in the guild either).
Future<void> forkCacheProfileMember(
  Ref ref,
  FluxerDatabase database,
  String? guildId,
  UserProfileFullResponse profile,
) async {
  if (!ref.mounted || guildId == null || guildId.isEmpty) {
    return;
  }
  final GuildMemberResponse? member = profile.guildMember;
  if (member != null) {
    await upsertGuildMembersFromSdk(database, guildId, <GuildMemberResponse>[
      member,
    ]);
    if (ref.mounted) {
      ref.read(guildMemberHydrationServiceProvider).clearNonMembers(
        guildId,
        <String>[member.user.id],
      );
    }
    return;
  }
  final String? viewerId = ref.read(currentUserIdProvider);
  if (viewerId == null || viewerId == profile.user.id) {
    return;
  }
  if (await database.memberDao.getMemberByUserId(viewerId, guildId) == null) {
    return;
  }
  if (!ref.mounted) {
    return;
  }
  await database.memberDao.deleteMember(profile.user.id, guildId);
  ForkMemberConfirmation.of(database).forget(guildId, profile.user.id);
}
