// Fork: tyne-chat/tyne#946 — regression tests for Group A (channels/sidebar)
// post-await WidgetRef/BuildContext disposal hazards across
// ChannelNotificationMenuContent, ChannelWebhooksWidget, showChannelDebugSheet,
// GuildSidebarCategoryHeader, and GuildSidebarChannelTile.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/daos/channel_dao.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/experiments/experiments_provider.dart';
import 'package:fluxer_app/core/permissions/channel_effective_permissions.dart';
import 'package:fluxer_app/core/permissions/channel_permission_cache_provider.dart';
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/router/route_kind.dart';
import 'package:fluxer_app/core/router/route_state_providers.dart';
import 'package:fluxer_app/core/synced_preferences/engine/synced_preference_field.dart';
import 'package:fluxer_app/core/synced_preferences/engine/synced_preferences_store.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/channels/presentation/channel_settings/tabs/channel_webhooks_widget.dart';
import 'package:fluxer_app/features/channels/presentation/widgets/channel_notification_menu_content.dart';
import 'package:fluxer_app/features/channels/presentation/widgets/guild_sidebar.dart';
import 'package:fluxer_app/features/channels/providers/channel_list_view_model.dart';
import 'package:fluxer_app/features/channels/providers/channel_mute_provider.dart';
import 'package:fluxer_app/features/channels/providers/channel_notification_menu_provider.dart';
import 'package:fluxer_app/features/channels/providers/channel_sidebar_icon_connect_bits_provider.dart';
import 'package:fluxer_app/features/channels/providers/channel_webhooks_provider.dart';
import 'package:fluxer_app/features/channels/providers/guild_collapsed_categories_provider.dart';
import 'package:fluxer_app/features/channels/providers/unread_provider.dart';
import 'package:fluxer_app/features/channels/utils/show_channel_debug_sheet.dart';
import 'package:fluxer_app/features/favorites/data/favorite_channels_repository.dart';
import 'package:fluxer_app/features/favorites/providers/favorite_channels_provider.dart';
import 'package:fluxer_app/features/guilds/data/guild_user_settings_repository.dart';
import 'package:fluxer_app/features/guilds/domain/guild.dart';
import 'package:fluxer_app/features/guilds/providers/guild_list_view_model.dart';
import 'package:fluxer_app/features/guilds/providers/guild_mute_provider.dart';
import 'package:fluxer_app/features/guilds/providers/guild_permissions_provider.dart';
import 'package:fluxer_app/features/guilds/providers/guild_read_state_provider.dart';
import 'package:fluxer_app/features/mature_content/domain/mature_content_types.dart';
import 'package:fluxer_app/features/mature_content/providers/mature_content_agreements_provider.dart';
import 'package:fluxer_app/features/mature_content/providers/sensitive_content_provider.dart';
import 'package:fluxer_app/features/settings/providers/preferences/appearance_preferences_provider.dart';
import 'package:fluxer_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:fluxer_app/features/ui/toast/toast_provider.dart';
import 'package:fluxer_app/features/voice/providers/voice_session_provider.dart';
import 'package:fluxer_app/features/voice/providers/voice_session_state.dart';
import 'package:fluxer_app/material_ui.dart' hide SensitiveContent;
import 'package:fluxer_dart/export.dart' hide ChannelType, Locale;

import '../../../helpers/open_test_database.dart';
import '../../../helpers/test_account_user_id.dart';
import '../../../helpers/test_l10n.dart';

const Channel _testChannel = Channel(
  id: 'ch-menu-1',
  guildId: 'g-menu-1',
  name: 'general',
);

Widget _shell({
  required ProviderContainer container,
  required Widget child,
  Locale locale = kTestLocale,
}) {
  final colorTheme = buildDarkColorTheme();
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      navigatorKey: rootNavigatorKey,
      locale: locale,
      localizationsDelegates: fluxerLocalizationsDelegates,
      supportedLocales: FluxerLocalizations.supportedLocales,
      theme: buildFluxerTheme(
        colorTheme: colorTheme,
        textTheme: FluxerTextTheme.fromColors(colorTheme),
        layoutTheme: FluxerLayoutTheme.scaled(),
      ),
      home: child,
    ),
  );
}

