// Fork: tests the fork adds, kept out of upstream's emoji_info_bottom_sheet_test.dart so that file stays as
// upstream has it.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/emoji/domain/emoji_info_data.dart';
import 'package:fluxer_app/features/emoji/domain/emoji_pins.dart';
import 'package:fluxer_app/features/emoji/presentation/sheets/emoji_info_bottom_sheet.dart';
import 'package:fluxer_app/features/emoji/providers/emoji_pins_provider.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/utils/emoji_registry.dart';
import 'package:riverpod/src/framework.dart' show Override;

import '../../../../helpers/test_l10n.dart';
import 'emoji_info_bottom_sheet_test.dart' hide main;

class _FakeMyPersonasNotifier extends MyPersonasNotifier {
  _FakeMyPersonasNotifier(this._personas);
  final List<Persona> _personas;

  @override
  AsyncValue<List<Persona>> build() => AsyncData(_personas);

  @override
  Future<void> reloadSilently() async {}
}

class _FakeEmojiPinsNotifier extends EmojiPinsNotifier {
  _FakeEmojiPinsNotifier(this._pins);
  final EmojiPins _pins;
  final List<(String, String?)> toggles = <(String, String?)>[];

  @override
  Future<EmojiPins> build() async => _pins;

  @override
  Future<bool> togglePin(String key, {String? personaId}) async {
    toggles.add((key, personaId));
    return true;
  }
}

class _FakeActivePersona extends ActivePersonaNotifier {
  _FakeActivePersona(this._state);
  final ActivePersonaState _state;

  @override
  ActivePersonaState build() => _state;
}

class _FakeChat extends ChatViewModel {
  @override
  ChatViewState build() => ChatViewState.empty.copyWith(channelId: 'c1');
}

/// The persona selection and the open chat, which the sheet reads when it is
/// opened without a persona.
List<Override> _personaInUse([
  ActivePersonaState active = const ActivePersonaState(),
]) => [
  activePersonaProvider.overrideWith(() => _FakeActivePersona(active)),
  chatViewModelProvider.overrideWith(_FakeChat.new),
];

Widget _buildTestApp({
  required Widget child,
  List<Override> extraOverrides = const [],
}) {
  return ProviderScope(
    overrides: extraOverrides,
    child: forkUpstream.buildTestApp(child: child),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await EmojiRegistry.preload();
  });

  testWidgets(
    'shows "React as..." and opens PersonaReactAsSheet when messageId and personas present',
    (tester) async {
      const testPersona = Persona(id: 'p1', name: 'Bob the Fox');
      final entry = EmojiRegistry.allEmojis.first;
      final data = EmojiInfoData(name: entry.surrogates);

      await tester.pumpWidget(
        _buildTestApp(
          extraOverrides: [
            myPersonasProvider.overrideWith(
              () => _FakeMyPersonasNotifier(const [testPersona]),
            ),
            ..._personaInUse(),
          ],
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  unawaited(
                    EmojiInfoBottomSheet.show(
                      context,
                      emoji: data,
                      messageId: 'msg-1',
                    ),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text(testL10n.fork.chatReactAs), findsOneWidget);

      await tester.tap(find.text(testL10n.fork.chatReactAs));
      await tester.pumpAndSettle();

      expect(find.text('Bob the Fox'), findsWidgets);
    },
  );

  group('pins', () {
    const Persona persona = Persona(id: '1001', name: 'Bob the Fox');

    Future<_FakeEmojiPinsNotifier> openSheet(
      WidgetTester tester, {
      required EmojiPins pins,
      String? personaId,
      String? channelId,
      ActivePersonaState active = const ActivePersonaState(),
    }) async {
      final _FakeEmojiPinsNotifier notifier = _FakeEmojiPinsNotifier(pins);
      final EmojiEntry entry = EmojiRegistry.allEmojis.first;
      await tester.pumpWidget(
        _buildTestApp(
          extraOverrides: [
            myPersonasProvider.overrideWith(
              () => _FakeMyPersonasNotifier(const [persona]),
            ),
            emojiPinsProvider.overrideWith(() => notifier),
            ..._personaInUse(active),
          ],
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => openEmojiInfoBottomSheet(
                context,
                emoji: EmojiInfoData(name: entry.surrogates),
                channelId: channelId,
                personaId: personaId,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      return notifier;
    }

    String keyOfFirstEmoji() =>
        'unicode:${EmojiRegistry.allEmojis.first.primaryName}';

    testWidgets('pins for the account, and offers no persona pin without '
        'a persona', (tester) async {
      final _FakeEmojiPinsNotifier notifier = await openSheet(
        tester,
        pins: EmojiPins.empty,
      );

      expect(find.text(testL10n.fork.emojiPinForPersona), findsNothing);
      await tester.tap(find.text(testL10n.fork.emojiPin));
      await tester.pumpAndSettle();

      expect(notifier.toggles, <(String, String?)>[(keyOfFirstEmoji(), null)]);
    });

    testWidgets('offers unpin for a pinned emoji, and pins for the persona '
        'the picker writes as', (tester) async {
      final _FakeEmojiPinsNotifier notifier = await openSheet(
        tester,
        pins: EmojiPins.empty.withPin(keyOfFirstEmoji())!,
        personaId: persona.id,
      );

      expect(find.text(testL10n.fork.emojiUnpin), findsOneWidget);
      await tester.tap(find.text(testL10n.fork.emojiPinForPersona));
      await tester.pumpAndSettle();

      expect(notifier.toggles, <(String, String?)>[
        (keyOfFirstEmoji(), persona.id),
      ]);
    });

    testWidgets('offers no persona pin for a persona that is not the '
        "account's", (tester) async {
      await openSheet(tester, pins: EmojiPins.empty, personaId: '1999');

      expect(find.text(testL10n.fork.emojiPin), findsOneWidget);
      expect(find.text(testL10n.fork.emojiPinForPersona), findsNothing);
    });

    // tyne-chat/tyne#237: a message's quick reactions open the sheet without a
    // persona.
    testWidgets('opened without a persona, pins for the persona in use in '
        'the channel', (tester) async {
      final _FakeEmojiPinsNotifier notifier = await openSheet(
        tester,
        pins: EmojiPins.empty,
        channelId: 'c1',
        active: ActivePersonaState(
          activePersonaId: persona.id,
          isLatched: true,
        ),
      );

      await tester.tap(find.text(testL10n.fork.emojiPinForPersona));
      await tester.pumpAndSettle();

      expect(notifier.toggles, <(String, String?)>[
        (keyOfFirstEmoji(), persona.id),
      ]);
    });

    testWidgets('offers no persona pin when the picker writes as the account', (
      tester,
    ) async {
      await openSheet(
        tester,
        pins: EmojiPins.empty,
        personaId: '0',
        channelId: 'c1',
        active: ActivePersonaState(
          activePersonaId: persona.id,
          isLatched: true,
        ),
      );

      expect(find.text(testL10n.fork.emojiPin), findsOneWidget);
      expect(find.text(testL10n.fork.emojiPinForPersona), findsNothing);
    });
  });
}
