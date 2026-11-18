// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: a name already on screen asks again for its member once a READY or the
// guild's return leaves the cached row unconfirmed (tyne-chat/tyne#614). Both
// signals change outside layout, and neither changes the member's row, so the
// display would otherwise not look again.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/gateway/fork_member_confirmation.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/providers/gateway/gateway_session_recovery_provider.dart';
import 'package:fluxer_app/features/guilds/providers/guild_availability_provider.dart';

/// Whether the cached member of [userId] in [guildId] should be asked for
/// again: unconfirmed in this connection and not asked for yet.
bool forkWatchCachedMemberRefresh(Ref ref, String userId, String guildId) {
  ref
    ..watch(gatewayFullRecoveryProvider)
    ..watch(
      guildAvailabilityProvider.select(
        (Set<String> unavailable) => unavailable.contains(guildId),
      ),
    );
  return ForkMemberConfirmation.of(
    ref.read(fluxerDatabaseProvider),
  ).needsRequest(guildId, userId);
}
