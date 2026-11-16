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
import 'package:fluxer_app/features/profile/domain/imported_placeholder.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/presentation/widgets/imported_user_tag.dart';
import 'package:fluxer_app/features/profile/presentation/widgets/user_profile_relationship_button.dart';
import 'package:fluxer_app/features/profile/presentation/widgets/user_profile_view.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button.dart';
import 'package:fluxer_app/features/ui/toast/fluxer_toast_overlay.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/icons/phosphor.dart';
import 'package:fluxer_app/shared/utils/fluxer_haptics.dart';
import 'package:fluxer_dart/export.dart';

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

  group('imported placeholder accounts (tyne-chat/tyne#682)', () {
    UserProfileFullResponse profile({required int flags, bool bot = false}) =>
        UserProfileFullResponse(
          user: UserPartialResponse(
            id: forkKOtherUserId,
            username: 'generalstrax',
            discriminator: '4821',
            globalName: 'generalstrax',
            avatar: null,
            avatarColor: null,
            flags: flags,
            bot: bot,
          ),
          userProfile: const UserProfileFullResponseUserProfile(
            bio: null,
            pronouns: null,
            banner: null,
            accentColor: null,
          ),
          timezoneOffset: null,
        );

    Future<void> pumpProfile(
      WidgetTester tester, {
      required int flags,
      bool bot = false,
      bool popout = false,
    }) async {
      final ScrollController scrollController = ScrollController();
      addTearDown(scrollController.dispose);
      final colorTheme = buildDarkColorTheme();
      await tester.pumpWidget(
        ProviderScope(
          overrides: forkUpstream.otherUserOverrides(
            Future<UserProfileFullResponse?>.value(
              profile(flags: flags, bot: bot),
            ),
            null,
          ),
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
                  userId: forkKOtherUserId,
                  autoFocusNote: false,
                  popout: popout,
                  scrollController: scrollController,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    final Finder addFriend = find.descendant(
      of: find.byType(UserProfileRelationshipButton),
      matching: find.byType(PhosphorIcon),
    );

    test("the flag is the server's IMPORTED bit", () {
      expect(kForkUserFlagImported, 1073741824);
      expect(isImportedPlaceholder(kForkUserFlagImported | 1), isTrue);
      expect(isImportedPlaceholder(0), isFalse);
      expect(isImportedPlaceholder(null), isFalse);
    });

    testWidgets('a full profile shows the tag and offers no Message or Add '
        'friend', (tester) async {
      await pumpProfile(tester, flags: kForkUserFlagImported);

      expect(find.byType(ImportedUserTag), findsOneWidget);
      expect(
        find.text(testL10n.fork.importedUserTag.toUpperCase()),
        findsOneWidget,
      );
      expect(find.text(testL10n.userProfileMessage), findsNothing);
      expect(find.text(testL10n.userProfileVoiceCall), findsNothing);
      expect(addFriend, findsNothing);
      await releaseTestWidgetTree(tester);
    });

    testWidgets('an ordinary account keeps Message and Add friend', (
      tester,
    ) async {
      await pumpProfile(tester, flags: 0);

      expect(find.byType(ImportedUserTag), findsNothing);
      expect(find.text(testL10n.userProfileMessage), findsOneWidget);
      expect(addFriend, findsOneWidget);
      await releaseTestWidgetTree(tester);
    });

    testWidgets('the popout shows the tag and no Message', (tester) async {
      await pumpProfile(tester, flags: kForkUserFlagImported, popout: true);

      expect(find.byType(ImportedUserTag), findsOneWidget);
      expect(find.text(testL10n.userProfileMessage), findsNothing);
      await releaseTestWidgetTree(tester);
    });

    testWidgets('the popout of an ordinary account keeps Message', (
      tester,
    ) async {
      await pumpProfile(tester, flags: 0, popout: true);

      expect(find.byType(ImportedUserTag), findsNothing);
      expect(find.text(testL10n.userProfileMessage), findsOneWidget);
      await releaseTestWidgetTree(tester);
    });

    testWidgets('a bot the import made shows the tag, in the full profile '
        'and the popout', (tester) async {
      await pumpProfile(tester, flags: kForkUserFlagImported, bot: true);
      expect(find.byType(ImportedUserTag), findsOneWidget);
      expect(find.text(testL10n.userProfileMessage), findsNothing);
      await releaseTestWidgetTree(tester);

      await pumpProfile(
        tester,
        flags: kForkUserFlagImported,
        bot: true,
        popout: true,
      );
      expect(find.byType(ImportedUserTag), findsOneWidget);
      await releaseTestWidgetTree(tester);
    });

    testWidgets('another bot shows no Imported tag', (tester) async {
      await pumpProfile(tester, flags: 0, bot: true);
      expect(find.byType(ImportedUserTag), findsNothing);
      await releaseTestWidgetTree(tester);
    });
  });
}
