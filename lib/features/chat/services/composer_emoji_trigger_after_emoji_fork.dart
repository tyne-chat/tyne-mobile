// Fork: upstream starts the emoji search only for a `:` at the start or after a
// space, so an emoji typed right after another (`:a::b`, `😀:b`) never offered
// suggestions. Emoji that have to touch, such as the halves of a combined
// picture, could not be typed with the search (tyne-chat/tyne#650). Here a `:`
// straight after an emoji starts the search too, as in the web app
// (`ForkEmojiTriggerAfterEmoji.ts`). What counts as an emoji is what the text
// before the caret can hold:
//
// - an inline token: the one private-use character (U+E000 to U+F8FF) the
//   composer shows for an emoji picked from the list or the picker, or typed
//   on the keyboard (`InlineTokenTextEditingController`). The text cannot tell
//   an emoji's token from a mention's or a timestamp's, so a `:` straight after
//   those starts the search too, as upstream's `@` does after any token;
// - an emoji character not made a token yet, while the keyboard is still
//   composing: one the app knows (the emoji list the composer makes tokens
//   from), or the end of one (variation selector, skin tone, keycap, flag);
// - a `:name:` typed out in full, which stays text until it is sent
//   (`resolveTypedCustomEmojiShortcodes`), or a custom emoji's `<:name:id>`
//   before the composer makes it a token.
//
// A `:` after a letter, a digit or other punctuation still does not start it,
// so `12:30`, `http://` and `(:` stay ordinary text, and the query still needs
// two characters, as upstream's.
//
// The web app recognises an emoji character with `\p{Extended_Pictographic}`.
// `flutter analyze` rejects that property (`valid_regexps`), though the Dart
// runtime accepts it, so here the app's own emoji list decides, the one the
// composer makes tokens from.
import 'package:fluxer_app/features/chat/services/composer_autocomplete_trigger.dart';
import 'package:fluxer_app/shared/utils/emoji/emoji_registry.dart';

/// Upstream's query (`_emoji`): the text after the last `:`, two characters at
/// least.
final RegExp _forkEmojiQuery = RegExp(
  r':([a-z0-9_+-]{2,})$',
  caseSensitive: false,
);

/// What the text before that `:` ends with when it ends with an emoji, apart
/// from a bare emoji character.
final RegExp _forkEmojiEnd = RegExp(
  // A `:name:` typed out, or a custom emoji's wire text.
  r'(?::[\p{L}\p{N}_+~.-]{2,}:|<a?:[a-zA-Z0-9_]+:\d+>'
  // An inline token; the end of an emoji: variation selector, keycap, skin
  // tone, regional indicator (flags), cancel tag (subdivision flags).
  r'|[\u{E000}-\u{F8FF}\u{FE0F}\u{20E3}\u{1F3FB}-\u{1F3FF}\u{1F1E6}-\u{1F1FF}\u{E007F}])$',
  unicode: true,
);

/// The emoji search for a `:` straight after an emoji in [textUpToCursor],
/// which upstream's rule leaves out, or null. It replaces from the `:`, as
/// upstream's does.
ComposerAutocompleteTrigger? forkEmojiTriggerAfterEmoji(String textUpToCursor) {
  final RegExpMatch? query = _forkEmojiQuery.firstMatch(textUpToCursor);
  if (query == null) {
    return null;
  }
  final String before = textUpToCursor.substring(0, query.start);
  if (!_forkEmojiEnd.hasMatch(before) && !_forkEndsWithKnownEmoji(before)) {
    return null;
  }
  return ComposerAutocompleteTrigger(
    kind: ComposerAutocompleteTriggerKind.emoji,
    matchStart: query.start,
    matchEnd: query.end,
    matchedText: query.group(1)!,
  );
}

/// Whether [text] ends with an emoji the app knows, as the composer finds the
/// emoji it makes tokens of. False until the emoji list has loaded.
bool _forkEndsWithKnownEmoji(String text) {
  final UnicodeEmojiMatcher? matcher = EmojiRegistry.unicodeEmojiMatcherSync;
  if (matcher == null || text.isEmpty) {
    return false;
  }
  // Only the end can hold the emoji, so only that is searched; a window that
  // starts inside a character starts before it.
  int windowStart = text.length - EmojiRegistry.maxUnicodeEmojiLength;
  if (windowStart < 0) {
    windowStart = 0;
  }
  final int firstUnit = text.codeUnitAt(windowStart);
  if (windowStart > 0 && firstUnit >= 0xDC00 && firstUnit <= 0xDFFF) {
    windowStart--;
  }
  final int windowLength = text.length - windowStart;
  return matcher
      .matches(text.substring(windowStart))
      .any((({int start, int end}) match) => match.end == windowLength);
}
