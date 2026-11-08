// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: where a profile shows an account's "Personas (N)", and the gallery it
// opens (tyne-chat/tyne#189).

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/presentation/widgets/persona_gallery_entry.dart';
import 'package:fluxer_app/features/profile/providers/persona_gallery_view_provider.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/features/profile/providers/public_persona_list_provider.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/utils/fluxer_haptics.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/test_l10n.dart';

const String _userId = '222';

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({this.status = 200, Object? body})
    : body = body ?? _listBody(const <String>['Ash', 'Bea']);

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

Map<String, Object?> _listBody(List<String> names) => <String, Object?>{
  'display_tag_text': 'System',
  'display_tag_icon': null,
  'personas': <Map<String, Object?>>[
    for (final (int i, String name) in names.indexed)
      <String, Object?>{
        'id': '${900 + i}',
        'name': name,
        'visibility': 'public',
        'pronouns': i == 0 ? 'they/them' : null,
        'bio': i == 1 ? 'Loves **gardening**' : null,
      },
  ],
};

class _FakeMyPersonas extends MyPersonasNotifier {
  _FakeMyPersonas(this._personas);
  final List<Persona> _personas;

  @override
  AsyncValue<List<Persona>> build() => AsyncValue.data(_personas);

  @override
  Future<void> reloadSilently() async {}
}

PersonaGalleryOwner _owner({bool isSelf = false}) => (
  userId: _userId,
  isSelf: isSelf,
  name: 'Kit',
  avatarUrl: null,
  avatarColor: null,
  guildId: null,
);

/// The account header's trailing, then a list section with the leading rows
/// (someone else) or the own section (yourself), as the profile lays them out.
class _ProfileBits extends ConsumerWidget {
  const _ProfileBits({required this.owner});

  final PersonaGalleryOwner owner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Widget> rows = personaGalleryLeadingRows(ref, owner);
    return ListView(
      children: <Widget>[
        Row(
          children: <Widget>[
            const Text('Kit'),
            ?accountPersonaNameTrailing(owner),
          ],
        ),
        ...ownPersonaGallerySection(owner, gap: 8),
        if (rows.isNotEmpty) FluxerListSection(children: rows),
      ],
    );
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required PersonaGalleryOwner owner,
  _RecordingAdapter? adapter,
  List<Persona>? myPersonas,
}) async {
  final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
    ..httpClientAdapter = adapter ?? _RecordingAdapter();
  final colorTheme = buildDarkColorTheme();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        fluxerDioProvider.overrideWithValue(dio),
        myPersonasProvider.overrideWith(
          () => _FakeMyPersonas(myPersonas ?? const <Persona>[]),
        ),
      ],
      child: MaterialApp(
        locale: kTestLocale,
        localizationsDelegates: fluxerLocalizationsDelegates,
        supportedLocales: FluxerLocalizations.supportedLocales,
        theme: buildFluxerTheme(
          colorTheme: colorTheme,
          textTheme: FluxerTextTheme.fromColors(colorTheme),
          layoutTheme: FluxerLayoutTheme.scaled(),
        ),
        home: Scaffold(body: _ProfileBits(owner: owner)),
      ),
    ),
  );
  await tester.pump();
  if (!owner.isSelf) {
    await _settleList(tester);
  }
}

