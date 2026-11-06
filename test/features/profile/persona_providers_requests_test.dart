// Fork: the requests the persona providers send, and what they keep when one
// fails. A burst of requests signs the user out (tyne-chat/tyne#114), so each
// load is counted: with the data missing, with the request failing (429, 401,
// offline), and with many readers. Also the selection, display tag and
// settings paths persona_providers_test.dart and persona_per_channel_test.dart
// leave out.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/features/emoji/domain/emoji_pins.dart';
import 'package:fluxer_app/features/emoji/providers/emoji_pins_provider.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/domain/persona_settings.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_dart/fluxer_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fork_support/wait_until.dart';

const String _list = '/users/@me/personas';
const String _settings = '/users/@me/personas/settings';
const String _channelStates = '/users/@me/personas/channel-states';

/// How a route answers: a status with a body, or no answer at all (offline).
class _Answer {
  const _Answer(this.status, [this.body]);
  const _Answer.offline() : status = 0, body = null;

  final int status;
  final Object? body;

  bool get offline => status == 0;
}

const _Answer _rateLimited = _Answer(429, <String, Object?>{
  'code': 'RATE_LIMITED',
  'message': 'Slow down',
  'retry_after': 1,
});
const _Answer _signedOut = _Answer(401, <String, Object?>{
  'code': 'UNAUTHORIZED',
  'message': 'Unauthorized',
});

/// The persona routes: answers each from [answers] and records every request
/// as "METHOD path body".
class _PersonaApi implements HttpClientAdapter {
  final List<String> calls = <String>[];
  final Map<String, _Answer> answers = <String, _Answer>{
    _list: const _Answer(200, <Object?>[]),
    _settings: const _Answer(200, <String, Object?>{}),
    _channelStates: const _Answer(200, <String, Object?>{
      'states': <Object?>[],
    }),
  };

  /// While set, GETs of the persona list wait for it.
  Completer<void>? holdList;

