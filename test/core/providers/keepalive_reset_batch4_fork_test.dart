// Fork: tyne-chat/tyne#946 — regression tests for Group D
// `@Riverpod(keepAlive: true)` providers whose mutable instance fields were not
// reset in `build()`: preference notifiers (ChatWallpaper,
// DefaultAppsPreferences, ChatPreferences, AdvancedPreferences,
// AppearancePreferences, VoiceSettings), ServiceStatusMaintenanceRead,
// StreamerMode, ObservabilityReportingPrompt, and PushRelayConsentPrompt.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/daos/user_preferences_dao.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/local_settings/local_setting_keys.dart';
import 'package:fluxer_app/core/local_settings/local_settings_store_provider.dart';
import 'package:fluxer_app/core/observability/reporting_consent/observability_reporting_prompt_provider.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/providers/instance/well_known_provider.dart';
import 'package:fluxer_app/core/push/relay_consent/push_relay_consent_prompt_provider.dart';
import 'package:fluxer_app/features/chat/providers/chat_wallpaper_provider.dart';
import 'package:fluxer_app/features/chat/wallpaper/chat_wallpaper.dart';
import 'package:fluxer_app/features/settings/domain/default_web_browser.dart';
import 'package:fluxer_app/features/settings/providers/preferences/advanced_preferences_provider.dart';
import 'package:fluxer_app/features/settings/providers/preferences/appearance_preferences_provider.dart';
import 'package:fluxer_app/features/settings/providers/preferences/chat_preferences_provider.dart';
import 'package:fluxer_app/features/settings/providers/preferences/default_apps_preferences_provider.dart';
import 'package:fluxer_app/features/settings/providers/preferences/streamer_mode_provider.dart';
import 'package:fluxer_app/features/settings/providers/preferences/voice_settings_provider.dart';
import 'package:fluxer_app/features/shell/domain/service_status_maintenance.dart';
import 'package:fluxer_app/features/shell/providers/service_status/service_status_maintenance_provider.dart';
import 'package:fluxer_dart/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/open_test_database.dart';

class _ControllableUserPreferencesDao extends Fake
    implements UserPreferencesDao {
  final Map<String, Completer<db.UserPreferencesTableData?>> pending =
      <String, Completer<db.UserPreferencesTableData?>>{};
  final List<db.UserPreferencesTableCompanion> saved =
      <db.UserPreferencesTableCompanion>[];

  @override
  Future<db.UserPreferencesTableData?> getPreferences(String userId) {
    final Completer<db.UserPreferencesTableData?> completer = pending
        .putIfAbsent(userId, Completer<db.UserPreferencesTableData?>.new);
    return completer.future;
  }

  @override
  Future<void> savePreferences(db.UserPreferencesTableCompanion prefs) async {
    saved.add(prefs);
  }
}

class _ControllablePrefsDatabase extends db.FluxerDatabase {
  _ControllablePrefsDatabase(this.dao)
    : super.forTesting(NativeDatabase.memory());

  final _ControllableUserPreferencesDao dao;

  @override
  UserPreferencesDao get userPreferencesDao => dao;
}

