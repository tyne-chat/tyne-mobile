// Fork: tyne-chat/tyne#633. A reader who scrolls toward older messages
// faster than pages arrive ends on the loading skeleton above the oldest
// loaded message. The list holds at most 400 messages and makes room by
// keeping those around the rows on screen; with only skeleton on screen it
// kept everything, stayed full, and asked for nothing more: the skeleton
// stayed for good, until the reader scrolled back down to the messages.
//
// These run the real list and the real chat against a server whose pages
// arrive when the test lets them, which is how a slow connection looks from
// the app: the reader reaches the end of the skeleton first.
@Tags(['slow'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/domain/message_window.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/messages/message_item.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/messages/message_list_viewport.dart';

import '../../../../../helpers/fork_message_gap_harness.dart';
import 'fork_message_list_scenario.dart';
import 'message_list_test_harness.dart'
    show
        messageListNewestRowOffset,
        messageListOldestRowOffset,
        messageListScrollPosition,
        messageListScrollable;

/// The reader keeps flinging to the top of the skeleton while pages arrive
/// behind them, until the list is full.
Future<void> _outrunOlderPagesUntilFull(
  WidgetTester tester,
  ForkListScenario s,
) async {
  s.server.holdBeforeFetch = true;
  for (
    int i = 0;
    i < 12 && s.state.messages.length < kMaxLoadedMessagesHard;
    i++
  ) {
    await flingForkListToEnd(tester, towardOlder: true);
    if (s.server.beforeFetchHeld) {
      await landForkOlderPage(tester, s);
    }
  }
  expect(
    s.state.messages.length,
    greaterThanOrEqualTo(kMaxLoadedMessagesHard),
    reason: 'the scenario needs a full list',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a reader who outruns paging to the top of the skeleton keeps '
      'getting older messages', (WidgetTester tester) async {
    final ForkListScenario s = await openForkListScenario(
      tester,
      historyLength: 1000,
    );
    final ScrollPosition position = messageListScrollPosition(tester);
    await _outrunOlderPagesUntilFull(tester, s);
    final int oldestWhenFull = s.oldestLoaded;
    final int requestsWhenFull = s.server.requests.length;

    // One more fling to the top of the skeleton, and the reader lets go.
    await flingForkListToEnd(tester, towardOlder: true);
    expect(forkListShowsMessages(tester), isFalse);

    expect(
      s.state.messages.length,
      lessThanOrEqualTo(kMaxLoadedMessages),
      reason: 'with only skeleton on screen the list still has to make room',
    );
    expect(
      s.oldestLoaded,
      oldestWhenFull,
      reason: 'the room is made at the far end, not where the reader is going',
    );
    expect(s.state.hasMoreNewerMessages, isTrue);
    expect(gapsInList(s.state, s.server), isEmpty);
    expect(
      messageListOldestRowOffset(tester) - position.pixels,
      moreOrLessEquals(
        messageListOldestRowOffset(tester) - position.minScrollExtent,
        epsilon: 1,
      ),
      reason: 'the reader is still at the top of the skeleton',
    );
    expect(
      s.server.requests.last,
      'before #$oldestWhenFull',
      reason: 'paging goes on from the oldest loaded message',
    );

    // The reader waits. Pages arrive until messages are on screen.
    for (int i = 0; i < 8 && !forkListShowsMessages(tester); i++) {
      if (s.server.beforeFetchHeld) {
        await landForkOlderPage(tester, s);
      }
      await settleForkList(tester);
    }
    expect(
      forkListShowsMessages(tester),
      isTrue,
      reason: 'the skeleton must give way to messages',
    );
    expect(gapsInList(s.state, s.server), isEmpty);
    expect(s.oldestLoaded, lessThan(oldestWhenFull));

    // One request per page, each for the page before the last.
    final List<String> after = s.server.requests
        .skip(requestsWhenFull)
        .toList();
    expect(after.toSet(), hasLength(after.length), reason: '$after');
    expect(after.length, lessThanOrEqualTo(6), reason: '$after');
    expect(after.every((String r) => r.startsWith('before #')), isTrue);
    await closeForkListScenario(tester);
  });

  testWidgets('making room with only skeleton on screen keeps the reader '
      'where they are in the skeleton', (WidgetTester tester) async {
    final ForkListScenario s = await openForkListScenario(
      tester,
      historyLength: 1000,
    );
    final ScrollPosition position = messageListScrollPosition(tester);
    // One page short of full, at the top of the skeleton.
    s.server.holdBeforeFetch = true;
    for (
      int i = 0;
      i < 12 && s.state.messages.length < kMaxLoadedMessagesHard - 50;
      i++
    ) {
      await flingForkListToEnd(tester, towardOlder: true);
      if (s.server.beforeFetchHeld) {
        await landForkOlderPage(tester, s);
      }
    }
    await flingForkListToEnd(tester, towardOlder: true);
    expect(s.state.messages.length, kMaxLoadedMessagesHard - 50);

    // A finger goes down and stays down while the last page arrives, moves
    // slowly to the middle of the skeleton, rests, and lifts without a fling.
    final TestGesture finger = await tester.startGesture(
      tester.getCenter(messageListScrollable()),
    );
    await finger.moveBy(const Offset(0, 30));
    await tester.pump(const Duration(milliseconds: 16));
    await landForkOlderPage(tester, s);
    expect(s.state.messages.length, kMaxLoadedMessagesHard);
    for (int i = 0; i < 20; i++) {
      await finger.moveBy(const Offset(0, 60));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.byType(MessageItem),
      findsNothing,
      reason: 'no message row is laid out, on screen or near it',
    );
    final double before = messageListOldestRowOffset(tester) - position.pixels;
    expect(before, greaterThan(position.viewportDimension * 2));
    expect(
      position.pixels - position.minScrollExtent,
      greaterThan(position.viewportDimension),
      reason: 'the reader is in the middle of the skeleton, not at its top',
    );

    await finger.up();
    await settleForkList(tester, rounds: 6);

    expect(s.state.messages.length, lessThanOrEqualTo(kMaxLoadedMessages));
    expect(
      messageListOldestRowOffset(tester) - position.pixels,
      moreOrLessEquals(before, epsilon: 1),
      reason: 'the skeleton is where it was under the reader',
    );
    expect(forkListShowsMessages(tester), isFalse);
    await closeForkListScenario(tester);
  });

  testWidgets('a slow page still lands after the list made room while idle '
      'on the skeleton', (WidgetTester tester) async {
    final ForkListScenario s = await openForkListScenario(
      tester,
      historyLength: 1000,
    );
    // Over the soft limit, under the hard one, at the top of the skeleton,
    // with the next page on its way.
    s.server.holdBeforeFetch = true;
    for (
      int i = 0;
      i < 12 && s.state.messages.length <= kMaxLoadedMessages;
      i++
    ) {
      await flingForkListToEnd(tester, towardOlder: true);
      if (s.server.beforeFetchHeld) {
        await landForkOlderPage(tester, s);
      }
    }
    await flingForkListToEnd(tester, towardOlder: true);
    expect(s.state.messages.length, greaterThan(kMaxLoadedMessages));
    expect(s.state.messages.length, lessThan(kMaxLoadedMessagesHard));
    expect(s.server.beforeFetchHeld, isTrue);
    expect(forkListShowsMessages(tester), isFalse);
    final int oldest = s.oldestLoaded;
    final int requests = s.server.requests.length;

    // The reader does nothing for longer than the list waits before it
    // makes room.
    await tester.pump(const Duration(milliseconds: 2100));
    await settleForkList(tester, rounds: 6);
    expect(s.state.messages.length, lessThanOrEqualTo(kMaxLoadedMessages));
    expect(s.oldestLoaded, oldest);
    expect(
      s.server.requests,
      hasLength(requests),
      reason: 'the page already asked for is not asked for again',
    );

    await landForkOlderPage(tester, s);
    expect(s.oldestLoaded, lessThan(oldest), reason: 'the slow page lands');
    expect(gapsInList(s.state, s.server), isEmpty);
    await closeForkListScenario(tester);
  });

  testWidgets('a reader who stops on the skeleton before the list has '
      'anything to trim gets messages before it is full', (
    WidgetTester tester,
  ) async {
    final ForkListScenario s = await openForkListScenario(
      tester,
      historyLength: 1000,
    );
    // Exactly at the soft limit, at the top of the skeleton: the scroll end
    // arms no trim, and from here on the reader does not touch the screen.
    s.server.holdBeforeFetch = true;
    for (
      int i = 0;
      i < 12 && s.state.messages.length < kMaxLoadedMessages;
      i++
    ) {
      await flingForkListToEnd(tester, towardOlder: true);
      if (s.server.beforeFetchHeld) {
        await landForkOlderPage(tester, s);
      }
    }
    await flingForkListToEnd(tester, towardOlder: true);
    expect(s.state.messages.length, kMaxLoadedMessages);
    expect(forkListShowsMessages(tester), isFalse);

    for (int i = 0; i < 8 && !forkListShowsMessages(tester); i++) {
      if (s.server.beforeFetchHeld) {
        await landForkOlderPage(tester, s);
      }
      await settleForkList(tester);
    }

    expect(forkListShowsMessages(tester), isTrue);
    expect(
      s.state.messages.length,
      lessThan(kMaxLoadedMessagesHard),
      reason: 'pages reach the reader before the list is full',
    );
    await closeForkListScenario(tester);
  });

  testWidgets('making room on the skeleton after an open at NEW leaves that '
      'layout and keeps the skeleton in place', (WidgetTester tester) async {
    // Nine unread messages: the channel opens at its NEW bar.
    final ForkListScenario s = await openForkListScenario(
      tester,
      historyLength: 1000,
      beforeOpen: (database) => setGapReadMark(database, gapHistoryId(990)),
    );
    final ScrollPosition position = messageListScrollPosition(tester);
    MessageListViewport viewport() =>
        tester.widget<MessageListViewport>(find.byType(MessageListViewport));
    expect(
      viewport().liveLeadingPad,
      isNotNull,
      reason: 'the scenario needs the layout of an open at NEW',
    );

    s.server.holdBeforeFetch = true;
    for (
      int i = 0;
      i < 12 && s.state.messages.length < kMaxLoadedMessagesHard - 50;
      i++
    ) {
      await flingForkListToEnd(tester, towardOlder: true);
      if (s.server.beforeFetchHeld) {
        await landForkOlderPage(tester, s);
      }
    }
    await flingForkListToEnd(tester, towardOlder: true);
    expect(s.state.messages.length, lessThan(kMaxLoadedMessagesHard));
    final TestGesture finger = await tester.startGesture(
      tester.getCenter(messageListScrollable()),
    );
    await finger.moveBy(const Offset(0, 30));
    await tester.pump(const Duration(milliseconds: 16));
    for (
      int i = 0;
      i < 3 && s.state.messages.length < kMaxLoadedMessagesHard;
      i++
    ) {
      await landForkOlderPage(tester, s);
    }
    expect(
      s.state.messages.length,
      greaterThanOrEqualTo(kMaxLoadedMessagesHard),
    );
    for (int i = 0; i < 20; i++) {
      await finger.moveBy(const Offset(0, 60));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(MessageItem), findsNothing);
    expect(viewport().liveLeadingPad, isNotNull);
    final double before = messageListOldestRowOffset(tester) - position.pixels;

    await finger.up();
    await settleForkList(tester, rounds: 6);

    expect(s.state.messages.length, lessThanOrEqualTo(kMaxLoadedMessages));
    expect(
      viewport().liveLeadingPad,
      isNull,
      reason: 'the layout of the open at NEW ended with its anchor',
    );
    expect(
      messageListOldestRowOffset(tester) - position.pixels,
      moreOrLessEquals(before, epsilon: 1),
      reason: 'the skeleton is where it was under the reader',
    );
    expect(gapsInList(s.state, s.server), isEmpty);
    await closeForkListScenario(tester);
  });

  testWidgets('a reader who outruns paging to the bottom of the newer '
      'skeleton keeps getting newer messages', (WidgetTester tester) async {
    final ForkListScenario s = await openForkListScenario(
      tester,
      historyLength: 1000,
    );
    final ScrollPosition position = messageListScrollPosition(tester);
    // A page deep in history, as after following a link to an old message.
    await tester.runAsync(
      () => s.chat.goToRepliedMessage(
        channelId: kGapChannelId,
        messageId: gapHistoryId(100),
      ),
    );
    await settleForkList(tester);
    expect(s.state.hasMoreNewerMessages, isTrue);

    s.server.holdAfterFetch = true;
    for (
      int i = 0;
      i < 12 && s.state.messages.length < kMaxLoadedMessagesHard;
      i++
    ) {
      await flingForkListToEnd(tester, towardOlder: false);
      if (s.server.afterFetchHeld) {
        await landForkNewerPage(tester, s);
      }
    }
    expect(
      s.state.messages.length,
      greaterThanOrEqualTo(kMaxLoadedMessagesHard),
    );
    final int newestWhenFull = s.newestLoaded;
    final int requestsWhenFull = s.server.requests.length;

    await flingForkListToEnd(tester, towardOlder: false);
    expect(forkListShowsMessages(tester), isFalse);

    expect(s.state.messages.length, lessThanOrEqualTo(kMaxLoadedMessages));
    expect(s.newestLoaded, newestWhenFull);
    expect(s.state.hasMoreMessages, isTrue);
    expect(gapsInList(s.state, s.server), isEmpty);
    expect(
      position.pixels - messageListNewestRowOffset(tester),
      moreOrLessEquals(
        position.maxScrollExtent - messageListNewestRowOffset(tester),
        epsilon: 1,
      ),
      reason: 'the reader is still at the bottom of the skeleton',
    );
    expect(s.server.requests.last, 'after #$newestWhenFull');

    for (int i = 0; i < 8 && !forkListShowsMessages(tester); i++) {
      if (s.server.afterFetchHeld) {
        await landForkNewerPage(tester, s);
      }
      await settleForkList(tester);
    }
    expect(forkListShowsMessages(tester), isTrue);
    expect(gapsInList(s.state, s.server), isEmpty);
    expect(s.newestLoaded, greaterThan(newestWhenFull));
    final List<String> after = s.server.requests
        .skip(requestsWhenFull)
        .toList();
    expect(after.toSet(), hasLength(after.length), reason: '$after');
    expect(after.length, lessThanOrEqualTo(6), reason: '$after');
    await closeForkListScenario(tester);
  });
}
