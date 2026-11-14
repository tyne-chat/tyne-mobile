// The device's copy of the signal bar and READY that drops nothing
// (tyne-chat/tyne#644, #645): the bar is there from the first frame after a
// restart, a new gateway session leaves it on screen while each channel is
// asked for again, and a tap on a copy that may be out of date is remembered
// and sent only once the answer shows it is needed. The server signs a
// session out over a burst of requests (tyne-chat/tyne#114), so these count
// them.

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/chat/providers/channel/channel_message_permissions_provider.dart';
import 'package:fluxer_app/features/signal_bar/data/signal_bar_repository.dart';
import 'package:fluxer_app/features/signal_bar/data/signal_bar_snapshot.dart';
import 'package:fluxer_app/features/signal_bar/domain/signal_bar_models.dart';
import 'package:fluxer_app/features/signal_bar/presentation/signal_bar_strip.dart';
import 'package:fluxer_app/features/signal_bar/presentation/signals_everywhere_sheet.dart';
import 'package:fluxer_app/features/signal_bar/providers/signal_bar_providers.dart';
import 'package:fluxer_app/features/signal_bar/providers/signal_bar_snapshot_writer.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/pump_fluxer_app.dart';
import '../../helpers/test_account_user_id.dart';

const String _me = kTestAccountUserId;
const String _channel = 'c';

const SignalBarSignal _reading = SignalBarSignal(
  id: 'reading',
  emojiName: '📖',
  animated: false,
  label: 'Reading',
);
const SignalBarSignal _done = SignalBarSignal(
  id: 'done',
  emojiName: '✅',
  animated: false,
);
const SignalBarConfig _bar = SignalBarConfig(
  version: 3,
  signals: <SignalBarSignal>[_reading, _done],
);

SignalEntry _entry(String signalId, String userId) => SignalEntry(
  signalId: signalId,
  userId: userId,
  username: 'user$userId',
  personaId: userId == _me ? null : 'p$userId',
  personaName: userId == _me ? null : 'Persona $userId',
);

/// A server whose channel answers wait until the test releases them, in any
/// order, and whose writes are recorded.
class _Server implements SignalBarRepository {
  _Server({this.held = false});

  /// Whether channel answers wait for [release].
  bool held;
  List<SignalEntry> entries = <SignalEntry>[];
  bool enabled = true;
  bool fail = false;
  final List<String> calls = <String>[];
  final List<Completer<void>> _waiting = <Completer<void>>[];

  int get channelGets => calls.where((String c) => c == 'GET channel').length;
  List<String> get writes => <String>[
    for (final String c in calls)
      if (c.startsWith('PUT') || c.startsWith('DELETE')) c,
  ];

  /// Lets the [index]th held channel answer go, with what the server holds
  /// at that moment.
  Future<void> release([int index = 0]) async {
    releaseNow(index);
    await pumpEventQueue();
  }

  /// [release] for widget tests, which then pump.
  void releaseNow([int index = 0]) => _waiting.removeAt(index).complete();

  @override
  Future<SignalBarConfig> fetchBar() async {
    calls.add('GET bar');
    return _bar;
  }

  @override
  Future<({bool enabled, int barVersion, List<SignalEntry> entries})>
  fetchChannel(String channelId) async {
    calls.add('GET channel');
    if (held) {
      final Completer<void> gate = Completer<void>();
      _waiting.add(gate);
      await gate.future;
    }
    if (fail) {
      throw Exception('offline');
    }
    return (enabled: enabled, barVersion: _bar.version, entries: entries);
  }

  @override
  Future<void> activate(
    String channelId,
    String signalId, {
    String? personaId,
  }) async => calls.add('PUT $signalId ${personaId ?? '-'}');

  @override
  Future<void> deactivate(String channelId, String signalId) async =>
      calls.add('DELETE $signalId');

