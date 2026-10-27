// Fork: tests the fork adds, kept out of upstream's composer_mention_controller_test.dart so that file stays as
// upstream has it.
// Root ProviderScope built by a helper; the lint only exempts a
// ProviderScope written inline in pumpWidget.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart'
    show KnownPersona;
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/chat/services/composer_mention_controller.dart';
import 'package:fluxer_app/features/profile/data/known_personas.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/features/profile/providers/public_persona_provider.dart';
import 'package:fluxer_app/l10n/fluxer_localizations_delegates.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/material_ui.dart';

import 'composer_mention_controller_test.dart' hide main;

const String _kUserId = '1481621807877361924';
const String _kOwnPersonaId = '1550229100331794432';
const String _kKnownPersonaId = '1550229100331794433';
const String _kUnknownPersonaId = '1550229100331794434';

class _FakeMyPersonasNotifier extends MyPersonasNotifier {
  @override
  AsyncValue<List<Persona>> build() => const AsyncValue.data(<Persona>[
    Persona(id: _kOwnPersonaId, name: 'Own', color: 0x00AAFF),
  ]);
}

/// Upstream's pump helper with the persona providers this file needs. A
/// widget watches the known persona, as a message mentioning it does in the
/// chat, so the composer finds it when it reads it.
Future<(ComposerMentionController, ProviderContainer)> _pumpWithPersonas(
  WidgetTester tester,
) async {
  final colorTheme = buildDarkColorTheme();
  ComposerMentionController? controller;
  late ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        myPersonasProvider.overrideWith(_FakeMyPersonasNotifier.new),
        knownPersonaProvider.overrideWith(
          (ref, String personaId) => Stream.value(
            personaId == _kKnownPersonaId
                ? const KnownPersona(
                    id: _kKnownPersonaId,
                    name: 'Known',
                    color: 0xFF8800,
                  )
                : null,
          ),
        ),
      ],
      child: MaterialApp(
        theme: buildFluxerTheme(
          colorTheme: colorTheme,
          textTheme: FluxerTextTheme.fromColors(colorTheme),
          layoutTheme: FluxerLayoutTheme.scaled(),
        ),
        localizationsDelegates: fluxerLocalizationsDelegates,
        supportedLocales: FluxerLocalizations.supportedLocales,
        home: Scaffold(
          body: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              container = ProviderScope.containerOf(context);
              ref
                ..watch(myPersonasProvider)
                ..watch(knownPersonaProvider(_kKnownPersonaId));
              controller ??= ComposerMentionController(ref: ref);
              return TextField(controller: controller);
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  addTearDown(() => controller?.dispose());
  return (controller!, container);
}

Color? _mentionColour(WidgetTester tester, String label) =>
    tester.widget<widgets.Text>(find.text(label)).style?.color;

Color _linkColour(WidgetTester tester) =>
    tester.element(find.byType(TextField)).colors.textLink;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'stores persona mention display label and renders wire text with personaId',
    (WidgetTester tester) async {
      final ComposerMentionController controller = await forkUpstream
          .pumpController(tester);

      controller.insertUserMentionPlaceholder(
        matchStart: 0,
        matchEnd: 0,
        userId: '1481621807877361924',
        personaId: '1550229100331794432',
        displayName: 'Bob the Fox',
      );
      await tester.pump();

      expect(find.text('@Bob the Fox'), findsOneWidget);
      expect(
        controller.toWireText().trim(),
        '<@1481621807877361924:1550229100331794432>',
      );
    },
  );

  testWidgets(
    'insertUserMentionPlaceholder with personaId replaces full autocomplete range',
    (WidgetTester tester) async {
      final ComposerMentionController controller = await forkUpstream
          .pumpController(tester);

      controller
        ..text = '@bob'
        ..selection = const TextSelection.collapsed(offset: 4)
        ..insertUserMentionPlaceholder(
          matchStart: 0,
          matchEnd: 4,
          userId: '1481621807877361924',
          personaId: '1550229100331794432',
          displayName: 'Bob the Fox',
        );
      await tester.pump();

      expect(find.text('@Bob the Fox'), findsOneWidget);
      expect(
        controller.toWireText().trim(),
        '<@1481621807877361924:1550229100331794432>',
      );
    },
  );

  // A persona mention in the composer takes the persona's colour, as in
  // messages (tyne-chat/tyne#241).
  testWidgets('a persona picked in the autocomplete is drawn in its colour', (
    WidgetTester tester,
  ) async {
    final (ComposerMentionController controller, _) = await _pumpWithPersonas(
      tester,
    );

    controller.insertUserMentionPlaceholder(
      matchStart: 0,
      matchEnd: 0,
      userId: _kUserId,
      personaId: _kUnknownPersonaId,
      displayName: 'Picked',
      personaColor: 0x112233,
    );
    await tester.pump();

    expect(_mentionColour(tester, '@Picked'), const Color(0xFF112233));
  });

  testWidgets('a draft names its persona mentions in their colours', (
    WidgetTester tester,
  ) async {
    final (ComposerMentionController controller, _) = await _pumpWithPersonas(
      tester,
    );

    await controller.applyWireText(
      '<@$_kUserId:$_kOwnPersonaId> <@$_kUserId:$_kKnownPersonaId>',
    );
    await tester.pump();

    expect(_mentionColour(tester, '@Own'), const Color(0xFF00AAFF));
    expect(_mentionColour(tester, '@Known'), const Color(0xFFFF8800));
  });

  testWidgets('a persona without a colour keeps the usual mention colour and '
      'nothing is fetched for it', (WidgetTester tester) async {
    final (ComposerMentionController controller, ProviderContainer container) =
        await _pumpWithPersonas(tester);

    controller.insertUserMentionPlaceholder(
      matchStart: 0,
      matchEnd: 0,
      userId: _kUserId,
      personaId: _kUnknownPersonaId,
      displayName: 'Plain',
    );
    await tester.pump();

    expect(_mentionColour(tester, '@Plain'), _linkColour(tester));
    expect(
      container.exists(
        publicPersonaProvider((
          userId: _kUserId,
          personaId: _kUnknownPersonaId,
        )),
      ),
      isFalse,
    );
  });

  testWidgets('a mention of an account keeps the usual mention colour', (
    WidgetTester tester,
  ) async {
    final (ComposerMentionController controller, _) = await _pumpWithPersonas(
      tester,
    );

    controller.insertUserMentionPlaceholder(
      matchStart: 0,
      matchEnd: 0,
      userId: _kUserId,
      displayName: 'account',
    );
    await tester.pump();

    expect(_mentionColour(tester, '@account'), _linkColour(tester));
  });
}
