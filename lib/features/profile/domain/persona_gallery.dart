// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: the rules of an account's "Personas (N)" gallery (tyne-chat/tyne#189):
// who sees which personas, how they are searched and sorted, and how a bio is
// shortened for a card. The web app's gallery follows the same rules.

import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart'
    show comparePersonasByName;
import 'package:fluxer_app/shared/utils/snowflake_time.dart';

/// How the gallery lays its personas out. Stored on the device by [name],
/// never by position.
enum PersonaGalleryView { gallery, list, avatars }

/// The orders the gallery offers. [recentlyUsed] is the owner's alone: the
/// server never tells anyone else when a persona was last used.
enum PersonaGallerySort { name, mostUsed, recentlyUsed }

/// The sorts offered to the owner of the personas, or to anyone else.
List<PersonaGallerySort> personaGallerySorts({required bool isOwner}) => isOwner
    ? PersonaGallerySort.values
    : const <PersonaGallerySort>[
        PersonaGallerySort.name,
        PersonaGallerySort.mostUsed,
      ];

/// Whether others see [persona] in its owner's gallery.
bool isPublicPersona(Persona persona) =>
    persona.visibility == 'public' && !persona.isDeleted;

/// The personas whose name, pronouns or bio contain [query], ignoring case.
/// Searching happens on the device.
List<Persona> filterPersonaGallery(List<Persona> personas, String query) {
  final String needle = query.trim().toLowerCase();
  if (needle.isEmpty) {
    return personas;
  }
  bool has(String? text) => text?.toLowerCase().contains(needle) ?? false;
  return <Persona>[
    for (final Persona persona in personas)
      if (has(persona.name) || has(persona.pronouns) || has(persona.bio))
        persona,
  ];
}

/// [personas] in [sort]'s order.
///
/// The list must arrive in the server's order, the most used first, which is
/// what "Most used" means for someone else's personas: the server sends the
/// order, never the counts. For the owner's own personas it is their use
/// count. [nameOrder] is the device's own name order of the owner's personas
/// (`sortedPersonasProvider`), used when it covers every one of them.
List<Persona> sortPersonaGallery(
  List<Persona> personas,
  PersonaGallerySort sort, {
  required bool isOwner,
  List<String>? nameOrder,
}) {
  final List<Persona> sorted = List<Persona>.of(personas);
  switch (sort) {
    case PersonaGallerySort.name:
      final Map<String, int>? position = nameOrder == null
          ? null
          : <String, int>{
              for (final (int index, String id) in nameOrder.indexed) id: index,
            };
      if (position != null &&
          sorted.every((Persona p) => position.containsKey(p.id))) {
        sorted.sort(
          (Persona a, Persona b) => position[a.id]!.compareTo(position[b.id]!),
        );
      } else {
        sorted.sort(comparePersonasByName);
      }
    case PersonaGallerySort.mostUsed:
      if (isOwner) {
        sorted.sort((Persona a, Persona b) {
          final int byUse = b.useCount.compareTo(a.useCount);
          return byUse != 0 ? byUse : comparePersonasByName(a, b);
        });
      }
    case PersonaGallerySort.recentlyUsed:
      if (!isOwner) {
        sorted.sort(comparePersonasByName);
        break;
      }
      sorted.sort((Persona a, Persona b) {
        final int byTime = (b.lastUsedAtMs ?? -1).compareTo(
          a.lastUsedAtMs ?? -1,
        );
        return byTime != 0 ? byTime : comparePersonasByName(a, b);
      });
  }
  return sorted;
}

/// When [persona] was created: the time in its id.
DateTime? personaCreatedAt(Persona persona) =>
    dateTimeFromUserSnowflakeOrNull(persona.id);

final RegExp _customEmoji = RegExp('<a?(:[A-Za-z0-9_~]+:)[0-9]+>');
final RegExp _mention = RegExp('<(@[!&]?|#)[0-9:]+>');
final RegExp _timestamp = RegExp('<t:-?[0-9]+(:[A-Za-z])?>');
final RegExp _link = RegExp(r'!?\[([^\]]*)\]\([^)]*\)');
final RegExp _angleLink = RegExp(r'<(https?://[^>\s]+)>');
final RegExp _lineMarker = RegExp(
  r'^\s*(#{1,6}\s+|>{1,3}\s?|-#\s+|[-*+]\s+|\d+[.)]\s+)',
  multiLine: true,
);
final RegExp _codeFence = RegExp('```[A-Za-z0-9_+-]*');
final RegExp _emphasis = RegExp(r'(\*{1,3}|_{1,3}|~~|\|\||`)');
final RegExp _escape = RegExp(r'\\([\\`*_{}\[\]()#+\-.!|~>])');
final RegExp _whitespace = RegExp(r'\s+');
const int _escaped = 0xE000;
final RegExp _escapedChar = RegExp('[\uE000-\uE07F]');

/// A bio as plain text for a card or a row: roughly without its markdown,
/// on one line. Null when nothing is left.
String? personaBioPlainText(String? bio) {
  if (bio == null) {
    return null;
  }
  final String text = bio
      .replaceAll(_codeFence, '')
      .replaceAllMapped(_link, (Match m) => m[1] ?? '')
      .replaceAllMapped(_angleLink, (Match m) => m[1] ?? '')
      .replaceAllMapped(_customEmoji, (Match m) => m[1] ?? '')
      .replaceAll(_mention, '')
      .replaceAll(_timestamp, '')
      .replaceAll(_lineMarker, '')
      // An escaped character stands in the private use area until the
      // emphasis markers are gone, then comes back.
      .replaceAllMapped(
        _escape,
        (Match m) => String.fromCharCode(_escaped + m[1]!.codeUnitAt(0)),
      )
      .replaceAll(_emphasis, '')
      .replaceAllMapped(
        _escapedChar,
        (Match m) => String.fromCharCode(m[0]!.codeUnitAt(0) - _escaped),
      )
      .replaceAll(_whitespace, ' ')
      .trim();
  return text.isEmpty ? null : text;
}
