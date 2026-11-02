// A nested ProviderScope gives this test its favourites, over upstream's app
// helper, which has none.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/pickers/emoji_picker_content.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/pickers/favorite_emoji_order.dart';
import 'package:fluxer_app/features/chat/providers/pickers/emoji_picker_provider.dart';
import 'package:fluxer_app/features/chat/providers/pickers/expression_picker_preferences_provider.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/utils/emoji/emoji_image_cache.dart';
import 'package:fluxer_app/shared/utils/emoji/emoji_registry.dart';

import '../../../../../helpers/open_test_database.dart';
import 'emoji_picker_content_test.dart' hide main;

class _StoredFavorites extends FavoriteEmojiKeys {
  @override
  Future<List<String>> build() =>
      Future.value(const ['custom:g1:zebra', 'custom:g1:ant']);
}

GuildEmojiEntry _emoji(String id) =>
    GuildEmojiEntry(id: id, name: id, animated: false, guildId: 'g1');

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await EmojiRegistry.preload();
  });

  setUp(() => forkUseDatabase(openTestDatabase()));

  group('sortByFavoriteOrder', () {
    test('follows the stored keys, mixing unicode and custom emoji', () {
      final items = ['unicode:joy', 'unicode:heart', 'custom:g1:1'];

      sortByFavoriteOrder(items, const [
        'unicode:heart',
        'custom:g1:1',
        'unicode:joy',
      ], (item) => item);

      expect(items, ['unicode:heart', 'custom:g1:1', 'unicode:joy']);
    });

    test('puts an item with no stored key last', () {
      final items = ['unknown', 'unicode:joy'];

      sortByFavoriteOrder(items, const ['unicode:joy'], (item) => item);

      expect(items, ['unicode:joy', 'unknown']);
    });
  });

  testWidgets('the Favorites row keeps the stored order', (tester) async {
    await tester.pumpWidget(
      forkUpstream.buildTestApp(
        allGuildEmojis: [_emoji('ant'), _emoji('zebra')],
        rankedUsageKeys: const <String>[],
        child: ProviderScope(
          overrides: [
            favoriteEmojiKeysProvider.overrideWith(_StoredFavorites.new),
          ],
          child: const SizedBox(
            width: 400,
            height: 400,
            child: EmojiPickerContent(channelId: 'channel-1'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final List<String?> shown = tester
        .widgetList<CachedEmojiImage>(find.byType(CachedEmojiImage))
        .map((widget) => widget.emojiId)
        .toList();

    expect(shown.take(2), ['zebra', 'ant']);
    await releaseTestWidgetTree(tester);
  });
}
