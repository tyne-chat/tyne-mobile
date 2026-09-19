// Fork: tests the fork adds, kept out of upstream's accessibility_theme_sync_store_test.dart so that file stays
// as upstream has it (tyne-chat/tyne#834).
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/synced_preferences/engine/synced_preferences_store.dart';
import 'package:fluxer_app/core/synced_preferences/generated/fluxer/user/preferences/v1/accessibility.pb.dart'
    as accessibility_pb;
import 'package:fluxer_app/core/synced_preferences/generated/fluxer/user/preferences/v1/preferences.pb.dart'
    as pb;
import 'package:fluxer_app/core/theme/providers/theme_preference_provider.dart';
import 'package:fluxer_app/features/settings/providers/preferences/appearance_preferences_provider.dart';

import '../../helpers/open_test_database.dart';
import 'accessibility_theme_sync_store_test.dart' hide main;

void main() {
  group('SyncedPreferencesStore mobile font size', () {
    late db.FluxerDatabase database;
    late ForkFakeUsersApi usersApi;
    late ProviderContainer container;

    // Copied from upstream's setUp in accessibility_theme_sync_store_test.dart, which a fork test cannot name.
    setUp(() {
      database = openTestDatabase();
      usersApi = ForkFakeUsersApi();
      container = forkUpstream.createContainer(
        database: database,
        usersApi: usersApi,
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'hydrate with desktop fontSize does not overwrite mobile chatFontSize',
      () async {
        final store = container.read(syncedPreferencesStoreProvider);
        await container.read(themePreferenceProvider.notifier).load('u1');
        expect(container.read(themePreferenceProvider).chatFontSize, 16);

        await store.hydrateFromUserSettings(
          forkUpstream.testUserSettings(
            syncedPreferences: forkUpstream.settingsWithAccessibility(
              accessibility_pb.AccessibilitySettings(
                fontSize: 14,
                saturationFactor: 1,
              ),
            ),
          ),
        );

        // Desktop fontSize 14 must not overwrite mobile chatFontSize (remains default 16).
        expect(container.read(themePreferenceProvider).chatFontSize, 16);
      },
    );

    test('hydrate with mobileFontSize updates mobile chatFontSize', () async {
      final store = container.read(syncedPreferencesStoreProvider);
      await container.read(themePreferenceProvider.notifier).load('u1');
      await forkUpstream.waitForDebounce(store);
      expect(container.read(themePreferenceProvider).chatFontSize, 16);

      await store.hydrateFromUserSettings(
        forkUpstream.testUserSettings(
          syncedPreferences: forkUpstream.settingsWithAccessibility(
            accessibility_pb.AccessibilitySettings(
              mobileFontSize: 20,
              fontSize: 14,
              saturationFactor: 1,
            ),
          ),
        ),
      );

      // Mobile chatFontSize must adopt mobileFontSize (20), not desktop fontSize (14).
      expect(container.read(themePreferenceProvider).chatFontSize, 20);
    });

    test(
      'changing chatFontSize pushes mobileFontSize and preserves desktop fontSize',
      () async {
        final store = container.read(syncedPreferencesStoreProvider);
        await container.read(themePreferenceProvider.notifier).load('u1');
        await container.read(appearancePreferencesProvider.notifier).load('u1');
        await store.hydrateFromUserSettings(
          forkUpstream.testUserSettings(
            syncedPreferences: forkUpstream.settingsWithAccessibility(
              accessibility_pb.AccessibilitySettings(
                fontSize: 14,
                saturationFactor: 1,
              ),
            ),
          ),
        );

        await container
            .read(themePreferenceProvider.notifier)
            .setChatFontSize(20);
        await forkUpstream.waitForDebounce(store);

        expect(usersApi.pushCount, 1);
        final bytes = base64Decode(
          usersApi.lastPushBody!.syncedPreferences.value!,
        );
        final synced = pb.SyncedPreferences.fromBuffer(bytes);
        expect(synced.accessibility.mobileFontSize, 20);
        expect(synced.accessibility.fontSize, 14);
      },
    );
  });
}
