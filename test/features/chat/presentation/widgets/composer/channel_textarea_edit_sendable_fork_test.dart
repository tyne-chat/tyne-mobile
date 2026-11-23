// Fork: tyne-chat/tyne#904. While editing, the composer saves only an edit the edit rules allow:
// a tag with nothing after it counts as no text, and an empty box on a message with attachments
// removes its text.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../helpers/composer_channel_textarea_harness.dart';

const MethodChannel _recorder = MethodChannel('com.llfbandit.record/messages');

const Persona _bob = Persona(
  id: 'persona_bob',
  name: 'Bob',
  personaTags: <PersonaTag>[PersonaTag(prefix: 'B:')],
);

class _Personas extends MyPersonasNotifier {
  @override
  AsyncValue<List<Persona>> build() =>
      const AsyncValue<List<Persona>>.data(<Persona>[_bob]);
}

Message _message({List<Attachment> attachments = const <Attachment>[]}) =>
    Message(
      id: '1',
      channelId: kComposerHarnessChannelA,
      authorId: kComposerHarnessUserId,
      authorName: 'me',
      content: 'hi',
      timestamp: DateTime.utc(2026, 11, 23),
      attachments: attachments,
    );

const List<Attachment> _photo = <Attachment>[
  Attachment(id: '9', filename: 'dog.png', url: 'https://x/dog.png'),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // The composer can set up the voice recorder, whose plugin tests do not have.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_recorder, (_) async => null);
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_recorder, null),
    );
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  /// Types [text] in the composer, editing [message] (or writing a new message
  /// when it is null), and presses Send if the composer offers it and [press]
  /// is set. Says whether Send was offered (shown and enabled) and whether
  /// anything was sent.
  Future<({bool offered, bool sent})> trySend(
    WidgetTester tester, {
    required Message? message,
    required String text,
    bool press = true,
  }) async {
    final ProviderContainer container =
        await pumpComposerChannelTextareaHarness(
          tester,
          extraOverrides: <Override>[
            myPersonasProvider.overrideWith(_Personas.new),
          ],
        );
    final MutableChatViewModel vm =
        container.read(chatViewModelProvider.notifier) as MutableChatViewModel;
    if (message != null) {
      vm.setEditing(message: message, messageText: message.content);
      await tester.pump();
    }
    await tester.enterText(find.byType(EditableText), text);
    await tester.pump();
    final Finder send = find.byKey(
      const ValueKey<String>('mobile-composer-send'),
    );
    bool offered = false;
    if (send.evaluate().isNotEmpty) {
      final GestureDetector button = tester.widget<GestureDetector>(
        find.ancestor(of: send, matching: find.byType(GestureDetector)).first,
      );
      offered = button.onTap != null;
      if (press) {
        await tester.tap(send, warnIfMissed: false);
        await tester.pump();
      }
    }
    return (offered: offered, sent: vm.sentTexts.isNotEmpty);
  }

  testWidgets('new text on a text message is saved', (
    WidgetTester tester,
  ) async {
    final result = await trySend(tester, message: _message(), text: 'hello');
    expect(result.offered, isTrue);
    expect(result.sent, isTrue);
  });

  testWidgets('an empty box on a text message is not offered', (
    WidgetTester tester,
  ) async {
    final result = await trySend(tester, message: _message(), text: '');
    expect(result.offered, isFalse);
    expect(result.sent, isFalse);
  });

  testWidgets('a tag alone on a text message is not offered', (
    WidgetTester tester,
  ) async {
    final result = await trySend(tester, message: _message(), text: 'B:');
    expect(result.offered, isFalse);
    expect(result.sent, isFalse);
  });

  testWidgets('an empty box on a captioned attachment is saved', (
    WidgetTester tester,
  ) async {
    final result = await trySend(
      tester,
      message: _message(attachments: _photo),
      text: '',
    );
    expect(result.offered, isTrue);
    expect(result.sent, isTrue);
  });

  testWidgets('a tag alone on a captioned attachment is saved', (
    WidgetTester tester,
  ) async {
    final result = await trySend(
      tester,
      message: _message(attachments: _photo),
      text: 'B:',
    );
    expect(result.offered, isTrue);
    expect(result.sent, isTrue);
  });

  testWidgets(
    'outside an edit a tag alone is still offered (it picks the persona)',
    (WidgetTester tester) async {
      // Not pressed: picking the persona saves the selection over the network.
      final result = await trySend(
        tester,
        message: null,
        text: 'B:',
        press: false,
      );
      expect(result.offered, isTrue);
    },
  );
}
