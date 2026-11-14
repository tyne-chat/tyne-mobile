// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: a persona opened from someone's "Personas (N)" gallery
// (tyne-chat/tyne#640). The gallery's list already holds each persona's
// profile card, so the page shows it at once, never the account's name in its
// place, and asks the server nothing on opening or swiping. Only a persona that
// is no longer in the list is fetched, once, and a failure is not asked again.
// The server signs a session out over a burst of requests (tyne-chat/tyne#114),
// so these count them.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/presentation/sheets/persona_profile_pager.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/features/profile/providers/public_persona_list_provider.dart';
import 'package:fluxer_app/features/ui/badge/fluxer_user_tag.dart';
import 'package:fluxer_app/features/ui/toast/fluxer_toast_overlay.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/providers/user_profile.dart';
import 'package:fluxer_app/shared/utils/fluxer_haptics.dart';
import 'package:fluxer_dart/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/open_test_database.dart';
import '../../../../helpers/test_l10n.dart';
import '../widgets/user_profile_view_test.dart' hide main;

/// Someone else's account; the viewer is `forkKUserId`.
const String _ownerId = '2';
const String _accountName = 'Account Name';
const String _listPath = '/users/$_ownerId/personas';

/// Answers the account's list, and each persona's profile from [profiles]
/// (404 for one not there, [profileStatus] for those that are), recording
/// every path asked for.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({
    this.profiles = const <String, Map<String, Object?>>{},
    this.profileStatus = 200,
  });

  final Map<String, Map<String, Object?>> profiles;
  final int profileStatus;
  final List<String> requestedPaths = <String>[];

  /// Requests for one persona's profile.
  List<String> get profileRequests => <String>[
    for (final String path in requestedPaths)
      if (path.startsWith('$_listPath/')) path,
  ];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final String path = options.path;
    requestedPaths.add(path);
    final (int status, Object? body) = switch (path) {
      _listPath => (200, _listBody),
      _ when path.startsWith('$_listPath/') =>
        profiles[path.substring(_listPath.length + 1)] == null
            ? (404, <String, Object?>{'code': 'UNKNOWN_PERSONA'})
            : (profileStatus, profiles[path.substring(_listPath.length + 1)]),
      _ => (404, <String, Object?>{}),
    };
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

const Map<String, Object?> _listBody = <String, Object?>{
  'display_tag_text': 'System',
  'display_tag_icon': null,
  'personas': <Map<String, Object?>>[
    <String, Object?>{
      'id': '900',
      'name': 'Ash',
      'bio': 'Ash likes tea',
      'pronouns': 'they/them',
      'visibility': 'public',
    },
    <String, Object?>{'id': '901', 'name': 'Bea', 'visibility': 'public'},
  ],
};

UserProfileFullResponse _accountProfile() => const UserProfileFullResponse(
  user: UserPartialResponse(
    id: _ownerId,
    username: 'account',
    discriminator: '0002',
    globalName: _accountName,
    avatar: null,
    avatarColor: null,
    flags: 0,
  ),
  userProfile: UserProfileFullResponseUserProfile(
    bio: null,
    pronouns: null,
    banner: null,
    accentColor: null,
  ),
  timezoneOffset: null,
);

class _FakeMyPersonas extends MyPersonasNotifier {
  _FakeMyPersonas(this._personas);
  final List<Persona> _personas;

  @override
  AsyncValue<List<Persona>> build() => AsyncValue.data(_personas);

  @override
  Future<void> reloadSilently() async {}
}

/// Stands in for the gallery under the pager: it holds someone else's list,
/// and the pager opens once the list is there, as a tap on the gallery does.
class _Gallery extends ConsumerWidget {
  const _Gallery({
    required this.ownerUserId,
    required this.ownerIsSelf,
    required this.personaIds,
    required this.initialIndex,
    required this.scrollController,
  });

  final String ownerUserId;
  final bool ownerIsSelf;
  final List<String> personaIds;
  final int initialIndex;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ownerIsSelf &&
        ref.watch(publicPersonaListProvider(ownerUserId)).value == null) {
      return const SizedBox.shrink();
    }
    return PersonaProfilePagerBody(
      ownerUserId: ownerUserId,
      ownerIsSelf: ownerIsSelf,
      personaIds: personaIds,
      initialIndex: initialIndex,
      scrollController: scrollController,
      onClose: () {},
    );
  }
}