  @override
  Future<UserSignalsSummary> fetchMySignals() async {
    calls.add('GET summary');
    return const UserSignalsSummary(
      chats: <UserSignalChat>[
        UserSignalChat(
          channelId: _channel,
          signals: <UserSignalRef>[UserSignalRef(signalId: 'reading')],
          updatedAt: 2,
        ),
      ],
      restoreAvailable: false,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A device copy for [_me]: the bar, [_channel] with [entries], and a summary.
SignalBarSnapshot _copy({List<SignalEntry>? entries, bool enabled = true}) =>
    SignalBarSnapshot(
      config: _bar,
      chats: <SignalBarSnapshotChat>[
        SignalBarSnapshotChat(
          channelId: _channel,
          enabled: enabled,
          entries: entries ?? <SignalEntry>[_entry('done', 'other')],
        ),
      ],
      summary: const UserSignalsSummary(
        chats: <UserSignalChat>[
          UserSignalChat(
            channelId: 'elsewhere',
            signals: <UserSignalRef>[UserSignalRef(signalId: 'done')],
            updatedAt: 1,
          ),
        ],
        restoreAvailable: true,
      ),
    );

/// Stored preferences holding [copy] as [userId]'s copy, as start-up loads
/// them.
Future<SharedPreferences> _preferences({
  SignalBarSnapshot? copy,
  String userId = _me,
}) {
  SharedPreferences.setMockInitialValues(<String, Object>{
    if (copy != null) 'signal_bar_snapshot_v1_$userId': copy.encode(),
  });
  return SharedPreferences.getInstance();
}

ProviderContainer _container(
  _Server server, {
  SharedPreferences? preferences,
  Duration writeDelay = kSignalBarSnapshotWriteDelay,
}) {
  final ProviderContainer container = ProviderContainer(
    overrides: [
      signalBarRepositoryProvider.overrideWithValue(server),
      signalBarSnapshotStoreProvider.overrideWith((Ref ref) {
        final SignalBarSnapshotStore store = SignalBarSnapshotStore(
          preferences: preferences,
          writeDelay: writeDelay,
        );
        ref.onDispose(store.dispose);
        return store;
      }),
    ],
  );
  container.read(currentUserIdProvider.notifier).set(_me);
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('READY drops nothing (tyne-chat/tyne#644)', () {
    test(
      'a loaded channel stays on screen, unconfirmed, until its answer',
      () async {
        final _Server server = _Server()
          ..entries = <SignalEntry>[_entry('done', 'other')];
        final ProviderContainer container = _container(server);
        final ChannelSignalsNotifier signals = container.read(
          channelSignalsProvider.notifier,
        );
        expect(await signals.loadChannel(_channel), SignalChannelLoad.current);

        signals.invalidate();

        expect(container.read(channelSignalsProvider)[_channel], hasLength(1));
        expect(signals.isEnabled(_channel), isTrue);
        expect(signals.isConfirmed(_channel), isFalse);
        expect(await signals.loadChannel(_channel), SignalChannelLoad.current);
        expect(signals.isConfirmed(_channel), isTrue);
        expect(server.channelGets, 2);
      },
    );

    test('an answer to a request sent before READY confirms nothing', () async {
      final _Server server = _Server(held: true);
      final ProviderContainer container = _container(server);
      final ChannelSignalsNotifier signals = container.read(
        channelSignalsProvider.notifier,
      );

      final Future<SignalChannelLoad> before = signals.loadChannel(_channel);
      await pumpEventQueue();
      signals.invalidate();
      server.entries = <SignalEntry>[_entry('done', 'other')];
      await server.release();

      expect(await before, SignalChannelLoad.outdated);
      expect(signals.isConfirmed(_channel), isFalse);
      expect(container.read(channelSignalsProvider)[_channel], hasLength(1));
    });

    test('an older answer never replaces a newer one', () async {
      final _Server server = _Server(held: true);
      final ProviderContainer container = _container(server);
      final ChannelSignalsNotifier signals = container.read(
        channelSignalsProvider.notifier,
      );

      final Future<SignalChannelLoad> older = signals.loadChannel(_channel);
      await pumpEventQueue();
      signals.invalidate();
      final Future<SignalChannelLoad> newer = signals.loadChannel(_channel);
      await pumpEventQueue();
      server.entries = <SignalEntry>[_entry('reading', 'other')];
      await server.release(1);
      expect(await newer, SignalChannelLoad.current);
      server.entries = <SignalEntry>[];
      await server.release();

      expect(await older, SignalChannelLoad.outdated);
      expect(
        container.read(channelSignalsProvider)[_channel]!.single.signalId,
        'reading',
      );
    });

    test('re-pointing waits for an unconfirmed channel', () async {
      final _Server server = _Server()
        ..entries = <SignalEntry>[_entry('reading', _me)];
      final ProviderContainer container = _container(server);
      final ChannelSignalsNotifier signals = container.read(
        channelSignalsProvider.notifier,
      );
      await signals.loadChannel(_channel);
      signals
        ..invalidate()
        ..affirmPersona(
          _channel,
          userId: _me,
          persona: const SignalPersona(id: 'p1', name: 'Wren'),
        );
      await pumpEventQueue();

      expect(server.writes, isEmpty);
    });
  });

  group("the device's copy (tyne-chat/tyne#645)", () {
    test('seeds the bar, the channel and the summary, unconfirmed', () async {
      final _Server server = _Server();
      final ProviderContainer container = _container(
        server,
        preferences: await _preferences(copy: _copy()),
      );
      final ChannelSignalsNotifier signals = container.read(
        channelSignalsProvider.notifier,
      );

      expect(container.read(signalBarConfigProvider).signals, hasLength(2));
      expect(container.read(channelSignalsProvider)[_channel], hasLength(1));
      expect(signals.isEnabled(_channel), isTrue);
      expect(signals.isConfirmed(_channel), isFalse);
      expect(
        container.read(mySignalsProvider).summary!.chats.single.channelId,
        'elsewhere',
      );
      expect(server.calls, isEmpty);

      // Each is still asked for once.
      container.read(signalBarConfigProvider.notifier).ensureLoaded();
      container.read(mySignalsProvider.notifier).ensureLoaded();
      await pumpEventQueue();
      expect(server.calls, containsAll(<String>['GET bar', 'GET summary']));
      expect(server.calls.where((String c) => c == 'GET bar'), hasLength(1));
      expect(
        server.calls.where((String c) => c == 'GET summary'),
        hasLength(1),
      );
    });

    test('a chat kept as off stays off', () async {
      final ProviderContainer container = _container(
        _Server(),
        preferences: await _preferences(copy: _copy(enabled: false)),
      );
      expect(
        container.read(channelSignalsProvider.notifier).isEnabled(_channel),
        isFalse,
      );
    });

    test(
      'keeps the 50 chats loaded last, oldest first, and reads back',
      () async {
        final _Server server = _Server()
          ..entries = <SignalEntry>[_entry('done', 'other')];
        final ProviderContainer container = _container(server);
        final ChannelSignalsNotifier signals = container.read(
          channelSignalsProvider.notifier,
        );
        for (int i = 0; i < 55; i++) {
          await signals.loadChannel('c$i');
        }
        // Loaded again: now the newest.
        await signals.loadChannel('c0');

        final List<SignalBarSnapshotChat> chats = signals.snapshotChats();
        expect(chats, hasLength(kSignalBarSnapshotChats));
        expect(chats.first.channelId, 'c6');
        expect(chats.last.channelId, 'c0');

        final SignalBarSnapshot read = SignalBarSnapshot.decode(
          SignalBarSnapshot(config: _bar, chats: chats).encode(),
        )!;
        expect(read.config.version, 3);
        expect(read.config.signals.first.label, 'Reading');
        final SignalEntry entry = read.chats.last.entries.single;
        expect(entry.signalId, 'done');
        expect(entry.userId, 'other');
        expect(entry.personaName, 'Persona other');
        expect(read.summary, isNull);
      },
    );

    test('an unreadable copy is ignored', () {
      expect(SignalBarSnapshot.decode('{not json'), isNull);
      expect(SignalBarSnapshot.decode(null), isNull);
    });

    test('is written once, a second after a burst of changes', () {
      fakeAsync((FakeAsync async) {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final _Server server = _Server()
          ..entries = <SignalEntry>[_entry('done', 'other')];
        final ProviderContainer container = _container(server)
          ..read(signalBarSnapshotWriterProvider);
        container.read(signalBarConfigProvider.notifier).refresh().ignore();
        final ChannelSignalsNotifier signals = container.read(
          channelSignalsProvider.notifier,
        );
        unawaited(signals.loadChannel('a'));
        unawaited(signals.loadChannel('b'));
        async.flushMicrotasks();

        String? stored() {
          String? value;
          unawaited(
            SharedPreferences.getInstance().then(
              (SharedPreferences p) =>
                  value = p.getString('signal_bar_snapshot_v1_$_me'),
            ),
          );
          async.flushMicrotasks();
          return value;
        }

        async.elapse(
          kSignalBarSnapshotWriteDelay - const Duration(milliseconds: 1),
        );
        expect(stored(), isNull);
        async.elapse(const Duration(milliseconds: 1));
        final SignalBarSnapshot copy = SignalBarSnapshot.decode(stored())!;
        expect(
          <String>[
            for (final SignalBarSnapshotChat c in copy.chats) c.channelId,
          ],
          <String>['a', 'b'],
        );
      });
    });

    test("an account switch starts from that account's copy", () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'signal_bar_snapshot_v1_$_me': _copy().encode(),
        'signal_bar_snapshot_v1_other': const SignalBarSnapshot(
          config: _bar,
          chats: <SignalBarSnapshotChat>[
            SignalBarSnapshotChat(
              channelId: 'theirs',
              enabled: true,
              entries: <SignalEntry>[],
            ),
          ],
        ).encode(),
      });
      final ProviderContainer container = _container(
        _Server(),
        preferences: await SharedPreferences.getInstance(),
      );
      expect(container.read(channelSignalsProvider).keys, <String>[_channel]);
      expect(container.read(mySignalsProvider).summary, isNotNull);

      container.read(currentUserIdProvider.notifier).set('other');

      expect(container.read(channelSignalsProvider).keys, <String>['theirs']);
      expect(container.read(mySignalsProvider).summary, isNull);
    });

    test('sign-out drops the copy and a write still waiting for it', () {
      fakeAsync((FakeAsync async) {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'signal_bar_snapshot_v1_$_me': _copy().encode(),
        });
        final SignalBarSnapshotStore store = SignalBarSnapshotStore()
          ..schedule(_me, _copy());
        unawaited(store.forget(_me));
        async
          ..flushMicrotasks()
          ..elapse(kSignalBarSnapshotWriteDelay * 2);
        bool? kept;
        unawaited(
          SharedPreferences.getInstance().then(
            (SharedPreferences p) =>
                kept = p.containsKey('signal_bar_snapshot_v1_$_me'),
          ),
        );
        async.flushMicrotasks();
        expect(kept, isFalse);
      });
    });
  });

  group('taps on an unconfirmed chat (tyne-chat/tyne#645)', () {
    Future<(ProviderContainer, _Server)> start({
      required List<SignalEntry> shown,
      required List<SignalEntry> answer,
      bool fail = false,
    }) async {
      final _Server server = _Server(held: true)
        ..entries = answer
        ..fail = fail;
      final ProviderContainer container = _container(
        server,
        preferences: await _preferences(copy: _copy(entries: shown)),
      );
      return (container, server);
    }

    test('turning off shows at once and is sent only if still on', () async {
      final (ProviderContainer container, _Server server) = await start(
        shown: <SignalEntry>[_entry('reading', _me)],
        answer: <SignalEntry>[_entry('reading', _me)],
      );
      container
          .read(channelSignalsProvider.notifier)
          .want(_channel, 'reading', on: false, userId: _me);
      expect(container.read(channelSignalsProvider)[_channel], isEmpty);
      expect(server.channelGets, 1);

      await server.release();

      expect(server.writes, <String>['DELETE reading']);
      expect(container.read(channelSignalsProvider)[_channel], isEmpty);
    });

    test('nothing is sent when the answer already shows it', () async {
      final (ProviderContainer container, _Server server) = await start(
        shown: <SignalEntry>[_entry('reading', _me)],
        answer: <SignalEntry>[],
      );
      container
          .read(channelSignalsProvider.notifier)
          .want(_channel, 'reading', on: false, userId: _me);
      await server.release();

      expect(server.writes, isEmpty);
    });

    test(
      'lighting is sent with its persona when the answer has it off',
      () async {
        final (ProviderContainer container, _Server server) = await start(
          shown: <SignalEntry>[],
          answer: <SignalEntry>[],
        );
        container
            .read(channelSignalsProvider.notifier)
            .want(_channel, 'done', on: true, userId: _me, personaId: 'p1');
        await server.release();

        expect(server.writes, <String>['PUT done p1']);
      },
    );

    test('the last tap wins, and taps share one request', () async {
      final (ProviderContainer container, _Server server) = await start(
        shown: <SignalEntry>[_entry('reading', _me)],
        answer: <SignalEntry>[_entry('reading', _me)],
      );
      container.read(channelSignalsProvider.notifier)
        ..want(_channel, 'reading', on: false, userId: _me)
        ..want(_channel, 'reading', on: true, userId: _me);
      expect(server.channelGets, 1);
      await server.release();

      expect(server.writes, isEmpty);
    });

    test('after a failed answer the tap is sent as it is, once', () async {
      final (ProviderContainer container, _Server server) = await start(
        shown: <SignalEntry>[],
        answer: <SignalEntry>[],
        fail: true,
      );
      container
          .read(channelSignalsProvider.notifier)
          .want(_channel, 'done', on: true, userId: _me);
      await server.release();
      await pumpEventQueue();

      expect(server.writes, <String>['PUT done -']);
      expect(server.channelGets, 1);
    });
  });

  group('the strip', () {
    Future<_Server> pumpStrip(
      WidgetTester tester, {
      SignalBarSnapshot? copy,
    }) async {
      final SharedPreferences preferences = await _preferences(copy: copy);
      final _Server server = _Server(held: true)
        ..entries = <SignalEntry>[_entry('done', 'other')];
      await tester.pumpWidget(
        pumpFluxerApp(
          overrides: [
            signalBarRepositoryProvider.overrideWithValue(server),
            signalBarSnapshotStoreProvider.overrideWith((Ref ref) {
              final SignalBarSnapshotStore store = SignalBarSnapshotStore(
                preferences: preferences,
              );
              ref.onDispose(store.dispose);
              return store;
            }),
            channelMessagePermissionsProvider(
              _channel,
            ).overrideWith((Ref ref) => ChannelMessagePermissions.all),
            knownSignalChatIdsProvider.overrideWithValue(null),
          ],
          child: const Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: 400,
                child: SignalBarStrip(
                  channelId: _channel,
                  guildId: '',
                  backgroundColor: Color(0xFF26272D),
                  dividerColor: Color(0xFF3C3E47),
                ),
              ),
            ),
          ),
        ),
      );
      return server;
    }

    testWidgets('shows the device copy on its first frame', (
      WidgetTester tester,
    ) async {
      final _Server server = await pumpStrip(tester, copy: _copy());

      expect(find.byType(SignalBarView), findsOneWidget);
      await tester.pump();
      // Then asks for the channel once, and the bar and summary.
      expect(server.channelGets, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      server.releaseNow();
      await tester.pump();
    });

    testWidgets(
      'stays on screen across READY while the channel is asked again',
      (WidgetTester tester) async {
        final _Server server = await pumpStrip(tester);
        await tester.pump();
        await tester.pump();
        expect(find.byType(SignalBarView), findsNothing);
        server.releaseNow();
        // The answer lands during this frame; the strip shows on the next.
        await tester.pump();
        await tester.pump();
        expect(find.byType(SignalBarView), findsOneWidget);
        expect(server.channelGets, 1);

        final ProviderContainer container = ProviderScope.containerOf(
          tester.element(find.byType(SignalBarStrip)),
        );
        container.read(channelSignalsProvider.notifier).invalidate();
        await tester.pump();

        expect(find.byType(SignalBarView), findsOneWidget);
        expect(server.channelGets, 2);
        server.releaseNow();
        await tester.pump();
        expect(find.byType(SignalBarView), findsOneWidget);
        expect(server.channelGets, 2);
      },
    );
  });
}
