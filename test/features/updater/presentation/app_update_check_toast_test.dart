// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/updater/app_update_provider.dart';
import 'package:fluxer_app/features/ui/toast/fluxer_toast.dart';
import 'package:fluxer_app/features/ui/toast/toast_provider.dart';
import 'package:fluxer_app/features/updater/presentation/app_update_check_toast.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';

import '../../../helpers/pump_fluxer_app.dart';
import '../../../helpers/test_l10n.dart';

const AppUpdateState _checking = AppUpdateState(
  status: AppUpdateStatus.checking,
  isManualCheck: true,
);

// tyne-chat/tyne#352: the answer to "Check for updates", from the shell's
// listener in both layouts.
void main() {
  late WidgetRef capturedRef;

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      pumpFluxerApp(
        child: Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? child) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ),
    );
  }

  List<FluxerToast> toasts() => <FluxerToast>[
    for (final ToastEntry entry in capturedRef.read(toastProvider)) entry.toast,
  ];

  Future<void> letToastsExpire(WidgetTester tester) =>
      tester.pump(const Duration(seconds: 5));

  testWidgets('a check someone asked for that finds nothing newer says so', (
    tester,
  ) async {
    await pump(tester);

    toastManualUpdateCheck(
      capturedRef,
      testL10n,
      _checking,
      _checking.copyWith(status: AppUpdateStatus.upToDate),
    );

    expect(toasts().single.message, testL10n.fork.userSettingsAppUpToDate);
    expect(toasts().single.variant, FluxerToastVariant.success);
    await letToastsExpire(tester);
  });

  testWidgets('a check someone asked for that fails says so', (tester) async {
    await pump(tester);

    toastManualUpdateCheck(
      capturedRef,
      testL10n,
      _checking,
      _checking.copyWith(status: AppUpdateStatus.error),
    );

    expect(toasts().single.message, testL10n.fork.userSettingsUpdateFailed);
    expect(toasts().single.variant, FluxerToastVariant.danger);
    await letToastsExpire(tester);
  });

  testWidgets('the check at start-up says nothing', (tester) async {
    await pump(tester);
    const AppUpdateState automatic = AppUpdateState(
      status: AppUpdateStatus.checking,
    );

    for (final AppUpdateStatus status in <AppUpdateStatus>[
      AppUpdateStatus.upToDate,
      AppUpdateStatus.error,
    ]) {
      toastManualUpdateCheck(
        capturedRef,
        testL10n,
        automatic,
        automatic.copyWith(status: status),
      );
    }

    expect(toasts(), isEmpty);
  });

  testWidgets('says nothing while checking, on a release, or twice', (
    tester,
  ) async {
    await pump(tester);
    final AppUpdateState upToDate = _checking.copyWith(
      status: AppUpdateStatus.upToDate,
    );

    toastManualUpdateCheck(capturedRef, testL10n, null, _checking);
    toastManualUpdateCheck(
      capturedRef,
      testL10n,
      _checking,
      _checking.copyWith(status: AppUpdateStatus.available),
    );
    toastManualUpdateCheck(capturedRef, testL10n, upToDate, upToDate);

    expect(toasts(), isEmpty);
  });
}
