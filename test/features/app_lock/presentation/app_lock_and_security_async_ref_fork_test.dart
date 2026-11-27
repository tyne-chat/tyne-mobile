// Fork: tyne-chat/tyne#946 — regression tests for Group A async WidgetRef
// disposal hazards across AppLockScreen, IncomingVoiceCallLayer,
// executeAcceptIncomingVoiceCall, RecoveryKitSettingsSubsection,
// UserSecurityLogin, ConnectionEditSheet, ConnectionRemoveSheet, and
// showUnifiedPushDistributorPickerSheet.

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/app_lock/app_lock_biometric_authenticator.dart';
import 'package:fluxer_app/core/app_lock/app_lock_controller.dart';
import 'package:fluxer_app/core/build/push_provider_kind.dart';
import 'package:fluxer_app/core/database/daos/channel_dao.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/push/delivery/display.dart';
import 'package:fluxer_app/core/push/unified_push/unified_push_distributor_picker_sheet.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/app_lock/presentation/app_lock_screen.dart';
import 'package:fluxer_app/features/auth/domain/stored_account.dart';
import 'package:fluxer_app/features/auth/providers/account_manager_provider.dart';
import 'package:fluxer_app/features/recovery_kit/domain/recovery_kit.dart';
import 'package:fluxer_app/features/recovery_kit/presentation/recovery_kit_settings_section.dart';
import 'package:fluxer_app/features/recovery_kit/providers/recovery_kit_providers.dart';
import 'package:fluxer_app/features/settings/presentation/sheets/connection_edit_sheet.dart';
import 'package:fluxer_app/features/settings/presentation/sheets/connection_remove_sheet.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/user_security_login.dart';
import 'package:fluxer_app/features/settings/providers/commerce/push_delivery_details_provider.dart';
import 'package:fluxer_app/features/settings/providers/view_models/connections_view_model.dart';
import 'package:fluxer_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:fluxer_app/features/settings/providers/view_models/webauthn_credentials_view_model.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button.dart';
import 'package:fluxer_app/features/ui/toast/toast_provider.dart';
import 'package:fluxer_app/features/voice/presentation/widgets/incoming_voice_call_layer.dart';
import 'package:fluxer_app/features/voice/providers/pending_incoming_voice_calls_provider.dart';
import 'package:fluxer_app/features/voice/utils/callkit/incoming_call_actions.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/utils/fluxer_haptics.dart';
import 'package:fluxer_dart/export.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Federated Android plugin is a transitive dependency of unifiedpush; register
// it in widget tests so UnifiedPush.saveDistributor routes to MethodChannel.
// ignore: depend_on_referenced_packages
import 'package:unifiedpush_android/unifiedpush_android.dart';

import '../../../helpers/core_test_provider_overrides.dart';
import '../../../helpers/open_test_database.dart';
import '../../../helpers/test_account_user_id.dart';
import '../../../helpers/test_l10n.dart';

const ConnectionResponse _sampleConnection = ConnectionResponse(
  id: 'conn-1',
  type: ConnectionType.bluesky,
  name: '@alice.bsky.social',
  verified: true,
  visibilityFlags: 0,
  sortOrder: 0,
  providerId: null,
  url: null,
);

class _TestPendingVoiceIds extends Notifier<List<String>> {
  @override
  List<String> build() => const <String>[];

  List<String> get ids => state;
  set ids(List<String> value) => state = value;
}

final _testPendingVoiceIdsProvider =
    NotifierProvider<_TestPendingVoiceIds, List<String>>(
      _TestPendingVoiceIds.new,
    );

