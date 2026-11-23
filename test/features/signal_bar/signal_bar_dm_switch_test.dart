// The signal bar's switch in a DM or group DM on the phone
// (tyne-chat/tyne#743): anyone in it may turn the bar on or off
// (tyne-chat/tyne#265), from the DM's long-press menu or More in its details,
// as from the web's DM menus. The server's answer is the switch's new state,
// so it shows at once; a refused switch asks for the chat once. The requests
// are counted with the chat not loaded and with the request failing.

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/dm/domain/dm_conversation.dart';
import 'package:fluxer_app/features/signal_bar/data/signal_bar_repository.dart';
import 'package:fluxer_app/features/signal_bar/domain/signal_bar_models.dart';
import 'package:fluxer_app/features/signal_bar/presentation/signal_bar_dm_menu_item.dart';
import 'package:fluxer_app/features/signal_bar/providers/signal_bar_providers.dart';
import 'package:fluxer_app/features/ui/bottom_sheet/fluxer_bottom_sheet.dart';
import 'package:fluxer_app/material_ui.dart';

import '../../helpers/pump_fluxer_app.dart';
import 'signal_bar_server_fixture.dart';

const String _dm = 'd1';

DmConversation _conversation({
  String id = _dm,
  ChannelType type = ChannelType.dm,
  String recipientId = '42',
}) => DmConversation(
  id: id,
  type: type.wireValue,
  recipientId: recipientId,
  recipientName: 'Someone',
  lastMessage: '',
  lastMessageTime: DateTime.utc(2026),
);

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

