// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: a profile fetched for a community brings the person's member there;
// upstream showed it in the profile sheet but did not store it, so the chat
// could keep an older nickname next to a sheet showing the new one
// (tyne-chat/tyne#614). Storing it costs no request.

import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/shared/utils/sdk_converters.dart';
import 'package:fluxer_dart/export.dart';

Future<void> forkCacheProfileMember(
  FluxerDatabase database,
  String? guildId,
  UserProfileFullResponse profile,
) async {
  final GuildMemberResponse? member = profile.guildMember;
  if (guildId == null || guildId.isEmpty || member == null) {
    return;
  }
  await upsertGuildMembersFromSdk(database, guildId, <GuildMemberResponse>[
    member,
  ]);
}
