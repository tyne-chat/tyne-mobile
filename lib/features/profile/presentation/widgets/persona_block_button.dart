// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: Block or Unblock beside Message on a persona's profile
// (tyne-chat/tyne#921), which the persona gallery opens too. It asks first, as
// blocking an account does (`user_profile_actions_sheet.dart`): a danger
// confirmation to block, a plain one to unblock. One request each, never
// retried; a failure shows a toast.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_app/features/chat/utils/messages/fork_blocked_persona.dart';
import 'package:fluxer_app/features/profile/presentation/sheets/user_profile_confirmation_sheet.dart';
import 'package:fluxer_app/features/profile/providers/persona_blocks_provider.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button_variant.dart';
import 'package:fluxer_app/features/ui/toast/fluxer_toast.dart';
import 'package:fluxer_app/features/ui/toast/toast_provider.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/shared/icons/phosphor.dart';

class PersonaBlockButton extends ConsumerWidget {
  const PersonaBlockButton({
    required this.userId,
    required this.personaId,
    required this.personaName,
    required this.ownerName,
    super.key,
  });

  final String userId;
  final String personaId;
  final String personaName;
  final String ownerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final bool isBlocked = ref
        .watch(blockedPersonaKeysProvider)
        .contains(personaBlockKey(userId, personaId));
    return FluxerButton.secondary(
      label: isBlocked
          ? l10n.fork.personaUnblockButton
          : l10n.fork.personaBlockButton,
      icon: PhosphorIconsFill.prohibit,
      onPressedAsync: () => _toggle(context, ref, isBlocked),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    bool isBlocked,
  ) async {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    // Read before the awaits: the profile may close while the sheet is open.
    final PersonaBlocksNotifier blocks = ref.read(
      blockedPersonaKeysProvider.notifier,
    );
    final Toast toast = ref.read(toastProvider.notifier);
    final bool confirmed = isBlocked
        ? await UserProfileConfirmationSheet.show(
            context,
            title: l10n.fork.personaUnblockConfirmTitle,
            description: l10n.fork.personaUnblockConfirmDescription(
              personaName,
            ),
            primaryLabel: l10n.fork.personaUnblockButton,
            primaryVariant: FluxerButtonVariant.primary,
          )
        : await UserProfileConfirmationSheet.show(
            context,
            title: l10n.fork.personaBlockConfirmTitle,
            description: l10n.fork.personaBlockConfirmDescription(
              personaName,
              ownerName,
            ),
            primaryLabel: l10n.fork.personaBlockButton,
            primaryVariant: FluxerButtonVariant.dangerPrimary,
          );
    if (!confirmed) {
      return;
    }
    try {
      if (isBlocked) {
        await blocks.unblock(userId, personaId);
      } else {
        await blocks.block(userId, personaId);
      }
    } on Object catch (err, st) {
      talker.warning(
        '[PersonaBlockButton] Failed to change the block: $err',
        err,
        st,
      );
      toast.show(
        FluxerToast(
          message: isBlocked
              ? l10n.fork.personaUnblockFailed
              : l10n.fork.personaBlockFailed,
          variant: FluxerToastVariant.danger,
        ),
      );
    }
  }
}
