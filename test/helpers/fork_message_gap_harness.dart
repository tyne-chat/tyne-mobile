// Fork: tyne-chat/tyne#212. A fake server and checks for the tests of gaps
// in the message list: one channel whose history grows with every send and
// every message from someone else, a record of the requests made for it, and
// a short description of what the list shows, to compare with what it should.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' hide Message;
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/chat/providers/messages/message_realtime_events.dart';
import 'package:fluxer_app/features/chat/providers/messages/message_realtime_provider.dart';
import 'package:fluxer_app/features/chat/utils/messages/message_page_sync.dart';
import 'package:fluxer_dart/export.dart';
import 'package:fluxer_dart/gateway.dart';

import 'chat_view_model_pagination_test_harness.dart';
import 'message_realtime_test_helpers.dart';

const String kGapChannelId = 'channel-1';
const String kGapOtherChannelId = 'channel-2';

/// Messages #0 to #99 are on the server when a test starts.
const int kGapHistoryLength = 100;

String gapHistoryId(int index) => paginationSnowflakeForIndex(index);

/// The server. Requests for the channel's messages are recorded as `latest`,
/// `send`, or the cursor and the message it names, such as `after #100`.
class GapServer extends PaginatingAdapter {
  GapServer()
    : super(
        messagesByChannel: <String, List<Map<String, Object?>>>{
          kGapChannelId: paginationChannelMessages(
            kGapChannelId,
            kGapHistoryLength,
          ),
          kGapOtherChannelId: paginationChannelMessages(
            kGapOtherChannelId,
            3,
            baseIndex: 1000,
          ),
        },
      );

  int _nextIndex = kGapHistoryLength;

  final List<String> requests = <String>[];

  /// While set, sends wait for it before the server answers.
  Completer<void>? sendHold;

  /// Sends the server refuses, from the next one on.
  int refusedSends = 0;

  List<Map<String, Object?>> get history => messagesByChannel[kGapChannelId]!;

  List<String> get historyIds => <String>[
    for (final Map<String, Object?> row in history) row['id']! as String,
  ];

  /// Adds a message to the end of the channel's history.
  Map<String, Object?> post({
    required String authorId,
    String? content,
    String? nonce,
  }) {
    final String id = paginationSnowflakeForIndex(_nextIndex++);
    final Map<String, Object?> row = <String, Object?>{
      ...paginationMessageJson(
        id: id,
        channelId: kGapChannelId,
        authorId: authorId,
      ),
      'content': ?content,
      'nonce': ?nonce,
    };
    history.add(row);
    return row;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final String path = options.uri.path;
    if (path.endsWith('/channels/$kGapChannelId/messages')) {
      if (options.method == 'POST') {
        requests.add('send');
        final Map<String, dynamic> body = await _jsonBody(
          requestStream,
          options.data,
        );
        await sendHold?.future;
        if (refusedSends > 0) {
          refusedSends--;
          return ResponseBody.fromString(
            jsonEncode(<String, Object?>{
              'code': 'CANNOT_SEND_MESSAGE',
              'message': 'Cannot send message',
            }),
            400,
            headers: <String, List<String>>{
              Headers.contentTypeHeader: <String>['application/json'],
            },
          );
        }
        return _json(
          post(
            authorId: 'me',
            content: body['content'] as String?,
            nonce: body['nonce'] as String?,
          ),
        );
      }
      final Map<String, String> query = options.uri.queryParameters;
      final String? cursor = const <String>[
        'before',
        'after',
        'around',
      ].where(query.containsKey).firstOrNull;
      requests.add(
        cursor == null
            ? 'latest'
            : '$cursor #${historyIds.indexOf(query[cursor]!)}',
      );
    }
    if (options.method == 'POST' && path.endsWith('/read-states/ack')) {
      return _json(<String, Object?>{
        'read_states': <Object?>[],
        'read_state_proto': '',
      });
    }
    if (options.method == 'POST' && path.endsWith('/ack')) {
      return ResponseBody.fromString('', 204);
    }
    return super.fetch(options, requestStream, cancelFuture);
  }

