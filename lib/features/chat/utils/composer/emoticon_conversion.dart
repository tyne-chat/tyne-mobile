import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fluxer_app/shared/utils/emoji/emoji_registry.dart';

/// Fork: turns text emoticons (`:)`, `<3`, ...) into emoji in an outgoing
/// message, as the web app's `EmoticonConversionUtils.ts` does when its
/// "Turn text smileys into emoji" setting is on (tyne-chat/tyne#260).
///
/// Same rules as the web: an emoticon converts only after whitespace or at the
/// start, and only before a space or at the end; code spans, markdown links and
/// URLs are left alone. [emoticons] maps each emoticon to its emoji.
String convertEmoticonsToEmoji(String content, Map<String, String> emoticons) {
  if (content.isEmpty || emoticons.isEmpty) {
    return content;
  }
  final int longest = emoticons.keys.fold<int>(
    0,
    (int max, String key) => key.length > max ? key.length : max,
  );

  final StringBuffer out = StringBuffer();
  int index = 0;
  while (index < content.length) {
    final int? protectedEnd = _findProtectedSpanEnd(content, index);
    if (protectedEnd != null && protectedEnd > index) {
      out.write(content.substring(index, protectedEnd));
      index = protectedEnd;
      continue;
    }

    final ({String shortcut, String emoji})? match = _matchEmoticonAt(
      content,
      index,
      emoticons,
      longest,
    );
    if (match != null) {
      out.write(match.emoji);
      index += match.shortcut.length;
      continue;
    }

    out.write(content[index]);
    index++;
  }
  return out.toString();
}

/// Fork: the emoticon table, built from the `shortcuts` of the emoji data the
/// app ships (the same list as the web's) and `EmojiRegistry`'s surrogates.
/// Loaded once, in the background, when the setting is on; until it is ready,
/// this is null and messages go out unconverted.
Map<String, String>? get emoticonTableSync => _emoticonTable;

Map<String, String>? _emoticonTable;
Future<void>? _pendingEmoticonTable;

Future<void> preloadEmoticonTable() {
  if (_emoticonTable != null) {
    return Future<void>.value();
  }
  return _pendingEmoticonTable ??= _loadEmoticonTable().whenComplete(
    () => _pendingEmoticonTable = null,
  );
}

Future<void> _loadEmoticonTable() async {
  await EmojiRegistry.ensureLoaded();
  final String raw = await rootBundle.loadString('assets/emojis.json');
  final List<String> shortcuts = await compute(_shortcutKeys, raw);
  final Map<String, String> table = <String, String>{};
  for (final String shortcut in shortcuts) {
    final String? emoji = EmojiRegistry.resolveSync(shortcut);
    if (emoji != null) {
      table[shortcut] = emoji;
    }
  }
  _emoticonTable = table;
}

@visibleForTesting
void setEmoticonTableForTesting(Map<String, String>? table) {
  _emoticonTable = table;
}

List<String> _shortcutKeys(String raw) {
  final Object? json = jsonDecode(raw);
  if (json is! Map<String, dynamic>) {
    return const <String>[];
  }
  final Object? shortcuts = json['shortcuts'];
  if (shortcuts is! Map<String, dynamic>) {
    return const <String>[];
  }
  return shortcuts.keys.toList(growable: false);
}

final RegExp _whitespace = RegExp(r'\s', unicode: true);
final RegExp _urlSchemeChar = RegExp('[A-Za-z0-9_-]');
final RegExp _asciiLetter = RegExp('[A-Za-z]');

const Set<String> _trimmedAutolinkPunctuation = <String>{
  '.',
  ',',
  ';',
  ':',
  '!',
  '?',
};

({String shortcut, String emoji})? _matchEmoticonAt(
  String content,
  int index,
  Map<String, String> emoticons,
  int longest,
) {
  if (index > 0 && !_whitespace.hasMatch(content[index - 1])) {
    return null;
  }
  // The web tries its emoticons in the data's order, taking the first that
  // matches. No emoticon in the data is a prefix of another, so at most one
  // matches here and the order cannot change the result.
  for (int length = 1; length <= longest; length++) {
    final int end = index + length;
    if (end > content.length) {
      break;
    }
    final String candidate = content.substring(index, end);
    final String? emoji = emoticons[candidate];
    if (emoji == null) {
      continue;
    }
    if (end < content.length && content[end] != ' ') {
      return null;
    }
    return (shortcut: candidate, emoji: emoji);
  }
  return null;
}

