// Fork: tyne-chat/tyne#946 — regression test for CreateThreadSheet swiped
// closed while thread creation is in flight (ensuring the created thread is
// persisted locally and its starter message is still sent without StateError).
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/core/permissions/thread_permissions.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/chat/data/message_repository.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_providers.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/friends/providers/blocked_user_ids_provider.dart';
import 'package:fluxer_app/features/threads/data/threads_repository.dart';
import 'package:fluxer_app/features/threads/presentation/create_thread_sheet.dart';
import 'package:fluxer_app/features/threads/providers/thread_ui_providers.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_dart/export.dart' hide ChannelType;

import '../../../helpers/core_test_provider_overrides.dart';
import '../../../helpers/open_test_database.dart';
import '../../../helpers/test_l10n.dart';

const String _guildId = '800';
const String _parentId = '1500';
const String _createdThreadId = '1999';

const Channel _parent = Channel(
  id: _parentId,
  guildId: _guildId,
  name: 'general',
);

Map<String, Object?> _createdThreadJson() => <String, Object?>{
  'id': _createdThreadId,
  'type': 11,
  'guild_id': _guildId,
  'parent_id': _parentId,
  'owner_id': '42',
  'name': 'Release Checklist',
  'message_count': 0,
  'total_message_sent': 0,
  'member_count': 1,
  'thread_metadata': <String, Object?>{
    'archived': false,
    'auto_archive_duration': 4320,
    'archive_timestamp': '2026-11-26T12:00:00.000Z',
    'locked': false,
    'create_timestamp': '2026-11-26T12:00:00.000Z',
  },
};

class _SlowThreadsRepository extends ThreadsRepository {
  _SlowThreadsRepository(db.FluxerDatabase database)
    : super(FluxerClient(Dio()), database);

  final Completer<StartForumThreadResponse> createCompleter =
      Completer<StartForumThreadResponse>();

  @override
  Future<StartForumThreadResponse> start({
    required String guildId,
    required String channelId,
    required StartThreadRequestBody body,
  }) {
    return createCompleter.future;
  }
}

class _RecordingMessageRepository extends Fake implements MessageRepository {
  final List<(String, String)> sentMessages = <(String, String)>[];

  @override
  Future<Message> sendMessage({
    required String channelId,
    required String content,
    String? replyToId,
    bool replyMention = true,
    String? clientNonce,
    List<String> stickerIds = const [],
    String? favoriteMemeId,
    List<dynamic>? attachmentMetadata,
    List<dynamic>? attachmentFiles,
    int? messageFlags,
    bool tts = false,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    Map<String, dynamic>? personaData,
  }) async {
    sentMessages.add((channelId, content));
    return Message(
      id: 'm-starter',
      channelId: channelId,
      authorId: '42',
      authorName: 'Alice',
      content: content,
      timestamp: DateTime.utc(2026, 11, 26, 12),
    );
  }
}

class _FakeChatViewModel extends ChatViewModel {
  final List<String> forgotten = <String>[];

  @override
  void forgetChannel(String channelId) => forgotten.add(channelId);

  @override
  ChatViewState build() => const ChatViewState(
    channelId: _parentId,
    messages: <Message>[],
    replyingTo: null,
    replyMentioning: false,
    editingMessage: null,
    messageText: '',
    scrollToBottomSignal: 0,
    isLoading: false,
    isSyncingMessages: false,
    isLoadingMore: false,
    isLoadingNewer: false,
    hasMoreMessages: false,
    hasMoreNewerMessages: false,
    errorMessage: null,
  );
}

void main() {
  testWidgets(
    'dismissing CreateThreadSheet while thread creation is in flight still persists the thread and sends the starter message without StateError',
    (WidgetTester tester) async {
      final db.FluxerDatabase database = openTestDatabase();
      final _SlowThreadsRepository threads = _SlowThreadsRepository(database);
      final _RecordingMessageRepository messages =
          _RecordingMessageRepository();
      final _FakeChatViewModel chat = _FakeChatViewModel();
      final colorTheme = buildDarkColorTheme();

      await tester.pumpWidget(
        ProviderScope(
          overrides: coreTestProviderOverrides(
            database: database,
            extra: [
              blockedUserIdsProvider.overrideWithValue(const <String>{}),
              threadsRepositoryProvider.overrideWithValue(threads),
              messageRepositoryProvider.overrideWithValue(messages),
              chatViewModelProvider.overrideWith(() => chat),
              parentThreadActorProvider(_guildId, _parentId).overrideWithValue(
                ThreadActor(
                  permissions:
                      Permission.viewChannel.value |
                      Permission.sendMessages.value |
                      Permission.readMessageHistory.value |
                      Permission.createPublicThreads.value |
                      Permission.sendMessagesInThreads.value,
                ),
              ),
            ],
          ),
          child: MaterialApp(
            navigatorKey: rootNavigatorKey,
            locale: kTestLocale,
            localizationsDelegates: fluxerLocalizationsDelegates,
            supportedLocales: FluxerLocalizations.supportedLocales,
            theme: buildFluxerTheme(
              colorTheme: colorTheme,
              textTheme: FluxerTextTheme.fromColors(colorTheme),
              layoutTheme: FluxerLayoutTheme.scaled(),
            ),
            home: Scaffold(
              body: Consumer(
                builder: (BuildContext context, WidgetRef ref, _) => Center(
                  child: ElevatedButton(
                    onPressed: () =>
                        showCreateThreadSheet(context, ref, parent: _parent),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final Finder textFields = find.byType(EditableText);
      expect(textFields, findsNWidgets(2));
      await tester.enterText(textFields.at(0), 'Release Checklist');
      await tester.enterText(textFields.at(1), 'Starter details here');
      await tester.pump();

      await tester.tap(find.text(testL10n.threadCreate).last);
      await tester.pump();

      // User swipes down / pops the bottom sheet while POST /threads is still
      // awaiting network completion.
      rootNavigatorKey.currentState!.pop();
      await tester.pumpAndSettle();

      // Now POST /threads resolves on the server.
      threads.createCompleter.complete(
        StartForumThreadResponse.fromJson(_createdThreadJson()),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final db.Channel? saved = await database.channelDao.getChannelById(
        _createdThreadId,
      );
      expect(saved, isNotNull);
      expect(chat.forgotten, <String>[_createdThreadId]);
      expect(messages.sentMessages, <(String, String)>[
        (_createdThreadId, 'Starter details here'),
      ]);
    },
  );
}
