import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/channels/providers/channel_providers.dart';
import 'package:fluxer_app/features/dm/domain/dm_conversation.dart';
import 'package:fluxer_app/features/dm/providers/dm_view_model.dart';
import 'package:fluxer_app/features/friends/domain/friend.dart';
import 'package:fluxer_app/features/guilds/providers/guild_list_view_model.dart';
import 'package:fluxer_app/features/signal_bar/data/signal_bar_repository.dart';
import 'package:fluxer_app/features/signal_bar/domain/signal_bar_models.dart';
import 'package:fluxer_app/features/signal_bar/presentation/signal_bar_strip.dart';
import 'package:fluxer_app/features/signal_bar/presentation/signals_everywhere_sheet.dart';
import 'package:fluxer_app/features/signal_bar/providers/signal_bar_providers.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button.dart';
import 'package:fluxer_app/material_ui.dart';

import '../../helpers/pump_fluxer_app.dart';

// Signals everywhere (tyne-chat/tyne#223) on the phone: the summary, its one
// request per action, the strip's globe and where it goes, and the sheet.

const String _me = '1';

const SignalBarSignal _reading = SignalBarSignal(
  id: 'reading',
  emojiName: '📖',
  animated: false,
  label: 'Reading',
);
const SignalBarSignal _sleeping = SignalBarSignal(
  id: 'sleeping',
  emojiName: '💤',
  animated: false,
  label: 'Sleeping',
  everywhere: true,
);

UserSignalChat _chat(String channelId, List<String> signals, int updatedAt) =>
    UserSignalChat(
      channelId: channelId,
      signals: <UserSignalRef>[
        for (final String id in signals) UserSignalRef(signalId: id),
      ],
      updatedAt: updatedAt,
    );

Map<String, dynamic> _entryJson(String signalId, String userId, int at) =>
    <String, dynamic>{
      'signal_id': signalId,
      'user': <String, dynamic>{'id': userId, 'username': 'user$userId'},
      'persona_id': null,
      'subprofile': null,
      'activated_at': at,
    };

/// Records every call; each answer can be set or made to fail.
class _RecordingRepository implements SignalBarRepository {
  final List<String> calls = <String>[];
  UserSignalsSummary summary = const UserSignalsSummary(
    chats: <UserSignalChat>[],
    restoreAvailable: false,
  );
  bool fail = false;
  Future<void>? hold;

  Future<UserSignalsSummary> _answer(String call) async {
    calls.add(call);
    final Future<void>? wait = hold;
    if (wait != null) {
      await wait;
    }
    if (fail) {
      throw DioLikeFailure();
    }
    return summary;
  }

  @override
  Future<UserSignalsSummary> fetchMySignals() => _answer('GET summary');

  @override
  Future<UserSignalsSummary> setEverywhere({
    required String? signalId,
    String? channelId,
    String? personaId,
  }) =>
      _answer('PUT ${signalId ?? '-'} ${channelId ?? '-'} ${personaId ?? '-'}');

  @override
  Future<UserSignalsSummary> restore() => _answer('POST restore');

  @override
  Future<UserSignalsRestorePreview> fetchRestorePreview() async {
    calls.add('GET restore');
    return const UserSignalsRestorePreview(
      available: false,
      chats: <UserSignalsRestoreChat>[],
    );
  }

  @override
  Future<SignalBarConfig> fetchBar() async => const SignalBarConfig(
    version: 1,
    signals: <SignalBarSignal>[_reading, _sleeping],
  );

  @override
  Future<({bool enabled, int barVersion, List<SignalEntry> entries})>
  fetchChannel(String channelId) async =>
      (enabled: true, barVersion: 1, entries: const <SignalEntry>[]);

  @override
  Future<void> activate(
    String channelId,
    String signalId, {
    String? personaId,
  }) async {}

  @override
  Future<void> deactivate(String channelId, String signalId) async {
    calls.add('DELETE $channelId $signalId');
  }

  @override
  Future<void> removeUser(
    String channelId,
    String signalId,
    String userId,
  ) async {}

  @override
  Future<void> reset(String channelId, String signalId) async {}
}

