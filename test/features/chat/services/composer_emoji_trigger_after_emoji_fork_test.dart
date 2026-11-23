import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/services/composer_autocomplete_trigger.dart';
import 'package:fluxer_app/features/chat/utils/composer/composer_command_insertion.dart';
import 'package:fluxer_app/features/chat/utils/composer/composer_emoji_resolution.dart';
import 'package:fluxer_app/features/ui/input/emoji_inline_token.dart';
import 'package:fluxer_app/features/ui/input/emoji_text_editing_controller.dart';
import 'package:fluxer_app/shared/utils/emoji/emoji_registry.dart';

// Fork: a `:` straight after an emoji starts the emoji search, so emoji can be
// typed touching each other (tyne-chat/tyne#650). A `:` after a letter, digit
// or other punctuation still does not. The cases follow the web app's
// `ForkEmojiTriggerAfterEmoji.test.ts`.

({String query, int replaceFrom})? _emojiQuery(String textUpToCursor) {
  final ComposerAutocompleteTrigger? trigger =
      ComposerAutocompleteTrigger.detectIfAllowed(
        fullText: textUpToCursor,
        caretIndex: textUpToCursor.length,
      );
  if (trigger == null ||
      trigger.kind != ComposerAutocompleteTriggerKind.emoji) {
    return null;
  }
  expect(trigger.matchEnd, textUpToCursor.length);
  return (
    query: trigger.matchedText,
    replaceFrom: composerAutocompleteReplacementStart(
      textUpToCursor: textUpToCursor,
      trigger: trigger,
    ),
  );
}

/// Types [typed] at the end of [controller]'s text, as a keyboard commits it.
void _type(EmojiTextEditingController controller, String typed) {
  final String text = controller.text + typed;
  controller.value = TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
}

