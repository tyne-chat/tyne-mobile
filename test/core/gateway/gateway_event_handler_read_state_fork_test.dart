// Fork: tests the fork adds, kept out of upstream's gateway_event_handler_read_state_test.dart so that
// file stays as upstream has it.
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/gateway/gateway_event_handler.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/channels/data/fork_read_state_write_batcher.dart';
import 'package:fluxer_app/features/channels/providers/read_state_write_batcher_provider.dart';
import 'package:fluxer_app/features/chat/data/message_write_batcher.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/messages/message_list.dart';
import 'package:fluxer_app/features/dm/providers/unread_dm_provider.dart';
import 'package:fluxer_dart/gateway.dart';

import '../../helpers/open_test_database.dart';
import 'gateway_event_handler_read_state_test.dart' hide main;

const String _dmId = 'dm-1';
const Duration _kWait = Duration(seconds: 5);

final String _readId = forkUpstream.snowflakeForUtc(
  DateTime.utc(2026, 11, 2, 12),
);
final String _newId = forkUpstream.snowflakeForUtc(
  DateTime.utc(2026, 11, 2, 12, 1),
);
final String _newerId = forkUpstream.snowflakeForUtc(
  DateTime.utc(2026, 11, 2, 12, 2),
);

/// Counts the writes to read_states and, while [refuse] is set, makes them throw.
class _ReadStateWrites extends QueryInterceptor {
  int writes = 0;
  bool refuse = false;

  void _write(Iterable<String> statements) {
    if (!statements.any((String s) => s.contains('read_states'))) {
      return;
    }
    writes += 1;
    if (refuse) {
      throw StateError('read_states write refused by the test');
    }
  }

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _write([statement]);
    return super.runInsert(executor, statement, args);
  }

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _write([statement]);
    return super.runUpdate(executor, statement, args);
  }

  @override
  Future<void> runBatched(
    QueryExecutor executor,
    BatchedStatements statements,
  ) {
    _write(statements.statements);
    return super.runBatched(executor, statements);
  }
}

/// A DM whose last message, [_readId], is read.
Future<void> _seedReadDm(FluxerDatabase db) async {
  await db.dmChannelDao.upsertDmChannels([
    DmChannelsCompanion.insert(
      id: _dmId,
      recipientId: 'other',
      lastMessageId: Value(_readId),
      lastMessageTime: Value(DateTime.utc(2026, 11, 2, 12)),
      unreadCount: const Value(0),
    ),
  ]);
  await db.readStateDao.upsertReadState(
    ReadStatesCompanion(
      channelId: const Value(_dmId),
      lastMessageId: Value(_readId),
      mentionCount: const Value(0),
      lastPinTimestamp: const Value('2026-11-01T10:00:00.000Z'),
      version: const Value('7'),
      flags: const Value(4),
    ),
  );
}

/// The app's wiring: the provider's read-state batcher, and the message write batcher unless
/// [direct], in which case the handler moves the DM's last message itself, right after the ack.
/// Returns every `hasUnread` the unread DM list reports for the DM after the setup.
Future<
  ({
    ProviderContainer container,
    GatewayEventHandler handler,
    List<bool> dmUnread,
  })
>
_openApp(FluxerDatabase db, {bool direct = false, bool dmOpen = false}) async {
  await _seedReadDm(db);
  final ProviderContainer container = ProviderContainer(
    overrides: [fluxerDatabaseProvider.overrideWithValue(db)],
  );
  addTearDown(container.dispose);
  final List<bool> dmUnread = <bool>[];
  final subscription = container.listen(
    unreadDmChannelsProvider,
    (_, UnreadDmState next) => dmUnread.add(next.hasUnread(_dmId)),
    fireImmediately: true,
  );
  addTearDown(subscription.close);
  MessageWriteBatcher? messageWriteBatcher;
  if (!direct) {
    messageWriteBatcher = MessageWriteBatcher(database: db);
    addTearDown(messageWriteBatcher.dispose);
  }
  final GatewayEventHandler handler = GatewayEventHandler(
    database: db,
    currentUserId: 'me',
    readStateWriteBatcher: container.read(readStateWriteBatcherProvider),
    messageWriteBatcher: messageWriteBatcher,
    isAutoAckActive: dmOpen ? (String id) => id == _dmId : null,
    isAtLiveTail: dmOpen ? (String id) => id == _dmId : null,
  );
  await pumpEventQueue();
  expect(dmUnread, isNotEmpty);
  expect(dmUnread, everyElement(isFalse));
  dmUnread.clear();
  return (container: container, handler: handler, dmUnread: dmUnread);
}

MessageCreateEvent _created(String id, {required String authorId}) =>
    MessageCreateEvent(
      message: forkUpstream.message(
        id: id,
        channelId: _dmId,
        authorId: authorId,
      ),
    );

Future<void> _storedAck(FluxerDatabase db, String messageId) => db.readStateDao
    .watchReadState(_dmId)
    .firstWhere((ReadState? row) => row?.lastMessageId == messageId)
    .timeout(_kWait);

