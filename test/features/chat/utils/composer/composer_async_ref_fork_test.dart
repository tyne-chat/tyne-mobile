// Fork: tyne-chat/tyne#946 — regression tests for composer async WidgetRef
// hazards: clipboard attachment paste, `/msg` DM send + error fallback, and
// `/nick` system message insertion when the composer unmounts mid-flight.
import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/chat/data/message_repository.dart';
import 'package:fluxer_app/features/chat/domain/api_attachment_metadata.dart';
import 'package:fluxer_app/features/chat/domain/cloud_composer_attachments.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_providers.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/chat/providers/upload/cloud_upload_controller.dart';
import 'package:fluxer_app/features/chat/utils/attachments/file_upload_validator.dart';
import 'package:fluxer_app/features/chat/utils/composer/composer_clipboard_paste.dart';
import 'package:fluxer_app/features/chat/utils/composer/composer_command.dart';
import 'package:fluxer_app/features/chat/utils/composer/composer_command_execute.dart';
import 'package:fluxer_app/features/chat/utils/composer/composer_upload_file.dart';
import 'package:fluxer_app/features/dm/data/dm_repository.dart';
import 'package:fluxer_app/features/dm/providers/dm_providers.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_clipboard/src/messages.g.dart';
import 'package:fluxer_dart/export.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/core_test_provider_overrides.dart';
import '../../../../helpers/open_test_database.dart';
import '../../../../helpers/test_account_user_id.dart';
import '../../../../helpers/test_l10n.dart';

class _RecordingCloudUploadController extends CloudUploadController {
  _RecordingCloudUploadController(this.uploadedFiles);

  final List<(int length, String? mimeType)> uploadedFiles;

  @override
  CloudComposerAttachments build(String accountUserId, String channelId) =>
      CloudComposerAttachments.empty;

  @override
  Future<FileUploadValidationResult> addFiles(
    List<ComposerUploadFile> files,
  ) async {
    for (final ComposerUploadFile file in files) {
      uploadedFiles.add((await file.file.length(), file.file.mimeType));
    }
    return const FileUploadValidationResult.success();
  }
}

class _SlowDmRepository extends Fake implements DmRepository {
  final Completer<String> ensureCompleter = Completer<String>();

  @override
  Future<String> ensureDmChannel(String recipientId) => ensureCompleter.future;
}

class _RecordingMessageRepository extends MessageRepository {
  _RecordingMessageRepository(db.FluxerDatabase database)
    : super(FluxerClient(Dio()), Dio(), database, kTestAccountUserId);

  final List<(String channelId, String content)> sent =
      <(String channelId, String content)>[];

  @override
  Future<Message> sendMessage({
    required String channelId,
    required String content,
    String? replyToId,
    bool replyMention = true,
    String? clientNonce,
    List<String> stickerIds = const <String>[],
    String? favoriteMemeId,
    List<ApiAttachmentMetadata>? attachmentMetadata,
    List<XFile>? attachmentFiles,
    int? messageFlags,
    bool tts = false,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    Map<String, dynamic>? personaData,
  }) async {
    sent.add((channelId, content));
    return Message(
      id: 'm1',
      channelId: channelId,
      authorId: kTestAccountUserId,
      authorName: 'Me',
      content: content,
      timestamp: DateTime.utc(2026, 11, 26),
    );
  }
}

class _RecordingChatViewModel extends ChatViewModel {
  _RecordingChatViewModel(this.systemMessages);

  final List<String> systemMessages;

  @override
  ChatViewState build() => ChatViewState.empty;

  @override
  void insertClientSystemMessage(String content) {
    systemMessages.add(content);
  }
}

class _SlowGuildsApi implements GuildsApi {
  final Completer<GuildMemberResponse> nickCompleter =
      Completer<GuildMemberResponse>();

