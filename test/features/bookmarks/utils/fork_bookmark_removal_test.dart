// Root ProviderScope built by a helper; the lint only exempts a
// ProviderScope written inline in pumpWidget.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart'
    show FluxerDatabase;
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/bookmarks/utils/fork_bookmark_removal.dart';
import 'package:fluxer_app/features/notifications/presentation/widgets/mention_inbox_card.dart';
import 'package:fluxer_app/features/ui/bottom_sheet/fluxer_bottom_sheet.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';

import '../../../helpers/open_test_database.dart';
import '../../../helpers/pump_fluxer_app.dart';
import '../../../helpers/test_l10n.dart';

// Removing a bookmark asks first, as unpinning a message does
// (tyne-chat/tyne#742).
void main() {
  const String messageId = 'msg-1';

  Finder question() =>
      find.text(testL10n.fork.bookmarkRemoveConfirmDescription);
  Finder removeButton() =>
      find.widgetWithText(FluxerButton, testL10n.chatMessageRemoveBookmark);

  Future<({BuildContext context, WidgetRef ref})> pumpHarness(
    WidgetTester tester,
    FluxerDatabase database,
  ) async {
    late BuildContext capturedContext;
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      pumpFluxerApp(
        overrides: [fluxerDatabaseProvider.overrideWithValue(database)],
        child: Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? child) {
            capturedContext = context;
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ),
    );
    return (context: capturedContext, ref: capturedRef);
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('the message menu adds a bookmark without asking', (
    tester,
  ) async {
    final FluxerDatabase database = openTestDatabase();
    final harness = await pumpHarness(tester, database);

    final bool goAhead = await confirmBookmarkRemovalIfSaved(
      harness.context,
      harness.ref,
      messageId: messageId,
    );
    await tester.pumpAndSettle();

    expect(goAhead, isTrue);
    expect(question(), findsNothing);
    await unmount(tester);
  });

  testWidgets(
    'removing a bookmark from the message menu asks first; Back keeps it',
    (tester) async {
      final FluxerDatabase database = openTestDatabase();
      await database.savedMessageDao.addSavedMessage(messageId);
      final harness = await pumpHarness(tester, database);

      final Future<bool> answer = confirmBookmarkRemovalIfSaved(
        harness.context,
        harness.ref,
        messageId: messageId,
      );
      await tester.pumpAndSettle();
      expect(question(), findsOneWidget);
      expect(removeButton(), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(question(), findsNothing);
      expect(await answer, isFalse);
      expect(await database.savedMessageDao.isSaved(messageId), isTrue);
      await unmount(tester);
    },
  );

  testWidgets('confirming lets the message menu go on to remove it', (
    tester,
  ) async {
    final FluxerDatabase database = openTestDatabase();
    await database.savedMessageDao.addSavedMessage(messageId);
    final harness = await pumpHarness(tester, database);

    final Future<bool> answer = confirmBookmarkRemovalIfSaved(
      harness.context,
      harness.ref,
      messageId: messageId,
    );
    await tester.pumpAndSettle();
    await tester.tap(removeButton());
    await tester.pumpAndSettle();

    expect(await answer, isTrue);
    expect(question(), findsNothing);
    await unmount(tester);
  });

  testWidgets(
    "a bookmark's long-press menu closes, then asks, and only a yes goes on",
    (tester) async {
      final FluxerDatabase database = openTestDatabase();
      final List<Future<bool>> answers = <Future<bool>>[];
      await tester.pumpWidget(
        pumpFluxerApp(
          overrides: [fluxerDatabaseProvider.overrideWithValue(database)],
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              return MentionInboxCard(
                messageId: messageId,
                message: null,
                header: null,
                previewGuildId: null,
                title: MentionInboxCardTitle.plain,
                removeLabel: testL10n.savedMessagesRemoveTooltip,
                onJump: (_) {},
                onRemove: (_) =>
                    answers.add(confirmBookmarkRemovalFromMenu(context)),
              );
            },
          ),
        ),
      );

      Future<void> openMenuAndRemove() async {
        await tester.longPress(find.byType(MentionInboxCard));
        await tester.pumpAndSettle();
        expect(find.byType(FluxerBottomSheetMenuItem), findsOneWidget);
        await tester.tap(find.byType(FluxerBottomSheetMenuItem));
        await tester.pumpAndSettle();
        // The menu has gone and the question stands on its own.
        expect(find.byType(FluxerBottomSheetMenuItem), findsNothing);
        expect(question(), findsOneWidget);
      }

      await openMenuAndRemove();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(question(), findsNothing);
      expect(await answers.single, isFalse);

      await openMenuAndRemove();
      await tester.tap(removeButton());
      await tester.pumpAndSettle();
      expect(question(), findsNothing);
      expect(await answers.last, isTrue);
      await unmount(tester);
    },
  );
}
