// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/gateway/fork_member_confirmation.dart';
import 'package:fluxer_app/shared/providers/fork_profile_member.dart';
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

void main() {
  test('a community profile stores and confirms the member it brings '
      '(tyne-chat/tyne#614)', () async {
    final FluxerDatabase database = openTestDatabase();
    ForkMemberConfirmation.of(
      database,
    ).startConnection(cacheKept: true, guildIds: <String>['guild-1']);

    await forkCacheProfileMember(
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
  });

  test('nothing is stored without a community or a member', () async {
    final FluxerDatabase database = openTestDatabase();

    await forkCacheProfileMember(
      database,
      null,
      _profile(member: _member('x')),
    );
    await forkCacheProfileMember(database, 'guild-1', _profile());

    expect(
      await database.memberDao.getMemberByUserId('user-1', 'guild-1'),
      isNull,
    );
  });
}
