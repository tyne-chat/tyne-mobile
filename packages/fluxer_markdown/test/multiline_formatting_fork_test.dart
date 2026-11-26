// Fork: inline formatting across blank lines renders bold across paragraphs in
// `FluxerMarkdown` and collapses cleanly in inline previews (tyne-chat/tyne#641).

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_markdown/src/config/fluxer_markdown_config.dart';
import 'package:fluxer_markdown/src/contexts/fluxer_markdown_context.dart';
import 'package:fluxer_markdown/src/widgets/fluxer_markdown.dart';
import 'package:material_ui/material_ui.dart';

import 'support/native_test_parser.dart';

const FluxerMarkdownConfig _testMarkdownConfig = FluxerMarkdownConfig(
  unicodeEmojiUrlBuilder: _noopUnicodeEmojiUrl,
  customEmojiUrlBuilder: _noopCustomEmojiUrl,
);

String? _noopUnicodeEmojiUrl(String unicode) => null;

String _noopCustomEmojiUrl({
  required String id,
  required bool animated,
  required int size,
}) => '';

bool _hasBoldText(InlineSpan span, String expected) {
  if (span is! TextSpan) {
    return false;
  }
  final String? text = span.text;
  if (text != null &&
      text == expected &&
      span.style?.fontWeight == FontWeight.w700) {
    return true;
  }
  for (final InlineSpan child in span.children ?? const <InlineSpan>[]) {
    if (_hasBoldText(child, expected)) {
      return true;
    }
  }
  return false;
}

void main() {
  testWidgets('**...** across blank lines renders all lines bold', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FluxerMarkdown(
            astParser: parseTestMarkdownAst,
            data: '**Test sentence one\n\nTest sentence 2**',
            config: _testMarkdownConfig,
          ),
        ),
      ),
    );

    final RichText richText = tester.widget<RichText>(find.byType(RichText));
    expect(richText.text.toPlainText(), 'Test sentence one\n\nTest sentence 2');
    expect(
      _hasBoldText(richText.text, 'Test sentence one\n\nTest sentence 2'),
      isTrue,
    );
  });

  testWidgets('**...** across blank lines stays bold in inline reply preview', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FluxerMarkdown(
            astParser: parseTestMarkdownAst,
            data: '**Test sentence one\n\nTest sentence 2**',
            config: _testMarkdownConfig,
            context: FluxerMarkdownContext.restrictedInlineReply,
          ),
        ),
      ),
    );

    final RichText richText = tester.widget<RichText>(find.byType(RichText));
    expect(richText.text.toPlainText(), 'Test sentence one Test sentence 2');
    expect(
      _hasBoldText(richText.text, 'Test sentence one Test sentence 2'),
      isTrue,
    );
  });
}
