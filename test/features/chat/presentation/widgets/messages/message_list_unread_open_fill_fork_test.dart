// Fork: tyne-chat/tyne#495. A channel opened at its NEW divider must not leave
// empty space below the newest message when nothing newer is left to load:
// not right after the open settles (the fill slop kept the divider at the
// middle up to 32 px short of the bottom), not when the last page lands, and
// not when a row below NEW gets shorter or the list grows taller (signal bar
// collapsed, keyboard closed), which nothing re-fitted.
@Tags(['slow'])
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/composer/wide_composer_layout.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/messages/message_list.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/messages/message_list_viewport.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';

import '../../../../../helpers/pump_fluxer_app.dart';
import 'message_list_test_harness.dart';

const double _kViewportHeight = 640;

/// Stands in for whatever shares the screen with the list below it (the
/// signal bar, the keyboard): the list gets the height it leaves.
class _BottomBarHost extends StatelessWidget {
  const _BottomBarHost({required this.barHeight});

  final ValueNotifier<double> barHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Expanded(
          child: MessageList(expectedChannelId: messageListChannelId),
        ),
        ValueListenableBuilder<double>(
          valueListenable: barHeight,
          builder: (BuildContext context, double height, Widget? _) =>
              SizedBox(height: height),
        ),
      ],
    );
  }
}

RenderViewport _listViewport(WidgetTester tester) =>
    tester.renderObject<RenderViewport>(
      find.descendant(
        of: messageListScrollable(),
        matching: find.byType(Viewport),
      ),
    );

/// The anchor the widget tree holds must match the one laid out: a rebuild
/// of the scroll view from a stale widget would put the old anchor back.
void _expectAnchorInSync(WidgetTester tester) {
  expect(
    tester
        .widget<MessageListViewport>(find.byType(MessageListViewport))
        .anchorFraction,
    moreOrLessEquals(_listViewport(tester).anchor, epsilon: 0.001),
    reason: 'MessageListViewport must carry the anchor the viewport uses',
  );
}

/// Opens once with plenty of room to measure what the unread rows take, then
/// returns a list height whose lower half is 16 px taller than that: inside
/// the 32 px slop that used to keep NEW at the middle.
Future<({double listHeight, double inset})> _slopListHeight(
  WidgetTester tester,
) async {
  final ValueNotifier<double> barHeight = ValueNotifier<double>(0);
  addTearDown(barHeight.dispose);
  final AroundAckMessageListHarness harness = await _pumpUnreadOpen(
    tester,
    barHeight: barHeight,
  );
  // The open fits exactly here, so everything below the anchor (the first
  // unread tile with its NEW divider, the rest, the inset) fills the list
  // below it.
  final RenderViewport fitted = _listViewport(tester);
  final double filledBelow = (1 - fitted.anchor) * fitted.size.height;
  final double inset = _bottomSpace(tester, harness.newestLoadedId);
  await disposeMessageList(tester);
  // One test database at a time: drift fails the test on a second one.
  await tester.runAsync(harness.database.close);
  return (listHeight: 2 * (filledBelow + 16), inset: inset);
}

/// Distance from the newest row's bottom to the list's bottom edge. At rest
/// at the bottom this is the list's own trailing inset and nothing more.
double _bottomSpace(WidgetTester tester, String newestId) {
  final Rect viewport = tester.getRect(messageListScrollable());
  return viewport.bottom - tester.getRect(messageItemFor(newestId)).bottom;
}

Future<AroundAckMessageListHarness> _pumpUnreadOpen(
  WidgetTester tester, {
  required ValueNotifier<double> barHeight,
}) async {
  // Two unread messages and nothing newer to load: they fill well under half
  // of the list, so the open must lower NEW until the newest sits at the
  // bottom.
  final AroundAckMessageListHarness harness =
      await createAroundAckMessageListHarness(
        ackIndex: 47,
        hasMoreNewerMessages: false,
      );
  await tester.pumpWidget(
    messageListApp(
      database: harness.database,
      chatViewModel: harness.chatViewModel,
      body: _BottomBarHost(barHeight: barHeight),
    ),
  );
  await pumpFluxerFrames(tester);
  expect(find.text('NEW'), findsOneWidget);
  expect(messageItemFor(harness.newestLoadedId), findsOneWidget);
  return harness;
}

