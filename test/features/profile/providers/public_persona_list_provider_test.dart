// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: requests for an account's public persona list, the "Personas (N)"
// gallery's data (tyne-chat/tyne#189). The server signs a session out over a
// burst of requests (tyne-chat/tyne#114), so these count them: one per
// profile opened, shared by everything that shows it, a failure not asked
// again by itself, and a change event dropping the list once.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/features/profile/data/persona_refresh.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/providers/persona_gateway_events.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/features/profile/providers/public_persona_list_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fork_support/wait_until.dart';

const String _userId = '111';

/// Answers every request with [status] and [body], and records the paths.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({this.status = 200, Object? body})
    : body = body ?? _listBody(2);

  int status;
  Object body;
  final List<String> requestedPaths = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestedPaths.add(options.path);
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

Map<String, Object?> _listBody(int count) => <String, Object?>{
  'display_tag_text': ' System ',
  'display_tag_icon': '0123abcd',
  'personas': <Map<String, Object?>>[
    for (int i = 0; i < count; i++)
      <String, Object?>{
        'id': '${900 + i}',
        'name': 'Persona $i',
        'visibility': 'public',
      },
  ],
};

ProviderContainer _container(
  _RecordingAdapter adapter, {
  Duration keepAlive = const Duration(seconds: 60),
  Duration refreshDelay = const Duration(milliseconds: 10),
}) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
    ..httpClientAdapter = adapter;
  return ProviderContainer(
    overrides: [
      fluxerDioProvider.overrideWithValue(dio),
      publicPersonaListKeepAliveProvider.overrideWithValue(keepAlive),
      personaRefreshDelayProvider.overrideWithValue(refreshDelay),
    ],
  );
}

class _FakeMyPersonas extends MyPersonasNotifier {
  _FakeMyPersonas(this._personas);
  final List<Persona> _personas;

