// Fork: tyne-chat/tyne#940. Tests the reaction concurrency failure behind
// optimistic reactions vanishing when a channel refresh GET races PUT /reactions.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' hide Message;
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';

import '../../../../helpers/chat_view_model_pagination_test_harness.dart';
import '../../../../helpers/fork_message_gap_harness.dart';
import '../../../../helpers/open_test_database.dart';

class _ReactionRaceGapServer extends GapServer {
  bool holdNextMessageGet = false;
  bool holdNextReactionPut = false;
  bool failNextReactionPut = false;
  Completer<void>? _getStartedCompleter;
  Completer<void>? _getReleaseCompleter;
  Completer<void>? _putStartedCompleter;
  Completer<void>? _putReleaseCompleter;

  bool get messageGetHeld => _getReleaseCompleter != null;

  bool get reactionPutHeld => _putReleaseCompleter != null;

  Future<void> waitForHeldMessageGet() =>
      (_getStartedCompleter ??= Completer<void>()).future;

  Future<void> waitForHeldReactionPut() =>
      (_putStartedCompleter ??= Completer<void>()).future;

  void releaseMessageGet() {
    holdNextMessageGet = false;
    final Completer<void>? release = _getReleaseCompleter;
    _getReleaseCompleter = null;
    _getStartedCompleter = null;
    if (release != null && !release.isCompleted) {
      release.complete();
    }
  }

  void releaseReactionPut() {
    holdNextReactionPut = false;
    final Completer<void>? release = _putReleaseCompleter;
    _putReleaseCompleter = null;
    _putStartedCompleter = null;
    if (release != null && !release.isCompleted) {
      release.complete();
    }
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final String path = options.uri.path;
    final RegExpMatch? reactionToggle = RegExp(
      r'/channels/([^/]+)/messages/([^/]+)/reactions/([^/]+)/@me$',
    ).firstMatch(path);
    if ((options.method == 'PUT' || options.method == 'DELETE') &&
        reactionToggle != null) {
      final String messageId = reactionToggle.group(2)!;
      final String emoji = Uri.decodeComponent(reactionToggle.group(3)!);
      requests.add(
        '${options.method.toLowerCase()}Reaction #${historyIds.indexOf(messageId)}',
      );
      if (options.method == 'PUT' && holdNextReactionPut) {
        holdNextReactionPut = false;
        final Completer<void> started = _putStartedCompleter ??=
            Completer<void>();
        if (!started.isCompleted) {
          started.complete();
        }
        await (_putReleaseCompleter ??= Completer<void>()).future;
      }
      if (options.method == 'PUT' && failNextReactionPut) {
        failNextReactionPut = false;
        return ResponseBody.fromString(
          jsonEncode(<String, Object?>{'message': 'server error'}),
          500,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>['application/json'],
          },
        );
      }
      if (options.method == 'PUT') {
        _addReactionOnServer(messageId: messageId, emojiName: emoji);
      } else {
        _removeOwnReactionOnServer(messageId: messageId, emojiName: emoji);
      }
      return ResponseBody.fromString('', 204, statusMessage: 'No Content');
    }

    final RegExpMatch? clearAll = RegExp(
      r'/channels/([^/]+)/messages/([^/]+)/reactions$',
    ).firstMatch(path);
    if (options.method == 'DELETE' && clearAll != null) {
      final String messageId = clearAll.group(2)!;
      requests.add('clearReactions #${historyIds.indexOf(messageId)}');
      final int index = historyIds.indexOf(messageId);
      if (index != -1) {
        history[index] = <String, Object?>{
          ...history[index],
          'reactions': <Map<String, Object?>>[],
        };
      }
      return ResponseBody.fromString('', 204, statusMessage: 'No Content');
    }

    if (options.method == 'GET' &&
        path.endsWith('/channels/$kGapChannelId/messages') &&
        holdNextMessageGet) {
      holdNextMessageGet = false;
      // Capture the pre-reaction snapshot before waiting so PUT 204 can finish
      // while this concurrent GET is still in flight (as observed in prod).
      final ResponseBody snapshot = await super.fetch(
        options,
        requestStream,
        cancelFuture,
      );
      final Completer<void> started = _getStartedCompleter ??=
          Completer<void>();
      if (!started.isCompleted) {
        started.complete();
      }
      await (_getReleaseCompleter ??= Completer<void>()).future;
      return snapshot;
    }

