// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: the order of a community's emoji settings (tyne-chat/tyne#775),
// remembered on this device for every account and community, like the persona
// gallery's view.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/features/settings/domain/guild/expressions/guild_emoji_list_order.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuildEmojiListOrderNotifier extends Notifier<GuildEmojiListOrder> {
  /// Hold the choices' names, never their positions.
  static const String sortPrefKey = 'guild_emoji_list_sort';
  static const String groupingPrefKey = 'guild_emoji_list_grouping';

  bool _chosen = false;

  @override
  GuildEmojiListOrder build() {
    _chosen = false;
    unawaited(_restore());
    return defaultGuildEmojiListOrder;
  }

  Future<void> _restore() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sort = prefs.getString(sortPrefKey);
      final String? grouping = prefs.getString(groupingPrefKey);
      if (!ref.mounted || _chosen) {
        return;
      }
      state = (
        sort: GuildEmojiListSort.values.firstWhere(
          (GuildEmojiListSort value) => value.name == sort,
          orElse: () => defaultGuildEmojiListOrder.sort,
        ),
        grouping: GuildEmojiListGrouping.values.firstWhere(
          (GuildEmojiListGrouping value) => value.name == grouping,
          orElse: () => defaultGuildEmojiListOrder.grouping,
        ),
      );
    } on Object catch (_) {
      // The default stays.
    }
  }

  /// Lists the emojis by [sort] from now on, on this device.
  Future<void> chooseSort(GuildEmojiListSort sort) async {
    _chosen = true;
    state = (sort: sort, grouping: state.grouping);
    await _save(sortPrefKey, sort.name);
  }

  /// Groups the emojis by [grouping] from now on, on this device.
  Future<void> chooseGrouping(GuildEmojiListGrouping grouping) async {
    _chosen = true;
    state = (sort: state.sort, grouping: grouping);
    await _save(groupingPrefKey, grouping.name);
  }

  Future<void> _save(String key, String value) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } on Object catch (_) {
      // Kept for this session only.
    }
  }
}

final NotifierProvider<GuildEmojiListOrderNotifier, GuildEmojiListOrder>
guildEmojiListOrderProvider =
    NotifierProvider<GuildEmojiListOrderNotifier, GuildEmojiListOrder>(
      GuildEmojiListOrderNotifier.new,
    );
