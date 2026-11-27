// Fork: tyne-chat/tyne#946 — regression tests for Group C (DM/inbox/keybinds/guilds)
// post-await WidgetRef/BuildContext disposal hazards across InboxPopout,
// UnreadChannelInboxCard, KeybindScope, registerKeybindHandlers, AddGuildModal,
// and loadInvitePeopleRecipients.

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/daos/notification_dao.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/providers/instance/well_known_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/synced_preferences/engine/synced_preference_field.dart';
import 'package:fluxer_app/core/synced_preferences/engine/synced_preferences_store.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_providers.dart';
import 'package:fluxer_app/features/dm/data/dm_repository.dart';
import 'package:fluxer_app/features/dm/domain/dm_conversation.dart';
import 'package:fluxer_app/features/dm/providers/dm_providers.dart';
import 'package:fluxer_app/features/friends/data/friend_repository.dart';
import 'package:fluxer_app/features/friends/domain/friend.dart';
import 'package:fluxer_app/features/friends/providers/friend_providers.dart';
import 'package:fluxer_app/features/guilds/data/guild_user_settings_repository.dart';
import 'package:fluxer_app/features/guilds/presentation/modals/add_guild_modal.dart';
import 'package:fluxer_app/features/guilds/providers/add_guild_enabled_provider.dart';
import 'package:fluxer_app/features/guilds/utils/invites/invite_people_recipients.dart';
import 'package:fluxer_app/features/input/domain/keybind_action.dart';
import 'package:fluxer_app/features/input/presentation/keybind_scope.dart';
import 'package:fluxer_app/features/input/providers/keybind_handler_registry.dart';
import 'package:fluxer_app/features/input/providers/keyboard_mode_provider.dart';
import 'package:fluxer_app/features/input/services/keybind_handlers.dart';
import 'package:fluxer_app/features/notifications/data/notifications_repository.dart';
import 'package:fluxer_app/features/notifications/data/unread_inbox_card_cache.dart';
import 'package:fluxer_app/features/notifications/data/unread_inbox_card_meta.dart';
import 'package:fluxer_app/features/notifications/data/unread_inbox_view.dart';
import 'package:fluxer_app/features/notifications/domain/unread_inbox_entry.dart';
import 'package:fluxer_app/features/notifications/presentation/inbox_popout.dart';
import 'package:fluxer_app/features/notifications/presentation/widgets/unread_channel_inbox_card.dart';
import 'package:fluxer_app/features/notifications/presentation/widgets/unread_inbox_card_header.dart';
import 'package:fluxer_app/features/notifications/providers/notifications_providers.dart';
import 'package:fluxer_app/features/settings/providers/preferences/advanced_preferences_provider.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/icons/phosphor.dart';
import 'package:fluxer_dart/export.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/core_test_provider_overrides.dart';
import '../../../../helpers/fake_well_known.dart';
import '../../../../helpers/open_test_database.dart';
import '../../../../helpers/test_l10n.dart';

