// Fork: the fork's wiring in upstream's gateway event listener
// (gateway_provider.dart). READY resets the signal bar, the server commands
// and reloads the account's personas; the fork's gateway events reach the
// signal bar, the server commands, the persona state and the typing personas.
// Each is one line inside upstream's code, which a rebase can drop without a
// conflict, so these tests send the events through the real listener and
// handler and check that each line still fires.
import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/gateway/providers/typing_personas_provider.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/providers/gateway/gateway_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/router/route_state_providers.dart';
import 'package:fluxer_app/features/guild_commands/providers/guild_commands_providers.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/domain/persona_settings.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/features/signal_bar/providers/signal_bar_providers.dart';
import 'package:fluxer_dart/export.dart';
import 'package:fluxer_dart/gateway.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fork_support/wait_until.dart';
import '../../helpers/open_test_database.dart';
import '../gateway/gateway_event_handler_ready_snapshot_test.dart' hide main;

/// What the fork's lines in the listener asked of the providers they reach.
class _Calls {
  int signalBarRefreshes = 0;
  int channelSignalResets = 0;
  final List<String?> channelSignalUpdates = <String?>[];
  int guildCommandBuilds = 0;
  final List<String> staleCommandGuilds = <String>[];
  int personaListReloads = 0;
  int personaSettingsReloads = 0;
}

class _SignalBar extends SignalBarConfigNotifier {
  _SignalBar(this.calls);

  final _Calls calls;

  @override
  Future<void> refresh() async {
    calls.signalBarRefreshes++;
  }
}

class _ChannelSignals extends ChannelSignalsNotifier {
  _ChannelSignals(this.calls);

  final _Calls calls;

  @override
  void invalidate() {
    calls.channelSignalResets++;
    super.invalidate();
  }

  @override
  void handleChannelUpdate(Map<String, dynamic> data) {
    calls.channelSignalUpdates.add(data['channel_id'] as String?);
    super.handleChannelUpdate(data);
  }
}

class _GuildCommands extends GuildCommandsNotifier {
  _GuildCommands(this.calls);

  final _Calls calls;

  @override
  GuildCommandsState build() {
    calls.guildCommandBuilds++;
    return super.build();
  }

  @override
  void markStale(String guildId) {
    calls.staleCommandGuilds.add(guildId);
    super.markStale(guildId);
  }
}

class _MyPersonas extends MyPersonasNotifier {
  _MyPersonas(this.calls);

  final _Calls calls;

  @override
  AsyncValue<List<Persona>> build() => const AsyncData(<Persona>[]);

  @override
  Future<void> reloadSilently() async {
    calls.personaListReloads++;
  }
}

class _PersonaSettings extends PersonaSettingsNotifier {
  _PersonaSettings(this.calls);

  final _Calls calls;

  @override
  AsyncValue<PersonaSettings> build() => const AsyncData(PersonaSettings());

  @override
  Future<void> reloadSilently() async {
    calls.personaSettingsReloads++;
  }
}

/// A connection whose events the test sends; it never opens a socket.
class _ScriptedGatewayConnection extends GatewayConnection {
  _ScriptedGatewayConnection() : super(token: 'test', dio: Dio());

  final StreamController<GatewayEvent> _scripted =
      StreamController<GatewayEvent>.broadcast();

  @override
  Stream<GatewayEvent> get events => _scripted.stream;

  void send(GatewayEvent event) => _scripted.add(event);

  @override
  Future<void> connect() async {}

  @override
  Future<void> suspend() async {}

  Future<void> close() => _scripted.close();
}

/// Fails every request: nothing here may reach the network.
class _NoNetwork implements HttpClientAdapter {
  final List<String> requested = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requested.add('${options.method} ${options.uri.path}');
    return ResponseBody.fromString('{}', 500);
  }

  @override
  void close({bool force = false}) {}
}