Future<void> _dmLastMessage(FluxerDatabase db, String messageId) => db
    .dmChannelDao
    .watchDmChannels()
    .firstWhere(
      (List<DmChannel> rows) => rows.any(
        (DmChannel r) => r.id == _dmId && r.lastMessageId == messageId,
      ),
    )
    .timeout(_kWait);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Since upstream's 70fc7129e an ack stays in memory until the app is backgrounded, while the unread
  // DM list and the NEW divider read the database (tyne-chat/tyne#466).
  group('read marks are stored as soon as they are queued', () {
    test("the user's own DM message never shows the DM as unread", () async {
      final FluxerDatabase db = openTestDatabase();
      final app = await _openApp(db);

      await app.handler.handle(_created(_newId, authorId: 'me'));
      await _dmLastMessage(db, _newId);
      await _storedAck(db, _newId);
      await pumpEventQueue();

      expect(app.dmUnread, everyElement(isFalse));
      expect(
        app.container.read(unreadDmChannelsProvider).hasUnread(_dmId),
        isFalse,
      );
    });

    test(
      'the DM stays read when the last message moves right after the ack',
      () async {
        final FluxerDatabase db = openTestDatabase();
        final app = await _openApp(db, direct: true);

        await app.handler.handle(_created(_newId, authorId: 'me'));
        await _storedAck(db, _newId);
        await pumpEventQueue();

        expect(
          (await db.dmChannelDao.getDmChannelById(_dmId))?.lastMessageId,
          _newId,
        );
        expect(app.dmUnread, everyElement(isFalse));
      },
    );

    test("the NEW divider reads the user's own message as read", () async {
      final FluxerDatabase db = openTestDatabase();
      final app = await _openApp(db);
      final divider = app.container.listen(
        messageListReadStateProvider(_dmId),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(divider.close);

      await app.handler.handle(_created(_newId, authorId: 'me'));
      await _storedAck(db, _newId);
      await pumpEventQueue();

      expect(
        app.container
            .read(messageListReadStateProvider(_dmId))
            .value
            ?.lastMessageId,
        _newId,
      );
    });

    test(
      'a message acked in an open DM is stored without the server',
      () async {
        final FluxerDatabase db = openTestDatabase();
        final app = await _openApp(db, dmOpen: true);

        await app.handler.handle(_created(_newId, authorId: 'other'));
        await _dmLastMessage(db, _newId);
        await _storedAck(db, _newId);
        await pumpEventQueue();

        expect(app.dmUnread, everyElement(isFalse));
      },
    );

    test(
      'an unseeded cursor keeps the stored pin timestamp, version and flags',
      () async {
        final FluxerDatabase db = openTestDatabase();
        await _seedReadDm(db);
        final batcher = ForkReadStateWriteBatcher(database: db);
        addTearDown(batcher.dispose);

        // Mark as read and the Escape key queue an ack without seeding the cursor first.
        batcher
          ..setCursorManual(_dmId, manual: false, clearSticky: true)
          ..enqueueAck(channelId: _dmId, messageId: _newId, clearSticky: true);
        await _storedAck(db, _newId);
        batcher.enqueueAck(
          channelId: _dmId,
          messageId: _newerId,
          clearSticky: true,
        );
        await _storedAck(db, _newerId);

        final ReadState? stored = await db.readStateDao.getReadState(_dmId);
        expect(stored?.lastPinTimestamp, '2026-11-01T10:00:00.000Z');
        expect(stored?.version, '7');
        expect(stored?.flags, 4);
      },
    );

    test('an older ack does not replace a newer stored one', () async {
      final FluxerDatabase db = openTestDatabase();
      await _seedReadDm(db);
      await db.readStateDao.upsertReadState(
        ReadStatesCompanion(
          channelId: const Value(_dmId),
          lastMessageId: Value(_newerId),
        ),
      );
      final batcher = ForkReadStateWriteBatcher(database: db);
      addTearDown(batcher.dispose);

      batcher.enqueueAck(
        channelId: _dmId,
        messageId: _newId,
        clearSticky: true,
      );
      await pumpEventQueue();

      expect(
        (await db.readStateDao.getReadState(_dmId))?.lastMessageId,
        _newerId,
      );
    });

    test('acks queued in one event are stored in one write', () async {
      final _ReadStateWrites writes = _ReadStateWrites();
      final FluxerDatabase db = FluxerDatabase.forTesting(
        NativeDatabase.memory().interceptWith(writes),
      );
      addTearDown(db.close);
      await _seedReadDm(db);
      final batcher = ForkReadStateWriteBatcher(database: db);
      addTearDown(batcher.dispose);
      await batcher.ensureCursor(_dmId);
      writes.writes = 0;

      batcher
        ..enqueueAck(channelId: _dmId, messageId: _newId, clearSticky: false)
        ..enqueueAck(channelId: _dmId, messageId: _newerId, clearSticky: false);
      await _storedAck(db, _newerId);
      await pumpEventQueue();

      expect(writes.writes, 1);
    });

    test('a refused write is not retried until the next ack', () async {
      final _ReadStateWrites writes = _ReadStateWrites();
      final FluxerDatabase db = FluxerDatabase.forTesting(
        NativeDatabase.memory().interceptWith(writes),
      );
      addTearDown(db.close);
      await _seedReadDm(db);
      final batcher = ForkReadStateWriteBatcher(database: db);
      addTearDown(batcher.dispose);
      await batcher.ensureCursor(_dmId);
      writes
        ..writes = 0
        ..refuse = true;

      batcher.enqueueAck(
        channelId: _dmId,
        messageId: _newId,
        clearSticky: false,
      );
      await pumpEventQueue();
      await pumpEventQueue();

      expect(writes.writes, 1);
      expect(
        (await db.readStateDao.getReadState(_dmId))?.lastMessageId,
        _readId,
      );

      writes.refuse = false;
      batcher.enqueueAck(
        channelId: _dmId,
        messageId: _newerId,
        clearSticky: false,
      );
      await _storedAck(db, _newerId);
      expect(writes.writes, 2);
    });
  });
}
