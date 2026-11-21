// Fork: removing a bookmark asks first, the way unpinning a message does
// (tyne-chat/tyne#742). Upstream removes it at once from the message's
// long-press menu and from a bookmark's long-press menu in the bookmarks list.
// The question is the sheet unpinning shows (`showUnpinMessageConfirmSheet`),
// with upstream's "Remove bookmark" as its title and button, and the web app
// asks the same. Each caller asks here and, when the answer is yes, goes on to
// upstream's own removal.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/ui/bottom_sheet/fluxer_bottom_sheet.dart';
import 'package:fluxer_app/features/ui/bottom_sheet/fluxer_confirm_sheet.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';

/// Asks whether to remove a bookmark. True only when the person confirmed and
/// [context] is still mounted, so the caller can go on with it.
Future<bool> confirmBookmarkRemoval(BuildContext context) async {
  final FluxerLocalizations l10n = FluxerLocalizations.of(context);
  final bool? confirmed = await FluxerConfirmSheet.show(
    context,
    title: l10n.chatMessageRemoveBookmark,
    description: l10n.fork.bookmarkRemoveConfirmDescription,
    confirmLabel: l10n.chatMessageRemoveBookmark,
    isDanger: true,
  );
  return (confirmed ?? false) && context.mounted;
}

/// The message menu's Bookmark action toggles: adding a bookmark goes ahead
/// without a question, removing one asks first, as Unpin there does.
Future<bool> confirmBookmarkRemovalIfSaved(
  BuildContext context,
  WidgetRef ref, {
  required String messageId,
}) async {
  final bool saved = await ref
      .read(fluxerDatabaseProvider)
      .savedMessageDao
      .isSaved(messageId);
  if (!context.mounted) {
    return false;
  }
  if (!saved) {
    return true;
  }
  return await confirmBookmarkRemoval(context);
}

/// From a bookmark's long-press menu, whose item calls its remove action and
/// then closes the menu in the same tap. The pins list asks once its menu has
/// closed; so does this: it lets the close run, lets the menu slide out
/// (`handOffFluxerSheet`, as the message menu's Forward does), then asks,
/// rather than opening the question on top of the menu.
Future<bool> confirmBookmarkRemovalFromMenu(BuildContext context) async {
  // The rest of the tap, the menu's close, runs before this continues.
  await Future<void>.value();
  if (!context.mounted) {
    return false;
  }
  await handOffFluxerSheet(context);
  if (!context.mounted) {
    return false;
  }
  return await confirmBookmarkRemoval(context);
}
