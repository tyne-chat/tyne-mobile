// Fork: threads in DMs arrive wrapped in FORK_DM_THREAD_EVENT and in READY's
// fork_dm_threads, and are stored as threads under the empty guild key
// (tyne-chat/tyne#699).
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/gateway/gateway_event_handler.dart';
import 'package:fluxer_app/features/chat/providers/messages/message_realtime_events.dart';
import 'package:fluxer_app/features/threads/fork_dm_threads/dm_thread_gateway.dart';
import 'package:fluxer_app/features/threads/fork_dm_threads/dm_threads.dart';
import 'package:fluxer_app/shared/utils/snowflake_time.dart';
import 'package:fluxer_dart/gateway.dart';
import 'package:fluxer_dart/gateway_client/event_parser.dart';

import '../../../helpers/open_test_database.dart';

const String _me = '100';
const String _other = '300';
const String _dmId = '500';
const String _threadId = '900';

String _snowflakeAt(int minute) =>
    ((DateTime.utc(2026, 11, 17, 10, minute).millisecondsSinceEpoch -
                kSnowflakeEpochMs) <<
            22)
        .toString();

Map<String, Object?> _dmThread({
  String id = _threadId,
  bool member = true,
  bool muted = false,
}) => <String, Object?>{
  'id': id,
  'type': 11,
  'parent_id': _dmId,
  'owner_id': _me,
  'name': 'Plans',
  'message_count': 0,
  'total_message_sent': 0,
  'member_count': 2,
  'thread_metadata': <String, Object?>{
    'archived': false,
    'auto_archive_duration': 4320,
    'archive_timestamp': '2026-11-17T09:00:00.000Z',
    'locked': false,
    'create_timestamp': '2026-11-17T09:00:00.000Z',
  },
  if (member)
    'member': <String, Object?>{
      'join_timestamp': '2026-11-17T09:00:00.000Z',
      'flags': 0,
      'muted': muted,
    },
};

Map<String, Object?> _message(String id, {String channelId = _threadId}) =>
    <String, Object?>{
      'id': id,
      'channel_id': channelId,
      'author': <String, Object?>{
        'id': _other,
        'username': 'other',
        'discriminator': '0001',
        'avatar': null,
        'avatar_color': null,
        'flags': 0,
      },
      'type': 0,
      'flags': 0,
      'content': 'hello',
      'timestamp': dateTimeFromUserSnowflakeOrNull(id)!.toIso8601String(),
      'pinned': false,
      'mention_everyone': false,
      'tts': false,
      'mentions': <Object?>[],
      'mention_roles': <Object?>[],
    };

UnknownGatewayEvent _wrapped(String name, Map<String, Object?> payload) =>
    UnknownGatewayEvent(
      eventType: forkDmThreadEventName,
      data: <String, dynamic>{'t': name, 'd': payload},
    );

ReadyEvent _ready({Map<String, Object?>? dmThreads}) =>
    const EventParser().parse('READY', <String, dynamic>{
          'session_id': 'session-1',
          'user': <String, Object?>{'id': _me, 'username': 'me'},
          'fork_dm_threads': ?dmThreads,
        })
        as ReadyEvent;

({FluxerDatabase database, GatewayEventHandler handler}) _build({
  MessageCreateCallback? onMessageCreate,
}) {
  final FluxerDatabase database = openTestDatabase();
  return (
    database: database,
    handler: GatewayEventHandler(
      database: database,
      currentUserId: _me,
      onMessageCreate: onMessageCreate,
    ),
  );
}