Widget _appShell({
  required ProviderContainer container,
  required Widget child,
}) {
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

class _UnmountingAccountManager extends AccountManager {
  _UnmountingAccountManager({
    required this.onSignOutStarted,
    required this.signOutCompleter,
  });

  final VoidCallback onSignOutStarted;
  final Completer<void> signOutCompleter;
  final List<String> removedUserIds = <String>[];
  final List<String> signedOutUserIds = <String>[];

  @override
  AccountManagerState build() => const AccountManagerState(
    accounts: <StoredAccount>[
      StoredAccount(
        userId: kTestAccountUserId,
        isValid: true,
        mediaBaseUrl: '',
      ),
      StoredAccount(userId: 'other-user-2', isValid: true, mediaBaseUrl: ''),
    ],
    isSwitching: false,
  );

  @override
  Future<void> loadAccounts() async {}

  @override
  Future<void> removeAccount(String userId) async {
    removedUserIds.add(userId);
  }

  @override
  Future<void> signOut(String userId, {bool keepInstance = false}) async {
    signedOutUserIds.add(userId);
    onSignOutStarted();
    await signOutCompleter.future;
  }
}

class _RecordingAppLockController extends AppLockController {
  int disableCalls = 0;

  @override
  AppLockState build() =>
      const AppLockState(loaded: true, enabled: true, isLocked: true);

  @override
  Future<void> load() async {}

  @override
  Future<List<AppLockBiometricKind>> availableBiometricKinds() async =>
      const <AppLockBiometricKind>[];

  @override
  Future<void> disable() async {
    disableCalls++;
  }
}

class _SlowChannelDao extends ChannelDao {
  _SlowChannelDao(super.attachedDatabase);

  final Completer<db.Channel?> lookupCompleter = Completer<db.Channel?>();

  @override
  Future<db.Channel?> getChannelById(String id) => lookupCompleter.future;
}

class _SlowChannelDatabase extends db.FluxerDatabase {
  _SlowChannelDatabase() : super.forTesting(NativeDatabase.memory());

  late final _SlowChannelDao slowChannelDao = _SlowChannelDao(this);

  @override
  ChannelDao get channelDao => slowChannelDao;
}

class _FailingRecoveryKitNotifier extends PendingRecoveryKit {
  _FailingRecoveryKitNotifier(this.completer);

  final Completer<RecoveryKit> completer;

  @override
  RecoveryKit? build() => null;

  @override
  Future<RecoveryKit> create({
    required RecoveryKitReason reason,
    String? username,
    String? discriminator,
    String? password,
  }) => completer.future;
}

class _FixedUserSettings extends UserSettingsViewModel {
  @override
  UserSettingsViewState build() => const UserSettingsViewState(
    userId: kTestAccountUserId,
    username: 'neo',
    displayName: 'Neo',
    discriminator: '0001',
    avatar: null,
    avatarColor: null,
    memberSince: null,
    status: 'online',
    messageDisplayCompact: false,
    developerMode: false,
    trustedDomains: <String>[],
    email: 'neo@example.com',
    verified: true,
  );
}

class _RecordingWebauthnCredentials extends WebauthnCredentialsViewModel {
  int silentLoads = 0;

  @override
  WebauthnCredentialsViewState build(String accountUserId) =>
      const WebauthnCredentialsViewState(
        isLoading: false,
        credentials: <WebAuthnCredentialResponse>[
          WebAuthnCredentialResponse(
            id: 'pk-1',
            name: 'YubiKey',
            createdAt: '2026-01-01T00:00:00Z',
            lastUsedAt: null,
            rpId: 'fluxer.app',
          ),
        ],
      );

  @override
  Future<void> load({bool silent = false}) async {
    if (silent) {
      silentLoads++;
    }
  }
}

class _SlowPasskeyUsersApi implements UsersApi {
  final Completer<void> deleteCompleter = Completer<void>();

  @override
  Future<void> deleteWebauthnCredential({
    required String credentialId,
    SudoVerificationSchema? body,
  }) => deleteCompleter.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'Unexpected UsersApi call: ${invocation.memberName}',
  );
}

class _SlowPasskeyClient implements FluxerClient {
  _SlowPasskeyClient(this._users);

  final _SlowPasskeyUsersApi _users;

  @override
  UsersApi get users => _users;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'Unexpected FluxerClient call: ${invocation.memberName}',
  );
}

class _FailingConnectionsNotifier extends ConnectionsViewModel {
  final Completer<void> updateCompleter = Completer<void>();
  final Completer<void> deleteCompleter = Completer<void>();

  @override
  ConnectionsViewState build(String accountUserId) =>
      const ConnectionsViewState(
        isLoading: false,
        connections: <ConnectionResponse>[_sampleConnection],
      );

  @override
  Future<void> load({bool silent = false}) async {}

  @override
  Future<void> updateVisibility(
    String type,
    String connectionId,
    int visibilityFlags,
  ) => updateCompleter.future;

  @override
  Future<void> deleteConnection(String type, String connectionId) =>
      deleteCompleter.future;
}

class _CountingPushDeliveryDetails extends PushDeliveryDetails {
  int builds = 0;

  @override
  Future<PushDeliveryDetailsState> build() async {
    builds++;
    return const PushDeliveryDetailsState(
      pushProvider: PushProviderKind.unifiedPush,
      relayStatus: FluxerRelayDeliveryStatus.inUse,
      availableDistributors: <String>[
        'org.unifiedpush.example.alpha',
        'org.unifiedpush.example.beta',
      ],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FluxerHaptics.enabled = false;
  });