ComposerAutocompleteTrigger? _triggerAtCaret(
  EmojiTextEditingController controller,
) => ComposerAutocompleteTrigger.detectIfAllowed(
  fullText: controller.text,
  caretIndex: controller.selection.baseOffset,
);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await EmojiRegistry.preload();
  });

  group('the emoji search right after an emoji', () {
    test('starts after a custom emoji typed out as :name:', () {
      expect(_emojiQuery(':gay::ki'), (query: 'ki', replaceFrom: 5));
      expect(_emojiQuery('hello :gay::kiss_left'), (
        query: 'kiss_left',
        replaceFrom: 11,
      ));
    });

    test('starts after an emoji the composer shows as a token', () {
      // Each emoji in the composer is one private-use character. A mention's
      // or a timestamp's token is one too, and the text cannot tell them
      // apart, so a `:` straight after those starts the search as well.
      expect(_emojiQuery('\u{E000}\u{E001}:he'), (query: 'he', replaceFrom: 2));
      expect(
        _emojiQuery(
          'hi \u{E000}\u{E001}\u{E002}\u{E003}\u{E004}\u{E005}\u{E006}:kiss',
        ),
        (query: 'kiss', replaceFrom: 10),
      );
      expect(_emojiQuery('\u{F8FF}:he'), (query: 'he', replaceFrom: 1));
    });

    test('starts after an emoji character', () {
      // Grinning face.
      expect(_emojiQuery('\u{1F600}:he'), (query: 'he', replaceFrom: 2));
      // Smiling face, without the variation selector that makes it an emoji.
      expect(_emojiQuery('\u{263A}:he'), (query: 'he', replaceFrom: 1));
      // Red heart with its variation selector.
      expect(_emojiQuery('\u{2764}\u{FE0F}:he'), (query: 'he', replaceFrom: 2));
      // Thumbs up with a skin tone.
      expect(_emojiQuery('\u{1F44D}\u{1F3FD}:he'), (
        query: 'he',
        replaceFrom: 4,
      ));
      // The flag of New Zealand.
      expect(_emojiQuery('\u{1F1F3}\u{1F1FF}:he'), (
        query: 'he',
        replaceFrom: 4,
      ));
      // Keycap one.
      expect(_emojiQuery('1\u{FE0F}\u{20E3}:he'), (
        query: 'he',
        replaceFrom: 3,
      ));
      // The flag of Scotland, a tag sequence.
      expect(
        _emojiQuery(
          '\u{1F3F4}\u{E0067}\u{E0062}\u{E0073}\u{E0063}\u{E0074}\u{E007F}:he',
        ),
        (query: 'he', replaceFrom: 14),
      );
      // A family, a sequence joined by zero-width joiners.
      expect(_emojiQuery('hi \u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}:he'), (
        query: 'he',
        replaceFrom: 11,
      ));
    });

    test("starts after a custom emoji's wire text", () {
      expect(_emojiQuery('<:gay:123>:ki'), (query: 'ki', replaceFrom: 10));
      expect(_emojiQuery('<a:gay:123>:ki'), (query: 'ki', replaceFrom: 11));
    });

    test('still needs two letters, as upstream asks', () {
      expect(_emojiQuery(':gay::k'), isNull);
      expect(_emojiQuery('\u{1F600}:h'), isNull);
      expect(_emojiQuery('\u{E000}:h'), isNull);
      expect(_emojiQuery('\u{E000}:'), isNull);
    });

    test("takes the query's letters as upstream does", () {
      expect(_emojiQuery('\u{E000}:Sm'), (query: 'Sm', replaceFrom: 1));
      expect(_emojiQuery('\u{E000}:+1'), (query: '+1', replaceFrom: 1));
      expect(_emojiQuery('\u{E000}:sm!'), isNull);
    });

    test('does not start after a letter, a digit or other punctuation', () {
      expect(_emojiQuery('abc:de'), isNull);
      expect(_emojiQuery('at 12:30'), isNull);
      expect(_emojiQuery('see http://example'), isNull);
      expect(_emojiQuery('(:sm'), isNull);
      expect(_emojiQuery('a:b::cd'), isNull);
      expect(_emojiQuery('xxxx:he'), isNull);
      expect(_emojiQuery('<@123>:he'), isNull);
      // A zero-width joiner alone is no emoji.
      expect(_emojiQuery('a\u{200D}:he'), isNull);
    });

    test(
      "leaves upstream's search after a space or at the start as it was",
      () {
        expect(_emojiQuery(':sm'), (query: 'sm', replaceFrom: 0));
        expect(_emojiQuery('hi :sm'), (query: 'sm', replaceFrom: 3));
        expect(_emojiQuery(':gay: :ki'), (query: 'ki', replaceFrom: 6));
        expect(_emojiQuery('\u{E000} :ki'), (query: 'ki', replaceFrom: 2));
      },
    );

    test('does not start inside an open code block', () {
      expect(_emojiQuery('```\n\u{E000}:he'), isNull);
      expect(_emojiQuery('```\n:gay::he'), isNull);
    });

    test('leaves the mention search alone', () {
      expect(
        ComposerAutocompleteTrigger.detect('\u{E000}@bob')?.kind,
        ComposerAutocompleteTriggerKind.mention,
      );
      expect(
        ComposerAutocompleteTrigger.detect('\u{1F600}:he @bo')?.kind,
        ComposerAutocompleteTriggerKind.mention,
      );
    });
  });

  group('in the composer', () {
    test('a pick from the list goes straight after the emoji before it', () {
      final controller = EmojiTextEditingController();
      addTearDown(controller.dispose);
      controller.insertEmoji('gaykiss_left', '<:gaykiss_left:1>');
      expect(controller.text, hasLength(1));

      _type(controller, ':gaykiss_r');
      final ComposerAutocompleteTrigger? trigger = _triggerAtCaret(controller);
      expect(trigger?.kind, ComposerAutocompleteTriggerKind.emoji);
      expect(trigger?.matchedText, 'gaykiss_r');
      expect(trigger?.matchStart, 1);

      // As the list's pick does (`_applyEmoji`).
      controller.replaceRangeWithToken(
        trigger!.matchStart,
        trigger.matchEnd,
        EmojiInlineToken(
          displayName: 'gaykiss_right',
          wireText: '<:gaykiss_right:2>',
        ),
        ensureTrailingSpace: true,
      );
      expect(controller.actualText, '<:gaykiss_left:1><:gaykiss_right:2> ');
    });

    test('an emoji typed on the keyboard becomes a token, and the search '
        'starts after it', () {
      final controller = EmojiTextEditingController();
      addTearDown(controller.dispose);

      _type(controller, '\u{1F600}:sm');
      expect(controller.text, hasLength(4));
      expect(controller.text.startsWith('\u{1F600}'), isFalse);
      final ComposerAutocompleteTrigger? trigger = _triggerAtCaret(controller);
      expect(trigger?.kind, ComposerAutocompleteTriggerKind.emoji);
      expect(trigger?.matchedText, 'sm');
      expect(trigger?.matchStart, 1);
      expect(controller.actualText, '\u{1F600}:sm');
    });

    test(
      'while the keyboard is still composing, the emoji character counts',
      () {
        final controller = EmojiTextEditingController();
        addTearDown(controller.dispose);

        controller.value = const TextEditingValue(
          text: '\u{1F600}:sm',
          selection: TextSelection.collapsed(offset: 5),
          composing: TextRange(start: 3, end: 5),
        );
        expect(controller.text, '\u{1F600}:sm');
        final ComposerAutocompleteTrigger? trigger = _triggerAtCaret(
          controller,
        );
        expect(trigger?.kind, ComposerAutocompleteTriggerKind.emoji);
        expect(trigger?.matchedText, 'sm');
        expect(trigger?.matchStart, 2);
      },
    );
  });

  group('typing the whole name', () {
    String? lookup(String nameLower) => switch (nameLower) {
      'gaykiss_left' => '<:gaykiss_left:1>',
      'gaykiss_right' => '<:gaykiss_right:2>',
      _ => null,
    };

    test('still turns into the custom emoji on send, right after another', () {
      expect(
        resolveTypedCustomEmojiShortcodes(
          ':gaykiss_left::gaykiss_right:',
          lookup,
        ),
        '<:gaykiss_left:1><:gaykiss_right:2>',
      );
      expect(
        resolveTypedCustomEmojiShortcodes(
          '<:gaykiss_left:1>:gaykiss_right:',
          lookup,
        ),
        '<:gaykiss_left:1><:gaykiss_right:2>',
      );
      expect(
        resolveTypedCustomEmojiShortcodes('\u{1F600}:gaykiss_right:', lookup),
        '\u{1F600}<:gaykiss_right:2>',
      );
    });
  });
}