  List<String> callsTo(String path) => calls
      .where((String call) => call.split(' ')[1] == path)
      .toList(growable: false);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final String path = options.uri.path;
    final Object? data = options.data;
    calls.add(
      '${options.method} $path${data == null ? '' : ' ${jsonEncode(data)}'}',
    );
    if (path == _list && options.method == 'GET') {
      await holdList?.future;
    }
    final _Answer answer =
        answers[path] ?? const _Answer(404, <String, Object?>{});
    if (answer.offline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    return ResponseBody.fromString(
      jsonEncode(answer.body),
      answer.status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _PinsThatCannotForget extends EmojiPinsNotifier {
  @override
  Future<EmojiPins> build() async => EmojiPins.empty;

  @override
  Future<void> forgetPersona(String personaId) =>
      Future<void>.error(StateError('storage is gone'));
}

Map<String, Object?> _persona(String id, String name, {bool deleted = false}) =>
    <String, Object?>{
      'id': id,
      'name': name,
      if (deleted) 'deleted_at': '2026-10-01T00:00:00.000Z',
    };

List<String> _ids(AsyncValue<List<Persona>> value) => <String>[
  for (final Persona p in value.asData?.value ?? const []) p.id,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _PersonaApi api;
  late ProviderContainer container;

  ProviderContainer containerWith({
    Map<String, Object> prefs = const <String, Object>{},
    bool pinsCannotForget = false,
  }) {
    SharedPreferences.setMockInitialValues(prefs);
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.fluxer.invalid'))
      ..httpClientAdapter = api;
    final ProviderContainer created = ProviderContainer(
      overrides: [
        fluxerDioProvider.overrideWithValue(dio),
        fluxerClientProvider.overrideWithValue(
          FluxerClient(dio, baseUrl: 'https://test.fluxer.invalid'),
        ),
        if (pinsCannotForget)
          emojiPinsProvider.overrideWith(_PinsThatCannotForget.new),
      ],
    );
    addTearDown(created.dispose);
    return created;
  }

  setUp(() {
    api = _PersonaApi();
    container = containerWith();
  });

  /// Lets every request in flight finish, so a late extra request would show.
  Future<void> settle() => pumpEventQueue(times: 50);

  /// Loads the settings as the app does at start, then forgets those
  /// requests: a change made before they arrive would be overwritten by them.
  Future<void> loadSettings() async {
    container.read(personaSettingsProvider);
    await waitUntil(
      () =>
          container.read(personaSettingsProvider).hasValue &&
          api.callsTo(_channelStates).isNotEmpty,
      'the settings to load',
    );
    await settle();
    api.calls.clear();
  }

  List<String> patches() => api.calls
      .where((String call) => call.startsWith('PATCH '))
      .toList(growable: false);

  Object? lastPatchBody() =>
      jsonDecode(patches().last.split(' ').skip(2).join(' '));

  group('the persona list', () {
    test('is asked for once, however many places read it', () async {
      api.answers[_list] = _Answer(200, <Object?>[
        _persona('p1', 'Alice'),
        _persona('p2', 'Bao'),
      ]);

      for (int i = 0; i < 5; i++) {
        container
          ..listen(myPersonasProvider, (_, _) {})
          ..read(myPersonasProvider);
      }
      await waitUntil(
        () => container.read(myPersonasProvider).hasValue,
        'the persona list',
      );
      for (int i = 0; i < 20; i++) {
        container.read(myPersonasProvider);
      }
      await settle();

      expect(api.calls, <String>['GET $_list']);
      expect(_ids(container.read(myPersonasProvider)), <String>['p1', 'p2']);
    });

    test('keeps only live personas, from either shape of the answer', () async {
      api.answers[_list] = _Answer(200, <String, Object?>{
        'personas': <Object?>[
          _persona('p1', 'Alice'),
          _persona('gone', 'Deleted', deleted: true),
          'not a persona',
        ],
      });

      container.read(myPersonasProvider);
      await waitUntil(
        () => container.read(myPersonasProvider).hasValue,
        'the persona list',
      );

      expect(_ids(container.read(myPersonasProvider)), <String>['p1']);
    });

    test('an answer without a list is an empty list', () async {
      api.answers[_list] = const _Answer(200, <String, Object?>{'other': 1});

      container.read(myPersonasProvider);
      await waitUntil(
        () => container.read(myPersonasProvider).hasValue,
        'the persona list',
      );

      expect(_ids(container.read(myPersonasProvider)), isEmpty);
    });

    for (final ({String name, _Answer answer}) failure
        in <({String name, _Answer answer})>[
          (name: 'rate limited (429)', answer: _rateLimited),
          (name: 'signed out (401)', answer: _signedOut),
          (name: 'offline', answer: const _Answer.offline()),
        ]) {
      test('a first load that fails ${failure.name} shows the error and is '
          'not asked again by later reads', () async {
        api.answers[_list] = failure.answer;

        container.listen(myPersonasProvider, (_, _) {});
        await waitUntil(
          () => container.read(myPersonasProvider).hasError,
          'the failed load',
        );
        for (int i = 0; i < 20; i++) {
          container
            ..read(myPersonasProvider)
            ..listen(myPersonasProvider, (_, _) {});
        }
        await settle();

        expect(api.callsTo(_list), hasLength(1));
      });
    }

    test(
      'refresh shows loading, then the new list, with one request',
      () async {
        container.read(myPersonasProvider);
        await waitUntil(
          () => container.read(myPersonasProvider).hasValue,
          'the first load',
        );
        api.answers[_list] = _Answer(200, <Object?>[_persona('p3', 'Cat')]);

        final Future<void> refreshed = container
            .read(myPersonasProvider.notifier)
            .refresh();
        expect(container.read(myPersonasProvider).isLoading, isTrue);
        await refreshed;

        expect(_ids(container.read(myPersonasProvider)), <String>['p3']);
        expect(api.callsTo(_list), hasLength(2));
      },
    );

    test(
      'a silent reload keeps the list on screen until the new one arrives',
      () async {
        api.answers[_list] = _Answer(200, <Object?>[_persona('p1', 'Alice')]);
        container.read(myPersonasProvider);
        await waitUntil(
          () => container.read(myPersonasProvider).hasValue,
          'the first load',
        );
        api
          ..answers[_list] = _Answer(200, <Object?>[
            _persona('p1', 'Alice'),
            _persona('p2', 'Bao'),
          ])
          ..holdList = Completer<void>();

        final Future<void> reloaded = container
            .read(myPersonasProvider.notifier)
            .reloadSilently();
        await settle();
        expect(container.read(myPersonasProvider).isLoading, isFalse);
        expect(_ids(container.read(myPersonasProvider)), <String>['p1']);

        api.holdList!.complete();
        await reloaded;

        expect(_ids(container.read(myPersonasProvider)), <String>['p1', 'p2']);
        expect(api.callsTo(_list), hasLength(2));
      },
    );
  });

  test(
    'removing a persona whose pins cannot be dropped still removes it',
    () async {
      api.answers[_list] = _Answer(200, <Object?>[
        _persona('p1', 'Alice'),
        _persona('p2', 'Bao'),
      ]);
      container = containerWith(pinsCannotForget: true);
      await waitUntil(
        () => container.read(myPersonasProvider).hasValue,
        'the persona list',
      );

      container.read(myPersonasProvider.notifier).removePersona('p1');
      await settle();

      expect(_ids(container.read(myPersonasProvider)), <String>['p2']);
    },
  );

  group('the persona settings', () {
    test('are asked for once with the channel selections, however many '
        'places read them', () async {
      api.answers[_settings] = const _Answer(200, <String, Object?>{
        'active_persona_mode': 'last',
        'active_persona_scope': 'channel',
        'active_persona_id': 'p1',
        'is_latched': true,
        'display_tag_text': 'SYS',
      });
      api.answers[_channelStates] = const _Answer(200, <String, Object?>{
        'states': <Object?>[
          <String, Object?>{'channel_id': 'c1', 'persona_id': 'p2'},
        ],
      });

      for (int i = 0; i < 5; i++) {
        container
          ..listen(personaSettingsProvider, (_, _) {})
          ..read(personaSettingsProvider);
      }
      await waitUntil(
        () => container
            .read(activePersonaProvider)
            .channelPersonaIds
            .containsKey('c1'),
        'the settings and the channel selections',
      );
      await settle();

      expect(api.calls, <String>['GET $_settings', 'GET $_channelStates']);
      final ActivePersonaState active = container.read(activePersonaProvider);
      expect(active.mode, PersonaMode.last);
      expect(active.scope, PersonaScope.channel);
      expect(active.latchedIdFor('c1'), 'p2');
      expect(container.read(systemDisplayTagProvider).text, 'SYS');
    });

    for (final ({String name, _Answer answer}) failure
        in <({String name, _Answer answer})>[
          (name: 'rate limited (429)', answer: _rateLimited),
          (name: 'signed out (401)', answer: _signedOut),
          (name: 'offline', answer: const _Answer.offline()),
        ]) {
      test('a load that fails ${failure.name} asks nothing more, now or on '
          'later reads', () async {
        api.answers[_settings] = failure.answer;

        container.listen(personaSettingsProvider, (_, _) {});
        await waitUntil(
          () => container.read(personaSettingsProvider).hasError,
          'the failed load',
        );
        for (int i = 0; i < 20; i++) {
          container
            ..read(personaSettingsProvider)
            ..listen(personaSettingsProvider, (_, _) {});
        }
        await settle();

        expect(api.calls, <String>['GET $_settings']);
      });
    }

    test(
      'a failed channel selection load keeps the selections and asks once',
      () async {
        api.answers[_channelStates] = _rateLimited;
        final ActivePersonaNotifier active = container.read(
          activePersonaProvider.notifier,
        )..applyChannelState('c1', 'p1');

        await active.loadChannelStates();
        await settle();

        expect(
          container.read(activePersonaProvider).channelPersonaIds,
          <String, String>{'c1': 'p1'},
        );
        expect(api.callsTo(_channelStates), hasLength(1));
      },
    );

    test('refresh shows loading, then asks once more', () async {
      container.read(personaSettingsProvider);
      await waitUntil(
        () => container.read(personaSettingsProvider).hasValue,
        'the first load',
      );
      api.answers[_settings] = const _Answer(200, <String, Object?>{
        'active_persona_mode': 'last',
      });

      final Future<void> refreshed = container
          .read(personaSettingsProvider.notifier)
          .refresh();
      expect(container.read(personaSettingsProvider).isLoading, isTrue);
      await refreshed;

      expect(
        container.read(personaSettingsProvider).value?.activePersonaMode,
        'last',
      );
      expect(api.callsTo(_settings), hasLength(2));
    });

    test('a silent reload applies the new settings with one request', () async {
      container.read(personaSettingsProvider);
      await waitUntil(
        () => container.read(personaSettingsProvider).hasValue,
        'the first load',
      );
      api.answers[_settings] = const _Answer(200, <String, Object?>{
        'display_tag_text': 'NEW',
      });

      await container.read(personaSettingsProvider.notifier).reloadSilently();

      expect(container.read(systemDisplayTagProvider).text, 'NEW');
      expect(api.callsTo(_settings), hasLength(2));
    });

    test('a change sends only the fields it changes', () async {
      await loadSettings();

      await container
          .read(personaSettingsProvider.notifier)
          .updateSettings(
            activePersonaScope: 'channel',
            displayTagText: 'SYS',
            displayTagIcon: () => 'icon-hash',
          );

      expect(patches(), hasLength(1));
      expect(api.calls, hasLength(1));
      expect(lastPatchBody(), <String, Object?>{
        'active_persona_scope': 'channel',
        'display_tag_text': 'SYS',
        'display_tag_icon': 'icon-hash',
      });
      expect(container.read(activePersonaProvider).scope, PersonaScope.channel);
    });

    test('a change the server refuses is reported to the caller', () async {
      await loadSettings();
      api.answers[_settings] = _rateLimited;

      await expectLater(
        container
            .read(personaSettingsProvider.notifier)
            .updateSettings(activePersonaMode: 'last'),
        throwsA(isA<DioException>()),
      );
      expect(api.calls, hasLength(1));
    });
  });

  group('the selection', () {
    test('comes back from the device with its usage counts', () async {
      container = containerWith(
        prefs: <String, Object>{
          'persona_active_mode': 'last',
          'persona_active_id': 'p1',
          'persona_is_latched': true,
          'persona_frecency_map': jsonEncode(<String, Object?>{
            'p1': <String, Object?>{'count': 3, 'last_used': 1700000000000},
            'p2': <String, Object?>{},
          }),
        },
      );

      await waitUntil(
        () => container.read(activePersonaProvider).activePersonaId == 'p1',
        'the saved selection',
      );

      final ActivePersonaState state = container.read(activePersonaProvider);
      expect(state.mode, PersonaMode.last);
      expect(state.isLatched, isTrue);
      expect(state.frecencyUsage['p1'], (
        count: 3,
        lastUsedAtMs: 1700000000000,
      ));
      expect(state.frecencyUsage['p2'], (count: 0, lastUsedAtMs: 0));
      expect(api.calls, isEmpty);
    });

    test('usage counts it cannot read are left out', () async {
      container = containerWith(
        prefs: <String, Object>{
          'persona_active_id': 'p1',
          'persona_frecency_map': 'not json',
        },
      );

      await waitUntil(
        () => container.read(activePersonaProvider).activePersonaId == 'p1',
        'the saved selection',
      );

      expect(container.read(activePersonaProvider).frecencyUsage, isEmpty);
    });

    test('changing the scope saves it with one request', () async {
      await loadSettings();
      final ActivePersonaNotifier active = container.read(
        activePersonaProvider.notifier,
      );

      await active.setScope(PersonaScope.channel);
      await active.setScope(PersonaScope.channel);

      expect(container.read(activePersonaProvider).scope, PersonaScope.channel);
      expect(api.calls, <String>[
        'PATCH $_settings {"active_persona_scope":"channel"}',
      ]);
    });

    test('a scope the server refuses goes back to what it was', () async {
      await loadSettings();
      api.answers[_settings] = _rateLimited;

      await container
          .read(activePersonaProvider.notifier)
          .setScope(PersonaScope.channel);

      expect(container.read(activePersonaProvider).scope, PersonaScope.global);
      expect(api.calls, hasLength(1));
    });

    test('a new mode is saved on the device and sent once', () async {
      await loadSettings();
      final ActivePersonaNotifier active = container.read(
        activePersonaProvider.notifier,
      );
      await active.setActivePersona('p1', latch: false);

      await active.setMode(PersonaMode.last);
      await settle();

      expect(container.read(activePersonaProvider).mode, PersonaMode.last);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('persona_active_mode'), 'last');
      expect(lastPatchBody(), <String, Object?>{'active_persona_mode': 'last'});
      expect(api.calls, hasLength(2), reason: 'one save per change');
    });

    test('a new mode with nobody selected latches nothing', () async {
      await loadSettings();
      await container
          .read(activePersonaProvider.notifier)
          .setMode(PersonaMode.last);

      expect(container.read(activePersonaProvider).isLatched, isFalse);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('persona_is_latched'), isFalse);
    });

    test('selecting nobody forgets the saved persona', () async {
      await loadSettings();
      final ActivePersonaNotifier active = container.read(
        activePersonaProvider.notifier,
      );
      await active.setActivePersona('p1');

      await active.setActivePersona(null);
      await settle();

      final ActivePersonaState state = container.read(activePersonaProvider);
      expect(state.activePersonaId, isNull);
      expect(state.isLatched, isFalse);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('persona_active_id'), isFalse);
      expect(prefs.getBool('persona_is_latched'), isFalse);
      expect(api.calls, hasLength(2), reason: 'one save per change');
      expect(lastPatchBody(), <String, Object?>{
        'active_persona_mode': 'manual',
        'active_persona_id': null,
        'is_latched': false,
      });
    });

    test('reset forgets the selection on the device too', () async {
      container = containerWith(
        prefs: <String, Object>{
          'persona_active_mode': 'last',
          'persona_active_id': 'p1',
          'persona_is_latched': true,
          'persona_frecency_map': '{}',
        },
      );
      await waitUntil(
        () => container.read(activePersonaProvider).activePersonaId == 'p1',
        'the saved selection',
      );

      await container.read(activePersonaProvider.notifier).reset();

      final ActivePersonaState state = container.read(activePersonaProvider);
      expect(state.activePersonaId, isNull);
      expect(state.mode, PersonaMode.manual);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
      expect(api.calls, isEmpty);
    });
  });