  @override
  AsyncValue<List<Persona>> build() => AsyncValue.data(_personas);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('publicPersonaListProvider', () {
    test('reads the personas in order and the trimmed display tag', () async {
      final _RecordingAdapter adapter = _RecordingAdapter();
      final ProviderContainer container = _container(adapter);
      addTearDown(container.dispose);

      final PublicPersonaListResult result = await container.read(
        publicPersonaListProvider(_userId).future,
      );

      expect(adapter.requestedPaths, <String>['/users/$_userId/personas']);
      final PublicPersonaList list = (result as PublicPersonaListLoaded).list;
      expect(
        <String>[for (final p in list.personas) p.name],
        <String>['Persona 0', 'Persona 1'],
      );
      expect(list.displayTagText, 'System');
      expect(list.displayTagIcon, '0123abcd');
    });

    test('one request however many things show the list at once', () async {
      final _RecordingAdapter adapter = _RecordingAdapter();
      final ProviderContainer container = _container(adapter);
      addTearDown(container.dispose);

      // The pill, the row and the gallery, plus the summary they read.
      for (int i = 0; i < 3; i++) {
        container.listen(publicPersonaListProvider(_userId), (_, _) {});
      }
      container.listen(
        personaGallerySummaryProvider((userId: _userId, isSelf: false)),
        (_, _) {},
      );
      await container.read(publicPersonaListProvider(_userId).future);
      // A rebuild of the profile reads it again.
      await container.read(publicPersonaListProvider(_userId).future);

      expect(adapter.requestedPaths, hasLength(1));
    });

    test('a failure is not asked again until Retry, then once more', () async {
      final _RecordingAdapter adapter = _RecordingAdapter(status: 500);
      final ProviderContainer container = _container(adapter);
      addTearDown(container.dispose);
      container.listen(publicPersonaListProvider(_userId), (_, _) {});

      final PublicPersonaListResult failed = await container.read(
        publicPersonaListProvider(_userId).future,
      );
      expect(failed, isA<PublicPersonaListFailed>());

      // Rebuilds and other places watching do not ask again.
      container.listen(publicPersonaListProvider(_userId), (_, _) {});
      await container.read(publicPersonaListProvider(_userId).future);
      await Future<void>.delayed(Duration.zero);
      expect(adapter.requestedPaths, hasLength(1));
      expect(
        container.read(
          personaGallerySummaryProvider((userId: _userId, isSelf: false)),
        ),
        isA<PersonaGallerySummary>()
            .having((s) => s.failed, 'failed', isTrue)
            .having((s) => s.visible, 'visible', isFalse),
      );

      // Retry.
      adapter.status = 200;
      container.invalidate(publicPersonaListProvider(_userId));
      final PublicPersonaListResult loaded = await container.read(
        publicPersonaListProvider(_userId).future,
      );
      expect(loaded, isA<PublicPersonaListLoaded>());
      expect(adapter.requestedPaths, hasLength(2));
    });

    test('a 403 hides the personas, without an error', () async {
      final _RecordingAdapter adapter = _RecordingAdapter(
        status: 403,
        body: <String, Object?>{'code': 'MISSING_ACCESS'},
      );
      final ProviderContainer container = _container(adapter);
      addTearDown(container.dispose);
      container.listen(publicPersonaListProvider(_userId), (_, _) {});

      expect(
        await container.read(publicPersonaListProvider(_userId).future),
        isA<PublicPersonaListForbidden>(),
      );
      final PersonaGallerySummary summary = container.read(
        personaGallerySummaryProvider((userId: _userId, isSelf: false)),
      );
      expect(summary.visible, isFalse);
      expect(summary.failed, isFalse);
      expect(summary.displayTagText, isNull);
    });

    test('kept a minute after the last listener, then asked again', () {
      fakeAsync((FakeAsync async) {
        final _RecordingAdapter adapter = _RecordingAdapter();
        final ProviderContainer container = _container(adapter);

        ProviderSubscription<Object?> show() =>
            container.listen(publicPersonaListProvider(_userId), (_, _) {});

        show().close();
        async.elapse(const Duration(seconds: 59));
        // Back within the minute: the same answer.
        show().close();
        async.elapse(const Duration(seconds: 59));
        expect(adapter.requestedPaths, hasLength(1));

        async.elapse(const Duration(seconds: 2));
        show();
        async.elapse(const Duration(milliseconds: 1));
        expect(adapter.requestedPaths, hasLength(2));

        container.dispose();
        async.flushTimers();
      });
    });

    test('a failure is dropped with its last listener', () {
      fakeAsync((FakeAsync async) {
        final _RecordingAdapter adapter = _RecordingAdapter(status: 500);
        final ProviderContainer container = _container(adapter);

        container.listen(publicPersonaListProvider(_userId), (_, _) {}).close();
        async.elapse(const Duration(milliseconds: 1));
        // The next profile opened asks again rather than show a failure.
        container.listen(publicPersonaListProvider(_userId), (_, _) {});
        async.elapse(const Duration(milliseconds: 1));
        expect(adapter.requestedPaths, hasLength(2));

        container.dispose();
        async.flushTimers();
      });
    });
  });

