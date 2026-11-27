// Fork: tyne-chat/tyne#946 — regression tests for PasswordChangeSheet,
// UsernameClaimAccountSheet, TotpEnableSheet, TotpDisableSheet, and
// applyReplacementSession when dismissed/unmounted mid-flight.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/providers/gateway/gateway_connection_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/auth/data/auth_repository.dart';
import 'package:fluxer_app/features/auth/providers/auth_providers.dart';
import 'package:fluxer_app/features/auth/providers/current_auth_session_provider.dart';
import 'package:fluxer_app/features/recovery_kit/providers/recovery_kit_providers.dart';
import 'package:fluxer_app/features/settings/presentation/sheets/backup_codes_sheet.dart';
import 'package:fluxer_app/features/settings/presentation/sheets/password_change_sheet.dart';
import 'package:fluxer_app/features/settings/presentation/sheets/totp_disable_sheet.dart';
import 'package:fluxer_app/features/settings/presentation/sheets/totp_enable_sheet.dart';
import 'package:fluxer_app/features/settings/presentation/sheets/username_claim_account_sheet.dart';
import 'package:fluxer_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button.dart';
import 'package:fluxer_app/features/ui/toast/toast_provider.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_dart/export.dart';
import 'package:fluxer_dart/gateway.dart';

import '../../../../helpers/core_test_provider_overrides.dart';
import '../../../../helpers/open_test_database.dart';
import '../../../../helpers/test_account_user_id.dart';
import '../../../../helpers/test_l10n.dart';

class _TestUserSettingsViewModel extends UserSettingsViewModel {
  _TestUserSettingsViewModel({required this.initialState, this.onLoadProfile});

  final UserSettingsViewState initialState;
  final VoidCallback? onLoadProfile;

  @override
  UserSettingsViewState build() => initialState;

  @override
  Future<void> loadProfile() async {
    onLoadProfile?.call();
  }
}

class _RecordingGatewayConnection extends Fake implements GatewayConnection {
  final List<String> tokens = <String>[];

  @override
  void setToken(String token) {
    tokens.add(token);
  }
}

class _RecordingAuthRepository extends Fake implements AuthRepository {
  final List<String> persistedTokens = <String>[];

  @override
  Future<void> persistRotatedToken(String token) async {
    persistedTokens.add(token);
  }
}

class _SeededAuthTokenNotifier extends FluxerAuthToken {
  @override
  String? build() => 'old-tok';

  @override
  void setToken(String? token, {String? issuerBaseUrl}) {
    state = token;
  }
}

class _SlowUsersApi implements UsersApi {
  final Completer<UserPasswordUpdateResponse> passwordCompleter =
      Completer<UserPasswordUpdateResponse>();
  final Completer<UserUpdateResponse> claimCompleter =
      Completer<UserUpdateResponse>();
  final Completer<MfaBackupCodesResponse> totpEnableCompleter =
      Completer<MfaBackupCodesResponse>();

  @override
  Future<UserPasswordUpdateResponse> updateCurrentUserPassword({
    required UserPasswordUpdateRequest body,
  }) => passwordCompleter.future;

  @override
  Future<UserUpdateResponse> updateCurrentUser({
    UserUpdateWithVerificationRequest? body,
  }) => claimCompleter.future;

  @override
  Future<MfaBackupCodesResponse> enableTotpMfa({
    required EnableMfaTotpRequest body,
  }) => totpEnableCompleter.future;

  @override
  Future<RecoveryKitCreateResponse> createRecoveryKit({
    SudoVerificationSchema? body,
  }) async => RecoveryKitCreateResponse(
    recoveryKey: 'AAAA-BBBB-CCCC-DDDD-EEEE-FFFF-GGGG-HHHH',
    createdAt: DateTime.utc(2026, 11, 26),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UsersTestClient extends FluxerClient {
  _UsersTestClient(this._users) : super(Dio());

  final UsersApi _users;

  @override
  UsersApi get users => _users;
}

class _SlowTotpDisableAdapter implements HttpClientAdapter {
  final Completer<void> disableCompleter = Completer<void>();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/users/@me/mfa/backup-codes')) {
      return ResponseBody.fromString(
        jsonEncode(<String, Object?>{
          'backup_codes': <Map<String, Object?>>[
            <String, Object?>{'code': 'UNUS-ED01', 'consumed': false},
          ],
        }),
        200,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      );
    }
    if (options.path.endsWith('/users/@me/mfa/totp/disable')) {
      await disableCompleter.future;
      return ResponseBody.fromString('', 204);
    }
    return ResponseBody.fromString('{}', 404);
  }

  @override
  void close({bool force = false}) {}
}

