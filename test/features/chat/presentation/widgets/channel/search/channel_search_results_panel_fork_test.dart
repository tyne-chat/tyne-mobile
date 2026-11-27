// Fork: tyne-chat/tyne#946 — regression tests for ChannelSearchResultsPanel
// Scope and Sort modal sheets when the panel unmounts before the user picks an
// option from the sheet.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/chat/data/channel_search_query_parser.dart';
import 'package:fluxer_app/features/chat/data/message_search_repository.dart';
import 'package:fluxer_app/features/chat/domain/channel_search_chip_filters.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/channel/search/channel_search_results_panel.dart';
import 'package:fluxer_app/features/chat/providers/channel/channel_details_providers.dart';
import 'package:fluxer_app/features/chat/providers/channel/channel_header_search_provider.dart';
import 'package:fluxer_app/features/chat/utils/search/channel_search_utils.dart';
import 'package:fluxer_app/material_ui.dart';

import '../../../../../../helpers/core_test_provider_overrides.dart';
import '../../../../../../helpers/input_modality_override.dart';
import '../../../../../../helpers/open_test_database.dart';
import '../../../../../../helpers/test_l10n.dart';

class _RecordingChannelSearch extends ChannelSearch {
  _RecordingChannelSearch(this.searchedQueries);

  final List<MessageSearchQuery> searchedQueries;

  @override
  ChannelSearchState build(String channelId, String? guildId) {
    return ChannelSearchState(
      query: MessageSearchQuery.build(
        channelId: channelId,
        guildId: guildId,
        rawQuery: 'hello',
      ),
      hasSearched: true,
    );
  }

  @override
  Future<void> search({
    MessageSearchQuery? query,
    String? rawQuery,
    String? text,
    ChannelSearchParseHints? hints,
    ChannelSearchParseContext? context,
    MessageSearchScopeFilter? scope,
    MessageSearchSortFilter? sort,
    String? authorId,
    Set<MessageSearchContentFilter>? contentTypes,
    ChannelSearchChipFilters chipFilters = const ChannelSearchChipFilters(),
  }) async {
    if (query != null) {
      searchedQueries.add(query);
      state = state.copyWith(query: query);
    }
  }
}

void main() {
  testWidgets(
    'selecting Scope or Sort in ChannelSearchResultsPanel bottom sheets updates search state without StateError after the panel unmounts',
    (WidgetTester tester) async {
      final db.FluxerDatabase database = openTestDatabase();
      final List<MessageSearchQuery> searchedQueries = <MessageSearchQuery>[];
      final ValueNotifier<bool> mountPanel = ValueNotifier<bool>(true);
      addTearDown(mountPanel.dispose);

      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: database,
          extra: [
            inputModalityOverride(touch: true),
            channelSearchProvider(
              'c1',
              'g1',
            ).overrideWith(() => _RecordingChannelSearch(searchedQueries)),
          ],
        ),
      );
      addTearDown(container.dispose);

      final colorTheme = buildDarkColorTheme();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            navigatorKey: rootNavigatorKey,
            locale: kTestLocale,
            localizationsDelegates: fluxerLocalizationsDelegates,
            supportedLocales: FluxerLocalizations.supportedLocales,
            theme: buildFluxerTheme(
              colorTheme: colorTheme,
              textTheme: FluxerTextTheme.fromColors(colorTheme),
              layoutTheme: FluxerLayoutTheme.scaled(),
            ),
            home: Scaffold(
              body: ValueListenableBuilder<bool>(
                valueListenable: mountPanel,
                builder: (_, bool mounted, _) {
                  if (!mounted) {
                    return const SizedBox.shrink();
                  }
                  return ChannelSearchResultsPanel(
                    channelId: 'c1',
                    guildId: 'g1',
                    onClose: () {},
                  );
                },
              ),
            ),
          ),
        ),
      );

      // 1. Open Scope bottom sheet, unmount panel while sheet is open, select
      // `allGuilds`, and verify no StateError and search triggered!
      final String currentScopeLabel = channelSearchScopeLabel(
        testL10n,
        MessageSearchScopeFilter.current,
        isGuildChannel: true,
      );
      await tester.tap(find.bySemanticsLabel(currentScopeLabel));
      await tester.pumpAndSettle();

      mountPanel.value = false;
      await tester.pump();

      final String allGuildsLabel = channelSearchScopeLabel(
        testL10n,
        MessageSearchScopeFilter.allGuilds,
        isGuildChannel: true,
      );
      await tester.tap(find.text(allGuildsLabel));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        container.read(channelHeaderSearchProvider).scope,
        MessageSearchScopeFilter.allGuilds,
      );
      expect(searchedQueries, hasLength(1));
      expect(
        searchedQueries.single.uiScope,
        MessageSearchScopeFilter.allGuilds,
      );

      // 2. Re-mount panel, open Sort bottom sheet, unmount panel while sheet is
      // open, select `oldest`, and verify no StateError and search triggered!
      mountPanel.value = true;
      await tester.pump();

      await tester.tap(
        find.bySemanticsLabel(testL10n.channelDetailsSearchSortBy),
      );
      await tester.pumpAndSettle();

      mountPanel.value = false;
      await tester.pump();

      final String oldestLabel = channelSearchSortLabel(
        testL10n,
        MessageSearchSortFilter.oldest,
      );
      await tester.tap(find.text(oldestLabel));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        container.read(channelHeaderSearchProvider).sort,
        MessageSearchSortFilter.oldest,
      );
      expect(searchedQueries, hasLength(2));
      expect(searchedQueries.last.uiSort, MessageSearchSortFilter.oldest);
    },
  );
}
