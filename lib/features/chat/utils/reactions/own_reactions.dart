// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';

// Fork: which of the account's own identities reacted with an emoji, and what
// a tap on a reaction does about them (tyne-chat/tyne#86). An identity is a
// persona id, or null for the account itself. The rules are the web app's
// (fluxer_app/src/features/persona/utils/OwnReactions.ts and
// PersonaReactionIdentities.ts in tyne-chat/tyne).

/// The own identities that reacted: the account first, then the personas.
///
/// [Reaction.personaReactions] holds only the account's own personas.
List<String?> ownReactedIds(Reaction reaction) => <String?>[
  if (reaction.meRoot) null,
  ...reaction.personaReactions,
];

/// Whether a tap on [reaction]'s chip opens the "Your reactions" sheet instead
/// of reacting: only with "React as several personas at once" on, for an
/// account that has personas, on an emoji one of its identities reacted with.
bool opensOwnReactionsSheet(
  Reaction reaction, {
  required bool multi,
  required bool hasPersonas,
}) => multi && hasPersonas && ownReactedIds(reaction).isNotEmpty;

/// The reaction with this emoji among [reactions], if any.
Reaction? findReaction(
  List<Reaction> reactions, {
  required String emoji,
  String? emojiId,
}) {
  for (final Reaction reaction in reactions) {
    if (reaction.emoji == emoji && reaction.emojiId == emojiId) {
      return reaction;
    }
  }
  return null;
}

/// A value that changes whenever the own identities behind [reaction] change.
///
/// [Reaction]'s equality leaves out `meRoot` and `personaReactions`, so a
/// widget that shows them watches this instead of the reaction.
String ownReactionKey(Reaction? reaction) => reaction == null
    ? ''
    : '${reaction.meRoot ? 1 : 0}|${reaction.personaReactions.join(',')}';

/// Every identity in the order a list shows them: the current one, the
/// account, then the other personas as given.
List<String?> orderedIdentities({
  required String? currentId,
  required List<Persona> personas,
}) {
  final bool currentIsPersona =
      currentId != null && personas.any((Persona p) => p.id == currentId);
  return <String?>[
    if (currentIsPersona) currentId,
    null,
    for (final Persona persona in personas)
      if (!currentIsPersona || persona.id != currentId) persona.id,
  ];
}

/// [orderedIdentities] split for a reaction: the identities that reacted and
/// the current one on top, everyone else below.
({List<String?> top, List<String?> rest}) splitIdentitiesForReaction({
  required Reaction? reaction,
  required String? currentId,
  required List<Persona> personas,
}) {
  final List<String?> ordered = orderedIdentities(
    currentId: currentId,
    personas: personas,
  );
  final String? current = ordered.first;
  final List<String?> top = <String?>[];
  final List<String?> rest = <String?>[];
  for (final String? id in ordered) {
    final bool reacted = reaction?.hasPersonaReacted(id) ?? false;
    (reacted || id == current ? top : rest).add(id);
  }
  return (top: top, rest: rest);
}

/// Below this many personas the whole list fits on screen, so a "Recent"
/// strip would only repeat it.
const int kRecentPersonasMinPersonas = 7;

/// The personas for the "Recent" strip. [ranked] is every persona, most
/// recently and often used first; a persona that was never used (on the
/// server's count or, in [usedHere], on this device since) is not recent.
/// Empty when the strip is not worth showing.
List<Persona> recentPersonas(
  List<Persona> ranked, {
  Set<String> usedHere = const <String>{},
  int limit = 6,
}) {
  if (ranked.length < kRecentPersonasMinPersonas) {
    return const <Persona>[];
  }
  final List<Persona> recent = ranked
      .where(
        (Persona p) =>
            usedHere.contains(p.id) ||
            (p.useCount > 0 && p.lastUsedAtMs != null),
      )
      .take(limit)
      .toList();
  return recent.length >= 2 ? recent : const <Persona>[];
}

/// Whether [persona] matches a search for [query]: its name, pronouns or a
/// proxy tag contains it, ignoring case.
bool personaMatchesQuery(Persona persona, String query) {
  final String needle = query.trim().toLowerCase();
  if (needle.isEmpty) {
    return true;
  }
  bool has(String? text) => text != null && text.toLowerCase().contains(needle);
  return has(persona.name) ||
      has(persona.pronouns) ||
      persona.personaTags.any((PersonaTag t) => has(t.prefix) || has(t.suffix));
}

/// [reactions] with the own identities in [ids] taken off the reaction with
/// this emoji. An identity that had not reacted changes nothing; the reaction
/// goes when nobody is left on it.
List<Reaction> withoutOwnReactions(
  List<Reaction> reactions, {
  required String emoji,
  required Iterable<String?> ids,
  String? emojiId,
}) {
  final List<Reaction> result = <Reaction>[];
  for (final Reaction reaction in reactions) {
    if (reaction.emoji != emoji || reaction.emojiId != emojiId) {
      result.add(reaction);
      continue;
    }
    bool meRoot = reaction.meRoot;
    final List<String> personaReactions = List<String>.of(
      reaction.personaReactions,
    );
    int removed = 0;
    for (final String? id in ids) {
      if (id == null || id == '0') {
        if (meRoot) {
          meRoot = false;
          removed++;
        }
      } else if (personaReactions.remove(id)) {
        removed++;
      }
    }
    if (removed == 0) {
      result.add(reaction);
      continue;
    }
    final int count = reaction.count - removed;
    if (count <= 0) {
      continue;
    }
    result.add(
      Reaction(
        emoji: reaction.emoji,
        emojiId: reaction.emojiId,
        animated: reaction.animated,
        count: count,
        hasReacted: meRoot || personaReactions.isNotEmpty,
        meRoot: meRoot,
        personaReactions: personaReactions,
      ),
    );
  }
  return result;
}
