// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/domain/persona_matcher.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';

/// Fork: the persona a message made only of that persona's proxy tags names
/// (tyne-chat/tyne#628): `a:` for the prefix tag `a:`, `[]` for `[` … `]`.
/// Sending such a message selects the persona instead, as the persona picker
/// does. Null when [text] holds anything besides the tags, or no persona's tags
/// match. Personas whose tags are not matched are skipped, as in matching.
/// Only for text alone: with files attached the tags keep naming who sends
/// them, so callers do not ask then.
Persona? forkPersonaSelectedByTags(String text, List<Persona> personas) {
  final String trimmed = text.trim();
  if (trimmed.isEmpty || personas.isEmpty) {
    return null;
  }
  // No latched persona: escapes and the unlatch command play no part here.
  final MatchResult result = matchPersona(
    trimmed,
    personas,
    null,
    hasAttachments: false,
    allowEmptyContent: true,
  );
  if (!result.matched ||
      !result.isFromTag ||
      result.strippedContent.trim().isNotEmpty) {
    return null;
  }
  return result.persona;
}

/// Selects [persona] as the persona picker does: for every chat, or for
/// [channelId] alone when selections are kept per chat. One request, the
/// selection's; a failure is handled as for the picker.
Future<void> forkSelectPersonaByTags(
  WidgetRef ref,
  Persona persona, {
  required String channelId,
}) => ref
    .read(activePersonaProvider.notifier)
    .setActivePersona(persona.id, channelId: channelId);
