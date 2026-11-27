// Fork: tyne-chat/tyne#946 — regression tests for showSystemMessageActionsSheet
// and showDeleteMessageConfirmSheet / showDeleteAttachmentConfirmSheet when the
// originating chat host unmounts while the root-navigator sheet is open.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart'
    show FluxerDatabase;
import 'package:fluxer_app/core/limits/instance_limit_provider.dart';
import 'package:fluxer_app/core/limits/limit_key.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/sheets/delete_message_confirm_sheet.dart';
import 'package:fluxer_app/features/chat/presentation/sheets/system_message_actions_sheet.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/message_actions/quick_reaction_row.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/chat/providers/messages/saved_message_provider.dart';
import 'package:fluxer_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:fluxer_app/material_ui.dart';

import '../../../../helpers/core_test_provider_overrides.dart';
import '../../../../helpers/open_test_database.dart';
import '../../../../helpers/test_l10n.dart';

const String _messageId = 'sys-m1';

class _FakeUser extends UserSettingsViewModel {
  @override
  UserSettingsViewState build() => const UserSettingsViewState(
    userId: 'viewer',
    username: 'viewer',
    displayName: 'viewer',
    discriminator: '0001',
    avatar: null,
    avatarColor: null,
    memberSince: null,
    status: 'online',
    messageDisplayCompact: false,
    developerMode: true,
    trustedDomains: <String>[],
  );
}

class _RecordingChatViewModel extends ChatViewModel {
  final List<String> deletedMessages = <String>[];
  final List<(String, String)> deletedAttachments = <(String, String)>[];
  final List<(String, String)> toggledReactions = <(String, String)>[];

  @override
  ChatViewState build() => const ChatViewState(
    channelId: 'c1',
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

  @override
  Future<void> deleteMessage(String messageId) async {
    deletedMessages.add(messageId);
  }

  @override
  Future<void> deleteMessageAttachment({
    required String messageId,
    required String attachmentId,
  }) async {
    deletedAttachments.add((messageId, attachmentId));
  }

  @override
  Future<void> toggleReaction(
    String messageId,
    String emoji, {
    String? emojiId,
    bool animated = false,
    String? personaId,
    bool explicitRoot = false,
  }) async {
    toggledReactions.add((messageId, emoji));
  }
}

Message _systemMessage() => Message(
  id: _messageId,
  channelId: 'c1',
  authorId: 'viewer',
  authorName: 'viewer',
  content: '',
  timestamp: DateTime.utc(2026, 11, 26),
  type: messageTypeChannelPinnedMessage,
);

Widget _mountSwitchableHost({
  required FluxerDatabase db,
  required _RecordingChatViewModel chat,
  required ValueNotifier<bool> mountHost,
  required void Function(BuildContext context, WidgetRef ref) onOpen,
}) {
  final colorTheme = buildDarkColorTheme();
  return ProviderScope(
    overrides: coreTestProviderOverrides(
      database: db,
      extra: [
        chatViewModelProvider.overrideWith(() => chat),
        userSettingsViewModelProvider.overrideWith(_FakeUser.new),
        isMessageSavedProvider(
          _messageId,
        ).overrideWith((ref) => Stream<bool>.value(false)),
        instanceFeatureEnabledProvider(
          LimitKeys.featureGlobalExpressions,
        ).overrideWith((ref) => false),
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
        body: ValueListenableBuilder<bool>(
          valueListenable: mountHost,
          builder: (_, bool mounted, _) {
            if (!mounted) {
              return const SizedBox.shrink();
            }
            return Consumer(
              builder: (BuildContext context, WidgetRef ref, _) => Center(
                child: ElevatedButton(
                  onPressed: () => onOpen(context, ref),
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'deleting a system message succeeds without StateError when the originating chat host unmounts before confirmation',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final FluxerDatabase db = openTestDatabase();
      final _RecordingChatViewModel chat = _RecordingChatViewModel();
      final ValueNotifier<bool> mountHost = ValueNotifier<bool>(true);
      addTearDown(mountHost.dispose);
      final Message message = _systemMessage();

      await tester.pumpWidget(
        _mountSwitchableHost(
          db: db,
          chat: chat,
          mountHost: mountHost,
          onOpen: (BuildContext context, WidgetRef ref) => unawaited(
            showSystemMessageActionsSheet(
              context,
              ref,
              message: message,
              guildId: 'g1',
              isDmChannel: false,
              canDelete: true,
              canAddReactions: true,
              canManageMessages: true,
              currentUserId: 'viewer',
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Unmount the originating chat host (simulating a channel switch or route
      // change while the root-navigator action sheet is open).
      mountHost.value = false;
      await tester.pump();

      // Tap "Delete message" in the system message bottom sheet.
      await tester.ensureVisible(find.text(testL10n.chatMessageDelete));
      await tester.pumpAndSettle();
      await tester.tap(find.text(testL10n.chatMessageDelete));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Confirm deletion on the FluxerConfirmSheet presented on rootNavigatorKey.
      await tester.tap(find.text(testL10n.chatMessageDelete).last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(chat.deletedMessages, <String>[_messageId]);
    },
  );

  testWidgets(
    'tapping a quick reaction on a system message sheet succeeds when the originating chat host unmounts',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final FluxerDatabase db = openTestDatabase();
      final _RecordingChatViewModel chat = _RecordingChatViewModel();
      final ValueNotifier<bool> mountHost = ValueNotifier<bool>(true);
      addTearDown(mountHost.dispose);
      final Message message = _systemMessage();

      await tester.pumpWidget(
        _mountSwitchableHost(
          db: db,
          chat: chat,
          mountHost: mountHost,
          onOpen: (BuildContext context, WidgetRef ref) => unawaited(
            showSystemMessageActionsSheet(
              context,
              ref,
              message: message,
              guildId: 'g1',
              isDmChannel: false,
              canDelete: true,
              canAddReactions: true,
              canManageMessages: true,
              currentUserId: 'viewer',
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Unmount the originating chat host while the action sheet stays open.
      mountHost.value = false;
      await tester.pump();

      final QuickReactionRow row = tester.widget(find.byType(QuickReactionRow));
      row.onReaction(const UnicodeQuickReaction('👍'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(chat.toggledReactions, <(String, String)>[(_messageId, '👍')]);
    },
  );

  testWidgets(
    'confirming attachment deletion succeeds without StateError when the originating widget unmounts',
    (WidgetTester tester) async {
      final FluxerDatabase db = openTestDatabase();
      final _RecordingChatViewModel chat = _RecordingChatViewModel();
      final ValueNotifier<bool> mountHost = ValueNotifier<bool>(true);
      addTearDown(mountHost.dispose);

      await tester.pumpWidget(
        _mountSwitchableHost(
          db: db,
          chat: chat,
          mountHost: mountHost,
          onOpen: (BuildContext context, WidgetRef ref) => unawaited(
            showDeleteAttachmentConfirmSheet(
              context,
              ref,
              messageId: _messageId,
              attachment: const Attachment(
                id: 'att-1',
                filename: 'notes.txt',
                size: 42,
                url:
                    'https://fluxerusercontent.com/attachments/att-1/notes.txt',
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      mountHost.value = false;
      await tester.pump();

      await tester.tap(find.text(testL10n.chatMessageDeleteAttachment).last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(chat.deletedAttachments, <(String, String)>[
        (_messageId, 'att-1'),
      ]);
    },
  );
}
