// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: how typed text finds a persona by name (tyne-chat/tyne#707). Besides
// its name, a persona may have aliases: other names to find it by, for a name
// written in letters a keyboard does not easily type (`SΛTVRN` found by
// "saturn") or names that are not what it is called. Aliases are never shown;
// they only take part in matching, a little below the name itself. The web
// app's `PersonaNameSearch.ts` (packages/schema) has the same rule.

/// The longest alias the server accepts.
const int kPersonaAliasMaxLength = 100;

/// The most aliases a persona has.
const int kPersonaAliasesMax = 10;

const int _namePrefix = 1000;
const int _nameWord = 800;
const int _nameAnywhere = 500;
const int _aliasPrefix = 900;
const int _aliasWord = 700;
const int _aliasAnywhere = 450;

/// What a word starts after: a space, a dash, an underscore, or an opening
/// bracket ("Chelsea (Sol)").
const List<String> _wordStarts = <String>[' ', '-', '_', '(', '['];

int _textScore(String text, String q, int prefix, int word, int anywhere) {
  final String lowered = text.toLowerCase();
  if (lowered.startsWith(q)) {
    return prefix;
  }
  if (_wordStarts.any((String start) => lowered.contains('$start$q'))) {
    return word;
  }
  if (lowered.contains(q)) {
    return anywhere;
  }
  return -1;
}

/// The score of [query] against a persona's [name] and [aliases], the best of
/// them: higher is a better match, -1 when none contains it. A name always
/// beats the same kind of match on an alias, but a stronger match on an alias
/// beats a weaker one on the name ("Saturn" as an alias outranks "Lady
/// Saturn" as a name). The query is trimmed and compared without case; an
/// empty one scores 0.
int personaNameMatchScore(
  String name,
  Iterable<String>? aliases,
  String query,
) {
  final String q = query.trim().toLowerCase();
  if (q.isEmpty) {
    return 0;
  }
  int best = _textScore(name, q, _namePrefix, _nameWord, _nameAnywhere);
  if (best == _namePrefix) {
    return best;
  }
  for (final String alias in aliases ?? const <String>[]) {
    final int score = _textScore(
      alias,
      q,
      _aliasPrefix,
      _aliasWord,
      _aliasAnywhere,
    );
    if (score > best) {
      best = score;
    }
  }
  return best;
}

/// Whether [query] is in the persona's name or one of its aliases, without
/// case. An empty query matches.
bool personaNameMatches(String name, Iterable<String>? aliases, String query) =>
    personaNameMatchScore(name, aliases, query) >= 0;

/// Whether one of [aliases] is exactly [wanted], without case or outer spaces.
bool personaAliasesInclude(Iterable<String>? aliases, String wanted) {
  final String w = wanted.trim().toLowerCase();
  if (w.isEmpty) {
    return false;
  }
  return (aliases ?? const <String>[]).any(
    (String alias) => alias.trim().toLowerCase() == w,
  );
}

/// Aliases as the server stores them: trimmed, without blanks or repeats
/// (compared without case), the first spelling kept, at most
/// [kPersonaAliasesMax].
List<String> normalizePersonaAliases(Iterable<String> aliases) {
  final Set<String> seen = <String>{};
  final List<String> out = <String>[];
  for (final String raw in aliases) {
    final String alias = raw.trim();
    if (alias.isEmpty || !seen.add(alias.toLowerCase())) {
      continue;
    }
    out.add(alias);
    if (out.length >= kPersonaAliasesMax) {
      break;
    }
  }
  return out;
}

/// Aliases read from JSON: the strings of a list, anything else dropped.
List<String> personaAliasesFromJson(Object? value) => value is List
    ? <String>[
        for (final Object? item in value)
          if (item is String) item,
      ]
    : const <String>[];

// The account's own personas as message search knows them (id, name,
// aliases), kept by `MyPersonasNotifier` whenever its list changes, so a name
// typed after `from:` or `mentions:` finds them even before the mention list
// has been fetched (tyne-chat/tyne#707). Plain data, no provider: the search
// parser has no ref.
List<Map<String, Object?>> _ownPersonasForSearch =
    const <Map<String, Object?>>[];

/// The account's own personas for message search, as mention items.
List<Map<String, Object?>> get ownPersonasForSearch => _ownPersonasForSearch;

/// Replaces [ownPersonasForSearch]: an empty list when signed out.
void noteOwnPersonasForSearch(
  Iterable<({String id, String name, List<String> aliases})> personas,
) {
  _ownPersonasForSearch = List<Map<String, Object?>>.unmodifiable(
    <Map<String, Object?>>[
      for (final ({String id, String name, List<String> aliases}) p in personas)
        <String, Object?>{'id': p.id, 'name': p.name, 'aliases': p.aliases},
    ],
  );
}