class _SuspendingGuildUserSettingsRepository
    extends GuildUserSettingsRepository {
  _SuspendingGuildUserSettingsRepository(super._ref, this.completer);

  final Completer<void> completer;
  final List<String> updatedChannelIds = <String>[];

  @override
  Future<void> updateChannelOverride({
    required String guildId,
    required String channelId,
    bool? muted,
    int? durationSeconds,
    UserNotificationSettings? messageNotifications,
    bool? collapsed,
    int? flags,
    GuildUserSettingsPersistenceOptions options =
        const GuildUserSettingsPersistenceOptions(),
  }) async {
    await completer.future;
    updatedChannelIds.add(channelId);
  }
}

class _SuspendingChannelWebhooks extends ChannelWebhooks {
  _SuspendingChannelWebhooks(this.createCompleter);

  final Completer<void> createCompleter;
  int createCalls = 0;

  @override
  Future<List<WebhookResponse>> build(String channelId) async =>
      const <WebhookResponse>[];

  @override
  Future<void> createWebhook({required String name}) async {
    createCalls += 1;
    await createCompleter.future;
  }
}

class _SuspendingChannelDao extends ChannelDao {
  _SuspendingChannelDao(super.attachedDatabase, this.lookupCompleter);

  final Completer<db.Channel?> lookupCompleter;

  @override
  Future<db.Channel?> getChannelById(String id) => lookupCompleter.future;
}

class _ControllableChannelDatabase extends db.FluxerDatabase {
  _ControllableChannelDatabase(this.lookupCompleter)
    : super.forTesting(NativeDatabase.memory()) {
    _dao = _SuspendingChannelDao(this, lookupCompleter);
  }

  final Completer<db.Channel?> lookupCompleter;
  late final _SuspendingChannelDao _dao;

  @override
  ChannelDao get channelDao => _dao;
}

