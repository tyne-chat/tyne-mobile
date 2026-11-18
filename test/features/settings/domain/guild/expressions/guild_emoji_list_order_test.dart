// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/settings/domain/guild/expressions/guild_emoji_list_order.dart';
import 'package:fluxer_app/features/settings/domain/guild/expressions/guild_emoji_settings_entry.dart';
import 'package:fluxer_app/features/settings/domain/guild/expressions/guild_expression_uploader.dart';

const GuildExpressionUploader _uploader = GuildExpressionUploader(
  id: '1',
  username: 'uploader',
);

GuildEmojiSettingsEntry _emoji(
  String id,
  String name, {
  bool animated = false,
}) => GuildEmojiSettingsEntry(
  id: id,
  name: name,
  animated: animated,
  uploader: _uploader,
);

// Snowflakes grow with time, so a larger id is a newer upload.
final List<GuildEmojiSettingsEntry> _emojis = <GuildEmojiSettingsEntry>[
  _emoji('1500000000000000002', 'banana'),
  _emoji('1500000000000000004', 'Apple', animated: true),
  _emoji('1500000000000000001', 'cherry', animated: true),
  _emoji('1500000000000000003', 'date'),
];

List<String> _names(List<GuildEmojiSettingsEntry> list) =>
    list.map((GuildEmojiSettingsEntry e) => e.name).toList();

void main() {
  test('lists by name in two sections by default', () {
    final sections = orderGuildEmojiSections(
      _emojis,
      defaultGuildEmojiListOrder,
    );
    expect(_names(sections.staticEmojis), <String>['banana', 'date']);
    expect(_names(sections.animatedEmojis), <String>['Apple', 'cherry']);
  });

  test('lists the newest upload first with Recently added', () {
    final sections = orderGuildEmojiSections(_emojis, (
      sort: GuildEmojiListSort.recent,
      grouping: GuildEmojiListGrouping.split,
    ));
    expect(_names(sections.staticEmojis), <String>['date', 'banana']);
    expect(_names(sections.animatedEmojis), <String>['Apple', 'cherry']);
  });

  test('puts every emoji in the first section with All in one list', () {
    final recent = orderGuildEmojiSections(_emojis, (
      sort: GuildEmojiListSort.recent,
      grouping: GuildEmojiListGrouping.together,
    ));
    expect(_names(recent.staticEmojis), <String>[
      'Apple',
      'date',
      'banana',
      'cherry',
    ]);
    expect(recent.animatedEmojis, isEmpty);
    final byName = orderGuildEmojiSections(_emojis, (
      sort: GuildEmojiListSort.name,
      grouping: GuildEmojiListGrouping.together,
    ));
    expect(_names(byName.staticEmojis), <String>[
      'Apple',
      'banana',
      'cherry',
      'date',
    ]);
  });

  test('leaves the list it was given as it was', () {
    final List<GuildEmojiSettingsEntry> given =
        List<GuildEmojiSettingsEntry>.of(_emojis);
    orderGuildEmojiSections(given, (
      sort: GuildEmojiListSort.recent,
      grouping: GuildEmojiListGrouping.together,
    ));
    expect(given, _emojis);
  });
}
