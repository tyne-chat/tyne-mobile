// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: requests for the personas this account blocked (tyne-chat/tyne#921):
// one load, shared, whoever reads the list and however often they rebuild; a
// failed load asked again only at the next READY, never per read; the event
// replacing the list without a request; one request per block or unblock,
// never retried.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/chat/utils/messages/fork_blocked_persona.dart';
import 'package:fluxer_app/features/profile/providers/persona_blocks_provider.dart';
import 'package:fluxer_dart/export.dart';

import '../../../fork_support/wait_until.dart';

class _Adapter implements HttpClientAdapter {
  int status = 200;

  /// Holds every answer until completed, when set.
  Completer<void>? gate;
  Object listBody = <Object?>[
    <String, Object?>{'user_id': 'u2', 'persona_id': 'p1'},
  ];
  final List<String> requests = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add('${options.method} ${options.path}');
    await gate?.future;
    final Object body = status != 200
        ? <String, Object?>{'code': 'X', 'message': 'Refused here.'}
        : listBody;
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

/// What READY and the gateway handler call, from a [Ref].
final Provider<void Function()> _readyProvider = Provider<void Function()>(
  (Ref ref) =>
      () => reloadPersonaBlocksIfLoaded(ref),
);
final Provider<void Function(Object?)> _eventProvider =
    Provider<void Function(Object?)>(
      (Ref ref) =>
          (Object? data) => applyPersonaBlocksEvent(ref, data),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Adapter adapter;
  late ProviderContainer container;

  setUp(() {
    adapter = _Adapter();
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
      ..httpClientAdapter = adapter;
    container = ProviderContainer(
      overrides: [
        fluxerDioProvider.overrideWithValue(dio),
        fluxerClientProvider.overrideWithValue(
          FluxerClient(dio, baseUrl: 'https://example.invalid'),
        ),
        currentUserIdProvider.overrideWithValue('u1'),
      ],
    );
    addTearDown(container.dispose);
  });

  ProviderSubscription<Set<String>> listen() {
    final ProviderSubscription<Set<String>> sub = container.listen(
      blockedPersonaKeysProvider,
      (_, _) {},
    );
    addTearDown(sub.close);
    return sub;
  }

  /// Starts reading the list and waits for the load that starts, joining it
  /// while it runs rather than starting another.
  Future<void> firstLoad() async {
    adapter.gate = Completer<void>();
    listen();
    final Future<void> load = container
        .read(blockedPersonaKeysProvider.notifier)
        .reloadSilently();
    adapter.gate!.complete();
    adapter.gate = null;
    await load;
    expect(adapter.requests.length, 1);
  }

  test('nothing is asked until something reads the list', () {
    container.read(_readyProvider)();
    container.read(_eventProvider)(<String, Object?>{'blocks': <Object?>[]});
    expect(adapter.requests, isEmpty);
    expect(container.read(blockedPersonaKeysProvider.exists), isFalse);
  });

  test(
    'one request, shared by every reader and reload while it runs',
    () async {
      adapter.gate = Completer<void>();
      listen();
      listen();
      final Future<void> again = container
          .read(blockedPersonaKeysProvider.notifier)
          .reloadSilently();
      adapter.gate!.complete();
      await again;
      expect(adapter.requests, <String>['GET /users/@me/personas/blocks']);
      expect(container.read(blockedPersonaKeysProvider), <String>{
        personaBlockKey('u2', 'p1'),
      });
    },
  );

  test(
    'a failed load is not asked again by reads, only by the next READY',
    () async {
      adapter.status = 429;
      await firstLoad();
      // Reads and rebuilds ask nothing more.
      container
        ..read(blockedPersonaKeysProvider)
        ..read(blockedPersonaKeysProvider);
      expect(adapter.requests.length, 1);
      expect(container.read(blockedPersonaKeysProvider), isEmpty);

      adapter.status = 200;
      container.read(_readyProvider)();
      await waitUntil(
        () => container.read(blockedPersonaKeysProvider).isNotEmpty,
        'the load at READY',
      );
      expect(adapter.requests.length, 2);
    },
  );

  test('the event replaces the list without a request', () async {
    await firstLoad();
    container.read(_eventProvider)(<String, Object?>{
      'blocks': <Object?>[
        <String, Object?>{'user_id': 'u3', 'persona_id': 'p9'},
        <String, Object?>{'user_id': '', 'persona_id': 'skipped'},
      ],
    });
    expect(container.read(blockedPersonaKeysProvider), <String>{
      personaBlockKey('u3', 'p9'),
    });
    expect(adapter.requests.length, 1);
  });

  test('a block and an unblock are one request each, and a failure is not '
      'retried', () async {
    await firstLoad();
    final PersonaBlocksNotifier notifier = container.read(
      blockedPersonaKeysProvider.notifier,
    );

    adapter.listBody = <Object?>[
      <String, Object?>{'user_id': 'u2', 'persona_id': 'p1'},
      <String, Object?>{'user_id': 'u2', 'persona_id': 'p2'},
    ];
    await notifier.block('u2', 'p2');
    expect(adapter.requests.last, 'PUT /users/@me/personas/blocks/u2/p2');
    expect(notifier.isBlocked('u2', 'p2'), isTrue);

    adapter.listBody = <Object?>[];
    await notifier.unblock('u2', 'p1');
    expect(adapter.requests.last, 'DELETE /users/@me/personas/blocks/u2/p1');
    expect(container.read(blockedPersonaKeysProvider), isEmpty);

    adapter.status = 404;
    await expectLater(notifier.block('u2', 'p3'), throwsA(anything));
    expect(adapter.requests.length, 4);
    expect(container.read(blockedPersonaKeysProvider), isEmpty);
  });
}
