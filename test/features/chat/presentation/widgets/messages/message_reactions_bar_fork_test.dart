// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: the reaction chips' part in persona reactions (tyne-chat/tyne#86): the
// caret on a chip of yours, and the tap that opens "Your reactions" instead of
// reacting.

import 'package:flutter/widgets.dart' as fw;
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/messages/message_reactions_bar.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/providers/multi_persona_reactions_provider.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../helpers/persona_reaction_fakes.dart';
import '../../../../../helpers/pump_fluxer_app.dart';

const Persona _bob = Persona(id: 'p_bob', name: 'Bob the Builder');

/// 👍 from the account and from Bob; 🎉 from other people only.
const Reaction _mine = Reaction(
  emoji: '👍',
  count: 3,
  hasReacted: true,
  meRoot: true,
  personaReactions: <String>['p_bob'],
);
const Reaction _theirs = Reaction(emoji: '🎉', count: 2);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeMyPersonas personasNotifier;
  late List<String> tapped;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tapped = <String>[];
  });

  Future<void> pumpBar(
    WidgetTester tester, {
    List<Reaction> reactions = const <Reaction>[_mine, _theirs],
    List<Persona> personas = const <Persona>[_bob],
    bool multi = true,
    String? messageId = kReactionTestMessageId,
  }) async {
    personasNotifier = FakeMyPersonas(personas);
    await tester.pumpWidget(
      pumpFluxerApp(
        overrides: [
          userSettingsViewModelProvider.overrideWith(
            FakeReactionUserSettings.new,
          ),
          myPersonasProvider.overrideWith(() => personasNotifier),
          chatViewModelProvider.overrideWith(
            () => FakeReactionChatViewModel(reactions: reactions),
          ),
          multiPersonaReactionsProvider.overrideWith(
            () => FixedMultiPersonaReactions(enabled: multi),
          ),
        ],
        child: Scaffold(
          body: MessageReactionsBar(
            reactions: reactions,
            channelId: kReactionTestChannelId,
            messageId: messageId,
            onReactionTap:
                (String emoji, {String? emojiId, bool animated = false}) =>
                    tapped.add(emoji),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  // A chip's count is the only "3" or "2" on the page.
  Finder chip(Reaction reaction) => find.text('${reaction.count}');
  final Finder caret = find.byIcon(PhosphorIconsBold.caretDown);

  group('the caret', () {
    testWidgets('marks the chip of an emoji you reacted with, and no other', (
      WidgetTester tester,
    ) async {
      await pumpBar(tester);

      expect(caret, findsOneWidget);
      // It follows the count of 👍, to the left of 🎉.
      expect(
        tester.getTopLeft(caret).dx,
        greaterThan(tester.getTopRight(chip(_mine)).dx),
      );
      expect(
        tester.getTopLeft(caret).dx,
        lessThan(tester.getTopLeft(chip(_theirs)).dx),
      );
    });

    testWidgets('takes the colour of the count', (WidgetTester tester) async {
      await pumpBar(tester);

      expect(
        tester.widget<Icon>(caret).color,
        tester.widget<fw.Text>(chip(_mine)).style?.color,
      );
    });

    testWidgets('is left out with the setting off', (
      WidgetTester tester,
    ) async {
      await pumpBar(tester, multi: false);

      expect(caret, findsNothing);
    });

    testWidgets('is left out for an account without personas', (
      WidgetTester tester,
    ) async {
      await pumpBar(
        tester,
        personas: const <Persona>[],
        reactions: const <Reaction>[
          Reaction(emoji: '👍', count: 3, hasReacted: true, meRoot: true),
        ],
      );

      expect(caret, findsNothing);
    });

    testWidgets('is left out where a tap cannot open the sheet', (
      WidgetTester tester,
    ) async {
      // System messages give the bar no message id.
      await pumpBar(tester, messageId: null);

      expect(caret, findsNothing);
      expect(personasNotifier.builds, 0);
    });

    testWidgets('asks for nothing on chips that are not yours', (
      WidgetTester tester,
    ) async {
      await pumpBar(tester, reactions: const <Reaction>[_theirs]);

      expect(caret, findsNothing);
      expect(personasNotifier.builds, 0);
    });

    testWidgets('asks for no personas with the setting off', (
      WidgetTester tester,
    ) async {
      await pumpBar(tester, multi: false);

      expect(personasNotifier.builds, 0);
    });
  });

  group('a tap', () {
    testWidgets('on your chip opens "Your reactions" and reacts to nothing', (
      WidgetTester tester,
    ) async {
      await pumpBar(tester);
      await tester.tap(chip(_mine));
      await tester.pumpAndSettle();

      expect(find.text('Your reactions'), findsOneWidget);
      expect(tapped, isEmpty);
    });

    testWidgets('on another chip reacts as before', (
      WidgetTester tester,
    ) async {
      await pumpBar(tester);
      await tester.tap(chip(_theirs));
      await tester.pumpAndSettle();

      expect(find.text('Your reactions'), findsNothing);
      expect(tapped, <String>['🎉']);
    });

    testWidgets('on your chip toggles as before with the setting off', (
      WidgetTester tester,
    ) async {
      await pumpBar(tester, multi: false);
      await tester.tap(chip(_mine));
      await tester.pumpAndSettle();

      expect(find.text('Your reactions'), findsNothing);
      expect(tapped, <String>['👍']);
    });

    testWidgets('on your chip toggles as before without personas', (
      WidgetTester tester,
    ) async {
      const Reaction own = Reaction(
        emoji: '👍',
        count: 3,
        hasReacted: true,
        meRoot: true,
      );
      await pumpBar(
        tester,
        personas: const <Persona>[],
        reactions: const <Reaction>[own],
      );
      await tester.tap(chip(own));
      await tester.pumpAndSettle();

      expect(find.text('Your reactions'), findsNothing);
      expect(tapped, <String>['👍']);
    });
  });
}