  group('when the personas change', () {
    test('a burst of change events drops a shown list once', () {
      fakeAsync((FakeAsync async) {
        final _RecordingAdapter adapter = _RecordingAdapter();
        final ProviderContainer container = _container(adapter)
          ..listen(publicPersonaListProvider(_userId), (_, _) {});
        async.elapse(const Duration(milliseconds: 1));
        expect(adapter.requestedPaths, hasLength(1));

        // One copy per shared community, at the same moment.
        final PublicPersonaListRefresher refresher = container.read(
          publicPersonaListRefresherProvider,
        );
        for (int i = 0; i < 20; i++) {
          refresher.request(_userId);
        }
        async.elapse(const Duration(milliseconds: 50));

        expect(adapter.requestedPaths, hasLength(2));
        container.dispose();
        async.flushTimers();
      });
    });

    test('a list nothing shows is fetched again only when shown', () {
      fakeAsync((FakeAsync async) {
        final _RecordingAdapter adapter = _RecordingAdapter();
        final ProviderContainer container = _container(adapter);
        container.listen(publicPersonaListProvider(_userId), (_, _) {}).close();
        async.elapse(const Duration(seconds: 1));
        expect(adapter.requestedPaths, hasLength(1));

        container.read(publicPersonaListRefresherProvider).request(_userId);
        async.elapse(const Duration(seconds: 1));
        expect(adapter.requestedPaths, hasLength(1));

        container.listen(publicPersonaListProvider(_userId), (_, _) {});
        async.elapse(const Duration(milliseconds: 1));
        expect(adapter.requestedPaths, hasLength(2));
        container.dispose();
        async.flushTimers();
      });
    });

    test('GUILD_PERSONAS_DIRTY reaches the refresher, deletes too', () async {
      final _RecordingAdapter adapter = _RecordingAdapter();
      final ProviderContainer container = _container(adapter);
      addTearDown(container.dispose);
      container.listen(publicPersonaListProvider(_userId), (_, _) {});
      await container.read(publicPersonaListProvider(_userId).future);

      container.read(
        Provider<void>(
          (Ref ref) => handlePersonaGatewayEvent(
            ref,
            'GUILD_PERSONAS_DIRTY',
            <String, Object?>{
              'action': 'delete',
              'user_id': _userId,
              'persona_id': '900',
            },
          ),
        ),
      );

      await waitUntil(
        () => adapter.requestedPaths.length == 2,
        'the list to be fetched again',
      );
    });
  });

  group('personaGallerySummaryProvider', () {
    test('someone else with public personas shows the count and tag', () async {
      final ProviderContainer container = _container(_RecordingAdapter());
      addTearDown(container.dispose);
      container.listen(
        personaGallerySummaryProvider((userId: _userId, isSelf: false)),
        (_, _) {},
      );
      // Nothing shows while the list loads.
      expect(
        container
            .read(
              personaGallerySummaryProvider((userId: _userId, isSelf: false)),
            )
            .visible,
        isFalse,
      );
      await container.read(publicPersonaListProvider(_userId).future);

      final PersonaGallerySummary summary = container.read(
        personaGallerySummaryProvider((userId: _userId, isSelf: false)),
      );
      expect(summary.visible, isTrue);
      expect(summary.count, 2);
      expect(summary.displayTagText, 'System');
    });

    test('someone else without public personas shows none', () async {
      final ProviderContainer container = _container(
        _RecordingAdapter(body: _listBody(0)),
      );
      addTearDown(container.dispose);
      container.listen(
        personaGallerySummaryProvider((userId: _userId, isSelf: false)),
        (_, _) {},
      );
      await container.read(publicPersonaListProvider(_userId).future);

      final PersonaGallerySummary summary = container.read(
        personaGallerySummaryProvider((userId: _userId, isSelf: false)),
      );
      expect(summary.visible, isFalse);
      // The display tag still shows after the account's name.
      expect(summary.displayTagText, 'System');
    });

    test('your own shows always, counts only public ones, asks nothing', () {
      final _RecordingAdapter adapter = _RecordingAdapter();
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
        ..httpClientAdapter = adapter;
      final ProviderContainer container = ProviderContainer(
        overrides: [
          fluxerDioProvider.overrideWithValue(dio),
          myPersonasProvider.overrideWith(
            () => _FakeMyPersonas(const <Persona>[
              Persona(id: '1', name: 'Unlisted'),
              Persona(id: '2', name: 'Private', visibility: 'private'),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      PersonaGallerySummary summary = container.read(
        personaGallerySummaryProvider((userId: _userId, isSelf: true)),
      );
      expect(summary.visible, isTrue);
      expect(summary.count, 0);

      container
          .read(myPersonasProvider.notifier)
          .upsertPersona(
            const Persona(id: '3', name: 'Out', visibility: 'public'),
          );
      summary = container.read(
        personaGallerySummaryProvider((userId: _userId, isSelf: true)),
      );
      expect(summary.count, 1);
      expect(adapter.requestedPaths, isEmpty);
    });
  });
}