  tearDown(() {
    FluxerHaptics.enabled = true;
  });

  testWidgets(
    'AppLockScreen forgot-PIN sign-out disables app lock without StateError when unmounted mid-signOut',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final db.FluxerDatabase database = openTestDatabase();
      final ValueNotifier<bool> mountScreen = ValueNotifier<bool>(true);
      addTearDown(mountScreen.dispose);
      final Completer<void> signOutCompleter = Completer<void>();
      final _UnmountingAccountManager accounts = _UnmountingAccountManager(
        onSignOutStarted: () => mountScreen.value = false,
        signOutCompleter: signOutCompleter,
      );
      final _RecordingAppLockController appLock = _RecordingAppLockController();

      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: database,
          extra: <Override>[
            accountManagerProvider.overrideWith(() => accounts),
            appLockControllerProvider.overrideWith(() => appLock),
          ],
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _appShell(
          container: container,
          child: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: mountScreen,
              builder: (_, bool mounted, _) =>
                  mounted ? const AppLockScreen() : const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text(testL10n.appLockForgotPin));
      await tester.pump();
      for (int i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final Finder signOutFinder = find.widgetWithText(
        FluxerButton,
        testL10n.signOut,
      );
      await tester.ensureVisible(signOutFinder);
      await tester.tap(signOutFinder);
      await tester.pump();
      for (int i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byType(AppLockScreen), findsNothing);

      signOutCompleter.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(accounts.removedUserIds, <String>['other-user-2']);
      expect(accounts.signedOutUserIds, <String>[kTestAccountUserId]);
      expect(appLock.disableCalls, 1);
    },
  );

  testWidgets(
    'IncomingVoiceCallLayer and executeAcceptIncomingVoiceCall handle caller disposal cleanly',
    (WidgetTester tester) async {
      // Case A: IncomingVoiceCallLayer unmounts while IncomingVoiceCallSheet
      // is open; dismissing the sheet runs `finally` without StateError.
      final db.FluxerDatabase database = openTestDatabase();
      final ValueNotifier<bool> mountLayer = ValueNotifier<bool>(true);
      addTearDown(mountLayer.dispose);

      final ProviderContainer layerContainer = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: database,
          extra: <Override>[
            pendingIncomingVoiceChannelIdsProvider.overrideWith(
              (Ref ref) => ref.watch(_testPendingVoiceIdsProvider),
            ),
          ],
        ),
      );
      addTearDown(layerContainer.dispose);

      await tester.pumpWidget(
        _appShell(
          container: layerContainer,
          child: ValueListenableBuilder<bool>(
            valueListenable: mountLayer,
            builder: (_, bool mounted, _) => mounted
                ? const IncomingVoiceCallLayer(
                    child: Scaffold(body: SizedBox.shrink()),
                  )
                : const Scaffold(body: SizedBox.shrink()),
          ),
        ),
      );
      await tester.pump();

