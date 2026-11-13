// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/utils/composer/fork_persona_tag_selection.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';

// tyne-chat/tyne#628: a message made only of a persona's proxy tags selects
// that persona instead of being sent.

const Persona _alpha = Persona(
  id: 'p_alpha',
  name: 'Alpha',
  personaTags: [PersonaTag(prefix: 'a:', suffix: '')],
);

const Persona _beta = Persona(
  id: 'p_beta',
  name: 'Beta',
  personaTags: [PersonaTag(prefix: '[', suffix: ']')],
);

const Persona _quiet = Persona(
  id: 'p_quiet',
  name: 'Quiet',
  personaTags: [PersonaTag(prefix: 'q:', suffix: '')],
  autoTagDisabled: true,
);

const List<Persona> _personas = <Persona>[_alpha, _beta, _quiet];

void main() {
  test('a prefix tag alone names its persona', () {
    expect(forkPersonaSelectedByTags('a:', _personas)?.id, 'p_alpha');
    expect(forkPersonaSelectedByTags('  a:  ', _personas)?.id, 'p_alpha');
  });

  test('a prefix and suffix pair alone names its persona', () {
    expect(forkPersonaSelectedByTags('[]', _personas)?.id, 'p_beta');
    expect(forkPersonaSelectedByTags('[ ]', _personas)?.id, 'p_beta');
  });

  test('tags with text are an ordinary message', () {
    expect(forkPersonaSelectedByTags('a: hello', _personas), isNull);
    expect(forkPersonaSelectedByTags('[hello]', _personas), isNull);
  });

  test('text that is no tag, half a pair or nothing selects nobody', () {
    expect(forkPersonaSelectedByTags('hello', _personas), isNull);
    expect(forkPersonaSelectedByTags('[', _personas), isNull);
    expect(forkPersonaSelectedByTags('', _personas), isNull);
    expect(forkPersonaSelectedByTags('   ', _personas), isNull);
    expect(forkPersonaSelectedByTags('a:', const <Persona>[]), isNull);
  });

  test('a persona whose tags are not matched is skipped', () {
    expect(forkPersonaSelectedByTags('q:', _personas), isNull);
  });

  test('the unlatch command is not a tag', () {
    expect(forkPersonaSelectedByTags(r'\\', _personas), isNull);
  });
}
