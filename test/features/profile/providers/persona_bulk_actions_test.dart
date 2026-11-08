// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: requests for changing or deleting many personas at once
// (tyne-chat/tyne#542): one request for N personas, nothing when nothing
// would change, Undo in one request, and deleted personas dropped here at
// once, selections included, without asking the server to clear them.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/providers/persona_bulk_actions.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef _Request = ({String method, String path, Object? data});

class _RecordingAdapter implements HttpClientAdapter {
  int status = 200;
  final List<_Request> requests = <_Request>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add((
      method: options.method,
      path: options.path,
      data: options.data,
    ));
    final Object? body = options.method == 'PATCH' && status == 200
        ? <Object?>[
            for (final Map<String, String> entry
                in ((options.data as Map<String, dynamic>)['personas']
                        as List<dynamic>)
                    .cast<Map<String, String>>())
              <String, Object?>{
                'id': entry['id'],
                'name': 'x',
                'visibility': entry['visibility'],
              },
          ]
        : null;
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status == 200 && options.method == 'POST' ? 204 : status,
      headers: <String, List<String>>{
        if (body != null)
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeMyPersonas extends MyPersonasNotifier {
  _FakeMyPersonas(this._personas);
  final List<Persona> _personas;

  @override
  AsyncValue<List<Persona>> build() => AsyncValue.data(_personas);

  @override
  Future<void> reloadSilently() async {}
}

const List<Persona> _personas = <Persona>[
  Persona(id: 'a', name: 'Ash', visibility: 'public', bio: 'kept'),
  Persona(id: 'b', name: 'Bea'),
  Persona(id: 'c', name: 'Cleo', visibility: 'private'),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingAdapter adapter;
  late ProviderContainer container;

  ProviderContainer makeContainer(List<Persona> personas) {
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
      ..httpClientAdapter = adapter;
    final ProviderContainer c = ProviderContainer(
      overrides: [
        fluxerDioProvider.overrideWithValue(dio),
        myPersonasProvider.overrideWith(() => _FakeMyPersonas(personas)),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Map<String, String> visibilities() => <String, String>{
    for (final Persona p in container.read(myPersonasProvider).value!)
      p.id: p.visibility,
  };

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    adapter = _RecordingAdapter();
    container = makeContainer(_personas);
  });

  test(
    'one PATCH for every persona that changes, none for the others',
    () async {
      final PersonaVisibilityChange? change = await container
          .read(personaBulkActionsProvider)
          .setVisibility(<String>['a', 'b', 'c'], 'public');

      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.single.method, 'PATCH');
      expect(adapter.requests.single.path, '/users/@me/personas/visibility');
      expect(adapter.requests.single.data, <String, Object?>{
        'personas': <Map<String, String>>[
          <String, String>{'id': 'b', 'visibility': 'public'},
          <String, String>{'id': 'c', 'visibility': 'public'},
        ],
      });
      expect(change!.count, 2);
      expect(change.previous, <String, String>{
        'b': 'unlisted',
        'c': 'private',
      });
      expect(visibilities(), <String, String>{
        'a': 'public',
        'b': 'public',
        'c': 'public',
      });
      // The rest of each persona stays as it was.
      expect(container.read(myPersonasProvider).value!.first.bio, 'kept');
    },
  );

  test('nothing is sent when no persona would change', () async {
    final PersonaVisibilityChange? change = await container
        .read(personaBulkActionsProvider)
        .setVisibility(<String>['a'], 'public');

    expect(change, isNull);
    expect(adapter.requests, isEmpty);
  });

  test("Undo is one PATCH with each persona's previous visibility", () async {
    final PersonaBulkActions actions = container.read(
      personaBulkActionsProvider,
    );
    final PersonaVisibilityChange? change = await actions.setVisibility(
      <String>['b', 'c'],
      'public',
    );

    await actions.undo(change!);

    expect(adapter.requests, hasLength(2));
    expect(adapter.requests.last.data, <String, Object?>{
      'personas': <Map<String, String>>[
        <String, String>{'id': 'b', 'visibility': 'unlisted'},
        <String, String>{'id': 'c', 'visibility': 'private'},
      ],
    });
    expect(visibilities(), <String, String>{
      'a': 'public',
      'b': 'unlisted',
      'c': 'private',
    });
  });

  test('a failure changes nothing here and is the caller to show', () async {
    adapter.status = 500;

    await expectLater(
      container.read(personaBulkActionsProvider).setVisibility(<String>[
        'b',
      ], 'public'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.requests, hasLength(1));
    expect(visibilities()['b'], 'unlisted');
  });

  test('more than 250 personas go in one request per 250', () async {
    adapter = _RecordingAdapter();
    container = makeContainer(<Persona>[
      for (int i = 0; i < 300; i++) Persona(id: 'p$i', name: 'P$i'),
    ]);

    await container.read(personaBulkActionsProvider).setVisibility(<String>[
      for (int i = 0; i < 300; i++) 'p$i',
    ], 'public');

    expect(adapter.requests, hasLength(2));
    expect(
      ((adapter.requests.first.data! as Map<String, dynamic>)['personas']
              as List<dynamic>)
          .length,
      kPersonaBulkLimit,
    );
  });

  test(
    'one POST deletes them all, and the selections naming them go here at once',
    () async {
      container.read(activePersonaProvider.notifier)
        ..applyChannelState('chan-1', 'b')
        ..applyChannelState('chan-2', 'a')
        ..syncFromSettings(
          mode: PersonaMode.manual,
          activeId: 'c',
          isLatched: true,
        );

      final int deleted = await container
          .read(personaBulkActionsProvider)
          .delete(<String>['b', 'c', 'gone']);

      expect(deleted, 2);
      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.path, '/users/@me/personas/bulk-delete');
      expect(adapter.requests.single.data, <String, Object?>{
        'persona_ids': <String>['b', 'c'],
      });
      expect(visibilities().keys, <String>['a']);
      final ActivePersonaState state = container.read(activePersonaProvider);
      expect(state.activePersonaId, isNull);
      expect(state.channelPersonaIds, <String, String>{'chan-2': 'a'});
    },
  );

  test("deleting none of the account's personas sends nothing", () async {
    expect(
      await container.read(personaBulkActionsProvider).delete(<String>['zz']),
      0,
    );
    expect(adapter.requests, isEmpty);
  });
}
