// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: how a community's emoji settings list its emojis (tyne-chat/tyne#775),
// as on the web app: by name or newest first, and with non-animated and
// animated emojis apart or in one list.

import 'package:fluxer_app/features/settings/domain/guild/expressions/guild_emoji_settings_entry.dart';
import 'package:fluxer_app/features/settings/utils/guild/guild_expression_search_utils.dart';

/// Stored by name, never by position.
enum GuildEmojiListSort { name, recent }

/// Stored by name, never by position.
enum GuildEmojiListGrouping { split, together }

typedef GuildEmojiListOrder = ({
  GuildEmojiListSort sort,
  GuildEmojiListGrouping grouping,
});

const GuildEmojiListOrder defaultGuildEmojiListOrder = (
  sort: GuildEmojiListSort.name,
  grouping: GuildEmojiListGrouping.split,
);

/// The two sections of the emoji list. `recent` lists the newest upload first,
/// as upstream did before the fork sorted by name. With `together`, every emoji
/// is in the first section and the second is empty.
({
  List<GuildEmojiSettingsEntry> staticEmojis,
  List<GuildEmojiSettingsEntry> animatedEmojis,
})
orderGuildEmojiSections(
  List<GuildEmojiSettingsEntry> emojis,
  GuildEmojiListOrder order,
) {
  final List<GuildEmojiSettingsEntry> ordered =
      List<GuildEmojiSettingsEntry>.of(emojis)..sort(
        order.sort == GuildEmojiListSort.recent
            ? (GuildEmojiSettingsEntry a, GuildEmojiSettingsEntry b) =>
                  compareGuildExpressionEntriesByIdDesc(a.id, b.id)
            : compareGuildEmojiSettingsEntriesByName,
      );
  if (order.grouping == GuildEmojiListGrouping.together) {
    return (
      staticEmojis: ordered,
      animatedEmojis: const <GuildEmojiSettingsEntry>[],
    );
  }
  return (
    staticEmojis: ordered
        .where((GuildEmojiSettingsEntry entry) => !entry.animated)
        .toList(growable: false),
    animatedEmojis: ordered
        .where((GuildEmojiSettingsEntry entry) => entry.animated)
        .toList(growable: false),
  );
}
