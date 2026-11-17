// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: Open DM on a Discord import placeholder's profile, in the place of
// Message, when you have an imported conversation with it
// (tyne-chat/tyne#696). Nobody is behind a placeholder, so it opens the
// history only: the server reopens that DM and refuses any other.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:fluxer_app/features/profile/presentation/widgets/user_profile_action_card_row.dart';
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
  if (!_hasImportedConversation(ref, userId)) {
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
    if (!imported || !_hasImportedConversation(ref, userId)) {
      return const SizedBox.shrink();
    }
    // Upstream's card, as Message and a blocked user's Open DM have it (Gemini
    // Carbon's review): its "blocked" only names the card Open DM.
    return UserProfileActionCardRow(
      isCurrentUser: false,
      isFriend: false,
      isBlocked: true,
      canCall: false,
      onMessage: () async => onOpen(),
      onVoiceCall: () async {},
      onVideoCall: () async {},
      onEditProfile: () {},
    );
  }
}

/// A persona profile's Open DM, for a persona of the placeholder with
/// [userId], where Message is for anyone else's (Gemini Carbon's review).
class ImportedConversationPersonaButton extends ConsumerWidget {
  const ImportedConversationPersonaButton({
    required this.userId,
    required this.onOpen,
    super.key,
  });

  final String userId;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_hasImportedConversation(ref, userId)) {
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

/// Whether there is an imported conversation to open: never asked, and none,
/// where the instance has DMs off.
bool _hasImportedConversation(WidgetRef ref, String userId) {
  if (ref.watch(
    instanceRuntimeConfigProvider.select(
      (config) => config.directMessagesDisabled,
    ),
  )) {
    return false;
  }
  return ref.watch(importedConversationProvider(userId)).value != null;
}
