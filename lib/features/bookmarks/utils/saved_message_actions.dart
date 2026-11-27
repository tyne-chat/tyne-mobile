import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/limits/instance_limit_provider.dart';
import 'package:fluxer_app/core/limits/limit_key.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/bookmarks/data/saved_messages_repository.dart';
import 'package:fluxer_app/features/bookmarks/providers/saved_messages_provider.dart';
import 'package:fluxer_app/features/ui/toast/fluxer_toast.dart';
import 'package:fluxer_app/features/ui/toast/toast_provider.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/shared/utils/api_error_presentation.dart';

Future<void> toggleSavedMessageBookmark({
  required WidgetRef ref,
  required FluxerLocalizations l10n,
  required String channelId,
  required String messageId,
}) async {
  // Fork: pre-capture container before `await` / optimistic list removal so an
  // unmounted row never throws StateError on toast/error (tyne-chat/tyne#946).
  final ProviderContainer container = ref.container;
  final SavedMessagesRepository repository = container.read(
    savedMessagesRepositoryProvider,
  );
  if (await container
      .read(fluxerDatabaseProvider)
      .savedMessageDao
      .isSaved(messageId)) {
    await _unsaveMessageBookmarkInContainer(
      container: container,
      l10n: l10n,
      messageId: messageId,
    );
    return;
  }
  try {
    await repository.saveMessage(channelId: channelId, messageId: messageId);
  } on Object catch (error) {
    await _showBookmarkError(container, error);
    return;
  }
  _showBookmarkToast(container, l10n, added: true);
}

Future<void> unsaveMessageBookmark({
  required WidgetRef ref,
  required FluxerLocalizations l10n,
  required String messageId,
}) => _unsaveMessageBookmarkInContainer(
  container: ref.container,
  l10n: l10n,
  messageId: messageId,
);

Future<void> _unsaveMessageBookmarkInContainer({
  required ProviderContainer container,
  required FluxerLocalizations l10n,
  required String messageId,
}) async {
  container.read(savedMessagesProvider.notifier).handleMessageDelete(messageId);
  try {
    await container
        .read(savedMessagesRepositoryProvider)
        .unsaveMessage(messageId);
  } on Object catch (error) {
    await _showBookmarkError(container, error);
    return;
  }
  _showBookmarkToast(container, l10n, added: false);
}

Future<void> _showBookmarkError(ProviderContainer container, Object error) {
  return showApiErrorFromRoot(
    ApiErrorAction.saveBookmark,
    error,
    details: ApiErrorDetails(
      count: container.read(instanceLimitProvider(LimitKeys.maxBookmarks)),
    ),
  );
}

void _showBookmarkToast(
  ProviderContainer container,
  FluxerLocalizations l10n, {
  required bool added,
}) {
  container
      .read(toastProvider.notifier)
      .show(
        FluxerToast(
          message: added
              ? l10n.savedMessagesAddedToast
              : l10n.savedMessagesRemovedToast,
          variant: FluxerToastVariant.success,
        ),
      );
}
