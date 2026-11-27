// Fork: tyne-chat/tyne#946 — regression tests for `@Riverpod(keepAlive: true)`
// providers whose mutable instance fields were not reset in `build()`:
// PushRelayConsent, QuickSwitcher, AppLockController, TypingIndicators, and
// VoiceTransmitHold.
import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/app_lock/app_lock_biometric_authenticator.dart';
import 'package:fluxer_app/core/app_lock/app_lock_controller.dart';
import 'package:fluxer_app/core/app_lock/app_lock_pin_hasher.dart';
import 'package:fluxer_app/core/app_lock/app_lock_store.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/gateway/providers/gateway_event_providers.dart';
import 'package:fluxer_app/core/providers/app/account_user_id.dart';
import 'package:fluxer_app/core/providers/app/app_ui_lifecycle_provider.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/push/relay_consent/push_relay_consent_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/dm/domain/dm_conversation.dart';
import 'package:fluxer_app/features/dm/providers/dm_view_model.dart';
import 'package:fluxer_app/features/friends/domain/friend.dart';
import 'package:fluxer_app/features/guilds/domain/guild.dart';
import 'package:fluxer_app/features/guilds/providers/guild_list_view_model.dart';
import 'package:fluxer_app/features/input/providers/keybind_preferences_provider.dart';
import 'package:fluxer_app/features/quick_switcher/data/quick_switcher_repository.dart';
import 'package:fluxer_app/features/quick_switcher/domain/quick_switcher_types.dart';
import 'package:fluxer_app/features/quick_switcher/domain/quick_switcher_unread_channel.dart';
import 'package:fluxer_app/features/quick_switcher/domain/recent_channel_visit.dart';
import 'package:fluxer_app/features/quick_switcher/providers/quick_switcher_provider.dart';
import 'package:fluxer_app/features/quick_switcher/providers/quick_switcher_providers.dart';
import 'package:fluxer_app/features/quick_switcher/providers/recent_channel_visits_provider.dart';
import 'package:fluxer_app/features/voice/providers/voice_transmit_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/open_test_database.dart';
import '../../helpers/test_account_user_id.dart';
import '../../helpers/test_l10n.dart';

class _SwappableQuickSwitcherRepository extends Fake
    implements QuickSwitcherRepository {
  List<Channel> guildChannels = <Channel>[
    const Channel(id: 'secret-c1', guildId: 'g-a', name: 'secret-alpha'),
  ];

  @override
  Future<List<Channel>> getGuildChannels() async => guildChannels;

  @override
  Future<List<QuickSwitcherUnreadChannel>> getUnreadChannels({
    required String? currentUserId,
    required List<DmConversation> conversations,
    bool unreadBadgeCustomizationEnabled = false,
  }) async => const <QuickSwitcherUnreadChannel>[];
}

class _FixedRecentVisits extends RecentChannelVisits {
  @override
  List<RecentChannelVisit> build() => const <RecentChannelVisit>[
    RecentChannelVisit(channelId: 'secret-c1', guildId: 'g-a'),
  ];
}

class _FixedGuildListViewModel extends GuildListViewModel {
  @override
  GuildListViewState build() => const GuildListViewState(
    guilds: <Guild>[Guild(id: 'g-a', name: 'Alpha')],
  );
}

class _FakeAppLockSecretStore implements AppLockSecretStore {
  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async {}

  @override
  Future<void> delete(String key) async {}
}

class _FakeAppLockStore extends AppLockStore {
  _FakeAppLockStore() : super(_FakeAppLockSecretStore());

  Future<AppLockSnapshot> Function()? onRead;

  @override
  Future<AppLockSnapshot> read() => onRead!();
}

class _MarkedAppLockInstallMarker implements AppLockInstallMarker {
  @override
  Future<bool> isMarked() async => true;

  @override
  Future<void> mark() async {}
}

class _NoopBiometricAuth implements AppLockBiometricAuthenticator {
  @override
  Future<List<AppLockBiometricKind>> availableKinds() async =>
      const <AppLockBiometricKind>[];

  @override
  Future<AppLockBiometricResult> authenticate({required String reason}) async =>
      AppLockBiometricResult.failed;
}

class _FixedKeybindPreferences extends KeybindPreferences {
  @override
  KeybindPreferencesState build() =>
      const KeybindPreferencesState(pushToTalkReleaseDelayMs: 50);
}

class _FixedAppUiForeground extends AppUiForeground {
  @override
  bool build() => true;
}

