// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: a DM thread fetched from the server (opened by id, closed, imported)
// is stored and known, though it has no guild (tyne-chat/tyne#699).

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/features/threads/data/threads_repository.dart';
import 'package:fluxer_app/features/threads/fork_dm_threads/dm_threads.dart';
import 'package:fluxer_dart/export.dart' hide ChannelType;

import '../../../helpers/open_test_database.dart';

class _DmThreadAdapter implements HttpClientAdapter {
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    return ResponseBody.fromString(
      jsonEncode(<String, Object?>{
        'id': '900',
        'type': 11,
        'parent_id': '500',
        'owner_id': '100',
        'name': 'Plans',
        'message_count': 3,
        'total_message_sent': 3,
        'member_count': 2,
        'thread_metadata': <String, Object?>{
          'archived': true,
          'auto_archive_duration': 4320,
          'archive_timestamp': '2026-11-17T09:00:00.000Z',
          'locked': false,
        },
      }),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  tearDown(forkResetDmThreadIndex);

  test('a fetched DM thread is stored under the DM key and indexed', () async {
    final FluxerDatabase database = openTestDatabase();
    final _DmThreadAdapter adapter = _DmThreadAdapter();
    final ThreadsRepository repository = ThreadsRepository(
      FluxerClient(
        Dio(BaseOptions(baseUrl: 'https://api.test/v1'))
          ..httpClientAdapter = adapter,
      ),
      database,
    );

    final Channel? row = await repository
        .ensureThreadInDatabase(guildId: forkDmThreadGuildKey, threadId: '900')
        .then((_) => database.channelDao.getChannelById('900'));

    expect(adapter.requests, 1);
    expect(row?.guildId, forkDmThreadGuildKey);
    expect(row?.parentId, '500');
    expect(forkDmThreadParentOf('900'), '500');
  });
}
