// Fork: the unread counts of a parent's followed threads: the DM row's
// threads mark, the Threads buttons, the chip and the browser rows
// (tyne-chat/tyne#699). Read from the local read states; no request.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/channels/providers/unread_provider.dart';
import 'package:fluxer_app/features/threads/domain/thread_channel.dart';
import 'package:fluxer_app/features/threads/fork_dm_threads/dm_thread_providers.dart';
import 'package:fluxer_app/features/threads/fork_dm_threads/dm_thread_widgets.dart';
import 'package:fluxer_app/features/threads/fork_dm_threads/dm_threads.dart';
import 'package:fluxer_app/features/threads/providers/thread_ui_providers.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/icons/phosphor.dart';

import '../../../helpers/pump_fluxer_app.dart';

const String _dmId = '500';

Channel _thread(String id, {bool archived = false}) => Channel(
  id: id,
  guildId: forkDmThreadGuildKey,
  name: 'thread $id',
  type: ChannelType.publicThread,
  parentId: _dmId,
  threadArchived: archived,
);

const ThreadMembership _following = ThreadMembership(flags: 0, muted: false);
const ThreadMembership _muted = ThreadMembership(flags: 0, muted: true);

List<Override> _overrides({
  required List<Channel> threads,
  required Map<String, UnreadState> unread,
  required Map<String, ThreadMembership?> membership,
}) => <Override>[
  parentThreadsProvider(
    forkDmThreadGuildKey,
    _dmId,
  ).overrideWith((Ref ref) => Stream<List<Channel>>.value(threads)),
  for (final MapEntry<String, UnreadState> entry in unread.entries)
    channelUnreadProvider(
      entry.key,
    ).overrideWith((Ref ref) => Stream<UnreadState>.value(entry.value)),
  for (final MapEntry<String, ThreadMembership?> entry in membership.entries)
    threadMembershipProvider(
      entry.key,
    ).overrideWith((Ref ref) => Stream<ThreadMembership?>.value(entry.value)),
];

void main() {
  tearDown(forkResetDmThreadIndex);

  test('only followed, unmuted, active threads count', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: _overrides(
        threads: <Channel>[
          _thread('t1'),
          _thread('t2'),
          _thread('t3'),
          _thread('t4', archived: true),
          _thread('t5'),
        ],
        unread: <String, UnreadState>{
          't1': const UnreadState(hasUnread: true, mentionCount: 2),
          't2': const UnreadState(hasUnread: true, mentionCount: 5),
          't3': const UnreadState(hasUnread: true, mentionCount: 7),
          't4': const UnreadState(hasUnread: true, mentionCount: 1),
          't5': const UnreadState(),
        },
        membership: <String, ThreadMembership?>{
          't1': _following,
          't2': _muted,
          't3': null,
          't4': _following,
          't5': _following,
        },
      ),
    );
    addTearDown(container.dispose);
    const ({String guildId, String parentId}) parent = (
      guildId: forkDmThreadGuildKey,
      parentId: _dmId,
    );
    container.listen(forkParentThreadsUnreadProvider(parent), (_, _) {});
    await container.read(
      parentThreadsProvider(forkDmThreadGuildKey, _dmId).future,
    );
    for (final String id in <String>['t1', 't2', 't3', 't5']) {
      await container.read(channelUnreadProvider(id).future);
      await container.read(threadMembershipProvider(id).future);
    }

    expect(
      container.read(forkParentThreadsUnreadProvider(parent)),
      const ForkThreadsUnread(threadsWithNews: 1, mentionCount: 2),
    );
  });

  testWidgets('the DM row shows the threads mark with their count', (
    tester,
  ) async {
    forkNoteDmThread('t1', _dmId);
    await tester.pumpWidget(
      pumpFluxerApp(
        overrides: _overrides(
          threads: <Channel>[_thread('t1'), _thread('t2')],
          unread: <String, UnreadState>{
            't1': const UnreadState(hasUnread: true, mentionCount: 2),
            't2': const UnreadState(hasUnread: true, mentionCount: 1),
          },
          membership: <String, ThreadMembership?>{
            't1': _following,
            't2': _following,
          },
        ),
        child: const Scaffold(
          body: ForkDmRowCountsWithThreads(dmId: _dmId, children: <Widget>[]),
        ),
      ),
    );
    await pumpFluxerFramesQuick(tester);

    expect(find.byType(FluxerBadge), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('no mark while the followed threads are read', (tester) async {
    forkNoteDmThread('t1', _dmId);
    await tester.pumpWidget(
      pumpFluxerApp(
        overrides: _overrides(
          threads: <Channel>[_thread('t1')],
          unread: <String, UnreadState>{'t1': const UnreadState()},
          membership: <String, ThreadMembership?>{'t1': _following},
        ),
        child: const Scaffold(body: ForkDmThreadsMark(dmId: _dmId)),
      ),
    );
    await pumpFluxerFramesQuick(tester);

    expect(find.byType(PhosphorIcon), findsNothing);
    expect(find.byType(FluxerBadge), findsNothing);
  });

  testWidgets('a browser row shows a dot, or the count of its mentions', (
    tester,
  ) async {
    await tester.pumpWidget(
      pumpFluxerApp(
        overrides: _overrides(
          threads: const <Channel>[],
          unread: <String, UnreadState>{
            't1': const UnreadState(hasUnread: true, hasUnreadMessages: true),
            't2': const UnreadState(hasUnread: true, mentionCount: 4),
          },
          membership: const <String, ThreadMembership?>{},
        ),
        child: const Scaffold(
          body: Column(
            children: <Widget>[
              ForkThreadRowUnread(threadId: 't1'),
              ForkThreadChipCount(threadId: 't1'),
              ForkThreadRowUnread(threadId: 't2'),
              ForkThreadChipCount(threadId: 't2'),
            ],
          ),
        ),
      ),
    );
    await pumpFluxerFramesQuick(tester);

    expect(find.byType(FluxerBadge), findsNWidgets(2));
    expect(find.text('4'), findsNWidgets(2));
  });

  testWidgets('threads with news come first, in their order', (tester) async {
    late List<Channel> sorted;
    await tester.pumpWidget(
      pumpFluxerApp(
        overrides: _overrides(
          threads: const <Channel>[],
          unread: <String, UnreadState>{
            'a': const UnreadState(),
            'b': const UnreadState(hasUnread: true),
            'c': const UnreadState(),
            'd': const UnreadState(hasUnread: true, mentionCount: 1),
          },
          membership: const <String, ThreadMembership?>{},
        ),
        child: Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? child) {
            sorted = <Channel>[
              _thread('a'),
              _thread('b'),
              _thread('c'),
              _thread('d'),
            ];
            forkSortThreadsWithNewsFirst(ref, sorted);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await pumpFluxerFramesQuick(tester);

    expect(
      <String>[for (final Channel t in sorted) t.id],
      <String>['b', 'd', 'a', 'c'],
    );
  });
}
