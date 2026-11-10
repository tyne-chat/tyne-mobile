// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: the rules for the account's own reactions (tyne-chat/tyne#86): who of
// yours reacted, when a tap opens "Your reactions", the order of the list, the
// "Recent" strip, the search, and taking own reactions off a message.
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/utils/reactions/own_reactions.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';

const Persona _ash = Persona(id: 'ash', name: 'Ash', pronouns: 'they/them');
const Persona _bao = Persona(
  id: 'bao',
  name: 'Bao',
  personaTags: <PersonaTag>[PersonaTag(prefix: 'B:', suffix: '-bao')],
);
const Persona _cyd = Persona(id: 'cyd', name: 'Cyd');

const Reaction _othersOnly = Reaction(emoji: '👍', count: 3);
const Reaction _accountOnly = Reaction(
  emoji: '👍',
  count: 2,
  hasReacted: true,
  meRoot: true,
);
const Reaction _accountAndBao = Reaction(
  emoji: '👍',
  count: 3,
  hasReacted: true,
  meRoot: true,
  personaReactions: <String>['bao'],
);

List<Persona> _many(int count, {Set<int> used = const <int>{}}) => <Persona>[
  for (int i = 0; i < count; i++)
    Persona(
      id: 'p$i',
      name: 'Persona $i',
      useCount: used.contains(i) ? 1 : 0,
      lastUsedAtMs: used.contains(i) ? 1000 + i : null,
    ),
];

