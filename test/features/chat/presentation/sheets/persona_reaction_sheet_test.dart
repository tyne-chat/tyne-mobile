// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: the two sheets that list the account's identities for one emoji on one
// message (tyne-chat/tyne#86): "Your reactions", opened by a tap on a reaction
// chip, and "React as...", opened from an emoji's menu.

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/sheets/persona_react_as_sheet.dart';
import 'package:fluxer_app/features/chat/presentation/sheets/persona_reaction_sheet.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/providers/multi_persona_reactions_provider.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/persona_reaction_fakes.dart';
import '../../../../helpers/pump_fluxer_app.dart';

const Persona _bob = Persona(
  id: 'p_bob',
  name: 'Bob the Builder',
  pronouns: 'he/him',
);
const Persona _alice = Persona(
  id: 'p_alice',
  name: 'Alice Wonder',
  pronouns: 'she/her',
);
const Persona _cleo = Persona(
  id: 'p_cleo',
  name: 'Cleo',
  personaTags: <PersonaTag>[PersonaTag(prefix: 'c:')],
);

/// 👍 from the account and from Bob, and from one other person.
const Reaction _thumbs = Reaction(
  emoji: '👍',
  count: 3,
  hasReacted: true,
  meRoot: true,
  personaReactions: <String>['p_bob'],
);

Finder _row(String? id) =>
    find.byKey(ValueKey<String>('persona-reaction-row-${id ?? 'account'}'));

Finder _in(Finder row, Finder what) => find.descendant(of: row, matching: what);

/// Whether the row's pill shows the reaction as made.
bool _reacted(WidgetTester tester, String? id) {
  final bool on = tester.any(
    _in(_row(id), find.byIcon(PhosphorIconsBold.check)),
  );
  final bool off = tester.any(
    _in(_row(id), find.byIcon(PhosphorIconsBold.plus)),
  );
  expect(on, isNot(off), reason: 'the pill of ${id ?? 'the account'}');
  return on;
}

