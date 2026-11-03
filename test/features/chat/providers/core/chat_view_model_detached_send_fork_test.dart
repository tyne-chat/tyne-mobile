// Fork: tyne-chat/tyne#212 (Android). A message sent while the list shows
// older history, not the newest messages, must not make that history count
// as the newest messages, or the messages in between are never loaded.
//
// The scenes follow the report of 2026-11-02 (1.2.14), with "Scroll to bottom
// when sending a message" off, as the reporter had it: the channel opened at
// the read mark, so the list held the page around it and the newer messages
// were still to load. The user replied to old messages from there. Later the
// list showed the replies straight after the page's last message, with the
// messages in between missing, and new messages arriving after them.
@Tags(['slow'])
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' hide Message;
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/settings/providers/preferences/advanced_preferences_provider.dart';

import '../../../../helpers/chat_view_model_pagination_test_harness.dart';
import '../../../../helpers/fork_message_gap_harness.dart';
import '../../../../helpers/open_test_database.dart';

const String _channelId = kGapChannelId;
const String _otherChannelId = kGapOtherChannelId;
const int _historyLength = kGapHistoryLength;

/// The last message the user had read. The channel opens on the page around
/// it: 24 older messages, the mark and 25 newer ones, so #26 to #75.
const int _readMark = 50;
const int _pageTail = 75;

typedef _Scene = ({
  FluxerDatabase db,
  GapServer server,
  ProviderContainer container,
  ChatViewModel notifier,
});

ChatViewState _state(_Scene scene) =>
    scene.container.read(chatViewModelProvider);

String _shape(_Scene scene) => gapListShape(_state(scene), scene.server);

String _complete(_Scene scene) => gapCompleteShape(scene.server);

Matcher _honest(_Scene scene) => gapHonestShape(scene.server);

/// What the pagination coordinator does while the list sits at its newer
/// edge: ask for newer pages until the list reaches the newest message.
Future<void> _scrollToEnd(_Scene scene) async {
  for (int i = 0; i < 5 && _state(scene).hasMoreNewerMessages; i++) {
    await scene.notifier.loadNewer();
    await paginationFlushAsync();
  }
}

String _historyId(int index) => gapHistoryId(index);

/// Opens the channel as the phone does after a night away: the server has
/// #0 to #99, READY has stored #99 as the channel's last message, and the
/// read mark is #50.
Future<_Scene> _openAtReadMark({bool scrollToBottomOnSend = false}) async {
  final FluxerDatabase db = openTestDatabase();
  await seedGapChannels(db);
  await _setReadMark(db, _historyId(_readMark));
  final GapServer server = GapServer();
  final ProviderContainer container = paginationContainer(db, server);
  addTearDown(container.dispose);
  await _setScrollToBottomOnSend(container, scrollToBottomOnSend);
  final ChatViewModel notifier = container.read(chatViewModelProvider.notifier);
  await notifier.switchChannel(_channelId);
  await paginationFlushAsync();
  return (db: db, server: server, container: container, notifier: notifier);
}

/// "Scroll to bottom when sending a message", kept in memory: the tests sign
/// in no user, so nothing is stored.
Future<void> _setScrollToBottomOnSend(
  ProviderContainer container,
  bool value,
) => container
    .read(advancedPreferencesProvider.notifier)
    .setScrollToBottomOnMessageSend(value: value);

Future<void> _setReadMark(FluxerDatabase db, String messageId) =>
    setGapReadMark(db, messageId);

/// What the gateway handler does with a MESSAGE_CREATE: store the row and
/// move the channel's last message, then hand it to the chat.
Future<void> _gatewayCreate(_Scene scene, Map<String, Object?> row) async {
  await storeGapCreate(scene.db, row);
  emitGapCreate(scene.container, row);
  await paginationFlushAsync();
}

