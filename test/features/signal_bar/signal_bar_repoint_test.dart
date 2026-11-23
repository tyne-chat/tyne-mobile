// Re-pointing the account's signals to the persona it writes as
// (tyne-chat/tyne#310). One persona change used to send one PUT per lit
// signal, all at once, up to fifty, against a toggle bucket of 30 per 10 s
// and the global limit whose overflow signs the session out
// (tyne-chat/tyne#114). A re-point the server refused came back with the
// channel's answer and went out again at the next keystroke. Now one
// `PUT /users/@me/signals/persona` names the chat, and a re-point that did not
// take waits ten seconds for that chat and persona.
//
// Requests go through the real repository to signal_bar_server_fixture.dart
// and are counted, with the data missing and with the request failing. No
// sleeps: fake_async moves the clock the notifier reads.

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/signal_bar/data/signal_bar_repository.dart';
import 'package:fluxer_app/features/signal_bar/domain/signal_bar_models.dart';
import 'package:fluxer_app/features/signal_bar/providers/signal_bar_providers.dart';

import 'signal_bar_server_fixture.dart';

const String _chat = 'c1';
const String _other = 'c2';
const Duration _tick = Duration(milliseconds: 1);

/// How many signals the account has lit in a chat: more than the toggle
/// bucket's 30 per 10 s would have let through one by one.
const int _litCount = 40;

const SignalPersona _wren = SignalPersona(id: 'p1', name: 'Wren');
const SignalPersona _kit = SignalPersona(id: 'p2', name: 'Kit');

/// Runs [body] on a fake clock with a container whose repository talks to
/// [server], as [kSignalTestMe].
void _withContainer(
  SignalBarTestServer server,
  void Function(FakeAsync async, ProviderContainer container) body,
) {
  fakeAsync((FakeAsync async) {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        signalBarRepositoryProvider.overrideWithValue(server.repository()),
      ],
    );
    container.read(currentUserIdProvider.notifier).set(kSignalTestMe);
    body(async, container);
    container.dispose();
    async.flushTimers();
  });
}

ChannelSignalsNotifier _signals(ProviderContainer container) =>
    container.read(channelSignalsProvider.notifier);

/// Loads [channelId] and lets the answer land.
void _load(FakeAsync async, ProviderContainer container, String channelId) {
  unawaited(_signals(container).loadChannel(channelId));
  async.elapse(Duration.zero);
}

/// The account's [_litCount] signals, lit as [personaId].
List<Map<String, Object?>> _ownSignals({String? personaId}) =>
    <Map<String, Object?>>[
      for (int i = 0; i < _litCount; i++)
        signalEntryJson('s$i', kSignalTestMe, personaId: personaId),
    ];

/// A change of text in [channelId]'s composer, writing as [persona], and what
/// it sends.
void _type(
  FakeAsync async,
  ProviderContainer container,
  SignalPersona? persona, {
  String channelId = _chat,
}) {
  _signals(
    container,
  ).affirmPersona(channelId, userId: kSignalTestMe, persona: persona);
  async.elapse(Duration.zero);
}

/// The personas the account's signals in [channelId] show, as a set.
Set<String?> _ownPersonas(ProviderContainer container, String channelId) =>
    <String?>{
      for (final SignalEntry entry
          in container.read(channelSignalsProvider)[channelId] ??
              const <SignalEntry>[])
        if (entry.userId == kSignalTestMe) entry.personaId,
    };

/// The `CHANNEL_SIGNAL_UPDATE` the server sends for [entries].
Map<String, dynamic> _event(
  String channelId,
  List<Map<String, Object?>> entries,
) => <String, dynamic>{
  'channel_id': channelId,
  'bar_version': 3,
  'added': entries,
  'removed': <Object?>[],
};

