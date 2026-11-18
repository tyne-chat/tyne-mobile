// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: cached members a READY left unconfirmed are asked for again through
// the gateway only, at most once per connection, and never through the
// per-user REST fallback (tyne-chat/tyne#614). Counts the requests with the
// data missing, with the reply leaving members out, with the request failing,
// and with the socket down.

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/gateway/fork_member_confirmation.dart';
import 'package:fluxer_app/features/members/providers/guild_member_chunk_waiter.dart';
import 'package:fluxer_app/shared/services/guild_member_hydration_service.dart';
import 'package:fluxer_dart/gateway.dart';

import '../../helpers/open_test_database.dart';
import 'guild_member_hydration_service_test.dart' hide main;

const String _guildId = 'guild-1';

class _SwitchableGateway extends ForkRecordingGateway {
  GatewayState current = GatewayState.connected;

  @override
  GatewayState get state => current;
}

class _Setup {
  _Setup({Duration chunkTimeout = kGuildMemberHydrationChunkTimeout})
    : database = openTestDatabase() {
    service = GuildMemberHydrationService(
      database: database,
      client: forkClientWithAdapter(rest),
      chunkWaiter: waiter,
      readGateway: () => gateway,
      chunkTimeout: chunkTimeout,
    );
  }

  final FluxerDatabase database;
  final ForkRecordingAdapter rest = ForkRecordingAdapter();
  final GuildMemberChunkWaiter waiter = GuildMemberChunkWaiter();
  final _SwitchableGateway gateway = _SwitchableGateway();
  late final GuildMemberHydrationService service;

  ForkMemberConfirmation get confirmation =>
      ForkMemberConfirmation.of(database);

  Future<void> cache(Iterable<String> userIds) async {
    for (final String userId in userIds) {
      await database.memberDao.upsertMember(
        MembersCompanion.insert(
          userId: userId,
          guildId: _guildId,
          nick: const Value('old'),
          roleIdsJson: const Value('[]'),
        ),
      );
    }
  }

  void cacheReady() => confirmation.startConnection(
    cacheKept: true,
    guildIds: <String>[_guildId],
  );

  /// The gateway answers with these members, written as the chunk handler
  /// writes them.
  void answerWith(Set<String> present) {
    gateway.onRequest = (ForkRecordedRequest request) async {
      final List<String> returned = request.userIds
          .where(present.contains)
          .toList();
      for (final String userId in returned) {
        await database.memberDao.upsertMember(
          MembersCompanion.insert(
            userId: userId,
            guildId: _guildId,
            nick: const Value('new'),
          ),
        );
      }
      confirmation.confirm(_guildId, returned);
      waiter.notifyChunk(
        nonce: request.nonce,
        chunkCount: 1,
        userIds: returned,
      );
    };
  }

  Future<void> hydrate(Iterable<String> userIds) =>
      service.hydrateMembers(guildId: _guildId, userIds: userIds);

  Future<String?> nick(String userId) async =>
      (await database.memberDao.getMemberByUserId(userId, _guildId))?.nick;
}