class _FixedDmViewModel extends DmViewModel {
  @override
  DmViewState build() => const DmViewState(
    conversations: <DmConversation>[],
    friendsList: <Friend>[],
    activeTab: FriendsTab.online,
    searchQuery: '',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'PushRelayConsent rebuild resets _isLoaded so ensureLoaded() reloads persisted grant state',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(pushRelayConsentProvider.notifier).grant();
      expect(container.read(pushRelayConsentProvider), isTrue);

      container
        ..invalidate(pushRelayConsentProvider)
        ..read(pushRelayConsentProvider);
      expect(container.read(pushRelayConsentProvider), isFalse);

      await container.read(pushRelayConsentProvider.notifier).ensureLoaded();
      expect(container.read(pushRelayConsentProvider), isTrue);
    },
  );

  test(
    'QuickSwitcher rebuild clears _recentGuildChannelCache so old channels do not leak after invalidation',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final db.FluxerDatabase database = openTestDatabase();
      final _SwappableQuickSwitcherRepository repo =
          _SwappableQuickSwitcherRepository();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          currentUserIdProvider.overrideWithValue(kTestAccountUserId),
          fluxerDatabaseProvider.overrideWithValue(database),
          appUiForegroundProvider.overrideWith(_FixedAppUiForeground.new),
          dmViewModelProvider.overrideWith(_FixedDmViewModel.new),
          quickSwitcherRepositoryProvider.overrideWithValue(repo),
          recentChannelVisitsProvider.overrideWith(_FixedRecentVisits.new),
          guildListViewModelProvider.overrideWith(_FixedGuildListViewModel.new),
        ],
      );
      addTearDown(container.dispose);

      final ProviderSubscription<QuickSwitcherState> sub = container.listen(
        quickSwitcherProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);
      await Future<void>.delayed(Duration.zero);

      container.read(quickSwitcherProvider.notifier).open(testL10n);
      expect(
        container
            .read(quickSwitcherProvider)
            .results
            .whereType<QuickSwitcherTextChannelResult>()
            .map((QuickSwitcherTextChannelResult r) => r.title),
        contains('secret-alpha'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Simulate switching accounts/workspaces with empty channel repository
      // before rebuilding QuickSwitcher.
      repo.guildChannels = const <Channel>[];
      container
        ..invalidate(quickSwitcherProvider)
        ..read(quickSwitcherProvider);
      await Future<void>.delayed(Duration.zero);

      container.read(quickSwitcherProvider.notifier).open(testL10n);
      expect(container.read(quickSwitcherProvider).results, isEmpty);
    },
  );

  test(
    'AppLockController rebuild mid-load resets _loading and ignores stale pre-rebuild read; TypingIndicators and VoiceTransmitHold reset timers on rebuild',
    () async {
      final Completer<AppLockSnapshot> staleRead = Completer<AppLockSnapshot>();
      final _FakeAppLockStore store = _FakeAppLockStore()
        ..onRead = () => staleRead.future;

      final db.FluxerDatabase database = openTestDatabase();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          currentUserIdProvider.overrideWithValue(kTestAccountUserId),
          fluxerDatabaseProvider.overrideWithValue(database),
          appLockStoreProvider.overrideWithValue(store),
          appLockInstallMarkerProvider.overrideWithValue(
            _MarkedAppLockInstallMarker(),
          ),
          appLockBiometricAuthenticatorProvider.overrideWithValue(
            _NoopBiometricAuth(),
          ),
          keybindPreferencesProvider.overrideWith(_FixedKeybindPreferences.new),
        ],
      );
      addTearDown(container.dispose);

      // 1. Start slow AppLockController.load() so `_loading` becomes `true`.
      final Future<void> staleLoad = container
          .read(appLockControllerProvider.notifier)
          .load();

      // Switch store to PIN-enabled snapshot and invalidate before stale load
      // finishes. `_loading` must reset to `false` so the rebuilt notifier loads!
      store.onRead = () async => const AppLockSnapshot(
        pinCredential: AppLockPinCredential(hash: 'h', salt: 's'),
      );
      container
        ..invalidate(appLockControllerProvider)
        ..read(appLockControllerProvider);

      await container.read(appLockControllerProvider.notifier).load();
      expect(container.read(appLockControllerProvider).loaded, isTrue);
      expect(container.read(appLockControllerProvider).isLocked, isTrue);

      // Even after the pre-rebuild load resolves with `hasPin: false`, it must
      // not overwrite the rebuilt notifier's locked state.
      staleRead.complete(const AppLockSnapshot());
      await staleLoad;
      expect(container.read(appLockControllerProvider).isLocked, isTrue);

      // 2. TypingIndicators & VoiceTransmitHold: invalidate while a timer is
      // active and confirm both cleanly cancel and allow fresh timers afterwards.
      final String uid = readAccountUserId(container);
      final DateTime baseTime = DateTime.utc(2026, 11, 26, 12);
      withClock(Clock.fixed(baseTime), () {
        container
            .read(typingIndicatorsProvider(uid).notifier)
            .addTyping('c1', 'u1');
        container
          ..invalidate(typingIndicatorsProvider(uid))
          ..read(typingIndicatorsProvider(uid));
        expect(container.read(typingIndicatorsProvider(uid)), isEmpty);
      });

      final ProviderSubscription<VoiceTransmitHoldState> holdSub = container
          .listen(voiceTransmitHoldProvider, (_, _) {}, fireImmediately: true);
      addTearDown(holdSub.close);
      container.read(voiceTransmitHoldProvider.notifier)
        ..pressPushToTalk()
        ..releasePushToTalk();
      container
        ..invalidate(voiceTransmitHoldProvider)
        ..read(voiceTransmitHoldProvider);
      expect(container.read(voiceTransmitHoldProvider).pushToTalkHeld, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(container.read(voiceTransmitHoldProvider).pushToTalkHeld, isFalse);
    },
  );
}
