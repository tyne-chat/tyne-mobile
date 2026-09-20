import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/ui/bottom_sheet/fluxer_bottom_sheet.dart';
import 'package:fluxer_app/material_ui.dart';

import 'fluxer_bottom_sheet_test.dart' hide main;

// tyne-chat/tyne#173 (audit F9-1): a sheet with unsaved changes is not dismissed by a drag, but the
// content's own close() closes it, as after a successful save.
void main() {
  Widget opener(void Function(BuildContext context) open) => buildTestApp(
    Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => open(context),
        child: const Text('Open'),
      ),
    ),
  );

  Widget closeButton(VoidCallback close) =>
      TextButton(onPressed: close, child: const Text('Done'));

  testWidgets('close() from the content closes a sheet that cannot be '
      'dismissed', (tester) async {
    final canDismiss = ValueNotifier<bool>(true);
    addTearDown(canDismiss.dispose);
    await tester.pumpWidget(
      opener(
        (context) => unawaited(
          FluxerBottomSheet.show<void>(
            context,
            title: 'Unsaved',
            canDismissNotifier: canDismiss,
            builder: (context, close) => closeButton(close),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    canDismiss.value = false;
    await tester.pumpAndSettle();

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Unsaved'), findsNothing);
  });

  testWidgets('close() from the content closes a scrollable sheet that cannot '
      'be dismissed', (tester) async {
    final canDismiss = ValueNotifier<bool>(true);
    addTearDown(canDismiss.dispose);
    await tester.pumpWidget(
      opener(
        (context) => unawaited(
          FluxerBottomSheet.showScrollable<void>(
            context,
            title: 'Unsaved',
            canDismissNotifier: canDismiss,
            builder: (context, scrollController, close) => ListView(
              controller: scrollController,
              shrinkWrap: true,
              children: <Widget>[closeButton(close)],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    canDismiss.value = false;
    await tester.pumpAndSettle();

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Unsaved'), findsNothing);
  });

  for (final dismissible in <bool>[true, false]) {
    testWidgets('a drag down ${dismissible ? 'dismisses' : 'does not dismiss'} '
        'a sheet whose canDismissNotifier is $dismissible', (tester) async {
      final canDismiss = ValueNotifier<bool>(dismissible);
      addTearDown(canDismiss.dispose);
      await tester.pumpWidget(
        opener(
          (context) => unawaited(
            FluxerBottomSheet.show<void>(
              context,
              title: 'Unsaved',
              canDismissNotifier: canDismiss,
              builder: (context, close) => closeButton(close),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.fling(find.text('Unsaved'), const Offset(0, 500), 3000);
      await tester.pumpAndSettle();

      expect(find.text('Unsaved'), dismissible ? findsNothing : findsOneWidget);
    });
  }
}