  ResponseBody _json(Object data) => ResponseBody.fromString(
    jsonEncode(data),
    200,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>['application/json'],
    },
  );

  Future<Map<String, dynamic>> _jsonBody(
    Stream<Uint8List>? stream,
    Object? data,
  ) async {
    if (data is Map<String, dynamic>) {
      return data;
    }
    final String raw = stream == null
        ? (data is String ? data : '')
        : utf8.decode(await stream.expand((Uint8List c) => c).toList());
    return raw.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(raw) as Map<String, dynamic>;
  }
}

/// Where the server's history is missing from the list: for each pair of
/// neighbouring messages in the list, the messages between them on the
/// server. Messages still sending are skipped.
List<String> gapsInList(ChatViewState state, GapServer server) {
  final List<String> serverIds = server.historyIds;
  final List<int> shown = <int>[
    for (final Message message in state.messages)
      if (!isLocalOnlyMessage(message)) serverIds.indexOf(message.id),
  ];
  return <String>[
    for (int i = 1; i < shown.length; i++)
      if (shown[i] != shown[i - 1] + 1) _gap(shown[i - 1], shown[i]),
  ];
}

String _gap(int before, int after) =>
    '#${before + 1} to #${after - 1} missing between #$before and #$after';

/// What the list shows: whether it says it reaches the newest message, the
/// gaps in it, and its last message.
String gapListShape(ChatViewState state, GapServer server) {
  final String? last = newestServerBackedMessageId(state.messages);
  return 'claims newest: ${!state.hasMoreNewerMessages}; '
      'gaps: ${gapsInList(state, server)}; '
      'last: #${last == null ? '-' : server.historyIds.indexOf(last)}';
}

/// The list after it has loaded down to the newest message.
String gapCompleteShape(GapServer server) =>
    'claims newest: true; gaps: []; last: #${server.history.length - 1}';

/// The list either says it does not reach the newest message, or reaches it
/// with nothing missing.
Matcher gapHonestShape(GapServer server) =>
    anyOf(startsWith('claims newest: false;'), gapCompleteShape(server));

/// The server's guild, the user's membership and both channels. READY has
/// stored #99 as the channel's last message.
Future<void> seedGapChannels(FluxerDatabase db) async {
  await db.guildDao.upsertServer(
    ServersCompanion.insert(id: 'guild-1', name: 'Guild'),
  );
  await db.memberDao.upsertMember(
    MembersCompanion.insert(userId: 'me', guildId: 'guild-1'),
  );
  await db.channelDao.upsertChannel(
    ChannelsCompanion.insert(
      id: kGapChannelId,
      guildId: 'guild-1',
      name: 'lounge',
      lastMessageId: Value(gapHistoryId(kGapHistoryLength - 1)),
    ),
  );
  await db.channelDao.upsertChannel(
    ChannelsCompanion.insert(
      id: kGapOtherChannelId,
      guildId: 'guild-1',
      name: 'other',
      lastMessageId: Value(gapHistoryId(1002)),
    ),
  );
}

Future<void> setGapReadMark(
  FluxerDatabase db,
  String messageId, {
  bool manual = false,
  String? stickyUnreadMessageId,
}) => db.readStateDao.upsertReadState(
  ReadStatesCompanion(
    channelId: const Value(kGapChannelId),
    lastMessageId: Value(messageId),
    mentionCount: const Value(0),
    manual: Value(manual),
    stickyUnreadMessageId: Value(stickyUnreadMessageId),
  ),
);

/// What the gateway handler stores for a MESSAGE_CREATE before the chat sees
/// it: the row, and the channel's last message.
Future<void> storeGapCreate(FluxerDatabase db, Map<String, Object?> row) async {
  final String id = row['id']! as String;
  final String authorId =
      (row['author']! as Map<String, Object?>)['id']! as String;
  await db.messageDao.upsertMessage(
    paginationCachedMessage(
      id: id,
      channelId: kGapChannelId,
    ).copyWith(authorId: Value(authorId)),
  );
  await db.channelDao.updateLastMessageId(kGapChannelId, id);
}

/// Hands a MESSAGE_CREATE for [row] to the chat, as the gateway handler does
/// after storing it.
void emitGapCreate(ProviderContainer container, Map<String, Object?> row) {
  container
      .read(messageRealtimeBusProvider)
      .emit(
        testMessageCreated(
          MessageCreateEvent(message: MessageResponseSchema.fromJson(row)),
          snapshot: const MessagePersistSnapshot(
            mentionsCurrentUser: false,
            isDm: false,
            acknowledgedByGateway: true,
          ),
        ),
      );
}
