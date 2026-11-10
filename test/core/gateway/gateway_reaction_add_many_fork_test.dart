// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: whose reactions MESSAGE_REACTION_ADD_MANY carries, and as which
// persona (tyne-chat/tyne#597, tyne-chat/tyne#120). The gateway sends several
// reactions to one message together, the account's own among them; the app has
// shown those already, so they must not be counted a second time.

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/gateway/gateway_event_handler.dart';
import 'package:fluxer_app/features/chat/domain/message.dart' as domain;
import 'package:fluxer_dart/gateway.dart';

import '../../helpers/open_test_database.dart';

void main() {
  const String channelId = '200';
  const String messageId = '500';
  const Map<String, dynamic> fox = <String, dynamic>{'name': '🦊', 'id': null};

  Future<FluxerDatabase> seed(List<domain.Reaction> reactions) async {
    final FluxerDatabase db = openTestDatabase();
    await db.messageDao.upsertMessage(
      domain.Message(
        id: messageId,
        channelId: channelId,
        authorId: '300',
        authorName: 'author',
        content: 'hello',
        timestamp: DateTime.utc(2026, 11, 9),
        reactions: reactions,
      ).toCompanion(),
    );
    return db;
  }

  Future<domain.Reaction?> foxOf(FluxerDatabase db) async {
    final row = await db.messageDao.getMessage(channelId, messageId);
    return domain.Message.reactionsFromStorageJson(
      row!.reactionsJson,
    ).where((domain.Reaction r) => r.emoji == '🦊').firstOrNull;
  }

  Future<void> addMany(
    FluxerDatabase db,
    List<Map<String, dynamic>> reactions,
  ) async {
    await GatewayEventHandler(database: db, currentUserId: 'me').handle(
      MessageReactionAddManyEvent(
        channelId: channelId,
        messageId: messageId,
        reactions: reactions,
      ),
    );
    await pumpEventQueue();
  }

  test(
    'your personas’ reactions, already shown, are not counted again',
    () async {
      final FluxerDatabase db = await seed(const <domain.Reaction>[
        domain.Reaction(
          emoji: '🦊',
          count: 2,
          hasReacted: true,
          personaReactions: <String>['p_fox', 'p_bao'],
        ),
      ]);

      await addMany(db, <Map<String, dynamic>>[
        <String, dynamic>{'user_id': 'me', 'emoji': fox, 'persona_id': 'p_fox'},
        <String, dynamic>{'user_id': 'me', 'emoji': fox, 'persona_id': 'p_bao'},
      ]);

      final domain.Reaction? reaction = await foxOf(db);
      expect(reaction?.count, 2);
      expect(reaction?.hasReacted, isTrue);
      expect(reaction?.meRoot, isFalse);
      expect(reaction?.personaReactions, <String>['p_fox', 'p_bao']);
    },
  );

  test(
    'your account’s reaction, already shown, is not counted again',
    () async {
      final FluxerDatabase db = await seed(const <domain.Reaction>[
        domain.Reaction(emoji: '🦊', count: 1, hasReacted: true, meRoot: true),
      ]);

      await addMany(db, <Map<String, dynamic>>[
        <String, dynamic>{'user_id': 'me', 'emoji': fox},
      ]);

      final domain.Reaction? reaction = await foxOf(db);
      expect(reaction?.count, 1);
      expect(reaction?.meRoot, isTrue);
    },
  );

  test('your persona’s reaction from another device shows as yours', () async {
    final FluxerDatabase db = await seed(const <domain.Reaction>[]);

    await addMany(db, <Map<String, dynamic>>[
      <String, dynamic>{'user_id': 'me', 'emoji': fox, 'persona_id': 'p_fox'},
      <String, dynamic>{'user_id': 'someone', 'emoji': fox},
    ]);

    final domain.Reaction? reaction = await foxOf(db);
    expect(reaction?.count, 2);
    expect(reaction?.hasReacted, isTrue);
    expect(reaction?.meRoot, isFalse);
    expect(reaction?.personaReactions, <String>['p_fox']);
  });

  test('other people’s reactions are counted, and are not yours', () async {
    final FluxerDatabase db = await seed(const <domain.Reaction>[]);

    await addMany(db, <Map<String, dynamic>>[
      <String, dynamic>{'user_id': 'alice', 'emoji': fox},
      <String, dynamic>{'user_id': 'bob', 'emoji': fox, 'persona_id': 'p_x'},
    ]);

    final domain.Reaction? reaction = await foxOf(db);
    expect(reaction?.count, 2);
    expect(reaction?.hasReacted, isFalse);
    expect(reaction?.personaReactions, isEmpty);
  });
}
