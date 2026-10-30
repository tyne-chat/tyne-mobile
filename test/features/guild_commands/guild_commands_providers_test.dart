import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/domain/composer_slash_command.dart';
import 'package:fluxer_app/features/guild_commands/providers/guild_commands_providers.dart';

import 'guild_commands_test_support.dart';

const String _mine = '/users/@me/guild-commands';

void main() {
  late RecordingAdapter adapter;
  late TestClock clock;
  late ProviderContainer container;

  GuildCommandsNotifier notifier() =>
      container.read(guildCommandsProvider.notifier);

  setUp(() {
    clock = TestClock();
    adapter = RecordingAdapter(
      (RequestOptions options) => options.path == _mine
          ? <Object?>[
              commandJson('1', 'g1', 'tuck'),
              commandJson('2', 'g2', 'tuck'),
              commandJson('3', 'g2', 'hug'),
            ]
          : <Object?>[commandJson('3', 'g2', 'hug')],
    );
    container = commandsContainer(adapter: adapter, clock: clock);
    addTearDown(container.dispose);
  });

  String? resolved(String name, {String? guild, int bits = 0}) => notifier()
      .resolve(name, channelGuildId: guild, channelPermissionBits: bits)
      ?.id;

  group('requests', () {
    test('loads every community with one request, shared, then none', () async {
      await Future.wait(<Future<void>>[
        notifier().ensureLoaded(),
        notifier().ensureLoaded(),
      ]);
      await notifier().ensureLoaded();
      expect(adapter.paths, <String>[_mine]);
    });

    test('waits 30 seconds after a failure before asking again', () async {
      adapter.failWith = 429;
      await notifier().ensureLoaded();
      await notifier().ensureLoaded();
      expect(adapter.paths, hasLength(1));
      clock.advance(const Duration(seconds: 29));
      await notifier().ensureLoaded();
      expect(adapter.paths, hasLength(1));
      clock.advance(const Duration(seconds: 2));
      await notifier().ensureLoaded();
      expect(adapter.paths, hasLength(2));
    });

    test(
      'fetches nothing on the event, and one community on next use',
      () async {
        await notifier().ensureLoaded();
        notifier().markStale('g2');
        expect(adapter.paths, hasLength(1));
        await notifier().ensureLoaded();
        expect(adapter.paths, <String>[_mine, '/guilds/g2/commands']);
        await notifier().ensureLoaded();
        expect(adapter.paths, hasLength(2));
      },
    );

    test('reloads everything with one request when many are stale', () async {
      await notifier().ensureLoaded();
      for (final String guildId in <String>['g1', 'g2', 'g3', 'g4']) {
        notifier().markStale(guildId);
      }
      await Future.wait(<Future<void>>[
        notifier().ensureLoaded(),
        notifier().ensureLoaded(),
      ]);
      expect(adapter.paths, <String>[_mine, _mine]);
    });

    test('keeps the commands it has when a refresh fails', () async {
      await notifier().ensureLoaded();
      adapter.failWith = 500;
      notifier().markStale('g2');
      await notifier().ensureLoaded();
      await notifier().ensureLoaded();
      expect(adapter.paths, hasLength(2));
      expect(resolved('hug'), '3');
    });
  });

  group('communities joined and left', () {
    test(
      'fetches a community joined after loading, and drops one left',
      () async {
        container.dispose();
        List<({String id, String name})> sidebar = <({String id, String name})>[
          (id: 'g1', name: 'Temple'),
          (id: 'g2', name: 'Garden'),
        ];
        container = commandsContainer(
          adapter: adapter,
          clock: clock,
          sidebar: () => sidebar,
        );
        addTearDown(container.dispose);
        await notifier().ensureLoaded();
        sidebar = <({String id, String name})>[
          (id: 'g1', name: 'Temple'),
          (id: 'g3', name: 'New'),
        ];
        container.invalidate(guildCommandsSidebarProvider);
        await notifier().ensureLoaded();
        expect(adapter.paths.last, '/guilds/g3/commands');
        expect(resolved('tuck', guild: 'g2'), isNull);
      },
    );
  });

  group('precedence', () {
    setUp(() => notifier().ensureLoaded());

    test('takes the channel community, then sidebar order', () {
      expect(resolved('tuck', guild: 'g2'), '2');
      expect(resolved('tuck', guild: 'g1'), '1');
      expect(resolved('tuck'), '1');
    });

    test('honours Use External Commands in another community', () {
      expect(resolved('hug', guild: 'g1'), isNull);
      expect(
        resolved('hug', guild: 'g1', bits: useExternalCommandsPermission),
        '3',
      );
      expect(resolved('hug'), '3');
    });

    test('lists one command per name, after the built-ins', () {
      const ComposerSimpleSlashCommand shrug = ComposerSimpleSlashCommand(
        name: '/shrug',
        description: 'Shrug',
        content: 'shrug',
      );
      final List<ComposerSlashCommand> commands = notifier().composerCommands(
        const <ComposerSlashCommand>[shrug],
        channelGuildId: null,
        channelPermissionBits: 0,
      );
      expect(commands.map((ComposerSlashCommand c) => c.name), <String>[
        '/shrug',
        '/tuck',
        '/hug',
      ]);
      expect(commands[1].description, 'Does tuck · Temple');
    });

    test('adds no input options, so picking one inserts plain text', () {
      final List<ComposerSlashCommand> commands = notifier().composerCommands(
        const <ComposerSlashCommand>[],
        channelGuildId: 'g1',
        channelPermissionBits: 0,
      );
      expect((commands.single as ComposerActionSlashCommand).options, isEmpty);
    });
  });
}