Future<void> _pump(
  WidgetTester tester,
  _RecordingAdapter adapter, {
  String ownerUserId = _ownerId,
  bool ownerIsSelf = false,
  List<String> personaIds = const <String>['900', '901'],
  int initialIndex = 0,
  List<Persona> myPersonas = const <Persona>[],
}) async {
  final ScrollController scrollController = ScrollController();
  addTearDown(scrollController.dispose);
  final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
    ..httpClientAdapter = adapter;
  final colorTheme = buildDarkColorTheme();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...forkUpstream.overrides(),
        fluxerDioProvider.overrideWithValue(dio),
        fluxerDatabaseProvider.overrideWithValue(openTestDatabase()),
        myPersonasProvider.overrideWith(() => _FakeMyPersonas(myPersonas)),
        userProfileProvider(userId: ownerUserId).overrideWith(
          (Ref ref) => Future<UserProfileFullResponse?>.value(
            ownerIsSelf ? null : _accountProfile(),
          ),
        ),
      ],
      child: MaterialApp(
        locale: kTestLocale,
        localizationsDelegates: FluxerLocalizations.localizationsDelegates,
        supportedLocales: FluxerLocalizations.supportedLocales,
        theme: buildFluxerTheme(
          colorTheme: colorTheme,
          textTheme: FluxerTextTheme.fromColors(colorTheme),
          layoutTheme: FluxerLayoutTheme.scaled(),
        ),
        home: FluxerToastOverlay(
          child: Scaffold(
            body: _Gallery(
              ownerUserId: ownerUserId,
              ownerIsSelf: ownerIsSelf,
              personaIds: personaIds,
              initialIndex: initialIndex,
              scrollController: scrollController,
            ),
          ),
        ),
      ),
    ),
  );
  await _settle(tester);
}

/// Lets the requests in flight answer.
Future<void> _settle(WidgetTester tester) async {
  for (int i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

Future<void> _swipe(WidgetTester tester, {required bool forward}) async {
  await tester.fling(
    find.byType(PageView),
    Offset(forward ? -600 : 600, 0),
    1000,
  );
  await tester.pumpAndSettle();
  await _settle(tester);
}

Finder _displayTag(String label) => find.byWidgetPredicate(
  (Widget widget) => widget is FluxerUserTag && widget.label == label,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Each test opens a database of its own and never closes it.
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    FluxerHaptics.enabled = false;
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() {
    FluxerHaptics.enabled = true;
  });

  testWidgets(
    "shows the list's persona with the display tag, asking nothing for it",
    (WidgetTester tester) async {
      final _RecordingAdapter adapter = _RecordingAdapter();
      await _pump(tester, adapter);

      expect(find.text('Ash'), findsOneWidget);
      expect(find.text('they/them'), findsOneWidget);
      expect(find.text('Ash likes tea', findRichText: true), findsOneWidget);
      expect(_displayTag('System'), findsOneWidget);
      // Only in the "Main account" row, not in the persona's place.
      expect(find.text(_accountName), findsOneWidget);
      expect(adapter.requestedPaths.where((p) => p == _listPath), hasLength(1));
      expect(adapter.profileRequests, isEmpty);
    },
  );

  testWidgets('swiping to the next persona asks nothing either', (
    WidgetTester tester,
  ) async {
    final _RecordingAdapter adapter = _RecordingAdapter();
    await _pump(tester, adapter);

    await _swipe(tester, forward: true);
    expect(find.text('Bea'), findsOneWidget);
    await _swipe(tester, forward: false);
    expect(find.text('Ash'), findsOneWidget);

    expect(adapter.requestedPaths.where((p) => p == _listPath), hasLength(1));
    expect(adapter.profileRequests, isEmpty);
  });

  testWidgets('a persona no longer in the list is fetched once', (
    WidgetTester tester,
  ) async {
    final _RecordingAdapter adapter = _RecordingAdapter(
      profiles: <String, Map<String, Object?>>{
        '950': <String, Object?>{
          'id': '950',
          'name': 'Cy',
          'visibility': 'unlisted',
        },
      },
    );
    await _pump(tester, adapter, personaIds: const <String>['950', '900']);

    expect(find.text('Cy'), findsOneWidget);
    expect(adapter.profileRequests, <String>['$_listPath/950']);

    await _swipe(tester, forward: true);
    await _swipe(tester, forward: false);
    expect(find.text('Cy'), findsOneWidget);
    expect(adapter.profileRequests, <String>['$_listPath/950']);
  });

  testWidgets('a failed fetch of such a persona is not asked again', (
    WidgetTester tester,
  ) async {
    final _RecordingAdapter adapter = _RecordingAdapter(
      profiles: <String, Map<String, Object?>>{
        '950': <String, Object?>{'message': 'Internal Server Error'},
      },
      profileStatus: 500,
    );
    await _pump(tester, adapter, personaIds: const <String>['950', '900']);

    await _swipe(tester, forward: true);
    await _swipe(tester, forward: false);
    await _settle(tester);
    expect(adapter.profileRequests, <String>['$_listPath/950']);
  });

  testWidgets('your own gallery asks for neither list nor profile', (
    WidgetTester tester,
  ) async {
    final _RecordingAdapter adapter = _RecordingAdapter();
    await _pump(
      tester,
      adapter,
      ownerUserId: forkKUserId,
      ownerIsSelf: true,
      personaIds: const <String>['p1'],
      myPersonas: const <Persona>[Persona(id: 'p1', name: 'Mine')],
    );

    expect(find.text('Mine'), findsOneWidget);
    expect(
      adapter.requestedPaths.where(
        (String p) => p.startsWith('/users/$forkKUserId/personas'),
      ),
      isEmpty,
    );
  });
}
