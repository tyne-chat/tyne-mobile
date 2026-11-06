// Fork: a persona row in the composer's autocomplete shows the persona's name
// with its account's display tag, or the owner's avatar, beside it. The badge
// gives way before the name does: the full tag when there is room, the tag's
// icon alone when there is less, nothing when even that would shorten the
// name. Kept out of upstream's composer_autocomplete_panel_test.dart so that
// file stays as upstream has it.
import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/composer/composer_autocomplete_panel.dart';
import 'package:fluxer_app/features/ui/avatar/fluxer_avatar.dart';
import 'package:fluxer_app/features/ui/badge/fluxer_user_tag.dart';
import 'package:fluxer_app/material_ui.dart';

import '../../../../../helpers/pump_fluxer_app.dart';

const String _tagIcon = 'https://cdn.test/tag-icon.png';

/// A persona row [width] wide. The test font draws every glyph one font size
/// wide, so the widths below are exact: the name "Al" is 32 wide, the badge
/// for "system" with its icon 83.5, and the row's padding takes 28.
Future<void> _pumpRow(
  WidgetTester tester, {
  required double width,
  String title = 'Al',
  String? tagText,
  String? tagIcon,
  String? ownerUserId,
  String? ownerAvatarUrl,
}) async {
  await tester.pumpWidget(
    pumpFluxerApp(
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: ComposerAutocompletePanelListTile(
              title: title,
              isSelected: false,
              onTap: () {},
              personaTagText: tagText,
              personaTagIcon: tagIcon,
              personaOwnerUserId: ownerUserId,
              personaOwnerAvatarUrl: ownerAvatarUrl,
              personaOwnerFallbackText: 'alice',
              personaOwnerAvatarColor: 0x336699,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

FluxerUserTag _tag(WidgetTester tester) =>
    tester.widget<FluxerUserTag>(find.byType(FluxerUserTag));

void main() {
  testWidgets('with room, a persona row shows the name and the full display '
      'tag', (WidgetTester tester) async {
    await _pumpRow(tester, width: 300, tagText: ' system ', tagIcon: _tagIcon);

    expect(find.text('Al'), findsOneWidget);
    expect(find.text('SYSTEM'), findsOneWidget);
    expect(_tag(tester).forceIconOnly, isFalse);
    expect(_tag(tester).iconUrl, _tagIcon);
  });

  testWidgets('with less room, the tag shrinks to its icon and the name stays '
      'whole', (WidgetTester tester) async {
    await _pumpRow(tester, width: 110, tagText: 'system', tagIcon: _tagIcon);

    expect(find.text('Al'), findsOneWidget);
    expect(find.text('SYSTEM'), findsNothing);
    expect(_tag(tester).forceIconOnly, isTrue);
  });

  testWidgets('with no room for any badge, only the name shows', (
    WidgetTester tester,
  ) async {
    await _pumpRow(tester, width: 70, tagText: 'system', tagIcon: _tagIcon);

    expect(find.text('Al'), findsOneWidget);
    expect(find.byType(FluxerUserTag), findsNothing);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });

  testWidgets('a tag without an icon shows no icon-only badge when narrow', (
    WidgetTester tester,
  ) async {
    await _pumpRow(tester, width: 110, tagText: 'system');

    expect(find.text('Al'), findsOneWidget);
    expect(find.byType(FluxerUserTag), findsNothing);
  });

  testWidgets('a tag icon without text shows the icon beside the name', (
    WidgetTester tester,
  ) async {
    await _pumpRow(tester, width: 300, tagText: '  ', tagIcon: ' $_tagIcon ');

    expect(find.byType(FluxerUserTag), findsNothing);
    expect(
      tester
          .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
          .imageUrl,
      _tagIcon,
    );
  });

  testWidgets("without a display tag, the owner's avatar shows beside the "
      'name', (WidgetTester tester) async {
    await _pumpRow(
      tester,
      width: 300,
      ownerUserId: '2000000000000000001',
      ownerAvatarUrl: 'https://cdn.test/avatar.png',
    );

    expect(find.text('Al'), findsOneWidget);
    final Finder owner = find.byKey(
      const ValueKey<String>(
        'auto-persona-owner-2000000000000000001-https://cdn.test/avatar.png',
      ),
    );
    expect(owner, findsOneWidget);
    expect(tester.widget<FluxerAvatar>(owner).size, 16);
  });

  testWidgets("without room for it, the owner's avatar gives way to the name", (
    WidgetTester tester,
  ) async {
    await _pumpRow(tester, width: 70, ownerUserId: '2000000000000000001');

    expect(find.text('Al'), findsOneWidget);
    expect(find.byType(FluxerAvatar), findsNothing);
  });

  testWidgets('a row with nothing of a persona keeps the plain name', (
    WidgetTester tester,
  ) async {
    await _pumpRow(tester, width: 300, tagText: ' ', ownerUserId: '');

    expect(find.text('Al'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ComposerAutocompletePanelListTile),
        matching: find.byType(LayoutBuilder),
      ),
      findsNothing,
    );
  });
}
