// Fork: tests the fork adds, kept out of upstream's dm_list_test.dart so that file stays as
// upstream has it.
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/dm/domain/dm_conversation.dart';
import 'package:fluxer_app/features/friends/domain/friend.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'dm_list_test.dart' hide main;

void main() {
  group('DMList mobile', () {
    testWidgets(
      'opens the quick switcher sheet from the mobile quick switcher FAB',
      (tester) async {
        forkUpstream.setMobileSurface(tester);

        await tester.pumpWidget(
          forkUpstream.buildTestApp(
            overrides: forkUpstream.buildOverrides(
              conversations: [
                DmConversation(
                  id: '100',
                  type: 1,
                  recipientId: '200',
                  recipientName: 'Monty',
                  lastMessage: 'Hi there',
                  lastMessageTime: forkUpstream.recentTime(),
                ),
              ],
              friendsList: const [
                Friend(
                  id: '300',
                  username: 'bob',
                  globalName: 'Bob Builder',
                  friendStatus: FriendStatus.accepted,
                  status: 'online',
                ),
              ],
            ),
          ),
        );
        await tester.pump();

        final fabFinder = find.byKey(
          const ValueKey<String>('quick-switcher-fab'),
        );
        expect(fabFinder, findsOneWidget);
        expect(find.byIcon(PhosphorIconsFill.lightning), findsOneWidget);

        await tester.tap(fabFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.text('Search for channels, people, or communities'),
          findsOneWidget,
        );
        expect(find.text('Search'), findsWidgets);
        expect(find.text('Friends'), findsWidgets);
      },
    );
  });
}
