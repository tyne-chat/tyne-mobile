import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/providers/app/app_startup_provider.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/synced_preferences/engine/synced_preferences_store.dart';
import 'package:fluxer_app/features/auth/providers/account_manager_provider.dart';
import 'package:fluxer_app/features/auth/providers/auth_providers.dart';
import 'package:fluxer_app/features/chat/data/channel_persona_mention_cache.dart';

import '../../../helpers/open_test_database.dart';
import 'account_manager_provider_test.dart' hide main;

/// Upstream's fake, plus the sign-out call it leaves unimplemented.
class _SignOutAuthRepository extends ForkFakeAuthRepository {
  _SignOutAuthRepository({super.targetBaseUrl});

  final List<String> loggedOut = <String>[];

  @override
  Future<void> logout(String userId) async => loggedOut.add(userId);
}

class _InstantAppStartup extends AppStartup {
  @override
  Future<void> build() async {}
}

/// The mention cache as the previous account left it: one of its private
/// personas, with its use count.
void _seedPreviousAccountsPersonas() {
  ChannelPersonaMentionCache.instance.setChannelPersonas('channel-1', [
    <String, dynamic>{
      'id': 'persona-private',
      'name': 'Private persona',
      'visibility': 'private',
      'use_count': 12,
    },
  ], guildId: 'guild-1');
  expect(ChannelPersonaMentionCache.instance.cachedItems, isNotEmpty);
}

void main() {
  setUp(ChannelPersonaMentionCache.instance.clear);
  tearDown(ChannelPersonaMentionCache.instance.clear);

  test('switching accounts empties the persona mention cache', () async {
    final ForkFakeApiServer server = await ForkFakeApiServer.start();
    addTearDown(server.close);
    final db = openTestDatabase();
    final container = ProviderContainer(
      overrides: [
        fluxerDatabaseProvider.overrideWithValue(db),
        fluxerBaseUrlProvider.overrideWithValue(server.baseUrl),
        authRepositoryProvider.overrideWithValue(
          ForkFakeAuthRepository(targetBaseUrl: server.baseUrl),
        ),
        syncedPreferencesStoreProvider.overrideWith(SyncedPreferencesStore.new),
        appStartupProvider.overrideWith(_InstantAppStartup.new),
      ],
    );
    addTearDown(container.dispose);
    await forkUpstream.signIn(container, db);
    await db.authSessionDao.saveSessionMetadata(userId: 'user-2');
    _seedPreviousAccountsPersonas();

    await container
        .read(accountManagerProvider.notifier)
        .switchToAccount('user-2');

    expect(server.requests, ['GET /users/@me']);
    expect(container.read(accountManagerProvider).isSwitching, isFalse);
    expect(ChannelPersonaMentionCache.instance.cachedItems, isEmpty);
  });

  test('an expired session empties the persona mention cache', () async {
    final ForkFakeApiServer server = await ForkFakeApiServer.start();
    addTearDown(server.close);
    server.statusCode = HttpStatus.unauthorized;
    final (:container, :db) = forkUpstream.harness(baseUrl: server.baseUrl);
    await forkUpstream.signIn(container, db);
    _seedPreviousAccountsPersonas();

    final bool expired = await container
        .read(accountManagerProvider.notifier)
        .expireSessionIfInvalid();

    expect(expired, isTrue);
    expect(ChannelPersonaMentionCache.instance.cachedItems, isEmpty);
  });

  test('signing out empties the persona mention cache', () async {
    final ForkFakeApiServer server = await ForkFakeApiServer.start();
    addTearDown(server.close);
    final db = openTestDatabase();
    final repository = _SignOutAuthRepository(targetBaseUrl: server.baseUrl);
    final container = ProviderContainer(
      overrides: [
        fluxerDatabaseProvider.overrideWithValue(db),
        fluxerBaseUrlProvider.overrideWithValue(server.baseUrl),
        authRepositoryProvider.overrideWithValue(repository),
        syncedPreferencesStoreProvider.overrideWith(SyncedPreferencesStore.new),
      ],
    );
    addTearDown(container.dispose);
    await forkUpstream.signIn(container, db);
    _seedPreviousAccountsPersonas();

    await container.read(accountManagerProvider.notifier).signOut('user-1');

    expect(repository.loggedOut, ['user-1']);
    expect(container.read(authStateProvider), isFalse);
    expect(ChannelPersonaMentionCache.instance.cachedItems, isEmpty);
  });
}