void main() {
  group('ChannelSignalsNotifier.setDmEnabled', () {
    test('switching on shows at once, with one request', () {
      final SignalBarTestServer server = SignalBarTestServer()
        ..enabled[_dm] = false;
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        final ChannelSignalsNotifier signals = container.read(
          channelSignalsProvider.notifier,
        );
        unawaited(signals.loadChannel(_dm));
        async.elapse(Duration.zero);
        expect(signals.isEnabled(_dm), isFalse);

        // No CHANNEL_SIGNAL_BAR_UPDATE arrives in this test.
        unawaited(signals.setDmEnabled(_dm, enabled: true));
        async.elapse(Duration.zero);

        expect(signals.isEnabled(_dm), isTrue);
        expect(server.writes, <String>['PUT /channels/d1/signal-bar']);
        async.elapse(const Duration(minutes: 1));
        expect(server.channelGets, hasLength(1));
      });
    });

    test('switching off clears the signals at once', () {
      final SignalBarTestServer server = SignalBarTestServer()
        ..lit[_dm] = <Map<String, Object?>>[
          signalEntryJson('reading', '42'),
          signalEntryJson('done', kSignalTestMe),
        ];
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        final ChannelSignalsNotifier signals = container.read(
          channelSignalsProvider.notifier,
        );
        unawaited(signals.loadChannel(_dm));
        async.elapse(Duration.zero);
        expect(container.read(channelSignalsProvider)[_dm], hasLength(2));

        unawaited(signals.setDmEnabled(_dm, enabled: false));
        async.elapse(Duration.zero);

        expect(signals.isEnabled(_dm), isFalse);
        expect(container.read(channelSignalsProvider)[_dm], isEmpty);
        expect(server.writes, hasLength(1));
        expect(server.channelGets, hasLength(1));
      });
    });

    test('its event arriving as well changes nothing', () {
      final SignalBarTestServer server = SignalBarTestServer()
        ..enabled[_dm] = false;
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        final ChannelSignalsNotifier signals = container.read(
          channelSignalsProvider.notifier,
        );
        unawaited(signals.loadChannel(_dm));
        async.elapse(Duration.zero);
        unawaited(signals.setDmEnabled(_dm, enabled: true));
        async.elapse(Duration.zero);
        final List<SignalEntry>? before = container.read(
          channelSignalsProvider,
        )[_dm];

        signals.handleEnabledUpdate(<String, dynamic>{
          'channel_id': _dm,
          'enabled': true,
        });

        expect(signals.isEnabled(_dm), isTrue);
        expect(container.read(channelSignalsProvider)[_dm], before);
      });
    });

    test('switching on a chat not loaded asks for it once', () {
      final SignalBarTestServer server = SignalBarTestServer()
        ..enabled[_dm] = false;
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        final ChannelSignalsNotifier signals = container.read(
          channelSignalsProvider.notifier,
        );
        unawaited(signals.setDmEnabled(_dm, enabled: true));
        async.elapse(Duration.zero);

        expect(server.writes, hasLength(1));
        expect(server.channelGets, hasLength(1));
        expect(signals.isEnabled(_dm), isTrue);
        async.elapse(const Duration(minutes: 1));
        expect(server.channelGets, hasLength(1));
      });
    });

    test('a refused switch asks for the chat once, and nothing more', () {
      final SignalBarTestServer server = SignalBarTestServer()
        ..enabled[_dm] = false
        ..failWrites = true;
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        bool? accepted;
        final ChannelSignalsNotifier signals = container.read(
          channelSignalsProvider.notifier,
        );
        unawaited(
          signals
              .setDmEnabled(_dm, enabled: true)
              .then((bool done) => accepted = done),
        );
        async.elapse(Duration.zero);

        expect(accepted, isFalse);
        expect(signals.isEnabled(_dm), isFalse);
        async.elapse(const Duration(minutes: 5));
        expect(server.writes, hasLength(1));
        expect(server.channelGets, hasLength(1));
      });
    });

    test('with that request failing too, nothing is sent again', () {
      final SignalBarTestServer server = SignalBarTestServer()
        ..failWrites = true
        ..failReads = true;
      _withContainer(server, (FakeAsync async, ProviderContainer container) {
        unawaited(
          container
              .read(channelSignalsProvider.notifier)
              .setDmEnabled(_dm, enabled: true),
        );
        async
          ..elapse(Duration.zero)
          ..elapse(const Duration(minutes: 5));

        expect(server.requests, <String>[
          'PUT /channels/d1/signal-bar',
          'GET /channels/d1/signals',
        ]);
      });
    });
  });

  group('the menu item', () {
    /// A screen whose button opens a menu holding the switch for [dm], as the
    /// DM's long-press menu does.
    Future<ProviderContainer> pumpMenu(
      WidgetTester tester,
      SignalBarTestServer server, {
      DmConversation? dm,
      bool withBar = true,
    }) async {
      final DmConversation conversation = dm ?? _conversation();
      await tester.pumpWidget(
        pumpFluxerApp(
          overrides: [
            signalBarRepositoryProvider.overrideWithValue(server.repository()),
          ],
          child: Scaffold(
            body: Builder(
              builder: (BuildContext context) => TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (BuildContext sheetContext) => Consumer(
                    builder: (BuildContext context, WidgetRef ref, _) =>
                        FluxerMenuGroup(
                          children: <Widget>[
                            ...signalBarDmMenuItems(ref, conversation),
                          ],
                        ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold)),
      );
      if (withBar) {
        // The request runs on the tester's fake clock: pumped, not awaited.
        unawaited(container.read(signalBarConfigProvider.notifier).refresh());
        await tester.pumpAndSettle();
        expect(container.read(signalBarConfigProvider).signals, isNotEmpty);
      }
      return container;
    }

    Future<void> openMenu(WidgetTester tester) async {
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    Future<void> closeMenu(WidgetTester tester) async {
      Navigator.of(tester.element(find.byType(FluxerMenuGroup))).pop();
      await tester.pumpAndSettle();
    }

    Future<void> finish(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(kMySignalsRetryDelay);
    }

    testWidgets('is left out without a bar, in personal notes and in the '
        'system DM', (WidgetTester tester) async {
      final SignalBarTestServer server = SignalBarTestServer();
      for (final (DmConversation dm, bool withBar) in <(DmConversation, bool)>[
        (_conversation(), false),
        (_conversation(type: ChannelType.dmPersonalNotes), true),
        (_conversation(recipientId: '0'), true),
      ]) {
        await pumpMenu(tester, server, dm: dm, withBar: withBar);
        await openMenu(tester);
        expect(find.byType(SignalBarDmMenuItem), findsNothing);
        await closeMenu(tester);
        await finish(tester);
      }
      expect(server.channelGets, isEmpty);
    });

    testWidgets('shows in a group DM too, with its state from the server', (
      WidgetTester tester,
    ) async {
      // On, on the server; the phone has not loaded it.
      final SignalBarTestServer server = SignalBarTestServer()
        ..enabled[_dm] = true;
      await pumpMenu(
        tester,
        server,
        dm: _conversation(type: ChannelType.groupDm),
      );
      await openMenu(tester);
      expect(find.text('Turn off signal bar'), findsOneWidget);
      expect(server.channelGets, hasLength(1));
      await closeMenu(tester);
      await finish(tester);
    });

    testWidgets('opening the menu asks for the chat once per cooldown, and a '
        'tap switches the bar', (WidgetTester tester) async {
      final SignalBarTestServer server = SignalBarTestServer()
        ..enabled[_dm] = false;
      final ProviderContainer container = await pumpMenu(tester, server);

      await openMenu(tester);
      expect(find.text('Turn on signal bar'), findsOneWidget);
      expect(server.channelGets, hasLength(1));
      await closeMenu(tester);
      await openMenu(tester);
      expect(server.channelGets, hasLength(1));

      await tester.tap(find.text('Turn on signal bar'));
      await tester.pumpAndSettle();
      expect(find.byType(SignalBarDmMenuItem), findsNothing);
      expect(server.writes, <String>['PUT /channels/d1/signal-bar']);
      expect(
        container.read(channelSignalsProvider.notifier).isEnabled(_dm),
        isTrue,
      );

      await openMenu(tester);
      expect(find.text('Turn off signal bar'), findsOneWidget);
      expect(server.channelGets, hasLength(1));
      await closeMenu(tester);

      await tester.pump(kSignalChannelRefetchCooldown);
      await openMenu(tester);
      expect(server.channelGets, hasLength(2));
      expect(find.text('Turn off signal bar'), findsOneWidget);
      await closeMenu(tester);
      await finish(tester);
    });

    testWidgets('with every request failing, one request per tap and per '
        'cooldown', (WidgetTester tester) async {
      final SignalBarTestServer server = SignalBarTestServer()
        ..failReads = true
        ..failWrites = true;
      await pumpMenu(tester, server);

      await openMenu(tester);
      expect(server.channelGets, hasLength(1));
      await tester.tap(find.text('Turn on signal bar'));
      await tester.pumpAndSettle();
      for (int i = 0; i < 5; i++) {
        await openMenu(tester);
        await closeMenu(tester);
      }

      // The opening's GET, the PUT and the one GET after it.
      expect(server.requests.where((String r) => r.contains('/d1/')), <String>[
        'GET /channels/d1/signals',
        'PUT /channels/d1/signal-bar',
        'GET /channels/d1/signals',
      ]);
      await openMenu(tester);
      expect(find.text('Turn on signal bar'), findsOneWidget);
      await closeMenu(tester);
      await finish(tester);
    });
  });
}
