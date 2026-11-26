// Fork: tyne-chat/tyne#943. End-to-end "Notification-Tap Storm" scenario matrix
// driving real ChannelChatContent + ChatViewModel + MessageList + IME height
// transitions + READY (gatewayFullRecoveryProvider) + GapServer across jump
// modes, keyboard states, READY timings, and reaction/action surfaces.
@Tags(['slow'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/deep_links/deep_link_handler.dart';
import 'package:fluxer_app/core/limits/instance_limit_provider.dart';
import 'package:fluxer_app/core/limits/limit_key.dart';
import 'package:fluxer_app/core/platform/fluxer_platform.dart';
import 'package:fluxer_app/core/providers/app/app_startup_provider.dart';
import 'package:fluxer_app/core/providers/app/app_ui_lifecycle_provider.dart';
import 'package:fluxer_app/core/providers/app/splash_exit_allowed_provider.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/providers/gateway/gateway_ready_provider.dart';
import 'package:fluxer_app/core/providers/gateway/gateway_reconnect_provider.dart';
import 'package:fluxer_app/core/providers/gateway/gateway_session_recovery_provider.dart';
import 'package:fluxer_app/core/providers/instance/well_known_provider.dart';
import 'package:fluxer_app/core/push/notification/pending_path_provider.dart';
import 'package:fluxer_app/core/push/notification/tap_handler.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/router/route_state_providers.dart';
import 'package:fluxer_app/core/router/shell_popup_route_observer.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/providers/theme_preference_provider.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/accessibility/providers/effective_motion_preferences_provider.dart';
import 'package:fluxer_app/features/channels/data/ack_batcher.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/channels/providers/ack_batcher_provider.dart';
import 'package:fluxer_app/features/channels/providers/channel_list_view_model.dart';
import 'package:fluxer_app/features/channels/providers/channel_providers.dart';
import 'package:fluxer_app/features/chat/domain/favorite_meme.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/sheets/persona_reaction_sheet.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/channel/channel_chat_content.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/message_actions/quick_reaction_loader.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/message_actions/quick_reaction_row.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/messages/message_list.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/messages/message_list_viewport.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/messages/message_reactions_bar.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/pickers/expression_picker.dart';
import 'package:fluxer_app/features/chat/providers/channel/channel_message_permissions_provider.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_read_viewport_provider.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/chat/providers/core/message_pagination_coordinator.dart';
import 'package:fluxer_app/features/chat/providers/guild/guild_composer_access_provider.dart';
import 'package:fluxer_app/features/chat/providers/messages/message_length_limits_provider.dart';
import 'package:fluxer_app/features/chat/providers/messages/message_translation_provider.dart';
import 'package:fluxer_app/features/chat/providers/messages/saved_message_provider.dart';
import 'package:fluxer_app/features/chat/providers/pickers/favorite_media_provider.dart';
import 'package:fluxer_app/features/dm/domain/dm_conversation.dart';
import 'package:fluxer_app/features/dm/providers/dm_view_model.dart';
import 'package:fluxer_app/features/emoji/domain/emoji_pins.dart';
import 'package:fluxer_app/features/emoji/providers/emoji_pins_provider.dart';
import 'package:fluxer_app/features/friends/domain/friend.dart';
import 'package:fluxer_app/features/friends/providers/blocked_user_ids_provider.dart';
import 'package:fluxer_app/features/guilds/services/guild_verification.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/providers/persona_blocks_provider.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/features/settings/providers/preferences/appearance_preferences_provider.dart';
import 'package:fluxer_app/features/settings/providers/preferences/chat_preferences_provider.dart';
import 'package:fluxer_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:fluxer_app/features/shell/providers/drawer/reveal_side_provider.dart';
import 'package:fluxer_app/features/shell/providers/layout/shell_popup_overlay_provider.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/services/guild_member_hydration_service.dart';
import 'package:fluxer_app/shared/utils/emoji/emoji_registry.dart';
import 'package:fluxer_dart/export.dart' hide ChannelType;
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../helpers/fork_message_gap_harness.dart';
import '../../../../../helpers/fork_no_personas.dart';
import '../../../../../helpers/input_modality_override.dart';
import '../../../../../helpers/instance_runtime_config_override.dart';
import '../../../../../helpers/message_list_unread_ack_test_helpers.dart';
import '../../../../../helpers/noop_guild_member_hydration_service.dart';
import '../../../../../helpers/open_test_database.dart';
import '../../../../../helpers/test_l10n.dart';

class _StormReactionServer extends GapServer {
  bool holdNextMessageGet = false;
  bool holdNextReactionPut = false;
  int? failNextReactionPutStatus;
  Completer<void>? _getReleaseCompleter;
  Completer<void>? _putReleaseCompleter;

  bool get messageGetHeld => _getReleaseCompleter != null;

  void releaseMessageGet() {
    holdNextMessageGet = false;
    final Completer<void>? release = _getReleaseCompleter;
    _getReleaseCompleter = null;
    if (release != null && !release.isCompleted) {
      release.complete();
    }
  }

  void releaseReactionPut() {
    holdNextReactionPut = false;
    final Completer<void>? release = _putReleaseCompleter;
    _putReleaseCompleter = null;
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
    final RegExpMatch? reactionMatch = RegExp(
      r'/channels/([^/]+)/messages/([^/]+)/reactions/([^/]+)/@me$',
    ).firstMatch(path);
    if (reactionMatch != null &&
        (options.method == 'PUT' || options.method == 'DELETE')) {
      final String messageId = reactionMatch.group(2)!;
      final String emojiName = Uri.decodeComponent(reactionMatch.group(3)!);
      String? personaId = options.uri.queryParameters['persona_id'];
      if (personaId == null && options.method == 'PUT') {
        final Object? data = options.data;
        if (data is Map && data['persona_id'] is String) {
          personaId = data['persona_id'] as String;
        } else if (requestStream != null) {
          final String raw = utf8.decode(
            await requestStream.expand((Uint8List c) => c).toList(),
          );
          if (raw.isNotEmpty) {
            final Object? decoded = jsonDecode(raw);
            if (decoded is Map && decoded['persona_id'] is String) {
              personaId = decoded['persona_id'] as String;
            }
          }
        }
      }
      final int idx = historyIds.indexOf(messageId);
      final String verb = options.method == 'PUT'
          ? 'putReaction'
          : 'deleteReaction';
      requests.add(
        '$verb #$idx${personaId == null ? '' : ' persona=$personaId'}',
      );
      if (options.method == 'PUT' && holdNextReactionPut) {
        holdNextReactionPut = false;
        await (_putReleaseCompleter ??= Completer<void>()).future;
      }
      final int? failStatus = options.method == 'PUT'
          ? failNextReactionPutStatus
          : null;
      if (failStatus != null) {
        failNextReactionPutStatus = null;
        return ResponseBody.fromString(
          '{"message":"Rate limited"}',
          failStatus,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>[Headers.jsonContentType],
          },
        );
      }
      _mutateReactionOnServer(
        messageId: messageId,
        emojiName: emojiName,
        personaId: personaId,
        isAdd: options.method == 'PUT',
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
      await (_getReleaseCompleter ??= Completer<void>()).future;
      return snapshot;
    }

    return await super.fetch(options, requestStream, cancelFuture);
  }

  void _mutateReactionOnServer({
    required String messageId,
    required String emojiName,
    required String? personaId,
    required bool isAdd,
  }) {
    final int index = historyIds.indexOf(messageId);
    if (index == -1) {
      return;
    }
    final List<Map<String, Object?>> current = <Map<String, Object?>>[
      for (final Object? entry
          in (history[index]['reactions'] as List<Object?>? ??
              const <Object?>[]))
        if (entry is Map<String, Object?>) entry,
    ];
    final int existingIdx = current.indexWhere(
      (Map<String, Object?> r) =>
          (r['emoji'] as Map<String, Object?>?)?['name'] == emojiName,
    );
    final bool isRoot = personaId == null || personaId == '0';

    bool meRoot =
        existingIdx != -1 && (current[existingIdx]['me_root'] == true);
    final Set<String> personas = <String>{
      if (existingIdx != -1)
        for (final Object? p
            in (current[existingIdx]['persona_reactions'] as List<Object?>? ??
                const <Object?>[]))
          if (p is Map<String, Object?> && p['persona_id'] is String)
            p['persona_id']! as String,
    };

    if (isAdd) {
      if (isRoot) {
        meRoot = true;
      } else {
        personas.add(personaId);
      }
    } else {
      if (isRoot) {
        meRoot = false;
      } else {
        personas.remove(personaId);
      }
    }

    final int nextCount = (meRoot ? 1 : 0) + personas.length;
    if (nextCount <= 0) {
      if (existingIdx != -1) {
        current.removeAt(existingIdx);
      }
    } else {
      final Map<String, Object?> updated = <String, Object?>{
        'emoji': <String, Object?>{
          'id': null,
          'name': emojiName,
          'animated': false,
        },
        'count': nextCount,
        'me': true,
        'me_root': meRoot,
        'persona_reactions': <Map<String, Object?>>[
          for (final String pid in personas)
            <String, Object?>{'persona_id': pid, 'count': 1, 'me': true},
        ],
      };
      if (existingIdx == -1) {
        current.add(updated);
      } else {
        current[existingIdx] = updated;
      }
    }
    history[index] = <String, Object?>{...history[index], 'reactions': current};
  }
}

class _IdleAppStartup extends AppStartup {
  @override
  Future<void> build() => Future<void>.value();
}

class _EmptyEmojiPins extends EmojiPinsNotifier {
  @override
  Future<EmojiPins> build() async => EmojiPins.empty;
}

class _NoBlockedPersonas extends PersonaBlocksNotifier {
  @override
  Set<String> build() => const <String>{};
}

class _SeededPersonas extends MyPersonasNotifier {
  _SeededPersonas(this._personas);

  final List<Persona> _personas;

  @override
  AsyncValue<List<Persona>> build() => AsyncData<List<Persona>>(_personas);

  @override
  Future<void> reloadSilently() async {}
}

class _LatchedPersona extends ActivePersonaNotifier {
  _LatchedPersona(this._personaId);

  final String _personaId;

  @override
  ActivePersonaState build() =>
      ActivePersonaState(activePersonaId: _personaId, isLatched: true);
}

class _StormRevealSide extends CurrentRevealSide {
  @override
  RevealSide build() => RevealSide.main;
}

class _StormDeepLinkHandler extends DeepLinkHandler {
  @override
  void build() {}
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

class _MutableChannelRoute extends ConsumerWidget {
  const _MutableChannelRoute({
    required this.routeNotifier,
    required this.keyboardHeight,
  });

  final ValueNotifier<({String channelId, String? targetMessageId})>
  routeNotifier;
  final ValueNotifier<double> keyboardHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<
      ({String channelId, String? targetMessageId})
    >(
      valueListenable: routeNotifier,
      builder:
          (
            BuildContext context,
            ({String channelId, String? targetMessageId}) route,
            Widget? _,
          ) {
            return Column(
              children: <Widget>[
                Expanded(
                  child: ChannelChatContent(
                    channelId: route.channelId,
                    targetMessageId: route.targetMessageId,
                    showTopBar: false,
                  ),
                ),
                ValueListenableBuilder<double>(
                  valueListenable: keyboardHeight,
                  builder: (BuildContext context, double height, Widget? _) =>
                      SizedBox(height: height),
                ),
              ],
            );
          },
    );
  }
}

Future<void> _settle(WidgetTester tester, {int rounds = 30}) async {
  for (int i = 0; i < rounds; i++) {
    await tester.pump(const Duration(milliseconds: 25));
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
  Directory? tempDir;

  setUpAll(() async {
    await EmojiRegistry.preload();
    tempDir = await Directory.systemTemp.createTemp('storm_reaction_test');
    const MethodChannel pathChannel = MethodChannel(
      'plugins.flutter.io/path_provider',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (MethodCall call) async {
          if (call.method == 'getTemporaryDirectory') {
            return tempDir?.path;
          }
          return null;
        });
  });

  tearDownAll(() async {
    const MethodChannel pathChannel = MethodChannel(
      'plugins.flutter.io/path_provider',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, null);
    await tempDir?.delete(recursive: true);
  });

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
      _StormReactionServer server,
      db.FluxerDatabase database,
      ValueNotifier<({String channelId, String? targetMessageId})>
      routeNotifier,
      ValueNotifier<double> keyboardHeight,
      ValueNotifier<String?> activeChannelNotifier,
    })
  >
  mountStormApp(
    WidgetTester tester, {
    required String initialChannelId,
    String? initialTargetMessageId,
    double initialKeyboardHeight = 0,
    List<Persona> personas = const <Persona>[],
    String? latchedPersonaId,
    void Function(_StormReactionServer server)? configureServer,
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const List<MethodChannel> silentChannels = <MethodChannel>[
      recorderChannel,
      MethodChannel('dexterous.com/flutter/local_notifications'),
      MethodChannel('fluxer_app/android_notifications'),
    ];
    for (final MethodChannel ch in silentChannels) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ch, (_) async => null);
    }
    addTearDown(() {
      for (final MethodChannel ch in silentChannels) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(ch, null);
      }
    });
    debugSetFluxerRuntimeMobileFormFactor(value: true);
    addTearDown(() => debugSetFluxerRuntimeMobileFormFactor(value: null));

    tester.view.physicalSize = const Size(420, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db.FluxerDatabase database = openTestDatabase();
    final _StormReactionServer server = _StormReactionServer();
    configureServer?.call(server);
    await tester.runAsync(() => seedGapChannels(database));

    final ValueNotifier<({String channelId, String? targetMessageId})>
    routeNotifier =
        ValueNotifier<({String channelId, String? targetMessageId})>((
          channelId: initialChannelId,
          targetMessageId: initialTargetMessageId,
        ));
    addTearDown(routeNotifier.dispose);
    final ValueNotifier<double> keyboardHeight = ValueNotifier<double>(
      initialKeyboardHeight,
    );
    addTearDown(keyboardHeight.dispose);
    final ValueNotifier<String?> activeChannelNotifier = ValueNotifier<String?>(
      initialChannelId,
    );
    addTearDown(activeChannelNotifier.dispose);

    final GoRouter stormRouter = GoRouter(
      initialLocation: '/channels/guild-1/$initialChannelId',
      routes: <RouteBase>[
        GoRoute(
          path: '/channels/:scope/:channelId/:messageId',
          builder: (_, _) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/channels/:scope/:channelId',
          builder: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
    addTearDown(stormRouter.dispose);

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
        fluxerRouterProvider.overrideWithValue(stormRouter),
        deepLinkHandlerProvider.overrideWith(_StormDeepLinkHandler.new),
        currentUserIdProvider.overrideWithValue('me'),
        activeChannelIdProvider.overrideWith((ref) {
          void listener() => ref.invalidateSelf();
          activeChannelNotifier.addListener(listener);
          ref.onDispose(() => activeChannelNotifier.removeListener(listener));
          return activeChannelNotifier.value;
        }),
        currentRevealSideProvider.overrideWith(_StormRevealSide.new),
        wellKnownProvider.overrideWith(_FakeWellKnown.new),
        maxMessageLengthProvider.overrideWithValue(2000),
        myPersonasProvider.overrideWith(
          personas.isEmpty
              ? ForkNoPersonas.new
              : () => _SeededPersonas(personas),
        ),
        if (latchedPersonaId != null)
          activePersonaProvider.overrideWith(
            () => _LatchedPersona(latchedPersonaId),
          ),
        blockedPersonaKeysProvider.overrideWith(_NoBlockedPersonas.new),
        emojiPinsProvider.overrideWith(_EmptyEmojiPins.new),
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
          ChannelListState(
            guild: null,
            categories: const <ChannelCategory>[],
            selectedChannelId: initialChannelId,
          ),
        ),
        guildComposerAccessProvider(
          kGapChannelId,
        ).overrideWithValue(const AsyncData(GuildComposerAccess.allowed)),
        guildComposerAccessProvider(
          kGapOtherChannelId,
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
        channelMessagePermissionsProvider(
          kGapOtherChannelId,
        ).overrideWith((ref) => ChannelMessagePermissions.all),
        messageListReadStateProvider(
          kGapChannelId,
        ).overrideWith((ref) => messageListUnreadAckStream()),
        messageListReadStateProvider(
          kGapOtherChannelId,
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
        for (final int idx in const <int>[20, 80, 95, 98, 99])
          isMessageSavedProvider(
            gapHistoryId(idx),
          ).overrideWith((ref) => Stream<bool>.value(false)),
        favoriteMemesProvider.overrideWith(
          (ref) => Stream<List<FavoriteMeme>>.value(const <FavoriteMeme>[]),
        ),
        messageTranslationAvailableProvider.overrideWith(
          (ref) => Future<bool>.value(false),
        ),
      ],
    );
    void syncRouterToStormRoute() {
      final List<String> segments =
          stormRouter.routeInformationProvider.value.uri.pathSegments;
      if (segments.length >= 3 && segments.first == 'channels') {
        final String channelId = segments[2];
        final String? messageId = segments.length >= 4 ? segments[3] : null;
        activeChannelNotifier.value = channelId;
        container
            .read(chatReadViewportProvider.notifier)
            .setActiveChannel(channelId);
        routeNotifier.value = (
          channelId: channelId,
          targetMessageId: messageId,
        );
      }
    }

    stormRouter.routeInformationProvider.addListener(syncRouterToStormRoute);
    addTearDown(
      () => stormRouter.routeInformationProvider.removeListener(
        syncRouterToStormRoute,
      ),
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
    container
        .read(chatReadViewportProvider.notifier)
        .setActiveChannel(initialChannelId);

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
            body: _MutableChannelRoute(
              routeNotifier: routeNotifier,
              keyboardHeight: keyboardHeight,
            ),
          ),
        ),
      ),
    );

    await _settle(tester);

    return (
      container: container,
      server: server,
      database: database,
      routeNotifier: routeNotifier,
      keyboardHeight: keyboardHeight,
      activeChannelNotifier: activeChannelNotifier,
    );
  }

  testWidgets(
    'Storm 1: push jump to recent message (#98) + READY recovery while sheet '
    'is open glues tail without breaking quick reaction or duplicating GETs',
    (WidgetTester tester) async {
      // Give #99 ~15 lines so that at #98's @0.50 anchor in the full-screen
      // viewport, 0 < maxScrollExtent <= 48 px: MessageList stays anchored at
      // @0.50 (!_parkedAtLiveTail) AND nearLoadedTail is true, so READY runs
      // loadLatestTail + onApplied: scrollToBottom (_schedulePinnedTailGlue)
      // while the sheet is open.
      final String targetId = gapHistoryId(98);
      final setup = await mountStormApp(
        tester,
        initialChannelId: kGapChannelId,
        initialTargetMessageId: targetId,
        configureServer: (_StormReactionServer server) {
          server.history[99] = <String, Object?>{
            ...server.history[99],
            'content': List<String>.generate(
              15,
              (int i) => 'recent tail line $i',
            ).join('\n'),
          };
        },
      );

      final Finder targetTile = find.byKey(ValueKey<String>('msg-$targetId'));
      expect(targetTile, findsOneWidget);

      await tester.longPress(targetTile);
      await _settle(tester);
      expect(find.byType(MessageQuickReactionRow), findsOneWidget);

      final int requestsBeforeReady = setup.server.requests.length;

      // Gateway READY arrives while the action sheet is open (zero keyboard!).
      setup.container.read(gatewayFullRecoveryProvider.notifier).bump();
      await _settle(tester);

      expect(
        setup.server.requests.skip(requestsBeforeReady),
        contains('latest'),
        reason: 'READY near loaded tail triggers direct latest resync',
      );
      expect(find.byType(MessageQuickReactionRow), findsOneWidget);

      setup.server.holdNextReactionPut = true;
      setup.server.holdNextMessageGet = true;

      final Finder firstQuickButton = find
          .ancestor(
            of: find.byType(QuickReactionGlyph).first,
            matching: find.byType(GestureDetector),
          )
          .first;
      await tester.tap(firstQuickButton);
      await _settle(tester);
      expect(setup.container.read(shellHasPopupOverlayProvider), isFalse);

      setup.server.releaseReactionPut();
      await _settle(tester);
      if (setup.server.messageGetHeld) {
        setup.server.releaseMessageGet();
        await _settle(tester);
      }

      expect(tester.takeException(), isNull);
      final List<String> stormRequests = setup.server.requests
          .skip(requestsBeforeReady)
          .toList();
      expect(stormRequests, contains('putReaction #98'));
      expect(
        stormRequests.length,
        lessThanOrEqualTo(2),
        reason:
            'READY + quick reaction must send at most 1 latest resync + 1 PUT: '
            '$stormRequests',
      );

      final Message finalMessage = setup.container
          .read(chatViewModelProvider)
          .messages
          .firstWhere((Message m) => m.id == targetId);
      expect(
        finalMessage.reactions.where((Reaction r) => r.hasReacted),
        isNotEmpty,
      );
      expect(
        find.descendant(
          of: find.byKey(ValueKey<String>('msg-$targetId')),
          matching: find.byType(MessageReactionsBar),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Storm 2: push jump to recent link message (#98) with IME open -> IME hide '
    '+ READY recovery unmounts row while sheet is open and still copies URL',
    (WidgetTester tester) async {
      String? copiedText;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (
            MethodCall call,
          ) async {
            if (call.method == 'Clipboard.setData') {
              final Map<dynamic, dynamic> args =
                  call.arguments as Map<dynamic, dynamic>;
              copiedText = args['text'] as String?;
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );

      const String url = 'https://tyne.chat/storm';
      final String targetId = gapHistoryId(98);
      final setup = await mountStormApp(
        tester,
        initialChannelId: kGapChannelId,
        initialTargetMessageId: targetId,
        initialKeyboardHeight: 260,
        configureServer: (_StormReactionServer server) {
          server.history[98] = <String, Object?>{
            ...server.history[98],
            'content': url,
          };
          server.history[99] = <String, Object?>{
            ...server.history[99],
            'content': List<String>.generate(
              10,
              (int i) => 'recent tail line $i',
            ).join('\n'),
          };
        },
      );

      final Finder targetTile = find.byKey(ValueKey<String>('msg-$targetId'));
      final Element originalTileElement = tester.element(targetTile);
      final int epochBeforeStorm = tester
          .widget<MessageListViewport>(find.byType(MessageListViewport))
          .anchorEpoch;
      final Finder linkText = find.descendant(
        of: targetTile,
        matching: find.textContaining(url, findRichText: true),
      );
      await tester.longPressAt(
        tester.getTopLeft(linkText) + const Offset(12, 8),
      );
      await _settle(tester);
      expect(find.text(testL10n.chatMessageCopyLink), findsOneWidget);

      // Simultaneous IME hide + READY bump unmounts the row behind the sheet!
      setup.keyboardHeight.value = 0;
      setup.container.read(gatewayFullRecoveryProvider.notifier).bump();
      await _settle(tester);
      expect(
        tester
            .widget<MessageListViewport>(find.byType(MessageListViewport))
            .anchorEpoch,
        greaterThan(epochBeforeStorm),
      );
      expect(originalTileElement.mounted, isFalse);

      await tester.tap(find.text(testL10n.chatMessageCopyLink));
      await _settle(tester);

      expect(tester.takeException(), isNull);
      expect(copiedText, url);
    },
  );

  testWidgets(
    'Storm 3: cross-channel push jump with IME open -> simultaneous IME hide + '
    'READY bump + stale GET race keeps quick reaction and closes sheet',
    (WidgetTester tester) async {
      final String targetId = gapHistoryId(98);
      final setup = await mountStormApp(
        tester,
        initialChannelId: kGapOtherChannelId,
        initialKeyboardHeight: 260,
        configureServer: (_StormReactionServer server) {
          server.history[99] = <String, Object?>{
            ...server.history[99],
            'content': List<String>.generate(
              10,
              (int i) => 'tail line $i',
            ).join('\n'),
          };
        },
      );

      // Simulate tapping a push notification for another channel while typing.
      setup.activeChannelNotifier.value = kGapChannelId;
      setup.container
          .read(chatReadViewportProvider.notifier)
          .setActiveChannel(kGapChannelId);
      setup.routeNotifier.value = (
        channelId: kGapChannelId,
        targetMessageId: targetId,
      );
      await _settle(tester);

      final Finder targetTile = find.byKey(ValueKey<String>('msg-$targetId'));
      expect(targetTile, findsOneWidget);
      final Element originalTileElement = tester.element(targetTile);

      await tester.longPress(targetTile);
      await _settle(tester);
      expect(find.byType(MessageQuickReactionRow), findsOneWidget);

      final int requestsBeforeStorm = setup.server.requests.length;

      // Simultaneous IME hide (HIDE_SOFT_INPUT) + gateway READY recovery!
      setup.keyboardHeight.value = 0;
      setup.container.read(gatewayFullRecoveryProvider.notifier).bump();
      await _settle(tester);

      expect(originalTileElement.mounted, isFalse);
      expect(find.byType(MessageQuickReactionRow), findsOneWidget);

      setup.server.holdNextReactionPut = true;
      setup.server.holdNextMessageGet = true;

      await tester.tap(
        find
            .ancestor(
              of: find.byType(QuickReactionGlyph).first,
              matching: find.byType(GestureDetector),
            )
            .first,
      );
      await _settle(tester);
      expect(setup.container.read(shellHasPopupOverlayProvider), isFalse);

      setup.server.releaseReactionPut();
      await _settle(tester);
      if (setup.server.messageGetHeld) {
        setup.server.releaseMessageGet();
        await _settle(tester);
      }

      expect(tester.takeException(), isNull);
      final List<String> stormRequests = setup.server.requests
          .skip(requestsBeforeStorm)
          .toList();
      expect(stormRequests, contains('putReaction #98'));
      expect(stormRequests.length, lessThanOrEqualTo(2));

      final db.Message? dbRow = await setup.database.messageDao.getMessage(
        kGapChannelId,
        targetId,
      );
      final List<dynamic> dbReactions =
          jsonDecode(dbRow!.reactionsJson) as List<dynamic>;
      expect(dbReactions, isNotEmpty);
    },
  );

  testWidgets(
    'Storm 4: in-place jump to detached older history (#20) + Add Reaction '
    'picker across READY recovery preserves detached window and reaction',
    (WidgetTester tester) async {
      final String targetId = gapHistoryId(20);
      final setup = await mountStormApp(
        tester,
        initialChannelId: kGapChannelId,
      );
      expect(
        setup.container.read(chatViewModelProvider).hasMoreNewerMessages,
        isFalse,
      );

      // Jump in-place to #20 (detached window, 80 messages behind tail).
      setup.routeNotifier.value = (
        channelId: kGapChannelId,
        targetMessageId: targetId,
      );
      await _settle(tester);
      expect(
        setup.container.read(chatViewModelProvider).hasMoreNewerMessages,
        isTrue,
      );

      final Finder targetTile = find.byKey(ValueKey<String>('msg-$targetId'));
      expect(targetTile, findsOneWidget);
      await tester.longPress(targetTile);
      await _settle(tester);

      final int requestsBeforeStorm = setup.server.requests.length;

      // Tap "+" Add Reaction button in QuickReactionRow while READY bumps right as the sheet hands off!
      await tester.tap(
        find
            .descendant(
              of: find.byType(QuickReactionRow),
              matching: find.byType(GestureDetector),
            )
            .last,
      );
      setup.container.read(gatewayFullRecoveryProvider.notifier).bump();
      await _settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(ExpressionPicker), findsOneWidget);
      expect(
        setup.container.read(chatViewModelProvider).hasMoreNewerMessages,
        isTrue,
        reason:
            'READY reconcile on a detached window must not yank back to latest',
      );

      // Dismiss picker and react via long-press sheet, then bump READY
      // once more to verify reconcile preserves the reaction on #20.
      Navigator.of(tester.element(find.byType(ExpressionPicker))).pop();
      await _settle(tester);

      await tester.longPress(find.byKey(ValueKey<String>('msg-$targetId')));
      await _settle(tester);
      await tester.tap(
        find
            .ancestor(
              of: find.byType(QuickReactionGlyph).first,
              matching: find.byType(GestureDetector),
            )
            .first,
      );
      setup.container.read(gatewayFullRecoveryProvider.notifier).bump();
      await _settle(tester);

      expect(tester.takeException(), isNull);
      final List<String> stormRequests = setup.server.requests
          .skip(requestsBeforeStorm)
          .toList();
      expect(stormRequests, contains('putReaction #20'));
      expect(
        stormRequests.length,
        lessThanOrEqualTo(6),
        reason: 'Detached READY reconcile must stay bounded: $stormRequests',
      );

      final Message finalMessage = setup.container
          .read(chatViewModelProvider)
          .messages
          .firstWhere((Message m) => m.id == targetId);
      expect(
        finalMessage.reactions.where((Reaction r) => r.hasReacted),
        isNotEmpty,
      );
    },
  );

  testWidgets(
    'Storm 5: multi-persona jump + long-press quick reaction -> Emoji Info -> '
    'React as… and reaction-chip Your reactions across IME hide + READY bumps',
    (WidgetTester tester) async {
      final String targetId = gapHistoryId(98);
      final setup = await mountStormApp(
        tester,
        initialChannelId: kGapChannelId,
        initialTargetMessageId: targetId,
        initialKeyboardHeight: 260,
        personas: const <Persona>[
          Persona(id: 'p-alice', name: 'Alice'),
          Persona(id: 'p-bob', name: 'Bob'),
        ],
        configureServer: (_StormReactionServer server) {
          server.history[99] = <String, Object?>{
            ...server.history[99],
            'content': List<String>.generate(
              15,
              (int i) => 'tail line $i',
            ).join('\n'),
          };
        },
      );

      final Finder targetTile = find.byKey(ValueKey<String>('msg-$targetId'));
      await tester.longPress(targetTile);
      await _settle(tester);

      // Long-press the first quick reaction -> opens EmojiInfoBottomSheet.
      await tester.longPress(
        find
            .ancestor(
              of: find.byType(QuickReactionGlyph).first,
              matching: find.byType(GestureDetector),
            )
            .first,
      );
      await _settle(tester);
      expect(find.text(testL10n.fork.chatReactAs), findsOneWidget);

      // Hide IME + bump READY while transitioning to PersonaReactAsSheet!
      setup.keyboardHeight.value = 0;
      setup.container.read(gatewayFullRecoveryProvider.notifier).bump();
      await tester.tap(find.text(testL10n.fork.chatReactAs));
      await _settle(tester);

      expect(find.byType(PersonaReactionSheetBody), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('persona-reaction-row-p-alice')),
      );
      await _settle(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('persona-reaction-row-account')),
      );
      await _settle(tester);

      Navigator.of(tester.element(find.byType(PersonaReactionSheetBody))).pop();
      await _settle(tester);

      // Tap the rendered reaction chip on #98 -> opens "Your reactions" sheet
      // while another READY bumps!
      final Finder chipBar = find.descendant(
        of: find.byKey(ValueKey<String>('msg-$targetId')),
        matching: find.byType(MessageReactionsBar),
      );
      expect(chipBar, findsOneWidget);
      await tester.tap(find.descendant(of: chipBar, matching: find.text('2')));
      setup.container.read(gatewayFullRecoveryProvider.notifier).bump();
      await _settle(tester);

      expect(find.byType(PersonaReactionSheetBody), findsOneWidget);
      if (find
          .byKey(const ValueKey<String>('persona-reaction-row-p-bob'))
          .evaluate()
          .isEmpty) {
        await tester.tap(find.text(testL10n.fork.personaReactionsSomeoneElse));
        await _settle(tester);
      }
      await tester.tap(
        find.byKey(const ValueKey<String>('persona-reaction-row-p-bob')),
      );
      await _settle(tester);

      Navigator.of(tester.element(find.byType(PersonaReactionSheetBody))).pop();
      await _settle(tester);

      expect(tester.takeException(), isNull);
      final Reaction reaction = setup.container
          .read(chatViewModelProvider)
          .messages
          .firstWhere((Message m) => m.id == targetId)
          .reactions
          .single;
      expect(reaction.meRoot, isTrue);
      expect(
        reaction.personaReactions,
        containsAll(<String>['p-alice', 'p-bob']),
      );
    },
  );

  testWidgets(
    'Storm 6: push jump + double-tap reaction and chip toggle-off concurrent '
    'with READY recovery',
    (WidgetTester tester) async {
      final String targetId = gapHistoryId(98);
      final setup = await mountStormApp(
        tester,
        initialChannelId: kGapChannelId,
        initialTargetMessageId: targetId,
      );

      final int requestsBeforeDoubleTap = setup.server.requests.length;
      final Finder targetTile = find.byKey(ValueKey<String>('msg-$targetId'));

      // Double-tap the jumped message row while READY bumps concurrently.
      await tester.tap(targetTile);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(targetTile);
      setup.container.read(gatewayFullRecoveryProvider.notifier).bump();
      await _settle(tester);

      expect(tester.takeException(), isNull);
      expect(
        setup.server.requests.skip(requestsBeforeDoubleTap),
        contains('putReaction #98'),
      );
      final Finder chipBar = find.descendant(
        of: find.byKey(ValueKey<String>('msg-$targetId')),
        matching: find.byType(MessageReactionsBar),
      );
      expect(chipBar, findsOneWidget);

      // Tap the reaction chip to toggle it off while READY bumps again.
      final int requestsBeforeRemove = setup.server.requests.length;
      await tester.tap(find.descendant(of: chipBar, matching: find.text('1')));
      setup.container.read(gatewayFullRecoveryProvider.notifier).bump();
      await _settle(tester);

      expect(tester.takeException(), isNull);
      expect(
        setup.server.requests.skip(requestsBeforeRemove),
        contains('deleteReaction #98 persona=0'),
      );
      expect(
        setup.container
            .read(chatViewModelProvider)
            .messages
            .firstWhere((Message m) => m.id == targetId)
            .reactions,
        isEmpty,
      );
    },
  );

  testWidgets(
    'Storm 7: raw OS push JSON payload queued before shell ready -> flushed '
    'on READY through DeepLinkHandler + GoRouter -> cross-channel jump + '
    'quick reaction across IME hide',
    (WidgetTester tester) async {
      final String targetId = gapHistoryId(98);
      final setup = await mountStormApp(
        tester,
        initialChannelId: kGapOtherChannelId,
        initialKeyboardHeight: 260,
        configureServer: (_StormReactionServer server) {
          server.history[99] = <String, Object?>{
            ...server.history[99],
            'content': List<String>.generate(
              10,
              (int i) => 'tail line $i',
            ).join('\n'),
          };
        },
      );

      // Simulate cold/background state before gateway READY completes.
      setup.container
          .read(authStateProvider.notifier)
          .setAuthenticated(value: true);
      setup.container.read(gatewayReadyProvider.notifier).reset();
      setup.container
          .read(gatewayConnectionFailedProvider.notifier)
          .setFailed(value: false);

      // Keep PendingPushNotificationPath listener alive, then deliver a real
      // OS notification tap JSON payload while shellDataReady is still false.
      final ProviderSubscription<Object?> pendingSub = setup.container.listen(
        pendingPushNotificationPathProvider,
        (_, _) {},
      );
      addTearDown(pendingSub.close);

      setup.container
          .read(pushNotificationTapHandlerProvider.notifier)
          .handlePayloadJson(
            jsonEncode(<String, String>{
              'guild_id': 'guild-1',
              'channel_id': kGapChannelId,
              'message_id': targetId,
            }),
          );
      await _settle(tester, rounds: 6);

      expect(
        setup.container.read(pendingPushNotificationPathProvider)?.path,
        '/channels/guild-1/$kGapChannelId/$targetId',
        reason: 'Push path must stay queued until shellDataReady + splash exit',
      );
      expect(setup.routeNotifier.value.channelId, kGapOtherChannelId);

      // Gateway READY arrives and splash exit is allowed -> PendingNavigation
      // flushes through DeepLinkHandler -> navigateToChannelJumpLinkVia ->
      // GoRouter -> ChannelChatContent jump to #98!
      setup.container.read(splashExitAllowedProvider.notifier).allow();
      setup.container.read(gatewayReadyProvider.notifier).setReady();
      setup.container.read(gatewaySessionRecoveryProvider.notifier).bump();
      setup.container.read(gatewayFullRecoveryProvider.notifier).bump();
      await _settle(tester);

      expect(setup.container.read(pendingPushNotificationPathProvider), isNull);
      expect(setup.routeNotifier.value.channelId, kGapChannelId);
      final Finder targetTile = find.byKey(ValueKey<String>('msg-$targetId'));
      expect(targetTile, findsOneWidget);
      final Element originalTileElement = tester.element(targetTile);

      await tester.longPress(targetTile);
      await _settle(tester);
      expect(find.byType(MessageQuickReactionRow), findsOneWidget);

      final int requestsBeforeReaction = setup.server.requests.length;

      // Hide IME while sheet is open -> _anchorEpoch++ unmounts original row.
      setup.keyboardHeight.value = 0;
      await _settle(tester);
      expect(originalTileElement.mounted, isFalse);

      await tester.tap(
        find
            .ancestor(
              of: find.byType(QuickReactionGlyph).first,
              matching: find.byType(GestureDetector),
            )
            .first,
      );
      await _settle(tester);

      expect(tester.takeException(), isNull);
      expect(setup.container.read(shellHasPopupOverlayProvider), isFalse);
      final List<String> reactionRequests = setup.server.requests
          .skip(requestsBeforeReaction)
          .toList();
      expect(reactionRequests, <String>['putReaction #98']);
    },
  );

  testWidgets(
    'Storm 8: active persona + push jump + IME-hide row unmount rolls back '
    'optimistic persona reaction cleanly on 429 without retrying or wedging',
    (WidgetTester tester) async {
      final String targetId = gapHistoryId(98);
      final setup = await mountStormApp(
        tester,
        initialChannelId: kGapChannelId,
        initialTargetMessageId: targetId,
        initialKeyboardHeight: 260,
        personas: const <Persona>[Persona(id: 'p-storm', name: 'Stormy')],
        latchedPersonaId: 'p-storm',
        configureServer: (_StormReactionServer server) {
          server.history[99] = <String, Object?>{
            ...server.history[99],
            'content': List<String>.generate(
              10,
              (int i) => 'tail line $i',
            ).join('\n'),
          };
        },
      );

      final Finder targetTile = find.byKey(ValueKey<String>('msg-$targetId'));
      final Element originalTileElement = tester.element(targetTile);
      await tester.longPress(targetTile);
      await _settle(tester);

      setup.keyboardHeight.value = 0;
      await _settle(tester);
      expect(originalTileElement.mounted, isFalse);

      final int requestsBeforeTap = setup.server.requests.length;
      setup.server.failNextReactionPutStatus = 429;

      await tester.tap(
        find
            .ancestor(
              of: find.byType(QuickReactionGlyph).first,
              matching: find.byType(GestureDetector),
            )
            .first,
      );
      await _settle(tester);

      expect(tester.takeException(), isNull);
      expect(setup.container.read(shellHasPopupOverlayProvider), isFalse);
      final List<String> putAttempts = setup.server.requests
          .skip(requestsBeforeTap)
          .toList();
      expect(putAttempts, <String>[
        'putReaction #98 persona=p-storm',
      ], reason: '429 must send exactly 1 persona PUT with zero retry loop');

      final Message finalMsg = setup.container
          .read(chatViewModelProvider)
          .messages
          .firstWhere((Message m) => m.id == targetId);
      expect(
        finalMsg.reactions,
        isEmpty,
        reason: 'Optimistic persona reaction must roll back on 429',
      );
      final db.Message? dbRow = await setup.database.messageDao.getMessage(
        kGapChannelId,
        targetId,
      );
      expect(jsonDecode(dbRow!.reactionsJson) as List<dynamic>, isEmpty);
    },
  );

  testWidgets(
    'Storm 9: rapid second OS push notification in-place retarget (#80 -> #98) '
    'while MessageBottomSheet on #80 is open + IME hide still reacts on #80',
    (WidgetTester tester) async {
      final String firstId = gapHistoryId(80);
      final String secondId = gapHistoryId(98);
      final setup = await mountStormApp(
        tester,
        initialChannelId: kGapChannelId,
        initialTargetMessageId: firstId,
        initialKeyboardHeight: 260,
        configureServer: (_StormReactionServer server) {
          server.history[99] = <String, Object?>{
            ...server.history[99],
            'content': List<String>.generate(
              10,
              (int i) => 'tail line $i',
            ).join('\n'),
          };
        },
      );

      setup.container
          .read(authStateProvider.notifier)
          .setAuthenticated(value: true);
      setup.container.read(gatewayReadyProvider.notifier).setReady();
      setup.container
          .read(gatewayConnectionFailedProvider.notifier)
          .setFailed(value: false);
      setup.container.read(splashExitAllowedProvider.notifier).allow();

      final Finder firstTile = find.byKey(ValueKey<String>('msg-$firstId'));
      expect(firstTile, findsOneWidget);
      await tester.longPress(firstTile);
      await _settle(tester);
      expect(find.byType(MessageQuickReactionRow), findsOneWidget);

      // While #80's sheet is open, a second push notification arrives for #98
      // in the SAME channel (ChannelJumpInPlace -> goToRepliedMessage) AND
      // the soft keyboard hides!
      setup.keyboardHeight.value = 0;
      setup.container
          .read(pushNotificationTapHandlerProvider.notifier)
          .handlePayloadJson(
            jsonEncode(<String, String>{
              'guild_id': 'guild-1',
              'channel_id': kGapChannelId,
              'message_id': secondId,
            }),
          );
      await _settle(tester);

      final int requestsBeforeTap = setup.server.requests.length;
      await tester.tap(
        find
            .ancestor(
              of: find.byType(QuickReactionGlyph).first,
              matching: find.byType(GestureDetector),
            )
            .first,
      );
      await _settle(tester);

      expect(tester.takeException(), isNull);
      expect(setup.container.read(shellHasPopupOverlayProvider), isFalse);
      final List<String> reactionRequests = setup.server.requests
          .skip(requestsBeforeTap)
          .toList();
      expect(
        reactionRequests,
        <String>['putReaction #80'],
        reason:
            'Quick reaction on #80 sheet must target #80 and never #98: '
            '$reactionRequests',
      );
    },
  );
}
