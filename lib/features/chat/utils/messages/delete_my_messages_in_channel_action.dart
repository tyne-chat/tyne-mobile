import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_dart/export.dart';

Future<void> confirmAndDeleteMyMessagesInChannel(
  BuildContext context,
  WidgetRef ref, {
  required String channelId,
  required bool isPrivateConversation,
}) async {
  final FluxerLocalizations l10n = FluxerLocalizations.of(context);
  final String title = isPrivateConversation
      ? l10n.dmDeleteMyMessagesTitle
      : l10n.channelMenuDeleteMyMessagesTitle;
  final String description = isPrivateConversation
      ? l10n.dmDeleteMyMessagesDescription
      : l10n.channelMenuDeleteMyMessagesDescription;
  // Fork: pre-capture container before modal/API awaits so leaving the channel
  // mid-delete still reloads/toasts instead of throwing StateError into the
  // error toast handler (tyne-chat/tyne#946).
  final ProviderContainer container = ref.container;
  final bool? confirmed = await FluxerConfirmModal.show(
    context,
    title: title,
    description: description,
    confirmLabel: l10n.channelMenuDeleteMyMessagesConfirm,
    isDanger: true,
    onConfirm: () {},
  );
  if (confirmed != true) {
    return;
  }
  final toast = container.read(toastProvider.notifier);
  try {
    await container
        .read(fluxerClientProvider)
        .channels
        .bulkDeleteMyMessagesInChannel(
          channelId: channelId,
          body: const SudoVerificationSchema(),
        );
    if (container.read(chatViewModelProvider).channelId == channelId) {
      await container
          .read(chatViewModelProvider.notifier)
          .reloadCurrentChannel();
    }
    toast.show(
      FluxerToast(
        message: l10n.channelMenuDeletedYourMessages,
        variant: FluxerToastVariant.success,
      ),
    );
  } on Object {
    toast.show(
      FluxerToast(
        message: l10n.channelMenuCouldNotDeleteYourMessages,
        variant: FluxerToastVariant.danger,
      ),
    );
  }
}
