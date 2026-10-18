// Fork: tests of the fork-owned typing_personas_provider.dart (tyne-chat/tyne#136).
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/gateway/providers/gateway_event_providers.dart';
import 'package:fluxer_app/core/gateway/providers/typing_personas_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_dart/models/message_subprofile_response_schema.dart';

const MessageSubprofileResponseSchema _ruby = MessageSubprofileResponseSchema(
  id: 'persona-1',
  name: 'Ruby Rose',
);
const MessageSubprofileResponseSchema _jade = MessageSubprofileResponseSchema(
  id: 'persona-2',
  name: 'Jade',
);

ProviderContainer _container() {
  final ProviderContainer container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(currentUserIdProvider.notifier).set('me');
  return container;
}

/// What the gateway provider does for one TYPING_START.
void _typingStart(
  ProviderContainer container,
  String channelId,
  String userId,
  MessageSubprofileResponseSchema? subprofile,
) {
  container
      .read(typingIndicatorsProvider.notifier)
      .addTyping(channelId, userId);
  container
      .read(typingPersonasProvider.notifier)
      .record(channelId, userId, subprofile);
}

MessageSubprofileResponseSchema? _shown(
  ProviderContainer container,
  String channelId,
  String userId,
) => container.read(channelTypingSubprofileProvider((channelId, userId)));

void main() {
  test('shows the persona a user is typing as', () {
    final ProviderContainer container = _container();
    _typingStart(container, 'c1', 'u1', _ruby);

    expect(_shown(container, 'c1', 'u1'), same(_ruby));
    expect(_shown(container, 'c2', 'u1'), isNull);
  });

  test('typing as the account, or as another persona, replaces it', () {
    final ProviderContainer container = _container();
    _typingStart(container, 'c1', 'u1', _ruby);
    _typingStart(container, 'c1', 'u1', _jade);
    expect(_shown(container, 'c1', 'u1'), same(_jade));

    _typingStart(container, 'c1', 'u1', null);
    expect(_shown(container, 'c1', 'u1'), isNull);
    expect(container.read(typingPersonasProvider), isEmpty);
  });

  test('shows nothing once upstream stops showing the user typing', () {
    final ProviderContainer container = _container();
    _typingStart(container, 'c1', 'u1', _ruby);
    _typingStart(container, 'c1', 'u2', _jade);

    container.read(typingIndicatorsProvider.notifier).removeTyping('c1', 'u1');
    expect(_shown(container, 'c1', 'u1'), isNull);
    expect(_shown(container, 'c1', 'u2'), same(_jade));

    container.read(typingIndicatorsProvider.notifier).clearAll();
    expect(_shown(container, 'c1', 'u2'), isNull);
  });

  test('shows nothing after the typing expiry', () {
    fakeAsync((FakeAsync async) {
      final ProviderContainer container = ProviderContainer();
      container.read(currentUserIdProvider.notifier).set('me');
      _typingStart(container, 'c1', 'u1', _ruby);
      expect(_shown(container, 'c1', 'u1'), same(_ruby));

      async.elapse(kTypingExpiry + const Duration(milliseconds: 1));

      expect(_shown(container, 'c1', 'u1'), isNull);
      container.dispose();
    });
  });

  test('drops the entries of users who stopped typing', () {
    final ProviderContainer container = _container();
    _typingStart(container, 'c1', 'u1', _ruby);
    container.read(typingIndicatorsProvider.notifier).removeTyping('c1', 'u1');

    _typingStart(container, 'c2', 'u2', _jade);

    expect(
      container.read(typingPersonasProvider),
      <String, Map<String, MessageSubprofileResponseSchema>>{
        'c2': <String, MessageSubprofileResponseSchema>{'u2': _jade},
      },
    );
  });

  test('starts empty for the next signed-in user', () {
    final ProviderContainer container = _container();
    _typingStart(container, 'c1', 'u1', _ruby);
    expect(container.read(typingPersonasProvider), isNotEmpty);

    container.read(currentUserIdProvider.notifier).set('other');

    expect(container.read(typingPersonasProvider), isEmpty);
  });
}
