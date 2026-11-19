// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: who gets many personas in mention suggestions, changed at once
// (tyne-chat/tyne#652): one request for N personas, nothing when nothing
// would change, null ("follows visibility") sent and restored like any
// value, and Undo in one request.

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
    final Object body = status == 200
        ? <Object?>[
            for (final Map<String, String?> entry
                in ((options.data as Map<String, dynamic>)['personas']
                        as List<dynamic>)
                    .cast<Map<String, String?>>())
              <String, Object?>{
                'id': entry['id'],
                'name': 'x',
                'mentionable_by': entry['mentionable_by'],
              },
          ]
        : <String, Object?>{'code': 'UNKNOWN_PERSONA'};
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: <String, List<String>>{
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
  Persona(id: 'a', name: 'Ash', bio: 'kept'),
  Persona(id: 'b', name: 'Bea', mentionableBy: 'self'),
  Persona(id: 'c', name: 'Cleo', mentionableBy: 'nobody'),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingAdapter adapter;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    adapter = _RecordingAdapter();
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
      ..httpClientAdapter = adapter;
    container = ProviderContainer(
      overrides: [
        fluxerDioProvider.overrideWithValue(dio),
        myPersonasProvider.overrideWith(() => _FakeMyPersonas(_personas)),
      ],
    );
    addTearDown(container.dispose);
  });

  Map<String, String?> stored() => <String, String?>{
    for (final Persona p in container.read(myPersonasProvider).value!)
      p.id: p.mentionableBy,
  };

  test(
    'one PATCH for every persona that changes, and Undo puts each back',
    () async {
      final PersonaBulkActions actions = container.read(
        personaBulkActionsProvider,
      );
      final PersonaMentionableByChange? change = await actions.setMentionableBy(
        <String>['a', 'b', 'c'],
        'nobody',
      );

      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.single.method, 'PATCH');
      expect(adapter.requests.single.path, '/users/@me/personas/mentions');
      expect(adapter.requests.single.data, <String, Object?>{
        'personas': <Map<String, String?>>[
          <String, String?>{'id': 'a', 'mentionable_by': 'nobody'},
          <String, String?>{'id': 'b', 'mentionable_by': 'nobody'},
        ],
      });
      expect(change!.count, 2);
      expect(stored(), <String, String?>{
        'a': 'nobody',
        'b': 'nobody',
        'c': 'nobody',
      });
      // The rest of each persona stays as it was.
      expect(container.read(myPersonasProvider).value!.first.bio, 'kept');

      await actions.undoMentionableBy(change);
      expect(adapter.requests, hasLength(2));
      expect(adapter.requests.last.data, <String, Object?>{
        'personas': <Map<String, String?>>[
          <String, String?>{'id': 'a', 'mentionable_by': null},
          <String, String?>{'id': 'b', 'mentionable_by': 'self'},
        ],
      });
      expect(stored(), <String, String?>{
        'a': null,
        'b': 'self',
        'c': 'nobody',
      });
    },
  );

  test('sends null to make personas follow their visibility again', () async {
    await container.read(personaBulkActionsProvider).setMentionableBy(<String>[
      'a',
      'b',
    ], null);

    expect(adapter.requests.single.data, <String, Object?>{
      'personas': <Map<String, String?>>[
        <String, String?>{'id': 'b', 'mentionable_by': null},
      ],
    });
    expect(stored()['b'], isNull);
  });

  test('nothing is sent when no persona would change', () async {
    final PersonaMentionableByChange? change = await container
        .read(personaBulkActionsProvider)
        .setMentionableBy(<String>['c'], 'nobody');

    expect(change, isNull);
    expect(adapter.requests, isEmpty);
  });

  test(
    'a refused change throws, is not retried and changes nothing here',
    () async {
      adapter.status = 404;

      await expectLater(
        container.read(personaBulkActionsProvider).setMentionableBy(<String>[
          'a',
        ], 'nobody'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.requests, hasLength(1));
      expect(stored()['a'], isNull);
    },
  );
}
