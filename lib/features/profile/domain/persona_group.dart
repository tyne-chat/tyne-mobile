// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: groups of the account's own personas (tyne-chat/tyne#829), as
// PluralKit has them for members. A persona can be in any number of groups,
// and only the account sees them. The server keeps them
// (`/users/@me/personas/groups`); how the Personas settings page lays them out
// and what the multi-select's Groups sheet sends are the pure functions here.

import 'package:flutter/foundation.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';

/// The fold key of the "Not in a group" section, which has no group id.
const String kUngroupedPersonaSectionKey = 'none';

/// The longest group name the server takes.
const int kPersonaGroupNameMaxLength = 100;

@immutable
class PersonaGroup {
  const PersonaGroup({
    required this.id,
    required this.name,
    this.personaIds = const <String>[],
  });

  /// A group as the server sends it. Null for anything without an id.
  static PersonaGroup? fromJson(Object? json) {
    if (json is! Map) {
      return null;
    }
    final Object? id = json['id'];
    if (id is! String || id.isEmpty) {
      return null;
    }
    final Object? name = json['name'];
    final Object? ids = json['persona_ids'];
    return PersonaGroup(
      id: id,
      name: name is String ? name : '',
      personaIds: <String>[
        if (ids is List)
          for (final Object? item in ids)
            if (item is String) item,
      ],
    );
  }

  /// The groups in a response or an event: a list, or `{groups: [...]}`.
  static List<PersonaGroup> listFromJson(Object? data) {
    final Object? list = data is Map ? data['groups'] : data;
    if (list is! List) {
      return const <PersonaGroup>[];
    }
    return <PersonaGroup>[
      for (final Object? item in list) ?PersonaGroup.fromJson(item),
    ];
  }

  final String id;
  final String name;

  /// The personas in the group, in the order they were added. Deleted ones
  /// stay listed (restoring one puts it back): only live personas show.
  final List<String> personaIds;

  bool contains(String personaId) => personaIds.contains(personaId);

  PersonaGroup copyWith({String? name, List<String>? personaIds}) =>
      PersonaGroup(
        id: id,
        name: name ?? this.name,
        personaIds: personaIds ?? this.personaIds,
      );

  @override
  bool operator ==(Object other) =>
      other is PersonaGroup &&
      other.id == id &&
      other.name == name &&
      listEquals(other.personaIds, personaIds);

  @override
  int get hashCode => Object.hash(id, name, Object.hashAll(personaIds));
}

/// One section of the Personas settings list: a group, or the personas in
/// none ([group] null).
@immutable
class PersonaGroupSection {
  const PersonaGroupSection({
    required this.group,
    required this.personas,
    required this.folded,
  });

  final PersonaGroup? group;

  /// The personas that show in it (folded or not), in the list's order.
  final List<Persona> personas;
  final bool folded;

  /// What its fold is remembered under.
  String get key => group?.id ?? kUngroupedPersonaSectionKey;
}

/// The sections of the Personas settings list: one per group in [groups]'
/// order, then the personas in no group. [personas] are those the list shows
/// (after the chips), in its order; a persona in several groups shows in each.
/// [hideEmpty] (a chip is on) leaves out groups with nothing to show; the
/// "Not in a group" section is left out whenever it is empty. Empty when there
/// are no groups: the list is then flat, as without groups.
List<PersonaGroupSection> buildPersonaGroupSections({
  required List<Persona> personas,
  required List<PersonaGroup> groups,
  required Set<String> folded,
  required bool hideEmpty,
}) {
  if (groups.isEmpty) {
    return const <PersonaGroupSection>[];
  }
  final Set<String> grouped = <String>{
    for (final PersonaGroup g in groups) ...g.personaIds,
  };
  final List<PersonaGroupSection> sections = <PersonaGroupSection>[];
  for (final PersonaGroup group in groups) {
    final Set<String> members = group.personaIds.toSet();
    final List<Persona> shown = <Persona>[
      for (final Persona p in personas)
        if (members.contains(p.id)) p,
    ];
    if (hideEmpty && shown.isEmpty) {
      continue;
    }
    sections.add(
      PersonaGroupSection(
        group: group,
        personas: shown,
        folded: folded.contains(group.id),
      ),
    );
  }
  final List<Persona> loose = <Persona>[
    for (final Persona p in personas)
      if (!grouped.contains(p.id)) p,
  ];
  if (loose.isNotEmpty) {
    sections.add(
      PersonaGroupSection(
        group: null,
        personas: loose,
        folded: folded.contains(kUngroupedPersonaSectionKey),
      ),
    );
  }
  return sections;
}

