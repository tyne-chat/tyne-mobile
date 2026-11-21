// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/updater/app_update_provider.dart';
import 'package:fluxer_app/features/ui/toast/fluxer_toast.dart';
import 'package:fluxer_app/features/ui/toast/toast_provider.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';

/// Answers "Check for updates" once the check ends: up to date, or it failed
/// (as does a download that fails after it). Only for a check someone asked
/// for: the one at start-up says nothing unless it finds a release.
///
/// The shell calls it from its update listener, which phones and wide layouts
/// both have, so each answer shows once (tyne-chat/tyne#352).
void toastManualUpdateCheck(
  WidgetRef ref,
  FluxerLocalizations l10n,
  AppUpdateState? previous,
  AppUpdateState next,
) {
  if (!next.isManualCheck || next.status == previous?.status) {
    return;
  }
  final FluxerToast? toast = switch (next.status) {
    AppUpdateStatus.upToDate => FluxerToast(
      message: l10n.fork.userSettingsAppUpToDate,
      variant: FluxerToastVariant.success,
    ),
    AppUpdateStatus.error => FluxerToast(
      message: l10n.fork.userSettingsUpdateFailed,
      variant: FluxerToastVariant.danger,
    ),
    _ => null,
  };
  if (toast != null) {
    ref.read(toastProvider.notifier).show(toast);
  }
}