Widget _shell({required ProviderContainer container, required Widget child}) {
  final colorTheme = buildDarkColorTheme();
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      navigatorKey: rootNavigatorKey,
      locale: kTestLocale,
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

class _SkipConfirmAdvancedPreferences extends AdvancedPreferences {
  @override
  AdvancedPreferencesState build() =>
      const AdvancedPreferencesState(skipMarkAllAsReadConfirmation: true);
}

class _SuspendingNotificationsRepository extends NotificationsRepository {
  _SuspendingNotificationsRepository({
    required super.database,
    required super.messageRepository,
    required super.client,
    required super.currentUserId,
    required this.markAllCompleter,
  });

  final Completer<void> markAllCompleter;
  int markAllCalls = 0;

  @override
  Future<void> markAllInboxChannelsAsRead(
    Iterable<UnreadInboxEntry> entries,
  ) async {
    markAllCalls += 1;
    await markAllCompleter.future;
  }
}

class _SuspendingNotificationDao extends NotificationDao {
  _SuspendingNotificationDao(super.attachedDatabase, this.upsertCompleter);

  final Completer<void> upsertCompleter;

  @override
  Future<void> upsertUnreadCollapsed({
    required String channelId,
    required bool isCollapsed,
  }) => upsertCompleter.future;
}

class _ControllableNotificationDatabase extends db.FluxerDatabase {
  _ControllableNotificationDatabase(this.upsertCompleter)
    : super.forTesting(NativeDatabase.memory()) {
    _dao = _SuspendingNotificationDao(this, upsertCompleter);
  }

  final Completer<void> upsertCompleter;
  late final _SuspendingNotificationDao _dao;

  @override
  NotificationDao get notificationDao => _dao;
}

class _RecordingSyncedStore extends SyncedPreferencesStore {
  // Test stub passes ref explicitly.
  // ignore: use_super_parameters
  _RecordingSyncedStore(Ref ref) : super(ref);

  final List<SyncedPreferenceField> dirtyFields = <SyncedPreferenceField>[];

  @override
  void markDirty(SyncedPreferenceField field) {
    dirtyFields.add(field);
  }

  @override
  void scheduleFlush() {}
}

class _SuspendingWellKnown extends WellKnown {
  _SuspendingWellKnown(this.completer);

  final Completer<WellKnownFluxerResponse> completer;

  @override
  Future<WellKnownFluxerResponse> build() => completer.future;
}

class _SuspendingFriendRepository extends FriendRepository {
  // Test stub passes super arguments explicitly.
  // ignore: use_super_parameters
  _SuspendingFriendRepository(
    FluxerClient client,
    db.FluxerDatabase db,
    this.completer,
  ) : super(client, db);

  final Completer<List<Friend>> completer;

  @override
  Future<List<Friend>> getRelationships() => completer.future;
}

class _StubDmRepository extends DmRepository {
  // Test stub passes super arguments explicitly.
  // ignore: use_super_parameters
  _StubDmRepository(
    FluxerClient client,
    db.FluxerDatabase db,
    GuildUserSettingsRepository guildSettings,
  ) : super(client, db, guildSettings);

  @override
  Future<List<DmConversation>> getDmChannels() async =>
      const <DmConversation>[];
}

class _EmptyHttpAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(<String, Object?>{}),
    200,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  testWidgets(
    'InboxPopout _markAllAsRead and UnreadChannelInboxCard _toggleCollapsed survive unmount',
    (WidgetTester tester) async {
      final Completer<void> markAllCompleter = Completer<void>();
      final Completer<void> upsertCompleter = Completer<void>();
      final _ControllableNotificationDatabase mockDb =
          _ControllableNotificationDatabase(upsertCompleter);
      addTearDown(() async {
        await flushTestWidgetBinding();
        await mockDb.close().timeout(
          const Duration(seconds: 2),
          onTimeout: mockDb.executor.close,
        );
      });

      await mockDb.channelDao.upsertChannel(
        db.ChannelsCompanion.insert(
          id: 'inbox-ch-1',
          guildId: 'g-1',
          name: 'general',
        ),
      );

      final Dio dio = Dio(BaseOptions(baseUrl: 'https://api.fluxer.invalid'))
        ..httpClientAdapter = _EmptyHttpAdapter();
      int inboxBuilds = 0;
      late _RecordingSyncedStore syncedStore;

      const UnreadInboxEntry entry = UnreadInboxEntry(
        channelId: 'inbox-ch-1',
        guildId: 'g-1',
        isDm: false,
        mentionCount: 0,
        isCollapsed: true,
        recencyComparator: 1,
        ackMessageId: null,
        lastMessageId: null,
      );

      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: mockDb,
          extra: <Override>[
            fluxerDioProvider.overrideWithValue(dio),
            fluxerClientProvider.overrideWithValue(
              FluxerClient(dio, baseUrl: 'https://api.fluxer.invalid'),
            ),
            advancedPreferencesProvider.overrideWith(
              _SkipConfirmAdvancedPreferences.new,
            ),
            syncedPreferencesStoreProvider.overrideWith(
              (Ref ref) => syncedStore = _RecordingSyncedStore(ref),
            ),
            notificationsRepositoryProvider.overrideWith(
              (Ref ref) => _SuspendingNotificationsRepository(
                database: ref.watch(fluxerDatabaseProvider),
                messageRepository: ref.watch(messageRepositoryProvider),
                client: ref.watch(fluxerClientProvider),
                currentUserId: ref.watch(currentUserIdProvider),
                markAllCompleter: markAllCompleter,
              ),
            ),
            unreadInboxChannelListProvider.overrideWith((Ref ref) {
              inboxBuilds += 1;
              return Stream<List<UnreadInboxEntry>>.value(
                const <UnreadInboxEntry>[entry],
              );
            }),
          ],
        ),
      );
      addTearDown(container.dispose);

      final ValueNotifier<bool> mountInbox = ValueNotifier<bool>(true);
      addTearDown(mountInbox.dispose);
      final ValueNotifier<bool> mountCard = ValueNotifier<bool>(true);
      addTearDown(mountCard.dispose);

      await tester.pumpWidget(
        _shell(
          container: container,
          child: Scaffold(
            body: Column(
              children: <Widget>[
                Expanded(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: mountInbox,
                    builder: (_, bool mounted, _) {
                      if (!mounted) {
                        return const SizedBox.shrink();
                      }
                      return const InboxPopout();
                    },
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: mountCard,
                  builder: (_, bool mounted, _) {
                    if (!mounted) {
                      return const SizedBox.shrink();
                    }
                    return UnreadChannelInboxCard(
                      row: UnreadInboxRow(
                        entry: entry,
                        data: UnreadInboxCardData(
                          cacheKey: 'inbox-ch-1',
                          meta: UnreadInboxCardMeta.empty(),
                          messages: const [],
                          hasMoreUnread: false,
                        ),
                        collapsed: true,
                        read: false,
                      ),
                      onCollapsedChanged: (_) {},
                      onDismissed: () {},
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final int initialBuilds = inboxBuilds;

      // 1. InboxPopout mark all as read -> unmount while markAllInboxChannelsAsRead is pending.
      await tester.tap(find.byIcon(PhosphorIconsBold.check).first);
      await tester.pump();

      mountInbox.value = false;
      await tester.pump();

      markAllCompleter.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      // Re-reading forces lazy rebuild after InboxPopout unmounted.
      container.read(unreadInboxChannelListProvider);
      await tester.pump();
      expect(inboxBuilds, greaterThan(initialBuilds));

      // 2. UnreadChannelInboxCard toggle collapse -> unmount while upsertUnreadCollapsed is pending.
      final UnreadInboxCardHeader header = tester.widget<UnreadInboxCardHeader>(
        find.byType(UnreadInboxCardHeader),
      );
      header.onToggleCollapsed!();
      await tester.pump();

      mountCard.value = false;
      await tester.pump();

      upsertCompleter.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(
        syncedStore.dirtyFields,
        contains(SyncedPreferenceField.unreadChannels),
      );
    },
  );

  testWidgets(
    'KeybindScope _dispatchFirst and registerKeybindHandlers survive unmount',
    (WidgetTester tester) async {
      final Completer<void> markAllCompleter = Completer<void>();
      final Completer<bool> focusCompleter = Completer<bool>();
      final db.FluxerDatabase mockDb = openTestDatabase();
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://api.fluxer.invalid'))
        ..httpClientAdapter = _EmptyHttpAdapter();

      int inboxBuilds = 0;
      const UnreadInboxEntry entry = UnreadInboxEntry(
        channelId: 'inbox-kb-1',
        guildId: 'g-1',
        isDm: false,
        mentionCount: 0,
        isCollapsed: false,
        recencyComparator: 1,
        ackMessageId: null,
        lastMessageId: null,
      );

      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: mockDb,
          extra: <Override>[
            fluxerDioProvider.overrideWithValue(dio),
            fluxerClientProvider.overrideWithValue(
              FluxerClient(dio, baseUrl: 'https://api.fluxer.invalid'),
            ),
            unreadInboxChannelListProvider.overrideWith((Ref ref) {
              inboxBuilds += 1;
              return Stream<List<UnreadInboxEntry>>.value(
                const <UnreadInboxEntry>[entry],
              );
            }),
            notificationsRepositoryProvider.overrideWith(
              (Ref ref) => _SuspendingNotificationsRepository(
                database: ref.watch(fluxerDatabaseProvider),
                messageRepository: ref.watch(messageRepositoryProvider),
                client: ref.watch(fluxerClientProvider),
                currentUserId: ref.watch(currentUserIdProvider),
                markAllCompleter: markAllCompleter,
              ),
            ),
          ],
        ),
      );
      addTearDown(container.dispose);
      final ProviderSubscription<AsyncValue<List<UnreadInboxEntry>>> inboxSub =
          container.listen(unreadInboxChannelListProvider, (_, _) {});
      addTearDown(inboxSub.close);
      await tester.pump();
      final int initialBuilds = inboxBuilds;

      final ValueNotifier<bool> mountHandlers = ValueNotifier<bool>(true);
      addTearDown(mountHandlers.dispose);
      final ValueNotifier<bool> mountScope = ValueNotifier<bool>(false);
      addTearDown(mountScope.dispose);
      final GoRouter router = GoRouter(
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (BuildContext ctx, GoRouterState state) => Scaffold(
              body: Column(
                children: <Widget>[
                  ValueListenableBuilder<bool>(
                    valueListenable: mountHandlers,
                    builder: (_, bool mounted, _) {
                      if (!mounted) {
                        return const SizedBox.shrink();
                      }
                      return Consumer(
                        builder: (BuildContext c, WidgetRef ref, _) {
                          registerKeybindHandlers(ref: ref, context: c);
                          return const SizedBox.shrink();
                        },
                      );
                    },
                  ),
                  Expanded(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: mountScope,
                      builder: (_, bool mounted, _) {
                        if (!mounted) {
                          return const SizedBox.shrink();
                        }
                        return const KeybindScope(child: SizedBox.expand());
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      final colorTheme = buildDarkColorTheme();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            locale: kTestLocale,
            localizationsDelegates: fluxerLocalizationsDelegates,
            supportedLocales: FluxerLocalizations.supportedLocales,
            theme: buildFluxerTheme(
              colorTheme: colorTheme,
              textTheme: FluxerTextTheme.fromColors(colorTheme),
              layoutTheme: FluxerLayoutTheme.scaled(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Trigger registered chatMarkInboxRead handler, unmount handler widget before markAll finishes.
      final Future<bool> inboxFuture = container
          .read(keybindHandlerRegistryProvider)
          .invoke(KeybindAction.chatMarkInboxRead);
      await tester.pump();

      mountHandlers.value = false;
      await tester.pump();

      markAllCompleter.complete();
      await tester.pump();
      expect(await inboxFuture, isTrue);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(inboxBuilds, greaterThan(initialBuilds));

      // 2. Mount KeybindScope, replace messageFocusTextarea handler with async one, trigger Escape, unmount KeybindScope.
      mountScope.value = true;
      await tester.pump();
      container
          .read(keybindHandlerRegistryProvider)
          .register(
            KeybindAction.messageFocusTextarea,
            () => focusCompleter.future,
          );
      container.read(keyboardModeProvider.notifier).enter();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      mountScope.value = false;
      await tester.pump();

      focusCompleter.complete(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'showAddGuildModal and loadInvitePeopleRecipients handle caller unmount during async fetches',
    (WidgetTester tester) async {
      final WellKnownFluxerResponse fakeWellKnown = await FakeWellKnown()
          .build();
      final Completer<WellKnownFluxerResponse> wellKnownCompleter =
          Completer<WellKnownFluxerResponse>();
      final Completer<List<Friend>> friendsCompleter =
          Completer<List<Friend>>();
      final db.FluxerDatabase mockDb = openTestDatabase();
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://api.fluxer.invalid'))
        ..httpClientAdapter = _EmptyHttpAdapter();

      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: mockDb,
          extra: <Override>[
            fluxerDioProvider.overrideWithValue(dio),
            fluxerClientProvider.overrideWithValue(
              FluxerClient(dio, baseUrl: 'https://api.fluxer.invalid'),
            ),
            addGuildEnabledProvider.overrideWithValue(true),
            wellKnownProvider.overrideWith(
              () => _SuspendingWellKnown(wellKnownCompleter),
            ),
            friendRepositoryProvider.overrideWith(
              (Ref ref) => _SuspendingFriendRepository(
                ref.watch(fluxerClientProvider),
                mockDb,
                friendsCompleter,
              ),
            ),
            dmRepositoryProvider.overrideWith(
              (Ref ref) => _StubDmRepository(
                ref.watch(fluxerClientProvider),
                mockDb,
                ref.watch(guildUserSettingsRepositoryProvider),
              ),
            ),
          ],
        ),
      );
      addTearDown(container.dispose);

      final ValueNotifier<bool> mountLauncher = ValueNotifier<bool>(true);
      addTearDown(mountLauncher.dispose);
      late BuildContext hostContext;
      late Future<List<Object?>> recipientsFuture;

      await tester.pumpWidget(
        _shell(
          container: container,
          child: Builder(
            builder: (BuildContext ctx) {
              hostContext = ctx;
              return Scaffold(
                body: Consumer(
                  builder: (_, WidgetRef hostRef, _) => Column(
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: () =>
                            unawaited(showAddGuildModal(hostContext, hostRef)),
                        child: const Text('AddGuild'),
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: mountLauncher,
                        builder: (_, bool mounted, _) {
                          if (!mounted) {
                            return const SizedBox.shrink();
                          }
                          return Consumer(
                            builder: (_, WidgetRef callerRef, _) =>
                                ElevatedButton(
                                  onPressed: () {
                                    recipientsFuture =
                                        loadInvitePeopleRecipients(
                                          ref: callerRef,
                                          l10n: testL10n,
                                        );
                                  },
                                  child: const Text('LoadRecipients'),
                                ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();

      // 1. Open AddGuildModal -> pop before wellKnownProvider finishes.
      await tester.tap(find.text('AddGuild'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      Navigator.of(rootNavigatorKey.currentContext!).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      wellKnownCompleter.complete(fakeWellKnown);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);

      // 2. loadInvitePeopleRecipients -> unmount caller WidgetRef before getRelationships completes.
      await tester.tap(find.text('LoadRecipients'));
      await tester.pump();

      mountLauncher.value = false;
      await tester.pump();

      friendsCompleter.complete(const <Friend>[
        Friend(
          id: 'friend-1',
          username: 'alice',
          discriminator: '0001',
          friendStatus: FriendStatus.accepted,
        ),
      ]);
      await tester.pump();
      final List<Object?> recipients = await recipientsFuture;
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(recipients, hasLength(1));
    },
  );
}
