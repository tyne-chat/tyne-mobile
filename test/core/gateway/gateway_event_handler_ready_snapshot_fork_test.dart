// Fork: READY keeps the user's own guild member when the user has a reply
// mention preference set (tyne-chat/tyne#193). The handler used to hand the
// guild parser `event.user.toJson()`, whose `mention_flags` is a Dart enum, so
// the parser dropped the own member from every guild and channel permissions
// stayed unknown: no reactions and no Pin in the long-press menu. Upstream
// fixed it in #1048 (a JSON round trip of the user); these tests guard that
// fix and the request count behind tyne-chat/tyne#114.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/gateway/gateway_event_handler.dart';
import 'package:fluxer_app/core/permissions/channel_effective_permissions.dart';
import 'package:fluxer_app/core/permissions/channel_permission_cache_provider.dart';
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/settings/providers/user_settings_view_model.dart';
import 'package:fluxer_dart/export.dart';
import 'package:fluxer_dart/gateway.dart';
import 'package:fluxer_dart/gateway_client/fork_parse_skips.dart';

import '../../helpers/open_test_database.dart';
import 'gateway_event_handler_ready_snapshot_test.dart' hide main;

const String _guildId = 'g1';
const String _channelId = 'c1';

/// upstream's test user ('100'), with [mentionFlags] as the server sends it.
UserPrivateResponse _user({int? mentionFlags}) =>
    UserPrivateResponse.fromJson(<String, dynamic>{
      ...jsonDecode(jsonEncode(forkUpstream.user())) as Map<String, dynamic>,
      'mention_flags': mentionFlags,
    });

/// What the server sends in READY's `users` for [user]: the partial user.
Map<String, dynamic> _readyUser(UserPrivateResponse user) => <String, dynamic>{
  'id': user.id,
  'username': user.username,
  'discriminator': user.discriminator,
  'flags': 0,
  if (user.mentionFlags case final MentionReplyPreferences flags)
    'mention_flags': flags.json,
};

/// Sends READY for [user] with one guild whose only member is the user, its
/// user reduced to the id as the server sends it, and `@everyone` allowed to
/// view channels and add reactions. Someone else owns the guild: an owner's
/// permissions never need the member. Returns the database READY wrote.
Future<FluxerDatabase> _sendReady(
  UserPrivateResponse user, {
  bool userInReadyUsers = true,
  List<String> channelIds = const <String>[_channelId],
}) async {
  final FluxerDatabase database = openTestDatabase();
  final GatewayEventHandler handler = GatewayEventHandler(database: database);
  final Map<String, dynamic> guild = forkUpstream.guild(
    channelIds: channelIds,
    roleIds: <String>[_guildId],
  );
  (guild['properties'] as Map<String, dynamic>)['owner_id'] = 'someone-else';
  (guild['roles'] as List<Map<String, Object?>>).first['permissions'] =
      (Permission.viewChannel.value | Permission.addReactions.value).toString();
  guild['members'] = <Map<String, Object?>>[
    <String, Object?>{
      'user': <String, Object?>{'id': user.id},
      'roles': <String>[],
      'joined_at': '2026-01-01T00:00:00.000Z',
      'mute': false,
      'deaf': false,
    },
  ];
  await handler.handle(
    ReadyEvent(
      sessionId: 'session-1',
      user: user,
      guilds: const [],
      rawGuilds: <Map<String, dynamic>>[guild],
      privateChannels: const [],
      relationships: const [],
      readStates: const [],
      presences: const [],
      users: userInReadyUsers
          ? <Map<String, dynamic>>[_readyUser(user)]
          : const <Map<String, dynamic>>[],
    ),
  );
  return database;
}

Future<bool> _ownMemberStoredAfterReady(
  UserPrivateResponse user, {
  bool userInReadyUsers = true,
}) async {
  final FluxerDatabase database = await _sendReady(
    user,
    userInReadyUsers: userInReadyUsers,
  );
  return await database.memberDao.getMemberByUserId(user.id, _guildId) != null;
}

class _RecordingAdapter implements HttpClientAdapter {
  final List<String> requestedPaths = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestedPaths.add(options.path);
    return ResponseBody.fromString('{}', 500);
  }

  @override
  void close({bool force = false}) {}
}

class _SignedInAs extends UserSettingsViewModel {
  _SignedInAs(this._userId);

  final String _userId;

  @override
  UserSettingsViewState build() => UserSettingsViewState(
    userId: _userId,
    username: 'tester',
    displayName: 'tester',
    discriminator: '0001',
    avatar: null,
    avatarColor: null,
    memberSince: null,
    status: 'online',
    messageDisplayCompact: false,
    developerMode: false,
    trustedDomains: const <String>[],
  );
}