  @override
  Future<GuildMemberResponse> updateCurrentGuildMember({
    required String guildId,
    MyGuildMemberUpdateRequest? body,
  }) => nickCompleter.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GuildsTestClient extends FluxerClient {
  _GuildsTestClient(this._guilds) : super(Dio());

  final GuildsApi _guilds;

  @override
  GuildsApi get guilds => _guilds;
}

void main() {
  testWidgets(
    'handleComposerPaste queues clipboard image attachment without StateError when composer unmounts while native clipboard readItems is in flight',
    (WidgetTester tester) async {
      final db.FluxerDatabase database = openTestDatabase();
      final List<(int, String?)> uploadedFiles = <(int, String?)>[];
      final Completer<List<NativeClipboardItem>> readItemsCompleter =
          Completer<List<NativeClipboardItem>>();

      final TestDefaultBinaryMessenger messenger =
          tester.binding.defaultBinaryMessenger..setMockMethodCallHandler(
            SystemChannels.platform,
            (MethodCall call) async {
              switch (call.method) {
                case 'Clipboard.getData':
                  return null;
                case 'Clipboard.hasStrings':
                  return <String, Object?>{'value': false};
                default:
                  return null;
              }
            },
          );
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );

      const String readTextChannel =
          'dev.flutter.pigeon.fluxer_clipboard.ClipboardHostApi.readText';
      const String readItemsChannel =
          'dev.flutter.pigeon.fluxer_clipboard.ClipboardHostApi.readItems';
      const MessageCodec<Object?> codec = ClipboardHostApi.pigeonChannelCodec;

      messenger
        ..setMockDecodedMessageHandler<Object?>(
          const BasicMessageChannel<Object?>(readTextChannel, codec),
          (_) async => <Object?>[null],
        )
        ..setMockDecodedMessageHandler<Object?>(
          const BasicMessageChannel<Object?>(readItemsChannel, codec),
          (_) async => <Object?>[await readItemsCompleter.future],
        );
      addTearDown(() {
        messenger
          ..setMockDecodedMessageHandler<Object?>(
            const BasicMessageChannel<Object?>(readTextChannel, codec),
            null,
          )
          ..setMockDecodedMessageHandler<Object?>(
            const BasicMessageChannel<Object?>(readItemsChannel, codec),
            null,
          );
      });

      final TextEditingController textController = TextEditingController();
      addTearDown(textController.dispose);
      final ValueNotifier<bool> mountComposer = ValueNotifier<bool>(true);
      addTearDown(mountComposer.dispose);

      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: database,
          extra: [
            cloudUploadControllerProvider(
              kTestAccountUserId,
              'c1',
            ).overrideWith(
              () => _RecordingCloudUploadController(uploadedFiles),
            ),
          ],
        ),
      );
      addTearDown(container.dispose);

