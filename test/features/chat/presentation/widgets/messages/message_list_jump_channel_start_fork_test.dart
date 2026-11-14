// Fork: tyne-chat/tyne#199. The app sits in the background on a channel,
// messages arrive, and the reader taps the notification of the newest one.
// The channel is still the open one, so the app jumps inside it: it loads the
// page around that message, which is short because nothing newer exists. The
// app read the short page as the start of the channel and showed its
// start-of-channel header 24 messages above the notified one, with the rest
// of the history out of reach.
//
// This runs the real list and the real chat, starts the jump from a
// notification's payload as the tap handler does, and uses a server that
// builds the page around a message the way the real one does.
@Tags(['slow'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/push/notification/path_resolver.dart';
import 'package:fluxer_app/core/utils/channel_jump_link.dart';
import 'package:fluxer_app/features/chat/utils/channel_jump_navigator.dart';

import '../../../../../helpers/fork_message_gap_harness.dart';
import 'fork_message_list_scenario.dart';

// The header sits above the oldest loaded message, usually out of view:
// slivers out of view count as offstage to a finder.
final Finder _channelStart = find.byKey(
  const ValueKey<String>('channel-welcome-section'),
  skipOffstage: false,
);

/// What the tap handler and the deep link handler do with a tapped message
/// notification: payload to path, path to link, link to a jump.
Future<void> _tapNotification(
  WidgetTester tester,
  ForkListScenario s,
  String messageId,
) async {
  final String path = resolvePushNotificationPath(<String, String>{
    'guild_id': 'guild-1',
    'channel_id': kGapChannelId,
    'message_id': messageId,
  })!;
  final ChannelJumpLink link = channelJumpLinkFromPathSegments(
    Uri.parse(path).pathSegments,
  )!;
  await tester.runAsync(
    () => navigateToChannelJumpLink(container: s.container, link: link),
  );
  await settleForkList(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('after tapping the notification of the newest message in the '
      'open channel, scrolling up loads older messages', (
    WidgetTester tester,
  ) async {
    final ForkListScenario s = await openForkListScenario(
      tester,
      historyLength: 300,
    );
    expect(s.oldestLoaded, 250);

    // In the background: three messages the app does not hear about.
    for (int i = 0; i < 3; i++) {
      s.server.post(authorId: 'other');
    }
    final String notified = s.server.historyIds.last;

    await _tapNotification(tester, s, notified);

    expect(s.server.requests, contains('around #302'));
    expect(s.state.messages.map((m) => m.id), contains(notified));
    expect(s.oldestLoaded, 278, reason: 'the server sends 24 older messages');
    expect(
      _channelStart,
      findsNothing,
      reason: '278 older messages are on the server',
    );

    // The reader scrolls up, past the 24 messages, and the next page arrives.
    s.server.holdBeforeFetch = true;
    await flingForkListToEnd(tester, towardOlder: true);
    expect(s.server.requests.last, 'before #278');
    await landForkOlderPage(tester, s);

    expect(s.oldestLoaded, 228);
    expect(gapsInList(s.state, s.server), isEmpty);
    expect(_channelStart, findsNothing);
    await closeForkListScenario(tester);
  });

  testWidgets('a jump that does reach the first message shows the start of '
      'the channel, without asking for more', (WidgetTester tester) async {
    final ForkListScenario s = await openForkListScenario(
      tester,
      historyLength: 80,
    );
    expect(s.oldestLoaded, 30);

    await _tapNotification(tester, s, gapHistoryId(5));

    expect(s.server.requests, contains('around #5'));
    expect(s.oldestLoaded, 0);
    expect(_channelStart, findsOneWidget);
    final int requests = s.server.requests.length;
    await flingForkListToEnd(tester, towardOlder: true);
    await settleForkList(tester);
    expect(
      s.server.requests.skip(requests).where((r) => r.startsWith('before')),
      isEmpty,
    );
    await closeForkListScenario(tester);
  });
}
