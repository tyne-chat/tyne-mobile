import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/utils/composer/emoticon_conversion.dart';

// A few entries of the shipped table; the last test loads the real one.
const Map<String, String> _table = <String, String>{
  ':)': '\u{1F642}',
  ':-)': '\u{1F642}',
  ':D': '\u{1F604}',
  '<3': '\u{2764}\u{FE0F}',
  '♡': '\u{2764}\u{FE0F}',
  ':(': '\u{1F641}',
  ';)': '\u{1F609}',
};

String _convert(String content) => convertEmoticonsToEmoji(content, _table);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('convertEmoticonsToEmoji', () {
    test('converts emoticons between spaces and at the ends', () {
      expect(_convert(':)'), '\u{1F642}');
      expect(_convert('hi :) there'), 'hi \u{1F642} there');
      expect(_convert('love you <3'), 'love you \u{2764}\u{FE0F}');
      expect(_convert(':D :-) ;)'), '\u{1F604} \u{1F642} \u{1F609}');
      expect(_convert('♡'), '\u{2764}\u{FE0F}');
    });

    test('converts after a newline or tab, not before one', () {
      // The web converts only before a space or at the end of the message.
      expect(_convert('line\n:)'), 'line\n\u{1F642}');
      expect(_convert('a\t:)'), 'a\t\u{1F642}');
      expect(_convert(':)\nnext'), ':)\nnext');
    });

    test('leaves emoticons inside words and punctuation alone', () {
      expect(_convert('a:)'), 'a:)');
      expect(_convert(':)a'), ':)a');
      expect(_convert(':))'), ':))');
      expect(_convert('(:)'), '(:)');
      expect(_convert('hi :).'), 'hi :).');
    });

    test('leaves code spans alone', () {
      expect(_convert('`:)` :)'), '`:)` \u{1F642}');
      expect(_convert('``a :) b`` :)'), '``a :) b`` \u{1F642}');
      expect(_convert('```\n:)\n```'), '```\n:)\n```');
    });

    test('leaves markdown links and URLs alone', () {
      expect(
        _convert('[ :) ](https://a.example/:))'),
        '[ :) ](https://a.example/:))',
      );
      expect(_convert('![ :) ](x)'), '![ :) ](x)');
      expect(_convert('https://a.example/ :)'), 'https://a.example/ \u{1F642}');
      expect(_convert('http://x.example/:D'), 'http://x.example/:D');
    });

    test('an unclosed code span does not protect the rest', () {
      expect(_convert('` :)'), '` \u{1F642}');
    });

    test('empty input and an empty table return the input', () {
      expect(_convert(''), '');
      expect(convertEmoticonsToEmoji(':)', const <String, String>{}), ':)');
    });
  });

  group('preloadEmoticonTable', () {
    tearDown(() => setEmoticonTableForTesting(null));

    test('loads every emoticon of the shipped emoji data', () async {
      setEmoticonTableForTesting(null);
      await preloadEmoticonTable();
      final Map<String, String> table = emoticonTableSync!;
      // The web's list (`emojis.json` `shortcuts`) has 128 emoticons.
      expect(table, hasLength(128));
      expect(table[':)'], '\u{1F642}');
      expect(table['<3'], '\u{2764}\u{FE0F}');
      expect(table[';)'], '\u{1F609}');
      // No emoticon is a prefix of another; the converter relies on it.
      for (final String a in table.keys) {
        for (final String b in table.keys) {
          if (a != b) {
            expect(b.startsWith(a), isFalse, reason: '$a is a prefix of $b');
          }
        }
      }
    });
  });
}