/// How many of the selected personas a group holds, for its row in the
/// multi-select's Groups sheet: a tick, a dash, or an empty box.
enum PersonaGroupTick { none, some, all }

PersonaGroupTick personaGroupTick(PersonaGroup group, Iterable<String> ids) {
  final List<String> selected = ids.toList();
  if (selected.isEmpty) {
    return PersonaGroupTick.none;
  }
  final int inGroup = selected.where(group.contains).length;
  if (inGroup == 0) {
    return PersonaGroupTick.none;
  }
  return inGroup == selected.length
      ? PersonaGroupTick.all
      : PersonaGroupTick.some;
}

/// What tapping a row does: all of the selected go in, unless all already
/// are; then all of them come out.
PersonaGroupTick nextPersonaGroupTick(PersonaGroupTick current) =>
    current == PersonaGroupTick.all
    ? PersonaGroupTick.none
    : PersonaGroupTick.all;

/// One group's part of a membership request.
@immutable
class PersonaGroupMemberChange {
  const PersonaGroupMemberChange({
    required this.groupId,
    this.add = const <String>[],
    this.remove = const <String>[],
  });

  final String groupId;
  final List<String> add;
  final List<String> remove;

  bool get isEmpty => add.isEmpty && remove.isEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
    'group_id': groupId,
    if (add.isNotEmpty) 'add': add,
    if (remove.isNotEmpty) 'remove': remove,
  };

  @override
  bool operator ==(Object other) =>
      other is PersonaGroupMemberChange &&
      other.groupId == groupId &&
      listEquals(other.add, add) &&
      listEquals(other.remove, remove);

  @override
  int get hashCode =>
      Object.hash(groupId, Object.hashAll(add), Object.hashAll(remove));
}

/// The changes the Groups sheet's Done sends: for each group whose tick was
/// changed to [PersonaGroupTick.all], the selected personas not in it yet; to
/// [PersonaGroupTick.none], those in it. Rows left as they were, and rows that
/// would change nothing, send nothing.
List<PersonaGroupMemberChange> personaGroupChangesForSelection({
  required List<PersonaGroup> groups,
  required List<String> selectedIds,
  required Map<String, PersonaGroupTick> wanted,
}) {
  return <PersonaGroupMemberChange>[
    for (final PersonaGroup group in groups)
      if (wanted[group.id] case final PersonaGroupTick tick)
        PersonaGroupMemberChange(
          groupId: group.id,
          add: tick == PersonaGroupTick.all
              ? <String>[
                  for (final String id in selectedIds)
                    if (!group.contains(id)) id,
                ]
              : const <String>[],
          remove: tick == PersonaGroupTick.none
              ? <String>[
                  for (final String id in selectedIds)
                    if (group.contains(id)) id,
                ]
              : const <String>[],
        ),
  ].where((PersonaGroupMemberChange c) => !c.isEmpty).toList();
}

/// The changes a persona editor's Save sends for [personaId]: into the groups
/// in [added] it is not in yet, out of those in [removed] it is in.
List<PersonaGroupMemberChange> personaGroupChangesForPersona({
  required String personaId,
  required List<PersonaGroup> groups,
  required Set<String> added,
  required Set<String> removed,
}) {
  return <PersonaGroupMemberChange>[
    for (final PersonaGroup group in groups)
      if (added.contains(group.id) && !group.contains(personaId))
        PersonaGroupMemberChange(groupId: group.id, add: <String>[personaId])
      else if (removed.contains(group.id) && group.contains(personaId))
        PersonaGroupMemberChange(
          groupId: group.id,
          remove: <String>[personaId],
        ),
  ];
}