/// Lets someone else's list arrive.
Future<void> _settleList(WidgetTester tester) async {
  for (int i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

void main() {
  setUp(() {
    FluxerHaptics.enabled = false;
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() {
    FluxerHaptics.enabled = true;
  });

  final String twoPersonas = testL10n.fork.personaGalleryTitle(2);

  group('pill and row', () {
    testWidgets('someone with public personas: tag, pill and row', (
      tester,
    ) async {
      final _RecordingAdapter adapter = _RecordingAdapter();
      await _pump(tester, owner: _owner(), adapter: adapter);

      expect(find.text('SYSTEM'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('persona-gallery-pill')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('persona-gallery-row')),
        findsOneWidget,
      );
      expect(find.text(twoPersonas), findsNWidgets(2));
      // The header, the row and the summary shared one request.
      expect(adapter.requestedPaths, <String>['/users/$_userId/personas']);
    });

    testWidgets('someone without public personas: the tag only', (
      tester,
    ) async {
      await _pump(
        tester,
        owner: _owner(),
        adapter: _RecordingAdapter(body: _listBody(const <String>[])),
      );

      expect(find.text('SYSTEM'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('persona-gallery-pill')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('persona-gallery-row')),
        findsNothing,
      );
    });

    testWidgets('a profile the server will not show: nothing', (tester) async {
      await _pump(
        tester,
        owner: _owner(),
        adapter: _RecordingAdapter(
          status: 403,
          body: const <String, Object?>{},
        ),
      );

      expect(find.text('SYSTEM'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('persona-gallery-pill')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('persona-gallery-row')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('persona-gallery-row-failed')),
        findsNothing,
      );
    });

    testWidgets(
      'your own profile shows the pill and row with no public persona',
      (tester) async {
        final _RecordingAdapter adapter = _RecordingAdapter();
        await _pump(
          tester,
          owner: _owner(isSelf: true),
          adapter: adapter,
          myPersonas: const <Persona>[Persona(id: '1', name: 'Hidden')],
        );

        final String none = testL10n.fork.personaGalleryTitle(0);
        expect(find.text(none), findsNWidgets(2));
        expect(adapter.requestedPaths, isEmpty);
      },
    );

    testWidgets('a failed load offers Retry, which asks once more', (
      tester,
    ) async {
      final _RecordingAdapter adapter = _RecordingAdapter(status: 500);
      await _pump(tester, owner: _owner(), adapter: adapter);

      expect(find.text(testL10n.fork.personaGalleryLoadFailed), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('persona-gallery-pill')),
        findsNothing,
      );
      // Rebuilds ask nothing more.
      await tester.pump(const Duration(seconds: 5));
      expect(adapter.requestedPaths, hasLength(1));

      adapter.status = 200;
      await tester.tap(find.text(testL10n.retry));
      await tester.pump();
      await _settleList(tester);

      expect(adapter.requestedPaths, hasLength(2));
      expect(find.text(twoPersonas), findsNWidgets(2));
    });
  });

  group('the gallery', () {
    Future<void> openGallery(WidgetTester tester) async {
      await tester.tap(
        find.byKey(const ValueKey<String>('persona-gallery-row')),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('lists, searches and switches layout', (tester) async {
      final _RecordingAdapter adapter = _RecordingAdapter();
      await _pump(tester, owner: _owner(), adapter: adapter);
      await openGallery(tester);

      expect(find.text('Ash'), findsOneWidget);
      expect(find.text('Bea'), findsOneWidget);
      // A bio as plain text, and a card without one.
      expect(find.text('Loves gardening'), findsOneWidget);
      expect(find.text(testL10n.fork.personaGalleryNoBio), findsOneWidget);
      expect(find.text(testL10n.fork.personaGalleryCount(2)), findsOneWidget);
      expect(
        find.text(testL10n.fork.personaGallerySearchOther('Kit')),
        findsOneWidget,
      );
      // Nothing of the owner's own.
      expect(
        find.byKey(const ValueKey<String>('persona-gallery-own-bar')),
        findsNothing,
      );

      await tester.enterText(find.byType(TextField), 'garden');
      await tester.pump();
      expect(find.text('Ash'), findsNothing);
      expect(
        find.text(testL10n.fork.personaGalleryCountFiltered(1, 2)),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();
      expect(find.text(testL10n.fork.personaGalleryNoMatch), findsOneWidget);

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('persona-gallery-view-list')),
      );
      await tester.pumpAndSettle();
      expect(find.text('(they/them)'), findsOneWidget);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(PersonaGalleryViewNotifier.prefKey), 'list');

      await tester.tap(
        find.byKey(const ValueKey<String>('persona-gallery-view-avatars')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ash'), findsOneWidget);

      // Opening the gallery asked for nothing more.
      expect(adapter.requestedPaths, hasLength(1));
    });

    testWidgets("someone else's gallery offers no \"Recently used\"", (
      tester,
    ) async {
      await _pump(tester, owner: _owner());
      await openGallery(tester);

      await tester.tap(
        find.byKey(const ValueKey<String>('persona-gallery-sort')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(testL10n.fork.personaGallerySortMostUsed),
        findsOneWidget,
      );
      expect(
        find.text(testL10n.fork.personaGallerySortRecentlyUsed),
        findsNothing,
      );
    });

    testWidgets('your own gallery: the bar, and the switch for the others', (
      tester,
    ) async {
      await _pump(
        tester,
        owner: _owner(isSelf: true),
        myPersonas: const <Persona>[
          Persona(id: '1', name: 'Out', visibility: 'public'),
          Persona(id: '2', name: 'Quiet'),
        ],
      );
      await openGallery(tester);

      expect(
        find.text(testL10n.fork.personaGalleryOthersSee(1)),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('persona-gallery-choose-featured')),
        findsNothing,
      );
      expect(find.text(testL10n.fork.personaGalleryManage), findsOneWidget);
      expect(find.text('Out'), findsOneWidget);
      expect(find.text('Quiet'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey<String>('persona-gallery-show-hidden')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quiet'), findsOneWidget);
      expect(
        find.text(testL10n.fork.personaVisibilityUnlisted),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('persona-gallery-sort')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(testL10n.fork.personaGallerySortRecentlyUsed),
        findsOneWidget,
      );
    });

    testWidgets('your own gallery without a public persona explains it', (
      tester,
    ) async {
      await _pump(
        tester,
        owner: _owner(isSelf: true),
        myPersonas: const <Persona>[Persona(id: '2', name: 'Quiet')],
      );
      await openGallery(tester);

      expect(find.text(testL10n.fork.personaGalleryNonePublic), findsOneWidget);
      expect(find.text(testL10n.fork.personaGalleryManage), findsOneWidget);
      expect(find.text('Quiet'), findsNothing);
      // Leads to the settings to pick some (tyne-chat/tyne#542).
      expect(
        find.byKey(const ValueKey<String>('persona-gallery-choose-featured')),
        findsOneWidget,
      );
    });
  });
}
