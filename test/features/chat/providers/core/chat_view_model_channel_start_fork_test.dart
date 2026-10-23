// Fork: tyne-chat/tyne#199. Opening a channel with nothing cached and no
// known last message must not mark the start of the channel before a page
// has shown it, or a failed first load leaves "Welcome to #channel" above the
// newest messages.
@Tags(['slow'])
library;

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/messages/message_list_unread_review.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';

import '../../../../helpers/chat_view_model_pagination_test_harness.dart';
import '../../../../helpers/open_test_database.dart';

/// Fails the next [latestFetchFailuresRemaining] latest-page requests (no
/// before, after or around) with a connection error, as a phone losing its
/// network does, and records the cursor of every message-page request.
class _FailingLatestAdapter extends PaginatingAdapter {
  _FailingLatestAdapter({required super.messagesByChannel});

  int latestFetchFailuresRemaining = 0;
  final List<String> requests = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    final Map<String, String> query = options.uri.queryParameters;
    final bool isLatest =
        options.method == 'GET' &&
        options.uri.path.endsWith('/messages') &&
        !query.containsKey('before') &&
        !query.containsKey('after') &&
        !query.containsKey('around');
    if (options.uri.path.endsWith('/messages')) {
      requests.add(query.keys.where((String k) => k != 'limit').join(','));
    }
    if (isLatest && latestFetchFailuresRemaining > 0) {
      latestFetchFailuresRemaining--;
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return super.fetch(options, requestStream, cancelFuture);
  }
}

bool _showsChannelStart(ChatViewState state) => shouldShowChannelWelcome(
  hasMoreOlderMessages: state.hasMoreMessages,
  messageLoadFailed: state.messageLoadFailed,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<({FluxerDatabase db, _FailingLatestAdapter adapter})> setUpChannel(
    List<Map<String, Object?>> serverMessages,
  ) async {
    final FluxerDatabase db = openTestDatabase();
    // A channel row with no last message id, and nothing cached.
    await db.channelDao.upsertChannel(
      ChannelsCompanion.insert(
        id: 'channel-1',
        guildId: 'guild-1',
        name: 'general',
        lastMessageId: const Value(null),
      ),
    );
    return (
      db: db,
      adapter: _FailingLatestAdapter(
        messagesByChannel: {'channel-1': serverMessages},
      ),
    );
  }

  test('the latest page decides: a full page offers older messages', () async {
    final setup = await setUpChannel(
      paginationChannelMessages('channel-1', 350),
    );
    final container = paginationContainer(setup.db, setup.adapter);
    addTearDown(container.dispose);

    await container
        .read(chatViewModelProvider.notifier)
        .switchChannel('channel-1');
    await paginationFlushAsync();

    final ChatViewState state = container.read(chatViewModelProvider);
    expect(state.messages, hasLength(50));
    expect(state.hasMoreMessages, isTrue);
    expect(_showsChannelStart(state), isFalse);
  });

  test('a failed first load, a live message and a resync do not show the '
      'channel start, and older messages stay reachable', () async {
    final List<Map<String, Object?>> server = paginationChannelMessages(
      'channel-1',
      350,
    );
    final setup = await setUpChannel(server);
    setup.adapter.latestFetchFailuresRemaining = 1;
    final container = paginationContainer(setup.db, setup.adapter);
    addTearDown(container.dispose);
    final notifier = container.read(chatViewModelProvider.notifier);

    await notifier.switchChannel('channel-1');
    await paginationFlushAsync();
    expect(container.read(chatViewModelProvider).messageLoadFailed, isTrue);

    final String liveId = paginationSnowflakeForIndex(350);
    server.add(
      paginationMessageJson(
        id: liveId,
        channelId: 'channel-1',
        authorId: 'other',
      ),
    );
    paginationEmitCreatedMessage(container, id: liveId);
    await paginationFlushAsync();

    await notifier.refreshAfterSessionRecovery();
    await paginationFlushAsync();

    ChatViewState state = container.read(chatViewModelProvider);
    expect(state.messageLoadFailed, isFalse);
    expect(state.messages.map((m) => m.id), contains(liveId));
    expect(state.hasMoreMessages, isTrue);
    expect(_showsChannelStart(state), isFalse);

    // Requests so far, by cursor ('' is the latest page): the failed first
    // load, then the resync's page around the window and its tail check.
    expect(setup.adapter.requests, <String>['', 'around', '']);

    final int before = state.messages.length;
    await notifier.loadMore();
    await paginationFlushAsync();

    // Scrolling up asks for one older page, which the window takes.
    state = container.read(chatViewModelProvider);
    expect(setup.adapter.requests, <String>['', 'around', '', 'before']);
    expect(state.messages.length, greaterThan(before));
    expect(state.hasMoreMessages, isTrue);
  });

  test('an empty channel still shows its start once the page is in', () async {
    final setup = await setUpChannel(<Map<String, Object?>>[]);
    final container = paginationContainer(setup.db, setup.adapter);
    addTearDown(container.dispose);

    await container
        .read(chatViewModelProvider.notifier)
        .switchChannel('channel-1');
    await paginationFlushAsync();

    final ChatViewState state = container.read(chatViewModelProvider);
    expect(state.messages, isEmpty);
    expect(state.hasMoreMessages, isFalse);
    expect(_showsChannelStart(state), isTrue);
  });

  test('a new channel with a short history shows its start', () async {
    final setup = await setUpChannel(paginationChannelMessages('channel-1', 3));
    final container = paginationContainer(setup.db, setup.adapter);
    addTearDown(container.dispose);

    await container
        .read(chatViewModelProvider.notifier)
        .switchChannel('channel-1');
    await paginationFlushAsync();

    final ChatViewState state = container.read(chatViewModelProvider);
    expect(state.messages, hasLength(3));
    expect(state.hasMoreMessages, isFalse);
    expect(_showsChannelStart(state), isTrue);
  });
}
