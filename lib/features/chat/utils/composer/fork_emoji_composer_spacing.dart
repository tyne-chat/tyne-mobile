// Fork: "Add a space after emoji" (tyne-chat/tyne#650). Upstream's
// `InlineTokenTextEditingController` adds a leading space after non-whitespace
// and a trailing space after an emoji (and before non-whitespace even when
// `ensureTrailingSpace` is false), and `ComposerAutocompleteFieldState`'s
// `_replaceTrigger` appends a trailing space on plain controllers. When the
// setting is off, these helpers insert or replace with the emoji token directly
// and add neither a leading nor a trailing space, matching the web app's
// `ForkEmojiComposerSpacing.ts` so adjacent emojis can touch.

import 'package:fluxer_app/features/ui/input/emoji_inline_token.dart';
import 'package:fluxer_app/features/ui/input/inline_token_text_editing_controller.dart';
import 'package:fluxer_app/material_ui.dart';

/// Inserts an emoji token into [controller] at its current selection without
/// adding a leading or trailing space.
void forkInsertEmojiWithoutSpacing(
  InlineTokenTextEditingController controller,
  String name,
  String surrogates, {
  int? maxActualLength,
}) {
  final String text = controller.text;
  final TextSelection sel = controller.selection;
  final int start = sel.isValid ? sel.start.clamp(0, text.length) : text.length;
  final int end = sel.isValid ? sel.end.clamp(start, text.length) : text.length;
  final EmojiInlineToken token = EmojiInlineToken(
    displayName: name,
    wireText: buildEmojiWireToken(name, surrogates),
  );
  if (maxActualLength != null) {
    final int removedLength = start == end
        ? 0
        : controller.wireLengthForDisplayText(text.substring(start, end));
    if (controller.wireLength - removedLength + token.wireText.length >
        maxActualLength) {
      return;
    }
  }
  final String sentinel = controller.allocateToken(token);
  final String before = text.substring(0, start);
  final String after = text.substring(end);
  controller.value = TextEditingValue(
    text: '$before$sentinel$after',
    selection: TextSelection.collapsed(offset: start + sentinel.length),
  );
}

/// Replaces [matchStart]..[matchEnd] in [controller] with an emoji (as an
/// inline token on [InlineTokenTextEditingController], or [wire] on a plain
/// [TextEditingController]) without adding a trailing space.
void forkReplaceRangeWithEmojiWithoutSpacing(
  TextEditingController controller, {
  required int matchStart,
  required int matchEnd,
  required String name,
  required String wire,
  int? maxActualLength,
}) {
  final String text = controller.text;
  if (controller is InlineTokenTextEditingController) {
    final EmojiInlineToken token = EmojiInlineToken(
      displayName: name,
      wireText: wire,
    );
    if (maxActualLength != null) {
      final int removedLength = controller.wireLengthForDisplayText(
        text.substring(matchStart, matchEnd),
      );
      if (controller.wireLength - removedLength + token.wireText.length >
          maxActualLength) {
        return;
      }
    }
    final String sentinel = controller.allocateToken(token);
    final String before = text.substring(0, matchStart);
    final String after = text.substring(matchEnd);
    controller.value = TextEditingValue(
      text: '$before$sentinel$after',
      selection: TextSelection.collapsed(offset: matchStart + sentinel.length),
    );
    return;
  }
  if (maxActualLength != null &&
      text.length - (matchEnd - matchStart) + wire.length > maxActualLength) {
    return;
  }
  final String before = text.substring(0, matchStart);
  final String after = text.substring(matchEnd);
  controller.value = TextEditingValue(
    text: '$before$wire$after',
    selection: TextSelection.collapsed(offset: matchStart + wire.length),
  );
}