void main() {
  testWidgets('a row below NEW that gets shorter after an unread open leaves '
      'no gap', (WidgetTester tester) async {
    configureMessageListViewport(tester);
    // On a phone the first unread row came out 16 px shorter once the window
    // reloaded. A row shrinking inside a list that fits on screen changes no
    // scroll metric, so only a check after the frame can see it.
    final AroundAckMessageListHarness harness =
        await createAroundAckMessageListHarness(
          ackIndex: 47,
          hasMoreNewerMessages: false,
          firstUnreadLines: 6,
        );
    await tester.pumpWidget(
      messageListApp(
        database: harness.database,
        chatViewModel: harness.chatViewModel,
      ),
    );
    await pumpFluxerFrames(tester);
    final double settled = _bottomSpace(tester, harness.newestLoadedId);
    final double tallHeight = tester
        .getRect(messageItemFor(harness.firstUnreadId))
        .height;

    final List<Message> window = harness.chatViewModel.testState.messages;
    harness.chatViewModel.testState = harness.chatViewModel.testState.copyWith(
      write: (
        messages: <Message>[
          for (final Message message in window)
            if (message.id == harness.firstUnreadId)
              harnessMessage(
                id: message.id,
                content: 'now one line',
                timestamp: message.timestamp,
              )
            else
              message,
        ],
        origin: MessagesOrigin.realtimeEvent,
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));

    expect(
      tester.getRect(messageItemFor(harness.firstUnreadId)).height,
      lessThan(tallHeight - 40),
      reason: 'the edit must make the first unread row shorter',
    );
    expect(find.text('NEW'), findsOneWidget);
    expect(
      _bottomSpace(tester, harness.newestLoadedId),
      moreOrLessEquals(settled, epsilon: 1),
      reason: 'the rows must still reach the bottom two frames later',
    );

    await disposeMessageList(tester);
  });

  testWidgets('the page that ends the window after an unread open fills the '
      'bottom within a frame or two', (WidgetTester tester) async {
    configureMessageListViewport(tester);
    // As on a phone's cold start: the list opens at NEW from a first page
    // that may have newer messages after it, and a moment later the newer
    // page lands with the last message and says there is nothing more.
    final AroundAckMessageListHarness harness =
        await createAroundAckMessageListHarness(ackIndex: 47);
    await tester.pumpWidget(
      messageListApp(
        database: harness.database,
        chatViewModel: harness.chatViewModel,
      ),
    );
    for (int frame = 0; frame < 3; frame += 1) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text('NEW'), findsOneWidget);

    final List<Message> window = harness.chatViewModel.testState.messages;
    final Message last = newerRows(window, count: 1, label: 'last').single;
    harness.chatViewModel.testState = harness.chatViewModel.testState.copyWith(
      write: (
        messages: <Message>[...window, last],
        origin: MessagesOrigin.newerPage,
      ),
      hasMoreNewerMessages: false,
    );
    final List<double> spaces = <double>[];
    for (int frame = 0; frame < 6; frame += 1) {
      await tester.pump(const Duration(milliseconds: 16));
      spaces.add(_bottomSpace(tester, last.id));
    }

    const double inset = WideComposerLayout.mobileMessageListTrailingInset;
    expect(find.text('NEW'), findsOneWidget);
    expect(
      spaces.skip(2),
      everyElement(moreOrLessEquals(inset, epsilon: 1)),
      reason: 'space below the newest per frame after the last page: $spaces',
    );
    await pumpFluxerFrames(tester);
    expect(_bottomSpace(tester, last.id), moreOrLessEquals(inset, epsilon: 1));

    await disposeMessageList(tester);
  });

  testWidgets('a list that grows after an unread open keeps the newest at the '
      'bottom', (WidgetTester tester) async {
    configureMessageListViewport(tester);
    final ValueNotifier<double> barHeight = ValueNotifier<double>(200);
    addTearDown(barHeight.dispose);
    final AroundAckMessageListHarness harness = await _pumpUnreadOpen(
      tester,
      barHeight: barHeight,
    );
    final double settled = _bottomSpace(tester, harness.newestLoadedId);

    barHeight.value = 0;
    await pumpFluxerFrames(tester);

    expect(find.text('NEW'), findsOneWidget);
    expect(
      _bottomSpace(tester, harness.newestLoadedId),
      moreOrLessEquals(settled, epsilon: 1),
      reason: 'the 200 px the list gained must not open a gap below the newest',
    );
    _expectAnchorInSync(tester);
    final ScrollPosition position = messageListScrollPosition(tester);
    expect(
      position.pixels,
      moreOrLessEquals(position.maxScrollExtent, epsilon: 1),
    );

    await disposeMessageList(tester);
  });

  testWidgets('an unread open that falls just short of half the list fills '
      'to the bottom', (WidgetTester tester) async {
    configureMessageListViewport(tester);
    final ({double listHeight, double inset}) slop = await _slopListHeight(
      tester,
    );
    final ValueNotifier<double> barHeight = ValueNotifier<double>(
      _kViewportHeight - slop.listHeight,
    );
    addTearDown(barHeight.dispose);
    final AroundAckMessageListHarness harness = await _pumpUnreadOpen(
      tester,
      barHeight: barHeight,
    );
    expect(
      tester.getRect(messageListScrollable()).height,
      moreOrLessEquals(slop.listHeight, epsilon: 1),
    );

    expect(
      _bottomSpace(tester, harness.newestLoadedId),
      moreOrLessEquals(slop.inset, epsilon: 1),
      reason: 'NEW 16 px short of the middle must not leave a 16 px gap',
    );
    _expectAnchorInSync(tester);

    await disposeMessageList(tester);
  });

  testWidgets('the first frame that shows an unread open has no gap', (
    WidgetTester tester,
  ) async {
    configureMessageListViewport(tester);
    // The list stays at opacity 0 while the open settles; the frame that shows
    // it must already have the rows at the bottom, not one frame later.
    final ({double listHeight, double inset}) slop = await _slopListHeight(
      tester,
    );
    final ValueNotifier<double> barHeight = ValueNotifier<double>(
      _kViewportHeight - slop.listHeight,
    );
    addTearDown(barHeight.dispose);
    final AroundAckMessageListHarness harness =
        await createAroundAckMessageListHarness(
          ackIndex: 47,
          hasMoreNewerMessages: false,
        );
    await tester.pumpWidget(
      messageListApp(
        database: harness.database,
        chatViewModel: harness.chatViewModel,
        body: _BottomBarHost(barHeight: barHeight),
      ),
    );
    // Hidden while settling: some Opacity above the list is at 0.
    bool hidden() =>
        messageListScrollable().evaluate().isNotEmpty &&
        tester
            .widgetList<Opacity>(
              find.ancestor(
                of: messageListScrollable(),
                matching: find.byType(Opacity),
              ),
            )
            .any((Opacity opacity) => opacity.opacity == 0);
    int frames = 0;
    bool wasHidden = hidden();
    while (!wasHidden || hidden()) {
      frames += 1;
      expect(frames, lessThan(30), reason: 'the unread open never showed');
      await tester.pump(const Duration(milliseconds: 16));
      wasHidden = wasHidden || hidden();
    }

    expect(find.text('NEW'), findsOneWidget);
    expect(
      _bottomSpace(tester, harness.newestLoadedId),
      moreOrLessEquals(slop.inset, epsilon: 1),
      reason: 'frame $frames, the first to show the list, has a gap',
    );

    await disposeMessageList(tester);
  });
}
