import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/providers/app/account_user_id.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/providers/gateway/gateway_connection_provider.dart';
import 'package:fluxer_app/core/providers/gateway/gateway_ready_provider.dart';
import 'package:fluxer_app/core/quick_actions/home_quick_action.dart';
import 'package:fluxer_app/core/quick_actions/pending_home_quick_action_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_mode.dart';
import 'package:fluxer_app/core/theme/providers/theme_preference_provider.dart';
import 'package:fluxer_app/features/guilds/providers/guild_drag_provider.dart';
import 'package:fluxer_app/features/guilds/providers/guild_sync_provider.dart';
import 'package:fluxer_app/features/members/data/member_repository.dart';
import 'package:fluxer_app/features/members/providers/member_providers.dart';
import 'package:fluxer_app/features/settings/providers/sync/user_settings_sync_service.dart';
import 'package:fluxer_app/features/settings/providers/view_models/connections_view_model.dart';
import 'package:fluxer_app/features/settings/providers/view_models/webauthn_credentials_view_model.dart';
import 'package:fluxer_app/features/shell/providers/user/current_user_private_provider.dart';
import 'package:fluxer_dart/export.dart';
import 'package:fluxer_dart/gateway.dart';

import '../../helpers/instance_runtime_config_override.dart';
import '../../helpers/open_test_database.dart';

class _StubUserSettingsSyncService extends UserSettingsSyncService {
  _StubUserSettingsSyncService(super.ref);

  @override
  Future<UserSettingsResponse> fetchCurrentSettings() {
    return Future<UserSettingsResponse>.error(
      StateError('skip network hydration in unit test'),
    );
  }
}

UserSettingsResponse _settingsWithTheme(String theme) {
  return UserSettingsResponse.fromJson(<String, dynamic>{
    'status': 'online',
    'theme': theme,
    'locale': 'en-US',
    'synced_preferences': '',
    'render_embeds': true,
    'profile_privacy': 0,
    'privacy_setup_version': 0,
    'restricted_guilds': <String>[],
    'bot_restricted_guilds': <String>[],
    'default_guilds_restricted': false,
    'bot_default_guilds_restricted': false,
    'inline_attachment_media': true,
    'inline_embed_media': true,
    'gif_auto_play': true,
    'render_reactions': true,
    'animate_emoji': true,
    'animate_stickers': 0,
    'render_spoilers': 0,
    'message_display_compact': false,
    'friend_source_flags': 0,
    'incoming_call_flags': 0,
    'group_dm_add_permission_flags': 0,
    'guild_folders': <Map<String, Object?>>[],
    'afk_timeout': 600,
    'time_format': 0,
    'developer_mode': false,
    'trusted_domains': <String>[],
    'default_hide_muted_channels': false,
    'sensitive_content_friend_dm_filter': 0,
    'sensitive_content_non_friend_dm_filter': 0,
    'sensitive_content_guild_filter': 0,
    'suppress_unprivileged_self_mentions': false,
    'suppress_unprivileged_self_mentions_bypass_user_ids': <String>[],
    'staff_dm_access_user_ids': <String>[],
    'default_share_voice_activity': false,
  });
}

class _FakeConnectionsApi implements ConnectionsApi {
  final List<Completer<List<ConnectionResponse>>> _pending =
      <Completer<List<ConnectionResponse>>>[];

  Completer<List<ConnectionResponse>> nextCompleter() {
    final Completer<List<ConnectionResponse>> completer =
        Completer<List<ConnectionResponse>>();
    _pending.add(completer);
    return completer;
  }

