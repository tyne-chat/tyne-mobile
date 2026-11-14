// Fork: tyne-chat/tyne#199. A jump inside the open channel loads the page
// around its target. The server fills that page with up to 25 newer messages,
// the target and up to 24 older ones, and does not make up for a short side.
// Only the older side says whether older messages remain: a page that is
// short because the target is near the newest message is not the start of the
// channel. The list test next to the message list shows this from a tapped
// notification; these cover the rule and the jump to the first unread message.
@Tags(['slow'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/features/chat/domain/pagination_pump_policy.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/messages/message_list_unread_review.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';

import '../../../../helpers/chat_view_model_pagination_test_harness.dart';
import '../../../../helpers/fork_message_gap_harness.dart';
import '../../../../helpers/open_test_database.dart';

bool _showsChannelStart(ChatViewState state) => shouldShowChannelWelcome(
  hasMoreOlderMessages: state.hasMoreMessages,
  messageLoadFailed: state.messageLoadFailed,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<({ProviderContainer container, GapServer server, FluxerDatabase db})>
  open(int historyLength) async {
    final FluxerDatabase db = openTestDatabase();
    await seedGapChannels(db, historyLength: historyLength);
    final GapServer server = GapServer(historyLength: historyLength);
    final ProviderContainer container = paginationContainer(db, server);
    addTearDown(container.dispose);
    await container
        .read(chatViewModelProvider.notifier)
        .switchChannel(kGapChannelId);
    await paginationFlushAsync();
    return (container: container, server: server, db: db);
  }

  int indexOf(GapServer server, String id) => server.historyIds.indexOf(id);

  // Each case: messages that arrive unseen after the channel was opened with
  // 350, and how far below the newest of them the jump's target is.
  for (final ({int unseen, int belowNewest, int window}) c
      in <({int unseen, int belowNewest, int window})>[
        (unseen: 1, belowNewest: 0, window: 25),
        (unseen: 30, belowNewest: 0, window: 25),
        (unseen: 40, belowNewest: 10, window: 35),
        (unseen: 60, belowNewest: 24, window: 49),
        (unseen: 80, belowNewest: 30, window: 50),
      ]) {
    test('a jump to a message ${c.belowNewest} below the newest, with '
        '${c.unseen} unseen, keeps older history reachable', () async {
      final setup = await open(350);
      final ChatViewModel notifier = setup.container.read(
        chatViewModelProvider.notifier,
      );
      for (int i = 0; i < c.unseen; i++) {
        setup.server.post(authorId: 'other');
      }
      final String target = setup
          .server
          .historyIds[setup.server.history.length - 1 - c.belowNewest];

      await notifier.goToRepliedMessage(
        channelId: kGapChannelId,
        messageId: target,
      );
      await paginationFlushAsync();

      ChatViewState state = setup.container.read(chatViewModelProvider);
      expect(state.messages, hasLength(c.window));
      expect(state.messages.map((m) => m.id), contains(target));
      expect(state.hasMoreMessages, isTrue);
      expect(_showsChannelStart(state), isFalse);

      final int oldest = indexOf(setup.server, state.messages.first.id);
      final int requests = setup.server.requests.length;
      final PageLoadResult older = await notifier.loadMore();
      await paginationFlushAsync();

      expect(older.status, PageLoadStatus.applied);
      expect(setup.server.requests.skip(requests), <String>['before #$oldest']);
      state = setup.container.read(chatViewModelProvider);
      expect(indexOf(setup.server, state.messages.first.id), oldest - 50);
      expect(gapsInList(state, setup.server), isEmpty);
    });
  }

  test('a jump whose page reaches the first message shows the start of the '
      'channel and asks for nothing older', () async {
    final setup = await open(80);
    final ChatViewModel notifier = setup.container.read(
      chatViewModelProvider.notifier,
    );

    await notifier.goToRepliedMessage(
      channelId: kGapChannelId,
      messageId: gapHistoryId(5),
    );
    await paginationFlushAsync();

    final ChatViewState state = setup.container.read(chatViewModelProvider);
    expect(indexOf(setup.server, state.messages.first.id), 0);
    expect(state.hasMoreMessages, isFalse);
    expect(_showsChannelStart(state), isTrue);
    final int requests = setup.server.requests.length;
    expect((await notifier.loadMore()).status, PageLoadStatus.skipped);
    expect(setup.server.requests, hasLength(requests));
  });

  test('a jump whose page holds exactly the 24 oldest messages below its '
      'target finds the start with one more request', () async {
    final setup = await open(120);
    final ChatViewModel notifier = setup.container.read(
      chatViewModelProvider.notifier,
    );

    await notifier.goToRepliedMessage(
      channelId: kGapChannelId,
      messageId: gapHistoryId(24),
    );
    await paginationFlushAsync();

    ChatViewState state = setup.container.read(chatViewModelProvider);
    expect(indexOf(setup.server, state.messages.first.id), 0);
    expect(state.hasMoreMessages, isTrue, reason: 'a full older side');
    final int requests = setup.server.requests.length;
    await notifier.loadMore();
    await paginationFlushAsync();
    state = setup.container.read(chatViewModelProvider);
    expect(setup.server.requests.skip(requests), <String>['before #0']);
    expect(state.hasMoreMessages, isFalse);
    expect(_showsChannelStart(state), isTrue);
  });

  test('the jump to the first unread message keeps older history reachable '
      'when few messages are unread', () async {
    final setup = await open(1000);
    final ChatViewModel notifier = setup.container.read(
      chatViewModelProvider.notifier,
    );
    // The list is deep in history, as after following a link there.
    await notifier.goToRepliedMessage(
      channelId: kGapChannelId,
      messageId: gapHistoryId(100),
    );
    await paginationFlushAsync();
    // Everything up to #990 is read; nine messages are not.
    await setGapReadMark(setup.db, gapHistoryId(990));

    await notifier.jumpToFirstUnread();
    await paginationFlushAsync();

    final ChatViewState state = setup.container.read(chatViewModelProvider);
    expect(setup.server.requests.last, 'around #990');
    expect(indexOf(setup.server, state.messages.first.id), 966);
    expect(state.hasMoreMessages, isTrue);
    expect(_showsChannelStart(state), isFalse);
    final PageLoadResult older = await notifier.loadMore();
    await paginationFlushAsync();
    expect(older.status, PageLoadStatus.applied);
  });
}
