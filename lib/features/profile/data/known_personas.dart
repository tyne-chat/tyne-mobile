// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/profile/domain/public_persona.dart';
import 'package:fluxer_dart/export.dart';

/// Fork: writes and reads the personas this device knows (`known_personas`),
/// as upstream writes the users a message names into `users` wherever a
/// message arrives (upsertMentionUsersFromSdk) and reads them to show
/// mentions.

/// The owner a row records when the payload names one; otherwise a stored
/// owner is kept.
Value<String?> _owner(String? ownerId) => ownerId == null || ownerId.isEmpty
    ? const Value<String?>.absent()
    : Value<String?>(ownerId);

KnownPersonasCompanion _companion({
  required String id,
  required String name,
  String? avatar,
  int? avatarColor,
  int? color,
  String? displayTagText,
  String? displayTagIcon,
  String? ownerId,
}) => KnownPersonasCompanion.insert(
  id: id,
  name: name,
  avatar: Value(avatar),
  avatarColor: Value(avatarColor),
  color: Value(color),
  displayTagText: Value(displayTagText),
  displayTagIcon: Value(displayTagIcon),
  userId: _owner(ownerId),
);

/// A persona mention in message text: `<@userId:personaId>`. The message's
/// `mention_personas` do not name their owners; the text does.
final RegExp _personaMention = RegExp(r'<@!?(\d+):(\d+)>');

Map<String, String> _mentionOwners(String? content) => <String, String>{
  for (final RegExpMatch match in _personaMention.allMatches(content ?? ''))
    match.group(2)!: match.group(1)!,
};

KnownPersonasCompanion? _fromSubprofile(
  MessageSubprofileResponseSchema? p, {
  String? ownerId,
}) {
  if (p == null || p.id.isEmpty || p.name.isEmpty) {
    return null;
  }
  return _companion(
    ownerId: ownerId,
    id: p.id,
    name: p.name,
    avatar: p.avatar,
    avatarColor: p.avatarColor,
    color: p.color,
    displayTagText: p.displayTagText,
    displayTagIcon: p.displayTagIcon,
  );
}

KnownPersonasCompanion? _fromJson(Object? json, {String? ownerId}) {
  if (json is! Map) {
    return null;
  }
  final Object? id = json['id'];
  final Object? name = json['name'];
  if (id is! String || id.isEmpty || name is! String || name.isEmpty) {
    return null;
  }
  // Only what the payload carries is written, as upstream's user upserts do,
  // so a gateway event without the tag keeps the stored one.
  Value<T?> carried<T>(List<String> keys, T? Function(Object?) read) {
    for (final String key in keys) {
      if (json.containsKey(key)) {
        return Value<T?>(read(json[key]));
      }
    }
    return const Value.absent();
  }

  return KnownPersonasCompanion(
    id: Value(id),
    name: Value(name),
    avatar: carried(<String>['avatar', 'avatar_hash'], (v) => v as String?),
    avatarColor: carried(<String>['avatar_color'], (v) => (v as num?)?.toInt()),
    color: carried(<String>['color'], (v) => (v as num?)?.toInt()),
    displayTagText: carried(<String>['display_tag_text'], (v) => v as String?),
    displayTagIcon: carried(<String>['display_tag_icon'], (v) => v as String?),
    userId: _owner(ownerId),
  );
}

Future<void> _upsertAll(
  FluxerDatabase database,
  Iterable<KnownPersonasCompanion?> rows,
) async {
  final Map<String, KnownPersonasCompanion> byId =
      <String, KnownPersonasCompanion>{
        for (final KnownPersonasCompanion row
            in rows.whereType<KnownPersonasCompanion>())
          row.id.value: row,
      };
  if (byId.isEmpty) {
    return;
  }
  await database.batch((Batch batch) {
    batch.insertAllOnConflictUpdate(database.knownPersonas, byId.values);
  });
}

/// The persona each message was sent as and the personas it mentions, each
/// with its owner.
Future<void> upsertKnownPersonasFromSdk(
  FluxerDatabase database,
  Iterable<MessageResponseSchema> messages,
) => _upsertAll(database, <KnownPersonasCompanion?>[
  for (final MessageResponseSchema message in messages) ...[
    _fromSubprofile(message.subprofile, ownerId: message.author.id),
    for (final MessageSubprofileResponseSchema persona
        in message.mentionPersonas ?? const <MessageSubprofileResponseSchema>[])
      _fromSubprofile(
        persona,
        ownerId: _mentionOwners(message.content)[persona.id],
      ),
  ],
]);