class _FixedWellKnown extends WellKnown {
  @override
  Future<WellKnownFluxerResponse> build() async =>
      const WellKnownFluxerResponse(
        apiCodeVersion: 1,
        endpoints: InstanceEndpointsSchema(
          api: 'https://api.example.test',
          apiClient: 'https://api.example.test',
          apiPublic: 'https://api.example.test',
          gateway: 'wss://gw.example.test',
          media: 'https://media.example.test',
          staticCdn: 'https://cdn.example.test',
          marketing: 'https://example.test',
          admin: 'https://admin.example.test',
          invite: 'https://invite.example.test',
          gift: 'https://gift.example.test',
          webapp: 'https://app.example.test',
        ),
        captcha: InstanceCaptchaSchema(provider: CaptchaProviderSchema.none),
        features: InstanceFeaturesSchema(
          voiceEnabled: true,
          stripeEnabled: false,
          premiumEnabled: false,
          stripeServiceable: false,
          selfHosted: false,
          presignedAttachmentUploads: false,
          emailsEnabled: true,
          phoneVerificationEnabled: false,
          accountIdentity: AccountIdentityModeSchema.email,
          tagStyle: TagStyleSchema.random,
        ),
        gif: InstanceGifSchema(
          provider: 'tenor',
          displayName: 'Tenor',
          attributionRequired: false,
        ),
        sso: InstanceSsoSchema(
          enabled: false,
          enforced: false,
          usernameFromProvider: false,
          displayName: null,
          buttonLabel: null,
          redirectUri: 'https://example.test/sso',
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
          gifEnabled: true,
          youtubeEnabled: true,
          blueskyEnabled: false,
        ),
        limits: WellKnownFluxerResponseLimits(
          version: 2,
          traitDefinitions: <String>[],
          defaultsHash: 'test',
          rules: <WellKnownFluxerResponseLimitsRules>[],
        ),
        push: InstancePushSchema(publicVapidKey: null),
        appPublic: InstanceAppPublicSchema(
          branding: InstanceBrandingSchema(
            productName: 'Fluxer',
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
            collectDateOfBirth: true,
          ),
        ),
        agePolicy: InstanceAgePolicySchema(
          geos: <InstanceAgePolicyGeoSchema>[],
        ),
      );
}

class _FakeHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  List<String>? operator [](String name) => name.toLowerCase() == 'content-type'
      ? const <String>['application/json']
      : null;

  @override
  String? value(String name) =>
      name.toLowerCase() == 'content-type' ? 'application/json' : null;

  @override
  void forEach(void Function(String name, List<String> values) action) {
    action('content-type', const <String>['application/json']);
  }
}

class _FakeHttpResponse extends Fake implements HttpClientResponse {
  _FakeHttpResponse(this._bodyBytes);

  final List<int> _bodyBytes;

  @override
  int get statusCode => 200;

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => 'OK';

  @override
  int get contentLength => _bodyBytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  List<RedirectInfo> get redirects => const <RedirectInfo>[];

  @override
  Stream<R> cast<R>() => Stream<List<int>>.value(_bodyBytes).cast<R>();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_bodyBytes).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class _FakeHttpRequest extends Fake implements HttpClientRequest {
  _FakeHttpRequest(this._responseFuture);

  final Future<HttpClientResponse> _responseFuture;

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  int contentLength = 0;

  @override
  bool persistentConnection = false;

  @override
  Future<HttpClientResponse> close() => _responseFuture;
}

class _SequencedStatusHttpClient extends Fake implements HttpClient {
  _SequencedStatusHttpClient(this._responder);

  final Future<HttpClientResponse> Function(int requestIndex) _responder;
  int calls = 0;

  @override
  bool autoUncompress = true;

  @override
  Duration? connectionTimeout;

  @override
  Duration idleTimeout = const Duration(seconds: 3);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    calls++;
    return _FakeHttpRequest(_responder(calls));
  }

  @override
  void close({bool force = false}) {}
}

class _TestStatusHttpOverrides extends HttpOverrides {
  _TestStatusHttpOverrides(this._client);

  final HttpClient _client;

