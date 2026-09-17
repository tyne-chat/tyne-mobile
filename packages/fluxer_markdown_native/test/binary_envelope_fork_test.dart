// Fork: the persona mention, in the fork's tests next to upstream's
// binary_envelope_test.dart (tyne-chat/tyne#846).
import 'package:fluxer_markdown_native/fluxer_markdown_native.dart';
import 'package:test/test.dart';

import 'binary_envelope_test.dart' hide main;

void main() {
  test('decodes persona user mention', () {
    final mention =
        parseFluxerMarkdownBinary('<@1234:5678>').single as MdMention;
    final user = mention.kind as MdUserMention;
    expect(user.id, '1234');
    expect(user.personaId, '5678');
  });

  test('binary and JSON paths agree on persona mentions', () {
    const input = 'with <@1> <#2> <@5:p5>';
    final binary = parseFluxerMarkdownBinary(input);
    final json = parseFluxerMarkdown(input);
    expect(
      binary.map(describeAst).join('\n'),
      json.map(describeAst).join('\n'),
    );
    expect(_personaIds(binary), _personaIds(json));
    expect(_personaIds(json), [null, 'p5']);
  });
}

List<String?> _personaIds(List<MdNode> nodes) => [
  for (final node in nodes)
    if (node case MdMention(kind: MdUserMention(:final personaId))) personaId,
];