/// The app signed in as [user] on [database], with an HTTP client that
/// records every request in [adapter] and fails it.
ProviderContainer _signedInContainer(
  FluxerDatabase database,
  UserPrivateResponse user,
  _RecordingAdapter adapter,
) {
  final ProviderContainer container = ProviderContainer(
    overrides: [
      fluxerDatabaseProvider.overrideWithValue(database),
      fluxerDioProvider.overrideWithValue(
        Dio(BaseOptions(baseUrl: 'https://example.invalid'))
          ..httpClientAdapter = adapter,
      ),
      userSettingsViewModelProvider.overrideWith(() => _SignedInAs(user.id)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('READY stores the own member', () {
    test('without a reply mention preference', () async {
      expect(await _ownMemberStoredAfterReady(_user()), isTrue);
    });

    test('when the user prefers to be mentioned in replies', () async {
      expect(await _ownMemberStoredAfterReady(_user(mentionFlags: 1)), isTrue);
    });

    test('when the user prefers not to be mentioned in replies', () async {
      expect(await _ownMemberStoredAfterReady(_user(mentionFlags: 2)), isTrue);
    });

    test('when READY lists no users and the preference is set', () async {
      expect(
        await _ownMemberStoredAfterReady(
          _user(mentionFlags: 1),
          userInReadyUsers: false,
        ),
        isTrue,
      );
    });
  });

  // tyne-chat/tyne#193: with the own member dropped, the long-press menu had
  // no reactions and no Pin for minutes after opening the app.
  test(
    'after READY the channel resolves with reactions allowed, without a request, when the preference is set (#193)',
    () async {
      final UserPrivateResponse user = _user(mentionFlags: 1);
      final FluxerDatabase database = await _sendReady(user);
      final _RecordingAdapter adapter = _RecordingAdapter();
      final ProviderContainer container = _signedInContainer(
        database,
        user,
        adapter,
      );

      final ChannelPermissionBitsOutcome outcome = await container.read(
        FutureProvider<ChannelPermissionBitsOutcome>(
          (Ref ref) => computeEffectiveGuildChannelPermissionBitsOutcome(
            ref: ref,
            channelId: _channelId,
          ),
        ).future,
      );

      expect(outcome.shouldCache, isTrue);
      expect(hasPermission(outcome.value, Permission.addReactions), isTrue);
      expect(adapter.requestedPaths, isEmpty);
    },
  );

  // tyne-chat/tyne#114: a user with the preference set was signed out again
  // and again. READY had dropped her own member, and the fork's old fallback
  // fetched it once per channel while the app computed each channel's
  // permissions: 65 requests in half a second, over the rate limit that ends
  // a session. With the member kept, every channel resolves from the local
  // database and nothing is requested.
  test(
    'after READY every channel resolves at once without a request, when the preference is set (#114)',
    () async {
      final List<String> channelIds = <String>[
        for (var i = 0; i < 20; i++) 'c$i',
      ];
      final UserPrivateResponse user = _user(mentionFlags: 1);
      final FluxerDatabase database = await _sendReady(
        user,
        channelIds: channelIds,
      );
      final _RecordingAdapter adapter = _RecordingAdapter();
      final ProviderContainer container = _signedInContainer(
        database,
        user,
        adapter,
      );
      final ChannelPermissionCache cache = container.read(
        channelPermissionCacheProvider.notifier,
      );

      await Future.wait(<Future<void>>[
        for (final String channelId in channelIds)
          cache.rebuildChannel(channelId),
      ]);

      expect(adapter.requestedPaths, isEmpty);
      final ChannelPermissionCaches caches = container.read(
        channelPermissionCacheProvider,
      );
      for (final String channelId in channelIds) {
        final int? bits = caches.effective[channelId];
        expect(bits, isNotNull, reason: channelId);
        expect(
          hasPermission(bits!, Permission.addReactions),
          isTrue,
          reason: channelId,
        );
      }
    },
  );

  test(
    'a guild member that does not parse in READY is reported on this isolate',
    () async {
      final List<String> skipped = <String>[];
      ForkGatewayParseSkips.onSkipped = (String what, Object error) =>
          skipped.add(what);
      addTearDown(() => ForkGatewayParseSkips.onSkipped = null);
      final FluxerDatabase database = openTestDatabase();
      final Map<String, dynamic> guild = forkUpstream.guild(
        channelIds: <String>[_channelId],
        roleIds: <String>[_guildId],
      );
      guild['members'] = <Map<String, Object?>>[
        <String, Object?>{
          'user': <String, Object?>{'id': '100'},
          'roles': <String>[],
          'joined_at': 'not a date',
        },
      ];

      await GatewayEventHandler(database: database).handle(
        ReadyEvent(
          sessionId: 'session-1',
          user: _user(),
          guilds: const [],
          rawGuilds: <Map<String, dynamic>>[guild],
          privateChannels: const [],
          relationships: const [],
          readStates: const [],
          presences: const [],
        ),
      );

      expect(skipped, <String>['GuildMemberResponse']);
    },
  );
}
