// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: who gets a persona in mention suggestions (tyne-chat/tyne#652). The
// same rule as the server's `PersonaMentionableBy.ts`, and the stored value
// kept through every copy the editor and the settings page make.

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/data/persona_search_ids.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/domain/persona_mention_setting.dart';
import 'package:fluxer_app/features/profile/domain/persona_name_search.dart';
import 'package:fluxer_app/features/profile/domain/public_persona.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';

void main() {
  test('follows visibility until chosen, as suggestions did before', () {
    expect(effectiveMentionableBy(null, 'public'), 'everyone');
    expect(effectiveMentionableBy(null, 'unlisted'), 'everyone');
    expect(effectiveMentionableBy(null, 'private'), 'self');
    expect(effectiveMentionableBy(null, null), 'everyone');
  });

  test('is what was chosen, whatever the visibility', () {
    expect(effectiveMentionableBy('nobody', 'public'), 'nobody');
    expect(effectiveMentionableBy('everyone', 'private'), 'everyone');
    expect(isOwnPersonaSuggested('self', 'unlisted'), isTrue);
    expect(isOwnPersonaSuggested('nobody', 'unlisted'), isFalse);
    expect(isOwnPersonaSuggested(null, 'private'), isTrue);
  });

  test('reads only known values; anything else follows visibility', () {
    expect(personaMentionableByFromJson('nobody'), 'nobody');
    expect(personaMentionableByFromJson('friends'), isNull);
    expect(personaMentionableByFromJson(null), isNull);
  });

  test('the stored value survives JSON, copies and the editor round trip', () {
    final Persona persona = Persona.fromJson(<String, dynamic>{
      'id': 'p1',
      'name': 'Lyra',
      'visibility': 'unlisted',
      'mentionable_by': 'nobody',
    });
    expect(persona.mentionableBy, 'nobody');
    expect(persona.effectiveMentionable, 'nobody');
    expect(persona.toJson()['mentionable_by'], 'nobody');

    final PublicPersona edited = persona.toPublicPersona().copyWith(
      name: 'Lyra (copy)',
    );
    expect(edited.mentionableBy, 'nobody');
    expect(edited.toPersona().mentionableBy, 'nobody');

    expect(persona.copyWith(name: 'x').mentionableBy, 'nobody');
    expect(persona.copyWith(mentionableBy: null).mentionableBy, isNull);
    expect(edited.copyWith(mentionableBy: null).mentionableBy, isNull);
  });

  test("one's own copy set to nobody leaves a typed name to the friend's", () {
    addTearDown(() => noteOwnPersonasForSearch(const []));
    noteOwnPersonasForSearch(
      ownPersonasSearchable(const <Persona>[
        Persona(id: '501', name: 'Lyra', mentionableBy: 'nobody'),
        Persona(id: '502', name: 'Wren', visibility: 'private'),
      ]),
    );
    final List<Map<String, dynamic>> known = <Map<String, dynamic>>[
      ...ownPersonasForSearch,
      <String, dynamic>{'id': '601', 'name': 'Lyra'},
    ];

    expect(
      resolvePersonaSearchName('Lyra', known: known),
      personaSearchId('601'),
    );
    // Private but not set to nobody: still found, as before.
    expect(
      resolvePersonaSearchName('Wren', known: known),
      personaSearchId('502'),
    );
  });
}
