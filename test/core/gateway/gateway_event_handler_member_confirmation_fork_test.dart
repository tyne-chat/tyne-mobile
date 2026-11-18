// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: after a READY that keeps the cached members, a member embedded in an
// event replaces a cached row this connection has not confirmed
// (tyne-chat/tyne#614), as upstream's web app does for restored members.

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/gateway/fork_member_confirmation.dart';
import 'package:fluxer_app/core/gateway/gateway_event_handler.dart';
import 'package:fluxer_dart/export.dart' show GuildMemberResponse;
import 'package:fluxer_dart/gateway.dart';
import 'package:fluxer_dart/gateway_client/event_parser.dart';

import '../../helpers/open_test_database.dart';
import 'gateway_event_handler_embedded_member_test.dart' hide main;
import 'gateway_event_handler_guild_cleanup_test.dart' hide main;

const EventParser _parser = EventParser();

Future<void> _cacheMember(FluxerDatabase database, {required String nick}) =>
    database.memberDao.upsertMember(
      MembersCompanion.insert(
        userId: forkAuthorId,
        guildId: forkGuildId,
        nick: Value(nick),
        roleIdsJson: const Value('["role-1"]'),
      ),
    );

Future<void> _ready(
  GatewayEventHandler handler, {
  Map<String, dynamic>? rawGuild,
  String sessionId = 'session-1',
}) => handler.handle(
  ReadyEvent(
    sessionId: sessionId,
    user: forkUpstreamReady.user(),
    rawGuilds: <Map<String, dynamic>>[
      rawGuild ?? forkUpstreamReady.guildRaw(id: forkGuildId),
    ],
    privateChannels: const [],
    relationships: const [],
    readStates: const [],
    presences: const [],
  ),
);

Map<String, Object?> _eventJson(String eventType, {required String nick}) =>
    eventType == 'MESSAGE_REACTION_ADD'
    ? forkUpstream.reactionJson(nick: nick)
    : forkUpstream.guildMessageJson(nick: nick);

int _markers = 0;

/// Sends [eventType] and waits until the handler is done with it, without a
/// clock: a message from a new author goes through the same database queue
/// right behind it, so once that author's row exists, the event's own read
/// (and the write it may have led to) has run.
Future<void> _send(
  GatewayEventHandler handler,
  FluxerDatabase database,
  String eventType, {
  required String nick,
}) async {
  await handler.handle(
    _parser.parse(eventType, _eventJson(eventType, nick: nick)),
  );
  final String markerId = 'marker-${_markers++}';
  await handler.handle(
    _parser.parse('MESSAGE_CREATE', <String, Object?>{
      ...forkUpstream.guildMessageJson(nick: 'marker'),
      'id': 'message-$markerId',
      'author': forkUpstream.userJson(markerId),
    }),
  );
  await database.memberDao
      .watchMemberByUserId(markerId, forkGuildId)
      .firstWhere((Member? member) => member != null);
  await database.memberDao.watchMemberByUserId(forkAuthorId, forkGuildId).first;
}

Future<String?> _nick(FluxerDatabase database) async =>
    (await database.memberDao.getMemberByUserId(
      forkAuthorId,
      forkGuildId,
    ))?.nick;