      layerContainer.read(_testPendingVoiceIdsProvider.notifier).ids = <String>[
        'vc-layer-1',
      ];
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(testL10n.incomingVoiceCallAccept), findsOneWidget);

      mountLayer.value = false;
      await tester.pump();

      Navigator.of(rootNavigatorKey.currentContext!).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      await releaseTestWidgetTree(tester);

      // Case B: executeAcceptIncomingVoiceCall unmounts caller ref during DB
      // lookup while an unscoped Context stays mounted (forcing failed result
      // and showing error toast via captured container).
      final _SlowChannelDatabase slowDb = _SlowChannelDatabase();
      addTearDown(slowDb.close);
      final ValueNotifier<bool> mountCaller = ValueNotifier<bool>(true);
      addTearDown(mountCaller.dispose);
      final ProviderContainer callContainer = ProviderContainer(
        overrides: coreTestProviderOverrides(database: slowDb),
      );
      addTearDown(callContainer.dispose);

      late BuildContext unscopedCtx;
      Object? actionError;
      var actionDone = false;
      final colorTheme = buildDarkColorTheme();

      await tester.pumpWidget(
        MaterialApp(
          locale: kTestLocale,
          localizationsDelegates: fluxerLocalizationsDelegates,
          supportedLocales: FluxerLocalizations.supportedLocales,
          theme: buildFluxerTheme(
            colorTheme: colorTheme,
            textTheme: FluxerTextTheme.fromColors(colorTheme),
            layoutTheme: FluxerLayoutTheme.scaled(),
          ),
          home: Builder(
            builder: (BuildContext outerCtx) {
              unscopedCtx = outerCtx;
              return UncontrolledProviderScope(
                container: callContainer,
                child: Scaffold(
                  body: ValueListenableBuilder<bool>(
                    valueListenable: mountCaller,
                    builder: (_, bool mounted, _) {
                      if (!mounted) {
                        return const SizedBox.shrink();
                      }
                      return Consumer(
                        builder: (_, WidgetRef ref, _) => ElevatedButton(
                          onPressed: () {
                            unawaited(
                              executeAcceptIncomingVoiceCall(
                                ref,
                                unscopedCtx,
                                'vc-accept-1',
                              ).then(
                                (_) => actionDone = true,
                                onError: (Object e) {
                                  actionError = e;
                                  actionDone = true;
                                },
                              ),
                            );
                          },
                          child: const Text('Accept'),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Accept'));
      await tester.pump();

      mountCaller.value = false;
      await tester.pump();

      slowDb.slowChannelDao.lookupCompleter.complete(null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(actionError, isNull);
      expect(actionDone, isTrue);
      expect(callContainer.read(toastProvider), hasLength(1));
    },
  );

  testWidgets(
    'RecoveryKitSettingsSubsection and UserSecurityLogin handle unmount across create and deletePasskey',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Case A: RecoveryKitSettingsSubsection unmounted while create fails.
      final db.FluxerDatabase database = openTestDatabase();
      final Completer<RecoveryKit> createCompleter = Completer<RecoveryKit>();
      final ValueNotifier<bool> mountRecovery = ValueNotifier<bool>(true);
      addTearDown(mountRecovery.dispose);

      final ProviderContainer recoveryContainer = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: database,
          extra: <Override>[
            recoveryKitStatusProvider.overrideWith(
              (Ref ref) => Future<RecoveryKitStatusResponse>.value(
                const RecoveryKitStatusResponse(
                  hasRecoveryKit: false,
                  createdAt: null,
                ),
              ),
            ),
            pendingRecoveryKitProvider.overrideWith(
              () => _FailingRecoveryKitNotifier(createCompleter),
            ),
          ],
        ),
      );
      addTearDown(recoveryContainer.dispose);

      await tester.pumpWidget(
        _appShell(
          container: recoveryContainer,
          child: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: mountRecovery,
              builder: (_, bool mounted, _) => mounted
                  ? const RecoveryKitSettingsSubsection()
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(testL10n.recoveryKitCreate));
      await tester.pump();

      mountRecovery.value = false;
      await tester.pump();

      createCompleter.completeError(Exception('create failed'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(
        recoveryContainer.read(toastProvider).single.toast.message,
        testL10n.recoveryKitCreateFailed,
      );

      // Case B: UserSecurityLogin unmounted during deleteWebauthnCredential.
      final _SlowPasskeyUsersApi usersApi = _SlowPasskeyUsersApi();
      final _RecordingWebauthnCredentials passkeysNotifier =
          _RecordingWebauthnCredentials();
      final ValueNotifier<bool> mountSecurity = ValueNotifier<bool>(true);
      addTearDown(mountSecurity.dispose);

      final ProviderContainer securityContainer = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: database,
          extra: <Override>[
            activeInstanceSupportsPasskeysProvider.overrideWithValue(true),
            userSettingsViewModelProvider.overrideWith(_FixedUserSettings.new),
            webauthnCredentialsViewModelProvider(
              kTestAccountUserId,
            ).overrideWith(() => passkeysNotifier),
            fluxerClientProvider.overrideWithValue(
              _SlowPasskeyClient(usersApi),
            ),
          ],
        ),
      );
      addTearDown(securityContainer.dispose);

      await tester.pumpWidget(
        _appShell(
          container: securityContainer,
          child: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: mountSecurity,
              builder: (_, bool mounted, _) =>
                  mounted ? const UserSecurityLogin() : const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Finder deleteButton = find.widgetWithText(
        FluxerButton,
        testL10n.delete,
      );
      await tester.ensureVisible(deleteButton);
      await tester.pumpAndSettle();
      await tester.tap(deleteButton);
      await tester.pump();
      for (int i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.tap(find.text(testL10n.securityPasskeysDeleteTitle).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      mountSecurity.value = false;
      await tester.pump();

      usersApi.deleteCompleter.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(passkeysNotifier.silentLoads, 1);
    },
  );

  testWidgets(
    'ConnectionEditSheet, ConnectionRemoveSheet, and showUnifiedPushDistributorPickerSheet survive unmount cleanly',
    (WidgetTester tester) async {
      final db.FluxerDatabase database = openTestDatabase();
      final _FailingConnectionsNotifier connectionsNotifier =
          _FailingConnectionsNotifier();
      final _CountingPushDeliveryDetails pushDetails =
          _CountingPushDeliveryDetails();

      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: database,
          extra: <Override>[
            connectionsViewModelProvider(
              kTestAccountUserId,
            ).overrideWith(() => connectionsNotifier),
            pushDeliveryDetailsProvider.overrideWith(() => pushDetails),
          ],
        ),
      );
      addTearDown(container.dispose);

      // Keep pushDetails active to count invalidation rebuilds.
      container.listen(pushDeliveryDetailsProvider, (_, _) {});
      await container.read(pushDeliveryDetailsProvider.future);
      final int initialPushBuilds = pushDetails.builds;

      const MethodChannel upChannel = MethodChannel(
        'org.unifiedpush.flutter.connector.PLUGIN_CHANNEL',
      );
      final Completer<bool> saveDistributorCompleter = Completer<bool>();
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      UnifiedPushAndroid.registerWith();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(upChannel, (MethodCall call) {
            if (call.method == 'saveDistributor') {
              return saveDistributorCompleter.future;
            }
            return Future<Object?>.value();
          });
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(upChannel, null);
      });

      final ValueNotifier<bool> mountLauncher = ValueNotifier<bool>(true);
      addTearDown(mountLauncher.dispose);
      late BuildContext rootContext;
      late WidgetRef callerRef;

      await tester.pumpWidget(
        _appShell(
          container: container,
          child: Builder(
            builder: (BuildContext outerContext) {
              rootContext = outerContext;
              return Scaffold(
                body: ValueListenableBuilder<bool>(
                  valueListenable: mountLauncher,
                  builder: (_, bool mounted, _) {
                    if (!mounted) {
                      return const SizedBox.shrink();
                    }
                    return Consumer(
                      builder: (BuildContext ctx, WidgetRef ref, _) {
                        callerRef = ref;
                        return Column(
                          children: <Widget>[
                            ElevatedButton(
                              onPressed: () => ConnectionEditSheet.show(
                                ctx,
                                ref,
                                connection: _sampleConnection,
                              ),
                              child: const Text('EditConn'),
                            ),
                            ElevatedButton(
                              onPressed: () => ConnectionRemoveSheet.show(
                                ctx,
                                ref,
                                connection: _sampleConnection,
                              ),
                              child: const Text('RemoveConn'),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  showUnifiedPushDistributorPickerSheet(
                                    rootContext,
                                    ref: ref,
                                    distributors: const <String>[
                                      'org.unifiedpush.example.alpha',
                                      'org.unifiedpush.example.beta',
                                    ],
                                    currentDistributor:
                                        'org.unifiedpush.example.alpha',
                                  ),
                              child: const Text('PickDist'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      );
      expect(callerRef.context.mounted, isTrue);

      // 1. ConnectionEditSheet dismissed while updateVisibility is pending.
      await tester.tap(find.text('EditConn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(testL10n.save));
      await tester.pump();

      Navigator.of(rootNavigatorKey.currentContext!).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      connectionsNotifier.updateCompleter.completeError(Exception('edit fail'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(
        container.read(toastProvider).last.toast.message,
        testL10n.connectionUpdateFailed,
      );

      // 2. ConnectionRemoveSheet dismissed while deleteConnection is pending.
      await tester.tap(find.text('RemoveConn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(testL10n.connectionRemoveConfirm));
      await tester.pump();

      Navigator.of(rootNavigatorKey.currentContext!).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      connectionsNotifier.deleteCompleter.completeError(
        Exception('remove fail'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      expect(
        container.read(toastProvider).last.toast.message,
        testL10n.connectionRemoveFailed,
      );

      // 3. UnifiedPush distributor picker: caller ref unmounts before save finishes.
      await tester.tap(find.text('PickDist'));
      await tester.pumpAndSettle();

      mountLauncher.value = false;
      await tester.pump();

      await tester.tap(find.text('beta'));
      await tester.pump();

      saveDistributorCompleter.complete(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await container.read(pushDeliveryDetailsProvider.future);

      expect(tester.takeException(), isNull);
      expect(pushDetails.builds, greaterThan(initialPushBuilds));
    },
  );
}
