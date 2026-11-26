// Fork: tyne-chat/tyne#940. End-to-end widget reproduction of quick-reacting
// right after jumping to a message: closing the bottom sheet triggers a spurious
// ChannelChatContent resync GET, and the concurrent pre-reaction GET wipes the
// optimistic reaction even after PUT /reactions returns 204.
@Tags(['slow'])
library;

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/limits/instance_limit_provider.dart';
import 'package:fluxer_app/core/limits/limit_key.dart';
import 'package:fluxer_app/core/platform/fluxer_platform.dart';
import 'package:fluxer_app/core/providers/app/app_startup_provider.dart';
import 'package:fluxer_app/core/providers/app/app_ui_lifecycle_provider.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/providers/instance/well_known_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/router/route_state_providers.dart';
import 'package:fluxer_app/core/router/shell_popup_route_observer.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/providers/theme_preference_provider.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/core/utils/channel_jump_link.dart';
import 'package:fluxer_app/features/accessibility/providers/effective_motion_preferences_provider.dart';
import 'package:fluxer_app/features/channels/data/ack_batcher.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/channels/providers/ack_batcher_provider.dart';
import 'package:fluxer_app/features/channels/providers/channel_list_view_model.dart';
import 'package:fluxer_app/features/channels/providers/channel_providers.dart';
import 'package:fluxer_app/features/chat/domain/favorite_meme.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/channel/channel_chat_content.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/channel/fork_channel_chat_jump_dedup.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/message_actions/quick_reaction_loader.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/message_actions/quick_reaction_row.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/messages/message_list.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/messages/message_reactions_bar.dart';
import 'package:fluxer_app/features/chat/providers/channel/channel_message_permissions_provider.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/chat/providers/core/message_pagination_coordinator.dart';
import 'package:fluxer_app/features/chat/providers/guild/guild_composer_access_provider.dart';
import 'package:fluxer_app/features/chat/providers/messages/message_length_limits_provider.dart';
import 'package:fluxer_app/features/chat/providers/messages/message_translation_provider.dart';
import 'package:fluxer_app/features/chat/providers/messages/saved_message_provider.dart';
import 'package:fluxer_app/features/chat/providers/pickers/favorite_media_provider.dart';
import 'package:fluxer_app/features/chat/utils/channel_jump_navigator.dart';
import 'package:fluxer_app/features/dm/domain/dm_conversation.dart';
import 'package:fluxer_app/features/dm/providers/dm_view_model.dart';
import 'package:fluxer_app/features/friends/domain/friend.dart';
import 'package:fluxer_app/features/friends/providers/blocked_user_ids_provider.dart';
import 'package:fluxer_app/features/guilds/services/guild_verification.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/features/settings/providers/preferences/appearance_preferences_provider.dart';
import 'package:fluxer_app/features/settings/providers/preferences/chat_preferences_provider.dart';
import 'package:fluxer_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:fluxer_app/features/shell/providers/drawer/reveal_side_provider.dart';
import 'package:fluxer_app/features/shell/providers/layout/shell_popup_overlay_provider.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/services/guild_member_hydration_service.dart';
import 'package:fluxer_dart/export.dart' hide ChannelType;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../helpers/fork_message_gap_harness.dart';
import '../../../../../helpers/fork_no_personas.dart';
import '../../../../../helpers/input_modality_override.dart';
import '../../../../../helpers/instance_runtime_config_override.dart';
import '../../../../../helpers/message_list_unread_ack_test_helpers.dart';
import '../../../../../helpers/noop_guild_member_hydration_service.dart';
import '../../../../../helpers/open_test_database.dart';
import '../../../../../helpers/test_l10n.dart';

class _EndToEndReactionServer extends GapServer {
  bool holdNextMessageGet = false;
  bool holdNextReactionPut = false;
  Completer<void>? _getStartedCompleter;
  Completer<void>? _getReleaseCompleter;
  Completer<void>? _putStartedCompleter;
  Completer<void>? _putReleaseCompleter;

  bool get messageGetHeld => _getReleaseCompleter != null;

  Future<void> waitForHeldMessageGet() =>
      (_getStartedCompleter ??= Completer<void>()).future;

  Future<void> waitForHeldReactionPut() =>
      (_putStartedCompleter ??= Completer<void>()).future;