void main() {
  tearDown(() {
    forkResetDmThreadsEnabled();
    forkResetDmThreadIndex();
  });

  group('the envelope', () {
    test('a thread event gets the DM thread key as its guild', () {
      final GatewayEvent? event = forkUnwrapDmThreadEvent(<String, dynamic>{
        't': 'THREAD_CREATE',
        'd': _dmThread(),
      });

      expect(event, isA<ThreadCreateEvent>());
      expect(
        (event! as ThreadCreateEvent).channel.guildId,
        forkDmThreadGuildKey,
      );
    });

    test('a message event stays without a guild', () {
      final GatewayEvent? event = forkUnwrapDmThreadEvent(<String, dynamic>{
        't': 'MESSAGE_CREATE',
        'd': _message(_snowflakeAt(1)),
      });

      expect(event, isA<MessageCreateEvent>());
      expect((event! as MessageCreateEvent).guildId, isNull);
    });

    test('anything that is not a DM thread event is dropped', () {
      for (final Map<String, dynamic> envelope in <Map<String, dynamic>>[
        <String, dynamic>{'t': 'READY', 'd': <String, Object?>{}},
        <String, dynamic>{'t': 'GUILD_DELETE', 'd': <String, Object?>{}},
        <String, dynamic>{'t': forkDmThreadEventName, 'd': <String, Object?>{}},
        <String, dynamic>{'t': 'THREAD_CREATE', 'd': <Object?>[]},
        <String, dynamic>{'d': _dmThread()},
        // A THREAD_DELETE without its parent does not parse.
        <String, dynamic>{
          't': 'THREAD_DELETE',
          'd': <String, Object?>{'id': _threadId},
        },
      ]) {
        expect(forkUnwrapDmThreadEvent(envelope), isNull, reason: '$envelope');
      }
    });
  });

  group('gateway events', () {
    test(
      'THREAD_CREATE stores the thread and the account as a member',
      () async {
        final h = _build();

        await h.handler.handle(_wrapped('THREAD_CREATE', _dmThread()));

        final Channel? row = await h.database.channelDao.getChannelById(
          _threadId,
        );
        expect(row?.guildId, forkDmThreadGuildKey);
        expect(row?.parentId, _dmId);
        expect(row != null && forkIsDmThreadRow(row), isTrue);
        final ThreadMember? member = await h.database.threadDao.getMember(
          _threadId,
        );
        expect(member?.guildId, forkDmThreadGuildKey);
        expect(forkDmThreadParentOf(_threadId), _dmId);
        expect(forkDmHasKnownThreads(_dmId), isTrue);
      },
    );

    test('THREAD_DELETE removes it', () async {
      final h = _build();
      await h.handler.handle(_wrapped('THREAD_CREATE', _dmThread()));

      await h.handler.handle(
        _wrapped('THREAD_DELETE', <String, Object?>{
          'id': _threadId,
          'parent_id': _dmId,
          'type': 11,
        }),
      );

      expect(await h.database.channelDao.getChannelById(_threadId), isNull);
      expect(await h.database.threadDao.getMember(_threadId), isNull);
      expect(forkDmThreadParentOf(_threadId), isNull);
    });

    test(
      'every message in a followed thread counts, but is not a mention',
      () async {
        final List<MessagePersistSnapshot> snapshots =
            <MessagePersistSnapshot>[];
        final h = _build(
          onMessageCreate: (MessageCreateDispatch d) =>
              snapshots.add(d.snapshot),
        );
        await h.handler.handle(_wrapped('THREAD_CREATE', _dmThread()));

        await h.handler.handle(
          _wrapped('MESSAGE_CREATE', _message(_snowflakeAt(1))),
        );
        await h.handler.handle(
          _wrapped('MESSAGE_CREATE', _message(_snowflakeAt(2))),
        );

        final ReadState? state = await h.database.readStateDao.getReadState(
          _threadId,
        );
        expect(state?.mentionCount, 2);
        expect(snapshots, hasLength(2));
        expect(snapshots.last.mentionsCurrentUser, isFalse);
        expect(snapshots.last.isDm, isFalse);
      },
    );

    test('a muted thread does not count its messages', () async {
      final h = _build();
      await h.handler.handle(_wrapped('THREAD_CREATE', _dmThread(muted: true)));

      await h.handler.handle(
        _wrapped('MESSAGE_CREATE', _message(_snowflakeAt(1))),
      );

      final ReadState? state = await h.database.readStateDao.getReadState(
        _threadId,
      );
      expect(state?.mentionCount ?? 0, 0);
    });

    test('a thread the account left does not count its messages', () async {
      final h = _build();
      await h.handler.handle(
        _wrapped('THREAD_CREATE', _dmThread(member: false)),
      );

      await h.handler.handle(
        _wrapped('MESSAGE_CREATE', _message(_snowflakeAt(1))),
      );

      final ReadState? state = await h.database.readStateDao.getReadState(
        _threadId,
      );
      expect(state?.mentionCount ?? 0, 0);
    });

    test('the message is kept in the thread, not in a DM', () async {
      final h = _build();
      await h.handler.handle(_wrapped('THREAD_CREATE', _dmThread()));
      final String messageId = _snowflakeAt(1);

      await h.handler.handle(_wrapped('MESSAGE_CREATE', _message(messageId)));

      expect(
        await h.database.messageDao.getMessage(_threadId, messageId),
        isNotNull,
      );
      expect(await h.database.dmChannelDao.getDmChannelById(_threadId), isNull);
    });
  });

  group('READY', () {
    test(
      'stores the followed threads, their read states and the switch',
      () async {
        final h = _build();

        await h.handler.handle(
          _ready(
            dmThreads: <String, Object?>{
              'enabled': true,
              'threads': <Object?>[_dmThread()],
              'read_states': <Object?>[
                <String, Object?>{
                  'id': _threadId,
                  'last_message_id': _snowflakeAt(1),
                  'mention_count': 2,
                },
              ],
            },
          ),
        );

        expect(
          (await h.database.channelDao.getChannelById(_threadId))?.guildId,
          forkDmThreadGuildKey,
        );
        expect(await h.database.threadDao.getMember(_threadId), isNotNull);
        final ReadState? state = await h.database.readStateDao.getReadState(
          _threadId,
        );
        expect(state?.mentionCount, 2);
        expect(state?.lastMessageId, _snowflakeAt(1));
        expect(forkDmThreadParentOf(_threadId), _dmId);
        expect(forkDmThreadsEnabledFor(_me), isTrue);
        expect(forkDmThreadsEnabledFor('someone else'), isFalse);
      },
    );

    test('a later READY drops a followed thread it no longer lists', () async {
      final h = _build();
      await h.handler.handle(
        _ready(
          dmThreads: <String, Object?>{
            'enabled': true,
            'threads': <Object?>[_dmThread()],
          },
        ),
      );

      await h.handler.handle(
        _ready(dmThreads: <String, Object?>{'enabled': false}),
      );

      expect(await h.database.channelDao.getChannelById(_threadId), isNull);
      expect(await h.database.threadDao.getMember(_threadId), isNull);
      expect(forkDmThreadParentOf(_threadId), isNull);
      expect(forkDmThreadsEnabledFor(_me), isFalse);
    });

    test('a server without the field keeps what is stored', () async {
      final h = _build();
      await h.handler.handle(
        _ready(
          dmThreads: <String, Object?>{
            'enabled': true,
            'threads': <Object?>[_dmThread()],
          },
        ),
      );

      await h.handler.handle(_ready());

      expect(await h.database.channelDao.getChannelById(_threadId), isNotNull);
      expect(forkDmThreadsEnabledFor(_me), isFalse);
    });

    test('READY from the cache keeps cached DM thread messages', () async {
      final FluxerDatabase database = openTestDatabase();
      final GatewayEventHandler handler = GatewayEventHandler(
        database: database,
        currentUserId: _me,
        isCacheOwnedBy: (String userId) async => true,
      );
      await handler.handle(_wrapped('THREAD_CREATE', _dmThread()));
      final String messageId = _snowflakeAt(1);
      await handler.handle(_wrapped('MESSAGE_CREATE', _message(messageId)));

      await handler.handle(
        _ready(
          dmThreads: <String, Object?>{
            'enabled': true,
            'threads': <Object?>[_dmThread()],
          },
        ),
      );

      expect(
        await database.messageDao.getMessage(_threadId, messageId),
        isNotNull,
      );
    });
  });
}