void main() {
  test('one gateway request for K unconfirmed members, no REST, and none '
      'again in the same connection', () async {
    final _Setup s = _Setup();
    final List<String> ids = <String>[for (int i = 0; i < 150; i++) 'u$i'];
    await s.cache(ids);
    s
      ..cacheReady()
      ..answerWith(ids.toSet());

    await s.hydrate(ids);
    await s.hydrate(ids);

    expect(s.gateway.requests, hasLength(2));
    expect(
      s.gateway.requests.expand((ForkRecordedRequest r) => r.userIds).toSet(),
      ids.toSet(),
    );
    expect(s.rest.requestCount, 0);
    expect(await s.nick('u0'), 'new');
  });

  test('confirmed members and a connection without a kept cache send '
      'nothing', () async {
    final _Setup s = _Setup();
    await s.cache(<String>['a', 'b']);
    s.cacheReady();
    s.confirmation.confirm(_guildId, <String>['a', 'b']);
    await s.hydrate(<String>['a', 'b']);

    s.confirmation.startConnection(
      cacheKept: false,
      guildIds: <String>[_guildId],
    );
    await s.hydrate(<String>['a', 'b']);

    expect(s.gateway.requests, isEmpty);
    expect(s.rest.requestCount, 0);
  });

  test('a request that fails is not retried in the connection, and never '
      'goes to REST', () async {
    final _Setup s = _Setup(chunkTimeout: Duration.zero);
    await s.cache(<String>['a']);
    s.cacheReady();

    await s.hydrate(<String>['a']);
    await s.hydrate(<String>['a']);
    await s.hydrate(<String>['a']);

    expect(s.gateway.requests, hasLength(1));
    expect(s.rest.requestCount, 0);
    expect(await s.nick('a'), 'old');
    expect(s.confirmation.isUnconfirmed(_guildId, 'a'), isTrue);
  });

  test('a missing member still falls back to REST; an unconfirmed one in '
      'the same request does not', () async {
    final _Setup s = _Setup(chunkTimeout: Duration.zero);
    await s.cache(<String>['cached']);
    s.cacheReady();

    await s.hydrate(<String>['cached', 'user-1']);

    expect(s.gateway.requests.single.userIds.toSet(), <String>{
      'cached',
      'user-1',
    });
    expect(s.rest.requestedPaths, <String>[
      '/v1/guilds/$_guildId/members/user-1',
    ]);
  });

  test('a member the reply leaves out left while the app was away: the row '
      'goes, without REST or a retry', () async {
    final _Setup s = _Setup();
    await s.cache(<String>['stayed', 'left']);
    s
      ..cacheReady()
      ..answerWith(<String>{'stayed'});

    await s.hydrate(<String>['stayed', 'left']);
    await s.hydrate(<String>['stayed', 'left']);

    expect(s.gateway.requests, hasLength(1));
    expect(s.rest.requestCount, 0);
    expect(await s.nick('stayed'), 'new');
    expect(
      await s.database.memberDao.getMemberByUserId('left', _guildId),
      isNull,
    );
    expect(s.service.isNonMember(_guildId, 'left'), isTrue);
  });

  test('non-members are forgotten on the next READY', () async {
    final _Setup s = _Setup();
    await s.cache(<String>['left']);
    s
      ..cacheReady()
      ..answerWith(<String>{});
    await s.hydrate(<String>['left']);
    expect(s.service.isNonMember(_guildId, 'left'), isTrue);

    s.cacheReady();

    expect(s.service.isNonMember(_guildId, 'left'), isFalse);
  });

  test('while the socket is down nothing is sent and the request is kept '
      'for later', () async {
    final _Setup s = _Setup();
    await s.cache(<String>['a']);
    s
      ..cacheReady()
      ..answerWith(<String>{'a'});
    s.gateway.current = GatewayState.disconnected;

    await s.hydrate(<String>['a']);
    expect(s.gateway.requests, isEmpty);
    expect(s.rest.requestCount, 0);

    s.gateway.current = GatewayState.connected;
    await s.hydrate(<String>['a']);
    expect(s.gateway.requests, hasLength(1));
    expect(await s.nick('a'), 'new');
  });

  test('two callers at once send one request', () async {
    final _Setup s = _Setup();
    await s.cache(<String>['a', 'b']);
    s
      ..cacheReady()
      ..answerWith(<String>{'a', 'b'});

    await Future.wait(<Future<void>>[
      s.hydrate(<String>['a', 'b']),
      s.service.hydrateMembers(guildId: _guildId, userIds: <String>['b', 'a']),
    ]);

    expect(s.gateway.requests, hasLength(1));
    expect(s.rest.requestCount, 0);
  });

  test('one gateway request at a time across guilds, none lost to the '
      "gateway's one waiting slot", () async {
    final _Setup s = _Setup();
    final List<String> guilds = <String>['g1', 'g2', 'g3', 'g4'];
    for (final String guildId in guilds) {
      await s.database.memberDao.upsertMember(
        MembersCompanion.insert(
          userId: 'u-$guildId',
          guildId: guildId,
          nick: const Value('old'),
        ),
      );
    }
    s.confirmation.startConnection(cacheKept: true, guildIds: guilds);
    final List<ForkRecordedRequest> open = <ForkRecordedRequest>[];
    int mostOpen = 0;
    s.gateway.onRequest = (ForkRecordedRequest request) async {
      open.add(request);
      if (open.length > mostOpen) {
        mostOpen = open.length;
      }
    };
    Future<void> answerFirst() async {
      await pumpEventQueue();
      final ForkRecordedRequest request = open.removeAt(0);
      s.waiter.notifyChunk(
        nonce: request.nonce,
        chunkCount: 1,
        userIds: request.userIds,
      );
    }

    final Future<void> all = Future.wait(<Future<void>>[
      for (final String guildId in guilds)
        s.service.hydrateMembers(
          guildId: guildId,
          userIds: <String>['u-$guildId'],
        ),
    ]);
    for (int i = 0; i < guilds.length; i++) {
      await answerFirst();
    }
    await all;

    expect(s.gateway.requests, hasLength(4));
    expect(mostOpen, 1);
    expect(s.rest.requestCount, 0);
  });
}
