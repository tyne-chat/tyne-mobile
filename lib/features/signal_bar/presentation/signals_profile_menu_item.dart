import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/signal_bar/presentation/signals_everywhere_sheet.dart';
import 'package:fluxer_app/features/signal_bar/providers/signal_bar_providers.dart';
import 'package:fluxer_app/features/ui/bottom_sheet/fluxer_bottom_sheet.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// "Signals" in the profile menu, after the status row: the same sheet as the
/// strip's globe, without an open chat. Shown while the account has a signal on
/// anywhere or Restore has something to put back.
class SignalsProfileMenuItem extends ConsumerWidget {
  const SignalsProfileMenuItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hasBar = ref.watch(
      signalBarConfigProvider.select((config) => config.signals.isNotEmpty),
    );
    final bool shown = ref.watch(
      mySignalsProvider.select(
        (MySignalsState state) =>
            (state.summary?.chats.isNotEmpty ?? false) ||
            (state.summary?.restoreAvailable ?? false),
      ),
    );
    if (!hasBar || !shown) {
      return const SizedBox.shrink();
    }
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    return FluxerBottomSheetMenuItem(
      key: const ValueKey<String>('signals-profile-menu-item'),
      label: l10n.fork.signalsProfileMenu,
      leading: PhosphorIcon(
        PhosphorIconsBold.globe,
        size: 20,
        color: context.colors.textPrimaryMuted,
      ),
      trailing: PhosphorIcon(
        PhosphorIconsBold.caretRight,
        size: 20,
        color: context.colors.textPrimaryMuted,
      ),
      onTap: () {
        final NavigatorState root = Navigator.of(context, rootNavigator: true);
        Navigator.of(context).pop();
        unawaited(SignalsEverywhereSheet.show(root.context));
      },
    );
  }
}
