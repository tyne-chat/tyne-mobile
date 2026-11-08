// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: the rules of the "Personas (N)" gallery (tyne-chat/tyne#189).

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/domain/persona_gallery.dart';
import 'package:fluxer_app/shared/utils/snowflake_time.dart';

Persona _persona(
  String id,
  String name, {
  String visibility = 'public',
  int useCount = 0,
  int? lastUsedAtMs,
  String? pronouns,
  String? bio,
}) => Persona(
  id: id,
  name: name,
  visibility: visibility,
  useCount: useCount,
  lastUsedAtMs: lastUsedAtMs,
  pronouns: pronouns,
  bio: bio,
);

List<String> _names(List<Persona> personas) => <String>[
  for (final Persona p in personas) p.name,
];

void main() {
  // In the server's order: the most used first.
  final List<Persona> serverOrder = <Persona>[
    _persona('3', 'Cleo', useCount: 9, lastUsedAtMs: 100),
    _persona('1', '✨Ash', useCount: 5, lastUsedAtMs: 300),
    _persona('2', 'bea', useCount: 7, lastUsedAtMs: 200),
  ];

  group('sortPersonaGallery', () {
    test('by name ignores case and leading decoration', () {
      expect(
        _names(
          sortPersonaGallery(
            serverOrder,
            PersonaGallerySort.name,
            isOwner: false,
          ),
        ),
        <String>['✨Ash', 'bea', 'Cleo'],
      );
    });

    test('by name follows the device order when it covers every persona', () {
      expect(
        _names(
          sortPersonaGallery(
            serverOrder,
            PersonaGallerySort.name,
            isOwner: true,
            nameOrder: const <String>['2', '3', '1'],
          ),
        ),
        <String>['bea', 'Cleo', '✨Ash'],
      );
      // An order missing one falls back to the plain one.
      expect(
        _names(
          sortPersonaGallery(
            serverOrder,
            PersonaGallerySort.name,
            isOwner: true,
            nameOrder: const <String>['2', '3'],
          ),
        ),
        <String>['✨Ash', 'bea', 'Cleo'],
      );
    });

    test("most used keeps the server's order for someone else's personas", () {
      // The use counts on these personas are not the server's: someone
      // else's personas never carry any, so only the order counts.
      expect(
        _names(
          sortPersonaGallery(
            serverOrder,
            PersonaGallerySort.mostUsed,
            isOwner: false,
          ),
        ),
        <String>['Cleo', '✨Ash', 'bea'],
      );
    });

    test('most used is by use count for the owner', () {
      expect(
        _names(
          sortPersonaGallery(
            serverOrder,
            PersonaGallerySort.mostUsed,
            isOwner: true,
          ),
        ),
        <String>['Cleo', 'bea', '✨Ash'],
      );
    });

    test('recently used is by last use for the owner, never used last', () {
      final List<Persona> withNever = <Persona>[
        _persona('4', 'Dee'),
        ...serverOrder,
      ];
      expect(
        _names(
          sortPersonaGallery(
            withNever,
            PersonaGallerySort.recentlyUsed,
            isOwner: true,
          ),
        ),
        <String>['✨Ash', 'bea', 'Cleo', 'Dee'],
      );
    });

    test('recently used falls back to names for anyone else', () {
      expect(
        _names(
          sortPersonaGallery(
            serverOrder,
            PersonaGallerySort.recentlyUsed,
            isOwner: false,
          ),
        ),
        <String>['✨Ash', 'bea', 'Cleo'],
      );
    });

    test('does not change the list it is given', () {
      sortPersonaGallery(serverOrder, PersonaGallerySort.name, isOwner: true);
      expect(_names(serverOrder), <String>['Cleo', '✨Ash', 'bea']);
    });
  });

  test('"Recently used" is offered to the owner only', () {
    expect(
      personaGallerySorts(isOwner: false),
      isNot(contains(PersonaGallerySort.recentlyUsed)),
    );
    expect(
      personaGallerySorts(isOwner: true),
      contains(PersonaGallerySort.recentlyUsed),
    );
  });

  group('filterPersonaGallery', () {
    final List<Persona> personas = <Persona>[
      _persona('1', 'Ash', pronouns: 'they/them'),
      _persona('2', 'Bea', bio: 'Loves **gardening**'),
      _persona('3', 'Cleo', pronouns: 'she/her'),
    ];

    test('matches name, pronouns and bio, ignoring case', () {
      expect(_names(filterPersonaGallery(personas, 'ASH')), <String>['Ash']);
      expect(_names(filterPersonaGallery(personas, 'she')), <String>['Cleo']);
      expect(_names(filterPersonaGallery(personas, 'garden')), <String>['Bea']);
    });

    test('an empty search keeps everything', () {
      expect(filterPersonaGallery(personas, '  '), personas);
    });

    test('a search matching nothing gives nothing', () {
      expect(filterPersonaGallery(personas, 'zzz'), isEmpty);
    });
  });

  test('only public personas count as public', () {
    expect(isPublicPersona(_persona('1', 'A')), isTrue);
    expect(
      isPublicPersona(_persona('1', 'A', visibility: 'unlisted')),
      isFalse,
    );
    expect(isPublicPersona(_persona('1', 'A', visibility: 'private')), isFalse);
    expect(
      isPublicPersona(
        Persona(
          id: '1',
          name: 'A',
          visibility: 'public',
          deletedAt: DateTime(2026),
        ),
      ),
      isFalse,
    );
  });

  group('personaBioPlainText', () {
    test('drops markdown and joins lines', () {
      expect(
        personaBioPlainText(
          '# Hi\n**Bold** and _soft_ ~~gone~~ ||spoiler||\n> quoted `code`',
        ),
        'Hi Bold and soft gone spoiler quoted code',
      );
    });

    test('keeps the text of links, emoji names and escaped characters', () {
      expect(
        personaBioPlainText(
          r'See [my site](https://example.com) <:wave:123> \*not bold\*',
        ),
        'See my site :wave: *not bold*',
      );
    });

    test('drops mentions and gives null for nothing', () {
      expect(personaBioPlainText('<@123> '), isNull);
      expect(personaBioPlainText(null), isNull);
      expect(personaBioPlainText('   '), isNull);
    });
  });

  test('a persona was created when its id says', () {
    final DateTime when = DateTime.utc(2026, 3, 14, 12);
    final Persona persona = _persona(snowflakeFromDateTime(when), 'A');
    expect(personaCreatedAt(persona), when);
  });
}