int? _findProtectedSpanEnd(String content, int index) {
  final int backtickRun = _readBacktickRun(content, index);
  if (backtickRun > 0) {
    return _findClosingBacktickRun(content, index + backtickRun, backtickRun);
  }

  final int? markdownLinkEnd = _findMarkdownLinkEnd(content, index);
  if (markdownLinkEnd != null) {
    return markdownLinkEnd;
  }

  if (!_isUrlStart(content, index)) {
    return null;
  }
  final int urlEnd = _findUrlEnd(content, index);
  return urlEnd > index ? urlEnd : null;
}

bool _isEscaped(String content, int index) {
  int backslashes = 0;
  for (
    int cursor = index - 1;
    cursor >= 0 && content[cursor] == r'\';
    cursor--
  ) {
    backslashes++;
  }
  return backslashes.isOdd;
}

int? _findClosingBracket(String content, int start) {
  int depth = 0;
  for (int index = start + 1; index < content.length; index++) {
    if (_isEscaped(content, index)) {
      continue;
    }
    final String char = content[index];
    if (char == '[') {
      depth++;
      continue;
    }
    if (char != ']') {
      continue;
    }
    if (depth == 0) {
      return index;
    }
    depth--;
  }
  return null;
}

int? _findMarkdownDestinationEnd(String content, int openParenIndex) {
  int depth = 0;
  for (int index = openParenIndex + 1; index < content.length; index++) {
    if (_isEscaped(content, index)) {
      continue;
    }
    final String char = content[index];
    if (char == '(') {
      depth++;
      continue;
    }
    if (char != ')') {
      continue;
    }
    if (depth == 0) {
      return index + 1;
    }
    depth--;
  }
  return null;
}

int? _findMarkdownLinkEnd(String content, int start) {
  final int bracketStart =
      _charAt(content, start) == '!' && _charAt(content, start + 1) == '['
      ? start + 1
      : start;
  if (_charAt(content, bracketStart) != '[') {
    return null;
  }
  final int? closeBracket = _findClosingBracket(content, bracketStart);
  if (closeBracket == null || _charAt(content, closeBracket + 1) != '(') {
    return null;
  }
  return _findMarkdownDestinationEnd(content, closeBracket + 1);
}

int _readBacktickRun(String content, int start) {
  int length = 0;
  while (_charAt(content, start + length) == '`') {
    length++;
  }
  return length;
}

int? _findClosingBacktickRun(String content, int start, int runLength) {
  int index = start;
  while (index < content.length) {
    if (content[index] != '`') {
      index++;
      continue;
    }
    final int length = _readBacktickRun(content, index);
    if (length == runLength) {
      return index + length;
    }
    index += length;
  }
  return null;
}

// The URL rules of the web's `UrlSpanUtils.ts` (`isUrlStart`, `findUrlEnd`
// with angle brackets ending a URL).
bool _isUrlStart(String content, int index) {
  if (content.startsWith('http://', index) ||
      content.startsWith('https://', index)) {
    return true;
  }
  const String appScheme = 'fluxer:';
  if (!content.startsWith(appScheme, index)) {
    return false;
  }
  final String next = _charAt(content, index + appScheme.length);
  return next == '/' || (next.isNotEmpty && _urlSchemeChar.hasMatch(next));
}

bool _isUrlTerminationChar(String char) {
  return char == '' ||
      char == ' ' ||
      char == '\t' ||
      char == '\n' ||
      char == '\r' ||
      char == ')' ||
      char == '"' ||
      char == '<' ||
      char == '>';
}

bool _hasTerminalTld(String text) {
  int index = text.length;
  int letters = 0;
  while (index > 0 && _asciiLetter.hasMatch(text[index - 1])) {
    letters++;
    index--;
  }
  return letters >= 2 && index > 0 && text[index - 1] == '.';
}

int _findUrlEnd(String content, int start) {
  int end = start;
  int parenDepth = 0;
  while (end < content.length) {
    final String char = content[end];
    if (char == '(') {
      parenDepth++;
      end++;
      continue;
    }
    if (char == ')') {
      if (parenDepth > 0) {
        parenDepth--;
        end++;
        continue;
      }
      break;
    }
    if (_isUrlTerminationChar(char)) {
      break;
    }
    end++;
  }
  while (end > start &&
      _trimmedAutolinkPunctuation.contains(content[end - 1]) &&
      !_hasTerminalTld(content.substring(start, end))) {
    end--;
  }
  return end;
}

String _charAt(String content, int index) =>
    index >= 0 && index < content.length ? content[index] : '';
