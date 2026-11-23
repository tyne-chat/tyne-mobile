// A session can miss the signal bar's events (tyne-chat/tyne#313), and then
// the phone showed what it had until the next READY or a restart:
//
// - tyne-chat/tyne#729: a lit signal shows only with its event. With the event
//   missed, the strip stayed unlit, and every further tap was a PUT the server
//   accepted for a signal already lit, which sends no event at all. Now a
//   write the strip does not show two seconds after the server accepted it
//   asks for the channel once.
// - tyne-chat/tyne#447: a channel answered once was not asked for again
//   before READY. Now entering it asks again, at most once per channel every
//   ten seconds, whatever the answer, so switching chats sends no burst.
//
// Each test counts the requests, with the data missing and with the request
// failing. No sleeps: fake_async and the widget tester's clock. Dio starts a
// request on a zero-length timer, so the fake clock is moved by zero, not
// only its microtasks flushed.

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/chat/providers/channel/channel_message_permissions_provider.dart';
import 'package:fluxer_app/features/signal_bar/data/signal_bar_repository.dart';
import 'package:fluxer_app/features/signal_bar/domain/signal_bar_models.dart';
import 'package:fluxer_app/features/signal_bar/presentation/signal_bar_strip.dart';
import 'package:fluxer_app/features/signal_bar/presentation/signals_everywhere_sheet.dart';
import 'package:fluxer_app/features/signal_bar/providers/signal_bar_providers.dart';
import 'package:fluxer_app/material_ui.dart';

import '../../helpers/pump_fluxer_app.dart';
import 'signal_bar_server_fixture.dart';

const String _chat = 'c1';
const String _other = 'c2';
const Duration _tick = Duration(milliseconds: 1);

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

/// The account's entry for [signalId] in [channelId], as the strip shows it.
SignalEntry? _mine(
  ProviderContainer container,
  String channelId,
  String signalId,
) => container
    .read(channelSignalsProvider)[channelId]
    ?.where(
      (SignalEntry e) => e.signalId == signalId && e.userId == kSignalTestMe,
    )
    .firstOrNull;

/// Loads [channelId] and lets the answer and what follows it land.
void _load(FakeAsync async, ProviderContainer container, String channelId) {
  unawaited(_signals(container).loadChannel(channelId));
  async.elapse(Duration.zero);
}