void main() {
  group('one request per persona change (tyne-chat/tyne#310)', () {
    test('every own signal in the chat is re-pointed at once, with one PUT '
        'naming that chat alone', () {
      final SignalBarTestServer server = SignalBarTestServer()
        ..lit[_chat] = <Map<String, Object?>>[
          signalEntryJson('s0', 'someone', personaId: 'theirs'),
          ..._ownSignals(),
        ]
        ..lit[_other] = _ownSignals();
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        _load(async, container, _chat);
        _load(async, container, _other);

        _signals(
          container,
        ).affirmPersona(_chat, userId: kSignalTestMe, persona: _wren);
        // Shown before the server answers.
        expect(_ownPersonas(container, _chat), <String?>{'p1'});
        expect(
          container
              .read(channelSignalsProvider)[_chat]!
              .firstWhere((SignalEntry e) => e.userId == 'someone')
              .personaId,
          'theirs',
        );
        expect(
          container
              .read(channelSignalsProvider)[_chat]!
              .map((SignalEntry e) => e.signalId),
          <String>['s0', for (int i = 0; i < _litCount; i++) 's$i'],
        );
        async.elapse(Duration.zero);

        expect(server.writes, <String>['PUT /users/@me/signals/persona']);
        expect(server.repointBodies.single, <String, Object?>{
          'persona_id': 'p1',
          'channel_ids': <String>[_chat],
        });
        // Another chat's signals are not this chat's business.
        expect(_ownPersonas(container, _other), <String?>{null});

        // Further keystrokes as the same persona find nothing to change.
        for (int i = 0; i < 5; i++) {
          _type(async, container, _wren);
        }
        expect(server.writes, hasLength(1));
        expect(server.channelGets, hasLength(2));
      });
    });

    test('back to the account names no persona', () {
      final SignalBarTestServer server = SignalBarTestServer()
        ..lit[_chat] = _ownSignals(personaId: 'p1');
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        _load(async, container, _chat);

        _type(async, container, null);

        expect(server.repointBodies.single, <String, Object?>{
          'persona_id': null,
          'channel_ids': <String>[_chat],
        });
        expect(_ownPersonas(container, _chat), <String?>{null});
      });
    });

    test('nothing is sent when nothing is stale', () {
      final SignalBarTestServer server = SignalBarTestServer()
        ..lit[_chat] = <Map<String, Object?>>[
          ..._ownSignals(personaId: 'p1'),
          signalEntryJson('s0', 'someone', personaId: 'p9'),
        ]
        ..lit[_other] = <Map<String, Object?>>[
          signalEntryJson('s0', 'someone'),
        ];
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        _load(async, container, _chat);
        _load(async, container, _other);

        // Already that persona; only someone else's lit; a chat not loaded.
        _type(async, container, _wren);
        _type(async, container, _kit, channelId: _other);
        _type(async, container, _kit, channelId: 'c3');
        async.elapse(const Duration(minutes: 1));

        expect(server.writes, isEmpty);
        expect(server.channelGets, hasLength(2));
      });
    });
  });

  group('a re-point that did not take (tyne-chat/tyne#310)', () {
    test('a refused PUT asks for the chat once, and is not sent again for '
        'ten seconds', () {
      final SignalBarTestServer server = SignalBarTestServer()
        ..lit[_chat] = _ownSignals()
        ..failWrites = true;
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        _load(async, container, _chat);

        _type(async, container, _wren);
        expect(server.repoints, hasLength(1));
        expect(server.channelGets, hasLength(2));
        // The chat's answer shows what the server holds.
        expect(_ownPersonas(container, _chat), <String?>{null});

        for (int i = 0; i < 9; i++) {
          async.elapse(const Duration(seconds: 1));
          _type(async, container, _wren);
        }
        async.elapse(const Duration(seconds: 1) - _tick);
        _type(async, container, _wren);
        expect(server.repoints, hasLength(1));
        expect(server.channelGets, hasLength(2));
        // Nothing shown that is not sent.
        expect(_ownPersonas(container, _chat), <String?>{null});

        server.failWrites = false;
        async.elapse(_tick);
        _type(async, container, _wren);
        expect(server.repoints, hasLength(2));
        expect(_ownPersonas(container, _chat), <String?>{'p1'});
        async.elapse(const Duration(minutes: 1));
        expect(server.channelGets, hasLength(2));
      });
    });

    test('a different persona within the ten seconds is sent', () {
      final SignalBarTestServer server = SignalBarTestServer()
        ..lit[_chat] = _ownSignals()
        ..unknownPersonas.add('p1');
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        _load(async, container, _chat);

        _type(async, container, _wren);
        _type(async, container, _wren);
        expect(server.repoints, hasLength(1));
        expect(server.channelGets, hasLength(2));

        async.elapse(const Duration(seconds: 1));
        _type(async, container, _kit);
        expect(server.repoints, hasLength(2));
        expect(server.repointBodies.last['persona_id'], 'p2');
        expect(_ownPersonas(container, _chat), <String?>{'p2'});

        // The refused persona still waits.
        _type(async, container, _wren);
        expect(server.repoints, hasLength(2));
        async.elapse(const Duration(minutes: 1));
        expect(server.channelGets, hasLength(2));
      });
    });

    test('with every request failing, one PUT and one GET, then nothing', () {
      final SignalBarTestServer server = SignalBarTestServer()
        ..lit[_chat] = _ownSignals();
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        _load(async, container, _chat);
        server
          ..failWrites = true
          ..failReads = true;

        for (int i = 0; i < 30; i++) {
          _type(async, container, _wren);
          async.elapse(const Duration(seconds: 1));
        }

        expect(server.repoints, hasLength(1));
        expect(server.channelGets, hasLength(2));
      });
    });

    test('accepted with nothing changed where the account may not light: '
        'one GET, and the same wait', () {
      final SignalBarTestServer server = SignalBarTestServer()
        ..lit[_chat] = _ownSignals()
        ..unlightable.add(_chat);
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        _load(async, container, _chat);

        for (int i = 0; i < 9; i++) {
          _type(async, container, _wren);
          async.elapse(const Duration(seconds: 1));
        }

        expect(server.repoints, hasLength(1));
        expect(server.channelGets, hasLength(2));
        expect(_ownPersonas(container, _chat), <String?>{null});
      });
    });

    test('accepted with nothing changed because the server had it so: the '
        'GET shows it, and nothing more is sent', () {
      final SignalBarTestServer server = SignalBarTestServer()
        ..lit[_chat] = _ownSignals();
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        _load(async, container, _chat);
        // Re-pointed from another device, and the event missed.
        server.lit[_chat] = _ownSignals(personaId: 'p1');

        _type(async, container, _wren);
        _type(async, container, _wren);
        async.elapse(const Duration(minutes: 1));

        expect(server.repoints, hasLength(1));
        expect(server.channelGets, hasLength(2));
        expect(_ownPersonas(container, _chat), <String?>{'p1'});
      });
    });

    test('a new gateway session forgets the refusal', () {
      final SignalBarTestServer server = SignalBarTestServer()
        ..lit[_chat] = _ownSignals()
        ..failWrites = true;
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        _load(async, container, _chat);
        _type(async, container, _wren);
        expect(server.repoints, hasLength(1));

        server.failWrites = false;
        _signals(container).invalidate();
        _load(async, container, _chat);
        _type(async, container, _wren);

        expect(server.repoints, hasLength(2));
        expect(_ownPersonas(container, _chat), <String?>{'p1'});
      });
    });

    test('an account change forgets the refusal', () {
      final SignalBarTestServer server = SignalBarTestServer()
        ..lit[_chat] = _ownSignals()
        ..failWrites = true;
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        _load(async, container, _chat);
        _type(async, container, _wren);
        expect(server.repoints, hasLength(1));

        server.failWrites = false;
        container.read(currentUserIdProvider.notifier)
          ..set('someone else')
          ..set(kSignalTestMe);
        _load(async, container, _chat);
        _type(async, container, _wren);

        expect(server.repoints, hasLength(2));
      });
    });
  });

  group('the check after an accepted re-point (tyne-chat/tyne#729)', () {
    test('with the event in time, nothing more is sent', () {
      final SignalBarTestServer server = SignalBarTestServer()
        ..lit[_chat] = _ownSignals();
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        _load(async, container, _chat);

        _type(async, container, _wren);
        _signals(
          container,
        ).handleChannelUpdate(_event(_chat, _ownSignals(personaId: 'p1')));
        async.elapse(const Duration(minutes: 1));

        expect(server.writes, hasLength(1));
        expect(server.channelGets, hasLength(1));
        expect(_ownPersonas(container, _chat), <String?>{'p1'});
      });
    });

    test('with the event missed, the strip already shows it and nothing more '
        'is sent', () {
      final SignalBarTestServer server = SignalBarTestServer()
        ..lit[_chat] = _ownSignals();
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        _load(async, container, _chat);

        _type(async, container, _wren);
        async.elapse(const Duration(minutes: 1));

        expect(server.writes, hasLength(1));
        expect(server.channelGets, hasLength(1));
      });
    });

    test('an older answer that brings the old persona back is asked for '
        'once', () {
      final SignalBarTestServer server = SignalBarTestServer()
        ..lit[_chat] = _ownSignals();
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        _load(async, container, _chat);

        _type(async, container, _wren);
        // What an answer to a request sent before the re-point would show.
        _signals(container).handleChannelUpdate(_event(_chat, _ownSignals()));
        expect(_ownPersonas(container, _chat), <String?>{null});

        async.elapse(kSignalWriteEventWait - _tick);
        expect(server.channelGets, hasLength(1));
        async.elapse(_tick);
        expect(server.channelGets, hasLength(2));
        expect(_ownPersonas(container, _chat), <String?>{'p1'});

        async.elapse(const Duration(minutes: 5));
        expect(server.channelGets, hasLength(2));
        expect(server.writes, hasLength(1));
      });
    });
  });
}
