import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/guild_commands/presentation/guild_command_editor.dart';
import 'package:fluxer_app/features/ui/input/fluxer_input.dart';
import 'package:fluxer_app/material_ui.dart';

void main() {
  testWidgets("the slash sits on the name's line, right before it", (
    WidgetTester tester,
  ) async {
    final TextEditingController name = TextEditingController(text: 'hug');
    final TextEditingController other = TextEditingController(text: 'hello');
    addTearDown(name.dispose);
    addTearDown(other.dispose);
    final colorTheme = buildDarkColorTheme();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFluxerTheme(
          colorTheme: colorTheme,
          textTheme: FluxerTextTheme.fromColors(colorTheme),
          layoutTheme: FluxerLayoutTheme.scaled(),
        ),
        home: Scaffold(
          body: Column(
            children: <Widget>[
              GuildCommandNameField(
                controller: name,
                label: 'Name',
                enabled: true,
                onChanged: (_) {},
              ),
              FluxerInput(controller: other, label: 'Other'),
            ],
          ),
        ),
      ),
    );

    final Finder fields = find.byType(EditableText);
    final Rect slash = tester.getRect(find.text('/'));
    final Rect nameText = tester.getRect(fields.first);
    final Rect otherText = tester.getRect(fields.last);

    // Not stretched to a prefix icon's 48 by 48 box, where the glyph would sit
    // in the top left corner and this box's edges would say nothing about it.
    expect(slash.height, lessThan(kMinInteractiveDimension));
    expect(slash.center.dy, moreOrLessEquals(nameText.center.dy, epsilon: 1));
    // Flutter keeps 4 between a prefix and the text.
    expect(nameText.left - slash.right, inInclusiveRange(0, 4));
    // Lined up with the text of the fields around it.
    expect(slash.left, moreOrLessEquals(otherText.left, epsilon: 1));
  });
}
