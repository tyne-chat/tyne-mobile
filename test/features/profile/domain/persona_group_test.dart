// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: persona groups (tyne-chat/tyne#829): which personas the Personas
// settings list shows in which section, what the select mode's Groups sheet
// shows and sends, and what the persona editor sends.

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/domain/persona_group.dart';

const Persona _wren = Persona(id: 'w', name: 'Wren');
const Persona _marlowe = Persona(id: 'm', name: 'Marlowe');
const Persona _lyra = Persona(id: 'l', name: 'Lyra');
const Persona _sable = Persona(id: 's', name: 'Sable');

const PersonaGroup _core = PersonaGroup(
  id: 'g1',
  name: 'Core',
  personaIds: <String>['w', 'm'],
);
const PersonaGroup _visitors = PersonaGroup(
  id: 'g2',
  name: 'Visitors',
  // A deleted persona stays listed; it is not one of the live personas.
  personaIds: <String>['l', 'gone', 'm'],
);
const PersonaGroup _empty = PersonaGroup(id: 'g3', name: 'Empty');

/// Each section as text: records holding lists compare by identity.
List<String> _shape(List<PersonaGroupSection> sections) => <String>[
  for (final PersonaGroupSection s in sections) _describe(s),
];

String _describe(PersonaGroupSection s) {
  final String names = s.personas.map((Persona p) => p.name).join(', ');
  final String folded = s.folded ? ' (folded)' : '';
  return '${s.group?.name ?? 'none'}: $names$folded';
}

void main() {
  group('buildPersonaGroupSections', () {
    const List<Persona> all = <Persona>[_lyra, _marlowe, _sable, _wren];

    test('is empty without groups, so the list stays flat', () {
      expect(
        buildPersonaGroupSections(
          personas: all,
          groups: const <PersonaGroup>[],
          folded: const <String>{},
          hideEmpty: false,
        ),
        isEmpty,
      );
    });

    test("a section per group in the server's order, then those in none; "
        "a persona in two groups shows in both, in the list's order", () {
      final List<PersonaGroupSection> sections = buildPersonaGroupSections(
        personas: all,
        groups: const <PersonaGroup>[_core, _visitors, _empty],
        folded: const <String>{'g2'},
        hideEmpty: false,
      );
      expect(_shape(sections), <String>[
        'Core: Marlowe, Wren',
        'Visitors: Lyra, Marlowe (folded)',
        'Empty: ',
        'none: Sable',
      ]);
      expect(sections.last.key, kUngroupedPersonaSectionKey);
      expect(sections.first.key, 'g1');
    });

    test('with a chip on, groups with nothing to show are left out', () {
      final List<PersonaGroupSection> sections = buildPersonaGroupSections(
        personas: const <Persona>[_lyra],
        groups: const <PersonaGroup>[_core, _visitors, _empty],
        folded: const <String>{},
        hideEmpty: true,
      );
      expect(_shape(sections), <String>['Visitors: Lyra']);
    });

    test(
      '"Not in a group" folds by its own key and is left out when empty',
      () {
        final List<PersonaGroupSection> folded = buildPersonaGroupSections(
          personas: all,
          groups: const <PersonaGroup>[_core],
          folded: const <String>{kUngroupedPersonaSectionKey},
          hideEmpty: false,
        );
        expect(folded.last.group, isNull);
        expect(folded.last.folded, isTrue);

        final List<PersonaGroupSection> none = buildPersonaGroupSections(
          personas: const <Persona>[_wren, _marlowe],
          groups: const <PersonaGroup>[_core],
          folded: const <String>{},
          hideEmpty: false,
        );
        // In the list's order (here as given), not the group's.
        expect(_shape(none), <String>['Core: Wren, Marlowe']);
      },
    );
  });

  group('the Groups sheet', () {
    test('a tick when all the selected are in a group, a dash for some', () {
      expect(personaGroupTick(_core, <String>['w', 'm']), PersonaGroupTick.all);
      expect(
        personaGroupTick(_core, <String>['w', 'l']),
        PersonaGroupTick.some,
      );
      expect(personaGroupTick(_core, <String>['l']), PersonaGroupTick.none);
      expect(personaGroupTick(_core, <String>[]), PersonaGroupTick.none);
    });

    test('a tap puts all of them in, unless all already are', () {
      expect(nextPersonaGroupTick(PersonaGroupTick.none), PersonaGroupTick.all);
      expect(nextPersonaGroupTick(PersonaGroupTick.some), PersonaGroupTick.all);
      expect(nextPersonaGroupTick(PersonaGroupTick.all), PersonaGroupTick.none);
    });

    test('Done sends only what changes, for the rows tapped', () {
      final List<PersonaGroupMemberChange> changes =
          personaGroupChangesForSelection(
            groups: const <PersonaGroup>[_core, _visitors, _empty],
            selectedIds: const <String>['w', 'l'],
            wanted: const <String, PersonaGroupTick>{
              // Wren is in Core already: only Lyra goes in.
              'g1': PersonaGroupTick.all,
              // Lyra comes out of Visitors; Wren was never in it.
              'g2': PersonaGroupTick.none,
              // Nothing to take out of an empty group: no change at all.
              'g3': PersonaGroupTick.none,
            },
          );
      expect(changes, const <PersonaGroupMemberChange>[
        PersonaGroupMemberChange(groupId: 'g1', add: <String>['l']),
        PersonaGroupMemberChange(groupId: 'g2', remove: <String>['l']),
      ]);
      expect(changes.first.toJson(), <String, Object?>{
        'group_id': 'g1',
        'add': <String>['l'],
      });
    });

    test('rows left alone send nothing', () {
      expect(
        personaGroupChangesForSelection(
          groups: const <PersonaGroup>[_core],
          selectedIds: const <String>['w'],
          wanted: const <String, PersonaGroupTick>{},
        ),
        isEmpty,
      );
    });
  });

  group('the persona editor', () {
    test('sends the groups the persona joins and leaves, not the others', () {
      expect(
        personaGroupChangesForPersona(
          personaId: 'w',
          groups: const <PersonaGroup>[_core, _visitors, _empty],
          added: const <String>{'g1', 'g3'},
          removed: const <String>{'g2'},
        ),
        const <PersonaGroupMemberChange>[
          PersonaGroupMemberChange(groupId: 'g3', add: <String>['w']),
        ],
      );
      expect(
        personaGroupChangesForPersona(
          personaId: 'm',
          groups: const <PersonaGroup>[_core, _visitors],
          added: const <String>{},
          removed: const <String>{'g2'},
        ),
        const <PersonaGroupMemberChange>[
          PersonaGroupMemberChange(groupId: 'g2', remove: <String>['m']),
        ],
      );
    });
  });

  test("reads the server's list and event, skipping what has no id", () {
    final List<PersonaGroup> groups = PersonaGroup.listFromJson(
      <String, Object?>{
        'groups': <Object?>[
          <String, Object?>{
            'id': 'g1',
            'name': 'Core',
            'persona_ids': <Object?>['w', 3],
          },
          <String, Object?>{'name': 'No id'},
          'junk',
        ],
      },
    );
    expect(groups, const <PersonaGroup>[
      PersonaGroup(id: 'g1', name: 'Core', personaIds: <String>['w']),
    ]);
    expect(PersonaGroup.listFromJson(<Object?>[]), isEmpty);
    expect(PersonaGroup.listFromJson('nonsense'), isEmpty);
  });
}