    return await super.fetch(options, requestStream, cancelFuture);
  }

  void setServerReactions(
    String messageId,
    List<Map<String, Object?>> reactions,
  ) {
    final int index = historyIds.indexOf(messageId);
    if (index == -1) {
      return;
    }
    history[index] = <String, Object?>{
      ...history[index],
      'reactions': reactions,
    };
  }

  List<Map<String, Object?>> _copiedReactionsAt(int index) =>
      (history[index]['reactions'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic e) => Map<String, Object?>.from(e as Map))
          .toList();

  void _addReactionOnServer({
    required String messageId,
    required String emojiName,
  }) {
    final int index = historyIds.indexOf(messageId);
    if (index == -1) {
      return;
    }
    setServerReactions(
      messageId,
      _copiedReactionsAt(index)..add(<String, Object?>{
        'emoji': <String, Object?>{
          'id': null,
          'name': emojiName,
          'animated': false,
        },
        'count': 1,
        'me': true,
      }),
    );
  }

  void _removeOwnReactionOnServer({
    required String messageId,
    required String emojiName,
  }) {
    final int index = historyIds.indexOf(messageId);
    if (index == -1) {
      return;
    }
    setServerReactions(
      messageId,
      _copiedReactionsAt(index)..removeWhere(
        (Map<String, Object?> r) =>
            (r['emoji']! as Map)['name'] == emojiName && r['me'] == true,
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<
    ({
      ProviderContainer container,
      _ReactionRaceGapServer server,
      FluxerDatabase db,
    })
  >
  openAtJump({
    int targetIndex = 50,
    List<Map<String, Object?>>? initialReactions,
  }) async {
    final FluxerDatabase db = openTestDatabase();
    await seedGapChannels(db);
    final _ReactionRaceGapServer server = _ReactionRaceGapServer();
    if (initialReactions != null) {
      server.setServerReactions(gapHistoryId(targetIndex), initialReactions);
    }
    final ProviderContainer container = paginationContainer(db, server);
    addTearDown(() {
      server
        ..releaseMessageGet()
        ..releaseReactionPut();
      container.dispose();
    });

    await container
        .read(chatViewModelProvider.notifier)
        .switchChannel(
          kGapChannelId,
          targetMessageId: gapHistoryId(targetIndex),
        );
    await paginationFlushAsync();
    return (container: container, server: server, db: db);
  }

  Future<void> waitForSyncToSettle(ProviderContainer container) async {
    for (int i = 0; i < 12; i++) {
      await paginationFlushAsync();
      if (!container.read(chatViewModelProvider).isSyncingMessages) {
        return;
      }
    }
  }

  test(
    'a reaction added concurrently with a pre-reaction GET survives when the stale GET finishes after PUT 204',
    () async {
      final setup = await openAtJump();
      final ChatViewModel chat = setup.container.read(
        chatViewModelProvider.notifier,
      );
      final String targetId = gapHistoryId(50);
      final int epochBefore = setup.container
          .read(chatViewModelProvider)
          .windowEpoch;

      // Simulate the concurrent GET started on sheet close reading the server
      // just before PUT /reactions commits, then completing 2ms after PUT 204.
      setup.server.holdNextMessageGet = true;
      await chat.switchChannel(kGapChannelId);
      await setup.server.waitForHeldMessageGet();

      // Add reaction while the stale GET response is in flight; PUT succeeds 204
      // first, before the stale GET arrives (same order as prod API logs).
      await chat.toggleReaction(targetId, '🖤');
      await paginationFlushAsync();

      final Message optimisticMessage = setup.container
          .read(chatViewModelProvider)
          .messages
          .firstWhere((Message m) => m.id == targetId);
      expect(
        optimisticMessage.reactions.map((Reaction r) => r.emoji),
        contains('🖤'),
        reason: 'baseline: optimistic reaction must appear immediately',
      );
      expect(setup.server.requests, contains('putReaction #50'));

      // Now let the concurrent pre-reaction GET response land on the client.
      setup.server.releaseMessageGet();
      await waitForSyncToSettle(setup.container);

      expect(
        setup.container.read(chatViewModelProvider).windowEpoch,
        greaterThan(epochBefore),
        reason: 'baseline: concurrent GET must have committed its window swap',
      );
      final Message afterStaleGet = setup.container
          .read(chatViewModelProvider)
          .messages
          .firstWhere((Message m) => m.id == targetId);
      expect(
        afterStaleGet.reactions.where((Reaction r) => r.emoji == '🖤'),
        isNotEmpty,
        reason:
            'a stale pre-reaction GET settling after PUT 204 must not wipe out '
            'the reaction (guild gateway skips echoing to this session)',
      );

      final dbRow = await setup.db.messageDao.getMessage(
        kGapChannelId,
        targetId,
      );
      final List<dynamic> dbReactions =
          jsonDecode(dbRow!.reactionsJson) as List<dynamic>;
      expect(
        dbReactions.where((dynamic r) => (r as Map)['emoji'] == '🖤'),
        isNotEmpty,
        reason: 'Drift cache must also retain the acknowledged reaction',
      );
      expect(
        chat.forkPendingReactionMutationCount,
        0,
        reason: 'mutation must retire once all earlier fetches have finished',
      );
    },
  );

  test(
    'a reaction whose PUT is still in flight is not wiped out if a concurrent GET settles first',
    () async {
      final setup = await openAtJump();
      final ChatViewModel chat = setup.container.read(
        chatViewModelProvider.notifier,
      );
      final String targetId = gapHistoryId(50);

      setup.server.holdNextReactionPut = true;
      setup.server.holdNextMessageGet = true;

      final Future<void> putFuture = chat.toggleReaction(targetId, '🖤');
      await setup.server.waitForHeldReactionPut();

      await chat.switchChannel(kGapChannelId);
      await setup.server.waitForHeldMessageGet();

      // GET completes with pre-reaction state while PUT is still pending.
      setup.server.releaseMessageGet();
      await waitForSyncToSettle(setup.container);

      final Message midPut = setup.container
          .read(chatViewModelProvider)
          .messages
          .firstWhere((Message m) => m.id == targetId);
      expect(
        midPut.reactions.where((Reaction r) => r.emoji == '🖤'),
        isNotEmpty,
        reason:
            'an in-flight reaction must be overlaid over concurrent page swaps',
      );

      setup.server.releaseReactionPut();
      await putFuture;
      await paginationFlushAsync();

      final Message settled = setup.container
          .read(chatViewModelProvider)
          .messages
          .firstWhere((Message m) => m.id == targetId);
      expect(
        settled.reactions.where((Reaction r) => r.emoji == '🖤'),
        isNotEmpty,
      );
      expect(chat.forkPendingReactionMutationCount, 0);
    },
  );

  test(
    'concurrent reactions from another user in GET merge cleanly with the local reaction',
    () async {
      final setup = await openAtJump();
      final ChatViewModel chat = setup.container.read(
        chatViewModelProvider.notifier,
      );
      final String targetId = gapHistoryId(50);

      // Another user reacts 🎉 on the server before GET executes; GET still
      // lacks our 🖤.
      setup.server.setServerReactions(targetId, <Map<String, Object?>>[
        <String, Object?>{
          'emoji': <String, Object?>{
            'id': null,
            'name': '🎉',
            'animated': false,
          },
          'count': 1,
          'me': false,
        },
      ]);
      setup.server.holdNextMessageGet = true;
      await chat.switchChannel(kGapChannelId);
      await setup.server.waitForHeldMessageGet();

      await chat.toggleReaction(targetId, '🖤');
      setup.server.releaseMessageGet();
      await waitForSyncToSettle(setup.container);

      final Message settled = setup.container
          .read(chatViewModelProvider)
          .messages
          .firstWhere((Message m) => m.id == targetId);
      expect(
        settled.reactions.map((Reaction r) => r.emoji),
        containsAll(<String>['🎉', '🖤']),
      );
      expect(chat.forkPendingReactionMutationCount, 0);
    },
  );

  test(
    'a reaction removal survives a concurrent pre-removal GET finishing after DELETE 204',
    () async {
      final setup = await openAtJump(
        initialReactions: <Map<String, Object?>>[
          <String, Object?>{
            'emoji': <String, Object?>{
              'id': null,
              'name': '👍',
              'animated': false,
            },
            'count': 1,
            'me': true,
          },
          <String, Object?>{
            'emoji': <String, Object?>{
              'id': null,
              'name': '🎉',
              'animated': false,
            },
            'count': 1,
            'me': false,
          },
        ],
      );
      final ChatViewModel chat = setup.container.read(
        chatViewModelProvider.notifier,
      );
      final String targetId = gapHistoryId(50);

      setup.server.holdNextMessageGet = true;
      await chat.switchChannel(kGapChannelId);
      await setup.server.waitForHeldMessageGet();

      await chat.toggleReaction(targetId, '👍');
      await paginationFlushAsync();
      expect(setup.server.requests, contains('deleteReaction #50'));

      setup.server.releaseMessageGet();
      await waitForSyncToSettle(setup.container);

      final Message settled = setup.container
          .read(chatViewModelProvider)
          .messages
          .firstWhere((Message m) => m.id == targetId);
      expect(
        settled.reactions.where((Reaction r) => r.emoji == '👍'),
        isEmpty,
        reason: 'stale pre-removal GET must not resurrect a removed reaction',
      );
      expect(
        settled.reactions.where((Reaction r) => r.emoji == '🎉'),
        isNotEmpty,
        reason: 'other users reactions on the message must stay intact',
      );
      final dbRow = await setup.db.messageDao.getMessage(
        kGapChannelId,
        targetId,
      );
      final List<dynamic> dbReactions =
          jsonDecode(dbRow!.reactionsJson) as List<dynamic>;
      expect(
        dbReactions.where((dynamic r) => (r as Map)['emoji'] == '👍'),
        isEmpty,
      );
      expect(chat.forkPendingReactionMutationCount, 0);
    },
  );

  test(
    'a failed reaction PUT withdraws the local mutation and leaves state clean across later GETs',
    () async {
      final setup = await openAtJump();
      final ChatViewModel chat = setup.container.read(
        chatViewModelProvider.notifier,
      );
      final String targetId = gapHistoryId(50);

      setup.server.holdNextReactionPut = true;
      setup.server.failNextReactionPut = true;
      setup.server.holdNextMessageGet = true;

      final Future<void> putFuture = chat.toggleReaction(targetId, '🖤');
      await setup.server.waitForHeldReactionPut();

      await chat.switchChannel(kGapChannelId);
      await setup.server.waitForHeldMessageGet();

      setup.server.releaseMessageGet();
      await waitForSyncToSettle(setup.container);
      setup.server.releaseReactionPut();
      await putFuture;
      await paginationFlushAsync();

      expect(chat.forkPendingReactionMutationCount, 0);
      final Message afterFailure = setup.container
          .read(chatViewModelProvider)
          .messages
          .firstWhere((Message m) => m.id == targetId);
      expect(
        afterFailure.reactions.where((Reaction r) => r.emoji == '🖤'),
        isEmpty,
      );
    },
  );

  test(
    'removeAllReactionsOnMessage survives a concurrent pre-clear GET finishing after DELETE 204',
    () async {
      final setup = await openAtJump(
        initialReactions: <Map<String, Object?>>[
          <String, Object?>{
            'emoji': <String, Object?>{
              'id': null,
              'name': '👍',
              'animated': false,
            },
            'count': 1,
            'me': true,
          },
          <String, Object?>{
            'emoji': <String, Object?>{
              'id': null,
              'name': '🎉',
              'animated': false,
            },
            'count': 1,
            'me': false,
          },
        ],
      );
      final ChatViewModel chat = setup.container.read(
        chatViewModelProvider.notifier,
      );
      final String targetId = gapHistoryId(50);

      setup.server.holdNextMessageGet = true;
      await chat.switchChannel(kGapChannelId);
      await setup.server.waitForHeldMessageGet();

      await chat.removeAllReactionsOnMessage(targetId);
      expect(setup.server.requests, contains('clearReactions #50'));

      setup.server.releaseMessageGet();
      await waitForSyncToSettle(setup.container);

      final Message settled = setup.container
          .read(chatViewModelProvider)
          .messages
          .firstWhere((Message m) => m.id == targetId);
      expect(settled.reactions, isEmpty);
      final dbRow = await setup.db.messageDao.getMessage(
        kGapChannelId,
        targetId,
      );
      expect(jsonDecode(dbRow!.reactionsJson), isEmpty);
      expect(chat.forkPendingReactionMutationCount, 0);
    },
  );
}
