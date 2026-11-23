// Fork: tyne-chat/tyne#904. When an edit in the composer can be saved.
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/utils/composer/fork_edit_sendable.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/shared/utils/emoji/emoji_registry.dart';

const Persona _bob = Persona(
  id: 'persona_bob',
  name: 'Bob',
  personaTags: <PersonaTag>[PersonaTag(prefix: 'B:')],
);

const List<Attachment> _photo = <Attachment>[
  Attachment(id: '9', filename: 'dog.png', url: 'https://x/dog.png'),
];

const List<MessageSticker> _sticker = <MessageSticker>[
  MessageSticker(id: '7', name: 'wave', animated: false),
];

Message _message({
  String content = 'hi',
  List<Attachment> attachments = const <Attachment>[],
  List<MessageSticker> stickers = const <MessageSticker>[],
  String? personaId,
}) => Message(
  id: '1',
  channelId: '2',
  authorId: '3',
  authorName: 'me',
  content: content,
  timestamp: DateTime.utc(2026, 11, 23),
  attachments: attachments,
  stickers: stickers,
  personaId: personaId,
);

bool _canSave(
  Message editing,
  String typed, {
  bool hasPendingUploads = false,
}) => forkEditHasSendableContentFromParts(
  editing: editing,
  wireText: typed,
  hasPendingUploads: hasPendingUploads,
  personas: const <Persona>[_bob],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await EmojiRegistry.preload();
  });

  group('the edit rules of tyne-chat/tyne#904', () {
    test('1: new text on a text message can be saved', () {
      expect(_canSave(_message(), 'hello'), isTrue);
    });

    test('2: new text on a message with attachments can be saved', () {
      expect(_canSave(_message(attachments: _photo), 'hello'), isTrue);
    });

    test('3: an empty box on a text message cannot be saved', () {
      expect(_canSave(_message(), ''), isFalse);
      expect(_canSave(_message(), '   '), isFalse);
    });

    test('4: an empty box on a captioned attachment removes the caption', () {
      expect(_canSave(_message(attachments: _photo), ''), isTrue);
    });

    test('5: a tag and text on a text message can be saved', () {
      expect(_canSave(_message(), 'B: hello'), isTrue);
    });

    test('6: a tag and text on a message with attachments can be saved', () {
      expect(_canSave(_message(attachments: _photo), 'B: hello'), isTrue);
    });

    test(
      '7: a tag with nothing after it on a text message counts as no text',
      () {
        expect(_canSave(_message(), 'B:'), isFalse);
        expect(_canSave(_message(), 'B:   '), isFalse);
      },
    );

    test(
      '8: a tag with nothing after it on a captioned attachment can be saved',
      () {
        expect(_canSave(_message(attachments: _photo), 'B:'), isTrue);
      },
    );
  });

  group('around the rules', () {
    test('a sticker counts as an attachment', () {
      expect(_canSave(_message(stickers: _sticker), ''), isTrue);
      expect(_canSave(_message(stickers: _sticker), 'B:'), isTrue);
    });

    test('an empty box on an attachment without text has nothing to save', () {
      expect(_canSave(_message(content: '', attachments: _photo), ''), isFalse);
    });

    test('a tag alone on an attachment without text changes the persona', () {
      expect(
        _canSave(_message(content: '', attachments: _photo), 'B:'),
        isTrue,
      );
    });

    test('a backslash alone on a persona text message counts as no text', () {
      expect(_canSave(_message(personaId: _bob.id), r'\'), isFalse);
    });

    test('a backslash and text on a persona text message can be saved', () {
      expect(_canSave(_message(personaId: _bob.id), r'\hello'), isTrue);
    });

    test('files being added make an empty box worth saving', () {
      expect(_canSave(_message(), '', hasPendingUploads: true), isTrue);
      expect(_canSave(_message(), 'B:', hasPendingUploads: true), isTrue);
    });

    test('text that only looks like a tag of nobody is text', () {
      expect(_canSave(_message(), 'Z:'), isTrue);
    });
  });
}
