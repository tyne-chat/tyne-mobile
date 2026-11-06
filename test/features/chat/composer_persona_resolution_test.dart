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
import 'package:shared_preferences/shared_preferences.dart';

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

    expect(res.text, 'bao');
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

      expect(res.text, 'test');
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

    expect(res.text, 'test');
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

    expect(res.text, 'hello from Alice');
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

      expect(res.text, 'hello');
      expect(res.personaData?['id'], bob.id);
      await tester.pumpAndSettle();
    },
  );
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