void main() {
  group('a write the strip does not show (tyne-chat/tyne#729)', () {
    test('a lit signal whose event is missed shows after one request', () {
      final SignalBarTestServer server = SignalBarTestServer();
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        _load(async, container, _chat);
        expect(server.channelGets, hasLength(1));

        unawaited(
          _signals(container).activate(_chat, 'reading', personaId: 'p1'),
        );
        async.elapse(Duration.zero);
        expect(server.writes, <String>['PUT /channels/c1/signals/reading/@me']);
        // No event: the strip still shows it off.
        expect(_mine(container, _chat, 'reading'), isNull);

        async.elapse(kSignalWriteEventWait - _tick);
        expect(server.channelGets, hasLength(1));
        async
          ..elapse(_tick)
          ..elapse(Duration.zero);
        expect(server.channelGets, hasLength(2));
        expect(_mine(container, _chat, 'reading')?.personaId, 'p1');

        async.elapse(const Duration(minutes: 5));
        expect(server.channelGets, hasLength(2));
      });
    });

    test('a tap the server answers with no event at all is not lost', () {
      // The server already has it lit, the strip does not: a PUT for a signal
      // lit as that persona only renews it and sends nothing.
      final SignalBarTestServer server = SignalBarTestServer();
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        _load(async, container, _chat);
        server.lit[_chat] = <Map<String, Object?>>[
          signalEntryJson('reading', kSignalTestMe),
        ];

        unawaited(_signals(container).activate(_chat, 'reading'));
        async
          ..elapse(kSignalWriteEventWait)
          ..elapse(Duration.zero);

        expect(_mine(container, _chat, 'reading'), isNotNull);
        expect(server.channelGets, hasLength(2));
      });
    });

    test('with the event in time, nothing more is sent', () {
      final SignalBarTestServer server = SignalBarTestServer();
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        _load(async, container, _chat);
        unawaited(_signals(container).activate(_chat, 'reading'));
        async.elapse(Duration.zero);
        _signals(container).handleChannelUpdate(<String, dynamic>{
          'channel_id': _chat,
          'bar_version': 3,
          'added': <Object?>[signalEntryJson('reading', kSignalTestMe)],
          'removed': <Object?>[],
        });

        async.elapse(const Duration(minutes: 1));

        expect(_mine(container, _chat, 'reading'), isNotNull);
        expect(server.channelGets, hasLength(1));
      });
    });

    test('a burst of taps shares one request', () {
      final SignalBarTestServer server = SignalBarTestServer();
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        _load(async, container, _chat);
        final ChannelSignalsNotifier signals = _signals(container);
        unawaited(signals.activate(_chat, 'reading'));
        async.elapse(const Duration(milliseconds: 500));
        unawaited(signals.activate(_chat, 'done'));
        async.elapse(const Duration(milliseconds: 500));
        unawaited(signals.activate(_chat, 'reading', personaId: 'p2'));
        async
          ..elapse(kSignalWriteEventWait)
          ..elapse(Duration.zero);

        expect(server.writes, hasLength(3));
        expect(server.channelGets, hasLength(2));
        expect(_mine(container, _chat, 'reading')?.personaId, 'p2');
        expect(_mine(container, _chat, 'done'), isNotNull);
      });
    });

    test('a refused write asks once, and is not checked again', () {
      final SignalBarTestServer server = SignalBarTestServer();
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        _load(async, container, _chat);
        server.failWrites = true;

        unawaited(_signals(container).activate(_chat, 'reading'));
        async
          ..elapse(Duration.zero)
          ..elapse(const Duration(minutes: 1));

        expect(server.writes, hasLength(1));
        expect(server.channelGets, hasLength(2));
      });
    });

    test('when the check fails, nothing is asked again', () {
      final SignalBarTestServer server = SignalBarTestServer();
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        _load(async, container, _chat);
        unawaited(_signals(container).activate(_chat, 'reading'));
        async.elapse(Duration.zero);
        server.failReads = true;

        async
          ..elapse(kSignalWriteEventWait)
          ..elapse(Duration.zero)
          ..elapse(const Duration(minutes: 5));

        expect(server.channelGets, hasLength(2));
      });
    });

    test('a channel not loaded is not asked for', () {
      final SignalBarTestServer server = SignalBarTestServer();
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        unawaited(_signals(container).activate(_chat, 'reading'));
        async.elapse(const Duration(minutes: 1));

        expect(server.writes, hasLength(1));
        expect(server.channelGets, isEmpty);
      });
    });

    test('a new gateway session drops the checks', () {
      final SignalBarTestServer server = SignalBarTestServer();
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        _load(async, container, _chat);
        unawaited(_signals(container).activate(_chat, 'reading'));
        async.elapse(Duration.zero);
        _signals(container).invalidate();

        async.elapse(const Duration(minutes: 1));

        // The strip asks for its channel after READY; the check does not.
        expect(server.channelGets, hasLength(1));
      });
    });

    test('a signal turned off that an older answer brings back is asked for '
        'once', () {
      final SignalBarTestServer server = SignalBarTestServer()
        ..lit[_chat] = <Map<String, Object?>>[
          signalEntryJson('reading', kSignalTestMe),
        ];
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        _load(async, container, _chat);
        unawaited(
          _signals(
            container,
          ).deactivate(_chat, 'reading', userId: kSignalTestMe),
        );
        async.elapse(Duration.zero);
        expect(_mine(container, _chat, 'reading'), isNull);
        // What an answer to a request sent before the DELETE would show.
        _signals(container).handleChannelUpdate(<String, dynamic>{
          'channel_id': _chat,
          'bar_version': 3,
          'added': <Object?>[signalEntryJson('reading', kSignalTestMe)],
          'removed': <Object?>[],
        });

        async
          ..elapse(kSignalWriteEventWait)
          ..elapse(Duration.zero);

        expect(_mine(container, _chat, 'reading'), isNull);
        expect(server.channelGets, hasLength(2));
      });
    });
  });

  group('asking for a channel again (tyne-chat/tyne#447)', () {
    test('a confirmed channel is asked for again only on entering, once per '
        'cooldown', () {
      final SignalBarTestServer server = SignalBarTestServer();
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        _load(async, container, _chat);
        final ChannelSignalsNotifier signals = _signals(container);
        expect(signals.isConfirmed(_chat), isTrue);
        expect(signals.shouldLoad(_chat, entering: true), isFalse);

        async.elapse(kSignalChannelRefetchCooldown - _tick);
        expect(signals.shouldLoad(_chat, entering: true), isFalse);
        async.elapse(_tick);
        expect(signals.shouldLoad(_chat, entering: true), isTrue);
        expect(signals.shouldLoad(_chat, entering: false), isFalse);
      });
    });

    test('a channel with no data is asked for at once', () {
      final SignalBarTestServer server = SignalBarTestServer();
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        final ChannelSignalsNotifier signals = _signals(container);
        expect(signals.shouldLoad(_chat, entering: false), isTrue);
        expect(signals.shouldLoad(_chat, entering: true), isTrue);
      });
    });

    test('a failed request is not sent again within the cooldown', () {
      final SignalBarTestServer server = SignalBarTestServer()
        ..failReads = true;
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        _load(async, container, _chat);
        final ChannelSignalsNotifier signals = _signals(container);
        expect(signals.isConfirmed(_chat), isFalse);
        expect(signals.isLoading(_chat), isFalse);
        expect(signals.shouldLoad(_chat, entering: true), isFalse);
        expect(signals.shouldLoad(_chat, entering: false), isFalse);

        async.elapse(kSignalChannelRefetchCooldown);
        expect(signals.shouldLoad(_chat, entering: false), isTrue);
      });
    });

    test('a request on its way is shared', () {
      final SignalBarTestServer server = SignalBarTestServer();
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        final ChannelSignalsNotifier signals = _signals(container);
        unawaited(signals.loadChannel(_chat));
        expect(signals.shouldLoad(_chat, entering: true), isFalse);
        async.elapse(Duration.zero);
      });
    });

    test('a new gateway session lifts the cooldown', () {
      final SignalBarTestServer server = SignalBarTestServer();
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        _load(async, container, _chat);
        final ChannelSignalsNotifier signals = _signals(container)
          ..invalidate();
        expect(signals.shouldLoad(_chat, entering: false), isTrue);
      });
    });
  });

  group('the strip on entering a chat (tyne-chat/tyne#447)', () {
    Future<(SignalBarTestServer, void Function(String channelId))> pumpChats(
      WidgetTester tester, {
      bool failReads = false,
    }) async {
      final SignalBarTestServer server = SignalBarTestServer()
        ..failReads = failReads;
      final ValueNotifier<String> open = ValueNotifier<String>(_chat);
      addTearDown(open.dispose);
      await tester.pumpWidget(
        pumpFluxerApp(
          overrides: [
            signalBarRepositoryProvider.overrideWithValue(server.repository()),
            for (final String id in <String>[_chat, _other])
              channelMessagePermissionsProvider(
                id,
              ).overrideWith((Ref ref) => ChannelMessagePermissions.all),
            knownSignalChatIdsProvider.overrideWithValue(null),
          ],
          child: Scaffold(
            body: ValueListenableBuilder<String>(
              valueListenable: open,
              // A new strip per chat, as the composer keys it.
              builder: (BuildContext context, String channelId, _) =>
                  SignalBarStrip(
                    key: ValueKey<String>(channelId),
                    channelId: channelId,
                    guildId: '',
                    backgroundColor: const Color(0xFF26272D),
                    dividerColor: const Color(0xFF3C3E47),
                  ),
            ),
          ),
        ),
      );
      await pumpFluxerFramesQuick(tester);
      return (server, (String channelId) => open.value = channelId);
    }

    Future<void> finish(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(kMySignalsRetryDelay);
    }

    testWidgets('switching back and forth asks once per chat per cooldown', (
      WidgetTester tester,
    ) async {
      final (SignalBarTestServer server, void Function(String) enter) =
          await pumpChats(tester);
      expect(server.channelGets, <String>['GET /channels/c1/signals']);

      for (int i = 0; i < 10; i++) {
        enter(i.isEven ? _other : _chat);
        await pumpFluxerFramesQuick(tester);
      }
      expect(server.channelGets, <String>[
        'GET /channels/c1/signals',
        'GET /channels/c2/signals',
      ]);

      // Someone lights a signal and the session misses the event.
      server.lit[_chat] = <Map<String, Object?>>[
        signalEntryJson('done', 'someone'),
      ];
      await tester.pump(kSignalChannelRefetchCooldown);
      enter(_other);
      await pumpFluxerFramesQuick(tester);
      enter(_chat);
      await pumpFluxerFramesQuick(tester);

      expect(server.channelGets, hasLength(4));
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(SignalBarStrip)),
      );
      expect(
        container.read(channelSignalsProvider)[_chat]?.single.userId,
        'someone',
      );
      await finish(tester);
    });

    testWidgets('with every request failing, still once per chat per '
        'cooldown', (WidgetTester tester) async {
      final (SignalBarTestServer server, void Function(String) enter) =
          await pumpChats(tester, failReads: true);

      for (int i = 0; i < 10; i++) {
        enter(i.isEven ? _other : _chat);
        await pumpFluxerFramesQuick(tester);
      }
      expect(server.channelGets, hasLength(2));
      expect(find.byType(SignalBarView), findsNothing);

      await tester.pump(kSignalChannelRefetchCooldown);
      enter(_other);
      await pumpFluxerFramesQuick(tester);
      expect(server.channelGets, hasLength(3));
      await finish(tester);
    });

    testWidgets('a chat left on screen is not asked for again', (
      WidgetTester tester,
    ) async {
      final (SignalBarTestServer server, _) = await pumpChats(tester);
      await tester.pump(const Duration(minutes: 5));
      await tester.pump();
      expect(server.channelGets, hasLength(1));
      await finish(tester);
    });
  });
}
