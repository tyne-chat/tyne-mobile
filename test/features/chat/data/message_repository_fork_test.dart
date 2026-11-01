// Fork: tests the fork adds, kept out of upstream's message_repository_test.dart so that file stays as
// upstream has it.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/data/message_repository.dart';
import 'package:fluxer_app/features/chat/domain/api_attachment_metadata.dart';
import 'package:fluxer_dart/export.dart';

import '../../../helpers/open_test_database.dart';

class _ReactionAdapter implements HttpClientAdapter {
  String? requestedPath;
  String? requestedMethod;
  dynamic requestedBody;
  Map<String, dynamic>? requestedQueryParams;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestedPath = options.uri.path;
    requestedMethod = options.method;
    requestedQueryParams = options.uri.queryParameters;
    requestedBody = options.data;
    return ResponseBody.fromString('', 204);
  }

  @override
  void close({bool force = false}) {}
}

class _EditAdapter implements HttpClientAdapter {
  String? method;
  String? path;
  Object? body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    method = options.method;
    path = options.uri.path;
    body = options.data;
    return ResponseBody.fromString(
      jsonEncode(<String, Object?>{
        'id': '123',
        'channel_id': 'chan-1',
        'author': <String, Object?>{
          'id': 'me',
          'username': 'me',
          'discriminator': '0001',
          'global_name': null,
          'avatar': null,
          'avatar_color': null,
          'flags': 0,
        },
        'type': 0,
        'flags': 0,
        'tts': false,
        'content': 'text',
        'timestamp': DateTime.utc(2026, 11).toIso8601String(),
        'pinned': false,
        'mention_everyone': false,
        'mentions': <Object?>[],
        'mention_roles': <Object?>[],
      }),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('editMessageWithFiles (tyne-chat/tyne#293)', () {
    Future<_EditAdapter> edit({List<XFile>? files}) async {
      final db = openTestDatabase();
      final adapter = _EditAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.fluxer.app/v1'))
        ..httpClientAdapter = adapter;
      final client = FluxerClient(dio, baseUrl: 'https://api.fluxer.app/v1');
      await MessageRepository(client, dio, db, 'me').editMessageWithFiles(
        channelId: 'chan-1',
        messageId: '123',
        content: 'text',
        keptAttachmentIds: const <String>['800'],
        attachmentMetadata: const <ApiAttachmentMetadata>[
          ApiAttachmentMetadata(
            id: '0',
            filename: 'a.png',
            title: 'a.png',
            uploadFilename: 'stored-a.png',
          ),
        ],
        attachmentFiles: files,
        updatePersona: true,
        personaData: const <String, dynamic>{'id': 'p_bob'},
      );
      return adapter;
    }

    test('stored files are named in a JSON request', () async {
      final _EditAdapter adapter = await edit();

      expect(adapter.method, 'PATCH');
      expect(adapter.path, endsWith('/channels/chan-1/messages/123'));
      expect(adapter.body, <String, dynamic>{
        'content': 'text',
        'persona_id': 'p_bob',
        'attachments': <Map<String, dynamic>>[
          <String, dynamic>{'id': '800'},
          <String, dynamic>{
            'id': '0',
            'filename': 'a.png',
            'title': 'a.png',
            'upload_filename': 'stored-a.png',
          },
        ],
      });
    });

    test('other files go with the request as form parts', () async {
      final Directory dir = await Directory.systemTemp.createTemp('edit_files');
      addTearDown(() => dir.delete(recursive: true));
      final File file = File('${dir.path}/a.png')..writeAsBytesSync(<int>[1]);

      final _EditAdapter adapter = await edit(files: <XFile>[XFile(file.path)]);

      final FormData form = adapter.body! as FormData;
      expect(form.files.single.key, 'files[0]');
      final Map<String, dynamic> payload =
          jsonDecode(form.fields.single.value) as Map<String, dynamic>;
      expect(form.fields.single.key, 'payload_json');
      expect(payload['attachments'], hasLength(2));
    });
  });

  test('addReaction sends persona_id in request body when provided', () async {
    final db = openTestDatabase();
    final adapter = _ReactionAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.fluxer.app/v1'))
      ..httpClientAdapter = adapter;
    final client = FluxerClient(dio, baseUrl: 'https://api.fluxer.app/v1');
    final repo = MessageRepository(client, dio, db, 'me');

    await repo.addReaction(
      channelId: 'chan-1',
      messageId: 'msg-1',
      emoji: '👍',
      personaId: 'p_bob',
    );

    expect(adapter.requestedMethod, 'PUT');
    expect(adapter.requestedPath, contains('/reactions/'));
    expect(adapter.requestedBody, {'persona_id': 'p_bob'});
  });

  test(
    'addReaction sends an empty body when personaId is null (root user)',
    () async {
      final db = openTestDatabase();
      final adapter = _ReactionAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.fluxer.app/v1'))
        ..httpClientAdapter = adapter;
      final client = FluxerClient(dio, baseUrl: 'https://api.fluxer.app/v1');
      final repo = MessageRepository(client, dio, db, 'me');

      await repo.addReaction(
        channelId: 'chan-1',
        messageId: 'msg-1',
        emoji: '👍',
      );

      expect(adapter.requestedMethod, 'PUT');
      expect(adapter.requestedBody, <String, dynamic>{});
    },
  );

  test(
    'removeReaction passes persona_id query parameter when provided',
    () async {
      final db = openTestDatabase();
      final adapter = _ReactionAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.fluxer.app/v1'))
        ..httpClientAdapter = adapter;
      final client = FluxerClient(dio, baseUrl: 'https://api.fluxer.app/v1');
      final repo = MessageRepository(client, dio, db, 'me');

      await repo.removeReaction(
        channelId: 'chan-1',
        messageId: 'msg-1',
        emoji: '👍',
        personaId: 'p_bob',
      );

      expect(adapter.requestedMethod, 'DELETE');
      expect(adapter.requestedQueryParams, {'persona_id': 'p_bob'});
    },
  );

  test(
    'removeReaction defaults to persona_id "0" when personaId is null (root user)',
    () async {
      final db = openTestDatabase();
      final adapter = _ReactionAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.fluxer.app/v1'))
        ..httpClientAdapter = adapter;
      final client = FluxerClient(dio, baseUrl: 'https://api.fluxer.app/v1');
      final repo = MessageRepository(client, dio, db, 'me');

      await repo.removeReaction(
        channelId: 'chan-1',
        messageId: 'msg-1',
        emoji: '👍',
      );

      expect(adapter.requestedMethod, 'DELETE');
      expect(adapter.requestedQueryParams, {'persona_id': '0'});
    },
  );
}
