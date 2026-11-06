// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/features/chat/utils/composer/composer_persona_resolution.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/features/ui/toast/fluxer_toast.dart';
import 'package:fluxer_app/features/ui/toast/toast_provider.dart';
import 'package:fluxer_dart/fluxer_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/open_test_database.dart';

class _MockDioAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _createMockDio() {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.fluxer.invalid'))
    ..httpClientAdapter = _MockDioAdapter();
  return dio;
}

class _FakeMyPersonasNotifier extends MyPersonasNotifier {
  _FakeMyPersonasNotifier(this._initial);
  final List<Persona> _initial;

  @override
  AsyncValue<List<Persona>> build() => AsyncValue.data(_initial);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const bob = Persona(
    id: 'persona_bob',
    name: 'Bob the Fox',
    personaTags: [PersonaTag(prefix: 'B:')],
  );

  const alice = Persona(
    id: 'persona_alice',
    name: 'Alice',
    personaTags: [PersonaTag(prefix: 'A:')],
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('sends as latched persona for normal text', (tester) async {
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fluxerDioProvider.overrideWithValue(_createMockDio()),
          myPersonasProvider.overrideWith(
            () => _FakeMyPersonasNotifier([bob, alice]),
          ),
          activePersonaProvider.overrideWith(ActivePersonaNotifier.new),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Latch Bob in manual mode
    await capturedRef
        .read(activePersonaProvider.notifier)
        .setActivePersona(bob.id, mode: PersonaMode.manual);

    final res = await resolveOutgoingPersona(
      ref: capturedRef,
      rawText: 'bao',
      channelId: 'test_channel',
    );

    expect(res!.text, 'bao');
    expect(res.personaData, isNotNull);
    expect(res.personaData!['id'], bob.id);
    expect(res.wasEscaped, isFalse);
    expect(capturedRef.read(activePersonaProvider).isLatched, isTrue);
    await tester.pumpAndSettle();
  });

  testWidgets(
    'escapes to root account with single backslash while preserving latch in manual mode',
    (tester) async {
      late WidgetRef capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fluxerDioProvider.overrideWithValue(_createMockDio()),
            myPersonasProvider.overrideWith(
              () => _FakeMyPersonasNotifier([bob, alice]),
            ),
            activePersonaProvider.overrideWith(ActivePersonaNotifier.new),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              capturedRef = ref;
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Latch Bob in manual mode
      await capturedRef
          .read(activePersonaProvider.notifier)
          .setActivePersona(bob.id, mode: PersonaMode.manual);

      final res = await resolveOutgoingPersona(
        ref: capturedRef,
        rawText: r'\test',
        channelId: 'test_channel',
      );

      expect(res!.text, 'test');
      expect(res.personaData, isNull);
      expect(res.wasEscaped, isTrue);
      expect(res.clearedLatch, isFalse);
      // Bob should still be latched for subsequent messages
      expect(capturedRef.read(activePersonaProvider).isLatched, isTrue);
      expect(capturedRef.read(activePersonaProvider).activePersonaId, bob.id);
      await tester.pumpAndSettle();
    },
  );

  testWidgets('escapes to root account with double backslash and unlatches', (
    tester,
  ) async {
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fluxerDioProvider.overrideWithValue(_createMockDio()),
          myPersonasProvider.overrideWith(
            () => _FakeMyPersonasNotifier([bob, alice]),
          ),
          activePersonaProvider.overrideWith(ActivePersonaNotifier.new),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Latch Bob in manual mode
    await capturedRef
        .read(activePersonaProvider.notifier)
        .setActivePersona(bob.id, mode: PersonaMode.manual);

    final res = await resolveOutgoingPersona(
      ref: capturedRef,
      rawText: r'\\test',
      channelId: 'test_channel',
    );

    expect(res!.text, 'test');
    expect(res.personaData, isNull);
    expect(res.wasEscaped, isTrue);
    expect(res.clearedLatch, isTrue);
    // Bob should now be unlatched
    expect(capturedRef.read(activePersonaProvider).isLatched, isFalse);
    expect(capturedRef.read(activePersonaProvider).activePersonaId, isNull);
    await tester.pumpAndSettle();
  });

  testWidgets('matches persona tag over latched persona', (tester) async {
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fluxerDioProvider.overrideWithValue(_createMockDio()),
          myPersonasProvider.overrideWith(
            () => _FakeMyPersonasNotifier([bob, alice]),
          ),
          activePersonaProvider.overrideWith(ActivePersonaNotifier.new),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Latch Bob
    await capturedRef
        .read(activePersonaProvider.notifier)
        .setActivePersona(bob.id, mode: PersonaMode.manual);

    final res = await resolveOutgoingPersona(
      ref: capturedRef,
      rawText: 'A: hello from Alice',
      channelId: 'test_channel',
    );

    expect(res!.text, 'hello from Alice');
    expect(res.personaData, isNotNull);
    expect(res.personaData!['id'], alice.id);
    await tester.pumpAndSettle();
  });

  // tyne-chat/tyne#499: the list reloads on every resume and READY, and a
  // reload the server refused used to empty it, so messages went out as the
  // account until the next reload worked.
  testWidgets(
    'still sends as the latched persona after a reload of the list fails',
    (tester) async {
      final _PersonaListThenRefused api = _PersonaListThenRefused();
      late WidgetRef capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fluxerDioProvider.overrideWithValue(
              Dio(BaseOptions(baseUrl: 'https://test.fluxer.invalid'))
                ..httpClientAdapter = api,
            ),
            activePersonaProvider.overrideWith(ActivePersonaNotifier.new),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              capturedRef = ref;
              ref.watch(myPersonasProvider);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(capturedRef.read(myPersonasProvider).asData?.value, hasLength(1));

      await capturedRef
          .read(activePersonaProvider.notifier)
          .setActivePersona(bob.id, mode: PersonaMode.manual);
      // Not awaited: the request finishes on the test's clock, which only
      // moves when it pumps.
      unawaited(capturedRef.read(myPersonasProvider.notifier).reloadSilently());
      await tester.pumpAndSettle();
      expect(api.listRequests, 2);

      final res = await resolveOutgoingPersona(
        ref: capturedRef,
        rawText: 'hello',
        channelId: 'test_channel',
      );

      expect(res!.text, 'hello');
      expect(res.personaData?['id'], bob.id);
      await tester.pumpAndSettle();
    },
  );

  // tyne-chat/tyne#30: a send before the persona list (or, per channel, the
  // per-channel selections) has loaded waits for it, and is held rather than
  // sent as the account when it cannot load.
  group('before the personas have loaded', () {
    Future<WidgetRef> pumpScope(
      WidgetTester tester,
      _PersonaServer server,
    ) async {
      late WidgetRef captured;
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.fluxer.invalid'))
        ..httpClientAdapter = server;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fluxerDioProvider.overrideWithValue(dio),
            fluxerClientProvider.overrideWithValue(
              FluxerClient(dio, baseUrl: 'https://test.fluxer.invalid'),
            ),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              captured = ref;
              return const SizedBox();
            },
          ),
        ),
      );
      // The device's copy of the selection is read first, as at start-up,
      // where it is long done before the server answers; then the settings
      // say Bob is selected, as the server would.
      captured
        ..read(activePersonaProvider)
        // As at start-up, the list starts loading, and the device's note of
        // whether the account had personas is read, before anything is sent.
        ..read(myPersonasProvider);
      await tester.pumpAndSettle();
      captured.read(personaSettingsProvider);
      await tester.pumpAndSettle();
      return captured;
    }

    /// Lets [pending] finish on the test's clock, which only moves when it
    /// pumps, calling [release] once it is waiting.
    Future<OutgoingMessageResolution?> settle(
      WidgetTester tester,
      Future<OutgoingMessageResolution?> pending, {
      void Function()? release,
    }) async {
      OutgoingMessageResolution? result;
      bool done = false;
      unawaited(
        pending.then((OutgoingMessageResolution? r) {
          result = r;
          done = true;
        }),
      );
      await tester.pump();
      release?.call();
      for (int i = 0; i < 20 && !done; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(done, isTrue, reason: 'the send resolved');
      return result;
    }

    testWidgets('waits for a list still loading, then sends as the persona', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'persona_list_had_personas': true,
      });
      final _PersonaServer server = _PersonaServer()
        ..holdList = Completer<void>();
      final WidgetRef ref = await pumpScope(tester, server);

      final OutgoingMessageResolution? res = await settle(
        tester,
        resolveOutgoingPersona(
          ref: ref,
          rawText: 'hello',
          channelId: 'test_channel',
        ),
        release: () => server.holdList!.complete(),
      );

      expect(res?.personaData?['id'], bob.id);
      expect(server.listRequests, 1);
    });

    testWidgets(
      'holds the message when the list cannot load and the account had '
      'personas, and "Send as" sends it once as the account',
      (tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'persona_list_had_personas': true,
        });
        final _PersonaServer server = _PersonaServer()..listStatus = 429;
        final WidgetRef ref = await pumpScope(tester, server);
        int sentAgain = 0;

        final OutgoingMessageResolution? held = await settle(
          tester,
          resolveOutgoingPersona(
            ref: ref,
            rawText: 'B: hello',
            channelId: 'test_channel',
            onSendAsAccount: () => sentAgain++,
          ),
        );
        expect(held, isNull);
        final FluxerToastAction action = ref
            .read(toastProvider)
            .last
            .toast
            .action!;
        expect(action.label, startsWith('Send as @'));

        action.onPressed();
        expect(sentAgain, 1);
        final OutgoingMessageResolution? again = await settle(
          tester,
          resolveOutgoingPersona(
            ref: ref,
            rawText: 'B: hello',
            channelId: 'test_channel',
          ),
        );
        expect(again?.personaData, isNull);
        expect(again?.text, 'B: hello');

        final OutgoingMessageResolution? next = await settle(
          tester,
          resolveOutgoingPersona(
            ref: ref,
            rawText: 'B: hello',
            channelId: 'test_channel',
          ),
        );
        expect(next, isNull, reason: '"Send as" covers one send only');
        expect(server.listRequests, 1);
        // Let the toasts' replace, dismiss and removal timers run out, and
        // the user settings the action's label read close their database
        // stream while the test can still run its timers.
        await tester.pump(const Duration(seconds: 10));
        await tester.pump(const Duration(seconds: 10));
        await releaseTestWidgetTree(tester);
      },
    );

    testWidgets(
      'sends as the account, as before, when the account never had personas',
      (tester) async {
        final _PersonaServer server = _PersonaServer()..listStatus = 429;
        final WidgetRef ref = await pumpScope(tester, server);

        final OutgoingMessageResolution? res = await settle(
          tester,
          resolveOutgoingPersona(
            ref: ref,
            rawText: 'hello',
            channelId: 'test_channel',
          ),
        );

        expect(res, isNotNull);
        expect(res?.personaData, isNull);
        expect(ref.read(toastProvider), isEmpty);
      },
    );

    testWidgets('a backslash sends as the account without waiting', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'persona_list_had_personas': true,
      });
      final _PersonaServer server = _PersonaServer()
        ..holdList = Completer<void>();
      final WidgetRef ref = await pumpScope(tester, server);

      final OutgoingMessageResolution? res = await settle(
        tester,
        resolveOutgoingPersona(
          ref: ref,
          rawText: r'\ just me',
          channelId: 'test_channel',
        ),
      );

      expect(res?.text, 'just me');
      expect(res?.personaData, isNull);
      expect(res?.wasEscaped, isTrue);
      server.holdList!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets(
      'with personas chosen per channel, waits for the channel selections',
      (tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'persona_list_had_personas': true,
        });
        final _PersonaServer server = _PersonaServer()
          ..scope = 'channel'
          ..channelStates = <String, String>{'test_channel': bob.id}
          ..holdChannelStates = Completer<void>();
        final WidgetRef ref = await pumpScope(tester, server);

        final OutgoingMessageResolution? res = await settle(
          tester,
          resolveOutgoingPersona(
            ref: ref,
            rawText: 'hello',
            channelId: 'test_channel',
          ),
          release: () => server.holdChannelStates!.complete(),
        );

        expect(res?.personaData?['id'], bob.id);
        expect(server.channelStateRequests, 1);
      },
    );
  });
}

