// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/widgets.dart' show StringCharacters;

/// The longest persona name the API takes, in UTF-16 code units
/// (`String.length`), as it counts.
const int _kPersonaNameMax = 100;

final RegExp _numberedName = RegExp(r'^(.*\S)\s+\(\d+\)$');

/// The longest start of [text] that fits in [max] code units, cut only between
/// whole characters.
String _fittingStart(String text, int max) {
  final StringBuffer start = StringBuffer();
  for (final String character in text.characters) {
    if (start.length + character.length > max) {
      break;
    }
    start.write(character);
  }
  return start.toString();
}

/// The name for a copy of the persona called [name]: the name with the first
/// free number, "Lyra (2)", "Lyra (3)"…, shortening the name, between whole
/// characters, where the number would not fit. A copy of a copy counts on from
/// the persona it copied ("Lyra (2)", with a Lyra, gives "Lyra (3)"); any
/// other number in brackets is part of the name ("Lyra (2026)" gives
/// "Lyra (2026) (2)"). Names compare trimmed and ignoring case, and the copy
/// never takes the name itself. The web app's `duplicatePersonaName`
/// (`PersonaDuplicate.ts`) has the same rule (tyne-chat/tyne#599).
String duplicatePersonaName(String name, Iterable<String> takenNames) {
  final String trimmed = name.trim();
  final Set<String> taken = <String>{
    for (final String n in takenNames) n.trim().toLowerCase(),
    trimmed.toLowerCase(),
  };
  final RegExpMatch? numbered = _numberedName.firstMatch(trimmed);
  final String? counted = numbered?.group(1);
  final String base = counted != null && taken.contains(counted.toLowerCase())
      ? counted
      : trimmed;
  for (int n = 2; n < 10000; n++) {
    final String suffix = ' ($n)';
    final String candidate =
        '${_fittingStart(base, _kPersonaNameMax - suffix.length).trimRight()}$suffix';
    if (!taken.contains(candidate.toLowerCase())) {
      return candidate;
    }
  }
  return trimmed;
}
