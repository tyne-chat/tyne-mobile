// Fork: searching a community's emojis or stickers crashed the page. The list
// of matches holds positions in the full list, and the page looked each one up
// again in the list of matches, which works only while nothing is filtered.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/guilds/providers/guild_providers.dart';
import 'package:fluxer_app/features/settings/domain/guild/expressions/guild_emoji_settings_entry.dart';
import 'package:fluxer_app/features/settings/domain/guild/expressions/guild_emoji_settings_state.dart';
import 'package:fluxer_app/features/settings/domain/guild/expressions/guild_expression_uploader.dart';
import 'package:fluxer_app/features/settings/domain/guild/expressions/guild_sticker_settings_entry.dart';
import 'package:fluxer_app/features/settings/domain/guild/expressions/guild_sticker_settings_state.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/guild/expressions/guild_emoji_list_item.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/guild/expressions/guild_emoji_settings_widget.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/guild/expressions/guild_sticker_grid_item.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/guild/expressions/guild_sticker_settings_widget.dart';
import 'package:fluxer_app/features/settings/providers/guild/guild_expression_limits_provider.dart';
import 'package:fluxer_app/features/settings/providers/guild/guild_settings_tab_providers.dart';
import 'package:fluxer_app/features/settings/utils/guild/guild_expression_search_utils.dart';
import 'package:fluxer_app/material_ui.dart';

import '../../../../../../helpers/test_l10n.dart';

const String _guildId = 'guild-1';
const GuildExpressionUploader _uploader = GuildExpressionUploader(
  id: 'me',
  username: 'me',
);
const List<String> _names = <String>[
  'alpha',
  'bravo',
  'charlie',
  'delta',
  'echo',
  'foxtrot',
];

Future<void> _pump(WidgetTester tester, Widget child) async {
  final colorTheme = buildDarkColorTheme();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('me'),
        guildSettingsPermissionsProvider(_guildId).overrideWithValue(0),
        guildExpressionLimitsProvider(_guildId).overrideWith((ref) => null),
        guildByIdProvider(_guildId).overrideWith((ref) => null),
      ],
      child: MaterialApp(
        locale: kTestLocale,
        localizationsDelegates: fluxerLocalizationsDelegates,
        supportedLocales: FluxerLocalizations.supportedLocales,
        theme: buildFluxerTheme(
          colorTheme: colorTheme,
          textTheme: FluxerTextTheme.fromColors(colorTheme),
          layoutTheme: FluxerLayoutTheme.scaled(),
        ),
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
}

/// Lets the images' own timers run out, on the test's fake clock.
Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

List<String> _emojiRows(WidgetTester tester) => tester
    .widgetList<GuildEmojiListItem>(find.byType(GuildEmojiListItem))
    .map((GuildEmojiListItem item) => item.entry.name)
    .toList();

void main() {
  group('a search on the community emoji page', () {
    final List<GuildEmojiSettingsEntry> emojis = <GuildEmojiSettingsEntry>[
      for (final String name in _names)
        GuildEmojiSettingsEntry(
          id: 'emoji-$name',
          name: name,
          animated: false,
          uploader: _uploader,
        ),
    ];

    GuildEmojiSettingsState searching(String query) => GuildEmojiSettingsState(
      loadStatus: GuildEmojiSettingsLoadStatus.success,
      emojis: emojis,
      searchQuery: query,
      debouncedSearchQuery: query,
      filteredIndices: filterGuildEmojiIndices(emojis, query),
    );

    testWidgets('shows a match from late in the list', (tester) async {
      await _pump(
        tester,
        GuildEmojiSettingsWidget(guildId: _guildId, state: searching('fox')),
      );

      expect(tester.takeException(), isNull);
      expect(_emojiRows(tester), <String>['foxtrot']);
      await _finish(tester);
    });

    testWidgets('shows the right match, not the one at its place in the '
        'matches', (tester) async {
      await _pump(
        tester,
        GuildEmojiSettingsWidget(guildId: _guildId, state: searching('o')),
      );

      expect(tester.takeException(), isNull);
      expect(_emojiRows(tester), <String>['bravo', 'echo', 'foxtrot']);
      await _finish(tester);
    });
  });

  group('a search on the community sticker page', () {
    final List<GuildStickerSettingsEntry> stickers =
        <GuildStickerSettingsEntry>[
          for (final String name in _names)
            GuildStickerSettingsEntry(
              id: 'sticker-$name',
              name: name,
              description: '',
              tags: const <String>[],
              uploader: _uploader,
            ),
        ];

    testWidgets('shows a match from late in the list', (tester) async {
      await _pump(
        tester,
        GuildStickerSettingsWidget(
          guildId: _guildId,
          state: GuildStickerSettingsState(
            loadStatus: GuildStickerSettingsLoadStatus.success,
            stickers: stickers,
            searchQuery: 'fox',
            debouncedSearchQuery: 'fox',
            filteredIndices: filterGuildStickerIndices(stickers, 'fox'),
            density: GuildStickerDensity.cozy,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester
            .widgetList<GuildStickerGridItem>(find.byType(GuildStickerGridItem))
            .map((GuildStickerGridItem item) => item.entry.name),
        <String>['foxtrot'],
      );
      await _finish(tester);
    });
  });
}
