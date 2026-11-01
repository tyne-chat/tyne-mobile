// Fork: tyne-chat/tyne#293. An edit's files upload from the composer, so a failure leaves them there.
import 'dart:async';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:fluxer_app/features/chat/data/prepared_attachments.dart';
import 'package:fluxer_app/features/chat/domain/message_upload_send_cancelled_exception.dart';
import 'package:fluxer_app/features/chat/domain/pending_attachment.dart';
import 'package:fluxer_app/features/chat/providers/upload/attachment_upload_client_provider.dart';
import 'package:fluxer_app/features/chat/providers/upload/cloud_upload_controller.dart';
import 'package:fluxer_app/features/chat/providers/upload/user_upload_limits_provider.dart';
import 'package:fluxer_app/features/chat/utils/composer/composer_upload_file.dart';

import '../../../../helpers/fake_attachment_upload_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAttachmentUploadClient client;
  late Directory tempDir;

  setUp(() async {
    client = FakeAttachmentUploadClient(apiDio: Dio(), uploadDio: Dio());
    tempDir = await Directory.systemTemp.createTemp('cloud_upload_edit_fork');
    addTearDown(() => tempDir.delete(recursive: true));
  });

  Future<(ProviderContainer, CloudUploadController, int)> withFile({
    bool presigned = true,
  }) async {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        maxAttachmentFileBytesProvider.overrideWithValue(1024 * 1024),
        attachmentUploadClientProvider.overrideWithValue(client),
        instanceRuntimeConfigProvider.overrideWithValue(
          testInstanceRuntimeConfig(presignedAttachmentUploads: presigned),
        ),
      ],
    );
    addTearDown(container.dispose);
    final CloudUploadController controller = container.read(
      cloudUploadControllerProvider('channel-1').notifier,
    );
    final File file = File('${tempDir.path}/a.png')..writeAsBytesSync(<int>[1]);
    await controller.addFiles(composerUploadFiles(<XFile>[XFile(file.path)]));
    final int id = container
        .read(cloudUploadControllerProvider('channel-1'))
        .items
        .single
        .id;
    return (container, controller, id);
  }

  List<PendingAttachment> composerFiles(ProviderContainer container) =>
      container.read(cloudUploadControllerProvider('channel-1')).items;

  test('uploaded files are named and stay in the composer', () async {
    final (container, controller, id) = await withFile();

    final PreparedAttachments prepared = await controller.prepareComposerFiles(
      <int>[id],
    );

    expect(prepared.attachmentFiles, isNull);
    expect(prepared.attachmentMetadata!.single.uploadFilename, 'stored-a.png');
    expect(composerFiles(container).single.id, id);
  });

  test('a save joins a pre-upload already running', () async {
    final (container, controller, id) = await withFile();
    client.gate = Completer<void>();
    final Future<PreparedAttachments> first = controller.prepareComposerFiles(
      <int>[id],
    );
    final Future<PreparedAttachments> second = controller.prepareComposerFiles(
      <int>[id],
    );
    await pumpEventQueue();

    client.gate!.complete();
    await Future.wait(<Future<PreparedAttachments>>[first, second]);

    expect(client.planRequests, 1);
  });

  test('a failed upload falls back to sending the file', () async {
    final (container, controller, id) = await withFile();
    client.failUploads = true;

    final PreparedAttachments prepared = await controller.prepareComposerFiles(
      <int>[id],
    );

    expect(prepared.attachmentFiles, hasLength(1));
    expect(prepared.attachmentMetadata!.single.uploadFilename, isNull);
    expect(
      composerFiles(container).single.status,
      PendingAttachmentStatus.pending,
    );
  });

  test('without presigned uploads the file goes with the request', () async {
    final (_, controller, id) = await withFile(presigned: false);

    final PreparedAttachments prepared = await controller.prepareComposerFiles(
      <int>[id],
    );

    expect(prepared.attachmentFiles, hasLength(1));
    expect(client.planRequests, 0);
  });

  test('a file removed during the upload stops the preparation', () async {
    final (_, controller, id) = await withFile();
    client.gate = Completer<void>();
    final Future<PreparedAttachments> prepared = controller
        .prepareComposerFiles(<int>[id]);
    await pumpEventQueue();
    final Future<void> stopped = expectLater(
      prepared,
      throwsA(isA<MessageUploadSendCancelledException>()),
    );

    await controller.removeAttachment(id);

    await stopped;
  });
}
