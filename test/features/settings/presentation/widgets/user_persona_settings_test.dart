import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/domain/persona_settings.dart';
import 'package:fluxer_app/features/profile/providers/multi_persona_reactions_provider.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/user_persona_settings.dart';
import 'package:fluxer_app/features/settings/providers/persona_settings_launch_provider.dart';
import 'package:fluxer_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:fluxer_app/features/shell/providers/user/current_user_private_provider.dart';
import 'package:fluxer_app/features/ui/switch_group/fluxer_switch_group.dart';
import 'package:fluxer_app/features/ui/tappable/fluxer_tappable.dart';
import 'package:fluxer_app/features/ui/toast/fluxer_toast.dart';
import 'package:fluxer_app/features/ui/toast/toast_provider.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_dart/export.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/pump_fluxer_app.dart';
import '../../../../helpers/test_account_user_id.dart';
import '../../../../helpers/test_l10n.dart';

class _MockDioAdapter implements HttpClientAdapter {
  /// What the select mode tests answer and count (tyne-chat/tyne#542).
  int status = 200;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      '{}',
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _createMockDio([_MockDioAdapter? adapter]) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.fluxer.invalid'))
    ..httpClientAdapter = adapter ?? _MockDioAdapter();
  return dio;
}

/// The settings page opened from the Personas gallery (tyne-chat/tyne#542).
class _PresetLaunch extends PersonaSettingsLaunchNotifier {
  @override
  PersonaSettingsLaunch? build() => const PersonaSettingsLaunch(
    filter: PersonaVisibilityFilter.unlisted,
    selecting: true,
  );
}

class _FakeUserSettings extends UserSettingsViewModel {
  @override
  UserSettingsViewState build() => const UserSettingsViewState(
    userId: '1',
    username: 'tester',
    displayName: 'Root User',
    discriminator: '0001',
    avatar: null,
    avatarColor: null,
    memberSince: null,
    status: 'online',
    messageDisplayCompact: false,
    developerMode: false,
    trustedDomains: <String>[],
  );
}

class _FixedCurrentUserPrivate extends CurrentUserPrivateRead {
  _FixedCurrentUserPrivate(this._user);

  final UserPrivateResponse? _user;

  @override
  UserPrivateResponse? build(String accountUserId) => _user;
}

class _FakeMyPersonasNotifier extends MyPersonasNotifier {
  _FakeMyPersonasNotifier(this._initial);

  final List<Persona> _initial;

  @override
  AsyncValue<List<Persona>> build() => AsyncData(_initial);

  @override
  Future<void> reloadSilently() async {}

  @override
  void removePersona(String id) {
    final current = state.asData?.value ?? [];
    state = AsyncData(current.where((p) => p.id != id).toList());
  }
}

class _FakePersonaSettingsNotifier extends PersonaSettingsNotifier {
  @override
  AsyncValue<PersonaSettings> build() => const AsyncData(PersonaSettings());

  @override
  Future<void> reloadSilently() async {}

  @override
  Future<void> updateSettings({
    String? activePersonaMode,
    String? activePersonaScope,
    String? Function()? activePersonaId,
    bool? isLatched,
    String? displayTagText,
    String? Function()? displayTagIcon,
  }) async {
    final current = state.asData?.value ?? const PersonaSettings();
    final updated = current.copyWith(
      activePersonaMode: activePersonaMode,
      activePersonaId: activePersonaId,
      isLatched: isLatched,
      displayTagText: displayTagText,
      displayTagIcon: displayTagIcon,
    );
    state = AsyncValue.data(updated);
  }
}

class _FakeSystemDisplayTagNotifier extends SystemDisplayTagNotifier {
  _FakeSystemDisplayTagNotifier(this._initial);

  final SystemDisplayTag _initial;

  @override
  SystemDisplayTag build() => _initial;

