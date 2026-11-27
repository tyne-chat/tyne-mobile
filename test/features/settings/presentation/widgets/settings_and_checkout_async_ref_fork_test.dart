// Fork: tyne-chat/tyne#946 — regression tests for Group D (settings & billing)
// post-await WidgetRef/BuildContext disposal hazards across
// UserOperatorPassSection, UserLanguageAndTime, UserThemeColors,
// UserAccessibilityTtsSection, confirmSwitchToStandardVoiceCall,
// UserNotificationsSettings, cancelPremiumSubscription, and selfServeRefundLatest.

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/build/push_provider_kind.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/push/apns/apns_mobile_device_registration.dart';
import 'package:fluxer_app/core/push/apns/apns_voip_mobile_device_registration.dart';
import 'package:fluxer_app/core/push/delivery/display.dart';
import 'package:fluxer_app/core/push/relay_consent/push_relay_consent_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/synced_preferences/engine/synced_preference_field.dart';
import 'package:fluxer_app/core/synced_preferences/engine/synced_preferences_store.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_mode.dart';
import 'package:fluxer_app/core/theme/providers/theme_preference_provider.dart';
import 'package:fluxer_app/core/theme/theme_color_editor.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/profile/providers/user_settings_status_provider.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/user_accessibility_tts_section.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/user_language_and_time.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/user_notifications_settings.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/user_operator_pass_section.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/user_theme_colors.dart';
import 'package:fluxer_app/features/settings/providers/commerce/operator_pass_settings_provider.dart';
import 'package:fluxer_app/features/settings/providers/commerce/premium_settings_state_provider.dart';
import 'package:fluxer_app/features/settings/providers/commerce/push_delivery_details_provider.dart';
import 'package:fluxer_app/features/settings/providers/preferences/appearance_preferences_provider.dart';
import 'package:fluxer_app/features/settings/providers/preferences/mention_preference_provider.dart';
import 'package:fluxer_app/features/settings/providers/preferences/notification_preferences_provider.dart';
import 'package:fluxer_app/features/settings/providers/preferences/sound_preferences_provider.dart';
import 'package:fluxer_app/features/settings/providers/preferences/time_format_providers.dart';
import 'package:fluxer_app/features/settings/providers/sync/user_settings_sync_service.dart';
import 'package:fluxer_app/features/settings/services/premium_checkout_service.dart';
import 'package:fluxer_app/features/shell/providers/nagbar/push_notification_permission_status_provider.dart';
import 'package:fluxer_app/features/shell/providers/user/current_user_private_provider.dart';
import 'package:fluxer_app/features/ui/toast/toast_provider.dart';
import 'package:fluxer_app/features/ui/voice/voice_channel_control_panel_settings.dart';
import 'package:fluxer_app/features/voice/providers/voice_session_provider.dart';
import 'package:fluxer_app/features/voice/providers/voice_session_state.dart';
import 'package:fluxer_app/features/voice/tts/fluxer_tts_provider.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_dart/export.dart';

import '../../../../helpers/core_test_provider_overrides.dart';
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

