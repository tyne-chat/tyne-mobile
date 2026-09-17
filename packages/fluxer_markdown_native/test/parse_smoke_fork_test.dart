// Fork: the persona mention, in the fork's tests next to upstream's
// parse_smoke_test.dart (tyne-chat/tyne#846).
import 'package:fluxer_markdown_native/fluxer_markdown_native.dart';
import 'package:test/test.dart';

void main() {
  test('user persona mention parses id and personaId', () {
    final mention = parseFluxerMarkdown('<@1234:5678>').single as MdMention;
    final user = mention.kind as MdUserMention;
    expect(user.id, '1234');
    expect(user.personaId, '5678');
  });
}