class _ChannelJsonAdapter implements HttpClientAdapter {
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests += 1;
    return ResponseBody.fromString(
      jsonEncode(<String, Object?>{
        'id': 'missing-ch',
        'type': 0,
        'guild_id': 'g-menu-1',
        'name': 'fetched-debug',
      }),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _StaticChannelListViewModel extends ChannelListViewModel {
  _StaticChannelListViewModel(this._state);

  final ChannelListState _state;

  @override
  ChannelListState build() => _state;
}

class _StaticPermissionCache extends ChannelPermissionCache {
  @override
  ChannelPermissionCaches build(String accountUserId) =>
      const ChannelPermissionCaches();

  @override
  void requestChannelBits(String channelId) {}
}

class _StaticGuildPermissions extends GuildPermissions {
  @override
  Map<String, int> build(String accountUserId) => <String, int>{
    'g-menu-1': Permission.manageChannels.value,
  };

  @override
  Future<void> refreshPermissions(String guildId) async {}
}

class _StaticAppearancePreferences extends AppearancePreferences {
  @override
  AppearancePreferencesState build() => const AppearancePreferencesState();
}

class _StaticUserSettings extends UserSettingsViewModel {
  @override
  UserSettingsViewState build() => const UserSettingsViewState(
    userId: kTestAccountUserId,
    username: 'me',
    displayName: 'Me',
    discriminator: '0',
    avatar: null,
    avatarColor: null,
    memberSince: null,
    status: 'online',
    messageDisplayCompact: false,
    developerMode: false,
    trustedDomains: <String>[],
  );
}

class _StaticVoiceSession extends VoiceSession {
  @override
  VoiceSessionState build() => const VoiceSessionState();
}

class _StaticSensitiveContent extends SensitiveContent {
  @override
  SensitiveContentState build() => const SensitiveContentState(
    isLoading: false,
    access: MatureAccess.allowed,
    showLocked: false,
  );
}

class _StaticMatureAgreements extends MatureContentAgreements {
  @override
  MatureContentAgreementsState build() =>
      const MatureContentAgreementsState(isLoaded: true);
}

class _InertSyncedStore extends SyncedPreferencesStore {
  // Test stub passes ref explicitly.
  // ignore: use_super_parameters
  _InertSyncedStore(Ref ref) : super(ref);

  @override
  void markDirty(SyncedPreferenceField field) {}

  @override
  void scheduleFlush() {}
}

class _SuspendingFavoriteChannelsRepository extends FavoriteChannelsRepository {
  // Test stub uses explicit super args matching FavoriteChannelsRepository.
  // ignore: use_super_parameters
  _SuspendingFavoriteChannelsRepository(
    db.FluxerDatabase database,
    SyncedPreferencesStore store,
    this.isFavoriteCompleter,
  ) : super(database, store);

  final Completer<bool> isFavoriteCompleter;

  @override
  Future<bool> isFavorite(String channelId) => isFavoriteCompleter.future;
}

void main() {
  testWidgets(
    'ChannelNotificationMenuContent _openMuteSheet still shows toast after onClose unmounts menu',
    (WidgetTester tester) async {
      final Completer<void> updateCompleter = Completer<void>();
      late _SuspendingGuildUserSettingsRepository repo;
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          channelNotificationMenuStateProvider(_testChannel).overrideWith(
            (Ref ref) => Stream<ChannelNotificationMenuState>.value(
              const ChannelNotificationMenuState(
                isMuted: false,
                selected: UserNotificationSettings.onlyMentions,
                effectiveDefault: UserNotificationSettings.onlyMentions,
                hasCategory: true,
              ),
            ),
          ),
          guildUserSettingsRepositoryProvider.overrideWith((Ref ref) {
            return repo = _SuspendingGuildUserSettingsRepository(
              ref,
              updateCompleter,
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      final ValueNotifier<bool> showMenu = ValueNotifier<bool>(true);
      addTearDown(showMenu.dispose);

      await tester.pumpWidget(
        _shell(
          container: container,
          child: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: showMenu,
              builder: (_, bool visible, _) {
                if (!visible) {
                  return const SizedBox.shrink();
                }
                return ChannelNotificationMenuContent(
                  channel: _testChannel,
                  onClose: () => showMenu.value = false,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(testL10n.notificationMuteChannel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(testL10n.dmMuteFor15Min));
      await tester.pump();
      await tester.pump();

      expect(find.byType(ChannelNotificationMenuContent), findsNothing);

      updateCompleter.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(repo.updatedChannelIds, <String>[_testChannel.id]);
      expect(
        container.read(toastProvider).single.toast.message,
        testL10n.channelDetailsMutedChannel,
      );
    },
  );

  testWidgets(
    'ChannelWebhooksWidget and showChannelDebugSheet handle caller unmount during async work',
    (WidgetTester tester) async {
      final Completer<void> createCompleter = Completer<void>();
      final _SuspendingChannelWebhooks webhooksNotifier =
          _SuspendingChannelWebhooks(createCompleter);
      final Completer<db.Channel?> daoCompleter = Completer<db.Channel?>();
      final _ControllableChannelDatabase mockDb = _ControllableChannelDatabase(
        daoCompleter,
      );
      addTearDown(mockDb.close);
      final _ChannelJsonAdapter adapter = _ChannelJsonAdapter();
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://api.fluxer.invalid'))
        ..httpClientAdapter = adapter;

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          channelWebhooksProvider(
            _testChannel.id,
          ).overrideWith(() => webhooksNotifier),
          fluxerDatabaseProvider.overrideWithValue(mockDb),
          fluxerDioProvider.overrideWithValue(dio),
          fluxerClientProvider.overrideWithValue(
            FluxerClient(dio, baseUrl: 'https://api.fluxer.invalid'),
          ),
        ],
      );
      addTearDown(container.dispose);

      final ValueNotifier<bool> mountWebhooks = ValueNotifier<bool>(true);
      addTearDown(mountWebhooks.dispose);
      final ValueNotifier<bool> mountDebugCaller = ValueNotifier<bool>(true);
      addTearDown(mountDebugCaller.dispose);
      late BuildContext outerContext;

      await tester.pumpWidget(
        _shell(
          container: container,
          child: Builder(
            builder: (BuildContext ctx) {
              outerContext = ctx;
              return Scaffold(
                body: Column(
                  children: <Widget>[
                    Expanded(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: mountWebhooks,
                        builder: (_, bool mounted, _) {
                          if (!mounted) {
                            return const SizedBox.shrink();
                          }
                          return ChannelWebhooksWidget(
                            channel: _testChannel,
                            permissions: Permission.manageWebhooks.value,
                          );
                        },
                      ),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: mountDebugCaller,
                      builder: (_, bool mounted, _) {
                        if (!mounted) {
                          return const SizedBox.shrink();
                        }
                        return Consumer(
                          builder: (_, WidgetRef ref, _) => ElevatedButton(
                            onPressed: () => unawaited(
                              showChannelDebugSheet(
                                outerContext,
                                ref: ref,
                                channelId: 'missing-ch',
                                title: 'Debug',
                              ),
                            ),
                            child: const Text('DebugCh'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(testL10n.channelSettingsCreateWebhook).first);
      await tester.pump();
      expect(webhooksNotifier.createCalls, 1);

      mountWebhooks.value = false;
      await tester.pump();

      createCompleter.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(
        container.read(toastProvider).single.toast.message,
        testL10n.channelSettingsWebhookCreated,
      );

      await tester.tap(find.text('DebugCh'));
      await tester.pump();

      mountDebugCaller.value = false;
      await tester.pump();

      daoCompleter.complete(null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(adapter.requests, 1);
    },
  );

  testWidgets(
    'GuildSidebar category header and channel tile context actions abort cleanly on unmount',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final Completer<int> categoryPermCompleter = Completer<int>();
      final Completer<bool> isFavoriteCompleter = Completer<bool>();
      final db.FluxerDatabase mockDb = db.FluxerDatabase.forTesting(
        NativeDatabase.memory(),
      );
      addTearDown(mockDb.close);

      const ChannelCategory category = ChannelCategory(
        id: 'cat-1',
        name: 'My Category',
        channels: <Channel>[_testChannel],
      );
      const Guild guild = Guild(id: 'g-menu-1', name: 'Guild One');
      const ChannelListState channelState = ChannelListState(
        guild: guild,
        categories: <ChannelCategory>[category],
        selectedChannelId: null,
        hasReceivedInitialChannelList: true,
      );

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          fluxerDatabaseProvider.overrideWithValue(mockDb),
          currentUserIdProvider.overrideWithValue(kTestAccountUserId),
          experimentsProvider.overrideWithValue(null),
          routeStateProvider.overrideWithValue(
            const RouteState(
              location: '/channels/g-menu-1',
              activeBranchLocation: '/channels/g-menu-1',
              activeBranchIndex: 0,
              kind: RouteKind.chat,
              guildId: 'g-menu-1',
              channelId: null,
            ),
          ),
          guildListViewModelProvider.overrideWithValue(
            const GuildListViewState(guilds: <Guild>[guild]),
          ),
          activeGuildIdProvider.overrideWithValue('g-menu-1'),
          activeChannelIdProvider.overrideWithValue(null),
          channelListViewModelProvider.overrideWith(
            () => _StaticChannelListViewModel(channelState),
          ),
          channelPermissionCacheProvider(
            kTestAccountUserId,
          ).overrideWith(_StaticPermissionCache.new),
          guildPermissionsProvider(
            kTestAccountUserId,
          ).overrideWith(_StaticGuildPermissions.new),
          appearancePreferencesProvider.overrideWith(
            _StaticAppearancePreferences.new,
          ),
          userSettingsViewModelProvider.overrideWith(_StaticUserSettings.new),
          voiceSessionProvider.overrideWith(_StaticVoiceSession.new),
          sensitiveContentProvider.overrideWith(_StaticSensitiveContent.new),
          matureContentAgreementsProvider.overrideWith(
            _StaticMatureAgreements.new,
          ),
          guildMuteProvider('g-menu-1').overrideWithValue(
            const AsyncData<GuildMuteState>(GuildMuteState()),
          ),
          mutedChannelIdsProvider(
            'g-menu-1',
          ).overrideWithValue(const AsyncData<Set<String>>(<String>{})),
          guildCollapsedCategoriesProvider(
            'g-menu-1',
          ).overrideWithValue(const AsyncData<Set<String>>(<String>{})),
          guildReadStateProvider.overrideWithValue(
            const <String, GuildReadStateEntry>{},
          ),
          effectiveGuildChannelPermissionBitsProvider(
            'cat-1',
          ).overrideWith((Ref ref) => categoryPermCompleter.future),
          effectiveGuildChannelPermissionBitsProvider(
            _testChannel.id,
          ).overrideWith((Ref ref) => Permission.viewChannel.value),
          channelSidebarIconConnectBitsProvider(
            _testChannel.id,
          ).overrideWith((Ref ref) => null),
          channelUnreadProvider(_testChannel.id).overrideWith(
            (Ref ref) => Stream<UnreadState>.value(const UnreadState()),
          ),
          favoriteChannelsRepositoryProvider.overrideWith(
            (Ref ref) => _SuspendingFavoriteChannelsRepository(
              mockDb,
              _InertSyncedStore(ref),
              isFavoriteCompleter,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final ValueNotifier<bool> mountSidebar = ValueNotifier<bool>(true);
      addTearDown(mountSidebar.dispose);

      await tester.pumpWidget(
        _shell(
          container: container,
          child: ValueListenableBuilder<bool>(
            valueListenable: mountSidebar,
            builder: (_, bool mounted, _) {
              if (!mounted) {
                return const SizedBox.shrink();
              }
              return const Scaffold(body: GuildSidebar());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Category header context menu unmounts while waiting for permission bits.
      await tester.tap(find.text('My Category'), buttons: kSecondaryButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      mountSidebar.value = false;
      await tester.pump();

      categoryPermCompleter.complete(Permission.manageChannels.value);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);

      // 2. Channel tile context menu unmounts while waiting for isFavorite DB lookup.
      mountSidebar.value = true;
      await tester.pumpAndSettle();

      await tester.tap(find.text('general'), buttons: kSecondaryButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      mountSidebar.value = false;
      await tester.pump();

      isFavoriteCompleter.complete(false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'GuildSidebar category mute sheet uses localized categoryMuteCategory title',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      const Locale esLocale = Locale('es');
      final FluxerLocalizations esL10n = await FluxerLocalizations.delegate
          .load(esLocale);
      expect(esL10n.categoryMuteCategory, isNot('Mute Category'));

      final db.FluxerDatabase mockDb = openTestDatabase();
      const ChannelCategory category = ChannelCategory(
        id: 'cat-1',
        name: 'My Category',
        channels: <Channel>[_testChannel],
      );
      const Guild guild = Guild(id: 'g-menu-1', name: 'Guild One');
      const ChannelListState channelState = ChannelListState(
        guild: guild,
        categories: <ChannelCategory>[category],
        selectedChannelId: null,
        hasReceivedInitialChannelList: true,
      );

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          fluxerDatabaseProvider.overrideWithValue(mockDb),
          currentUserIdProvider.overrideWithValue(kTestAccountUserId),
          experimentsProvider.overrideWithValue(null),
          routeStateProvider.overrideWithValue(
            const RouteState(
              location: '/channels/g-menu-1',
              activeBranchLocation: '/channels/g-menu-1',
              activeBranchIndex: 0,
              kind: RouteKind.chat,
              guildId: 'g-menu-1',
              channelId: null,
            ),
          ),
          guildListViewModelProvider.overrideWithValue(
            const GuildListViewState(guilds: <Guild>[guild]),
          ),
          activeGuildIdProvider.overrideWithValue('g-menu-1'),
          activeChannelIdProvider.overrideWithValue(null),
          channelListViewModelProvider.overrideWith(
            () => _StaticChannelListViewModel(channelState),
          ),
          channelPermissionCacheProvider(
            kTestAccountUserId,
          ).overrideWith(_StaticPermissionCache.new),
          guildPermissionsProvider(
            kTestAccountUserId,
          ).overrideWith(_StaticGuildPermissions.new),
          appearancePreferencesProvider.overrideWith(
            _StaticAppearancePreferences.new,
          ),
          userSettingsViewModelProvider.overrideWith(_StaticUserSettings.new),
          voiceSessionProvider.overrideWith(_StaticVoiceSession.new),
          sensitiveContentProvider.overrideWith(_StaticSensitiveContent.new),
          matureContentAgreementsProvider.overrideWith(
            _StaticMatureAgreements.new,
          ),
          guildMuteProvider('g-menu-1').overrideWithValue(
            const AsyncData<GuildMuteState>(GuildMuteState()),
          ),
          mutedChannelIdsProvider(
            'g-menu-1',
          ).overrideWithValue(const AsyncData<Set<String>>(<String>{})),
          guildCollapsedCategoriesProvider(
            'g-menu-1',
          ).overrideWithValue(const AsyncData<Set<String>>(<String>{})),
          guildReadStateProvider.overrideWithValue(
            const <String, GuildReadStateEntry>{},
          ),
          effectiveGuildChannelPermissionBitsProvider(
            'cat-1',
          ).overrideWith((Ref ref) => Permission.viewChannel.value),
          effectiveGuildChannelPermissionBitsProvider(
            _testChannel.id,
          ).overrideWith((Ref ref) => Permission.viewChannel.value),
          channelSidebarIconConnectBitsProvider(
            _testChannel.id,
          ).overrideWith((Ref ref) => null),
          channelUnreadProvider(_testChannel.id).overrideWith(
            (Ref ref) => Stream<UnreadState>.value(const UnreadState()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _shell(
          container: container,
          locale: esLocale,
          child: const Scaffold(body: GuildSidebar()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('My Category'), buttons: kSecondaryButton);
      await tester.pumpAndSettle();

      await tester.tap(find.text(esL10n.categoryMuteCategory));
      await tester.pumpAndSettle();

      expect(find.text(esL10n.categoryMuteCategory), findsNWidgets(2));
      expect(find.text('Mute Category'), findsNothing);
    },
  );
}
