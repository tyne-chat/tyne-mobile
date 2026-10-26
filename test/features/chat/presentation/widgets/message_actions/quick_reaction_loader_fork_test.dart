// Fork: tests the fork adds, kept out of upstream's quick_reaction_loader_test.dart so that file stays as
// upstream has it.
// Root ProviderScope built by a helper; the lint only exempts a
// ProviderScope written inline in pumpWidget.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart'
    show FluxerDatabase;
import 'package:fluxer_app/core/limits/instance_limit_provider.dart';
import 'package:fluxer_app/core/limits/limit_key.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/message_actions/quick_reaction_loader.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/message_actions/quick_reaction_row.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/chat/providers/pickers/emoji_picker_provider.dart';
import 'package:fluxer_app/features/emoji/domain/emoji_pins.dart';
import 'package:fluxer_app/features/emoji/providers/emoji_pins_provider.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/utils/emoji/emoji_registry.dart';

import '../../../../../helpers/open_test_database.dart';

const Persona _bob = Persona(id: '1001', name: 'Bob');

class _FakePersonas extends MyPersonasNotifier {
  @override
  AsyncValue<List<Persona>> build() => const AsyncData([_bob]);
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

class _FakeEmojiPins extends EmojiPinsNotifier {
  _FakeEmojiPins(this._pins);
  final EmojiPins _pins;

  @override
  Future<EmojiPins> build() async => _pins;
}

String _surrogates(String name) => EmojiRegistry.entryByName(name)!.surrogates;

List<String> _describe(List<QuickReactionItem> items) => [
  for (final item in items)
    switch (item) {
      UnicodeQuickReaction(:final emoji) => emoji,
      CustomQuickReaction(:final emoji) => 'custom:${emoji.id}',
    },
];

late FluxerDatabase _database;

/// The row's items in channel `c1`, with `fire` pinned for the account and
/// `rofl` for Bob, and `sob` the most used emoji.
Future<List<String>> _load(
  WidgetTester tester, {
  required ActivePersonaState active,
}) async {
  final EmojiPins pins = EmojiPins.empty
      .withPin('unicode:fire')!
      .withPin('unicode:rofl', personaId: _bob.id)!;
  late WidgetRef capturedRef;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        fluxerDatabaseProvider.overrideWithValue(_database),
        instanceFeatureEnabledProvider(
          LimitKeys.featureGlobalExpressions,
        ).overrideWithValue(false),
        rankedEmojiUsageKeysProvider.overrideWithValue(
          const AsyncData<List<String>>(['unicode:sob']),
        ),
        emojiPinsProvider.overrideWith(() => _FakeEmojiPins(pins)),
        myPersonasProvider.overrideWith(_FakePersonas.new),
        activePersonaProvider.overrideWith(() => _FakeActivePersona(active)),
        chatViewModelProvider.overrideWith(_FakeChat.new),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          capturedRef = ref;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  final List<QuickReactionItem>? items = await tester
      .runAsync<List<QuickReactionItem>?>(
        () =>
            loadQuickReactionItems(capturedRef, channelId: 'c1', guildId: null),
      );
  return _describe(items!);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(EmojiRegistry.preload);

  setUp(() {
    _database = openTestDatabase();
  });

  // tyne-chat/tyne#237: as on the web, the active persona's pins follow the
  // account's.
  testWidgets("puts the account's pins, then the active persona's, first", (
    tester,
  ) async {
    final List<String> items = await _load(
      tester,
      active: ActivePersonaState(activePersonaId: _bob.id, isLatched: true),
    );

    expect(items.take(3), [
      _surrogates('fire'),
      _surrogates('rofl'),
      _surrogates('sob'),
    ]);
  });

  testWidgets("leaves a persona's pins out when writing as the account", (
    tester,
  ) async {
    final List<String> items = await _load(
      tester,
      active: const ActivePersonaState(),
    );

    expect(items.take(2), [_surrogates('fire'), _surrogates('sob')]);
    expect(items, isNot(contains(_surrogates('rofl'))));
  });

  testWidgets('leaves out the pins of a persona selected in another channel', (
    tester,
  ) async {
    final List<String> items = await _load(
      tester,
      active: ActivePersonaState(
        scope: PersonaScope.channel,
        channelPersonaIds: {'c2': _bob.id},
      ),
    );

    expect(items, isNot(contains(_surrogates('rofl'))));
  });
}
