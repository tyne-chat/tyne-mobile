// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: Open DM on a Discord import placeholder's profile, in the place of
// Message, when you have an imported conversation with it
// (tyne-chat/tyne#696). Nobody is behind a placeholder, so it opens the
// history only: the server reopens that DM and refuses any other.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/features/profile/providers/imported_conversation_provider.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/icons/phosphor.dart';

/// The profile popout's footer for the placeholder with [userId]: Open DM
/// when there is an imported conversation, else none. Call it from a build.
Widget? importedConversationFooter(
  BuildContext context,
  WidgetRef ref, {
  required String userId,
  required VoidCallback onOpen,
}) {
  if (ref.watch(importedConversationProvider(userId)).value == null) {
    return null;
  }
  return FluxerButton.primary(
    label: FluxerLocalizations.of(context).userProfileOpenDm,
    icon: PhosphorIconsFill.chatTeardrop,
    size: FluxerButtonSize.small,
    onPressed: onOpen,
  );
}

/// The full profile's action for a placeholder ([imported]), where the
/// Message card is for anyone else; nothing for anyone else.
class ImportedConversationAction extends ConsumerWidget {
  const ImportedConversationAction({
    required this.userId,
    required this.imported,
    required this.onOpen,
    super.key,
  });

  final String userId;
  final bool imported;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!imported ||
        ref.watch(importedConversationProvider(userId)).value == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: double.infinity,
      child: FluxerButton.primary(
        label: FluxerLocalizations.of(context).userProfileOpenDm,
        icon: PhosphorIconsFill.chatTeardrop,
        onPressed: onOpen,
      ),
    );
  }
}
