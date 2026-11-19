// SPDX-License-Identifier: AGPL-3.0-or-later

// Who gets a persona in mention suggestions and in search's `from:` /
// `mentions:` suggestions (tyne-chat/tyne#652): everyone, only its owner's
// account, or nobody. A convenience setting for copies of other people's
// personas: it hides nothing else, and a persona keeps speaking as before.
// The server's `packages/schema/src/domains/persona/PersonaMentionableBy.ts`
// states the same rule.

/// The values of a persona's `mentionable_by`, as the server sends them.
abstract final class PersonaMentionableBy {
  static const String everyone = 'everyone';
  static const String self = 'self';
  static const String nobody = 'nobody';

  static const List<String> values = <String>[everyone, self, nobody];
}

/// The stored setting read from JSON: null when absent or unknown, which
/// means the persona follows its visibility.
String? personaMentionableByFromJson(Object? raw) =>
    raw is String && PersonaMentionableBy.values.contains(raw) ? raw : null;

/// What a stored setting means: null follows visibility, a private persona
/// only for its owner and any other for everyone.
String effectiveMentionableBy(String? stored, String? visibility) {
  if (stored != null) {
    return stored;
  }
  return visibility == 'private'
      ? PersonaMentionableBy.self
      : PersonaMentionableBy.everyone;
}

/// Whether one of the account's own personas belongs in its own suggestions:
/// unless it is for nobody.
bool isOwnPersonaSuggested(String? stored, String? visibility) =>
    effectiveMentionableBy(stored, visibility) != PersonaMentionableBy.nobody;
