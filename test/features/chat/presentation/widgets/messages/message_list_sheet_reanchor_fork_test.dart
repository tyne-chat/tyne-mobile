// Fork: tyne-chat/tyne#942. When a jump anchors the message list at 0.50 while
// the soft keyboard is up and long-pressing a message opens the action sheet,
// hiding the keyboard grows the viewport, trips underfill bottom reanchor
// (_anchorEpoch++), and unmounts the MessageItem that opened the sheet. Quick
// reactions, menu items, and sheet dismissal must all keep working cleanly.

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/limits/instance_limit_provider.dart';
import 'package:fluxer_app/core/limits/limit_key.dart';
import 'package:fluxer_app/core/permissions/channel_permission_cache_provider.dart';
import 'package:fluxer_app/core/router/route_state_providers.dart';
import 'package:fluxer_app/core/synced_preferences/usage_frecency.dart';
import 'package:fluxer_app/features/chat/domain/favorite_meme.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/message_actions/message_bottom_sheet.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/message_actions/quick_reaction_row.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/messages/message_list.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/messages/message_list_viewport.dart';
import 'package:fluxer_app/features/chat/providers/messages/message_translation_provider.dart';
import 'package:fluxer_app/features/chat/providers/messages/saved_message_provider.dart';
import 'package:fluxer_app/features/chat/providers/pickers/emoji_picker_provider.dart';
import 'package:fluxer_app/features/chat/providers/pickers/expression_usage_provider.dart';
import 'package:fluxer_app/features/chat/providers/pickers/favorite_media_provider.dart';
import 'package:fluxer_app/features/emoji/domain/emoji_pins.dart';
import 'package:fluxer_app/features/emoji/providers/emoji_pins_provider.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/providers/persona_blocks_provider.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/shared/utils/emoji/emoji_registry.dart';
import 'package:fluxer_app/shared/widgets/unicode_emoji_widget.dart';

import '../../../../../helpers/instance_runtime_config_override.dart';
import '../../../../../helpers/test_l10n.dart';
import 'message_list_test_harness.dart';

class _RecordingChatViewModel extends InstrumentedChatViewModel {
  _RecordingChatViewModel(super.initialState);

  final List<(String messageId, String emoji)> toggledReactions =
      <(String, String)>[];
  final List<String> repliedMessageIds = <String>[];

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

  @override
  void startReply(Message message) {
    repliedMessageIds.add(message.id);
  }
}

class _NoPersonas extends MyPersonasNotifier {
  @override
  AsyncValue<List<Persona>> build() =>
      const AsyncData<List<Persona>>(<Persona>[]);
}

class _NoBlockedPersonas extends PersonaBlocksNotifier {
  @override
  Set<String> build() => const <String>{};
}

class _EmptyEmojiPins extends EmojiPinsNotifier {
  @override
  Future<EmojiPins> build() async => EmojiPins.empty;
}

class _RecordingExpressionUsage extends ExpressionUsage {
  final List<String> trackedKeys = <String>[];

  @override
  Future<Map<String, UsageEntry>> build(ExpressionUsageKind kind) async =>
      const <String, UsageEntry>{};

  @override
  Future<void> track(String key) async {
    trackedKeys.add(key);
  }
}

/// Simulates the soft keyboard sharing vertical space beneath [MessageList].
class _KeyboardHost extends StatelessWidget {
  const _KeyboardHost({required this.keyboardHeight});

  final ValueNotifier<double> keyboardHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Expanded(
          child: MessageList(expectedChannelId: messageListChannelId),
        ),
        ValueListenableBuilder<double>(
          valueListenable: keyboardHeight,
          builder: (BuildContext context, double height, Widget? _) =>
              SizedBox(height: height),
        ),
      ],
    );
  }
}

Future<void> _pumpAsyncFrames(WidgetTester tester, {int count = 8}) async {
  for (int i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
  }
}

/// Reproduces the exact push-notification jump + long-press sequence:
/// 1. Keyboard is open (260 px), leaving a shorter viewport.
/// 2. Jump (`scrollToMessage`) targets the second-to-last message, anchoring
///    the list at 0.50 while the newer message below still overflows the
///    keyboard-shortened viewport (`maxScrollExtent > 0`).
/// 3. Long-pressing the target message opens `showMessageBottomSheet`.
/// 4. Opening the modal sheet hides the keyboard (`keyboardHeight = 0`),
///    growing the viewport so `maxScrollExtent <= 0`, which triggers
///    `_scheduleUnderfillBottomReanchor` (`_anchorEpoch++`) and unmounts the
///    `MessageItem` that opened the still-visible sheet.
Future<
  ({
    _RecordingChatViewModel chat,
    _RecordingExpressionUsage usage,
    String targetId,
    ValueNotifier<double> keyboardHeight,
  })
