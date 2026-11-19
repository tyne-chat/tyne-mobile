// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/gateway/fork_member_confirmation.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/members/providers/guild_member_chunk_waiter.dart';
import 'package:fluxer_app/shared/providers/fork_profile_member.dart';
import 'package:fluxer_app/shared/services/guild_member_hydration_service.dart';
import 'package:fluxer_dart/export.dart';

import '../../helpers/open_test_database.dart';

UserProfileFullResponse _profile({GuildMemberResponse? member}) {
  const UserPartialResponse user = UserPartialResponse(
    id: 'user-1',
    username: 'silvia',
    discriminator: '6913',
    globalName: null,
    avatar: null,
    avatarColor: null,
    flags: 0,
  );
  return UserProfileFullResponse(
    user: user,
    userProfile: const UserProfileFullResponseUserProfile(
      bio: null,
      pronouns: null,
      accentColor: null,
      banner: null,
    ),
    guildMember: member,
    timezoneOffset: null,
  );
}

GuildMemberResponse _member(String nick) => GuildMemberResponse(
  user: const UserPartialResponse(
    id: 'user-1',
    username: 'silvia',
    discriminator: '6913',
    globalName: null,
    avatar: null,
    avatarColor: null,
    flags: 0,
  ),
  nick: nick,
  roles: const <String>[],
  joinedAt: DateTime.utc(2026),
  mute: false,
  deaf: false,
);

final Provider<Ref> _refProbe = Provider<Ref>((Ref ref) => ref);

class _Hydration extends GuildMemberHydrationService {
  _Hydration({required super.database})
    : super(
        client: FluxerClient(Dio()),
        chunkWaiter: GuildMemberChunkWaiter(),
        readGateway: () => null,
      );

  final List<(String, List<String>)> cleared = <(String, List<String>)>[];

  @override
  void clearNonMembers(String guildId, Iterable<String> userIds) {
    cleared.add((guildId, userIds.toList()));
    super.clearNonMembers(guildId, userIds);
  }
}

void main() {
  late FluxerDatabase database;
  late _Hydration hydration;
  late Ref ref;

  setUp(() {
    database = openTestDatabase();
    hydration = _Hydration(database: database);
    final ProviderContainer container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue('me'),
        guildMemberHydrationServiceProvider.overrideWithValue(hydration),
      ],
    );
    addTearDown(container.dispose);
    ref = container.read(_refProbe);
  });

  Future<void> cacheRow(String userId, String nick) =>
      database.memberDao.upsertMember(
        MembersCompanion.insert(
          userId: userId,
          guildId: 'guild-1',
          nick: Value(nick),
        ),
      );

  test('a community profile stores and confirms the member it brings, and '
      'forgets a non-member mark (tyne-chat/tyne#614)', () async {
    ForkMemberConfirmation.of(
      database,
    ).startConnection(cacheKept: true, guildIds: <String>['guild-1']);

    await forkCacheProfileMember(
      ref,
      database,
      'guild-1',
      _profile(member: _member('(≖ω≖)')),
    );

    expect(
      (await database.memberDao.getMemberByUserId('user-1', 'guild-1'))?.nick,
      '(≖ω≖)',
    );
    expect(
      ForkMemberConfirmation.of(database).isUnconfirmed('guild-1', 'user-1'),
      isFalse,
    );
    expect(hydration.cleared, hasLength(1));
    expect(hydration.cleared.single.$1, 'guild-1');
    expect(hydration.cleared.single.$2, <String>['user-1']);
  });

  test('without a member, the row of someone who left goes, when the viewer '
      'is in the guild', () async {
    await cacheRow('me', 'Me');
    await cacheRow('user-1', 'Old nick');

    await forkCacheProfileMember(ref, database, 'guild-1', _profile());

    expect(
      await database.memberDao.getMemberByUserId('user-1', 'guild-1'),
      isNull,
    );
  });

  test('without a member, nothing goes when the viewer is not in the guild, '
      'and nothing is stored without a community', () async {
    await cacheRow('user-1', 'Old nick');

    await forkCacheProfileMember(ref, database, 'guild-1', _profile());
    await forkCacheProfileMember(
      ref,
      database,
      null,
      _profile(member: _member('x')),
    );

    expect(
      (await database.memberDao.getMemberByUserId('user-1', 'guild-1'))?.nick,
      'Old nick',
    );
  });
}
