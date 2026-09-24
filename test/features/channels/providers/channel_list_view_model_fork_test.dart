import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/permissions/channel_permission_cache_provider.dart';
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/features/channels/data/channel_repository.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/channels/providers/channel_list_view_model.dart';
import 'package:fluxer_app/features/channels/providers/channel_providers.dart';
import 'package:fluxer_app/features/guilds/data/guild_repository.dart';
import 'package:fluxer_app/features/guilds/domain/guild.dart';
import 'package:fluxer_app/features/guilds/providers/guild_providers.dart';
import 'package:riverpod/src/framework.dart' show Override;

// Fork: the channel list after a sign-out, when the provider is invalidated
// but kept alive (tyne-chat/tyne#250), and the early return in loadChannels
// (tyne-chat/tyne#249).

const Guild _guild = Guild(id: 'guild-1', name: 'Guild 1');
const List<Channel> _channels = <Channel>[
  Channel(id: 'c1', guildId: 'guild-1', name: 'general'),
];

class _RecordingChannelRepository implements ChannelRepository {
  _RecordingChannelRepository(this.controller);

  final List<String> watchedGuildIds = <String>[];
  final StreamController<List<Channel>> controller;

  @override
  Stream<List<Channel>> watchChannels(String guildId) {
    watchedGuildIds.add(guildId);
    return controller.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SilentGuildRepository implements GuildRepository {
  @override
  Stream<Guild?> watchServerById(String id) => const Stream<Guild?>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProviderContainer _container(_RecordingChannelRepository channels) {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      channelRepositoryProvider.overrideWithValue(channels),
      guildRepositoryProvider.overrideWithValue(_SilentGuildRepository()),
      // The channel's permissions are cached, so the list does not ask the
      // permission cache to rebuild (as in upstream's test).
      channelPermissionCacheProvider.overrideWithValue(
        ChannelPermissionCaches(
          effective: <String, int>{'c1': Permission.viewChannel.value},
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'after a sign-out invalidates the provider, the same guild loads again',
    () async {
      final StreamController<List<Channel>> controller =
          StreamController<List<Channel>>.broadcast();
      addTearDown(controller.close);
      final _RecordingChannelRepository channels = _RecordingChannelRepository(
        controller,
      );
      final ProviderContainer container = _container(channels);

      container
          .read(channelListViewModelProvider.notifier)
          .loadChannels(_guild.id, guild: _guild);
      channels.controller.add(_channels);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(channelListViewModelProvider).categories,
        isNotEmpty,
      );

      // What sign-out does (user_settings_modal.dart): the kept-alive
      // provider runs onDispose and build() again on the same object.
      container.invalidate(channelListViewModelProvider);
      expect(container.read(channelListViewModelProvider).categories, isEmpty);

      container
          .read(channelListViewModelProvider.notifier)
          .loadChannels(_guild.id, guild: _guild);
      expect(channels.watchedGuildIds, <String>[_guild.id, _guild.id]);

      channels.controller.add(_channels);
      await Future<void>.delayed(Duration.zero);
      final ChannelListState state = container.read(
        channelListViewModelProvider,
      );
      expect(state.categories, isNotEmpty);
      expect(state.hasReceivedInitialChannelList, isTrue);
    },
  );

  test(
    'loading the same guild again before its first list keeps the watch',
    () async {
      final StreamController<List<Channel>> controller =
          StreamController<List<Channel>>.broadcast();
      addTearDown(controller.close);
      final _RecordingChannelRepository channels = _RecordingChannelRepository(
        controller,
      );
      final ProviderContainer container = _container(channels);
      container.read(channelListViewModelProvider.notifier)
        ..loadChannels(_guild.id, guild: _guild)
        ..loadChannels(_guild.id, guild: _guild);
      expect(channels.watchedGuildIds, <String>[_guild.id]);

      channels.controller.add(_channels);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(channelListViewModelProvider).categories,
        isNotEmpty,
      );
    },
  );
}
