// Fork: tyne-chat/tyne#293. Files in the composer go with an edit, and the edit stays open until they
// land, as on the web app.
@Tags(['slow'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' hide Message;
import 'package:fluxer_app/core/providers/app/account_user_id.dart';
import 'package:fluxer_app/core/providers/app/app_ui_lifecycle_provider.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/channels/data/ack_batcher.dart';
import 'package:fluxer_app/features/channels/providers/ack_batcher_provider.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/domain/pending_attachment.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/chat/providers/upload/attachment_upload_client_provider.dart';
import 'package:fluxer_app/features/chat/providers/upload/cloud_upload_controller.dart';
import 'package:fluxer_app/features/chat/providers/upload/user_upload_limits_provider.dart';
import 'package:fluxer_app/features/chat/utils/composer/composer_upload_file.dart';
import 'package:fluxer_app/features/ui/toast/toast_provider.dart';
import 'package:fluxer_app/shared/services/guild_member_hydration_service.dart';
import 'package:fluxer_dart/export.dart';

import '../../../../helpers/chat_view_model_pagination_test_harness.dart';
import '../../../../helpers/fake_attachment_upload_client.dart';
import '../../../../helpers/noop_guild_member_hydration_service.dart';
import '../../../../helpers/open_test_database.dart';

const String _channelId = 'channel-1';
final String _messageId = paginationSnowflakeForIndex(1);

Map<String, Object?> _attachmentJson(String id, String filename) =>
    <String, Object?>{
      'id': id,
      'filename': filename,
      'size': 1,
      'url': 'https://cdn.test/$filename',
      'proxy_url': 'https://cdn.test/$filename',
    };

/// Records every edit of the message, and answers as the server does or with a 400.
class _EditRecorder extends PaginatingAdapter {
  _EditRecorder({this.existing = const <Map<String, Object?>>[]})
    : super(
        messagesByChannel: <String, List<Map<String, Object?>>>{
          _channelId: <Map<String, Object?>>[
            <String, Object?>{
              ...paginationMessageJson(
                id: _messageId,
                channelId: _channelId,
                authorId: 'me',
              ),
              'content': 'Test',
              'attachments': existing,
            },
          ],
        },
      );

  final List<Map<String, Object?>> existing;
  final List<Map<String, dynamic>> edits = <Map<String, dynamic>>[];
  final List<FormData> multipartEdits = <FormData>[];
  bool failEdits = false;
  Completer<void>? holdEdit;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method != 'PATCH') {
      return super.fetch(options, requestStream, cancelFuture);
    }
    final Object? data = options.data;
    final Map<String, dynamic> body;
    if (data is FormData) {
      multipartEdits.add(data);
      body =
          jsonDecode(
                data.fields
                    .firstWhere(
                      (MapEntry<String, String> f) => f.key == 'payload_json',
                    )
                    .value,
              )
              as Map<String, dynamic>;
    } else {
      body = data! as Map<String, dynamic>;
    }
    edits.add(body);
    await holdEdit?.future;
    final Map<String, List<String>> headers = <String, List<String>>{
      Headers.contentTypeHeader: <String>['application/json'],
    };
    if (failEdits) {
      return ResponseBody.fromString(
        jsonEncode(<String, Object?>{'code': 'NOPE', 'message': 'Refused'}),
        400,
        headers: headers,
      );
    }
    return ResponseBody.fromString(
      jsonEncode(<String, Object?>{
        ...paginationMessageJson(
          id: _messageId,
          channelId: _channelId,
          authorId: 'me',
        ),
        'content': body['content'],
        'edited_timestamp': DateTime.utc(2026, 11).toIso8601String(),
        'attachments': <Map<String, Object?>>[
          ...existing,
          _attachmentJson('900', 'a.png'),
        ],
      }),
      200,
      headers: headers,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FluxerDatabase db;
  late Directory tempDir;
  late FakeAttachmentUploadClient uploads;

  setUp(() async {
    db = openTestDatabase();
    await db.channelDao.upsertChannel(
      ChannelsCompanion.insert(id: _channelId, guildId: '', name: 'dm'),
    );
    tempDir = await Directory.systemTemp.createTemp('edit_files_fork');
    addTearDown(() => tempDir.delete(recursive: true));
    uploads = FakeAttachmentUploadClient(apiDio: Dio(), uploadDio: Dio());
  });

  ProviderContainer containerWith(
    _EditRecorder adapter, {
    bool presigned = true,
  }) {
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://api.fluxer.app/v1'))
      ..httpClientAdapter = adapter;
    final FluxerClient client = FluxerClient(
      dio,
      baseUrl: 'https://api.fluxer.app/v1',
    );
    final ProviderContainer container = ProviderContainer(
      overrides: [
        fluxerDatabaseProvider.overrideWithValue(db),
        appUiForegroundProvider.overrideWithValue(true),
        fluxerDioProvider.overrideWithValue(dio),
        fluxerClientProvider.overrideWithValue(client),
        currentUserIdProvider.overrideWithValue('me'),
        attachmentUploadClientProvider.overrideWithValue(uploads),
        maxAttachmentFileBytesProvider.overrideWithValue(1024 * 1024),
        instanceRuntimeConfigProvider.overrideWithValue(
          testInstanceRuntimeConfig(presignedAttachmentUploads: presigned),
        ),
        ackBatcherProvider.overrideWith((ref) {
          final AckBatcher batcher = AckBatcher(
            client: client,
            batchDelay: Duration.zero,
          );
          ref.onDispose(() {
            unawaited(batcher.dispose());
          });
          return batcher;
        }),
        guildMemberHydrationServiceProvider.overrideWithValue(
          NoopGuildMemberHydrationService(database: db),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  // Opens the channel, starts editing the message and puts a file in the composer.
  Future<ChatViewModel> editWithFile(ProviderContainer container) async {
    final ChatViewModel notifier = container.read(
      chatViewModelProvider.notifier,
    );
    await notifier.switchChannel(_channelId);
    await paginationFlushAsync();
    notifier.startEdit(
      container
          .read(chatViewModelProvider)
          .messages
          .firstWhere((Message m) => m.id == _messageId),
    );
    await paginationFlushAsync();
    final File file = File('${tempDir.path}/a.png')..writeAsBytesSync(<int>[1]);
    await container
        .read(
          cloudUploadControllerProvider(
            readAccountUserId(container),
            _channelId,
          ).notifier,
        )
        .addFiles(composerUploadFiles(<XFile>[XFile(file.path)]));
    return notifier;
  }

  List<PendingAttachment> composerFiles(ProviderContainer container) =>
      container
          .read(
            cloudUploadControllerProvider(
              readAccountUserId(container),
              _channelId,
            ),
          )
          .items;

  Message row(ProviderContainer container) => container
      .read(chatViewModelProvider)
      .messages
      .firstWhere((Message m) => m.id == _messageId);

  test(
    'unchanged text and a file saves, naming the attachments the message keeps',
    () async {
      final _EditRecorder adapter = _EditRecorder(
        existing: <Map<String, Object?>>[_attachmentJson('800', 'old.png')],
      );
      final ProviderContainer container = containerWith(adapter);
      final ChatViewModel notifier = await editWithFile(container);

      await notifier.saveEditedMessage(text: 'Test');
      await paginationFlushAsync();

      expect(container.read(toastProvider), isEmpty);
      expect(adapter.edits, hasLength(1));
      final List<dynamic> attachments =
          adapter.edits.single['attachments'] as List<dynamic>;
      expect(attachments.first, <String, dynamic>{'id': '800'});
      expect(attachments[1], containsPair('upload_filename', 'stored-a.png'));
      expect(attachments, hasLength(2));
      expect(uploads.planRequests, 1);
      expect(composerFiles(container), isEmpty);
      expect(container.read(chatViewModelProvider).editingMessage, isNull);
      expect(row(container).attachments.map((Attachment a) => a.id), <String>[
        '800',
        '900',
      ]);
    },
  );

  test('emptied text with a file saves the empty text', () async {
    final _EditRecorder adapter = _EditRecorder();
    final ProviderContainer container = containerWith(adapter);
    final ChatViewModel notifier = await editWithFile(container);

    await notifier.saveEditedMessage(text: '');

    expect(adapter.edits.single['content'], '');
    expect(composerFiles(container), isEmpty);
  });

  test('without presigned uploads the file goes with the edit', () async {
    final _EditRecorder adapter = _EditRecorder();
    final ProviderContainer container = containerWith(
      adapter,
      presigned: false,
    );
    final ChatViewModel notifier = await editWithFile(container);

    await notifier.saveEditedMessage(text: 'Test');

    expect(adapter.multipartEdits.single.files.single.key, 'files[0]');
    expect(uploads.planRequests, 0);
    expect(composerFiles(container), isEmpty);
  });

  test(
    'the edit stays open until the files land, and Send does nothing meanwhile',
    () async {
      final _EditRecorder adapter = _EditRecorder();
      final ProviderContainer container = containerWith(adapter);
      final ChatViewModel notifier = await editWithFile(container);
      uploads.gate = Completer<void>();

      final Future<void> save = notifier.saveEditedMessage(text: 'Test 2');
      await paginationFlushAsync();
      await notifier.saveEditedMessage(text: 'Test 3');

      expect(
        container.read(chatViewModelProvider).editingMessage?.id,
        _messageId,
      );
      expect(composerFiles(container), hasLength(1));
      expect(adapter.edits, isEmpty);

      uploads.gate!.complete();
      await save;

      expect(adapter.edits.single['content'], 'Test 2');
      expect(uploads.planRequests, 1);
      expect(container.read(chatViewModelProvider).editingMessage, isNull);
    },
  );

  test(
    'a failed save keeps the edit and its files, and can be sent again',
    () async {
      final _EditRecorder adapter = _EditRecorder()..failEdits = true;
      final ProviderContainer container = containerWith(adapter);
      final ChatViewModel notifier = await editWithFile(container);
      notifier.updateMessageText('Test 2');

      await notifier.saveEditedMessage(text: 'Test 2');

      expect(adapter.edits, hasLength(1));
      expect(
        container.read(chatViewModelProvider).editingMessage?.id,
        _messageId,
      );
      expect(container.read(chatViewModelProvider).messageText, 'Test 2');
      expect(composerFiles(container), hasLength(1));
      expect(row(container).content, 'Test');

      adapter.failEdits = false;
      await notifier.saveEditedMessage(text: 'Test 2');

      expect(adapter.edits, hasLength(2));
      expect(uploads.planRequests, 1);
      expect(composerFiles(container), isEmpty);
      expect(container.read(chatViewModelProvider).editingMessage, isNull);
    },
  );

  test('text typed during the save stays open for the next Send', () async {
    final _EditRecorder adapter = _EditRecorder();
    final ProviderContainer container = containerWith(adapter);
    final ChatViewModel notifier = await editWithFile(container);
    uploads.gate = Completer<void>();

    final Future<void> save = notifier.saveEditedMessage(text: 'Test');
    await paginationFlushAsync();
    notifier.updateMessageText('Test and more');
    uploads.gate!.complete();
    await save;

    final Message? editing = container
        .read(chatViewModelProvider)
        .editingMessage;
    expect(editing?.attachments.map((Attachment a) => a.id), <String>['900']);
    expect(container.read(chatViewModelProvider).messageText, 'Test and more');
    expect(composerFiles(container), isEmpty);
  });

  test('removing a file being saved stops the save', () async {
    final _EditRecorder adapter = _EditRecorder();
    final ProviderContainer container = containerWith(adapter);
    final ChatViewModel notifier = await editWithFile(container);
    uploads.gate = Completer<void>();

    final Future<void> save = notifier.saveEditedMessage(text: 'Test 2');
    await paginationFlushAsync();
    await container
        .read(
          cloudUploadControllerProvider(
            readAccountUserId(container),
            _channelId,
          ).notifier,
        )
        .removeAttachment(composerFiles(container).single.id);
    uploads.gate!.complete();
    await save;

    expect(adapter.edits, isEmpty);
    expect(
      container.read(chatViewModelProvider).editingMessage?.id,
      _messageId,
    );
  });

  test('spoilering a file being saved stops the save', () async {
    final _EditRecorder adapter = _EditRecorder();
    final ProviderContainer container = containerWith(adapter);
    final ChatViewModel notifier = await editWithFile(container);
    uploads.gate = Completer<void>();

    final Future<void> save = notifier.saveEditedMessage(text: 'Test 2');
    await paginationFlushAsync();
    final PendingAttachment file = composerFiles(container).single;
    container
        .read(
          cloudUploadControllerProvider(
            readAccountUserId(container),
            _channelId,
          ).notifier,
        )
        .updateAttachment(
          file.id,
          filename: file.filename,
          description: file.description,
          flags: 8,
        );
    uploads.gate!.complete();
    await save;

    expect(adapter.edits, isEmpty);
    expect(composerFiles(container), hasLength(1));
  });

  test('closing the edit stops the save and leaves the file', () async {
    final _EditRecorder adapter = _EditRecorder();
    final ProviderContainer container = containerWith(adapter);
    final ChatViewModel notifier = await editWithFile(container);
    uploads.gate = Completer<void>();

    final Future<void> save = notifier.saveEditedMessage(text: 'Test 2');
    await paginationFlushAsync();
    notifier.cancelEdit();
    await paginationFlushAsync();
    uploads.gate!.complete();
    await save;

    expect(adapter.edits, isEmpty);
    expect(composerFiles(container), hasLength(1));
    expect(row(container).content, 'Test');
  });

  test('closing the edit stops a file being sent with it', () async {
    final _EditRecorder adapter = _EditRecorder()..holdEdit = Completer<void>();
    addTearDown(() => adapter.holdEdit?.complete());
    final ProviderContainer container = containerWith(
      adapter,
      presigned: false,
    );
    final ChatViewModel notifier = await editWithFile(container);

    final Future<void> save = notifier.saveEditedMessage(text: 'Test 2');
    await paginationFlushAsync();
    notifier.cancelEdit();
    await paginationFlushAsync();
    await save;

    expect(composerFiles(container), hasLength(1));
  });

  test(
    'a request already naming stored files finishes after the edit closes',
    () async {
      final _EditRecorder adapter = _EditRecorder()
        ..holdEdit = Completer<void>();
      final ProviderContainer container = containerWith(adapter);
      final ChatViewModel notifier = await editWithFile(container);

      final Future<void> save = notifier.saveEditedMessage(text: 'Test 2');
      await paginationFlushAsync();
      notifier.cancelEdit();
      await paginationFlushAsync();
      adapter.holdEdit!.complete();
      await save;

      expect(composerFiles(container), isEmpty);
      expect(row(container).attachments, hasLength(1));
    },
  );

  test('with no files an unchanged edit still reports no changes', () async {
    final _EditRecorder adapter = _EditRecorder();
    final ProviderContainer container = containerWith(adapter);
    final ChatViewModel notifier = await editWithFile(container);
    await container
        .read(
          cloudUploadControllerProvider(
            readAccountUserId(container),
            _channelId,
          ).notifier,
        )
        .removeAttachment(composerFiles(container).single.id);

    await notifier.saveEditedMessage(text: 'Test');

    expect(adapter.edits, isEmpty);
    expect(container.read(chatViewModelProvider).editingMessage, isNull);
  });
}