Widget _wrapWithApp(ProviderContainer container, Widget home) {
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
      home: home,
    ),
  );
}

void main() {
  testWidgets(
    'PasswordChangeSheet dismissed during updateCurrentUserPassword still applies replacement session, shows toast, reloads profile, and presents recovery kit without StateError',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db.FluxerDatabase database = openTestDatabase();
      final _SlowUsersApi usersApi = _SlowUsersApi();
      final _RecordingGatewayConnection gateway = _RecordingGatewayConnection();
      final _RecordingAuthRepository authRepo = _RecordingAuthRepository();
      int loadProfileCalls = 0;

      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: database,
          extra: [
            userSettingsViewModelProvider.overrideWith(
              () => _TestUserSettingsViewModel(
                initialState: const UserSettingsViewState(
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
                  usernameSignIn: true,
                ),
                onLoadProfile: () => loadProfileCalls++,
              ),
            ),
            fluxerClientProvider.overrideWithValue(_UsersTestClient(usersApi)),
            gatewayConnectionProvider.overrideWithValue(gateway),
            authRepositoryProvider.overrideWithValue(authRepo),
            fluxerAuthTokenProvider.overrideWith(_SeededAuthTokenNotifier.new),
          ],
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrapWithApp(
          container,
          Scaffold(
            body: Consumer(
              builder: (BuildContext context, WidgetRef ref, _) => Center(
                child: ElevatedButton(
                  onPressed: () => PasswordChangeSheet.show(context, ref),
                  child: const Text('Change Password'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle();

      final Finder fields = find.byType(EditableText);
      await tester.enterText(fields.at(0), 'new-secret-pass');
      await tester.enterText(fields.at(1), 'new-secret-pass');
      await tester.pump();

      final Finder submitButton = find.widgetWithText(
        FluxerButton,
        testL10n.passwordChangeSubmit,
      );
      await tester.ensureVisible(submitButton);
      await tester.pumpAndSettle();
      await tester.tap(submitButton);
      await tester.pump();

      // Dismiss the sheet while `updateCurrentUserPassword` is in flight.
      Navigator.of(rootNavigatorKey.currentContext!).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(PasswordChangeSheet), findsNothing);

      usersApi.passwordCompleter.complete(
        const UserPasswordUpdateResponse(
          token: 'rot-tok-1',
          authSessionIdHash: 'hash-1',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(gateway.tokens, <String>['rot-tok-1']);
      expect(authRepo.persistedTokens, <String>['rot-tok-1']);
      expect(container.read(currentAuthSessionIdHashProvider), 'hash-1');
      expect(loadProfileCalls, 1);
      expect(
        container.read(toastProvider).single.toast.message,
        testL10n.passwordChangeSuccess,
      );
      expect(
        container.read(pendingRecoveryKitProvider)?.recoveryKey,
        'AAAA-BBBB-CCCC-DDDD-EEEE-FFFF-GGGG-HHHH',
      );
    },
  );

  testWidgets(
    'UsernameClaimAccountSheet unmounted during updateCurrentUser still applies replacement session, shows toast, reloads profile, and presents recovery kit without StateError',
    (WidgetTester tester) async {
      final db.FluxerDatabase database = openTestDatabase();
      final _SlowUsersApi usersApi = _SlowUsersApi();
      final _RecordingGatewayConnection gateway = _RecordingGatewayConnection();
      final _RecordingAuthRepository authRepo = _RecordingAuthRepository();
      final ValueNotifier<bool> mountSheet = ValueNotifier<bool>(true);
      addTearDown(mountSheet.dispose);
      int loadProfileCalls = 0;

      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: database,
          extra: [
            userSettingsViewModelProvider.overrideWith(
              () => _TestUserSettingsViewModel(
                initialState: const UserSettingsViewState(
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
                ),
                onLoadProfile: () => loadProfileCalls++,
              ),
            ),
            fluxerClientProvider.overrideWithValue(_UsersTestClient(usersApi)),
            gatewayConnectionProvider.overrideWithValue(gateway),
            authRepositoryProvider.overrideWithValue(authRepo),
            fluxerAuthTokenProvider.overrideWith(_SeededAuthTokenNotifier.new),
          ],
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrapWithApp(
          container,
          Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: mountSheet,
              builder: (_, bool mounted, _) => mounted
                  ? const UsernameClaimAccountSheet()
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      );

      final Finder fields = find.byType(EditableText);
      await tester.enterText(fields.at(0), 'trinity');
      await tester.enterText(fields.at(1), 'claim-pass-1');
      await tester.enterText(fields.at(2), 'claim-pass-1');
      await tester.pump();

      await tester.ensureVisible(find.text(testL10n.claimAccount));
      await tester.pump();
      await tester.tap(find.text(testL10n.claimAccount));
      await tester.pump();

      // Unmount the sheet while `updateCurrentUser` is in flight.
      mountSheet.value = false;
      await tester.pump();

      usersApi.claimCompleter.complete(
        UserUpdateResponse.fromJson(<String, Object?>{
          'id': kTestAccountUserId,
          'username': 'trinity',
          'discriminator': '0002',
          'token': 'claim-tok',
          'auth_session_id_hash': 'claim-hash',
        }),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(gateway.tokens, <String>['claim-tok']);
      expect(authRepo.persistedTokens, <String>['claim-tok']);
      expect(container.read(currentAuthSessionIdHashProvider), 'claim-hash');
      expect(loadProfileCalls, 1);
      expect(
        container.read(toastProvider).single.toast.message,
        testL10n.claimAccountSuccess,
      );
      expect(
        container.read(pendingRecoveryKitProvider)?.recoveryKey,
        'AAAA-BBBB-CCCC-DDDD-EEEE-FFFF-GGGG-HHHH',
      );
    },
  );

  testWidgets(
    'TotpEnableSheet and TotpDisableSheet dismissed mid-submit still show toasts, reload profile, and open BackupCodesSheet without StateError',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db.FluxerDatabase database = openTestDatabase();
      final _SlowUsersApi usersApi = _SlowUsersApi();
      final _SlowTotpDisableAdapter disableAdapter = _SlowTotpDisableAdapter();
      final Dio disableDio = Dio()..httpClientAdapter = disableAdapter;
      int loadProfileCalls = 0;

      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: database,
          extra: [
            userSettingsViewModelProvider.overrideWith(
              () => _TestUserSettingsViewModel(
                initialState: const UserSettingsViewState(
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
                ),
                onLoadProfile: () => loadProfileCalls++,
              ),
            ),
            fluxerClientProvider.overrideWithValue(_UsersTestClient(usersApi)),
            fluxerDioProvider.overrideWithValue(disableDio),
          ],
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrapWithApp(
          container,
          Scaffold(
            body: Consumer(
              builder: (BuildContext context, WidgetRef ref, _) => Column(
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () => TotpEnableSheet.show(context, ref),
                    child: const Text('Enable TOTP'),
                  ),
                  ElevatedButton(
                    onPressed: () => TotpDisableSheet.show(context, ref),
                    child: const Text('Disable TOTP'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // 1. TotpEnableSheet: submit -> dismiss sheet -> complete -> verify toast,
      // profile reload, and BackupCodesSheet shown on root navigator.
      await tester.tap(find.text('Enable TOTP'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find
            .descendant(
              of: find.byType(TotpEnableSheet),
              matching: find.byType(EditableText),
            )
            .last,
        '123456',
      );
      await tester.pump();
      final Finder continueButton = find.widgetWithText(
        FluxerButton,
        testL10n.continueAction,
      );
      await tester.ensureVisible(continueButton);
      await tester.pumpAndSettle();
      await tester.tap(continueButton);
      await tester.pump();

      Navigator.of(rootNavigatorKey.currentContext!).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(TotpEnableSheet), findsNothing);

      usersApi.totpEnableCompleter.complete(
        const MfaBackupCodesResponse(
          backupCodes: <MfaBackupCodesResponseBackupCodes>[
            MfaBackupCodesResponseBackupCodes(
              code: 'ABCD-EFGH',
              consumed: false,
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      expect(loadProfileCalls, 1);
      expect(
        container.read(toastProvider).last.toast.message,
        testL10n.totpEnableSuccess,
      );
      expect(find.byType(BackupCodesSheet), findsOneWidget);
      expect(find.text('ABCD-EFGH'), findsOneWidget);

      // Dismiss BackupCodesSheet so we can test TotpDisableSheet cleanly.
      Navigator.of(rootNavigatorKey.currentContext!).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 2. TotpDisableSheet: submit -> dismiss sheet -> complete -> verify toast
      // and profile reload.
      await tester.tap(find.text('Disable TOTP'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).first, '654321');
      await tester.pump();
      final Finder disableContinueButton = find.widgetWithText(
        FluxerButton,
        testL10n.continueAction,
      );
      await tester.ensureVisible(disableContinueButton);
      await tester.pumpAndSettle();
      await tester.tap(disableContinueButton);
      await tester.pump();
      await tester.pump();

      Navigator.of(rootNavigatorKey.currentContext!).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(TotpDisableSheet), findsNothing);

      disableAdapter.disableCompleter.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
      expect(loadProfileCalls, 2);
      expect(
        container.read(toastProvider).last.toast.message,
        testL10n.totpDisableSuccess,
      );
    },
  );
}