UnknownGatewayEvent _event(String type, Map<String, dynamic> data) =>
    UnknownGatewayEvent(eventType: type, data: data);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Calls calls;
  late _ScriptedGatewayConnection connection;
  late _NoNetwork network;
  late FluxerDatabase db;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    calls = _Calls();
    connection = _ScriptedGatewayConnection();
    network = _NoNetwork();
    db = openTestDatabase();
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.fluxer.invalid'))
      ..httpClientAdapter = network;
    container = ProviderContainer(
      overrides: [
        gatewayConnectionProvider.overrideWithValue(connection),
        fluxerDatabaseProvider.overrideWithValue(db),
        fluxerDioProvider.overrideWithValue(dio),
        fluxerClientProvider.overrideWithValue(
          FluxerClient(dio, baseUrl: 'https://test.fluxer.invalid'),
        ),
        // upstream's test user in READY below.
        currentUserIdProvider.overrideWithValue('100'),
        contextualGuildIdProvider.overrideWithValue(null),
        signalBarConfigProvider.overrideWith(() => _SignalBar(calls)),
        channelSignalsProvider.overrideWith(() => _ChannelSignals(calls)),
        guildCommandsProvider.overrideWith(() => _GuildCommands(calls)),
        myPersonasProvider.overrideWith(() => _MyPersonas(calls)),
        personaSettingsProvider.overrideWith(() => _PersonaSettings(calls)),
      ],
    );
    // Disposed before the database closes (openTestDatabase's tear-down).
    addTearDown(() async {
      container.dispose();
      await connection.close();
      await connection.dispose();
    });
    container.read(gatewayEventListenerProvider);
  });

  /// The listener handles events one at a time, in order: once a marker sent
  /// after [events] has been handled, so has every one of them.
  Future<void> sendThenWait(List<GatewayEvent> events) async {
    for (final GatewayEvent event in events) {
      connection.send(event);
    }
    connection.send(
      _event('GUILD_COMMANDS_UPDATE', <String, dynamic>{'guild_id': 'marker'}),
    );
    await waitUntil(
      () =>
          calls.staleCommandGuilds.isNotEmpty &&
          calls.staleCommandGuilds.last == 'marker',
      'the listener to handle the events',
    );
    calls.staleCommandGuilds.removeLast();
  }

  group('READY', () {
    Future<void> sendReady() => sendThenWait(<GatewayEvent>[
      ReadyEvent(
        sessionId: 'session-1',
        user: forkUpstream.user(),
        rawGuilds: const <Map<String, dynamic>>[],
        privateChannels: const [],
        relationships: const [],
        readStates: const [],
        presences: const [],
        users: const <Map<String, dynamic>>[],
      ),
    ]);

    test("empties every channel's signals and refetches the bar", () async {
      await sendReady();

      expect(calls.channelSignalResets, 1);
      expect(calls.signalBarRefreshes, 1);
    });

    test('drops the server commands, to be loaded again on next use', () async {
      container.read(guildCommandsProvider);
      expect(calls.guildCommandBuilds, 1);

      await sendReady();
      container.read(guildCommandsProvider);

      expect(calls.guildCommandBuilds, 2);
    });

    test('reloads the persona list and the persona settings once', () async {
      await sendReady();

      expect(calls.personaListReloads, 1);
      expect(calls.personaSettingsReloads, 1);
      expect(network.requested, isEmpty);
    });

    test('a resume repeats none of it', () async {
      await sendThenWait(<GatewayEvent>[const ResumedEvent()]);

      expect(calls.channelSignalResets, 0);
      expect(calls.signalBarRefreshes, 0);
      expect(calls.personaListReloads, 0);
      expect(calls.personaSettingsReloads, 0);
    });
  });

  test(
    "a community's commands changing marks only that community stale",
    () async {
      await sendThenWait(<GatewayEvent>[
        _event('GUILD_COMMANDS_UPDATE', <String, dynamic>{'guild_id': 'g1'}),
        _event('GUILD_COMMANDS_UPDATE', <String, dynamic>{'guild_id': 'g2'}),
      ]);

      expect(calls.staleCommandGuilds, <String>['g1', 'g2']);
    },
  );

  group('signal bar events', () {
    test("a channel's signals changing reaches that channel", () async {
      await sendThenWait(<GatewayEvent>[
        _event('CHANNEL_SIGNAL_UPDATE', <String, dynamic>{
          'channel_id': 'c1',
          'bar_version': 0,
        }),
      ]);

      expect(calls.channelSignalUpdates, <String?>['c1']);
    });

    test('a newer bar is fetched', () async {
      await sendThenWait(<GatewayEvent>[
        _event('SIGNAL_BAR_UPDATE', <String, dynamic>{'version': 3}),
      ]);

      expect(calls.signalBarRefreshes, 1);
    });
  });

  test(
    'a persona selected in a channel by another session is applied',
    () async {
      await sendThenWait(<GatewayEvent>[
        _event('USER_PERSONA_CHANNEL_STATE_UPDATE', <String, dynamic>{
          'channel_id': 'c1',
          'persona_id': 'persona_a',
        }),
      ]);

      expect(
        container.read(activePersonaProvider).channelPersonaIds,
        <String, String>{'c1': 'persona_a'},
      );
    },
  );

  test('typing as a persona names the persona while they type', () async {
    await sendThenWait(<GatewayEvent>[
      TypingStartEvent(
        channelId: 'c1',
        userId: '200',
        timestamp: DateTime.now(),
        subprofile: MessageSubprofileResponseSchema.fromJson(
          const <String, Object?>{'id': 'persona_b', 'name': 'Bao'},
        ),
      ),
    ]);

    expect(
      container.read(typingPersonasProvider)['c1']?['200']?.id,
      'persona_b',
    );
  });
}
