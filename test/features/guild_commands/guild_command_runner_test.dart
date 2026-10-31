import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/permissions/channel_permission_cache_provider.dart';
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/features/guild_commands/providers/guild_command_runner.dart';
import 'package:fluxer_app/features/guild_commands/providers/guild_commands_providers.dart';

import 'guild_commands_test_support.dart';

const String _run = '/channels/c/commands/1';

/// The empty message the server answers with: only the fields the SDK requires.
Map<String, Object?> _message() => <String, Object?>{
  'id': '9',
  'channel_id': 'c',
  'author': <String, Object?>{
    'id': 'me',
    'username': 'me',
    'discriminator': '0',
    'global_name': null,
    'avatar': null,
    'avatar_color': null,
    'flags': 0,
  },
  'type': 0,
  'flags': 0,
  'content': 'posted',
  'timestamp': '2026-10-30T00:00:00.000Z',
  'pinned': false,
  'mention_everyone': false,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RecordingAdapter adapter;
  late ProviderContainer container;
  late TestClock clock;

  setUp(() {
    clock = TestClock();
    adapter = RecordingAdapter(
      (RequestOptions options) => options.path == _run
          ? _message()
          : <Object?>[commandJson('1', 'g1', 'tuck')],
    );
    container = commandsContainer(adapter: adapter, clock: clock);
    addTearDown(container.dispose);
  });

  Future<GuildCommandRunResult> run(
    String text, {
    String Function(String)? resolveEmoji,
  }) {
    return container
        .read(guildCommandRunnerProvider)
        .run(
          channelId: 'c',
          channelGuildId: 'g1',
          wireText: text,
          resolveEmoji: resolveEmoji ?? (String value) => value,
        );
  }

  Map<String, Object?> body(RequestOptions options) =>
      options.data as Map<String, Object?>;

  List<RequestOptions> posts() => <RequestOptions>[
    for (final RequestOptions options in adapter.requests)
      if (options.method == 'POST') options,
  ];

  test(
    'leaves ordinary text and unknown commands to the normal send',
    () async {
      expect(await run('hello there'), isA<GuildCommandNotACommand>());
      expect(adapter.requests, isEmpty);
      expect(await run('/nosuch hi'), isA<GuildCommandNotACommand>());
      expect(posts(), isEmpty);
    },
  );

  test('runs a command with its input, resolving typed emoji', () async {
    final GuildCommandRunResult result = await run(
      '/tuck <@2:3> :tuck:',
      resolveEmoji: (String text) => text.replaceAll(':tuck:', '<:tuck:5>'),
    );
    expect(result, isA<GuildCommandPosted>());
    expect(posts().single.path, _run);
    expect(body(posts().single), containsPair('input', '<@2:3> <:tuck:5>'));
  });

  test('waits for the list when it has not loaded', () async {
    expect(await run('/tuck x'), isA<GuildCommandPosted>());
    expect(adapter.paths, <String>['/users/@me/guild-commands', _run]);
  });

  test('sends once when Send is pressed twice while the run is out', () async {
    await container.read(guildCommandsProvider.notifier).ensureLoaded();
    final Completer<void> gate = Completer<void>();
    adapter.beforeResponse = (RequestOptions options) async {
      if (options.method == 'POST') {
        await gate.future;
      }
    };
    final Future<GuildCommandRunResult> first = run('/tuck x');
    await pumpEventQueue();
    expect(await run('/tuck x'), isA<GuildCommandIgnored>());
    gate.complete();
    expect(await first, isA<GuildCommandPosted>());
    expect(posts(), hasLength(1));
  });

  test('reuses the nonce when the same text is tried again', () async {
    await container.read(guildCommandsProvider.notifier).ensureLoaded();
    adapter.failWith = 500;
    expect(await run('/tuck x'), isA<GuildCommandFailed>());
    adapter.failWith = null;
    expect(await run('/tuck x'), isA<GuildCommandPosted>());
    expect(posts(), hasLength(2));
    expect(body(posts()[1])['nonce'], body(posts()[0])['nonce']);
    expect(await run('/tuck x'), isA<GuildCommandPosted>());
    expect(body(posts()[2])['nonce'], isNot(body(posts()[0])['nonce']));
  });

  test('refuses input on two lines without asking the server', () async {
    final GuildCommandRunResult result = await run('/tuck one\ntwo');
    expect(result, isA<GuildCommandNeedsOneLine>());
    expect(posts(), isEmpty);
  });

  test('says when the script is what is broken', () async {
    await container.read(guildCommandsProvider.notifier).ensureLoaded();
    adapter
      ..failWith = 400
      ..failBody = <String, Object?>{
        'code': 'GUILD_COMMAND_TEMPLATE_INVALID',
        'message': 'Invalid form body',
      };
    final GuildCommandRunResult result = await run('/tuck x');
    expect((result as GuildCommandFailed).broken, isTrue);
  });

  test(
    'marks the community stale when the command is gone, and only then',
    () async {
      final GuildCommandsNotifier notifier = container.read(
        guildCommandsProvider.notifier,
      );
      await notifier.ensureLoaded();
      adapter
        ..failWith = 429
        ..failBody = <String, Object?>{'code': 'RATE_LIMITED'};
      await run('/tuck x');
      adapter.failWith = null;
      final int before = adapter.requests.length;
      await notifier.ensureLoaded();
      expect(adapter.requests, hasLength(before));
      adapter
        ..failWith = 404
        ..failBody = <String, Object?>{'code': 'UNKNOWN_GUILD_COMMAND'};
      await run('/tuck x');
      adapter.failWith = null;
      await notifier.ensureLoaded();
      expect(adapter.paths.last, '/guilds/g1/commands');
    },
  );

  test("uses Use External Commands in another community's channel", () async {
    await container.read(guildCommandsProvider.notifier).ensureLoaded();
    Future<GuildCommandRunResult> elsewhere() => container
        .read(guildCommandRunnerProvider)
        .run(
          channelId: 'c',
          channelGuildId: 'g2',
          wireText: '/tuck x',
          resolveEmoji: (String value) => value,
        );
    expect(await elsewhere(), isA<GuildCommandNotACommand>());
    container
        .read(channelPermissionCacheProvider.notifier)
        .cacheEffectiveBits(
          channelId: 'c',
          outcome: (
            value: Permission.useExternalCommands.value,
            shouldCache: true,
          ),
        );
    expect(await elsewhere(), isA<GuildCommandPosted>());
  });
}