void main() {
  group('ownReactedIds', () {
    test('lists the account first, then the personas', () {
      expect(ownReactedIds(_accountAndBao), <String?>[null, 'bao']);
      expect(ownReactedIds(_accountOnly), <String?>[null]);
      expect(ownReactedIds(_othersOnly), isEmpty);
    });
  });

  group('opensOwnReactionsSheet', () {
    test('only with the setting on, personas, and an own reaction', () {
      expect(
        opensOwnReactionsSheet(_accountOnly, multi: true, hasPersonas: true),
        isTrue,
      );
      expect(
        opensOwnReactionsSheet(_accountOnly, multi: false, hasPersonas: true),
        isFalse,
      );
      expect(
        opensOwnReactionsSheet(_accountOnly, multi: true, hasPersonas: false),
        isFalse,
      );
      expect(
        opensOwnReactionsSheet(_othersOnly, multi: true, hasPersonas: true),
        isFalse,
      );
    });
  });

  group('findReaction', () {
    test('tells a custom emoji from a unicode one of the same name', () {
      const Reaction custom = Reaction(emoji: 'blob', emojiId: 'e1', count: 1);
      const Reaction plain = Reaction(emoji: 'blob', count: 1);
      const List<Reaction> reactions = <Reaction>[custom, plain];

      expect(
        findReaction(reactions, emoji: 'blob', emojiId: 'e1')?.emojiId,
        'e1',
      );
      expect(findReaction(reactions, emoji: 'blob')?.emojiId, isNull);
      expect(findReaction(reactions, emoji: '👍'), isNull);
    });
  });

  group('ownReactionKey', () {
    test('changes when an own identity is added or removed', () {
      // Reaction's own equality leaves these fields out.
      expect(_accountOnly == _accountAndBao.copyWith(count: 2), isTrue);
      expect(
        ownReactionKey(_accountOnly),
        isNot(ownReactionKey(_accountAndBao)),
      );
      expect(ownReactionKey(_othersOnly), isNot(ownReactionKey(_accountOnly)));
      expect(ownReactionKey(null), '');
    });
  });

  group('the order of the list', () {
    const List<Persona> personas = <Persona>[_ash, _bao, _cyd];

    test('the current persona, the account, then the others', () {
      expect(orderedIdentities(currentId: 'bao', personas: personas), <String?>[
        'bao',
        null,
        'ash',
        'cyd',
      ]);
    });

    test('the account leads when it is the current identity', () {
      expect(orderedIdentities(currentId: null, personas: personas), <String?>[
        null,
        'ash',
        'bao',
        'cyd',
      ]);
    });

    test('a current persona that is gone counts as the account', () {
      expect(
        orderedIdentities(currentId: 'gone', personas: personas),
        <String?>[null, 'ash', 'bao', 'cyd'],
      );
    });

    test('who reacted and the current identity go on top', () {
      final ({List<String?> top, List<String?> rest}) split =
          splitIdentitiesForReaction(
            reaction: _accountAndBao,
            currentId: 'cyd',
            personas: personas,
          );

      expect(split.top, <String?>['cyd', null, 'bao']);
      expect(split.rest, <String?>['ash']);
    });

    test('with no reaction yet only the current identity is on top', () {
      final ({List<String?> top, List<String?> rest}) split =
          splitIdentitiesForReaction(
            reaction: null,
            currentId: null,
            personas: personas,
          );

      expect(split.top, <String?>[null]);
      expect(split.rest, <String?>['ash', 'bao', 'cyd']);
    });
  });

  group('recentPersonas', () {
    test('nothing below seven personas: the list already shows them all', () {
      expect(recentPersonas(_many(6, used: <int>{0, 1, 2})), isEmpty);
    });

    test('nothing with fewer than two recent personas', () {
      expect(recentPersonas(_many(8, used: <int>{3})), isEmpty);
    });

    test('the used personas, in the order given, six at most', () {
      final List<Persona> ranked = _many(
        12,
        used: <int>{0, 1, 2, 3, 4, 5, 6, 7},
      );

      expect(recentPersonas(ranked).map((Persona p) => p.id), <String>[
        'p0',
        'p1',
        'p2',
        'p3',
        'p4',
        'p5',
      ]);
    });

    test('a persona used on this device since the list loaded counts', () {
      final List<Persona> ranked = _many(8, used: <int>{2});

      expect(
        recentPersonas(
          ranked,
          usedHere: <String>{'p5'},
        ).map((Persona p) => p.id),
        <String>['p2', 'p5'],
      );
    });
  });

  group('personaMatchesQuery', () {
    test('matches name, pronouns and tags, ignoring case', () {
      expect(personaMatchesQuery(_ash, 'AS'), isTrue);
      expect(personaMatchesQuery(_ash, 'they'), isTrue);
      expect(personaMatchesQuery(_bao, 'b:'), isTrue);
      expect(personaMatchesQuery(_bao, '-BAO'), isTrue);
      expect(personaMatchesQuery(_cyd, 'they'), isFalse);
    });

    test('an empty search matches everyone', () {
      expect(personaMatchesQuery(_cyd, '  '), isTrue);
    });
  });

  group('withoutOwnReactions', () {
    const Reaction other = Reaction(emoji: '🎉', count: 1);

    test('takes the named identities off and keeps the others', () {
      final List<Reaction> result = withoutOwnReactions(
        const <Reaction>[other, _accountAndBao],
        emoji: '👍',
        ids: const <String?>[null],
      );

      expect(result, hasLength(2));
      expect(result.first, same(other));
      expect(result.last.count, 2);
      expect(result.last.meRoot, isFalse);
      expect(result.last.personaReactions, <String>['bao']);
      expect(result.last.hasReacted, isTrue);
    });

    test('with every own identity gone, other people keep the reaction', () {
      final Reaction left = withoutOwnReactions(
        const <Reaction>[_accountAndBao],
        emoji: '👍',
        ids: const <String?>[null, 'bao'],
      ).single;

      expect(left.count, 1);
      expect(left.hasReacted, isFalse);
      expect(left.meRoot, isFalse);
      expect(left.personaReactions, isEmpty);
    });

    test('the reaction goes when nobody is left on it', () {
      expect(
        withoutOwnReactions(
          <Reaction>[_accountOnly.copyWith(count: 1)],
          emoji: '👍',
          ids: const <String?>[null],
        ),
        isEmpty,
      );
    });

    test('the id 0 is the account', () {
      expect(
        withoutOwnReactions(
          const <Reaction>[_accountAndBao],
          emoji: '👍',
          ids: const <String?>['0'],
        ).single.meRoot,
        isFalse,
      );
    });

    test('an identity that had not reacted changes nothing', () {
      final List<Reaction> result = withoutOwnReactions(
        const <Reaction>[_accountOnly],
        emoji: '👍',
        ids: const <String?>['bao', 'cyd'],
      );

      expect(result.single, same(_accountOnly));
    });

    test('a custom emoji of the same name is left alone', () {
      const Reaction custom = Reaction(
        emoji: '👍',
        emojiId: 'e1',
        count: 1,
        hasReacted: true,
        meRoot: true,
      );

      final List<Reaction> result = withoutOwnReactions(
        const <Reaction>[custom, _accountOnly],
        emoji: '👍',
        ids: const <String?>[null],
      );

      expect(result.first, same(custom));
      expect(result.last.meRoot, isFalse);
    });
  });
}
