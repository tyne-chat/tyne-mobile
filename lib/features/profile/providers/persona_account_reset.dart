// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/features/chat/data/channel_persona_mention_cache.dart';
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
  ref
    ..invalidate(myPersonasProvider)
    ..invalidate(personaSettingsProvider)
    ..invalidate(systemDisplayTagProvider)
    ..invalidate(activePersonaProvider);
  ChannelPersonaMentionCache.instance.clear();
}