      Object? pasteError;
      bool? pasteResult;
      final colorTheme = buildDarkColorTheme();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: kTestLocale,
            localizationsDelegates: fluxerLocalizationsDelegates,
            supportedLocales: FluxerLocalizations.supportedLocales,
            theme: buildFluxerTheme(
              colorTheme: colorTheme,
              textTheme: FluxerTextTheme.fromColors(colorTheme),
              layoutTheme: FluxerLayoutTheme.scaled(),
            ),
            home: Scaffold(
              body: ValueListenableBuilder<bool>(
                valueListenable: mountComposer,
                builder: (_, bool mounted, _) {
                  if (!mounted) {
                    return const SizedBox.shrink();
                  }
                  return Consumer(
                    builder: (_, WidgetRef ref, _) => ElevatedButton(
                      onPressed: () {
                        unawaited(
                          handleComposerPaste(
                            ref: ref,
                            channelId: 'c1',
                            controller: textController,
                            isAttachEnabled: true,
                          ).then(
                            (bool ok) => pasteResult = ok,
                            onError: (Object e) => pasteError = e,
                          ),
                        );
                      },
                      child: const Text('Paste'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Paste'));
      await tester.pump();
      await tester.pump();

      // Unmount the composer while `readItems` is awaiting native clipboard I/O.
      mountComposer.value = false;
      await tester.pump();

      readItemsCompleter.complete(<NativeClipboardItem>[
        NativeClipboardItem(
          data: Uint8List.fromList(<int>[0x89, 0x50, 0x4E, 0x47, 1, 2, 3, 4]),
          mimeType: 'image/png',
          name: 'shot.png',
        ),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(tester.takeException(), isNull);
      expect(pasteError, isNull);
      expect(pasteResult, isTrue);
      expect(uploadedFiles, <(int, String?)>[(8, 'image/png')]);
    },
  );

  testWidgets(
    'executeComposerSideEffect completes /msg send + DM navigation and /nick system message without StateError when composer unmounts mid-flight',
    (WidgetTester tester) async {
      final db.FluxerDatabase database = openTestDatabase();
      final _SlowDmRepository dmRepo = _SlowDmRepository();
      final _RecordingMessageRepository msgRepo = _RecordingMessageRepository(
        database,
      );
      final List<String> systemMessages = <String>[];
      final _SlowGuildsApi guildsApi = _SlowGuildsApi();
      final GoRouter router = GoRouter(
        initialLocation: '/',
        routes: <RouteBase>[
          GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink()),
          GoRoute(
            path: '/channels/@me/:channelId',
            builder: (_, _) => const SizedBox.shrink(),
          ),
        ],
      );
      addTearDown(router.dispose);

      final ValueNotifier<bool> mountComposer = ValueNotifier<bool>(true);
      addTearDown(mountComposer.dispose);

      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: database,
          extra: [
            dmRepositoryProvider.overrideWithValue(dmRepo),
            messageRepositoryProvider.overrideWithValue(msgRepo),
            chatViewModelProvider.overrideWith(
              () => _RecordingChatViewModel(systemMessages),
            ),
            fluxerClientProvider.overrideWithValue(
              _GuildsTestClient(guildsApi),
            ),
            fluxerRouterProvider.overrideWithValue(router),
          ],
        ),
      );
      addTearDown(container.dispose);

      Object? msgError;
      Object? nickError;
      final colorTheme = buildDarkColorTheme();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            locale: kTestLocale,
            localizationsDelegates: fluxerLocalizationsDelegates,
            supportedLocales: FluxerLocalizations.supportedLocales,
            theme: buildFluxerTheme(
              colorTheme: colorTheme,
              textTheme: FluxerTextTheme.fromColors(colorTheme),
              layoutTheme: FluxerLayoutTheme.scaled(),
            ),
            builder: (_, Widget? child) => Scaffold(
              body: Column(
                children: <Widget>[
                  Expanded(child: child ?? const SizedBox.shrink()),
                  ValueListenableBuilder<bool>(
                    valueListenable: mountComposer,
                    builder: (_, bool mounted, _) {
                      if (!mounted) {
                        return const SizedBox.shrink();
                      }
                      return Consumer(
                        builder: (_, WidgetRef ref, _) => ElevatedButton(
                          onPressed: () {
                            unawaited(
                              executeComposerSideEffect(
                                ref: ref,
                                command: const ComposerMsgCommand(
                                  userId: 'bob-id',
                                  message: 'hey bob',
                                ),
                                channelId: 'c1',
                                guildId: 'g1',
                                l10n: testL10n,
                              ).catchError((Object e) {
                                msgError = e;
                              }),
                            );
                            unawaited(
                              executeComposerSideEffect(
                                ref: ref,
                                command: const ComposerNickCommand('Trinity'),
                                channelId: 'c1',
                                guildId: 'g1',
                                l10n: testL10n,
                              ).catchError((Object e) {
                                nickError = e;
                              }),
                            );
                          },
                          child: const Text('Run Slash Commands'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Run Slash Commands'));
      await tester.pump();

      // Switch channels / unmount composer while `/msg` and `/nick` await HTTP.
      mountComposer.value = false;
      await tester.pump();

      dmRepo.ensureCompleter.complete('dm-bob');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(msgError, isNull);
      expect(msgRepo.sent, <(String, String)>[('dm-bob', 'hey bob')]);
      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/channels/@me/dm-bob',
      );

      guildsApi.nickCompleter.complete(
        GuildMemberResponse.fromJson(<String, Object?>{
          'joined_at': '2026-11-26T00:00:00.000Z',
          'user': <String, Object?>{'id': kTestAccountUserId, 'username': 'me'},
        }),
      );
      await tester.pump();

      expect(nickError, isNull);
      expect(systemMessages, hasLength(1));
      expect(systemMessages.single, contains('Trinity'));
      expect(tester.takeException(), isNull);
    },
  );
}
