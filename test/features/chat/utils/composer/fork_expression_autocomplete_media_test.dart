// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/domain/favorite_meme.dart';
import 'package:fluxer_app/features/chat/providers/pickers/sticker_picker_provider.dart';
import 'package:fluxer_app/features/chat/utils/composer/fork_expression_autocomplete_media.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';

// tyne-chat/tyne#777: stickers and saved media in the `:` list, only while the
// composer holds nothing a pick would lose.

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

const List<Persona> _personas = <Persona>[_alpha, _beta];

/// Whether [text] is free with the `:query` at its end (as the caret leaves it).
bool _free(String text, {String? latched, List<Persona> personas = _personas}) {
  final int start = text.lastIndexOf(':');
  return forkExpressionMediaDraftIsFree(
    text: text,
    matchStart: start,
    matchEnd: text.length,
    personas: personas,
    latchedPersonaId: latched,
  );
}

StickerEntry _sticker(String id, String name, {String guildId = 'g1'}) =>
    StickerEntry(
      id: id,
      guildId: guildId,
      name: name,
      description: '',
      tags: const <String>[],
      animated: false,
    );

FavoriteMeme _meme(String id, String name, {List<String> tags = const []}) =>
    FavoriteMeme(
      id: id,
      userId: 'u1',
      name: name,
      altText: null,
      tags: tags,
      attachmentId: 'a$id',
      filename: '$id.png',
      contentType: 'image/png',
      contentHash: null,
      size: 1,
      width: 1,
      height: 1,
      duration: null,
      isGifv: false,
      url: 'https://media.invalid/$id.png',
      klipySlug: null,
      tenorSlugId: null,
    );

void main() {
  group('forkExpressionMediaDraftIsFree', () {
    test('the query alone, or with whitespace around it, is free', () {
      expect(_free(':wave'), isTrue);
      expect(_free('  :wave'), isTrue);
      expect(_free('\n:wave'), isTrue);
    });

    test('other text is not free', () {
      expect(_free('hello :wave'), isFalse);
      expect(_free('a: hello :wave'), isFalse);
    });

    test('text after the caret counts too', () {
      expect(
        forkExpressionMediaDraftIsFree(
          text: ':wave hello',
          matchStart: 0,
          matchEnd: 5,
          personas: _personas,
          latchedPersonaId: null,
        ),
        isFalse,
      );
    });

    test('a persona tag the send uses up is free', () {
      expect(_free('a: :wave'), isTrue);
      // Half a pair is not a tag.
      expect(_free('[ :wave'), isFalse);
      expect(
        forkExpressionMediaDraftIsFree(
          text: '[:wave]',
          matchStart: 1,
          matchEnd: 6,
          personas: _personas,
          latchedPersonaId: null,
        ),
        isTrue,
      );
    });

    test('a tag of no persona of the account is ordinary text', () {
      expect(_free('a: :wave', personas: const <Persona>[]), isFalse);
    });

    test('a backslash is used up only while a persona is selected', () {
      expect(_free(r'\ :wave', latched: _alpha.id), isTrue);
      expect(_free(r'\ :wave'), isFalse);
    });
  });

  group('forkExpressionStickerMatches', () {
    test('matches name, recent ones first, then the active community', () {
      final List<StickerEntry> results = forkExpressionStickerMatches(
        query: 'wa',
        available: <StickerEntry>[
          _sticker('1', 'wave', guildId: 'other'),
          _sticker('2', 'walrus'),
          _sticker('3', 'cat'),
          _sticker('4', 'swan'),
        ],
        frecent: <StickerEntry>[_sticker('4', 'swan')],
        activeGuildId: 'g1',
      );
      expect(results.map((StickerEntry s) => s.id), <String>['4', '2', '1']);
    });

    test('a recent sticker that is not usable here is left out', () {
      final List<StickerEntry> results = forkExpressionStickerMatches(
        query: 'wa',
        available: <StickerEntry>[_sticker('2', 'walrus')],
        frecent: <StickerEntry>[_sticker('9', 'wave')],
        activeGuildId: 'g1',
      );
      expect(results.map((StickerEntry s) => s.id), <String>['2']);
    });

    test('at most five', () {
      final List<StickerEntry> results = forkExpressionStickerMatches(
        query: 'wa',
        available: <StickerEntry>[
          for (int i = 0; i < 8; i++) _sticker('$i', 'wave$i'),
        ],
        frecent: const <StickerEntry>[],
        activeGuildId: 'g1',
      );
      expect(results, hasLength(kForkExpressionMediaLimit));
    });
  });

  group('forkExpressionMemeMatches', () {
    test('matches name and tags, in the given order, at most five', () {
      final List<FavoriteMeme> memes = <FavoriteMeme>[
        _meme('1', 'Waving cat'),
        _meme('2', 'dog', tags: <String>['wave']),
        _meme('3', 'nothing'),
        for (int i = 4; i < 10; i++) _meme('$i', 'wave $i'),
      ];
      final List<FavoriteMeme> results = forkExpressionMemeMatches(
        query: 'wav',
        memes: memes,
      );
      expect(results.map((FavoriteMeme m) => m.id), <String>[
        '1',
        '2',
        '4',
        '5',
        '6',
      ]);
    });
  });
}