>
_openSheetAndTriggerUnderfillReanchor(WidgetTester tester) async {
  configureMessageListViewport(tester);
  final ValueNotifier<double> keyboardHeight = ValueNotifier<double>(260);
  addTearDown(keyboardHeight.dispose);

  final AroundAckMessageListHarness base = await createBottomMessageListHarness(
    messageCount: 30,
  );
  // Give the newest message a few lines so that with the 260 px keyboard open,
  // content below the second-to-last message's 0.50 anchor overflows (> 0),
  // whereas once the keyboard closes (0 px) it underfills (<= 0).
  final List<Message> seeded = List<Message>.of(base.messages);
  final Message last = seeded.last;
  seeded[seeded.length - 1] = harnessMessage(
    id: last.id,
    content: List<String>.generate(8, (int i) => 'newest line $i').join('\n'),
    timestamp: last.timestamp,
  );
  final String targetId = seeded[seeded.length - 2].id;

  final _RecordingChatViewModel chat = _RecordingChatViewModel(
    detachedState(seeded, hasMoreNewer: false),
  );
  final _RecordingExpressionUsage usage = _RecordingExpressionUsage();
  addTearDown(() => tester.runAsync(base.database.close));

  await tester.pumpWidget(
    messageListApp(
      database: base.database,
      chatViewModel: chat,
      disableMessageListAnimations: false,
      body: _KeyboardHost(keyboardHeight: keyboardHeight),
      overrides: [
        instanceRuntimeConfigOverride(),
        contextualGuildIdProvider.overrideWithValue(null),
        channelPermissionCacheProvider(
          messageListCurrentUserId,
        ).overrideWithValue(
          const ChannelPermissionCaches(
            effective: <String, int>{messageListChannelId: -1},
          ),
        ),
        instanceFeatureEnabledProvider(
          LimitKeys.featureGlobalExpressions,
        ).overrideWithValue(false),
        rankedEmojiUsageKeysProvider.overrideWithValue(
          const AsyncData<List<String>>(<String>[]),
        ),
        expressionUsageProvider(
          ExpressionUsageKind.emoji,
        ).overrideWith(() => usage),
        emojiPinsProvider.overrideWith(_EmptyEmojiPins.new),
        myPersonasProvider.overrideWith(_NoPersonas.new),
        blockedPersonaKeysProvider.overrideWith(_NoBlockedPersonas.new),
        isMessageSavedProvider(
          targetId,
        ).overrideWith((ref) => Stream<bool>.value(false)),
        favoriteMemesProvider.overrideWith(
          (ref) => Stream<List<FavoriteMeme>>.value(const <FavoriteMeme>[]),
        ),
        messageTranslationAvailableProvider.overrideWith(
          (ref) => Future<bool>.value(false),
        ),
      ],
    ),
  );
  await _pumpAsyncFrames(tester);

  // Jump in-place (as a push notification tap on the active channel does).
  chat.scrollToMessage(targetId);
  await _pumpAsyncFrames(tester);

  final MessageListViewport jumpedViewport = tester.widget<MessageListViewport>(
    find.byType(MessageListViewport),
  );
  expect(
    jumpedViewport.anchorFraction,
    lessThan(1.0),
    reason: 'With the keyboard open, the jumped message stays anchored at 0.50',
  );
  expect(
    messageListScrollPosition(tester).maxScrollExtent,
    greaterThan(0),
    reason: 'Newer message overflows the keyboard-shortened viewport',
  );

  final int epochBeforeSheet = jumpedViewport.anchorEpoch;
  final Element originalItemElement = tester.element(messageItemFor(targetId));

  // Long-press the jumped message to open showMessageBottomSheet, keeping the
  // gesture past FluxerSheetRoute's 300 ms input lockout.
  await tester.longPress(messageItemFor(targetId));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await _pumpAsyncFrames(tester, count: 6);
  expect(find.text(testL10n.chatMessageReply), findsOneWidget);
  expect(find.byType(QuickReactionRow), findsOneWidget);

  // Pushing the modal bottom sheet hides the soft keyboard (HIDE_SOFT_INPUT),
  // expanding the underlying MessageList viewport and triggering underfill
  // reanchor while the sheet remains open.
  keyboardHeight.value = 0;
  await _pumpAsyncFrames(tester, count: 10);

  final MessageListViewport reanchoredViewport = tester
      .widget<MessageListViewport>(find.byType(MessageListViewport));
  expect(
    reanchoredViewport.anchorEpoch,
    greaterThan(epochBeforeSheet),
    reason: 'Hiding the keyboard triggers underfill _reanchor (_anchorEpoch++)',
  );
  expect(
    originalItemElement.mounted,
    isFalse,
    reason: 'KeyedSubtree(anchorEpoch) unmounted the original MessageItem',
  );
  expect(
    find.byType(QuickReactionRow),
    findsOneWidget,
    reason: 'The message action sheet is still open above the remounted list',
  );

  return (
    chat: chat,
    usage: usage,
    targetId: targetId,
    keyboardHeight: keyboardHeight,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Directory? tempDir;

  setUpAll(() async {
    await EmojiRegistry.preload();
    tempDir = await Directory.systemTemp.createTemp('sheet_reanchor_test');
    const MethodChannel pathChannel = MethodChannel(
      'plugins.flutter.io/path_provider',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (MethodCall call) async {
          if (call.method == 'getTemporaryDirectory') {
            return tempDir?.path;
          }
          return null;
        });
  });

  tearDownAll(() async {
    const MethodChannel pathChannel = MethodChannel(
      'plugins.flutter.io/path_provider',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, null);
    await tempDir?.delete(recursive: true);
  });

  testWidgets('tapping a quick reaction after keyboard-hide reanchor unmounts '
      'MessageItem still reacts and closes the sheet', (
    WidgetTester tester,
  ) async {
    final (:chat, :usage, :targetId, keyboardHeight: _) =
        await _openSheetAndTriggerUnderfillReanchor(tester);

    final Finder thumbsUp = find.descendant(
      of: find.byType(QuickReactionRow),
      matching: find.byWidgetPredicate(
        (Widget w) => w is UnicodeEmojiWidget && w.emoji == '\u{1F44D}',
      ),
    );
    expect(thumbsUp, findsOneWidget);

    await tester.tap(thumbsUp);
    await _pumpAsyncFrames(tester);

    expect(tester.takeException(), isNull);
    expect(chat.toggledReactions, <(String, String)>[(targetId, '\u{1F44D}')]);
    expect(usage.trackedKeys, <String>['unicode:thumbsup']);
    expect(
      find.byType(QuickReactionRow),
      findsNothing,
      reason: 'Tapping a quick reaction must close the bottom sheet',
    );

    await disposeMessageList(tester);
  });

  testWidgets('choosing Reply or dismissing the sheet after reanchor unmounts '
      'MessageItem dispatches without throwing on State.context', (
    WidgetTester tester,
  ) async {
    final (:chat, usage: _, :targetId, keyboardHeight: _) =
        await _openSheetAndTriggerUnderfillReanchor(tester);

    await tester.tap(find.text(testL10n.chatMessageReply));
    await _pumpAsyncFrames(tester);

    expect(tester.takeException(), isNull);
    expect(chat.repliedMessageIds, <String>[targetId]);
    expect(find.byType(QuickReactionRow), findsNothing);

    await disposeMessageList(tester);
  });

  testWidgets('dismissing the sheet without an action after reanchor unmounts '
      'MessageItem closes cleanly without throwing on State.context', (
    WidgetTester tester,
  ) async {
    await _openSheetAndTriggerUnderfillReanchor(tester);

    // Tap the modal barrier above the half-height scrollable sheet.
    await tester.tapAt(const Offset(210, 20));
    await _pumpAsyncFrames(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(QuickReactionRow), findsNothing);

    await disposeMessageList(tester);
  });

  testWidgets(
    'showMessageBottomSheet still pops when an onQuickReaction callback throws',
    (WidgetTester tester) async {
      final (:chat, usage: _, :targetId, keyboardHeight: _) =
          await _openSheetAndTriggerUnderfillReanchor(tester);
      // Close the MessageItem-opened sheet first, then open one directly with a
      // throwing callback to verify the route pop guard on its own.
      await tester.tapAt(const Offset(210, 20));
      await _pumpAsyncFrames(tester);

      final BuildContext hostContext = tester.element(find.byType(MessageList));
      final Message target = chat.testState.messages.firstWhere(
        (Message m) => m.id == targetId,
      );
      unawaited(
        showMessageBottomSheet(
          hostContext,
          message: target,
          isOwnMessage: false,
          isDmChannel: false,
          canDelete: false,
          canReport: false,
          canAddReactions: true,
          canPinMessage: false,
          canManageMessages: false,
          canSendMessages: true,
          developerMode: false,
          onQuickReaction: (_) => throw StateError('simulated callback error'),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(QuickReactionRow), findsOneWidget);

      final Finder thumbsUp = find.descendant(
        of: find.byType(QuickReactionRow),
        matching: find.byWidgetPredicate(
          (Widget w) => w is UnicodeEmojiWidget && w.emoji == '\u{1F44D}',
        ),
      );
      final Finder thumbsUpButton = find
          .ancestor(of: thumbsUp, matching: find.byType(GestureDetector))
          .first;
      await tester.tap(thumbsUpButton);
      await _pumpAsyncFrames(tester);

      expect(tester.takeException(), isA<StateError>());
      expect(
        find.byType(QuickReactionRow),
        findsNothing,
        reason: 'Sheet must still pop even if onQuickReaction throws',
      );

      await disposeMessageList(tester);
    },
  );
}