/// The same for a message read as JSON.
Future<void> upsertKnownPersonasFromJson(
  FluxerDatabase database,
  Map<String, dynamic> message,
) {
  final Object? author = message['author'];
  final Map<String, String> mentionOwners = _mentionOwners(
    message['content'] as String?,
  );
  return _upsertAll(database, <KnownPersonasCompanion?>[
    _fromJson(
      message['subprofile'],
      ownerId: author is Map ? author['id'] as String? : null,
    ),
    for (final Object? persona
        in message['mention_personas'] as List<dynamic>? ?? const <dynamic>[])
      _fromJson(
        persona,
        ownerId: persona is Map ? mentionOwners[persona['id']] : null,
      ),
  ]);
}

/// A persona as a gateway event sends it.
Future<void> upsertKnownPersonaFromJson(
  FluxerDatabase database,
  Object? persona, {
  String? ownerId,
}) => _upsertAll(database, <KnownPersonasCompanion?>[
  _fromJson(persona, ownerId: ownerId),
]);

/// A persona looked up by ID, with its owner.
Future<void> upsertKnownPersonaFromLookup(
  FluxerDatabase database,
  PersonaLookupItemSchema item,
) => _upsertAll(database, <KnownPersonasCompanion?>[
  _companion(
    id: item.id,
    name: item.name,
    avatar: item.avatar,
    avatarColor: item.avatarColor,
    color: item.color,
    displayTagText: item.displayTagText,
    displayTagIcon: item.displayTagIcon,
    ownerId: item.userId,
  ),
]);

/// Whether this device already knows a persona.
Future<bool> isKnownPersona(FluxerDatabase database, String personaId) async =>
    await (database.select(
      database.knownPersonas,
    )..where((t) => t.id.equals(personaId))).getSingleOrNull() !=
    null;

/// The personas of an account this device knows: stored with that owner, or
/// on cached messages the account sent as them.
Future<List<String>> knownPersonaIdsOf(
  FluxerDatabase database,
  String userId,
) async {
  final List<QueryRow> rows = await database
      .customSelect(
        'SELECT id FROM known_personas WHERE user_id = ? '
        'UNION SELECT persona_id AS id FROM messages '
        'WHERE author_id = ? AND persona_id IS NOT NULL',
        variables: <Variable<Object>>[
          Variable<String>(userId),
          Variable<String>(userId),
        ],
      )
      .get();
  return <String>[for (final QueryRow row in rows) row.read<String>('id')];
}

/// A persona's profile card. The card carries no display tag, so a stored tag
/// is kept.
KnownPersonasCompanion? _fromProfileCard({
  required String id,
  required String name,
  String? avatar,
  int? avatarColor,
  int? color,
}) => id.isEmpty || name.isEmpty
    ? null
    : KnownPersonasCompanion(
        id: Value(id),
        name: Value(name),
        avatar: Value(avatar),
        avatarColor: Value(avatarColor),
        color: Value(color),
      );

/// A persona looked up through its public profile.
Future<void> upsertKnownPersonaFromPublic(
  FluxerDatabase database,
  PublicPersona persona,
) => _upsertAll(database, <KnownPersonasCompanion?>[
  _fromProfileCard(
    id: persona.id,
    name: persona.name,
    avatar: persona.avatarHash,
    avatarColor: persona.avatarColor,
    color: persona.color,
  ),
]);

/// A persona picked in the mention autocomplete, as the channel's mention list
/// describes it, so that a message still being sent names it: only the
/// server's copy of the message brings its `mention_personas`
/// (tyne-chat/tyne#240). Written only when the device does not know the
/// persona yet: a stored row comes from messages and events, which keep it
/// current, while the list can be older and, for the personas it takes from
/// loaded messages, has no colour of theirs.
Future<void> recordPickedMentionPersona(
  FluxerDatabase database,
  Map<String, dynamic> item,
) async {
  final Object? ownerId = item['owner_user_id'];
  final KnownPersonasCompanion? row = _fromJson(<String, Object?>{
    for (final String key in const <String>[
      'id',
      'name',
      'avatar_hash',
      'color',
      'display_tag_text',
      'display_tag_icon',
    ])
      if (item.containsKey(key)) key: item[key],
  }, ownerId: ownerId is String ? ownerId : null);
  if (row == null) {
    return;
  }
  await database
      .into(database.knownPersonas)
      .insert(row, mode: InsertMode.insertOrIgnore);
}

/// What this device knows about a persona, kept current as rows change.
// The family type is long and says nothing the next line does not.
// ignore: specify_nonobvious_property_types
final knownPersonaProvider = StreamProvider.autoDispose
    .family<KnownPersona?, String>((ref, String personaId) {
      final FluxerDatabase database = ref.watch(fluxerDatabaseProvider);
      return (database.select(
        database.knownPersonas,
      )..where((t) => t.id.equals(personaId))).watchSingleOrNull();
    });
