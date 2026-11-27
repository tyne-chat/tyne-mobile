// Fork: tyne-chat/tyne#946 — regression test for AccountSwitcherSheet closing
// before switchToAccount completes and throwing StateError when displaying the
// failure toast.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/auth/domain/auth_failure.dart';
import 'package:fluxer_app/features/auth/domain/stored_account.dart';
import 'package:fluxer_app/features/auth/presentation/sheets/account_switcher_sheet.dart';
import 'package:fluxer_app/features/auth/providers/account_manager_provider.dart';
import 'package:fluxer_app/features/ui/toast/toast_provider.dart';
import 'package:fluxer_app/material_ui.dart';

import '../../../../helpers/core_test_provider_overrides.dart';
import '../../../../helpers/instance_runtime_config_override.dart';
import '../../../../helpers/test_l10n.dart';

class _SlowFailingAccountManager extends AccountManager {
  final Completer<void> switchCompleter = Completer<void>();
  final List<String> attemptedUserIds = <String>[];

  @override
  AccountManagerState build() {
    return const AccountManagerState(
      accounts: <StoredAccount>[
        StoredAccount(
          userId: 'user-1',
          isValid: true,
          username: 'alice',
          mediaBaseUrl: 'https://fluxerusercontent.com',
        ),
        StoredAccount(
          userId: 'user-2',
          isValid: true,
          username: 'bob',
          mediaBaseUrl: 'https://fluxerusercontent.com',
        ),
      ],
      isSwitching: false,
    );
  }

  @override
  Future<void> switchToAccount(
    String userId, {
    bool ignoreIfPending = false,
  }) async {
    attemptedUserIds.add(userId);
    await switchCompleter.future;
  }
}

void main() {
  testWidgets(
    'failing switchToAccount after AccountSwitcherSheet closes shows error toast without StateError',
    (WidgetTester tester) async {
      final _SlowFailingAccountManager manager = _SlowFailingAccountManager();
      final ProviderContainer container = ProviderContainer(
        overrides: mergeProviderOverrides([
          instanceRuntimeConfigOverride(),
          currentUserIdProvider.overrideWithValue('user-1'),
          accountManagerProvider.overrideWith(() => manager),
        ]),
      );
      addTearDown(container.dispose);

      final colorTheme = buildDarkColorTheme();
      await tester.pumpWidget(
        UncontrolledProviderScope(
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
            home: Scaffold(
              body: Builder(
                builder: (BuildContext context) => Center(
                  child: ElevatedButton(
                    onPressed: () => AccountSwitcherSheet.show(context),
                    child: const Text('Switch Accounts'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Switch Accounts'));
      await tester.pumpAndSettle();
      expect(find.byType(AccountSwitcherSheetBody), findsOneWidget);

      // Tap the second account ('bob'). `_handleSelectAccount` immediately
      // invokes `onClose()`, popping and unmounting `AccountSwitcherSheetBody`
      // while `switchToAccount` is still awaiting network validation.
      await tester.tap(find.text('bob'));
      await tester.pumpAndSettle();
      expect(find.byType(AccountSwitcherSheetBody), findsNothing);
      expect(manager.attemptedUserIds, <String>['user-2']);

      // Now network validation fails with a non-session-expired error.
      manager.switchCompleter.completeError(
        const AuthFailure('Network unreachable'),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      final List<ToastEntry> toasts = container.read(toastProvider);
      expect(toasts, hasLength(1));
      expect(toasts.single.toast.message, testL10n.accountSwitchFailed);
    },
  );
}
