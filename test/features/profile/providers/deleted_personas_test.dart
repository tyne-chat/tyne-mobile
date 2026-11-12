// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: requests for the Personas settings page's Deleted personas section
// (tyne-chat/tyne#610): nothing until asked, one shared load, a failure that
// waits for Retry, one restore at a time, and a refused restore that leaves
// the list as it was.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/providers/deleted_personas.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef _Request = ({String method, String path});

class _Adapter implements HttpClientAdapter {
  int listStatus = 200;
  int restoreStatus = 200;

  /// Holds every answer until completed, when set.
  Completer<void>? gate;
  final List<_Request> requests = <_Request>[];

  static final List<Map<String, Object?>> deleted = <Map<String, Object?>>[
    <String, Object?>{
      'id': 'r',
      'name': 'Riven',
      'deleted_at': '2026-11-11T08:00:00.000Z',
      'use_count': 214,
      'persona_tags': <Object?>[
        <String, Object?>{'prefix': 'r:', 'suffix': null},
      ],
    },
    <String, Object?>{
      'id': 'm',
      'name': 'Mira',
      'deleted_at': '2026-10-30T08:00:00.000Z',
    },
  ];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add((method: options.method, path: options.path));
    await gate?.future;
    final bool restore = options.method == 'POST';
    final int status = restore ? restoreStatus : listStatus;
    final Object body = status != 200
        ? <String, Object?>{'code': 'X', 'message': 'Refused here.'}
        : restore
        ? <String, Object?>{
            'persona': <String, Object?>{
              ...deleted.first,
              'deleted_at': null,
              'persona_tags': <Object?>[],
            },
            'dropped_tags': <Object?>[
              <String, Object?>{'prefix': 'r:', 'suffix': null},
            ],
            'dropped_signature_emojis': <Object?>[
              <String, Object?>{'id': null, 'name': '🌀'},
            ],
          }
        : deleted;
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
  @override
  AsyncValue<List<Persona>> build() =>
      const AsyncValue.data(<Persona>[Persona(id: 'k', name: 'Kai')]);

  @override
  Future<void> reloadSilently() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Adapter adapter;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    adapter = _Adapter();
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
      ..httpClientAdapter = adapter;
    container = ProviderContainer(
      overrides: [
        fluxerDioProvider.overrideWithValue(dio),
        myPersonasProvider.overrideWith(_FakeMyPersonas.new),
      ],
    );
    addTearDown(container.dispose);
    // Keep the auto-disposed state alive, as the section does on screen.
    final ProviderSubscription<DeletedPersonasState> sub = container.listen(
      deletedPersonasProvider,
      (_, _) {},
    );
    addTearDown(sub.close);
  });

  DeletedPersonasNotifier notifier() =>
      container.read(deletedPersonasProvider.notifier);
  DeletedPersonasState state() => container.read(deletedPersonasProvider);

  test('nothing is asked until the list is wanted', () {
    expect(state().status, DeletedPersonasStatus.closed);
    expect(adapter.requests, isEmpty);
  });

  test('two loads at once share one GET', () async {
    await Future.wait(<Future<void>>[notifier().load(), notifier().load()]);

    expect(adapter.requests, <_Request>[
      (method: 'GET', path: '/users/@me/personas/deleted'),
    ]);
    expect(state().status, DeletedPersonasStatus.ready);
    expect(state().personas.map((Persona p) => p.name), <String>[
      'Riven',
      'Mira',
    ]);
    expect(state().personas.first.useCount, 214);
  });

  test('a failed load waits for Retry, which asks once more', () async {
    adapter.listStatus = 500;
    await notifier().load();

    expect(state().status, DeletedPersonasStatus.failed);
    expect(adapter.requests, hasLength(1));

    adapter.listStatus = 200;
    await notifier().load();
    expect(adapter.requests, hasLength(2));
    expect(state().status, DeletedPersonasStatus.ready);
  });

  test(
    'restore sends one POST, shows the persona and says what it lost',
    () async {
      await notifier().load();

      final PersonaRestoreResult? result = await notifier().restore('r');

      expect(adapter.requests.last, (
        method: 'POST',
        path: '/users/@me/personas/deleted/r/restore',
      ));
      expect(adapter.requests, hasLength(2));
      expect(result!.name, 'Riven');
      expect(result.droppedTags.single.prefix, 'r:');
      expect(result.droppedSignatureEmojis, <String>['🌀']);
      expect(state().personas.map((Persona p) => p.id), <String>['m']);
      expect(state().restoringId, isNull);
      expect(
        container.read(myPersonasProvider).value!.map((Persona p) => p.id),
        <String>['k', 'r'],
      );
    },
  );

  test('a second restore while one runs sends nothing', () async {
    await notifier().load();
    adapter.gate = Completer<void>();

    final Future<PersonaRestoreResult?> first = notifier().restore('r');
    expect(state().restoringId, 'r');
    expect(await notifier().restore('m'), isNull);
    expect(await notifier().restore('r'), isNull);

    adapter.gate!.complete();
    await first;
    expect(
      adapter.requests.where((_Request r) => r.method == 'POST'),
      hasLength(1),
    );
  });

  test(
    'a refused restore leaves the list as it was and is not retried',
    () async {
      await notifier().load();
      adapter.restoreStatus = 403;

      await expectLater(notifier().restore('r'), throwsA(isA<DioException>()));

      expect(adapter.requests, hasLength(2));
      expect(state().personas.map((Persona p) => p.id), <String>['r', 'm']);
      expect(state().restoringId, isNull);
      expect(
        container.read(myPersonasProvider).value!.map((Persona p) => p.id),
        <String>['k'],
      );
    },
  );

  test('personas deleted here join a list that is showing', () async {
    notifier().personasDeleted(<Persona>[const Persona(id: 'x', name: 'X')]);
    expect(state().personas, isEmpty);

    await notifier().load();
    notifier().personasDeleted(<Persona>[
      const Persona(id: 'k', name: 'Kai', useCount: 3),
    ]);

    expect(state().personas.map((Persona p) => p.id), <String>['k', 'r', 'm']);
    expect(state().personas.first.isDeleted, isTrue);
    expect(state().personas.first.useCount, 3);
    expect(adapter.requests, hasLength(1));
  });
}