/// Sends [text] from the list as it is, and lets the REST answer land.
Future<Map<String, Object?>> _reply(_Scene scene, String text) async {
  await scene.notifier.sendMessage(text: text);
  await paginationFlushAsync();
  return scene.server.history.last;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('opening at the read mark shows the page around it, with newer '
      'messages still to load', () async {
    final _Scene scene = await _openAtReadMark();

    expect(scene.server.requests, <String>['around #$_readMark']);
    expect(_state(scene).messages.first.id, _historyId(26));
    expect(_shape(scene), 'claims newest: false; gaps: []; last: #$_pageTail');
  });

  test(
    'control: scrolling down from there loads the messages in between',
    () async {
      final _Scene scene = await _openAtReadMark();

      await _scrollToEnd(scene);

      expect(scene.server.requests, <String>[
        'around #$_readMark',
        'after #$_pageTail',
      ]);
      expect(_shape(scene), _complete(scene));
    },
  );

  group('a reply sent from the page around the read mark', () {
    test('is not added to the page while newer messages are still to '
        'load', () async {
      final _Scene scene = await _openAtReadMark();

      final Map<String, Object?> sent = await _reply(scene, 'reply');
      await _gatewayCreate(scene, sent);

      // The reply (#100) is on the server and loads with the newer pages.
      expect(scene.server.requests.last, 'send');
      expect(
        _state(scene).messages.map((Message m) => m.id),
        isNot(contains(sent['id'])),
      );
      expect(_shape(scene), 'claims newest: false; gaps: []; last: #75');
    });

    test('loads in its place once scrolling down reaches it', () async {
      final _Scene scene = await _openAtReadMark();
      final Map<String, Object?> sent = await _reply(scene, 'reply');
      await _gatewayCreate(scene, sent);

      await _scrollToEnd(scene);

      expect(_state(scene).messages.last.id, sent['id']);
      expect(_shape(scene), _complete(scene));
    });

    test('that the server refuses is shown once newer messages load, with '
        'nothing missing', () async {
      final _Scene scene = await _openAtReadMark();
      scene.server.refusedSends = 1;

      await _reply(scene, 'refused');
      await _scrollToEnd(scene);

      expect(
        _state(scene).messages.where(
          (Message m) =>
              m.content == 'refused' &&
              m.deliveryState == MessageDeliveryState.failed,
        ),
        hasLength(1),
      );
      expect(_shape(scene), _complete(scene));
    });

    test('with "scroll to bottom" on but no jump, its delivery takes it out '
        'of the page again', () async {
      final _Scene scene = await _openAtReadMark(scrollToBottomOnSend: true);

      final Map<String, Object?> sent = await _reply(scene, 'reply');
      await _gatewayCreate(scene, sent);

      expect(
        _state(scene).messages.map((Message m) => m.id),
        isNot(contains(sent['id'])),
      );
      await _scrollToEnd(scene);
      expect(_shape(scene), _complete(scene));
    });

    test('with "scroll to bottom" on, a gateway echo that arrives before the '
        'send is answered also takes it out', () async {
      final _Scene scene = await _openAtReadMark(scrollToBottomOnSend: true);
      scene.server.sendHold = Completer<void>();

      await scene.notifier.sendMessage(text: 'reply');
      await paginationFlushAsync();
      final Map<String, Object?> sent = scene.server.history.last;
      await _gatewayCreate(scene, sent);
      scene.server.sendHold!.complete();
      await paginationFlushAsync();

      expect(
        _state(scene).messages.map((Message m) => m.id),
        isNot(contains(sent['id'])),
      );
      await _scrollToEnd(scene);
      expect(_shape(scene), _complete(scene));
    });

    test('then scrolling down loads the messages in between '
        '(gateway echo stored first)', () async {
      final _Scene scene = await _openAtReadMark();
      final Map<String, Object?> sent = await _reply(scene, 'reply');
      await _gatewayCreate(scene, sent);

      await _scrollToEnd(scene);

      expect(_shape(scene), _complete(scene));
      expect(scene.server.requests.skip(2).first, 'after #$_pageTail');
    });

    test('then scrolling down loads the messages in between '
        '(gateway echo not stored yet)', () async {
      final _Scene scene = await _openAtReadMark();
      await _reply(scene, 'reply');

      await _scrollToEnd(scene);

      expect(_shape(scene), _complete(scene));
      expect(scene.server.requests.skip(2).first, 'after #$_pageTail');
    });

    test('then a resync (foreground return, READY) keeps the list '
        'detached', () async {
      final _Scene scene = await _openAtReadMark();
      final Map<String, Object?> sent = await _reply(scene, 'reply');
      await _gatewayCreate(scene, sent);

      await scene.notifier.refreshAfterSessionRecovery();
      await paginationFlushAsync();

      expect(_shape(scene), _honest(scene));
    });

    test('then a new message from someone else after scrolling down lands '
        'after the messages in between', () async {
      final _Scene scene = await _openAtReadMark();
      final Map<String, Object?> sent = await _reply(scene, 'reply');
      await _gatewayCreate(scene, sent);
      await _scrollToEnd(scene);

      final Map<String, Object?> live = scene.server.post(authorId: 'other');
      await _gatewayCreate(scene, live);

      expect(_shape(scene), _complete(scene));
    });
  });

  group('reopening the channel after replying from the page', () {
    // The replies in the report that are missing from the list. Before
    // tyne-chat/tyne#466 (fixed after 1.2.15), the read mark for the user's
    // own messages stayed in memory and never reached the database, so the
    // channel still counted as unread with its mark at #50.
    test('with the read mark left at #50 (1.2.14): the page around the mark '
        'again, without the replies', () async {
      final _Scene scene = await _openAtReadMark();
      final Map<String, Object?> first = await _reply(scene, 'first');
      await _gatewayCreate(scene, first);
      final Map<String, Object?> second = await _reply(scene, 'second');
      await _gatewayCreate(scene, second);

      await scene.notifier.switchChannel(_otherChannelId);
      await paginationFlushAsync();
      scene.server.requests.clear();
      await scene.notifier.switchChannel(_channelId);
      await paginationFlushAsync();

      expect(scene.server.requests, <String>['around #$_readMark']);
      expect(
        _state(scene).messages.map((Message m) => m.id),
        isNot(anyOf(contains(first['id']), contains(second['id']))),
      );
      expect(
        _shape(scene),
        'claims newest: false; gaps: []; last: #$_pageTail',
      );
    });

    test('with the read mark left at #50: the next reply, scrolling down and '
        'a new message from someone else leave no gap', () async {
      final _Scene scene = await _openAtReadMark();
      final Map<String, Object?> first = await _reply(scene, 'first');
      await _gatewayCreate(scene, first);
      await scene.notifier.switchChannel(_otherChannelId);
      await paginationFlushAsync();
      await scene.notifier.switchChannel(_channelId);
      await paginationFlushAsync();

      final Map<String, Object?> next = await _reply(scene, 'next');
      await _gatewayCreate(scene, next);
      await _scrollToEnd(scene);
      final Map<String, Object?> live = scene.server.post(authorId: 'other');
      await _gatewayCreate(scene, live);

      expect(_shape(scene), _complete(scene));
    });

    test('with the read mark at the reply (since tyne#466): the list does not '
        'claim the cached rows reach the newest message', () async {
      final _Scene scene = await _openAtReadMark();
      final Map<String, Object?> sent = await _reply(scene, 'reply');
      await _gatewayCreate(scene, sent);
      await _setReadMark(scene.db, sent['id']! as String);

      await scene.notifier.switchChannel(_otherChannelId);
      await paginationFlushAsync();
      scene.server.requests.clear();
      await scene.notifier.switchChannel(_channelId);
      await paginationFlushAsync();

      expect(_shape(scene), _honest(scene));
    });

    test('after an app restart, the cached rows ending in the reply are not '
        'taken for the newest messages', () async {
      final _Scene scene = await _openAtReadMark();
      final Map<String, Object?> sent = await _reply(scene, 'reply');
      await _gatewayCreate(scene, sent);
      await _setReadMark(scene.db, sent['id']! as String);
      scene.container.dispose();

      final ProviderContainer restarted = paginationContainer(
        scene.db,
        scene.server,
      );
      addTearDown(restarted.dispose);
      final _Scene after = (
        db: scene.db,
        server: scene.server,
        container: restarted,
        notifier: restarted.read(chatViewModelProvider.notifier),
      );
      scene.server.requests.clear();
      await after.notifier.switchChannel(_channelId);
      await paginationFlushAsync();

      expect(_shape(after), _honest(after));
    });
  });

  group('after marking an old message unread and restarting the app', () {
    // Chiara's repro of 2026-11-02, with "Scroll to bottom when sending a
    // message" on: scroll far up, mark a message unread, swipe the app away,
    // start it again and send. The list does not move and the gap appears.

    /// Opens at the newest messages, scrolls up to #0, marks #20 unread and
    /// starts the app again: the channel opens on the page around the mark.
    Future<_Scene> restartAfterMarkingUnread({
      bool scrollToBottomOnSend = false,
    }) async {
      final _Scene first = await _openAtReadMark();
      await _setReadMark(first.db, _historyId(_historyLength - 1));
      await first.notifier.switchChannel(_otherChannelId);
      await paginationFlushAsync();
      await first.notifier.switchChannel(_channelId);
      await paginationFlushAsync();
      for (int i = 0; i < 3 && _state(first).hasMoreMessages; i++) {
        await first.notifier.loadMore();
        await paginationFlushAsync();
      }
      expect(_state(first).messages.first.id, _historyId(0));
      await first.notifier.markMessageUnread(_historyId(20));
      await paginationFlushAsync();
      first.container.dispose();

      final ProviderContainer restarted = paginationContainer(
        first.db,
        first.server,
      );
      addTearDown(restarted.dispose);
      await _setScrollToBottomOnSend(restarted, scrollToBottomOnSend);
      final _Scene scene = (
        db: first.db,
        server: first.server,
        container: restarted,
        notifier: restarted.read(chatViewModelProvider.notifier),
      );
      first.server.requests.clear();
      await scene.notifier.switchChannel(_channelId);
      await paginationFlushAsync();
      return scene;
    }

    test('the channel opens on the page around the mark, newer messages '
        'still to load', () async {
      final _Scene scene = await restartAfterMarkingUnread();

      expect(scene.server.requests.first, 'around #19');
      expect(_shape(scene), 'claims newest: false; gaps: []; last: #44');
    });

    test('with "scroll to bottom" on, a send asks the list to scroll to the '
        'bottom', () async {
      final _Scene scene = await restartAfterMarkingUnread(
        scrollToBottomOnSend: true,
      );
      final int before = _state(scene).scrollToBottomSignal;

      await scene.notifier.sendMessage(text: 'reply');

      expect(_state(scene).scrollToBottomSignal, before + 1);
      await paginationFlushAsync();
    });

    test('jumping to the newest messages right after the send, as the list '
        'does when asked to scroll to the bottom, leaves no gap', () async {
      final _Scene scene = await restartAfterMarkingUnread(
        scrollToBottomOnSend: true,
      );

      await scene.notifier.sendMessage(text: 'reply');
      final bool started = await scene.notifier.jumpToLatestMessages();
      await paginationFlushAsync();
      await _gatewayCreate(scene, scene.server.history.last);

      expect(started, isTrue);
      expect(_shape(scene), _complete(scene));
    });

    test('with "scroll to bottom" off, scrolling down after the send leaves no '
        'gap', () async {
      final _Scene scene = await restartAfterMarkingUnread();

      final Map<String, Object?> sent = await _reply(scene, 'reply');
      await _gatewayCreate(scene, sent);
      await _scrollToEnd(scene);

      expect(_shape(scene), _complete(scene));
    });
  });
}
