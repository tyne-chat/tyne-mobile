// SPDX-License-Identifier: AGPL-3.0-or-later

// Persona aliases (tyne-chat/tyne#707): other names a persona is found by when
// searching or mentioning, never shown.

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/data/channel_persona_mention_cache.dart';
import 'package:fluxer_app/features/chat/data/persona_search_ids.dart';
import 'package:fluxer_app/features/chat/utils/reactions/own_reactions.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/domain/persona_gallery.dart';
import 'package:fluxer_app/features/profile/domain/persona_name_search.dart';
import 'package:fluxer_app/features/profile/domain/public_persona.dart';

Map<String, dynamic> _item(
  String id,
  String name, {
  List<String> aliases = const <String>[],
}) => <String, dynamic>{
  'id': id,
  'name': name,
  'aliases': aliases,
  'owner_user_id': 'u1',
  'owner_username': 'owner',
};

void main() {
  group('personaNameMatchScore', () {
    test('finds a persona by its alias when the name cannot be typed', () {
      expect(personaNameMatches('SΛTVRN', <String>['Saturn'], 'sat'), isTrue);
      expect(
        personaNameMatches('悪賢い', <String>['Sonic', 'Warui'], 'warui'),
        isTrue,
      );
      expect(personaNameMatches('ΞΣNΛ', const <String>[], 'aelena'), isFalse);
    });

    test('lets a stronger match on an alias beat a weaker one on the name, '
        'and takes an opening bracket as the start of a word', () {
      expect(
        personaNameMatchScore('SΛTVRN', <String>['Saturn'], 'saturn'),
        greaterThan(personaNameMatchScore('Lady Saturn', null, 'saturn')),
      );
      expect(
        personaNameMatchScore('Marisol', <String>['Sol'], 'sol'),
        personaNameMatchScore('X', <String>['Sol'], 'sol'),
      );
      expect(
        personaNameMatchScore('神聖狐天使', <String>['Chelsea (Sol)'], 'sol'),
        personaNameMatchScore('神聖狐天使', <String>['Chelsea Sol'], 'sol'),
      );
    });

    test("a typed search name finds the account's own persona by its alias "
        'before any mention list is fetched', () {
      noteOwnPersonasForSearch(
        <({String id, String name, List<String> aliases})>[
          (id: 'own-1', name: 'SΛTVRN', aliases: <String>['Saturn']),
        ],
      );
      addTearDown(() => noteOwnPersonasForSearch(const []));
      expect(resolvePersonaSearchName('saturn'), personaSearchId('own-1'));
    });

    test('ranks a name match above the same match on an alias', () {
      expect(
        personaNameMatchScore('Saturn', null, 'sat'),
        greaterThan(personaNameMatchScore('SΛTVRN', <String>['Saturn'], 'sat')),
      );
      expect(personaNameMatchScore('SΛTVRN', <String>['Saturn'], '  '), 0);
      expect(personaNameMatchScore('SΛTVRN', <String>['Saturn'], 'moon'), -1);
    });
  });

  test('the mention list matches an alias, after a name match', () {
    final List<Map<String, dynamic>> sorted = ChannelPersonaMentionCache
        .instance
        .filterItems(<Map<String, dynamic>>[
          _item('p-1', 'SΛTVRN', aliases: <String>['Sat', 'Saturn']),
          _item('p-2', 'Saturnine'),
          _item('p-3', 'Moss'),
        ], 'sat');

    expect(sorted.map((Map<String, dynamic> i) => i['id']), <String>[
      'p-2',
      'p-1',
    ]);
  });

  test('a typed search name resolves to an alias only when no name has it', () {
    expect(
      resolvePersonaSearchName(
        'saturn',
        known: <Map<String, dynamic>>[
          _item('p-1', 'SΛTVRN', aliases: <String>['Sat', 'Saturn']),
        ],
      ),
      personaSearchId('p-1'),
    );
    expect(
      resolvePersonaSearchName(
        'Saturn',
        known: <Map<String, dynamic>>[
          _item('p-1', 'SΛTVRN', aliases: <String>['Sat', 'Saturn']),
          _item('p-2', 'Saturn'),
        ],
      ),
      personaSearchId('p-2'),
    );
  });

  test('the persona pickers and the gallery match an alias', () {
    const Persona saturn = Persona(
      id: 'p-1',
      name: 'SΛTVRN',
      aliases: <String>['Saturn'],
    );
    expect(personaMatchesQuery(saturn, 'satu'), isTrue);
    expect(filterPersonaGallery(<Persona>[saturn], 'satu'), <Persona>[saturn]);
  });

  test('aliases are stored tidied', () {
    expect(
      normalizePersonaAliases(<String>[' Saturn ', '', 'saturn', 'Sat']),
      <String>['Saturn', 'Sat'],
    );
    expect(
      normalizePersonaAliases(<String>[for (int i = 0; i < 15; i++) 'a$i']),
      hasLength(kPersonaAliasesMax),
    );
    expect(personaAliasesInclude(<String>[' Saturn '], 'saturn'), isTrue);
  });

  test('the alias survives the models, and is not sent with messages', () {
    final Persona persona = Persona.fromJson(<String, dynamic>{
      'id': 'p-1',
      'name': 'SΛTVRN',
      'aliases': <Object?>['Saturn', 3],
    });
    expect(persona.aliases, <String>['Saturn']);
    expect(persona.toJson()['aliases'], <String>['Saturn']);
    final PublicPersona public = persona.toPublicPersona();
    expect(public.aliases, <String>['Saturn']);
    expect(
      PublicPersona.fromJson(public.toJson()).toPersona().aliases,
      <String>['Saturn'],
    );
    expect(persona.toSubprofilePayload(), isNot(contains('aliases')));
  });
}
