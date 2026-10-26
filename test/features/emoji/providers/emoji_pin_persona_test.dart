import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/emoji/providers/emoji_pin_persona.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';

const Persona _bob = Persona(
  id: '1001',
  name: 'Bob',
  personaTags: [PersonaTag(prefix: 'B:')],
);
const Persona _alice = Persona(
  id: '1002',
  name: 'Alice',
  personaTags: [PersonaTag(prefix: 'A:')],
);

class _FakePersonas extends MyPersonasNotifier {
  _FakePersonas(this._personas);
  final List<Persona> _personas;

  @override
  AsyncValue<List<Persona>> build() => AsyncData(_personas);
}

class _FakeActivePersona extends ActivePersonaNotifier {
  _FakeActivePersona(this._state);
  final ActivePersonaState _state;

  @override
  ActivePersonaState build() => _state;
}

class _FakeChat extends ChatViewModel {
  _FakeChat({required this.channelId, this.draft = ''});
  final String channelId;
  final String draft;

  @override
  ChatViewState build() =>
      ChatViewState.empty.copyWith(channelId: channelId, messageText: draft);
}

class _UnreadableChat extends ChatViewModel {
  @override
  ChatViewState build() => throw StateError('the chat was read');
}

ProviderContainer _container({
  List<Persona> personas = const [_bob, _alice],
  ActivePersonaState active = const ActivePersonaState(),
  ChatViewModel Function()? chat,
}) {
  final ProviderContainer container = ProviderContainer(
    overrides: [
      myPersonasProvider.overrideWith(() => _FakePersonas(personas)),
      activePersonaProvider.overrideWith(() => _FakeActivePersona(active)),
      chatViewModelProvider.overrideWith(
        chat ?? () => _FakeChat(channelId: 'c1'),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('is the account, reading nothing else, without personas', () {
    final ProviderContainer container = _container(
      personas: const [],
      active: const ActivePersonaState(
        activePersonaId: '1001',
        isLatched: true,
      ),
      chat: _UnreadableChat.new,
    );

    expect(emojiPinPersonaIdFor(container.read, 'c1'), isNull);
  });

  test('is the persona selected for every channel', () {
    final ProviderContainer container = _container(
      active: const ActivePersonaState(
        activePersonaId: '1001',
        isLatched: true,
      ),
    );

    expect(emojiPinPersonaIdFor(container.read, 'c1'), '1001');
    expect(emojiPinPersonaIdFor(container.read, 'c2'), '1001');
    expect(emojiPinPersonaIdFor(container.read, null), '1001');
  });

  test('is the account when a persona is chosen but not selected', () {
    final ProviderContainer container = _container(
      active: const ActivePersonaState(activePersonaId: '1001'),
    );

    expect(emojiPinPersonaIdFor(container.read, 'c1'), isNull);
  });

  test("is each channel's own persona when they are kept per channel", () {
    final ProviderContainer container = _container(
      active: const ActivePersonaState(
        scope: PersonaScope.channel,
        channelPersonaIds: {'c2': '1002'},
      ),
    );

    expect(emojiPinPersonaIdFor(container.read, 'c1'), isNull);
    expect(emojiPinPersonaIdFor(container.read, 'c2'), '1002');
    expect(emojiPinPersonaIdFor(container.read, null), isNull);
  });

  test("is the persona a tag in the open channel's draft names", () {
    final ProviderContainer container = _container(
      active: const ActivePersonaState(
        activePersonaId: '1001',
        isLatched: true,
      ),
      chat: () => _FakeChat(channelId: 'c1', draft: 'A: hello'),
    );

    expect(emojiPinPersonaIdFor(container.read, 'c1'), '1002');
    // The draft belongs to the open channel only.
    expect(emojiPinPersonaIdFor(container.read, 'c2'), '1001');
  });
}
