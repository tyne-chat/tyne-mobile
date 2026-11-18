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

int _textScore(String text, String q, int prefix, int word, int anywhere) {
  final String lowered = text.toLowerCase();
  if (lowered.startsWith(q)) {
    return prefix;
  }
  if (lowered.contains(' $q') ||
      lowered.contains('-$q') ||
      lowered.contains('_$q')) {
    return word;
  }
  if (lowered.contains(q)) {
    return anywhere;
  }
  return -1;
}

/// The score of [query] against a persona's [name], else its best alias:
/// higher is a better match, -1 when none contains it. The query is trimmed
/// and compared without case; an empty one scores 0.
int personaNameMatchScore(
  String name,
  Iterable<String>? aliases,
  String query,
) {
  final String q = query.trim().toLowerCase();
  if (q.isEmpty) {
    return 0;
  }
  final int byName = _textScore(name, q, _namePrefix, _nameWord, _nameAnywhere);
  if (byName >= 0) {
    return byName;
  }
  int best = -1;
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
