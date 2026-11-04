// Fork: tyne-chat/tyne#293. An edit with files keeps its text in the composer until they land.
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/limits/instance_limit_provider.dart';
import 'package:fluxer_app/core/limits/limit_key.dart';
import 'package:fluxer_app/core/providers/app/account_user_id.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/chat/providers/upload/cloud_upload_controller.dart';
import 'package:fluxer_app/features/chat/utils/composer/composer_upload_file.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../helpers/composer_channel_textarea_harness.dart';

const MethodChannel _recorder = MethodChannel('com.llfbandit.record/messages');

Finder _send() => find.byKey(const ValueKey<String>('mobile-composer-send'));

Message _edited({List<Attachment> attachments = const <Attachment>[]}) =>
    Message(
      id: '1',
      channelId: kComposerHarnessChannelA,
      authorId: kComposerHarnessUserId,
      authorName: 'me',
      content: 'Test',
      timestamp: DateTime.utc(2026, 11),
      attachments: attachments,
    );

Future<void> _addFile(ProviderContainer container, Directory dir) async {
  final File file = File('${dir.path}/a.png')..writeAsBytesSync(<int>[1]);
  await container
      .read(
        cloudUploadControllerProvider(
          readAccountUserId(container),
          kComposerHarnessChannelA,
        ).notifier,
      )
      .addFiles(composerUploadFiles(<XFile>[XFile(file.path)]));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('composer_edit_files');
    addTearDown(() => dir.deleteSync(recursive: true));
    // The composer can set up the voice recorder, whose plugin tests do not have.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_recorder, (_) async => null);
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_recorder, null),
    );
    // The composer builds the signal bar, which reads SharedPreferences. Unmocked, its
    // MissingPluginException failed a test whenever it landed during the tests' real-async
    // file adds (tyne-chat/tyne#475).
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<(ProviderContainer, MutableChatViewModel)> editing(
    WidgetTester tester, {
    Message? message,
    int? limit,
  }) async {
    final ProviderContainer container =
        await pumpComposerChannelTextareaHarness(
          tester,
          extraOverrides: <Override>[
            if (limit != null)
              instanceLimitProvider(
                LimitKeys.maxAttachmentsPerMessage,
              ).overrideWithValue(limit),
          ],
        );
    final MutableChatViewModel vm =
        container.read(chatViewModelProvider.notifier) as MutableChatViewModel
          ..setEditing(message: message ?? _edited(), messageText: 'Test');
    await tester.pump();
    return (container, vm);
  }

  testWidgets('Send keeps the text in the composer while files land', (
    WidgetTester tester,
  ) async {
    final (ProviderContainer container, MutableChatViewModel vm) =
        await editing(tester);
    await tester.runAsync(() => _addFile(container, dir));
    await tester.pump();

    await tester.tap(_send());
    await tester.pump();

    expect(vm.sentTexts, hasLength(1));
    expect(container.read(chatViewModelProvider).messageText, 'Test');
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      isNotEmpty,
    );
  });

  testWidgets('files past the limit are not sent', (WidgetTester tester) async {
    final (
      ProviderContainer container,
      MutableChatViewModel vm,
    ) = await editing(
      tester,
      limit: 1,
      message: _edited(
        attachments: const <Attachment>[
          Attachment(id: '9', filename: 'old.png', url: 'https://x/y'),
        ],
      ),
    );
    await tester.runAsync(() => _addFile(container, dir));
    await tester.pump();

    await tester.tap(_send());
    await tester.pump();

    expect(vm.sentTexts, isEmpty);
    expect(
      container
          .read(
            cloudUploadControllerProvider(
              readAccountUserId(container),
              kComposerHarnessChannelA,
            ),
          )
          .items,
      hasLength(1),
    );
  });
}