/// Answers the first request for the persona list with Bob, refuses every
/// later one with a 429, says Bob is selected when asked for the settings, and
/// answers anything else with an empty object.
class _PersonaListThenRefused implements HttpClientAdapter {
  int listRequests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final Map<String, List<String>> json = {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    };
    if (options.method == 'GET' && options.uri.path == '/users/@me/personas') {
      listRequests++;
      if (listRequests > 1) {
        return ResponseBody.fromString(
          '{"code":"RATE_LIMITED","message":"Slow down","retry_after":1}',
          429,
          headers: json,
        );
      }
      return ResponseBody.fromString(
        jsonEncode(<Object?>[
          <String, Object?>{
            'id': 'persona_bob',
            'name': 'Bob the Fox',
            'persona_tags': <Object?>[
              <String, Object?>{'prefix': 'B:'},
            ],
          },
        ]),
        200,
        headers: json,
      );
    }
    if (options.uri.path == '/users/@me/personas/settings') {
      return ResponseBody.fromString(
        jsonEncode(<String, Object?>{
          'active_persona_mode': 'manual',
          'active_persona_id': 'persona_bob',
          'is_latched': true,
        }),
        200,
        headers: json,
      );
    }
    return ResponseBody.fromString('{}', 200, headers: json);
  }

  @override
  void close({bool force = false}) {}
}

