import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/features/profile/domain/profile_badge_variant_field.dart';
import 'package:fluxer_app/features/profile/providers/own_profile_badges_provider.dart';
import 'package:fluxer_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:fluxer_dart/export.dart';

// Fork: OwnProfileBadgesSettingsPreview once watched the whole
// userSettingsViewModelProvider and relied on `if (!ref.mounted)` after a
// 250 ms delay to debounce rebuilds. Because AsyncNotifier reuses its instance
// and `this.ref` resolves to the current element ref, `ref.mounted` stayed
// true across rebuilds: dragging the accent color picker or typing in profile
// fields fired POST /users/@me/profile-badges/preview on every frame/keystroke
// and tripped the 50 req/s global rate limit, signing the user out
// (tyne-chat/tyne#909).

const String _kUserId = 'user_1';

class _RecordedRequest {
  const _RecordedRequest({
    required this.method,
    required this.path,
    required this.body,
  });

  final String method;
  final String path;
  final Map<String, Object?> body;
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({this.statusCode = 200});

  int statusCode;
  final List<_RecordedRequest> requests = <_RecordedRequest>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final Object? rawData = options.data;
    final Map<String, Object?> body = rawData is Map<Object?, Object?>
        ? rawData.map(
            (Object? key, Object? value) =>
                MapEntry<String, Object?>(key.toString(), value),
          )
        : const <String, Object?>{};
    requests.add(
      _RecordedRequest(method: options.method, path: options.path, body: body),
    );
    if (statusCode >= 400) {
      return ResponseBody.fromString(
        jsonEncode(<String, Object?>{'message': 'error'}),
        statusCode,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode(<String, Object?>{
        'profile_badges': <Object?>[],
        'own_badges': <Object?>[],
      }),
      statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _TestUserSettingsViewModel extends UserSettingsViewModel {
  _TestUserSettingsViewModel(this._initialState);

  final UserSettingsViewState _initialState;

  @override
  UserSettingsViewState build() => _initialState;
}

UserSettingsViewState _loadedState({
  String userId = _kUserId,
  bool isProfileLoaded = true,
}) {
  return UserSettingsViewState(
    userId: userId,
    username: 'tester',
    displayName: 'Tester',
    discriminator: '0001',
    avatar: null,
    avatarColor: 0x4641D9,
    memberSince: null,
    status: 'online',
    messageDisplayCompact: false,
    developerMode: false,
    trustedDomains: const <String>[],
    isProfileLoaded: isProfileLoaded,
  );
}

ProviderContainer _createContainer({
  required _RecordingAdapter adapter,
  required UserSettingsViewState initialState,
}) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
    ..httpClientAdapter = adapter;
  return ProviderContainer(
    overrides: [
      fluxerBaseUrlProvider.overrideWithValue('https://example.invalid'),
      fluxerDioProvider.overrideWithValue(dio),
      userSettingsViewModelProvider.overrideWith(
        () => _TestUserSettingsViewModel(initialState),
      ),
    ],
  );
}

void main() {
  test(
    'unloaded profile sends no badge preview requests even across edits',
    () {
      fakeAsync((FakeAsync async) {
        final _RecordingAdapter adapter = _RecordingAdapter();
        final ProviderContainer container = _createContainer(
          adapter: adapter,
          initialState: _loadedState(userId: '', isProfileLoaded: false),
        );
        addTearDown(container.dispose);

        final ProviderSubscription<AsyncValue<ProfileBadgePreviewResponse?>>
        sub = container.listen(
          ownProfileBadgesSettingsPreviewProvider,
          (_, _) {},
          fireImmediately: true,
        );
        addTearDown(sub.close);

        final UserSettingsViewModel vm = container.read(
          userSettingsViewModelProvider.notifier,
        );
        for (int i = 0; i < 20; i++) {
          vm.updateAccentColor(0x100000 + i);
          async.elapse(const Duration(milliseconds: 16));
        }
        async.elapse(const Duration(seconds: 1));

        expect(adapter.requests, isEmpty);
      });
    },
  );

  test('dragging accent color at 60 Hz and typing bio/name/pronouns sends zero '
      'extra badge preview requests', () {
    fakeAsync((FakeAsync async) {
      final _RecordingAdapter adapter = _RecordingAdapter();
      final ProviderContainer container = _createContainer(
        adapter: adapter,
        initialState: _loadedState(),
      );
      addTearDown(container.dispose);

      final ProviderSubscription<AsyncValue<ProfileBadgePreviewResponse?>> sub =
          container.listen(
            ownProfileBadgesSettingsPreviewProvider,
            (_, _) {},
            fireImmediately: true,
          );
      addTearDown(sub.close);

      // Initial preview after the 250 ms debounce.
      async.elapse(const Duration(milliseconds: 300));
      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.single.path, '/users/@me/profile-badges/preview');

      final UserSettingsViewModel vm = container.read(
        userSettingsViewModelProvider.notifier,
      );

      // Simulate 90 frames (~1.44 s at 60 Hz) of dragging the accent color
      // picker, matching the production flood scenario.
      for (int i = 0; i < 90; i++) {
        vm.updateAccentColor(0x0EFF00 + i);
        async.elapse(const Duration(milliseconds: 16));
      }

      // Simulate typing in display name, pronouns, and bio.
      for (int i = 1; i <= 15; i++) {
        vm
          ..updateDisplayName('Name $i')
          ..updatePronouns('They/Them $i')
          ..updateBio('Bio text $i');
        async.elapse(const Duration(milliseconds: 50));
      }

      async.elapse(const Duration(seconds: 2));

      // Still only the single initial request.
      expect(adapter.requests, hasLength(1));
    });
  });

  test(
    'rapid badge toggles within 250 ms coalesce into a single preview request '
    'with the latest settings',
    () {
      fakeAsync((FakeAsync async) {
        final _RecordingAdapter adapter = _RecordingAdapter();
        final ProviderContainer container = _createContainer(
          adapter: adapter,
          initialState: _loadedState(),
        );
        addTearDown(container.dispose);

        final ProviderSubscription<AsyncValue<ProfileBadgePreviewResponse?>>
        sub = container.listen(
          ownProfileBadgesSettingsPreviewProvider,
          (_, _) {},
          fireImmediately: true,
        );
        addTearDown(sub.close);

        async.elapse(const Duration(milliseconds: 300));
        expect(adapter.requests, hasLength(1));

        // Five distinct badge changes spaced 40 ms apart (all < 250 ms).
        final UserSettingsViewModel vm = container.read(
          userSettingsViewModelProvider.notifier,
        )..setProfileBadgeHidden(key: 'staff', hidden: true);
        async.elapse(const Duration(milliseconds: 40));
        vm.setProfileBadgeHidden(key: 'bug_hunter', hidden: true);
        async.elapse(const Duration(milliseconds: 40));
        vm.setProfileBadgeVariant(
          ProfileBadgeVariantField.premiumBadgeMasked,
          value: true,
        );
        async.elapse(const Duration(milliseconds: 40));
        vm.setProfileBadgeVariant(
          ProfileBadgeVariantField.premiumBadgeTimestampHidden,
          value: true,
        );
        async.elapse(const Duration(milliseconds: 40));
        vm.setProfileBadgeVariant(
          ProfileBadgeVariantField.operatorPassBadgeCountHidden,
          value: true,
        );

        // 240 ms after the final toggle: superseded builds must not have fired.
        async.elapse(const Duration(milliseconds: 240));
        expect(adapter.requests, hasLength(1));

        // Past the 250 ms debounce of the final toggle: exactly one new request.
        async.elapse(const Duration(milliseconds: 20));
        expect(adapter.requests, hasLength(2));

        final Map<String, Object?> latestBody = adapter.requests.last.body;
        expect(latestBody['hidden_profile_badges'], <String>[
          'bug_hunter',
          'staff',
        ]);
        expect(latestBody['premium_badge_masked'], isTrue);
        expect(latestBody['premium_badge_timestamp_hidden'], isTrue);
        expect(latestBody['operator_pass_badge_count_hidden'], isTrue);
      });
    },
  );

  test('disposing the provider during the debounce window cancels the pending '
      'preview request', () {
    fakeAsync((FakeAsync async) {
      final _RecordingAdapter adapter = _RecordingAdapter();
      final ProviderContainer container = _createContainer(
        adapter: adapter,
        initialState: _loadedState(),
      );
      addTearDown(container.dispose);

      final ProviderSubscription<AsyncValue<ProfileBadgePreviewResponse?>> sub =
          container.listen(
            ownProfileBadgesSettingsPreviewProvider,
            (_, _) {},
            fireImmediately: true,
          );

      async.elapse(const Duration(milliseconds: 100));
      sub.close();
      async.elapse(const Duration(seconds: 1));

      expect(adapter.requests, isEmpty);
    });
  });

  test(
    'a failing preview request does not retry on unrelated edits or timers',
    () {
      fakeAsync((FakeAsync async) {
        final _RecordingAdapter adapter = _RecordingAdapter(statusCode: 429);
        final ProviderContainer container = _createContainer(
          adapter: adapter,
          initialState: _loadedState(),
        );
        addTearDown(container.dispose);

        final ProviderSubscription<AsyncValue<ProfileBadgePreviewResponse?>>
        sub = container.listen(
          ownProfileBadgesSettingsPreviewProvider,
          (_, _) {},
          fireImmediately: true,
        );
        addTearDown(sub.close);

        async.elapse(const Duration(milliseconds: 300));
        expect(adapter.requests, hasLength(1));
        expect(sub.read().asData?.value, isNull);

        final UserSettingsViewModel vm = container.read(
          userSettingsViewModelProvider.notifier,
        );
        for (int i = 0; i < 30; i++) {
          vm.updateAccentColor(0x220000 + i);
          async.elapse(const Duration(milliseconds: 16));
        }
        async.elapse(const Duration(seconds: 5));

        expect(adapter.requests, hasLength(1));
      });
    },
  );

  test(
    'each badge variant toggle triggers a preview after its debounce window',
    () {
      fakeAsync((FakeAsync async) {
        final _RecordingAdapter adapter = _RecordingAdapter();
        final ProviderContainer container = _createContainer(
          adapter: adapter,
          initialState: _loadedState(),
        );
        addTearDown(container.dispose);

        final ProviderSubscription<AsyncValue<ProfileBadgePreviewResponse?>>
        sub = container.listen(
          ownProfileBadgesSettingsPreviewProvider,
          (_, _) {},
          fireImmediately: true,
        );
        addTearDown(sub.close);

        async.elapse(const Duration(milliseconds: 300));
        expect(adapter.requests, hasLength(1));

        container
            .read(userSettingsViewModelProvider.notifier)
            .setProfileBadgeVariant(
              ProfileBadgeVariantField.operatorPassBadgeTimestampHidden,
              value: true,
            );
        async.elapse(const Duration(milliseconds: 300));
        expect(adapter.requests, hasLength(2));
        expect(
          adapter.requests.last.body['operator_pass_badge_timestamp_hidden'],
          isTrue,
        );
      });
    },
  );
}