  @override
  Future<List<ConnectionResponse>> listConnections() {
    if (_pending.isNotEmpty) {
      return _pending.removeAt(0).future;
    }
    return Future<List<ConnectionResponse>>.value(const <ConnectionResponse>[]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUsersApi implements UsersApi {
  final List<Completer<List<WebAuthnCredentialResponse>>> _credentialLoads =
      <Completer<List<WebAuthnCredentialResponse>>>[];
  Completer<UserPrivateResponse>? currentUserCompleter;

  Completer<List<WebAuthnCredentialResponse>> nextCredentialsCompleter() {
    final Completer<List<WebAuthnCredentialResponse>> completer =
        Completer<List<WebAuthnCredentialResponse>>();
    _credentialLoads.add(completer);
    return completer;
  }

  @override
  Future<List<WebAuthnCredentialResponse>> listWebauthnCredentials() {
    if (_credentialLoads.isNotEmpty) {
      return _credentialLoads.removeAt(0).future;
    }
    return Future<List<WebAuthnCredentialResponse>>.value(
      const <WebAuthnCredentialResponse>[],
    );
  }

  @override
  Future<UserPrivateResponse> getCurrentUser() {
    return currentUserCompleter?.future ??
        Future<UserPrivateResponse>.value(_privateUser('default'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeClient extends FluxerClient {
  _FakeClient(this._connectionsApi, this._usersApi) : super(Dio());

  final ConnectionsApi _connectionsApi;
  final UsersApi _usersApi;

  @override
  ConnectionsApi get connections => _connectionsApi;

  @override
  UsersApi get users => _usersApi;
}

class _FakeGatewayConnection extends Fake implements GatewayConnection {
  GatewayState current = GatewayState.connected;
  final List<String> syncedGuildIds = <String>[];

  @override
  GatewayState get state => current;

  @override
  void sendLazyRequest({
    required Map<String, LazyRequestSubscription> subscriptions,
  }) {
    syncedGuildIds.addAll(subscriptions.keys);
  }
}

class _FakeMemberRepository extends Fake implements MemberRepository {}

ConnectionResponse _connection(String id) => ConnectionResponse(
  id: id,
  type: ConnectionType.bluesky,
  name: 'user-$id',
  verified: true,
  visibilityFlags: 0,
  sortOrder: 0,
  providerId: null,
  url: null,
);

WebAuthnCredentialResponse _credential(String id) => WebAuthnCredentialResponse(
  id: id,
  name: 'Key $id',
  createdAt: '2026-01-01T00:00:00Z',
  lastUsedAt: null,
  rpId: 'fluxer.com',
);

UserPrivateResponse _privateUser(String id) => UserPrivateResponse(
  hasVerifiedPhone: false,
  username: 'user-$id',
  discriminator: '0001',
  globalName: null,
  avatar: null,
  avatarColor: null,
  privacyAgreedAt: null,
  termsAgreedAt: null,
  pendingBulkMessageDeletion: null,
  flags: 0,
  unreadGiftInventoryCount: 0,
  isStaff: false,
  acls: const <String>[],
  traits: const <String>[],
  email: null,
  hasUnreadGiftInventory: false,
  hasEverPurchased: false,
  id: id,
  bio: null,
  pronouns: null,
  accentColor: null,
  banner: null,
  hasDismissedPremiumOnboarding: false,
  bannerColor: null,
  mfaEnabled: false,
  nsfwAllowed: true,
  verified: true,
  premiumType: null,
  premiumSince: null,
  premiumUntil: null,
  premiumWillCancel: false,
  premiumBillingCycle: null,
  premiumLifetimeSequence: null,
  premiumGraceEndsAt: null,
  premiumDiscriminator: false,
  requiredActions: const <String>[],
  premiumBadgeMasked: false,
  premiumBadgeTimestampHidden: false,
  premiumBadgeSequenceHidden: false,
  premiumPurchaseDisabled: false,
  premiumEnabledOverride: false,
  passwordLastChangedAt: null,
  lastVoiceActivitySharingChangeAt: null,
  premiumBadgeHidden: false,
  premiumPerksDisabled: false,
  hiddenProfileBadges: const <String>[],
);

Future<void> _pumpMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('keepAlive reset Batch 6 regressions', () {
    test('PendingHomeQuickAction clears queued action when invalidated', () {
      final ProviderContainer container = ProviderContainer(
        overrides: [instanceRuntimeConfigOverride()],
      );
      addTearDown(container.dispose);

      final ProviderSubscription<HomeQuickAction?> sub = container.listen(
        pendingHomeQuickActionProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      container.read(authStateProvider.notifier).setAuthenticated(value: false);
      container
          .read(pendingHomeQuickActionProvider.notifier)
          .store(HomeQuickAction.search);
      expect(container.read(pendingHomeQuickActionProvider), isNull);

      container
        ..invalidate(pendingHomeQuickActionProvider)
        ..read(pendingHomeQuickActionProvider);

      container.read(authStateProvider.notifier).setAuthenticated(value: true);
      container.read(gatewayReadyProvider.notifier).setReady();

      expect(container.read(pendingHomeQuickActionProvider), isNull);
    });

    test(
      'ThemePreference resets stale userId on invalidate so pre-load server settings are dropped',
      () async {
        final db.FluxerDatabase database = openTestDatabase();
        final ProviderContainer container = ProviderContainer(
          overrides: [
            instanceRuntimeConfigOverride(),
            fluxerDatabaseProvider.overrideWithValue(database),
            userSettingsSyncProvider.overrideWith(
              _StubUserSettingsSyncService.new,
            ),
          ],
        );
        addTearDown(container.dispose);

        container.read(currentUserIdProvider.notifier).set('u1');
        await container.read(themePreferenceProvider.notifier).load('u1');
        await container
            .read(themePreferenceProvider.notifier)
            .applyServerSettings(_settingsWithTheme('light'));
        expect(
          container.read(themePreferenceProvider).mode,
          FluxerThemeMode.light,
        );

        container
          ..invalidate(currentUserIdProvider)
          ..invalidate(themePreferenceProvider);
        expect(
          container.read(themePreferenceProvider).mode,
          FluxerThemeMode.system,
        );

        await container
            .read(themePreferenceProvider.notifier)
            .applyServerSettings(_settingsWithTheme('coal'));
        expect(
          container.read(themePreferenceProvider).mode,
          FluxerThemeMode.system,
        );
      },
    );

    test(
      'ConnectionsViewModel advances _updateSeq on invalidate so pre-invalidation load is ignored',
      () async {
        final _FakeConnectionsApi connectionsApi = _FakeConnectionsApi();
        final Completer<List<ConnectionResponse>> firstLoad = connectionsApi
            .nextCompleter();
        final Completer<List<ConnectionResponse>> secondLoad = connectionsApi
            .nextCompleter();
        final ProviderContainer container = ProviderContainer(
          overrides: [
            instanceRuntimeConfigOverride(),
            fluxerClientProvider.overrideWithValue(
              _FakeClient(connectionsApi, _FakeUsersApi()),
            ),
          ],
        );
        addTearDown(container.dispose);

        final ProviderSubscription<ConnectionsViewState> sub = container.listen(
          connectionsViewModelProvider('u1'),
          (_, _) {},
        );
        addTearDown(sub.close);
        await _pumpMicrotasks();

        container
          ..invalidate(connectionsViewModelProvider('u1'))
          ..read(connectionsViewModelProvider('u1'));
        await _pumpMicrotasks();

        secondLoad.complete(<ConnectionResponse>[_connection('fresh')]);
        await _pumpMicrotasks();
        expect(
          container
              .read(connectionsViewModelProvider('u1'))
              .connections
              .map((ConnectionResponse c) => c.id),
          <String>['fresh'],
        );

        firstLoad.complete(<ConnectionResponse>[_connection('stale')]);
        await _pumpMicrotasks();
        expect(
          container
              .read(connectionsViewModelProvider('u1'))
              .connections
              .map((ConnectionResponse c) => c.id),
          <String>['fresh'],
        );
      },
    );

    test(
      'WebauthnCredentialsViewModel advances _updateSeq on invalidate so pre-invalidation load is ignored',
      () async {
        final _FakeUsersApi usersApi = _FakeUsersApi();
        final Completer<List<WebAuthnCredentialResponse>> firstLoad = usersApi
            .nextCredentialsCompleter();
        final Completer<List<WebAuthnCredentialResponse>> secondLoad = usersApi
            .nextCredentialsCompleter();
        final ProviderContainer container = ProviderContainer(
          overrides: [
            fluxerClientProvider.overrideWithValue(
              _FakeClient(_FakeConnectionsApi(), usersApi),
            ),
          ],
        );
        addTearDown(container.dispose);

        final ProviderSubscription<WebauthnCredentialsViewState> sub = container
            .listen(webauthnCredentialsViewModelProvider('u1'), (_, _) {});
        addTearDown(sub.close);
        await _pumpMicrotasks();

        container
          ..invalidate(webauthnCredentialsViewModelProvider('u1'))
          ..read(webauthnCredentialsViewModelProvider('u1'));
        await _pumpMicrotasks();

        secondLoad.complete(<WebAuthnCredentialResponse>[_credential('fresh')]);
        await _pumpMicrotasks();
        expect(
          container
              .read(webauthnCredentialsViewModelProvider('u1'))
              .credentials
              .map((WebAuthnCredentialResponse c) => c.id),
          <String>['fresh'],
        );

        firstLoad.complete(<WebAuthnCredentialResponse>[_credential('stale')]);
        await _pumpMicrotasks();
        expect(
          container
              .read(webauthnCredentialsViewModelProvider('u1'))
              .credentials
              .map((WebAuthnCredentialResponse c) => c.id),
          <String>['fresh'],
        );
      },
    );

    test(
      'CurrentUserPrivateRead advances _epoch on invalidate so in-flight refresh cannot overwrite reset state',
      () async {
        final _FakeUsersApi usersApi = _FakeUsersApi();
        final Completer<UserPrivateResponse> refreshCompleter =
            Completer<UserPrivateResponse>();
        usersApi.currentUserCompleter = refreshCompleter;
        final ProviderContainer container = ProviderContainer(
          overrides: [
            fluxerClientProvider.overrideWithValue(
              _FakeClient(_FakeConnectionsApi(), usersApi),
            ),
          ],
        );
        addTearDown(container.dispose);
        container.read(currentUserIdProvider.notifier).set('u1');

        final Future<void> pendingRefresh = container
            .read(currentUserPrivateReadProvider('u1').notifier)
            .refresh();
        await _pumpMicrotasks();

        container.invalidate(currentUserPrivateReadProvider('u1'));
        expect(container.read(currentUserPrivateReadProvider('u1')), isNull);

        refreshCompleter.complete(_privateUser('stale'));
        await pendingRefresh;

        expect(container.read(currentUserPrivateReadProvider('u1')), isNull);
      },
    );

    test(
      'GuildSync clears pending guild and own-member sync cache on invalidate',
      () {
        final _FakeGatewayConnection connection = _FakeGatewayConnection();
        final ProviderContainer container = ProviderContainer(
          overrides: [
            gatewayConnectionProvider.overrideWithValue(connection),
            memberRepositoryProvider.overrideWithValue(_FakeMemberRepository()),
          ],
        );
        addTearDown(container.dispose);
        final String accountUserId = readAccountUserId(container);

        final GuildSync notifier = container.read(
          guildSyncProvider(accountUserId).notifier,
        )..requestOwnMemberSync('g1');
        expect(connection.syncedGuildIds, <String>['g1']);

        connection.current = GatewayState.connecting;
        notifier.syncIfNeeded('g2');
        connection.syncedGuildIds.clear();

        container.invalidate(guildSyncProvider(accountUserId));
        connection.current = GatewayState.connected;

        container.read(guildSyncProvider(accountUserId).notifier)
          ..flushPending()
          ..requestOwnMemberSync('g1');

        expect(connection.syncedGuildIds, <String>['g1']);
      },
    );

    test('GuildDrag clears prior drag origin coordinates when invalidated', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(guildDragProvider.notifier)
        ..startDrag('g1', sourceIsFolder: false)
        ..updateDragMovement(const Offset(10, 100));

      container.invalidate(guildDragProvider);

      final bool moved = container
          .read(guildDragProvider.notifier)
          .updateDragMovement(const Offset(10, 120));

      expect(moved, isFalse);
      expect(container.read(guildDragProvider).hasMovedFromHoldPoint, isFalse);
    });
  });
}
