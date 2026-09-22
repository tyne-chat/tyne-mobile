// Fork: tests the fork adds, kept out of upstream's user_profile_view_test.dart so that file stays as
// upstream has it.

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/presentation/widgets/user_profile_view.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button.dart';
import 'package:fluxer_app/features/ui/toast/fluxer_toast_overlay.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/utils/fluxer_haptics.dart';

import '../../../../helpers/open_test_database.dart';
import '../../../../helpers/test_l10n.dart';
import 'user_profile_view_test.dart' hide main;

class _FakeMyPersonasNotifier extends MyPersonasNotifier {
  _FakeMyPersonasNotifier(this._initial);
  final List<Persona> _initial;

  @override
  AsyncValue<List<Persona>> build() => AsyncValue.data(_initial);
}

/// Personas that have not arrived, because the load is running or has failed.
class _UnloadedPersonas extends MyPersonasNotifier {
  _UnloadedPersonas(this._state);
  final AsyncValue<List<Persona>> _state;

  /// How often the list was asked for.
  static int loads = 0;

  @override
  AsyncValue<List<Persona>> build() {
    loads++;
    return _state;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The test above opens the app's own database and never closes it.
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    FluxerHaptics.enabled = false;
  });

  tearDown(() {
    FluxerHaptics.enabled = true;
  });

  testWidgets(
    'own persona profile resolves from myPersonasProvider and displays edit button',
    (tester) async {
      final ScrollController scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      const testPersona = Persona(
        id: 'persona_1',
        name: 'Sneaks Test',
        bio: 'Sneaky bio',
        personaTags: [PersonaTag(prefix: 'Snk:')],
      );

      final colorTheme = buildDarkColorTheme();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...forkUpstream.overrides(),
            myPersonasProvider.overrideWith(
              () => _FakeMyPersonasNotifier([testPersona]),
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
                body: UserProfileView(
                  userId: forkKUserId,
                  personaId: 'persona_1',
                  autoFocusNote: false,
                  scrollController: scrollController,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sneaks Test'), findsOneWidget);
      expect(find.text(testL10n.fork.personaEditPersona), findsOneWidget);
    },
  );

  Future<void> pumpOwnPersonaProfile(
    WidgetTester tester,
    AsyncValue<List<Persona>> personas,
  ) async {
    final ScrollController scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    _UnloadedPersonas.loads = 0;

    final colorTheme = buildDarkColorTheme();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...forkUpstream.overrides(),
          // With no persona loaded the view looks in the device's database.
          fluxerDatabaseProvider.overrideWithValue(openTestDatabase()),
          myPersonasProvider.overrideWith(() => _UnloadedPersonas(personas)),
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
              body: UserProfileView(
                userId: forkKUserId,
                personaId: 'persona_1',
                autoFocusNote: false,
                scrollController: scrollController,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('Edit does not open before the personas have loaded', (
    tester,
  ) async {
    await pumpOwnPersonaProfile(tester, const AsyncValue.loading());

    await tester.tap(find.byType(FluxerButton).last, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(TextField), findsNothing);
    await releaseTestWidgetTree(tester);
  });

  testWidgets('Edit asks for the personas again after a failed load', (
    tester,
  ) async {
    await pumpOwnPersonaProfile(
      tester,
      AsyncValue.error(Exception('offline'), StackTrace.empty),
    );
    final int loads = _UnloadedPersonas.loads;

    await tester.tap(find.text(testL10n.fork.personaEditPersona));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(TextField), findsNothing);
    expect(_UnloadedPersonas.loads, loads + 1);
    await releaseTestWidgetTree(tester);
  });
}