class _SuspendingBillingAdapter implements HttpClientAdapter {
  Completer<void>? operatorPassCompleter;
  Completer<void>? cancelPremiumCompleter;
  Completer<void>? refundPremiumCompleter;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final String path = options.uri.path;
    if (path.contains('operator-pass')) {
      await operatorPassCompleter?.future;
      return ResponseBody.fromString(
        jsonEncode(<String, Object?>{'message': 'boom'}),
        500,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      );
    }
    if (path.contains('cancel') || options.method == 'DELETE') {
      await cancelPremiumCompleter?.future;
      return ResponseBody.fromString(
        jsonEncode(<String, Object?>{}),
        204,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      );
    }
    if (path.contains('refund')) {
      await refundPremiumCompleter?.future;
      return ResponseBody.fromString(
        jsonEncode(<String, Object?>{}),
        200,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode(<String, Object?>{}),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _SuspendingTimestampFormatPreference extends TimestampFormatPreference {
  _SuspendingTimestampFormatPreference(this.completer);

  final Completer<void> completer;

  @override
  TimestampFormatTypes build() => TimestampFormatTypes.auto;

  @override
  Future<void> setTimestampFormat(TimestampFormatTypes value) async {
    await completer.future;
  }
}

class _FakeRegionalFormatPreference extends RegionalFormatPreference {
  @override
  String? build() => null;
}

class _NoopUserSettingsSyncService extends UserSettingsSyncService {
  _NoopUserSettingsSyncService(super.ref);

  @override
  Future<void> pushAfkTimeout(int minutes) async {}
}

class _StaticAppearancePreferences extends AppearancePreferences {
  @override
  AppearancePreferencesState build() => const AppearancePreferencesState();
}

class _RecordingThemePreference extends ThemePreference {
  _RecordingThemePreference(this._initialCss);

  final String _initialCss;
  final List<FluxerThemeMode> resetModes = <FluxerThemeMode>[];

  @override
  ThemePreferenceState build() => ThemePreferenceState(
    mode: FluxerThemeMode.dark,
    customThemeCss: _initialCss,
  );

  @override
  Future<void> flushPendingThemeColorPersist() async {}

  @override
  Future<void> resetThemeColorOverridesForMode(
    FluxerThemeMode editingMode,
  ) async {
    resetModes.add(editingMode);
    state = state.copyWith(customThemeCss: '');
  }
}

class _SuspendingTtsService extends FluxerTtsService {
  _SuspendingTtsService(this.supportedCompleter);

  final Completer<bool> supportedCompleter;
  int speakPreviewCalls = 0;

  @override
  FluxerTtsSpeakingState build() => const FluxerTtsSpeakingState();

  @override
  Future<bool> isSupported() => supportedCompleter.future;

  @override
  Future<void> speakPreview({
    required String text,
    required double rate,
    String? locale,
    void Function()? onEnd,
    void Function()? onError,
  }) async {
    speakPreviewCalls += 1;
  }

  @override
  Future<void> stop() async {}
}

class _RecordingVoiceSession extends VoiceSession {
  int switchToStandardCalls = 0;

  @override
  VoiceSessionState build() => const VoiceSessionState(
    isConnected: true,
    channelId: 'voice-1',
    guildId: 'g-1',
  );

  @override
  void switchToStandardCall() {
    switchToStandardCalls += 1;
  }
}

class _SuspendingPushRelayConsent extends PushRelayConsent {
  _SuspendingPushRelayConsent(this.ensureLoadedCompleter);

  final Completer<void> ensureLoadedCompleter;
  final List<Set<String>> revokedUserIdSets = <Set<String>>[];

  @override
  bool build() => true;

  @override
  Future<void> ensureLoaded() => ensureLoadedCompleter.future;

  @override
  Future<void> revoke({Set<String> userIds = const <String>{}}) async {
    revokedUserIdSets.add(userIds);
    state = false;
  }
}

class _RecordingApnsRegistration extends ApnsMobileDeviceRegistration {
  int unregisterCalls = 0;

  @override
  int build() => 0;

  @override
  Future<void> unregisterCurrentToken() async {
    unregisterCalls += 1;
  }
}

class _RecordingVoipApnsRegistration extends ApnsVoipMobileDeviceRegistration {
  int unregisterCalls = 0;

  @override
  int build() => 0;

  @override
  Future<void> unregisterCurrentToken() async {
    unregisterCalls += 1;
  }
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

class _StubNotificationPreferences extends NotificationPreferences {
  @override
  NotificationPreferencesState build() => const NotificationPreferencesState();
}

class _StubMentionReplyPreference extends MentionReplyPreference {
  @override
  Stream<MentionReplyPreferences> build() async* {
    yield MentionReplyPreferences.noPreference;
  }
}

class _StubPushDeliveryDetails extends PushDeliveryDetails {
  @override
  Future<PushDeliveryDetailsState> build() async =>
      const PushDeliveryDetailsState(
        pushProvider: PushProviderKind.apple,
        relayStatus: FluxerRelayDeliveryStatus.inUse,
      );
}

class _StubSoundPreferences extends SoundPreferences {
  @override
  SoundPreferencesState build() => const SoundPreferencesState();
}

class _CountingCurrentUserPrivate extends CurrentUserPrivateRead {
  int refreshCalls = 0;

  @override
  UserPrivateResponse? build(String accountUserId) => null;

  @override
  Future<void> refresh() async {
    refreshCalls += 1;
  }
}

class _CountingPremiumSettings extends PremiumSettingsState {
  int refreshCalls = 0;

  @override
  Future<PremiumStateResponse?> build() async => null;

  @override
  Future<void> refresh({String? countryCode, bool silent = false}) async {
    refreshCalls += 1;
  }
}

void main() {
  testWidgets(
    'UserOperatorPassSection, UserLanguageAndTime, and UserThemeColors survive unmount',
    (WidgetTester tester) async {
      final _SuspendingBillingAdapter adapter = _SuspendingBillingAdapter()
        ..operatorPassCompleter = Completer<void>();
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://api.fluxer.invalid'))
        ..httpClientAdapter = adapter;
      final Completer<void> timestampCompleter = Completer<void>();
      final db.FluxerDatabase mockDb = openTestDatabase();

      final String brandCssVar = themeColorTokenForProperty(
        'brandPrimary',
      )!.cssVariable;
      final _RecordingThemePreference themeNotifier = _RecordingThemePreference(
        upsertScopedThemeColor(
          editingMode: FluxerThemeMode.dark,
          cssVariable: brandCssVar,
          hexValue: '#FF0000',
        ),
      );

      final OperatorPassSettingsData passData = (
        passes: OperatorPassPassesResponse.fromJson(<String, Object?>{
          'count': 1,
          'passes': const <Object?>[],
          'incoming_offers': const <Object?>[],
          'outgoing_offers': const <Object?>[],
          'labs': const <String, Object?>{
            'show_operators': false,
            'greeting': false,
          },
        }),
        listing: null,
      );

      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: mockDb,
          extra: <Override>[
            fluxerDioProvider.overrideWithValue(dio),
            fluxerClientProvider.overrideWithValue(
              FluxerClient(dio, baseUrl: 'https://api.fluxer.invalid'),
            ),
            operatorPassSettingsProvider.overrideWith((Ref ref) => passData),
            appearancePreferencesProvider.overrideWith(
              _StaticAppearancePreferences.new,
            ),
            regionalFormatPreferenceProvider.overrideWith(
              _FakeRegionalFormatPreference.new,
            ),
            timestampFormatPreferenceProvider.overrideWith(
              () => _SuspendingTimestampFormatPreference(timestampCompleter),
            ),
            userSettingsSyncProvider.overrideWith(
              _NoopUserSettingsSyncService.new,
            ),
            userSettingsStatusProvider.overrideWithValue(null),
            themePreferenceProvider.overrideWith(() => themeNotifier),
          ],
        ),
      );
      addTearDown(container.dispose);
      await container.read(operatorPassSettingsProvider.future);

      final ValueNotifier<bool> mountOp = ValueNotifier<bool>(true);
      addTearDown(mountOp.dispose);
      final ValueNotifier<bool> mountLang = ValueNotifier<bool>(true);
      addTearDown(mountLang.dispose);
      final ValueNotifier<bool> mountTheme = ValueNotifier<bool>(true);
      addTearDown(mountTheme.dispose);

      await tester.pumpWidget(
        _shell(
          container: container,
          child: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  ValueListenableBuilder<bool>(
                    valueListenable: mountOp,
                    builder: (_, bool mounted, _) => mounted
                        ? const UserOperatorPassSection()
                        : const SizedBox.shrink(),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: mountLang,
                    builder: (_, bool mounted, _) => mounted
                        ? const UserLanguageAndTime()
                        : const SizedBox.shrink(),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: mountTheme,
                    builder: (_, bool mounted, _) => mounted
                        ? const UserThemeColors()
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. UserOperatorPassSection -> toggle switch, unmount, reject API request -> toast still fires.
      await tester.ensureVisible(
        find.text(testL10n.operatorPassShowOperatorsLabel),
      );
      await tester.tap(find.text(testL10n.operatorPassShowOperatorsLabel));
      await tester.pump();

      mountOp.value = false;
      await tester.pump();

      adapter.operatorPassCompleter!.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(
        container.read(toastProvider).last.toast.message,
        testL10n.operatorPassUpdateFailed,
      );

      // 2. UserLanguageAndTime -> tap timestamp radio, unmount, fail -> toast still fires.
      await tester.ensureVisible(
        find.text(testL10n.languageAndTimeDateFormatIso),
      );
      await tester.tap(find.text(testL10n.languageAndTimeDateFormatIso));
      await tester.pump();

      mountLang.value = false;
      await tester.pump();

      timestampCompleter.completeError(Exception('time sync failed'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      expect(
        container.read(toastProvider).last.toast.message,
        testL10n.languageAndTimeFormatSyncFailed,
      );

      // 3. UserThemeColors -> tap reset button, unmount before confirming modal -> reset still runs.
      final Finder resetFinder = find.text(
        testL10n.lookAndFeelThemeColorsResetForMode(
          testL10n.lookAndFeelThemeDark,
        ),
      );
      await tester.ensureVisible(resetFinder);
      await tester.tap(resetFinder);
      await tester.pumpAndSettle();

      mountTheme.value = false;
      await tester.pump();

      await tester.tap(find.text(testL10n.uiReset));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(themeNotifier.resetModes, <FluxerThemeMode>[FluxerThemeMode.dark]);
    },
  );

  testWidgets(
    'UserAccessibilityTtsSection and confirmSwitchToStandardVoiceCall handle unmount safely',
    (WidgetTester tester) async {
      final Completer<bool> supportedCompleter = Completer<bool>();
      final _SuspendingTtsService ttsService = _SuspendingTtsService(
        supportedCompleter,
      );
      final _RecordingVoiceSession voiceSession = _RecordingVoiceSession();
      final db.FluxerDatabase mockDb = openTestDatabase();

      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: mockDb,
          extra: <Override>[
            appearancePreferencesProvider.overrideWith(
              _StaticAppearancePreferences.new,
            ),
            fluxerTtsServiceProvider.overrideWith(() => ttsService),
            voiceSessionProvider.overrideWith(() => voiceSession),
          ],
        ),
      );
      addTearDown(container.dispose);

      final ValueNotifier<bool> mountTts = ValueNotifier<bool>(true);
      addTearDown(mountTts.dispose);
      final ValueNotifier<bool> mountSwitchCaller = ValueNotifier<bool>(true);
      addTearDown(mountSwitchCaller.dispose);
      late BuildContext hostContext;

      await tester.pumpWidget(
        _shell(
          container: container,
          child: Builder(
            builder: (BuildContext ctx) {
              hostContext = ctx;
              return Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      ValueListenableBuilder<bool>(
                        valueListenable: mountTts,
                        builder: (_, bool mounted, _) => mounted
                            ? const UserAccessibilityTtsSection()
                            : const SizedBox.shrink(),
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: mountSwitchCaller,
                        builder: (_, bool mounted, _) {
                          if (!mounted) {
                            return const SizedBox.shrink();
                          }
                          return Consumer(
                            builder: (_, WidgetRef callerRef, _) =>
                                ElevatedButton(
                                  onPressed: () => unawaited(
                                    confirmSwitchToStandardVoiceCall(
                                      hostContext,
                                      callerRef,
                                    ),
                                  ),
                                  child: const Text('SwitchVoice'),
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
      await tester.pumpAndSettle();

      // 1. UserAccessibilityTtsSection -> unmount before isSupported() resolves.
      await tester.tap(find.text(testL10n.accessibilityTtsPlaySampleLabel));
      await tester.pump();

      mountTts.value = false;
      await tester.pump();

      supportedCompleter.complete(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(ttsService.speakPreviewCalls, 0);

      // 2. confirmSwitchToStandardVoiceCall -> unmount caller while confirm sheet is open.
      await tester.tap(find.text('SwitchVoice'));
      await tester.pumpAndSettle();

      mountSwitchCaller.value = false;
      await tester.pump();

      await tester.tap(find.text(testL10n.voiceP2pSwitchToStandard).last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(voiceSession.switchToStandardCalls, 1);
    },
  );

  testWidgets(
    'UserNotificationsSettings revoke consent and checkout helpers survive caller unmount',
    (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final Completer<void> consentLoadedCompleter = Completer<void>();
      final _SuspendingPushRelayConsent relayConsent =
          _SuspendingPushRelayConsent(consentLoadedCompleter);
      final _RecordingApnsRegistration apnsReg = _RecordingApnsRegistration();
      final _RecordingVoipApnsRegistration voipReg =
          _RecordingVoipApnsRegistration();
      final _CountingCurrentUserPrivate userPrivate =
          _CountingCurrentUserPrivate();
      final _CountingPremiumSettings premiumSettings =
          _CountingPremiumSettings();

      final _SuspendingBillingAdapter adapter = _SuspendingBillingAdapter()
        ..cancelPremiumCompleter = Completer<void>()
        ..refundPremiumCompleter = Completer<void>();
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://api.fluxer.invalid'))
        ..httpClientAdapter = adapter;

      final db.FluxerDatabase mockDb = openTestDatabase();

      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: mockDb,
          extra: <Override>[
            fluxerDioProvider.overrideWithValue(dio),
            fluxerClientProvider.overrideWithValue(
              FluxerClient(dio, baseUrl: 'https://api.fluxer.invalid'),
            ),
            isActiveInstanceOfficialProvider.overrideWithValue(false),
            pushRelayConsentProvider.overrideWith(() => relayConsent),
            apnsMobileDeviceRegistrationProvider.overrideWith(() => apnsReg),
            apnsVoipMobileDeviceRegistrationProvider.overrideWith(
              () => voipReg,
            ),
            syncedPreferencesStoreProvider.overrideWith(_InertSyncedStore.new),
            userSettingsSyncProvider.overrideWith(
              _NoopUserSettingsSyncService.new,
            ),
            userSettingsStatusProvider.overrideWithValue(null),
            notificationPreferencesProvider.overrideWith(
              _StubNotificationPreferences.new,
            ),
            mentionReplyPreferenceProvider.overrideWith(
              _StubMentionReplyPreference.new,
            ),
            soundPreferencesProvider.overrideWith(_StubSoundPreferences.new),
            pushNotificationPermissionGrantedProvider.overrideWith(
              (Ref ref) => true,
            ),
            pushNotificationRequiresSystemSettingsProvider.overrideWith(
              (Ref ref) => false,
            ),
            pushDeliveryDetailsProvider.overrideWith(
              _StubPushDeliveryDetails.new,
            ),
            currentUserPrivateReadProvider(
              'test-user-id',
            ).overrideWith(() => userPrivate),
            premiumSettingsStateProvider.overrideWith(() => premiumSettings),
          ],
        ),
      );
      addTearDown(container.dispose);
      final ProviderSubscription<AsyncValue<PremiumStateResponse?>> premiumSub =
          container.listen(premiumSettingsStateProvider, (_, _) {});
      addTearDown(premiumSub.close);
      await container.read(premiumSettingsStateProvider.future);

      final ValueNotifier<bool> mountNotifs = ValueNotifier<bool>(true);
      addTearDown(mountNotifs.dispose);
      final ValueNotifier<bool> mountBilling = ValueNotifier<bool>(true);
      addTearDown(mountBilling.dispose);
      late Future<void> cancelFuture;
      late Future<bool> refundFuture;

      await tester.pumpWidget(
        _shell(
          container: container,
          child: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  ValueListenableBuilder<bool>(
                    valueListenable: mountNotifs,
                    builder: (_, bool mounted, _) => mounted
                        ? const UserNotificationsSettings()
                        : const SizedBox.shrink(),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: mountBilling,
                    builder: (_, bool mounted, _) {
                      if (!mounted) {
                        return const SizedBox.shrink();
                      }
                      return Consumer(
                        builder: (_, WidgetRef callerRef, _) => Column(
                          children: <Widget>[
                            ElevatedButton(
                              onPressed: () {
                                cancelFuture = cancelPremiumSubscription(
                                  callerRef,
                                );
                              },
                              child: const Text('CancelSub'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                refundFuture = selfServeRefundLatest(callerRef);
                              },
                              child: const Text('RefundSub'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. UserNotificationsSettings revoke push relay consent -> unmount before ensureLoaded finishes.
      final Finder relayToggle = find.text(
        testL10n.notificationsPushRelayConsentLabel,
      );
      await tester.ensureVisible(relayToggle);
      await tester.tap(relayToggle);
      await tester.pump();

      mountNotifs.value = false;
      await tester.pump();

      consentLoadedCompleter.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(relayConsent.revokedUserIdSets, hasLength(1));
      expect(apnsReg.unregisterCalls, 1);
      expect(voipReg.unregisterCalls, 1);

      // 2. cancelPremiumSubscription & selfServeRefundLatest -> unmount caller before billing APIs resolve.
      await tester.ensureVisible(find.text('CancelSub'));
      await tester.tap(find.text('CancelSub'));
      await tester.pump();
      await tester.ensureVisible(find.text('RefundSub'));
      await tester.tap(find.text('RefundSub'));
      await tester.pump();

      mountBilling.value = false;
      await tester.pump();

      adapter.cancelPremiumCompleter!.complete();
      adapter.refundPremiumCompleter!.complete();
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      await cancelFuture;
      expect(await refundFuture, isTrue);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(userPrivate.refreshCalls, 1);
      expect(premiumSettings.refreshCalls, 2);
    },
  );
}