/// The ids of the rows on screen, from the top; null is the account.
List<String?> _rowOrder(WidgetTester tester, List<String?> ids) {
  final List<String?> shown = <String?>[
    for (final String? id in ids)
      if (tester.any(_row(id))) id,
  ];
  return shown..sort(
    (String? a, String? b) =>
        tester.getTopLeft(_row(a)).dy.compareTo(tester.getTopLeft(_row(b)).dy),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeReactionChatViewModel chat;
  late FakeMyPersonas personasNotifier;
  late int reactedCalls;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    reactedCalls = 0;
  });

  /// A page with one button that opens the sheet for 👍 on the message.
  Future<void> open(
    WidgetTester tester, {
    required bool reactAs,
    List<Persona> personas = const <Persona>[_bob, _alice, _cleo],
    List<Reaction> reactions = const <Reaction>[_thumbs],
    String? currentId,
    bool multi = true,
    ActivePersonaState active = const ActivePersonaState(),
  }) async {
    chat = FakeReactionChatViewModel(
      reactions: reactions,
      currentId: currentId,
    );
    personasNotifier = FakeMyPersonas(personas);
    // A tall phone, so that every row of the longest list here is on screen.
    tester.view.physicalSize = const Size(412, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      pumpFluxerApp(
        overrides: [
          userSettingsViewModelProvider.overrideWith(
            FakeReactionUserSettings.new,
          ),
          myPersonasProvider.overrideWith(() => personasNotifier),
          chatViewModelProvider.overrideWith(() => chat),
          multiPersonaReactionsProvider.overrideWith(
            () => FixedMultiPersonaReactions(enabled: multi),
          ),
          activePersonaProvider.overrideWith(() => FixedActivePersona(active)),
        ],
        child: Scaffold(
          body: Builder(
            builder: (BuildContext context) => Center(
              child: ElevatedButton(
                key: const ValueKey<String>('open'),
                onPressed: () => reactAs
                    ? PersonaReactAsSheet.show(
                        context,
                        channelId: kReactionTestChannelId,
                        messageId: kReactionTestMessageId,
                        emoji: '👍',
                        onReacted: () => reactedCalls++,
                      )
                    : showOwnReactionsSheet(
                        context,
                        channelId: kReactionTestChannelId,
                        messageId: kReactionTestMessageId,
                        emoji: '👍',
                      ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey<String>('open')));
    await tester.pumpAndSettle();
  }

  Future<void> tapRow(WidgetTester tester, String? id) async {
    await tester.tap(_row(id));
    await tester.pumpAndSettle();
  }

  Future<void> done(WidgetTester tester) async {
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
  }

  const List<String?> everyone = <String?>[null, 'p_bob', 'p_alice', 'p_cleo'];

  group('"Your reactions"', () {
    testWidgets('opens short: who reacted, and a way to the others', (
      WidgetTester tester,
    ) async {
      await open(tester, reactAs: false);

      expect(find.text('Your reactions'), findsOneWidget);
      expect(_rowOrder(tester, everyone), <String?>[null, 'p_bob']);
      expect(_reacted(tester, null), isTrue);
      expect(_reacted(tester, 'p_bob'), isTrue);
      expect(find.text('React as someone else...'), findsOneWidget);
      expect(find.text('EVERYONE ELSE'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Done'), findsOneWidget);
      // The account is what a plain reaction is sent as here.
      expect(_in(_row(null), find.text('CURRENT')), findsOneWidget);
      expect(_in(_row(null), find.text('Account')), findsOneWidget);
      expect(_in(_row('p_bob'), find.text('CURRENT')), findsNothing);
    });

    testWidgets('sends no request for the personas', (
      WidgetTester tester,
    ) async {
      await open(tester, reactAs: false);
      await tapRow(tester, 'p_bob');
      await done(tester);

      expect(personasNotifier.reloads, 0);
    });

    testWidgets('lists the current persona although it has not reacted', (
      WidgetTester tester,
    ) async {
      await open(tester, reactAs: false, currentId: 'p_alice');

      expect(_rowOrder(tester, everyone), <String?>['p_alice', null, 'p_bob']);
      expect(_reacted(tester, 'p_alice'), isFalse);
      expect(_in(_row('p_alice'), find.text('CURRENT')), findsOneWidget);
      expect(_in(_row(null), find.text('CURRENT')), findsNothing);
    });

    testWidgets('grows to everyone, without raising the keyboard', (
      WidgetTester tester,
    ) async {
      await open(tester, reactAs: false);
      await tester.tap(find.text('React as someone else...'));
      await tester.pumpAndSettle();

      expect(find.text('React as someone else...'), findsNothing);
      expect(find.text('EVERYONE ELSE'), findsOneWidget);
      expect(_rowOrder(tester, everyone), <String?>[
        null,
        'p_bob',
        'p_alice',
        'p_cleo',
      ]);
      expect(_reacted(tester, 'p_alice'), isFalse);
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.testTextInput.isVisible, isFalse);
      expect(
        tester.widget<TextField>(find.byType(TextField)).autofocus,
        isFalse,
      );
    });

    testWidgets('grows on the screen with its list', (
      WidgetTester tester,
    ) async {
      await open(tester, reactAs: false);
      final double top = tester
          .getRect(find.byType(PersonaReactionSheetBody))
          .top;
      // The tap ends upstream's sheet drag, which pins its resting height.
      await tester.tap(find.text('React as someone else...'));
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.byType(PersonaReactionSheetBody)).top,
        lessThan(top),
      );
      for (final String? id in everyone) {
        expect(
          tester.getRect(_row(id)).bottom,
          lessThanOrEqualTo(tester.view.physicalSize.height),
        );
      }
    });

    testWidgets('has nothing to grow to when every identity is listed', (
      WidgetTester tester,
    ) async {
      await open(tester, reactAs: false, personas: const <Persona>[_bob]);

      expect(_rowOrder(tester, everyone), <String?>[null, 'p_bob']);
      expect(find.text('React as someone else...'), findsNothing);
    });

    testWidgets('a row takes that reaction off and stays where it is', (
      WidgetTester tester,
    ) async {
      await open(tester, reactAs: false);
      await tapRow(tester, 'p_bob');

      expect(chat.toggles, <ReactionToggle>[
        (emoji: '👍', personaId: 'p_bob', explicitRoot: false),
      ]);
      expect(chat.onlyChoices, isEmpty);
      // Still open, Bob still second, now offered instead of made.
      expect(find.text('Your reactions'), findsOneWidget);
      expect(_rowOrder(tester, everyone), <String?>[null, 'p_bob']);
      expect(_reacted(tester, 'p_bob'), isFalse);
      expect(_reacted(tester, null), isTrue);

      await tapRow(tester, 'p_bob');
      expect(chat.toggles, hasLength(2));
      expect(_reacted(tester, 'p_bob'), isTrue);
    });

    testWidgets('the account row toggles the account, whoever is current', (
      WidgetTester tester,
    ) async {
      await open(tester, reactAs: false, currentId: 'p_alice');
      await tapRow(tester, null);

      expect(chat.toggles, <ReactionToggle>[
        (emoji: '👍', personaId: null, explicitRoot: true),
      ]);
      expect(_reacted(tester, null), isFalse);
      expect(_reacted(tester, 'p_alice'), isFalse);
    });

    testWidgets('stays open with its rows when the last reaction goes', (
      WidgetTester tester,
    ) async {
      await open(tester, reactAs: false);
      await tapRow(tester, 'p_bob');
      await tapRow(tester, null);

      expect(chat.reactionFor('👍')?.hasReacted, isFalse);
      expect(find.text('Your reactions'), findsOneWidget);
      expect(_rowOrder(tester, everyone), <String?>[null, 'p_bob']);
      expect(_reacted(tester, null), isFalse);
      expect(_reacted(tester, 'p_bob'), isFalse);
    });

    testWidgets('several can be added one after the other', (
      WidgetTester tester,
    ) async {
      await open(tester, reactAs: false);
      await tester.tap(find.text('React as someone else...'));
      await tester.pumpAndSettle();
      await tapRow(tester, 'p_alice');
      await tapRow(tester, 'p_cleo');

      expect(chat.toggles.map((ReactionToggle t) => t.personaId), <String>[
        'p_alice',
        'p_cleo',
      ]);
      expect(chat.reactionFor('👍')?.personaReactions, <String>[
        'p_bob',
        'p_alice',
        'p_cleo',
      ]);
      // Nobody moved up to the reacted rows.
      expect(_rowOrder(tester, everyone), <String?>[
        null,
        'p_bob',
        'p_alice',
        'p_cleo',
      ]);
    });

    testWidgets('Done closes it', (WidgetTester tester) async {
      await open(tester, reactAs: false);
      await done(tester);

      expect(find.text('Your reactions'), findsNothing);
      expect(chat.toggles, isEmpty);
    });

    testWidgets('a row says whether it is on to a screen reader', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await open(tester, reactAs: false, currentId: 'p_alice');

      expect(
        tester.getSemantics(_row('p_bob')),
        isSemantics(isButton: true, hasToggledState: true, isToggled: true),
      );
      expect(
        tester.getSemantics(_row('p_alice')),
        isSemantics(isButton: true, hasToggledState: true, isToggled: false),
      );
      handle.dispose();
    });
  });

  group('"React as..."', () {
    testWidgets('opens with everyone and a search field', (
      WidgetTester tester,
    ) async {
      await open(tester, reactAs: true);

      expect(find.text('React as...'), findsOneWidget);
      expect(find.text('Your reactions'), findsNothing);
      expect(find.text('React as someone else...'), findsNothing);
      expect(_rowOrder(tester, everyone), <String?>[
        null,
        'p_bob',
        'p_alice',
        'p_cleo',
      ]);
      expect(_reacted(tester, null), isTrue);
      expect(_reacted(tester, 'p_bob'), isTrue);
      expect(_reacted(tester, 'p_alice'), isFalse);
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.testTextInput.isVisible, isFalse);
    });

    testWidgets('asks for the personas once per opening', (
      WidgetTester tester,
    ) async {
      await open(tester, reactAs: true);
      await tapRow(tester, 'p_alice');
      await tester.enterText(find.byType(TextField), 'bob');
      await tester.pumpAndSettle();

      expect(personasNotifier.reloads, 1);
    });

    testWidgets('search finds names, pronouns and tags', (
      WidgetTester tester,
    ) async {
      await open(tester, reactAs: true);

      await tester.enterText(find.byType(TextField), 'alice');
      await tester.pumpAndSettle();
      expect(_rowOrder(tester, everyone), <String?>['p_alice']);
      expect(find.text('EVERYONE ELSE'), findsNothing);

      await tester.enterText(find.byType(TextField), 'HE/HIM');
      await tester.pumpAndSettle();
      expect(_rowOrder(tester, everyone), <String?>['p_bob']);

      await tester.enterText(find.byType(TextField), 'c:');
      await tester.pumpAndSettle();
      expect(_rowOrder(tester, everyone), <String?>['p_cleo']);

      await tester.enterText(find.byType(TextField), 'root');
      await tester.pumpAndSettle();
      expect(_rowOrder(tester, everyone), <String?>[null]);

      await tester.enterText(find.byType(TextField), 'nobody at all');
      await tester.pumpAndSettle();
      expect(_rowOrder(tester, everyone), isEmpty);
      expect(find.text('No matching personas found.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(_rowOrder(tester, everyone), hasLength(4));
      expect(find.text('EVERYONE ELSE'), findsOneWidget);
    });

    testWidgets('a row toggles and the sheet stays until Done', (
      WidgetTester tester,
    ) async {
      await open(tester, reactAs: true);
      await tapRow(tester, 'p_alice');

      expect(chat.toggles, <ReactionToggle>[
        (emoji: '👍', personaId: 'p_alice', explicitRoot: false),
      ]);
      expect(_reacted(tester, 'p_alice'), isTrue);
      expect(find.text('React as...'), findsOneWidget);
      // The emoji picker under it closes only once the sheet has.
      expect(reactedCalls, 0);

      await done(tester);
      expect(find.text('React as...'), findsNothing);
      expect(reactedCalls, 1);
    });

    testWidgets('Done with nothing changed leaves the picker open', (
      WidgetTester tester,
    ) async {
      await open(tester, reactAs: true);
      await done(tester);

      expect(find.text('React as...'), findsNothing);
      expect(reactedCalls, 0);
      expect(chat.toggles, isEmpty);
    });

    group('with "React as several personas at once" off', () {
      testWidgets('a row is one choice, and closes the sheet', (
        WidgetTester tester,
      ) async {
        await open(tester, reactAs: true, multi: false);
        await tapRow(tester, 'p_alice');

        expect(chat.onlyChoices, <({String emoji, String? personaId})>[
          (emoji: '👍', personaId: 'p_alice'),
        ]);
        expect(chat.toggles, isEmpty);
        expect(find.text('React as...'), findsNothing);
        expect(reactedCalls, 1);
      });

      testWidgets('the account can be the choice', (WidgetTester tester) async {
        await open(tester, reactAs: true, multi: false, currentId: 'p_bob');
        await tapRow(tester, null);

        expect(chat.onlyChoices, <({String emoji, String? personaId})>[
          (emoji: '👍', personaId: null),
        ]);
        expect(find.text('React as...'), findsNothing);
      });
    });

    group('recent personas', () {
      final List<Persona> many = <Persona>[
        for (int i = 0; i < 8; i++)
          Persona(
            id: 'p_$i',
            name: 'Persona $i',
            // The two highest were used, 7 more than 6.
            useCount: i >= 6 ? i : 0,
            lastUsedAtMs: i >= 6
                ? DateTime(2026, 11, 9).millisecondsSinceEpoch + i
                : null,
          ),
      ];
      Finder recent(String id) =>
          find.byKey(ValueKey<String>('persona-reaction-recent-$id'));

      testWidgets('lead the list of a large system', (
        WidgetTester tester,
      ) async {
        await open(tester, reactAs: true, personas: many);

        expect(find.text('RECENT PERSONAS'), findsOneWidget);
        expect(recent('p_7'), findsOneWidget);
        expect(recent('p_6'), findsOneWidget);
        expect(recent('p_0'), findsNothing);
        expect(
          tester.getTopLeft(recent('p_7')).dx,
          lessThan(tester.getTopLeft(recent('p_6')).dx),
        );
      });

      testWidgets('count what this device used since the list loaded', (
        WidgetTester tester,
      ) async {
        await open(
          tester,
          reactAs: true,
          personas: many,
          active: ActivePersonaState(
            frecencyUsage: <String, ({int count, int lastUsedAtMs})>{
              'p_2': (
                count: 1,
                lastUsedAtMs: DateTime(2026, 11, 9).millisecondsSinceEpoch,
              ),
            },
          ),
        );

        expect(recent('p_2'), findsOneWidget);
        expect(recent('p_7'), findsOneWidget);
      });

      testWidgets('toggle like a row', (WidgetTester tester) async {
        await open(tester, reactAs: true, personas: many);
        await tester.tap(recent('p_7'));
        await tester.pumpAndSettle();

        expect(chat.toggles, <ReactionToggle>[
          (emoji: '👍', personaId: 'p_7', explicitRoot: false),
        ]);
        expect(_reacted(tester, 'p_7'), isTrue);
        expect(find.text('React as...'), findsOneWidget);
      });

      testWidgets('step aside for a search', (WidgetTester tester) async {
        await open(tester, reactAs: true, personas: many);
        await tester.enterText(find.byType(TextField), 'persona 3');
        await tester.pumpAndSettle();

        expect(find.text('RECENT PERSONAS'), findsNothing);
        expect(recent('p_7'), findsNothing);
        expect(_row('p_3'), findsOneWidget);
      });

      testWidgets('are left out of a system that fits on the screen', (
        WidgetTester tester,
      ) async {
        await open(tester, reactAs: true, personas: many.sublist(2));

        expect(find.text('RECENT PERSONAS'), findsNothing);
        expect(recent('p_7'), findsNothing);
      });

      testWidgets('are left out when only one was ever used', (
        WidgetTester tester,
      ) async {
        await open(
          tester,
          reactAs: true,
          personas: <Persona>[
            ...many.take(7),
            const Persona(id: 'p_7', name: 'Persona 7'),
          ],
        );

        expect(find.text('RECENT PERSONAS'), findsNothing);
      });

      testWidgets('wait until "Your reactions" has grown', (
        WidgetTester tester,
      ) async {
        await open(tester, reactAs: false, personas: many);
        expect(find.text('RECENT PERSONAS'), findsNothing);

        await tester.tap(find.text('React as someone else...'));
        await tester.pumpAndSettle();
        expect(find.text('RECENT PERSONAS'), findsOneWidget);
      });
    });
  });

  group('a tap on a reaction chip', () {
    Future<bool> tapChip(
      WidgetTester tester, {
      required Reaction chip,
      List<Persona> personas = const <Persona>[_bob, _alice],
      List<Reaction> reactions = const <Reaction>[_thumbs],
      bool multi = true,
      String? messageId = kReactionTestMessageId,
      String channelId = kReactionTestChannelId,
    }) async {
      chat = FakeReactionChatViewModel(reactions: reactions);
      personasNotifier = FakeMyPersonas(personas);
      late bool opened;
      await tester.pumpWidget(
        pumpFluxerApp(
          overrides: [
            userSettingsViewModelProvider.overrideWith(
              FakeReactionUserSettings.new,
            ),
            myPersonasProvider.overrideWith(() => personasNotifier),
            chatViewModelProvider.overrideWith(() => chat),
            multiPersonaReactionsProvider.overrideWith(
              () => FixedMultiPersonaReactions(enabled: multi),
            ),
          ],
          child: Scaffold(
            body: Builder(
              builder: (BuildContext context) => ElevatedButton(
                key: const ValueKey<String>('chip'),
                onPressed: () => opened = openOwnReactionsSheetOnChipTap(
                  context,
                  channelId: channelId,
                  messageId: messageId,
                  reaction: chip,
                ),
                child: const Text('Chip'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey<String>('chip')));
      await tester.pumpAndSettle();
      expect(
        find.text('Your reactions'),
        opened ? findsOneWidget : findsNothing,
      );
      return opened;
    }

    testWidgets('opens "Your reactions" on an emoji of yours', (
      WidgetTester tester,
    ) async {
      expect(await tapChip(tester, chip: _thumbs), isTrue);
      expect(chat.toggles, isEmpty);
    });

    testWidgets('reacts as before on an emoji that is not yours', (
      WidgetTester tester,
    ) async {
      const Reaction others = Reaction(emoji: '🎉', count: 2);
      expect(
        await tapChip(
          tester,
          chip: others,
          reactions: const <Reaction>[_thumbs, others],
        ),
        isFalse,
      );
    });

    testWidgets('reacts as before with the setting off', (
      WidgetTester tester,
    ) async {
      expect(await tapChip(tester, chip: _thumbs, multi: false), isFalse);
    });

    testWidgets('reacts as before for an account without personas', (
      WidgetTester tester,
    ) async {
      const Reaction mine = Reaction(
        emoji: '👍',
        count: 1,
        hasReacted: true,
        meRoot: true,
      );
      expect(
        await tapChip(
          tester,
          chip: mine,
          personas: const <Persona>[],
          reactions: const <Reaction>[mine],
        ),
        isFalse,
      );
    });

    testWidgets('reacts as before on a message without an id', (
      WidgetTester tester,
    ) async {
      expect(await tapChip(tester, chip: _thumbs, messageId: null), isFalse);
    });

    testWidgets('reacts as before for a message of another channel', (
      WidgetTester tester,
    ) async {
      expect(
        await tapChip(tester, chip: _thumbs, channelId: 'chan_other'),
        isFalse,
      );
    });

    testWidgets("goes by the channel's reaction, not by an older chip", (
      WidgetTester tester,
    ) async {
      // The chip was built when the account had reacted; since then it took
      // the reaction off, and `Reaction ==` did not rebuild the chip.
      expect(
        await tapChip(
          tester,
          chip: _thumbs,
          reactions: const <Reaction>[Reaction(emoji: '👍', count: 1)],
        ),
        isFalse,
      );
    });
  });
}
