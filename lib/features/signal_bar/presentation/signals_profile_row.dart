import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/signal_bar/presentation/signals_everywhere_sheet.dart';
import 'package:fluxer_app/features/ui/list/fluxer_list_row.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// "Signals" on your own profile, under "Personas (N)": how many chats have
/// your signals on, and the same sheet as the strip's globe, without an open
/// chat. The caller shows it as `watchSignalsProfileEntryShown` says.
class SignalsProfileRow extends ConsumerWidget {
  const SignalsProfileRow({super.key});

  static const double _iconSize = 40;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final int? count = ref.watch(knownSignalChatIdsProvider)?.length;
    return FluxerListRow(
      key: const ValueKey<String>('signals-profile-row'),
      leading: Container(
        width: _iconSize,
        height: _iconSize,
        decoration: BoxDecoration(
          color: context.colors.backgroundTertiary,
          borderRadius: BorderRadius.circular(_iconSize / 2),
        ),
        child: Center(
          child: PhosphorIcon(
            PhosphorIconsFill.globe,
            size: _iconSize / 2,
            color: context.colors.textPrimaryMuted,
          ),
        ),
      ),
      title: l10n.fork.signalsProfileMenu,
      subtitle: count == null
          ? null
          : l10n.fork.signalsEverywhereTooltip(count),
      trailing: const PhosphorIcon(PhosphorIconsBold.caretRight, size: 18),
      onTap: () => unawaited(SignalsEverywhereSheet.show(context)),
    );
  }
}
