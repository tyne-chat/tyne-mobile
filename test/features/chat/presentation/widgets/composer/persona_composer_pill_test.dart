// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/composer/persona_composer_pill.dart';
import 'package:fluxer_app/features/profile/data/known_personas.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/domain/persona_settings.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../helpers/pump_fluxer_app.dart';

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

class _FakeMyPersonasNotifier extends MyPersonasNotifier {
  _FakeMyPersonasNotifier(this._initial);

  final List<Persona> _initial;

  @override
  AsyncValue<List<Persona>> build() => AsyncData(_initial);

  @override
  Future<void> reloadSilently() async {}
}

/// A persona list that has not loaded (tyne-chat/tyne#30), for an account
/// that had personas when it last did, or not.
class _LoadingMyPersonasNotifier extends MyPersonasNotifier {
  _LoadingMyPersonasNotifier({required this.had});

  final bool had;

  @override
  AsyncValue<List<Persona>> build() => const AsyncLoading();

  @override
  bool get hadPersonas => had;

  @override
  Future<void> reloadSilently() async {}
}

class _FakeActivePersonaNotifier extends ActivePersonaNotifier {
  _FakeActivePersonaNotifier({this.initialLatchedId});

  final String? initialLatchedId;

  @override
  ActivePersonaState build() => ActivePersonaState(
    isLatched: initialLatchedId != null,
    activePersonaId: initialLatchedId,
  );
}

class _FakePersonaSettingsNotifier extends PersonaSettingsNotifier {
  @override
  AsyncValue<PersonaSettings> build() => const AsyncData(PersonaSettings());

  @override
  Future<void> reloadSilently() async {}
}