class DioLikeFailure implements Exception {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the summary', () {
    test('parses the routes and keeps chats newest first', () {
      final UserSignalsSummary summary = UserSignalsSummary.fromJson(
        const <String, dynamic>{
          'restore_available': true,
          'chats': <dynamic>[
            <String, dynamic>{
              'channel_id': 'old',
              'signals': <dynamic>[
                <String, dynamic>{'signal_id': 'reading', 'persona_id': '7'},
              ],
              'updated_at': 1,
            },
            <String, dynamic>{
              'channel_id': 'new',
              'signals': <dynamic>[],
              'updated_at': 5,
            },
          ],
        },
      );
      expect(summary.restoreAvailable, isTrue);
      expect(
        summary.newestFirst.map((UserSignalChat c) => c.channelId),
        <String>['new', 'old'],
      );
      expect(
        summary.chats.first.signals.single,
        const UserSignalRef(signalId: 'reading', personaId: '7'),
      );
      expect(
        SignalBarSignal.fromJson(const <String, dynamic>{
          'id': 's',
          'emoji_name': '💤',
          'everywhere': true,
        }).everywhere,
        isTrue,
      );
      expect(
        SignalBarSignal.fromJson(const <String, dynamic>{
          'id': 's',
          'emoji_name': '💤',
        }).everywhere,
        isFalse,
      );
    });