  void releaseMessageGet() {
    holdNextMessageGet = false;
    final Completer<void>? release = _getReleaseCompleter;
    _getReleaseCompleter = null;
    _getStartedCompleter = null;
    if (release != null && !release.isCompleted) {
      release.complete();
    }
  }

  void releaseReactionPut() {
    holdNextReactionPut = false;
    final Completer<void>? release = _putReleaseCompleter;
    _putReleaseCompleter = null;
    _putStartedCompleter = null;
    if (release != null && !release.isCompleted) {
      release.complete();
    }
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final String path = options.uri.path;
    final RegExpMatch? reactionPut = RegExp(
      r'/channels/([^/]+)/messages/([^/]+)/reactions/([^/]+)/@me$',
    ).firstMatch(path);
    if (options.method == 'PUT' && reactionPut != null) {
      final String messageId = reactionPut.group(2)!;
      requests.add('putReaction #${historyIds.indexOf(messageId)}');
      if (holdNextReactionPut) {
        holdNextReactionPut = false;
        final Completer<void> started = _putStartedCompleter ??=
            Completer<void>();
        if (!started.isCompleted) {
          started.complete();
        }
        await (_putReleaseCompleter ??= Completer<void>()).future;
      }
      _recordReactionOnServer(
        messageId: messageId,
        emojiName: Uri.decodeComponent(reactionPut.group(3)!),
      );
      return ResponseBody.fromString('', 204, statusMessage: 'No Content');
    }

    if (options.method == 'GET' &&
        path.endsWith('/channels/$kGapChannelId/messages') &&
        holdNextMessageGet) {
      holdNextMessageGet = false;
      final ResponseBody snapshot = await super.fetch(
        options,
        requestStream,
        cancelFuture,
      );
      final Completer<void> started = _getStartedCompleter ??=
          Completer<void>();
      if (!started.isCompleted) {
        started.complete();
      }
      await (_getReleaseCompleter ??= Completer<void>()).future;
      return snapshot;
    }

    return await super.fetch(options, requestStream, cancelFuture);
  }

  void _recordReactionOnServer({
    required String messageId,
    required String emojiName,
  }) {
    final int index = historyIds.indexOf(messageId);
    if (index == -1) {
      return;
    }
    history[index] = <String, Object?>{
      ...history[index],
      'reactions': <Map<String, Object?>>[
        <String, Object?>{
          'emoji': <String, Object?>{
            'id': null,
            'name': emojiName,
            'animated': false,
          },
          'count': 1,
          'me': true,
        },
      ],
    };
  }
}

class _IdleAppStartup extends AppStartup {
  @override
  Future<void> build() => Future<void>.value();
}

class _FakeWellKnown extends WellKnown {
  @override
  Future<WellKnownFluxerResponse> build() async {
    return const WellKnownFluxerResponse(
      apiCodeVersion: 1,
      endpoints: InstanceEndpointsSchema(
        api: '',
        apiClient: '',
        apiPublic: '',
        gateway: '',
        media: '',
        staticCdn: '',
        marketing: '',
        admin: '',
        invite: '',
        gift: '',
        webapp: '',
      ),
      captcha: InstanceCaptchaSchema(provider: CaptchaProviderSchema.none),
      features: InstanceFeaturesSchema(
        voiceEnabled: false,
        stripeEnabled: false,
        premiumEnabled: false,
        stripeServiceable: false,
        selfHosted: false,
        presignedAttachmentUploads: false,
        emailsEnabled: false,
        phoneVerificationEnabled: false,
        accountIdentity: AccountIdentityModeSchema.email,
        tagStyle: TagStyleSchema.random,
      ),
      gif: InstanceGifSchema(
        provider: '',
        displayName: '',
        attributionRequired: false,
      ),
      sso: InstanceSsoSchema(
        enabled: false,
        enforced: false,
        usernameFromProvider: false,
        displayName: null,
        buttonLabel: null,
        redirectUri: '',
      ),
      registration: InstanceRegistrationSchema(
        mode: InstanceRegistrationModeSchema.open,
        adminRegistrationUrlsEnabled: false,
      ),
      community: InstanceCommunitySchema(
        singleCommunity: false,
        singleCommunityGuildId: null,
        directMessagesDisabled: false,
        guildCreateAccess: true,
      ),
      services: InstanceServicesSchema(
        connectionProviders: <InstanceConnectionProviderSchema>[],
        gifEnabled: false,
        youtubeEnabled: false,
        blueskyEnabled: false,
      ),
      limits: WellKnownFluxerResponseLimits(
        version: 2,
        traitDefinitions: <String>[],
        rules: <WellKnownFluxerResponseLimitsRules>[],
        defaultsHash: '',
      ),
      push: InstancePushSchema(publicVapidKey: null),
      appPublic: InstanceAppPublicSchema(
        branding: InstanceBrandingSchema(
          productName: '',
          iconUrl: null,
          symbolUrl: null,
          logoUrl: null,
          wordmarkUrl: null,
          faviconUrl: null,
          themeColor: null,
          statusPageUrl: null,
          statusPageInstatus: false,
          statusPageIncidentHistoryUrl: null,
          premiumProductName: 'Plutonium',
          premiumInfoUrl: null,
          faviconDarkUrl: null,
          signInBackdropUrl: null,
          premiumPageColor: null,
          premiumShowcaseExpressionsUrl: null,
          premiumShowcaseProfileUrl: null,
          premiumShowcaseStreamUrl: null,
          premiumShowcaseUploadUrl: null,
          customCss: null,
          uploadLimitMessage: null,
          trustedDomains: <String>[],
        ),
        setup: InstanceSetupSchema(configured: true, adminUrl: null),
        legal: InstanceAppPublicSchemaLegal(
          termsUrl: null,
          privacyUrl: null,
          guidelinesUrl: null,
        ),
        registration: InstanceAppPublicSchemaRegistration(
          collectDateOfBirth: false,
        ),
      ),
      agePolicy: InstanceAgePolicySchema(geos: []),
    );
  }
}

