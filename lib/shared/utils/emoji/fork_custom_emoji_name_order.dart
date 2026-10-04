// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: the A to Z order of custom emojis, as the web app's
// `compareEmojisByName` (fluxer_app EmojiSortingUtils.ts) has it, so that both
// apps list a community's emojis the same way.

/// Compares two custom emojis by name, ignoring case, with runs of digits
/// compared as numbers (`blob_2` before `blob_10`). Emojis whose names differ
/// only by case, or not at all, are listed newest first.
///
/// Emoji names hold only letters, digits and `_`. As in the web app's collation,
/// `_` comes before digits and digits before letters.
int compareCustomEmojiNames(
  String leftName,
  String leftId,
  String rightName,
  String rightId,
) {
  final int byName = _compareNatural(leftName, rightName);
  if (byName != 0) {
    return byName;
  }
  return _compareIdsNewestFirst(leftId, rightId);
}

/// A snowflake grows with time, so the larger id is the newer emoji. Ids are
/// compared as numbers: a 19-digit id is newer than an 18-digit one.
int _compareIdsNewestFirst(String leftId, String rightId) {
  final BigInt? left = BigInt.tryParse(leftId);
  final BigInt? right = BigInt.tryParse(rightId);
  if (left == null || right == null) {
    return rightId.compareTo(leftId);
  }
  return right.compareTo(left);
}

int _compareNatural(String left, String right) {
  int i = 0;
  int j = 0;
  while (i < left.length && j < right.length) {
    final int a = left.codeUnitAt(i);
    final int b = right.codeUnitAt(j);
    if (_isDigit(a) && _isDigit(b)) {
      final int leftEnd = _digitRunEnd(left, i);
      final int rightEnd = _digitRunEnd(right, j);
      final int byNumber = _compareDigitRuns(
        left.substring(i, leftEnd),
        right.substring(j, rightEnd),
      );
      if (byNumber != 0) {
        return byNumber;
      }
      i = leftEnd;
      j = rightEnd;
      continue;
    }
    final int byClass = _charClass(a).compareTo(_charClass(b));
    if (byClass != 0) {
      return byClass;
    }
    final int byChar = _lower(a).compareTo(_lower(b));
    if (byChar != 0) {
      return byChar;
    }
    i++;
    j++;
  }
  return (left.length - i).compareTo(right.length - j);
}

bool _isDigit(int unit) => unit >= 0x30 && unit <= 0x39;

int _digitRunEnd(String text, int start) {
  int end = start;
  while (end < text.length && _isDigit(text.codeUnitAt(end))) {
    end++;
  }
  return end;
}

/// Compares two runs of digits by value; leading zeros do not count.
int _compareDigitRuns(String left, String right) {
  final String a = _withoutLeadingZeros(left);
  final String b = _withoutLeadingZeros(right);
  if (a.length != b.length) {
    return a.length.compareTo(b.length);
  }
  return a.compareTo(b);
}

String _withoutLeadingZeros(String digits) {
  int start = 0;
  while (start < digits.length - 1 && digits.codeUnitAt(start) == 0x30) {
    start++;
  }
  return digits.substring(start);
}

/// Punctuation such as `_` first, then digits, then letters and the rest.
int _charClass(int unit) {
  if (_isDigit(unit)) {
    return 1;
  }
  final int lower = _lower(unit);
  if (lower >= 0x61 && lower <= 0x7a) {
    return 2;
  }
  return unit < 0x80 ? 0 : 2;
}

int _lower(int unit) => unit >= 0x41 && unit <= 0x5a ? unit + 0x20 : unit;