    test('reads what Restore would change', () {
      final UserSignalsRestorePreview preview =
          UserSignalsRestorePreview.fromJson(const <String, dynamic>{
            'available': true,
            'created_at': 100,
            'action': <String, dynamic>{'kind': 'set', 'signal_id': 'sleeping'},
            'chats': <dynamic>[
              <String, dynamic>{
                'channel_id': 'a',
                'available': true,
                'now': <dynamic>[
                  <String, dynamic>{
                    'signal_id': 'sleeping',
                    'persona_id': null,
                  },
                ],
                'after': <dynamic>[
                  <String, dynamic>{'signal_id': 'reading', 'persona_id': null},
                ],
              },
              <String, dynamic>{
                'channel_id': 'b',
                'available': false,
                'now': <dynamic>[],
                'after': <dynamic>[],
              },
            ],
          });
      expect(preview.kind, UserSignalsRestoreKind.set);
      expect(preview.signalId, 'sleeping');
      expect(preview.chats.first.changes, isTrue);
      expect(preview.chats.last.changes, isFalse);
      expect(preview.chats.last.available, isFalse);
    });
  });

  group('MySignalsNotifier', () {
    late _RecordingRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = _RecordingRepository();
      container = ProviderContainer(
        overrides: [
          signalBarRepositoryProvider.overrideWithValue(repository),
          currentUserIdProvider.overrideWithValue(_me),
        ],
      );
      addTearDown(container.dispose);
    });

    MySignalsNotifier notifier() => container.read(mySignalsProvider.notifier);

    test('loads once for many strips', () async {
      notifier()
        ..ensureLoaded()
        ..ensureLoaded();
      await notifier().refresh();
      notifier().ensureLoaded();

      expect(repository.calls, <String>['GET summary']);
    });

    test('waits a minute after a failed load before asking again', () async {
      DateTime clock = DateTime(2026, 11, 10, 12);
      notifier().now = () => clock;
      repository.fail = true;

      notifier().ensureLoaded();
      await notifier().refresh();
      notifier().ensureLoaded();
      notifier().ensureLoaded();
      expect(repository.calls, <String>['GET summary']);

      clock = clock.add(kMySignalsRetryDelay);
      repository.fail = false;
      notifier().ensureLoaded();
      expect(repository.calls, <String>['GET summary', 'GET summary']);
    });

    test(
      'follows the events that name the account, in channels never loaded',
      () async {
        await notifier().refresh();
        final ChannelSignalsNotifier channels =
            container.read(channelSignalsProvider.notifier)
              ..handleChannelUpdate(<String, dynamic>{
                'channel_id': 'a',
                'bar_version': 0,
                'added': <dynamic>[
                  _entryJson('sleeping', _me, 10),
                  _entryJson('sleeping', '2', 11),
                ],
                'removed': <dynamic>[],
              })
              ..handleChannelUpdate(<String, dynamic>{
                'channel_id': 'b',
                'bar_version': 0,
                'added': <dynamic>[_entryJson('reading', _me, 20)],
                'removed': <dynamic>[],
              });
        expect(
          container
              .read(mySignalsProvider)
              .summary!
              .newestFirst
              .map((UserSignalChat c) => c.channelId),
          <String>['b', 'a'],
        );

        channels.handleChannelUpdate(<String, dynamic>{
          'channel_id': 'b',
          'bar_version': 0,
          'added': <dynamic>[],
          'removed': <dynamic>[
            <String, dynamic>{'signal_id': 'reading', 'user_id': _me},
          ],
        });
        expect(
          container
              .read(mySignalsProvider)
              .summary!
              .chats
              .map((UserSignalChat c) => c.channelId),
          <String>['a'],
        );
        expect(repository.calls, <String>['GET summary']);
      },
    );

    test(
      'sets a signal everywhere in one request with the open chat',
      () async {
        repository.summary = UserSignalsSummary(
          chats: <UserSignalChat>[
            _chat('open', <String>['sleeping'], 3),
          ],
          restoreAvailable: true,
        );

        await notifier().setEverywhere(
          'sleeping',
          channelId: 'open',
          personaId: '7',
        );

        expect(repository.calls, <String>['PUT sleeping open 7']);
        expect(
          container.read(mySignalsProvider).summary!.restoreAvailable,
          isTrue,
        );
      },
    );

    test('turns all off with no chat and no persona', () async {
      await notifier().setEverywhere(null, channelId: 'open', personaId: '7');

      expect(repository.calls, <String>['PUT - - -']);
    });

    test('sends nothing while a change is on its way', () async {
      final Completer<void> gate = Completer<void>();
      repository.hold = gate.future;

      final Future<void> first = notifier().setEverywhere('sleeping');
      await notifier().setEverywhere(null);
      await notifier().restore();
      expect(container.read(mySignalsProvider).busy, isTrue);
      gate.complete();
      await first;

      expect(repository.calls, <String>['PUT sleeping - -']);
      expect(container.read(mySignalsProvider).busy, isFalse);
    });

    test(
      'reloads the summary once after a failed change, and does not resend it',
      () async {
        repository.fail = true;

        await notifier().setEverywhere('sleeping');

        expect(repository.calls, <String>['PUT sleeping - -', 'GET summary']);
      },
    );

    test(
      'loads the summary with the bar, so menus know it without a strip',
      () async {
        await container.read(signalBarConfigProvider.notifier).refresh();
        await Future<void>.value();

        expect(repository.calls, <String>['GET summary']);
        expect(container.read(mySignalsProvider).summary, isNotNull);
      },
    );

    test('drops a chat whose bar is switched off', () async {
      repository.summary = UserSignalsSummary(
        chats: <UserSignalChat>[
          _chat('a', <String>['reading'], 1),
          _chat('b', <String>['reading'], 2),
        ],
        restoreAvailable: false,
      );
      await notifier().refresh();

      container.read(channelSignalsProvider.notifier).handleEnabledUpdate(
        <String, dynamic>{'channel_id': 'a', 'enabled': false},
      );

      expect(
        container
            .read(mySignalsProvider)
            .summary!
            .chats
            .map((UserSignalChat c) => c.channelId),
        <String>['b'],
      );
      expect(repository.calls, <String>['GET summary']);
    });

    test('a new gateway session forgets the summary', () async {
      await notifier().refresh();
      expect(container.read(mySignalsProvider).summary, isNotNull);

      container.read(channelSignalsProvider.notifier).invalidate();

      expect(container.read(mySignalsProvider).summary, isNull);
    });
  });

  group('where the globe and caret go', () {
    test(
      'side by side while the signals fit on one row beside them, else stacked',
      () {
        // Seven 40 dp signals 6 dp apart take 316; the divider takes 17 and the
        // globe and caret side by side 76.
        expect(
          signalBarEndLayout(count: 7, width: 409, showGlobe: true).stacked,
          isFalse,
        );
        final layout = signalBarEndLayout(
          count: 7,
          width: 408,
          showGlobe: true,
        );
        expect(layout.stacked, isTrue);
        expect(layout.signalsWidth, 408 - 17 - 40);
      },
    );

    test('without a globe the caret stays beside the signals', () {
      final layout = signalBarEndLayout(
        count: 30,
        width: 300,
        showGlobe: false,
      );
      expect(layout.stacked, isFalse);
      expect(layout.signalsWidth, 260);
    });

    test('sixteen signals on a phone make two rows of eight', () {
      final layout = signalBarEndLayout(count: 16, width: 380, showGlobe: true);
      expect(layout.stacked, isTrue);
      final double size = signalBarSignalSize(
        count: 16,
        width: layout.signalsWidth,
      );
      expect(((layout.signalsWidth + 6) / (size + 6)).floor(), 8);
    });
  });

  group('the strip', () {
    Future<void> pump(
      WidgetTester tester, {
      required int? myChatCount,
      bool collapsed = false,
      List<SignalEntry> entries = const <SignalEntry>[],
      double width = 400,
    }) async {
      await tester.pumpWidget(
        pumpFluxerApp(
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: width,
                child: SignalBarView(
                  signals: const <SignalBarSignal>[_reading, _sleeping],
                  entries: entries,
                  currentUserId: _me,
                  collapsed: collapsed,
                  backgroundColor: const Color(0xFF26272D),
                  dividerColor: const Color(0xFF3C3E47),
                  onToggle: null,
                  onDetails: null,
                  onToggleCollapsed: () {},
                  myChatCount: myChatCount,
                  onOpenEverywhere: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await pumpFluxerFramesQuick(tester);
    }

    Text countText(WidgetTester tester) => tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('signal-bar-globe-count')),
        matching: find.byType(Text),
      ),
    );

    testWidgets('counts your chats on the globe, and shows a grey zero', (
      WidgetTester tester,
    ) async {
      await pump(tester, myChatCount: 3);
      expect(tester.takeException(), isNull);
      expect(countText(tester).data, '3');
      final Color lit = countText(tester).style!.color!;

      await pump(tester, myChatCount: 0);
      expect(countText(tester).data, '0');
      expect(countText(tester).style!.color, isNot(lit));

      await pump(tester, myChatCount: null);
      expect(
        find.byKey(const ValueKey<String>('signal-bar-globe-count')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('signal-bar-globe')),
        findsOneWidget,
      );
    });

    testWidgets('puts the globe beside the caret on one row, over it on two', (
      WidgetTester tester,
    ) async {
      await pump(tester, myChatCount: 1);
      expect(
        find.byKey(const ValueKey<String>('signal-bar-end-side-by-side')),
        findsOneWidget,
      );

      await pump(tester, myChatCount: 1, width: 130);
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey<String>('signal-bar-end-stacked')),
        findsOneWidget,
      );
    });

    testWidgets('collapsed with nothing lit here, only the caret is left', (
      WidgetTester tester,
    ) async {
      await pump(tester, myChatCount: 2, collapsed: true);
      expect(
        find.byKey(const ValueKey<String>('signal-bar-globe')),
        findsNothing,
      );

      await pump(
        tester,
        myChatCount: 2,
        collapsed: true,
        entries: const <SignalEntry>[
          SignalEntry(signalId: 'reading', userId: '2', username: 'two'),
        ],
      );
      expect(
        find.byKey(const ValueKey<String>('signal-bar-globe')),
        findsOneWidget,
      );
    });
  });

  group('the sheet', () {
    DmConversation dm(String id, String name) => DmConversation(
      id: id,
      type: 1,
      recipientId: 'u$id',
      recipientName: name,
      lastMessage: '',
      lastMessageTime: DateTime(2026),
    );

    List<Override> sheetOverrides(
      _RecordingRepository repository,
      List<String> dms,
    ) => [
      signalBarRepositoryProvider.overrideWithValue(repository),
      currentUserIdProvider.overrideWithValue(_me),
      dmViewModelProvider.overrideWithValue(
        DmViewState(
          conversations: <DmConversation>[
            for (final String id in dms) dm(id, id),
          ],
          friendsList: const <Friend>[],
          activeTab: FriendsTab.all,
          searchQuery: '',
        ),
      ),
      guildListViewModelProvider.overrideWithValue(
        const GuildListViewState(guilds: []),
      ),
      channelByIdProvider(
        'gone',
      ).overrideWith((ref) => Stream<Channel?>.value(null)),
    ];

    Future<_RecordingRepository> pumpSheet(
      WidgetTester tester, {
      required UserSignalsSummary summary,
      required List<String> opened,
      List<String> dms = const <String>['alice', 'bob'],
    }) async {
      final _RecordingRepository repository = _RecordingRepository()
        ..summary = summary;
      await tester.pumpWidget(
        pumpFluxerApp(
          overrides: sheetOverrides(repository, dms),
          child: Scaffold(
            body: SingleChildScrollView(
              child: SignalsEverywhereSheetBody(
                openChannelId: null,
                openGuildId: null,
                onClose: () => opened.add('closed'),
                onOpenChat: (SignalChatInfo chat, WidgetRef ref) async =>
                    opened.add(chat.channelId),
                onRestore: (WidgetRef ref) => opened.add('restore'),
              ),
            ),
          ),
        ),
      );
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(SignalsEverywhereSheetBody)),
      );
      await container.read(signalBarConfigProvider.notifier).refresh();
      await pumpFluxerFramesQuick(tester);
      return repository;
    }

    testWidgets(
      'offers ticked signals, lists known chats newest first, and opens one',
      (WidgetTester tester) async {
        final List<String> opened = <String>[];
        final _RecordingRepository repository = await pumpSheet(
          tester,
          opened: opened,
          summary: UserSignalsSummary(
            chats: <UserSignalChat>[
              _chat('bob', <String>['reading'], 1),
              _chat('alice', <String>['reading', 'sleeping'], 5),
              _chat('gone', <String>['reading'], 9),
            ],
            restoreAvailable: false,
          ),
        );
        expect(tester.takeException(), isNull);
        expect(repository.calls, <String>['GET summary']);

        expect(
          find.byKey(
            const ValueKey<String>('signals-everywhere-tile-sleeping'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('signals-everywhere-tile-reading')),
          findsNothing,
        );
        expect(find.text('SET EVERYWHERE (2 CHATS)'), findsOneWidget);

        final double alice = tester
            .getTopLeft(
              find.byKey(
                const ValueKey<String>('signals-everywhere-row-alice'),
              ),
            )
            .dy;
        final double bob = tester
            .getTopLeft(
              find.byKey(const ValueKey<String>('signals-everywhere-row-bob')),
            )
            .dy;
        expect(alice, lessThan(bob));
        expect(
          find.byKey(const ValueKey<String>('signals-everywhere-row-gone')),
          findsNothing,
        );
        final List<double> columnWidths = tester
            .widgetList<SizedBox>(
              find.byKey(const ValueKey<String>('signals-everywhere-columns')),
            )
            .map((SizedBox box) => box.width!)
            .toList();
        expect(columnWidths.toSet().length, 1);

        await tester.tap(
          find.byKey(const ValueKey<String>('signals-everywhere-row-bob')),
        );
        expect(opened, <String>['bob']);

        await tester.tap(
          find.byKey(
            const ValueKey<String>('signals-everywhere-tile-sleeping'),
          ),
        );
        await pumpFluxerFramesQuick(tester);
        expect(repository.calls, <String>['GET summary', 'PUT sleeping - -']);
        expect(opened, <String>['bob', 'closed']);
      },
    );

    testWidgets('counts only the chats the app knows', (
      WidgetTester tester,
    ) async {
      await pumpSheet(
        tester,
        opened: <String>[],
        summary: UserSignalsSummary(
          chats: <UserSignalChat>[
            _chat('gone', <String>['reading'], 3),
            _chat('alice', <String>['reading'], 1),
          ],
          restoreAvailable: false,
        ),
      );
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(SignalsEverywhereSheetBody)),
      );

      expect(container.read(knownSignalChatIdsProvider), <String>['alice']);
      expect(
        find.byKey(const ValueKey<String>('signals-everywhere-row-gone')),
        findsNothing,
      );
    });

    testWidgets(
      'lets Turn all off clear signals in chats the app cannot show',
      (WidgetTester tester) async {
        await pumpSheet(
          tester,
          opened: <String>[],
          dms: const <String>[],
          summary: UserSignalsSummary(
            chats: <UserSignalChat>[
              _chat('gone', <String>['reading'], 3),
            ],
            restoreAvailable: false,
          ),
        );

        expect(
          find.byKey(const ValueKey<String>('signals-everywhere-row-gone')),
          findsNothing,
        );
        final FluxerButton turnAllOff = tester.widget<FluxerButton>(
          find.byKey(const ValueKey<String>('signals-everywhere-turn-all-off')),
        );
        expect(turnAllOff.onPressed, isNotNull);
      },
    );

    testWidgets('closes after Turn all off', (WidgetTester tester) async {
      final List<String> opened = <String>[];
      final _RecordingRepository repository = await pumpSheet(
        tester,
        opened: opened,
        summary: UserSignalsSummary(
          chats: <UserSignalChat>[
            _chat('alice', <String>['reading'], 1),
          ],
          restoreAvailable: false,
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('signals-everywhere-turn-all-off')),
      );
      await pumpFluxerFramesQuick(tester);

      expect(repository.calls, <String>['GET summary', 'PUT - - -']);
      expect(opened, <String>['closed']);
    });

    testWidgets(
      "a long press turns off one chat's signals, one DELETE each, and stays open",
      (WidgetTester tester) async {
        final List<String> opened = <String>[];
        final _RecordingRepository repository = await pumpSheet(
          tester,
          opened: opened,
          summary: UserSignalsSummary(
            chats: <UserSignalChat>[
              _chat('alice', <String>['reading', 'sleeping'], 5),
              _chat('bob', <String>['reading'], 1),
            ],
            restoreAvailable: false,
          ),
        );

        await tester.longPress(
          find.byKey(const ValueKey<String>('signals-everywhere-row-alice')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(
            const ValueKey<String>('signals-everywhere-turn-off-chat'),
          ),
        );
        await tester.pumpAndSettle();

        expect(repository.calls, <String>[
          'GET summary',
          'DELETE alice reading',
          'DELETE alice sleeping',
        ]);
        expect(
          find.byKey(const ValueKey<String>('signals-everywhere-row-alice')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey<String>('signals-everywhere-row-bob')),
          findsOneWidget,
        );
        expect(opened, isEmpty);
      },
    );

    testWidgets('the restore list shows every chat and scrolls past ten', (
      WidgetTester tester,
    ) async {
      final List<String> ids = <String>[for (int i = 0; i < 12; i++) 'c$i'];
      UserSignalsRestorePreview preview(List<String> chats) =>
          UserSignalsRestorePreview(
            available: true,
            createdAt: 0,
            kind: UserSignalsRestoreKind.off,
            chats: <UserSignalsRestoreChat>[
              for (final String id in chats)
                UserSignalsRestoreChat(
                  channelId: id,
                  available: true,
                  now: const <UserSignalRef>[],
                  after: const <UserSignalRef>[
                    UserSignalRef(signalId: 'reading'),
                  ],
                ),
            ],
          );
      Future<void> show(List<String> chats) async {
        await tester.pumpWidget(
          pumpFluxerApp(
            overrides: sheetOverrides(_RecordingRepository(), ids),
            child: Scaffold(
              body: SingleChildScrollView(
                child: SignalsRestorePreview(
                  preview: preview(chats),
                  signals: const <SignalBarSignal>[_reading, _sleeping],
                ),
              ),
            ),
          ),
        );
        await pumpFluxerFramesQuick(tester);
      }

      await show(ids);
      expect(tester.takeException(), isNull);
      for (final String id in ids) {
        expect(
          find.byKey(ValueKey<String>('signals-restore-row-$id')),
          findsOneWidget,
        );
      }
      expect(
        find.byKey(const ValueKey<String>('signals-restore-scroll')),
        findsOneWidget,
      );

      await show(ids.take(10).toList());
      expect(
        find.byKey(const ValueKey<String>('signals-restore-scroll')),
        findsNothing,
      );
    });
  });
}