/// The persona routes for the tests before the personas have loaded: Bob in
/// the list (or [listStatus] as the answer), Bob selected in the settings,
/// with the scope [scope], and [channelStates]. A hold delays its route.
class _PersonaServer implements HttpClientAdapter {
  int listRequests = 0;
  int channelStateRequests = 0;
  int listStatus = 200;
  String scope = 'global';
  Map<String, String> channelStates = <String, String>{};
  Completer<void>? holdList;
  Completer<void>? holdChannelStates;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final String path = options.uri.path;
    Object? body = <String, Object?>{};
    int status = 200;
    if (path == '/users/@me/personas' && options.method == 'GET') {
      listRequests++;
      await holdList?.future;
      status = listStatus;
      body = listStatus == 200
          ? <Object?>[
              <String, Object?>{
                'id': 'persona_bob',
                'name': 'Bob the Fox',
                'persona_tags': <Object?>[
                  <String, Object?>{'prefix': 'B:'},
                ],
              },
            ]
          : <String, Object?>{'code': 'RATE_LIMITED', 'message': 'Slow down'};
    } else if (path == '/users/@me/personas/settings') {
      body = <String, Object?>{
        'active_persona_mode': 'manual',
        'active_persona_scope': scope,
        'active_persona_id': 'persona_bob',
        'is_latched': true,
      };
    } else if (path == '/users/@me/personas/channel-states') {
      channelStateRequests++;
      await holdChannelStates?.future;
      body = <String, Object?>{
        'states': <Object?>[
          for (final MapEntry<String, String> e in channelStates.entries)
            <String, Object?>{'channel_id': e.key, 'persona_id': e.value},
        ],
      };
    }
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