  @override
  Future<void> updateDisplayTag(String? text, String? iconUrl) async {
    state = SystemDisplayTag(text: text, iconUrl: iconUrl);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const personaAlpha = Persona(
    id: 'p_alpha',
    name: 'Alpha Alter',
    pronouns: 'they/them',
    bio: 'Primary front',
    personaTags: [PersonaTag(prefix: 'a:', suffix: '')],
  );

  const personaBeta = Persona(
    id: 'p_beta',
    name: 'Beta Alter',
    pronouns: 'she/her',
    bio: 'Co-front',
    personaTags: [PersonaTag(prefix: '[', suffix: ']')],
  );

  final allPersonas = [personaAlpha, personaBeta];

  Widget buildTestBed({
    List<Persona> personas = const [],
    SystemDisplayTag initialTag = const SystemDisplayTag(),
    _MockDioAdapter? adapter,
    bool launchFromGallery = false,
  }) {
    return pumpFluxerApp(
      overrides: [
        if (launchFromGallery)
          personaSettingsLaunchProvider.overrideWith(_PresetLaunch.new),
        fluxerDioProvider.overrideWithValue(_createMockDio(adapter)),
        userSettingsViewModelProvider.overrideWith(_FakeUserSettings.new),
        currentUserPrivateReadProvider(
          kTestAccountUserId,
        ).overrideWith(() => _FixedCurrentUserPrivate(null)),
        myPersonasProvider.overrideWith(
          () => _FakeMyPersonasNotifier(personas),
        ),
        personaSettingsProvider.overrideWith(_FakePersonaSettingsNotifier.new),
        systemDisplayTagProvider.overrideWith(
          () => _FakeSystemDisplayTagNotifier(initialTag),
        ),
      ],
      child: const Scaffold(body: UserPersonaSettings()),
    );
  }

  Future<void> pumpSettings(
    WidgetTester tester, {
    List<Persona> personas = const [],
    SystemDisplayTag initialTag = const SystemDisplayTag(),
    _MockDioAdapter? adapter,
    bool launchFromGallery = false,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      buildTestBed(
        personas: personas,
        initialTag: initialTag,
        adapter: adapter,
        launchFromGallery: launchFromGallery,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('UserPersonaSettings', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
      'renders sections, mode options, and empty state when no personas',
      (tester) async {
        await pumpSettings(tester);

        expect(find.text('Manual'), findsOneWidget);
        expect(find.text('Last Used'), findsOneWidget);
        expect(find.text('CHAT PREVIEW'), findsOneWidget);
        expect(
          find.text(
            'No personas configured yet. Create one via Manage Personas.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('renders configured personas list with details and actions', (
      tester,
    ) async {
      await pumpSettings(tester, personas: allPersonas);

      expect(find.text('Configured Personas (2)'), findsOneWidget);
      expect(find.text('Alpha Alter'), findsOneWidget);
      expect(find.text('(they/them)'), findsOneWidget);
      expect(find.text('a:text'), findsOneWidget);
      expect(find.text('Primary front'), findsOneWidget);

      expect(find.text('Beta Alter'), findsOneWidget);
      expect(find.text('(she/her)'), findsOneWidget);
      expect(find.text('[text]'), findsOneWidget);
      expect(find.text('Co-front'), findsOneWidget);

      // Both personas have Set Active, Edit, and Delete buttons
      expect(find.text('Set Active'), findsNWidgets(2));
      expect(find.byIcon(PhosphorIconsBold.pencilSimple), findsNWidgets(2));
      expect(find.byIcon(PhosphorIconsBold.trash), findsNWidgets(2));
    });

    testWidgets('filters personas using search query and shows empty search', (
      tester,
    ) async {
      await pumpSettings(tester, personas: allPersonas);

      // Search input is the second FluxerInput on screen (first is display tag)
      final searchInputs = find.byType(TextField);
      expect(searchInputs, findsNWidgets(2));
      final searchField = searchInputs.at(1);

      await tester.enterText(searchField, 'Alpha');
      await tester.pumpAndSettle();

      expect(find.text('Alpha Alter'), findsOneWidget);
      expect(find.text('Beta Alter'), findsNothing);

      // Search by pronouns
      await tester.enterText(searchField, 'she/her');
      await tester.pumpAndSettle();

      expect(find.text('Alpha Alter'), findsNothing);
      expect(find.text('Beta Alter'), findsOneWidget);

      // Non-existent search
      await tester.enterText(searchField, 'UnknownName');
      await tester.pumpAndSettle();

      expect(find.text('No matching personas found.'), findsOneWidget);
    });

    testWidgets('toggles persona active latch state', (tester) async {
      await pumpSettings(tester, personas: allPersonas);

      expect(find.text('Set Active'), findsNWidgets(2));
      expect(find.text('Active'), findsNothing);

      // Tap Set Active on first persona (Alpha)
      await tester.tap(find.text('Set Active').first);
      await tester.pumpAndSettle();

      // Now Alpha Alter is Active
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Set Active'), findsOneWidget);

      // Tapping Active unlatches it
      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsNothing);
      expect(find.text('Set Active'), findsNWidgets(2));
    });

    testWidgets('editing display tag activates save bar and allows reset', (
      tester,
    ) async {
      await pumpSettings(tester, personas: allPersonas);

      final displayTagField = find.byType(TextField).first;
      expect(
        tester.widget<TextField>(displayTagField).controller?.text,
        isEmpty,
      );

      // Enter a new display tag
      await tester.enterText(displayTagField, '[SYS]');
      await tester.pumpAndSettle();

      // SaveBar should be visible
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);

      // Tap Reset
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(displayTagField).controller?.text,
        isEmpty,
      );
    });

    testWidgets('saving display tag updates state and hides save bar', (
      tester,
    ) async {
      await pumpSettings(tester, personas: allPersonas);

      final displayTagField = find.byType(TextField).first;
      await tester.enterText(displayTagField, '[MY-SYS]');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // SaveBar resets
      expect(
        tester.widget<TextField>(displayTagField).controller?.text,
        '[MY-SYS]',
      );
    });

    testWidgets(
      'delete persona button shows modal and removes persona on confirm',
      (tester) async {
        await pumpSettings(tester, personas: allPersonas);

        expect(find.text('Beta Alter'), findsOneWidget);

        // Tap trash button for Beta Alter (second trash icon)
        final trashButtons = find.byIcon(PhosphorIconsBold.trash);
        await tester.tap(trashButtons.at(1));
        await tester.pumpAndSettle();

        // Confirmation modal
        expect(find.text('Delete Persona'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);

        // Confirm delete
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Beta Alter is removed from the list
        expect(find.text('Beta Alter'), findsNothing);
        expect(find.text('Alpha Alter'), findsOneWidget);
      },
    );

    testWidgets('switches persona mode to Last Used via radio item', (
      tester,
    ) async {
      await pumpSettings(tester, personas: allPersonas);

      await tester.tap(find.text('Last Used'));
      await tester.pumpAndSettle();
    });

    testWidgets('removing tag icon marks sheet dirty and shows save bar', (
      tester,
    ) async {
      await pumpSettings(
        tester,
        personas: allPersonas,
        initialTag: const SystemDisplayTag(text: '[SYS]', iconUrl: '1a2b3c4d'),
      );

      expect(find.text('Remove Icon'), findsOneWidget);

      await tester.tap(find.text('Remove Icon'));
      await tester.pumpAndSettle();

      // SaveBar becomes visible
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets(
      'loads no image for a tag icon that is a link, and still offers to remove it',
      (tester) async {
        await pumpSettings(
          tester,
          personas: allPersonas,
          initialTag: const SystemDisplayTag(
            text: '[SYS]',
            iconUrl: 'https://tracker.example/pixel.png',
          ),
        );

        expect(
          find.byWidgetPredicate(
            (Widget widget) =>
                widget is Image &&
                widget.image is NetworkImage &&
                (widget.image as NetworkImage).url.contains('tracker.example'),
          ),
          findsNothing,
        );
        expect(find.text('Remove Icon'), findsOneWidget);
      },
    );
  });

  // Fork: "React as several personas at once" (tyne-chat/tyne#86).
  group('the reactions switch', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    final Finder item = find.widgetWithText(
      FluxerSettingsSwitchItem,
      'React as several personas at once',
    );
    bool shownOn(WidgetTester tester) =>
        tester.widget<FluxerSettingsSwitchItem>(item).value;

    List<RequestOptions> saves(_MockDioAdapter adapter) => <RequestOptions>[
      for (final RequestOptions r in adapter.requests)
        if (r.method == 'PATCH' && r.path == '/users/@me/personas/settings') r,
    ];

    testWidgets(
      'is on until told otherwise, with a label and nothing under it',
      (tester) async {
        final adapter = _MockDioAdapter();
        await pumpSettings(tester, adapter: adapter);

        expect(
          find.textContaining(
            RegExp(
              testL10n.fork.personaSettingsReactionsHeader,
              caseSensitive: false,
            ),
          ),
          findsOneWidget,
        );
        expect(shownOn(tester), isTrue);
        expect(
          tester.widget<FluxerSettingsSwitchItem>(item).description,
          isNull,
        );
        expect(saves(adapter), isEmpty);
      },
    );

    testWidgets('saves a change in one request that names only this setting', (
      tester,
    ) async {
      final adapter = _MockDioAdapter();
      await pumpSettings(tester, adapter: adapter);

      await tester.ensureVisible(item);
      await tester.tap(find.text('React as several personas at once'));
      await tester.pumpAndSettle();

      expect(shownOn(tester), isFalse);
      expect(saves(adapter).map((RequestOptions r) => r.data), [
        <String, dynamic>{'multi_persona_reactions': false},
      ]);
      expect(
        ProviderScope.containerOf(
          tester.element(find.byType(UserPersonaSettings)),
        ).read(multiPersonaReactionsProvider),
        isFalse,
      );
    });

    testWidgets('goes back when the save is refused, and does not try again', (
      tester,
    ) async {
      final adapter = _MockDioAdapter();
      await pumpSettings(tester, adapter: adapter);
      adapter.status = 429;

      await tester.ensureVisible(item);
      await tester.tap(find.text('React as several personas at once'));
      await tester.pumpAndSettle();

      expect(shownOn(tester), isTrue);
      expect(saves(adapter), hasLength(1));
    });
  });

  // Fork: selecting many personas to change their visibility or delete them
  // (tyne-chat/tyne#542).
  group('select mode', () {
    const Persona pub = Persona(
      id: 'pub',
      name: 'Pub One',
      visibility: 'public',
    );
    const Persona unl = Persona(id: 'unl', name: 'Unl One');
    const Persona unl2 = Persona(id: 'unl2', name: 'Unl Two');
    const Persona priv = Persona(
      id: 'priv',
      name: 'Priv One',
      visibility: 'private',
    );
    const List<Persona> mixed = <Persona>[pub, unl, unl2, priv];

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Finder selectedText(int count) =>
        find.text(testL10n.fork.personaBulkSelectedCount(count));

    Future<void> settle(WidgetTester tester) async {
      for (int i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      await tester.pumpAndSettle();
    }

    ProviderContainer containerOf(WidgetTester tester) =>
        ProviderScope.containerOf(
          tester.element(find.byType(UserPersonaSettings)),
        );

    bool barButtonEnabled(WidgetTester tester, String key) => tester
        .widget<FluxerTappable>(
          find.descendant(
            of: find.byKey(ValueKey<String>(key)),
            matching: find.byType(FluxerTappable),
          ),
        )
        .enabled;

    List<Object?> patched(_MockDioAdapter adapter) => <Object?>[
      for (final RequestOptions r in adapter.requests)
        if (r.method == 'PATCH') r.data,
    ];

    testWidgets('chips count each visibility and filter the cards', (
      tester,
    ) async {
      await pumpSettings(tester, personas: mixed);

      Finder count(String filter, String n) => find.descendant(
        of: find.byKey(ValueKey<String>('persona-filter-$filter')),
        matching: find.text(n),
      );
      expect(count('all', '4'), findsOneWidget);
      expect(count('public', '1'), findsOneWidget);
      expect(count('unlisted', '2'), findsOneWidget);
      expect(count('private', '1'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('persona-filter-unlisted')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unl One'), findsOneWidget);
      expect(find.text('Unl Two'), findsOneWidget);
      expect(find.text('Pub One'), findsNothing);
      // The section title keeps the total.
      expect(find.text('Configured Personas (4)'), findsOneWidget);
    });

    testWidgets('an empty filter says so', (tester) async {
      await pumpSettings(tester, personas: const <Persona>[pub]);

      await tester.tap(
        find.byKey(const ValueKey<String>('persona-filter-private')),
      );
      await tester.pumpAndSettle();

      expect(find.text(testL10n.fork.personaFilterEmpty), findsOneWidget);
    });

    testWidgets('a long press selects the card and hides the card actions', (
      tester,
    ) async {
      await pumpSettings(tester, personas: mixed);
      expect(find.text('Set Active'), findsNWidgets(4));

      await tester.longPress(find.text('Unl One'));
      await tester.pumpAndSettle();

      expect(selectedText(1), findsOneWidget);
      expect(find.text('Set Active'), findsNothing);
      expect(find.byIcon(PhosphorIconsBold.pencilSimple), findsNothing);

      // A tap now toggles instead of editing.
      await tester.tap(find.text('Unl Two'));
      await tester.pumpAndSettle();
      expect(selectedText(2), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('persona-selection-close')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('persona-selection-bar')),
        findsNothing,
      );
      expect(find.text('Set Active'), findsNWidgets(4));
    });

    testWidgets('Select all takes what the filter shows; the selection stays', (
      tester,
    ) async {
      await pumpSettings(tester, personas: mixed);
      await tester.tap(
        find.byKey(const ValueKey<String>('persona-filter-unlisted')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('persona-select-mode')),
      );
      await tester.pumpAndSettle();
      expect(selectedText(0), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('persona-select-all')),
      );
      await tester.pumpAndSettle();
      expect(selectedText(2), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('persona-filter-all')),
      );
      await tester.pumpAndSettle();
      expect(selectedText(2), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('persona-select-all')),
      );
      await tester.pumpAndSettle();
      expect(selectedText(4), findsOneWidget);

      // All shown are selected: the toggle clears them.
      await tester.tap(
        find.byKey(const ValueKey<String>('persona-select-all')),
      );
      await tester.pumpAndSettle();
      expect(selectedText(0), findsOneWidget);
    });

    testWidgets('a visibility all the selected have is disabled', (
      tester,
    ) async {
      await pumpSettings(tester, personas: mixed);
      await tester.longPress(find.text('Pub One'));
      await tester.pumpAndSettle();

      expect(barButtonEnabled(tester, 'persona-bulk-public'), isFalse);
      expect(barButtonEnabled(tester, 'persona-bulk-unlisted'), isTrue);
      expect(barButtonEnabled(tester, 'persona-bulk-private'), isTrue);

      await tester.tap(find.text('Unl One'));
      await tester.pumpAndSettle();
      expect(barButtonEnabled(tester, 'persona-bulk-public'), isTrue);
    });

    testWidgets('Unlisted applies at once in one request, and Undo puts back', (
      tester,
    ) async {
      final _MockDioAdapter adapter = _MockDioAdapter();
      await pumpSettings(tester, personas: mixed, adapter: adapter);
      await tester.longPress(find.text('Pub One'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Priv One'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('persona-bulk-unlisted')),
      );
      await settle(tester);

      expect(
        find.byKey(const ValueKey<String>('persona-bulk-confirm')),
        findsNothing,
      );
      expect(patched(adapter), <Object?>[
        <String, Object?>{
          'personas': <Map<String, String>>[
            <String, String>{'id': 'pub', 'visibility': 'unlisted'},
            <String, String>{'id': 'priv', 'visibility': 'unlisted'},
          ],
        },
      ]);
      expect(
        find.byKey(const ValueKey<String>('persona-selection-bar')),
        findsNothing,
      );

      final ProviderContainer container = containerOf(tester);
      final FluxerToast toast = container.read(toastProvider).last.toast;
      expect(toast.message, testL10n.fork.personaBulkNowUnlisted(2));
      expect(toast.action?.label, testL10n.fork.personaUndo);

      toast.action!.onPressed();
      await settle(tester);

      expect(patched(adapter), hasLength(2));
      expect(patched(adapter).last, <String, Object?>{
        'personas': <Map<String, String>>[
          <String, String>{'id': 'pub', 'visibility': 'public'},
          <String, String>{'id': 'priv', 'visibility': 'private'},
        ],
      });
    });

    testWidgets(
      'Public asks first; Cancel sends nothing and keeps the selection',
      (tester) async {
        final _MockDioAdapter adapter = _MockDioAdapter();
        await pumpSettings(tester, personas: mixed, adapter: adapter);
        await tester.longPress(find.text('Unl One'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey<String>('persona-bulk-public')),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(testL10n.fork.personaBulkConfirmPublicTitle(1)),
          findsOneWidget,
        );
        await tester.tap(find.text(testL10n.cancel));
        await tester.pumpAndSettle();
        expect(adapter.requests, isEmpty);
        expect(selectedText(1), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey<String>('persona-bulk-public')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey<String>('persona-bulk-confirm')),
        );
        await settle(tester);
        expect(patched(adapter), hasLength(1));
      },
    );

    testWidgets('Private asks first', (tester) async {
      await pumpSettings(tester, personas: mixed);
      await tester.longPress(find.text('Unl One'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('persona-bulk-private')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(testL10n.fork.personaBulkConfirmPrivateTitle(1)),
        findsOneWidget,
      );
      expect(
        find.text(testL10n.fork.personaBulkConfirmPrivateBody),
        findsOneWidget,
      );
    });

    testWidgets('Delete asks, then deletes all in one request', (tester) async {
      final _MockDioAdapter adapter = _MockDioAdapter();
      await pumpSettings(tester, personas: mixed, adapter: adapter);
      await tester.longPress(find.text('Unl One'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unl Two'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('persona-bulk-delete')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(testL10n.fork.personaBulkConfirmDeleteTitle(2)),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('persona-bulk-confirm')),
      );
      await settle(tester);

      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.path, '/users/@me/personas/bulk-delete');
      expect(adapter.requests.single.data, <String, Object?>{
        'persona_ids': <String>['unl', 'unl2'],
      });
      expect(find.text('Unl One'), findsNothing);
      expect(find.text('Unl Two'), findsNothing);
      expect(
        containerOf(tester).read(toastProvider).last.toast.message,
        testL10n.fork.personaBulkDeleted(2),
      );
    });

    testWidgets('a failure says so and keeps the selection', (tester) async {
      final _MockDioAdapter adapter = _MockDioAdapter()..status = 500;
      await pumpSettings(tester, personas: mixed, adapter: adapter);
      await tester.longPress(find.text('Unl One'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('persona-bulk-private')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('persona-bulk-confirm')),
      );
      await settle(tester);

      expect(adapter.requests, hasLength(1));
      expect(selectedText(1), findsOneWidget);
      final FluxerToast toast = containerOf(
        tester,
      ).read(toastProvider).last.toast;
      expect(toast.message, testL10n.fork.personaBulkFailed);
      expect(toast.variant, FluxerToastVariant.danger);
    });

    testWidgets('opened from the gallery: unlisted ones, ready to select', (
      tester,
    ) async {
      await pumpSettings(tester, personas: mixed, launchFromGallery: true);

      expect(selectedText(0), findsOneWidget);
      expect(find.text('Unl One'), findsOneWidget);
      expect(find.text('Pub One'), findsNothing);
      // Only once.
      expect(containerOf(tester).read(personaSettingsLaunchProvider), isNull);
    });
  });
}