  group('the display tag', () {
    test(
      'shows the one saved on the device until the server answers',
      () async {
        container = containerWith(
          prefs: <String, Object>{
            'system_display_tag_text': 'SYS',
            'system_display_tag_icon': 'icon-hash',
          },
        );

        await waitUntil(
          () => container.read(systemDisplayTagProvider).isNotEmpty,
          'the saved display tag',
        );

        expect(container.read(systemDisplayTagProvider).text, 'SYS');
        expect(container.read(systemDisplayTagProvider).iconUrl, 'icon-hash');
      },
    );

    test('a new tag is saved on the device and sent once', () async {
      await loadSettings();
      await container
          .read(systemDisplayTagProvider.notifier)
          .updateDisplayTag('SYS', 'icon-hash');

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('system_display_tag_text'), 'SYS');
      expect(prefs.getString('system_display_tag_icon'), 'icon-hash');
      expect(api.calls, <String>[
        'PATCH $_settings {"display_tag_text":"SYS","display_tag_icon":"icon-hash"}',
      ]);
    });

    test(
      'clearing the tag clears it on the device and sends it blank',
      () async {
        api.answers[_settings] = const _Answer(200, <String, Object?>{
          'display_tag_text': 'SYS',
          'display_tag_icon': 'icon-hash',
        });
        await loadSettings();
        expect(container.read(systemDisplayTagProvider).text, 'SYS');

        await container
            .read(systemDisplayTagProvider.notifier)
            .updateDisplayTag(null, null);

        // The server's blank answer is what stays on the device.
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('system_display_tag_text') ?? '', isEmpty);
        expect(prefs.containsKey('system_display_tag_icon'), isFalse);
        expect(container.read(systemDisplayTagProvider).isEmpty, isTrue);
        expect(api.calls, <String>[
          'PATCH $_settings {"display_tag_text":"","display_tag_icon":null}',
        ]);
      },
    );

