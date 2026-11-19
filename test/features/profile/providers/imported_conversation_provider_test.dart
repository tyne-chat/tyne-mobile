// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: requests behind the Open DM of a Discord import placeholder's profile
// (tyne-chat/tyne#696). The server signs a session out over a burst of
// requests (tyne-chat/tyne#114), so these count them: one per placeholder,
// shared by everything that shows it, kept once answered, and a failure not
// asked again within a minute of its profile closing.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/profile/providers/imported_conversation_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _userId = '111';

/// Answers every request with [status] and [channelId], and records the paths.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({this.status = 200, this.channelId = '555'});

  int status;
  String? channelId;
  final List<String> requestedPaths = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestedPaths.add(options.path);
    return ResponseBody.fromString(
      jsonEncode(<String, Object?>{'channel_id': channelId}),
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ProviderContainer _container(
  _RecordingAdapter adapter, {
  String? viewer = 'me',
}) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
    ..httpClientAdapter = adapter;
  final ProviderContainer container = ProviderContainer(
    overrides: [
      fluxerDioProvider.overrideWithValue(dio),
      fluxerBaseUrlProvider.overrideWithValue('https://example.invalid'),
    ],
  );
  if (viewer != null) {
    container.read(currentUserIdProvider.notifier).set(viewer);
  }
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('importedConversationProvider', () {
    test('reads the DM id from the server', () async {
      final _RecordingAdapter adapter = _RecordingAdapter();
      final ProviderContainer container = _container(adapter);
      addTearDown(container.dispose);

      final String? channelId = await container.read(
        importedConversationProvider(_userId).future,
      );

      expect(channelId, '555');
      expect(adapter.requestedPaths, <String>[
        '/users/@me/imported-conversations/$_userId',
      ]);
    });

    test('one request however often and wherever the profile shows', () {
      fakeAsync((FakeAsync async) {
        final _RecordingAdapter adapter = _RecordingAdapter(channelId: null);
        final ProviderContainer container = _container(adapter);

        // The footer and the full profile at once, and a rebuild.
        for (int i = 0; i < 3; i++) {
          container.listen(importedConversationProvider(_userId), (_, _) {});
        }
        async.elapse(const Duration(milliseconds: 1));
        expect(adapter.requestedPaths, hasLength(1));

        container.dispose();
        async.flushTimers();
      });
      // Closed and opened again a day later: the answer is kept.
      fakeAsync((FakeAsync async) {
        final _RecordingAdapter adapter = _RecordingAdapter();
        final ProviderContainer container = _container(adapter);

        container
            .listen(importedConversationProvider(_userId), (_, _) {})
            .close();
        async.elapse(const Duration(days: 1));
        container.listen(importedConversationProvider(_userId), (_, _) {});
        async.elapse(const Duration(milliseconds: 1));
        expect(adapter.requestedPaths, hasLength(1));
        expect(
          container.read(importedConversationProvider(_userId)).value,
          '555',
        );

        container.dispose();
        async.flushTimers();
      });
    });

    test('a failure is not asked again within a minute of closing', () {
      fakeAsync((FakeAsync async) {
        final _RecordingAdapter adapter = _RecordingAdapter(status: 429);
        final ProviderContainer container = _container(adapter);

        ProviderSubscription<Object?> show() =>
            container.listen(importedConversationProvider(_userId), (_, _) {});

        show();
        async.elapse(const Duration(milliseconds: 1));
        expect(
          container.read(importedConversationProvider(_userId)).value,
          isNull,
        );
        // Rebuilds and other places showing it do not ask again.
        show().close();
        async.elapse(const Duration(seconds: 59));
        expect(adapter.requestedPaths, hasLength(1));

        container.dispose();
        async.flushTimers();
      });
      fakeAsync((FakeAsync async) {
        final _RecordingAdapter adapter = _RecordingAdapter(status: 429);
        final ProviderContainer container = _container(adapter);

        ProviderSubscription<Object?> show() =>
            container.listen(importedConversationProvider(_userId), (_, _) {});

        show().close();
        async.elapse(const Duration(seconds: 59));
        // Opened again within the minute: still the failure, no request.
        show().close();
        async.elapse(const Duration(seconds: 59));
        expect(adapter.requestedPaths, hasLength(1));

        // A minute after it last closed, the next profile asks once more.
        adapter.status = 200;
        async.elapse(const Duration(seconds: 2));
        show();
        async.elapse(const Duration(milliseconds: 1));
        expect(adapter.requestedPaths, hasLength(2));
        expect(
          container.read(importedConversationProvider(_userId)).value,
          '555',
        );

        container.dispose();
        async.flushTimers();
      });
    });

    // Gemini Carbon's review of tyne-chat/tyne#696.
    test('asks nothing while signed out', () async {
      final _RecordingAdapter adapter = _RecordingAdapter();
      final ProviderContainer container = _container(adapter, viewer: null);
      addTearDown(container.dispose);
      expect(
        await container.read(importedConversationProvider(_userId).future),
        isNull,
      );
      expect(adapter.requestedPaths, isEmpty);
    });

    test('asks again for the account switched to', () {
      fakeAsync((FakeAsync async) {
        final _RecordingAdapter adapter = _RecordingAdapter();
        final ProviderContainer container = _container(adapter)
          ..listen(importedConversationProvider(_userId), (_, _) {});
        async.elapse(const Duration(milliseconds: 1));
        container.read(currentUserIdProvider.notifier).set('other');
        async.elapse(const Duration(milliseconds: 1));
        expect(adapter.requestedPaths, hasLength(2));

        container.dispose();
        async.flushTimers();
      });
    });

    test('a failure that comes after the profile is gone leaves no timer', () {
      fakeAsync((FakeAsync async) {
        final _RecordingAdapter adapter = _RecordingAdapter(status: 429);
        final ProviderContainer container = _container(adapter);
        container
            .listen(importedConversationProvider(_userId), (_, _) {})
            .close();
        // Gone before the answer arrives.
        container.invalidate(importedConversationProvider(_userId));
        async.elapse(const Duration(milliseconds: 1));
        expect(async.pendingTimers, isEmpty);

        container.dispose();
      });
    });
  });
}
