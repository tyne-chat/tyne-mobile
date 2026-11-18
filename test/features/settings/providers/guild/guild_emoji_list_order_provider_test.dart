// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/settings/domain/guild/expressions/guild_emoji_list_order.dart';
import 'package:fluxer_app/features/settings/providers/guild/guild_emoji_list_order_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Waits for the provider to read this device's saved choice.
Future<GuildEmojiListOrder> _restored(ProviderContainer container) async {
  container.read(guildEmojiListOrderProvider);
  await SharedPreferences.getInstance();
  await pumpEventQueue();
  return container.read(guildEmojiListOrderProvider);
}

void main() {
  test('starts by name, in two sections', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await _restored(container), defaultGuildEmojiListOrder);
  });

  test('remembers the choices by name on this device', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final ProviderContainer first = ProviderContainer();
    addTearDown(first.dispose);
    final GuildEmojiListOrderNotifier notifier = first.read(
      guildEmojiListOrderProvider.notifier,
    );
    await notifier.chooseSort(GuildEmojiListSort.recent);
    await notifier.chooseGrouping(GuildEmojiListGrouping.together);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(GuildEmojiListOrderNotifier.sortPrefKey), 'recent');
    expect(
      prefs.getString(GuildEmojiListOrderNotifier.groupingPrefKey),
      'together',
    );

    final ProviderContainer second = ProviderContainer();
    addTearDown(second.dispose);
    expect(await _restored(second), (
      sort: GuildEmojiListSort.recent,
      grouping: GuildEmojiListGrouping.together,
    ));
  });

  test('falls back to the default for a value it does not know', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      GuildEmojiListOrderNotifier.sortPrefKey: 'newest',
      GuildEmojiListOrderNotifier.groupingPrefKey: 'together',
    });
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await _restored(container), (
      sort: GuildEmojiListSort.name,
      grouping: GuildEmojiListGrouping.together,
    ));
  });
}
