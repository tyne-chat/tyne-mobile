// Fork: issue shorthands (`tyne/101`) become links (tyne-chat/tyne#460).
//
// The cases are the shared list the parser's Rust tests and the API's tests
// read, in the `fluxer` submodule the native library is built from, so the
// three cannot drift apart.
import 'dart:convert';
import 'dart:io';

import 'package:fluxer_markdown_native/fluxer_markdown_native.dart';
import 'package:test/test.dart';

/// Relative to this package, where `dart test` runs (as the build hook finds
/// the parser).
const String _casesPath =
    '../../fluxer/packages/markdown_parser/rust/tests/'
    'fork_issue_shorthand_cases.json';

typedef _Case = ({String input, List<String> links});

List<_Case> _readCases() {
  final file = File(_casesPath);
  if (!file.existsSync()) {
    throw StateError(
      'No ${file.absolute.path}: run from packages/fluxer_markdown_native '
      'with the fluxer submodule checked out.',
    );
  }
  final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  return <_Case>[
    for (final Object? entry in json['cases']! as List<Object?>)
      switch (entry) {
        {'input': final String input, 'links': final List<Object?> links} => (
          input: input,
          links: links.cast<String>(),
        ),
        _ => throw FormatException('Not a case: $entry'),
      },
  ];
}

String _issueUrl(String shorthand) {
  final slash = shorthand.indexOf('/');
  return 'https://github.com/tyne-chat/${shorthand.substring(0, slash)}'
      '/issues/${shorthand.substring(slash + 1)}';
}

List<MdNode> _childrenOf(MdNode node) => switch (node) {
  MdBlockquote(:final List<MdNode> children) => children,
  MdStrong(:final List<MdNode> children) => children,
  MdEmphasis(:final List<MdNode> children) => children,
  MdUnderline(:final List<MdNode> children) => children,
  MdStrikethrough(:final List<MdNode> children) => children,
  MdSpoiler(:final List<MdNode> children) => children,
  MdHeading(:final List<MdNode> children) => children,
  MdSubtext(:final List<MdNode> children) => children,
  MdSequence(:final List<MdNode> children) => children,
  MdTableCell(:final List<MdNode> children) => children,
  MdAlert(:final List<MdNode> children) => children,
  MdList(:final List<MdListItem> items) => <MdNode>[
    for (final MdListItem item in items) ...item.children,
  ],
  MdTable(:final MdNode header, :final List<MdNode> rows) => <MdNode>[
    header,
    ...rows,
  ],
  MdTableRow(:final List<MdNode> cells) => cells,
  MdLink(:final MdNode? text) => <MdNode>[?text],
  _ => const <MdNode>[],
};

/// Every link in [nodes], in order, as the text it shows and its address.
List<(String, String)> _links(List<MdNode> nodes) => <(String, String)>[
  for (final MdNode node in nodes) ...<(String, String)>[
    if (node case MdLink(:final MdText text, :final String url))
      (text.content, url),
    ..._links(_childrenOf(node)),
  ],
];

void main() {
  final cases = _readCases();

  for (final (String name, List<MdNode> Function(String) parse)
      in <(String, List<MdNode> Function(String))>[
        // What the app shows messages from.
        ('binary', parseFluxerMarkdownBinary),
        ('json', parseFluxerMarkdown),
      ]) {
    group('$name tree', () {
      test('links exactly the shorthands the shared cases list', () {
        expect(cases, isNotEmpty);
        for (final c in cases) {
          expect(
            _links(parse(c.input)),
            <(String, String)>[
              for (final String shorthand in c.links)
                (shorthand, _issueUrl(shorthand)),
            ],
            reason: c.input,
          );
        }
      });

      test('tyne/235 is a link to its issue, shown as typed', () {
        final nodes = parse('see tyne/235.');
        expect(nodes, hasLength(3));
        expect((nodes[0] as MdText).content, 'see ');
        final link = nodes[1] as MdLink;
        expect((link.text! as MdText).content, 'tyne/235');
        expect(link.url, 'https://github.com/tyne-chat/tyne/issues/235');
        expect((nodes[2] as MdText).content, '.');
      });

      test('tyne-tools/14 links to its own repository', () {
        final link = parse('tyne-tools/14').single as MdLink;
        expect((link.text! as MdText).content, 'tyne-tools/14');
        expect(link.url, 'https://github.com/tyne-chat/tyne-tools/issues/14');
      });

      test('a path such as /opt/tyne/1 stays plain text', () {
        final text = parse('/opt/tyne/1').single as MdText;
        expect(text.content, '/opt/tyne/1');
      });
    });
  }
}