void main() {
  late FluxerDatabase database;

  setUp(() => database = openTestDatabase());

  GatewayEventHandler handlerKeepingCache() => GatewayEventHandler(
    database: database,
    currentUserId: '100',
    isCacheOwnedBy: (String userId) async => true,
  );

  for (final String eventType in <String>[
    'MESSAGE_CREATE',
    'MESSAGE_UPDATE',
    'MESSAGE_REACTION_ADD',
  ]) {
    test('after a cache READY, $eventType replaces an unconfirmed member '
        'once', () async {
      await _cacheMember(database, nick: 'Silvia');
      final GatewayEventHandler handler = handlerKeepingCache();
      await _ready(handler);

      await _send(handler, database, eventType, nick: 'Fox');
      expect(await _nick(database), 'Fox');

      await _send(handler, database, eventType, nick: 'Older');
      expect(await _nick(database), 'Fox');
    });
  }

  test('a member READY brings is confirmed', () async {
    await _cacheMember(database, nick: 'Silvia');
    final GatewayEventHandler handler = handlerKeepingCache();
    await _ready(
      handler,
      rawGuild: <String, dynamic>{
        ...forkUpstreamReady.guildRaw(id: forkGuildId),
        'members': <Map<String, Object?>>[
          <String, Object?>{
            ...forkUpstream.memberJson(nick: 'Ready'),
            'user': forkUpstream.userJson(forkAuthorId),
          },
        ],
      },
    );
    expect(await _nick(database), 'Ready');

    await _send(handler, database, 'MESSAGE_CREATE', nick: 'Fox');
    expect(await _nick(database), 'Ready');
  });

  test('after a full READY, nothing is unconfirmed', () async {
    final GatewayEventHandler handler = GatewayEventHandler(
      database: database,
      currentUserId: '100',
      isCacheOwnedBy: (String userId) async => false,
    );
    await _ready(handler);
    await _cacheMember(database, nick: 'Silvia');

    await _send(handler, database, 'MESSAGE_CREATE', nick: 'Fox');
    expect(await _nick(database), 'Silvia');
  });

  test('RESUMED neither confirms nor forgets', () async {
    await _cacheMember(database, nick: 'Silvia');
    final GatewayEventHandler handler = handlerKeepingCache();
    await _ready(handler);
    await handler.handle(const ResumedEvent());

    await _send(handler, database, 'MESSAGE_CREATE', nick: 'Fox');
    expect(await _nick(database), 'Fox');

    await handler.handle(const ResumedEvent());
    await _send(handler, database, 'MESSAGE_CREATE', nick: 'Older');
    expect(await _nick(database), 'Fox');
  });

  test('a new READY makes confirmed members unconfirmed again', () async {
    await _cacheMember(database, nick: 'Silvia');
    final GatewayEventHandler handler = handlerKeepingCache();
    await _ready(handler);
    await _send(handler, database, 'MESSAGE_CREATE', nick: 'Fox');

    await _ready(handler, sessionId: 'session-2');
    await _send(handler, database, 'MESSAGE_CREATE', nick: 'Again');
    expect(await _nick(database), 'Again');
  });

  test(
    'a guild unavailable in a cache READY keeps unconfirmed members',
    () async {
      await _cacheMember(database, nick: 'Silvia');
      final GatewayEventHandler handler = handlerKeepingCache();
      await _ready(
        handler,
        rawGuild: <String, dynamic>{'id': forkGuildId, 'unavailable': true},
      );

      expect(
        ForkMemberConfirmation.of(
          database,
        ).isUnconfirmed(forkGuildId, forkAuthorId),
        isTrue,
      );
      await _send(handler, database, 'MESSAGE_CREATE', nick: 'Fox');
      expect(await _nick(database), 'Fox');
    },
  );

  test('GUILD_MEMBER_UPDATE confirms', () async {
    await _cacheMember(database, nick: 'Silvia');
    final GatewayEventHandler handler = handlerKeepingCache();
    await _ready(handler);
    await handler.handle(
      _parser.parse('GUILD_MEMBER_UPDATE', <String, Object?>{
        ...forkUpstream.memberJson(nick: 'Updated'),
        'user': forkUpstream.userJson(forkAuthorId),
        'guild_id': forkGuildId,
      }),
    );
    await database.memberDao
        .watchMemberByUserId(forkAuthorId, forkGuildId)
        .firstWhere((Member? member) => member?.nick == 'Updated');

    await _send(handler, database, 'MESSAGE_CREATE', nick: 'Older');
    expect(await _nick(database), 'Updated');
  });

  group('ForkMemberConfirmation', () {
    test('asks for a member once per connection', () {
      final ForkMemberConfirmation confirmation = ForkMemberConfirmation.of(
        database,
      )..startConnection(cacheKept: true, guildIds: <String>['g']);
      expect(confirmation.claimRequests('g', <String>['a', 'b']), <String>[
        'a',
        'b',
      ]);
      expect(confirmation.claimRequests('g', <String>['a', 'b']), isEmpty);
      expect(confirmation.isUnconfirmed('g', 'a'), isTrue);

      // A GUILD_CREATE or GUILD_SYNC of an available guild (it comes whenever
      // the guild is opened) gives nobody a second request.
      forkGuildCreateStored(
        database,
        'g',
        const <GuildMemberResponse>[],
        current: true,
      );
      expect(confirmation.claimRequests('g', <String>['a']), isEmpty);

      confirmation.startConnection(cacheKept: true, guildIds: <String>['g']);
      expect(confirmation.claimRequests('g', <String>['a']), <String>['a']);
    });

    test('a guild READY listed as unavailable is asked for only once its '
        'GUILD_CREATE is stored', () {
      final ForkMemberConfirmation confirmation = ForkMemberConfirmation.of(
        database,
      );
      forkStartMemberConfirmation(
        database,
        fullWipe: false,
        rawGuilds: <Map<String, dynamic>>[
          <String, dynamic>{'id': 'g', 'unavailable': true},
          <String, dynamic>{
            'id': 'hidden',
            'unavailable': true,
            'unavailable_hidden': true,
          },
        ],
      );
      expect(confirmation.isUnconfirmed('g', 'a'), isTrue);
      expect(confirmation.needsRequest('g', 'a'), isFalse);
      expect(confirmation.needsRequest('hidden', 'a'), isFalse);

      // A GUILD_DELETE won the race: still unavailable.
      forkGuildCreateStored(
        database,
        'g',
        const <GuildMemberResponse>[],
        current: false,
      );
      expect(confirmation.needsRequest('g', 'a'), isFalse);

      forkGuildCreateStored(
        database,
        'g',
        const <GuildMemberResponse>[],
        current: true,
      );
      expect(confirmation.needsRequest('g', 'a'), isTrue);
    });

    test(
      'GUILD_DELETE forgets the guild, and an account change everything',
      () {
        final ForkMemberConfirmation confirmation = ForkMemberConfirmation.of(
          database,
        )..startConnection(cacheKept: true, guildIds: <String>['g', 'h']);
        final int ready = confirmation.readyCount;

        confirmation.forgetGuild('g');
        expect(confirmation.isUnconfirmed('g', 'a'), isFalse);
        expect(confirmation.isUnconfirmed('h', 'a'), isTrue);

        confirmation.reset();
        expect(confirmation.isUnconfirmed('h', 'a'), isFalse);
        expect(confirmation.readyCount, ready + 1);
      },
    );

    test('confirmed and full-READY members are not asked for', () {
      final ForkMemberConfirmation confirmation =
          ForkMemberConfirmation.of(database)
            ..startConnection(cacheKept: true, guildIds: <String>['g'])
            ..confirm('g', <String>['a']);
      expect(confirmation.needsRequest('g', 'a'), isFalse);
      expect(confirmation.needsRequest('other', 'a'), isFalse);

      confirmation.startConnection(cacheKept: false, guildIds: <String>['g']);
      expect(confirmation.needsRequest('g', 'b'), isFalse);
    });
  });
}