  @override
  HttpClient createHttpClient(SecurityContext? context) => _client;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'preference keepAlive notifiers ignore stale in-flight load() results and VoiceSettings resets _userId on invalidate',
    () async {
      final db.FluxerDatabase seedDb = openTestDatabase();
      await seedDb.userPreferencesDao.savePreferences(
        db.UserPreferencesTableCompanion(
          userId: const Value('user-a'),
          chatWallpaperJson: Value(
            chatWallpaperToJson(
              const ChatWallpaperState(
                kind: ChatWallpaperKind.preset,
                id: 'sunset',
              ),
            ),
          ),
          defaultWebBrowser: Value(DefaultWebBrowser.external.name),
          autoSendKlipyGifs: const Value(false),
          embedMediaDimensionSize: Value(MediaDimensionSize.large.name),
          enableTextSelection: const Value(true),
          showNeko: const Value(true),
        ),
      );
      final db.UserPreferencesTableData? rowA = await seedDb.userPreferencesDao
          .getPreferences('user-a');
      expect(rowA, isNotNull);

      final _ControllableUserPreferencesDao fakeDao =
          _ControllableUserPreferencesDao();
      final _ControllablePrefsDatabase controllableDb =
          _ControllablePrefsDatabase(fakeDao);
      addTearDown(controllableDb.close);
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          fluxerDatabaseProvider.overrideWithValue(controllableDb),
        ],
      );
      addTearDown(container.dispose);
      await container.read(localSettingsStoreProvider).load();

      // Start loads for user-a that hang on getPreferences('user-a').
      final Future<void> fWallpaper = container
          .read(chatWallpaperProvider.notifier)
          .load('user-a');
      final Future<void> fDefaultApps = container
          .read(defaultAppsPreferencesProvider.notifier)
          .load('user-a');
      final Future<void> fChatPrefs = container
          .read(chatPreferencesProvider.notifier)
          .load('user-a');
      final Future<void> fAdvanced = container
          .read(advancedPreferencesProvider.notifier)
          .load('user-a');
      final Future<void> fAppearance = container
          .read(appearancePreferencesProvider.notifier)
          .load('user-a');
      await container.read(voiceSettingsProvider.notifier).load('user-a');

      // Rebuild all 6 providers while loads for user-a are still in flight.
      container
        ..invalidate(chatWallpaperProvider)
        ..invalidate(defaultAppsPreferencesProvider)
        ..invalidate(chatPreferencesProvider)
        ..invalidate(advancedPreferencesProvider)
        ..invalidate(appearancePreferencesProvider)
        ..invalidate(voiceSettingsProvider)
        ..read(chatWallpaperProvider)
        ..read(defaultAppsPreferencesProvider)
        ..read(chatPreferencesProvider)
        ..read(advancedPreferencesProvider)
        ..read(appearancePreferencesProvider)
        ..read(voiceSettingsProvider);

      // Now stale user-a DB query finishes.
      fakeDao.pending['user-a']!.complete(rowA);
      await Future.wait(<Future<void>>[
        fWallpaper,
        fDefaultApps,
        fChatPrefs,
        fAdvanced,
        fAppearance,
      ]);

      expect(container.read(chatWallpaperProvider).selection.id, isNull);
      expect(
        container.read(defaultAppsPreferencesProvider),
        DefaultWebBrowser.inApp,
      );
      expect(container.read(chatPreferencesProvider).autoSendKlipyGifs, isTrue);
      expect(
        container.read(chatPreferencesProvider).embedMediaDimensionSize,
        MediaDimensionSize.small,
      );
      expect(
        container.read(advancedPreferencesProvider).enableTextSelection,
        isFalse,
      );
      expect(container.read(appearancePreferencesProvider).showNeko, isFalse);

      // VoiceSettings after invalidate must not still write to user-a overrides.
      await container
          .read(voiceSettingsProvider.notifier)
          .setInputDeviceId('mic-rebuilt');
      expect(
        container
            .read(localSettingsStoreProvider)
            .readAccount(
              LocalSettingKeys.voiceDeviceOverrides,
              userId: 'user-a',
            ),
        isEmpty,
      );
    },
  );

  test(
    'ServiceStatusMaintenanceRead and StreamerMode reset in-flight/timer state across invalidate',
    () async {
      final Completer<HttpClientResponse> staleSummary =
          Completer<HttpClientResponse>();
      final Map<String, Object?> activeMaintenanceJson = <String, Object?>{
        'page': <String, Object?>{'status': 'OK'},
        'activeIncidents': const <Object?>[],
        'activeMaintenances': <Object?>[
          <String, Object?>{
            'id': 'maint-2',
            'name': 'Database Upgrade',
            'status': 'NOTSTARTEDYET',
            'start': '2030-01-01T00:00:00.000Z',
            'duration': 30,
            'url': 'https://status.example.test/maint-2',
          },
        ],
      };

      final _SequencedStatusHttpClient httpClient = _SequencedStatusHttpClient((
        int requestIndex,
      ) {
        if (requestIndex == 1) {
          return staleSummary.future;
        }
        return Future<HttpClientResponse>.value(
          _FakeHttpResponse(utf8.encode(jsonEncode(activeMaintenanceJson))),
        );
      });

      await HttpOverrides.runZoned(
        () async {
          final db.FluxerDatabase database = openTestDatabase();
          final ProviderContainer container = ProviderContainer(
            overrides: <Override>[
              fluxerDatabaseProvider.overrideWithValue(database),
              wellKnownProvider.overrideWith(_FixedWellKnown.new),
            ],
          );
          addTearDown(container.dispose);
          container.listen(wellKnownProvider, (_, _) {});
          await container.read(localSettingsStoreProvider).load();
          await container.read(wellKnownProvider.future);

          // Kick off initial refresh (hangs on request #1 -> _refreshInFlight = true).
          container.read(serviceStatusMaintenanceReadProvider);
          await Future<void>.delayed(const Duration(milliseconds: 50));
          expect(httpClient.calls, 1);

          // Invalidate while request #1 is in flight and re-read -> request #2 must run now.
          container
            ..invalidate(serviceStatusMaintenanceReadProvider)
            ..read(serviceStatusMaintenanceReadProvider);
          await Future<void>.delayed(const Duration(milliseconds: 50));

          final ServiceStatusMaintenance? current = container.read(
            serviceStatusMaintenanceReadProvider,
          );
          expect(current, isNotNull);
          expect(current!.id, 'maint-2');

          // Completing stale request #1 later must not overwrite fresh maintenance state.
          staleSummary.complete(
            _FakeHttpResponse(
              utf8.encode(jsonEncode(const <String, Object?>{})),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 50));
          expect(
            container.read(serviceStatusMaintenanceReadProvider)?.id,
            'maint-2',
          );

          // Exercise StreamerMode rebuild & disposal reset cleanly.
          container.read(streamerModeProvider);
          await container
              .read(streamerModeProvider.notifier)
              .setAutoEnable(value: false);
          container.invalidate(streamerModeProvider);
          expect(container.read(streamerModeProvider).autoEnable, isFalse);
        },
        createHttpClient: (_) =>
            _TestStatusHttpOverrides(httpClient).createHttpClient(null),
      );
    },
  );

  test(
    'ObservabilityReportingPrompt and PushRelayConsentPrompt reset flight/userId state on invalidate',
    () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      // 1. ObservabilityReportingPrompt resets _presentationInFlight on rebuild.
      final ObservabilityReportingPrompt obs1 = container.read(
        observabilityReportingPromptProvider.notifier,
      )..requestPrompt();
      expect(obs1.beginPresentation(), isTrue);
      expect(obs1.isPresentationInFlight, isTrue);

      container.invalidate(observabilityReportingPromptProvider);
      final ObservabilityReportingPrompt obs2 = container.read(
        observabilityReportingPromptProvider.notifier,
      );
      expect(obs2.isPresentationInFlight, isFalse);
      obs2.requestPrompt();
      expect(container.read(observabilityReportingPromptProvider), isTrue);
      expect(obs2.beginPresentation(), isTrue);

      // 2. PushRelayConsentPrompt clears pending _userIds AND _presentationInFlight on rebuild.
      container
          .read(pushRelayConsentPromptProvider.notifier)
          .requestPrompt(userId: 'stale-user');
      container.invalidate(pushRelayConsentPromptProvider);
      container
          .read(pushRelayConsentPromptProvider.notifier)
          .requestPrompt(userId: 'fresh-user-1');

      final Set<String>? firstBatch = container
          .read(pushRelayConsentPromptProvider.notifier)
          .beginPresentation();
      expect(firstBatch, <String>{'fresh-user-1'});
      expect(
        container
            .read(pushRelayConsentPromptProvider.notifier)
            .isPresentationInFlight,
        isTrue,
      );

      container.invalidate(pushRelayConsentPromptProvider);
      expect(
        container
            .read(pushRelayConsentPromptProvider.notifier)
            .isPresentationInFlight,
        isFalse,
      );
      container
          .read(pushRelayConsentPromptProvider.notifier)
          .requestPrompt(userId: 'fresh-user-2');
      expect(container.read(pushRelayConsentPromptProvider), isTrue);
      expect(
        container
            .read(pushRelayConsentPromptProvider.notifier)
            .beginPresentation(),
        <String>{'fresh-user-2'},
      );
    },
  );
}