/// The colour of the ring around the pill's avatar (tyne-chat/tyne#626).
Color _ringColor(WidgetTester tester) {
  final Container ring = tester.widget<Container>(
    find
        .byWidgetPredicate(
          (Widget widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).shape == BoxShape.circle &&
              (widget.decoration! as BoxDecoration).border != null,
        )
        .first,
  );
  return ((ring.decoration! as BoxDecoration).border! as Border).top.color;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const personaAlpha = Persona(
    id: 'p_alpha',
    name: 'Alpha Alter',
    pronouns: 'they/them',
    personaTags: [PersonaTag(prefix: 'a:', suffix: '')],
  );

  const personaBeta = Persona(
    id: 'p_beta',
    name: 'Beta Alter',
    pronouns: 'she/her',
    personaTags: [PersonaTag(prefix: '[', suffix: ']')],
  );

  final allPersonas = [personaAlpha, personaBeta];

  Widget buildTestBed({
    List<Persona> personas = const [],
    String? latchedPersonaId,
    String text = '',
    bool hasAttachments = false,
    bool listLoaded = true,
    bool hadPersonas = true,
    KnownPersona? knownLatched,
  }) {
    return pumpFluxerApp(
      overrides: [
        userSettingsViewModelProvider.overrideWith(_FakeUserSettings.new),
        if (listLoaded)
          myPersonasProvider.overrideWith(
            () => _FakeMyPersonasNotifier(personas),
          )
        else
          myPersonasProvider.overrideWith(
            () => _LoadingMyPersonasNotifier(had: hadPersonas),
          ),
        if (latchedPersonaId != null)
          knownPersonaProvider(
            latchedPersonaId,
          ).overrideWith((ref) => Stream<KnownPersona?>.value(knownLatched)),
        activePersonaProvider.overrideWith(
          () => _FakeActivePersonaNotifier(initialLatchedId: latchedPersonaId),
        ),
        personaSettingsProvider.overrideWith(_FakePersonaSettingsNotifier.new),
      ],
      child: Scaffold(
        body: Center(
          child: PersonaComposerPill(
            text: text,
            hasAttachments: hasAttachments,
          ),
        ),
      ),
    );
  }

  group('PersonaComposerPill', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders SizedBox.shrink when user has no personas', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestBed());
      await tester.pumpAndSettle();

      expect(find.byType(Tooltip), findsNothing);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets(
      'renders root user state with root tooltip when unlatched and no tag match',
      (tester) async {
        await tester.pumpWidget(
          buildTestBed(personas: allPersonas, text: 'Hello world'),
        );
        await tester.pumpAndSettle();

        final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
        expect(tooltip.message, 'Sending as @tester');

        // No lock badge, no tag badge, no ring
        expect(find.byIcon(PhosphorIconsBold.lockSimple), findsNothing);
        expect(find.byIcon(PhosphorIconsBold.tag), findsNothing);
        expect(_ringColor(tester), Colors.transparent);
      },
    );

    testWidgets('renders latched persona without a badge, with the latched '
        'tooltip', (tester) async {
      await tester.pumpWidget(
        buildTestBed(
          personas: allPersonas,
          latchedPersonaId: 'p_alpha',
          text: 'Hello world',
        ),
      );
      await tester.pumpAndSettle();

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'Sending as Alpha Alter (Latched)');

      // No lock badge or ring (tyne-chat/tyne#626), and no tag badge
      expect(find.byIcon(PhosphorIconsBold.lockSimple), findsNothing);
      expect(find.byIcon(PhosphorIconsBold.tag), findsNothing);
      expect(_ringColor(tester), Colors.transparent);
    });

    testWidgets('renders tag matched persona without a badge, with the tag '
        'tooltip', (tester) async {
      await tester.pumpWidget(
        buildTestBed(personas: allPersonas, text: 'a: Hello world'),
      );
      await tester.pumpAndSettle();

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'Sending as Alpha Alter (Matched by tag)');

      // No tag badge, lock badge or ring (tyne-chat/tyne#626)
      expect(find.byIcon(PhosphorIconsBold.tag), findsNothing);
      expect(find.byIcon(PhosphorIconsBold.lockSimple), findsNothing);
      expect(_ringColor(tester), Colors.transparent);
    });

    testWidgets('tag match overrides latched persona indicator', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestBed(
          personas: allPersonas,
          latchedPersonaId: 'p_alpha',
          text: '[Hello world]',
        ),
      );
      await tester.pumpAndSettle();

      // Matched Beta Alter via [text]
      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'Sending as Beta Alter (Matched by tag)');

      expect(find.byIcon(PhosphorIconsBold.tag), findsNothing);
      expect(find.byIcon(PhosphorIconsBold.lockSimple), findsNothing);
    });

    testWidgets(
      'renders tag matched persona for emoji prefix tag, without a badge',
      (tester) async {
        const emojiPersona = Persona(
          id: 'p_dragon',
          name: 'Knightmoon',
          personaTags: [PersonaTag(prefix: '🐉')],
        );

        await tester.pumpWidget(
          buildTestBed(
            personas: [...allPersonas, emojiPersona],
            latchedPersonaId: 'p_alpha',
            text: '🐉 Hello world',
          ),
        );
        await tester.pumpAndSettle();

        final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
        expect(tooltip.message, 'Sending as Knightmoon (Matched by tag)');
        expect(find.byIcon(PhosphorIconsBold.tag), findsNothing);
        expect(find.byIcon(PhosphorIconsBold.lockSimple), findsNothing);
      },
    );

    testWidgets('tapping pill opens PersonaPickerSheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestBed(
          personas: allPersonas,
          latchedPersonaId: 'p_alpha',
          text: 'Hello world',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PersonaComposerPill));
      await tester.pumpAndSettle();

      expect(find.text('Select Persona'), findsOneWidget);
    });

    // tyne-chat/tyne#30: before the list loads, a selected persona still
    // decides the send, so the pill stays and opens the picker, where the
    // account can be chosen again.
    testWidgets(
      'stays while a persona is selected and the list has not loaded, drawn '
      'from the device copy',
      (tester) async {
        await tester.pumpWidget(
          buildTestBed(
            listLoaded: false,
            latchedPersonaId: 'p_alpha',
            knownLatched: const KnownPersona(
              id: 'p_alpha',
              name: 'Alpha Alter',
            ),
          ),
        );
        await tester.pumpAndSettle();

        final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
        expect(tooltip.message, 'Sending as Alpha Alter (Latched)');
        expect(find.byIcon(PhosphorIconsBold.lockSimple), findsNothing);
      },
    );

    testWidgets('shows the account while the list has not loaded and nobody '
        'is selected', (tester) async {
      await tester.pumpWidget(buildTestBed(listLoaded: false));
      await tester.pumpAndSettle();

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'Sending as @tester');
      expect(find.byIcon(PhosphorIconsBold.lockSimple), findsNothing);
    });

    testWidgets('is hidden while the list has not loaded for an account that '
        'never had personas', (tester) async {
      await tester.pumpWidget(
        buildTestBed(listLoaded: false, hadPersonas: false),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Tooltip), findsNothing);
    });
  });
}
