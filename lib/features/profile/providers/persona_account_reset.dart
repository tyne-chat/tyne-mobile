// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/gateway/fork_member_confirmation.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/chat/data/channel_persona_mention_cache.dart';
import 'package:fluxer_app/features/profile/data/persona_lookup.dart';
import 'package:fluxer_app/features/profile/providers/multi_persona_reactions_provider.dart';
import 'package:fluxer_app/features/profile/providers/persona_groups_provider.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';

/// Fork: forgets the signed-in account's personas when the account changes
/// (switch, sign-out, expired session), so the next account never sees them.
/// The mention cache is process-wide and holds the account's private personas
/// with their use counts, so it is cleared here too.
void resetPersonaStateForAccountChange(Ref ref) {
  ref.read(myPersonasProvider.notifier).reset();
  ref.read(personaSettingsProvider.notifier).reset();
  unawaited(ref.read(systemDisplayTagProvider.notifier).reset());
  unawaited(ref.read(activePersonaProvider.notifier).reset());
  unawaited(ref.read(multiPersonaReactionsProvider.notifier).reset());
  ref
    ..invalidate(myPersonasProvider)
    ..invalidate(personaSettingsProvider)
    ..invalidate(systemDisplayTagProvider)
    ..invalidate(activePersonaProvider);
  // The groups are loaded again for the next account only where something
  // reads them (tyne-chat/tyne#829).
  if (ref.read(personaGroupsProvider.exists)) {
    ref.invalidate(personaGroupsProvider);
  }
  ChannelPersonaMentionCache.instance.clear();
  // Which cached members the last connection confirmed (tyne-chat/tyne#614).
  ForkMemberConfirmation.of(ref.read(fluxerDatabaseProvider)).reset();
  // Lookups and refreshes still on their way belong to the previous account.
  ref.invalidate(personaLookupBatcherProvider);
}