    test('reset forgets it on the device', () async {
      container = containerWith(
        prefs: <String, Object>{'system_display_tag_text': 'SYS'},
      );
      await waitUntil(
        () => container.read(systemDisplayTagProvider).isNotEmpty,
        'the saved display tag',
      );

      await container.read(systemDisplayTagProvider.notifier).reset();

      expect(container.read(systemDisplayTagProvider).isEmpty, isTrue);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('system_display_tag_text'), isFalse);
    });
  });

  group('ordering', () {
    test('a name of nothing but decoration is filed as it is', () {
      expect(personaSortName('  ✨✨  '), '✨✨');
    });

    test('the persona used more often comes first', () async {
      api.answers[_list] = _Answer(200, <Object?>[
        _persona('p1', 'Alice'),
        _persona('p2', 'Bao'),
      ]);
      container.read(myPersonasProvider);
      await waitUntil(
        () => container.read(myPersonasProvider).hasValue,
        'the persona list',
      );
      final ActivePersonaNotifier active = container.read(
        activePersonaProvider.notifier,
      );
      await active.recordUsage('p2');
      await active.recordUsage('p2');

      expect(
        <String>[
          for (final Persona p in container.read(rankedPersonasProvider)) p.id,
        ],
        <String>['p2', 'p1'],
      );
    });
  });

  test('the scope names itself on the wire', () {
    expect(PersonaScope.channel.toWire(), 'channel');
    expect(PersonaScope.global.toWire(), 'global');
  });

  test('settings sent by the gateway arrive as they are', () {
    container.read(personaSettingsProvider.notifier).updateFromGateway(
      <String, dynamic>{'active_persona_mode': 'last'},
    );

    expect(
      container.read(personaSettingsProvider).value,
      isA<PersonaSettings>().having(
        (PersonaSettings s) => s.activePersonaMode,
        'mode',
        'last',
      ),
    );
  });
}
