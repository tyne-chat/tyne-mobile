// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/profile/data/known_personas.dart';
import 'package:fluxer_app/features/profile/domain/public_persona.dart';
import 'package:fluxer_dart/export.dart';

import '../../../fork_support/wait_until.dart';

// Fork: the personas this device knows, written wherever a message arrives as
// upstream writes the users a message names.

Map<String, Object?> _message({
  Map<String, Object?>? subprofile,
  List<Map<String, Object?>>? mentionPersonas,
  String content = 'hi',
}) => <String, Object?>{
  'id': '1',
  'channel_id': 'c1',
  'author': <String, Object?>{
    'id': 'u1',
    'username': 'alice',
    'discriminator': '0001',
    'flags': 0,
  },
  'type': 0,
  'flags': 0,
  'content': content,
  'timestamp': '2026-10-17T00:00:00.000Z',
  'pinned': false,
  'mention_everyone': false,
  'tts': false,
  'mentions': <Object?>[],
  'mention_roles': <String>[],
  'subprofile': ?subprofile,
  'mention_personas': ?mentionPersonas,
};

void main() {
  late FluxerDatabase db;

  setUp(() {
    db = FluxerDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Future<KnownPersona?> known(String id) => (db.select(
    db.knownPersonas,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  test(
    'keeps the persona a message was sent as and those it mentions',
    () async {
      await upsertKnownPersonasFromSdk(db, [
        MessageResponseSchema.fromJson(
          _message(
            subprofile: <String, Object?>{
              'id': 'p1',
              'name': 'Ada',
              'avatar': 'a1a1a1a1',
              'display_tag_text': 'SYS',
            },
            mentionPersonas: [
              <String, Object?>{'id': 'p2', 'name': 'Bob', 'color': 0x112233},
            ],
          ),
        ),
      ]);

      final KnownPersona? ada = await known('p1');
      expect(ada?.name, 'Ada');
      expect(ada?.avatar, 'a1a1a1a1');
      expect(ada?.displayTagText, 'SYS');
      expect((await known('p2'))?.color, 0x112233);
    },
  );

  test(
    'takes what a later message says, as a rename or "Deleted Persona"',
    () async {
      Future<void> mentionedAs(String name) => upsertKnownPersonasFromSdk(db, [
        MessageResponseSchema.fromJson(
          _message(
            mentionPersonas: [
              <String, Object?>{'id': 'p2', 'name': name, 'avatar': 'b0b0b0b0'},
            ],
          ),
        ),
      ]);

      await mentionedAs('Bob');
      await mentionedAs('Robert');
      expect((await known('p2'))?.name, 'Robert');

      await upsertKnownPersonasFromSdk(db, [
        MessageResponseSchema.fromJson(
          _message(
            mentionPersonas: [
              <String, Object?>{'id': 'p2', 'name': 'Deleted Persona'},
            ],
          ),
        ),
      ]);
      final KnownPersona? gone = await known('p2');
      expect(gone?.name, 'Deleted Persona');
      expect(gone?.avatar, isNull);
    },
  );

  test(
    'reads a message as JSON, a gateway persona and a looked-up one',
    () async {
      await upsertKnownPersonasFromJson(
        db,
        _message(
          subprofile: <String, Object?>{'id': 'p1', 'name': 'Ada'},
          mentionPersonas: [
            <String, Object?>{'id': 'p2', 'name': 'Bob'},
            <String, Object?>{'id': 'p3', 'name': ''},
          ],
        ),
      );
      await upsertKnownPersonaFromJson(db, <String, Object?>{
        'id': 'p4',
        'name': 'Cy',
        'avatar_hash': 'c4c4c4c4',
      });
      await upsertKnownPersonaFromPublic(
        db,
        const PublicPersona(id: 'p5', name: 'Di', avatarHash: 'd5d5d5d5'),
      );

      expect((await known('p1'))?.name, 'Ada');
      expect((await known('p2'))?.name, 'Bob');
      expect(await known('p3'), isNull);
      expect((await known('p4'))?.avatar, 'c4c4c4c4');
      expect((await known('p5'))?.avatar, 'd5d5d5d5');
    },
  );

  test('keeps what a gateway persona leaves out', () async {
    await upsertKnownPersonaFromJson(db, <String, Object?>{
      'id': 'p1',
      'name': 'Ada',
      'display_tag_text': 'SYS',
    });
    await upsertKnownPersonaFromJson(db, <String, Object?>{
      'id': 'p1',
      'name': 'Adele',
      'avatar_hash': 'a2a2a2a2',
    });

    final KnownPersona? ada = await known('p1');
    expect(ada?.name, 'Adele');
    expect(ada?.avatar, 'a2a2a2a2');
    expect(ada?.displayTagText, 'SYS');
  });

  test('is cleared with the rest of the account data', () async {
    await upsertKnownPersonaFromJson(db, <String, Object?>{
      'id': 'p1',
      'name': 'Ada',
    });

    await db.clearAccountData();

    expect(await known('p1'), isNull);
  });

  test('tells its readers when a persona changes', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: [fluxerDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    final List<String?> names = <String?>[];
    container.listen(knownPersonaProvider('p1'), (
      _,
      AsyncValue<KnownPersona?> next,
    ) {
      if (next.hasValue) {
        names.add(next.value?.name);
      }
    }, fireImmediately: true);

    await container.read(knownPersonaProvider('p1').future);
    await upsertKnownPersonaFromJson(db, <String, Object?>{
      'id': 'p1',
      'name': 'Ada',
    });
    await waitUntil(() => names.last == 'Ada', 'the new persona to be read');
    await upsertKnownPersonaFromJson(db, <String, Object?>{
      'id': 'p1',
      'name': 'Adele',
    });
    await waitUntil(() => names.last == 'Adele', 'the rename to be read');

    expect(names.first, isNull);
  });

  // The owner of each known persona is kept, so that when an account changes
  // its personas the ones this device holds can be fetched again
  // (tyne-tools#7).
  test('keeps who each persona belongs to: the author, and the account a '
      'mention names', () async {
    await upsertKnownPersonasFromSdk(db, [
      MessageResponseSchema.fromJson(
        _message(
          content: 'hello <@900:202>',
          subprofile: <String, Object?>{'id': 'p1', 'name': 'Ada'},
          mentionPersonas: [
            <String, Object?>{'id': '202', 'name': 'Bob'},
          ],
        ),
      ),
    ]);

    expect((await known('p1'))?.userId, 'u1');
    expect((await known('202'))?.userId, '900');
    expect(await knownPersonaIdsOf(db, '900'), <String>['202']);
    expect(await knownPersonaIdsOf(db, 'u1'), <String>['p1']);
  });

  test('keeps a stored owner when a payload names none', () async {
    await upsertKnownPersonaFromLookup(
      db,
      PersonaLookupItemSchema.fromJson(<String, Object?>{
        'id': 'p3',
        'user_id': 'u3',
        'name': 'Cy',
      }),
    );
    await upsertKnownPersonaFromJson(db, <String, Object?>{
      'id': 'p3',
      'name': 'Cy renamed',
    });

    final KnownPersona? cy = await known('p3');
    expect(cy?.name, 'Cy renamed');
    expect(cy?.userId, 'u3');
  });
}