Future<void> _settle(WidgetTester tester, {int rounds = 30}) async {
  for (int i = 0; i < rounds; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() async {
      for (int j = 0; j < 4; j++) {
        await pumpEventQueue();
      }
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel recorderChannel = MethodChannel(
    'com.llfbandit.record/messages',
  );

  Future<void> teardownTree(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SizedBox.shrink(),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      for (int i = 0; i < 4; i++) {
        await pumpEventQueue();
      }
    });
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  Future<
    ({
      ProviderContainer container,
      _EndToEndReactionServer server,
      db.FluxerDatabase database,
    })
  >
  mountJumpAndOpenSheet(
    WidgetTester tester, {
    required String targetId,
    String expectedJumpRequest = 'around #50',
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(recorderChannel, (_) async => null);
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(recorderChannel, null),
    );
    debugSetFluxerRuntimeMobileFormFactor(value: true);
    addTearDown(() => debugSetFluxerRuntimeMobileFormFactor(value: null));

    tester.view.physicalSize = const Size(420, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db.FluxerDatabase database = openTestDatabase();
    final _EndToEndReactionServer server = _EndToEndReactionServer();
    await tester.runAsync(() => seedGapChannels(database));

    final Dio dio = Dio(BaseOptions(baseUrl: 'https://api.fluxer.app/v1'))
      ..httpClientAdapter = server;
    final FluxerClient client = FluxerClient(
      dio,
      baseUrl: 'https://api.fluxer.app/v1',
    );
    final ProviderContainer container = ProviderContainer(
      overrides: [
        instanceRuntimeConfigOverride(),
        fluxerDatabaseProvider.overrideWithValue(database),
        appUiForegroundProvider.overrideWithValue(true),
        fluxerDioProvider.overrideWithValue(dio),
        fluxerClientProvider.overrideWithValue(client),
        currentUserIdProvider.overrideWithValue('me'),
        activeChannelIdProvider.overrideWithValue(kGapChannelId),
        currentRevealSideProvider.overrideWithValue(RevealSide.main),
        wellKnownProvider.overrideWith(_FakeWellKnown.new),
        maxMessageLengthProvider.overrideWithValue(2000),
        myPersonasProvider.overrideWith(ForkNoPersonas.new),
        inputModalityOverride(touch: true),
        ackBatcherProvider.overrideWith((ref) {
          final AckBatcher batcher = AckBatcher(
            client: client,
            batchDelay: Duration.zero,
          );
          ref.onDispose(() {
            unawaited(batcher.dispose());
          });
          return batcher;
        }),
        guildMemberHydrationServiceProvider.overrideWithValue(
          NoopGuildMemberHydrationService(database: database),
        ),
        messagePaginationCoordinatorProvider.overrideWith((ref) {
          final MessagePaginationCoordinator coordinator =
              MessagePaginationCoordinator(ref, now: tester.binding.clock.now);
          ref.onDispose(coordinator.dispose);
          return coordinator;
        }),
        androidAnimatorDurationDisabledProvider.overrideWith(
          (ref) => Stream<bool>.value(false),
        ),
        appStartupProvider.overrideWith(_IdleAppStartup.new),
        blockedUserIdsProvider.overrideWithValue(<String>{}),
        activeGuildIdProvider.overrideWithValue(null),
        channelListViewModelProvider.overrideWithValue(
          const ChannelListState(
            guild: null,
            categories: <ChannelCategory>[],
            selectedChannelId: kGapChannelId,
          ),
        ),
        guildComposerAccessProvider(
          kGapChannelId,
        ).overrideWithValue(const AsyncData(GuildComposerAccess.allowed)),
        dmViewModelProvider.overrideWithValue(
          const DmViewState(
            conversations: <DmConversation>[],
            friendsList: <Friend>[],
            activeTab: FriendsTab.online,
            searchQuery: '',
          ),
        ),
        channelMessagePermissionsProvider(
          kGapChannelId,
        ).overrideWith((ref) => ChannelMessagePermissions.all),
        messageListReadStateProvider(
          kGapChannelId,
        ).overrideWith((ref) => messageListUnreadAckStream()),
        themePreferenceProvider.overrideWithValue(ThemePreferenceState()),
        userSettingsViewModelProvider.overrideWithValue(
          const UserSettingsViewState(
            userId: 'me',
            username: 'tester',
            displayName: 'Tester',
            discriminator: '0',
            avatar: null,
            avatarColor: null,
            memberSince: null,
            status: 'online',
            messageDisplayCompact: false,
            developerMode: false,
            trustedDomains: <String>[],
            renderEmbeds: false,
            inlineAttachmentMedia: false,
          ),
        ),
        chatPreferencesProvider.overrideWithValue(const ChatPreferencesState()),
        appearancePreferencesProvider.overrideWithValue(
          const AppearancePreferencesState(),
        ),
        instanceFeatureEnabledProvider(
          LimitKeys.featureGlobalExpressions,
        ).overrideWith((ref) => false),
        isMessageSavedProvider(
          targetId,
        ).overrideWith((ref) => Stream<bool>.value(false)),
        favoriteMemesProvider.overrideWith(
          (ref) => Stream<List<FavoriteMeme>>.value(const <FavoriteMeme>[]),
        ),
        messageTranslationAvailableProvider.overrideWith(
          (ref) => Future<bool>.value(false),
        ),
      ],
    );
    addTearDown(() async {
      server
        ..releaseReactionPut()
        ..releaseMessageGet();
      await teardownTree(tester, container);
      container.dispose();
    });

    final ProviderSubscription<Object?> channelSub = container.listen(
      channelByIdProvider(kGapChannelId),
      (_, _) {},
    );
    addTearDown(channelSub.close);

    final ShellPopupRouteObserver popupObserver = ShellPopupRouteObserver(
      ({required bool hasOverlay}) => container
          .read(shellHasPopupOverlayProvider.notifier)
          .setHasOverlay(value: hasOverlay),
    );
    final colorTheme = buildDarkColorTheme();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: kTestLocale,
          localizationsDelegates: fluxerLocalizationsDelegates,
          supportedLocales: FluxerLocalizations.supportedLocales,
          theme: buildFluxerTheme(
            colorTheme: colorTheme,
            textTheme: FluxerTextTheme.fromColors(colorTheme),
            layoutTheme: FluxerLayoutTheme.scaled(),
          ),
          navigatorObservers: <NavigatorObserver>[popupObserver],
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(disableAnimations: true),
                  child: ChannelChatContent(
                    channelId: kGapChannelId,
                    targetMessageId: targetId,
                    showTopBar: false,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    await _settle(tester);

    expect(server.requests, contains(expectedJumpRequest));
    expect(
      container
          .read(channelJumpTargetLedgerProvider)
          .isConsumed(channelId: kGapChannelId, messageId: targetId),
      isTrue,
      reason: 'baseline: initial jump target must settle and be consumed',
    );
    final Finder targetTile = find.byKey(ValueKey<String>('msg-$targetId'));
    expect(
      targetTile,
      findsOneWidget,
      reason: 'baseline: jumped message tile must be on screen',
    );

    await tester.longPress(targetTile);
    await _settle(tester);

    expect(
      container.read(shellHasPopupOverlayProvider),
      isTrue,
      reason: 'baseline: opening message sheet flips popup overlay flag true',
    );
    expect(find.byType(MessageQuickReactionRow), findsOneWidget);
    expect(find.byType(QuickReactionGlyph), findsWidgets);

    return (container: container, server: server, database: database);
  }

  testWidgets(
    'tapping a quick reaction after a message jump does not trigger a spurious message GET on sheet close',
    (WidgetTester tester) async {
      final String targetId = gapHistoryId(50);
      final setup = await mountJumpAndOpenSheet(tester, targetId: targetId);
      final int requestsBeforeTap = setup.server.requests.length;

      await tester.tap(find.byType(QuickReactionGlyph).first);
      await _settle(tester);

      final List<String> afterTap = setup.server.requests
          .skip(requestsBeforeTap)
          .toList();
      expect(afterTap, contains('putReaction #50'));
      expect(
        afterTap.where((String req) => req != 'putReaction #50'),
        isEmpty,
        reason:
            'closing the quick-reaction sheet after an already-consumed jump '
            'must not send a spurious switchChannel GET /messages request',
      );
    },
  );

  testWidgets(
    'quick-reacting right after a jump keeps the reaction on screen and in storage when a concurrent GET returns pre-reaction state after PUT 204',
    (WidgetTester tester) async {
      final String targetId = gapHistoryId(50);
      final setup = await mountJumpAndOpenSheet(tester, targetId: targetId);

      var sawOptimisticReaction = false;
      final ProviderSubscription<ChatViewState> sub = setup.container.listen(
        chatViewModelProvider,
        (_, ChatViewState next) {
          for (final Message message in next.messages) {
            if (message.id == targetId &&
                message.reactions.any((Reaction r) => r.hasReacted)) {
              sawOptimisticReaction = true;
            }
          }
        },
      );
      addTearDown(sub.close);

      // Capture the server race observed in prod: PUT /reactions and the
      // spurious GET /messages triggered by popping the sheet run concurrently;
      // GET reads pre-reaction state, PUT commits & returns 204 first, then
      // the stale GET response arrives on the client.
      setup.server.holdNextReactionPut = true;
      setup.server.holdNextMessageGet = true;

      await tester.tap(find.byType(QuickReactionGlyph).first);
      await _settle(tester);

      expect(
        sawOptimisticReaction,
        isTrue,
        reason: 'baseline: quick reaction must appear optimistically on tap',
      );
      expect(
        setup.server.requests,
        contains('putReaction #50'),
        reason: 'baseline: PUT /reactions must have started on tap',
      );
      expect(
        setup.container.read(shellHasPopupOverlayProvider),
        isFalse,
        reason: 'baseline: bottom sheet must have popped',
      );

      // PUT commits and finishes 204 first; if sheet pop fired a concurrent
      // GET, let the stale pre-reaction response land afterward as in prod.
      setup.server.releaseReactionPut();
      await _settle(tester);
      if (setup.server.messageGetHeld) {
        setup.server.releaseMessageGet();
        await _settle(tester);
      }

      final Message finalMessage = setup.container
          .read(chatViewModelProvider)
          .messages
          .firstWhere((Message m) => m.id == targetId);
      expect(
        finalMessage.reactions.where((Reaction r) => r.hasReacted),
        isNotEmpty,
        reason:
            'reaction must not vanish from state when the concurrent GET settles',
      );
      expect(
        find.descendant(
          of: find.byKey(ValueKey<String>('msg-$targetId')),
          matching: find.byType(MessageReactionsBar),
        ),
        findsOneWidget,
        reason: 'reaction pill must remain rendered on the message tile',
      );

      final db.Message? dbRow = await setup.database.messageDao.getMessage(
        kGapChannelId,
        targetId,
      );
      final List<dynamic> dbReactions =
          jsonDecode(dbRow!.reactionsJson) as List<dynamic>;
      expect(
        dbReactions,
        isNotEmpty,
        reason: 'Drift cache must retain the reaction',
      );
    },
  );

  testWidgets(
    'closing a popup after a consumed jump still allows a deliberate repeat jump to the same target',
    (WidgetTester tester) async {
      final String targetId = gapHistoryId(10);
      final setup = await mountJumpAndOpenSheet(
        tester,
        targetId: targetId,
        expectedJumpRequest: 'around #10',
      );

      // Tap quick reaction (closes sheet without spurious GET), then move the
      // window away to latest (#50..#99, which excludes #10) and re-trigger
      // a jump to #10.
      await tester.tap(find.byType(QuickReactionGlyph).first);
      await _settle(tester);

      await tester.runAsync(
        () => setup.container
            .read(chatViewModelProvider.notifier)
            .jumpToLatestMessages(),
      );
      await _settle(tester);

      final int requestsBeforeRetap = setup.server.requests.length;
      await tester.runAsync(
        () => navigateToChannelJumpLink(
          container: setup.container,
          link: MessageJumpLink(
            scope: 'guild-1',
            channelId: kGapChannelId,
            messageId: targetId,
          ),
        ),
      );
      await _settle(tester);

      expect(
        setup.server.requests.skip(requestsBeforeRetap),
        contains('around #10'),
        reason: 'a deliberate repeat jump must still fetch around targetId',
      );
    },
  );

  group('forkShouldAdoptConsumedJumpTarget', () {
    ChatViewState loadedState({
      String channelId = 'channel-1',
      List<Message>? messages,
      bool messageLoadFailed = false,
    }) {
      return ChatViewState(
        channelId: channelId,
        messages:
            messages ??
            <Message>[
              Message(
                id: 'target',
                channelId: channelId,
                authorId: 'u1',
                authorName: 'User',
                content: 'hi',
                timestamp: DateTime.utc(2026),
              ),
            ],
        replyingTo: null,
        replyMentioning: false,
        editingMessage: null,
        messageText: '',
        scrollToBottomSignal: 0,
        isLoading: false,
        isSyncingMessages: false,
        isLoadingMore: false,
        isLoadingNewer: false,
        hasMoreMessages: false,
        hasMoreNewerMessages: false,
        errorMessage: null,
        messageLoadFailed: messageLoadFailed,
      );
    }

    const ChannelChatSwitchRequest targetReq = (
      channelId: 'channel-1',
      targetMessageId: 'target',
      loadMessages: true,
    );
    const ChannelChatSwitchRequest nullReq = (
      channelId: 'channel-1',
      targetMessageId: null,
      loadMessages: true,
    );

    test(
      'adopts null request when jump target was consumed on loaded channel',
      () {
        final consumption = ChannelJumpTargetConsumption(
          consumedKeys: <String>{
            ChannelJumpTargetConsumption.keyFor(
              channelId: 'channel-1',
              messageId: 'target',
            ),
          },
        );
        expect(
          forkShouldAdoptConsumedJumpTarget(
            lastRequest: targetReq,
            request: nullReq,
            routeTarget: 'target',
            consumption: consumption,
            state: loadedState(),
          ),
          isTrue,
        );
      },
    );

    test(
      'adopts null request when jump target was superseded on loaded channel',
      () {
        const consumption = ChannelJumpTargetConsumption(
          latestIntentByChannel: <String, String>{'channel-1': 'other-target'},
        );
        expect(
          forkShouldAdoptConsumedJumpTarget(
            lastRequest: targetReq,
            request: nullReq,
            routeTarget: 'target',
            consumption: consumption,
            state: loadedState(),
          ),
          isTrue,
        );
      },
    );

    test('does not adopt when window is empty or load failed', () {
      final consumption = ChannelJumpTargetConsumption(
        consumedKeys: <String>{
          ChannelJumpTargetConsumption.keyFor(
            channelId: 'channel-1',
            messageId: 'target',
          ),
        },
      );
      expect(
        forkShouldAdoptConsumedJumpTarget(
          lastRequest: targetReq,
          request: nullReq,
          routeTarget: 'target',
          consumption: consumption,
          state: loadedState(messages: const <Message>[]),
        ),
        isFalse,
      );
      expect(
        forkShouldAdoptConsumedJumpTarget(
          lastRequest: targetReq,
          request: nullReq,
          routeTarget: 'target',
          consumption: consumption,
          state: loadedState(messageLoadFailed: true),
        ),
        isFalse,
      );
    });
  });
}
