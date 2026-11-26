// Fork: inline formatting (`**...**`, `*...*`, `***...***`, `__...__`,
// `~~...~~`, mid-line `||...||`) spans blank lines in the native parser,
// markdown bridge, and composer source-span aligner (tyne-chat/tyne#641).

import 'package:fluxer_markdown_native/fluxer_markdown_native.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:test/test.dart';

List<(String, bool, int)> _describe(String source) {
  return <(String, bool, int)>[
    for (final MdSourceSpan span in computeMarkdownSourceSpans(source))
      (source.substring(span.start, span.end), span.isMarker, span.format),
  ];
}

void _expectCovers(String source) {
  final spans = computeMarkdownSourceSpans(source);
  var cursor = 0;
  for (final span in spans) {
    expect(span.start, cursor, reason: 'gap before $span in "$source"');
    expect(span.end, greaterThan(span.start));
    cursor = span.end;
  }
  expect(cursor, source.length);
}

void main() {
  group('multiline formatting across blank lines', () {
    for (final (String name, List<MdNode> Function(String) parse)
        in <(String, List<MdNode> Function(String))>[
          ('binary', parseFluxerMarkdownBinary),
          ('json', parseFluxerMarkdown),
        ]) {
      group('$name tree', () {
        test('bold spans blank lines and normalizes spaced blank lines', () {
          final nodes = parse(
            '**Test sentence one\n\nTest sentence 2**',
          );
          final strong = nodes.single as MdStrong;
          expect(
            (strong.children.single as MdText).content,
            'Test sentence one\n\nTest sentence 2',
          );

          final spaced = parse('**line 1\n   \nline 2**').single as MdStrong;
          expect(
            (spaced.children.single as MdText).content,
            'line 1\n\nline 2',
          );
        });

        test(
          'other inline formatting spans blank lines except inline code',
          () {
            final em = parse('*a\n\nb*').single as MdEmphasis;
            expect((em.children.single as MdText).content, 'a\n\nb');

            final under = parse('__a\n\nb__').single as MdUnderline;
            expect((under.children.single as MdText).content, 'a\n\nb');

            final strike = parse('~~a\n\nb~~').single as MdStrikethrough;
            expect((strike.children.single as MdText).content, 'a\n\nb');

            final code = parse('`a\n\nb`').single as MdText;
            expect(code.content, '`a\n\nb`');
          },
        );

        test('blocks still bound inline formatting', () {
          final headingNodes = parse('**a\n\n# Heading\n\nb**');
          expect(headingNodes[1], isA<MdHeading>());

          final blockSpoilerNodes = parse(
            'intro\n\n||block\nspoiler||',
          );
          final spoiler = blockSpoilerNodes.last as MdSpoiler;
          expect(spoiler.isBlock, isTrue);
        });
      });
    }

    test(
      'markdown bridge preserves bold across blank lines and block gaps',
      () {
        final bridged = fluxerNativeAstToMarkdown(
          parseFluxerMarkdownBinary('**Test sentence one\n\nTest sentence 2**'),
        );
        final p = bridged.single as md.Element;
        expect(p.tag, 'p');
        final strong = p.children!.single as md.Element;
        expect(strong.tag, 'strong');
        expect(strong.textContent, 'Test sentence one\n\nTest sentence 2');

        final beforeList = fluxerNativeAstToMarkdown(
          parseFluxerMarkdownBinary('**a\n\nb**\n\n- item'),
        );
        final tags = <String>[
          for (final md.Element el in beforeList.cast<md.Element>()) el.tag,
        ];
        expect(tags, <String>['p', 'blank-lines', 'ul']);
      },
    );

    test('composer source spans align across blank and spaced blank lines', () {
      expect(
        _describe('**Test sentence one\n\nTest sentence 2**'),
        <(String, bool, int)>[
          ('**', true, MdSpanFormat.bold),
          ('Test sentence one\n\nTest sentence 2', false, MdSpanFormat.bold),
          ('**', true, MdSpanFormat.bold),
        ],
      );

      expect(_describe('**line 1\n   \nline 2**'), <(String, bool, int)>[
        ('**', true, MdSpanFormat.bold),
        ('line 1\n   \nline 2', false, MdSpanFormat.bold),
        ('**', true, MdSpanFormat.bold),
      ]);

      expect(
        _describe('**line 1\n\n*italic*\n\nline 3**'),
        <(String, bool, int)>[
          ('**', true, MdSpanFormat.bold),
          ('line 1\n\n', false, MdSpanFormat.bold),
          ('*', true, MdSpanFormat.bold | MdSpanFormat.italic),
          ('italic', false, MdSpanFormat.bold | MdSpanFormat.italic),
          ('*', true, MdSpanFormat.bold | MdSpanFormat.italic),
          ('\n\nline 3', false, MdSpanFormat.bold),
          ('**', true, MdSpanFormat.bold),
        ],
      );

      const quotedBold = MdSpanFormat.blockquote | MdSpanFormat.bold;
      const quotePrefix =
          MdSpanFormat.blockquote | MdSpanFormat.blockquoteMarker;
      expect(_describe('> **line 1\n>   \n> line 2**'), <(String, bool, int)>[
        ('> ', true, quotePrefix),
        ('**', true, quotedBold),
        ('line 1\n', false, quotedBold),
        ('> ', true, quotePrefix),
        ('  ', false, MdSpanFormat.blockquote),
        ('\n', false, quotedBold),
        ('> ', true, quotePrefix),
        ('line 2', false, quotedBold),
        ('**', true, quotedBold),
      ]);

      <String>[
        '**a\n\nb**',
        '**a\n\n\nb**',
        '*a\n\nb*',
        '***a\n\nb***',
        '__a\n\nb__',
        '~~a\n\nb~~',
        'x ||a\n\nb||',
        '**a**\n\n**b**',
        '**a\n\nb**\n\n- item',
        '**a\n\nb**\n\n# Heading',
        '**a\n\n# Heading\n\nb**',
        '> **a\n> \n> b**',
        '>>> **a\n\nb**',
      ].forEach(_expectCovers);
    });
  });
}
