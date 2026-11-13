import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/signal_bar/data/signal_bar_repository.dart';
import 'package:fluxer_app/features/signal_bar/domain/signal_bar_models.dart';
import 'package:fluxer_app/features/signal_bar/presentation/signal_bar_strip.dart';
import 'package:fluxer_app/features/signal_bar/providers/signal_bar_collapsed_provider.dart';
import 'package:fluxer_app/features/signal_bar/providers/signal_bar_providers.dart';
import 'package:fluxer_app/material_ui.dart';

import '../../helpers/pump_fluxer_app.dart';

// tyne-chat/tyne#623: the composer around the strip rebuilds on every frame of
// the keyboard animation. The strip hands back the same SignalBarView while
// nothing it shows has changed, so Flutter skips the bar's subtree.

const SignalBarSignal _reading = SignalBarSignal(
  id: 'reading',
  emojiName: '📖',
  animated: false,
  label: 'Reading',
);

class _Repository implements SignalBarRepository {
  @override
  Future<SignalBarConfig> fetchBar() async =>
      const SignalBarConfig(version: 1, signals: <SignalBarSignal>[_reading]);

  @override
  Future<({bool enabled, int barVersion, List<SignalEntry> entries})>
  fetchChannel(String channelId) async =>
      (enabled: true, barVersion: 1, entries: const <SignalEntry>[]);

  @override
  Future<UserSignalsSummary> fetchMySignals() async => const UserSignalsSummary(
    chats: <UserSignalChat>[],
    restoreAvailable: false,
  );

  @override
  Future<UserSignalsSummary> setEverywhere({
    required String? signalId,
    String? channelId,
    String? personaId,
  }) => fetchMySignals();

  @override
  Future<UserSignalsSummary> restore() => fetchMySignals();

  @override
  Future<UserSignalsRestorePreview> fetchRestorePreview() async =>
      const UserSignalsRestorePreview(
        available: false,
        chats: <UserSignalsRestoreChat>[],
      );

  @override
  Future<void> activate(
    String channelId,
    String signalId, {
    String? personaId,
  }) async {}

  @override
  Future<void> deactivate(String channelId, String signalId) async {}

  @override
  Future<void> removeUser(
    String channelId,
    String signalId,
    String userId,
  ) async {}

  @override
  Future<void> reset(String channelId, String signalId) async {}
}

void main() {
  testWidgets('a parent rebuild hands back the same SignalBarView', (
    WidgetTester tester,
  ) async {
    late StateSetter rebuildParent;
    await tester.pumpWidget(
      pumpFluxerApp(
        overrides: [
          signalBarRepositoryProvider.overrideWithValue(_Repository()),
          currentUserIdProvider.overrideWithValue('1'),
        ],
        child: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              rebuildParent = setState;
              // A new strip widget on every build, as the composer makes.
              // ignore: prefer_const_constructors -- const would hand back one instance
              return SignalBarStrip(
                channelId: 'c1',
                guildId: '',
                backgroundColor: const Color(0xFF202020),
                dividerColor: const Color(0xFF404040),
              );
            },
          ),
        ),
      ),
    );
    await pumpFluxerFramesQuick(tester);
    expect(find.byType(SignalBarView), findsOneWidget);
    final SignalBarView first = tester.widget(find.byType(SignalBarView));

    rebuildParent(() {});
    await tester.pump();
    expect(identical(tester.widget(find.byType(SignalBarView)), first), isTrue);

    // Something it shows changes: a new view.
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(SignalBarStrip)),
    );
    container.read(signalBarCollapsedProvider.notifier).toggle();
    await tester.pump();
    final SignalBarView second = tester.widget(find.byType(SignalBarView));
    expect(identical(second, first), isFalse);
    expect(second.collapsed, isNot(first.collapsed));

    // The summary's retry timer outlives the tree; let it run on the fake clock.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(kMySignalsRetryDelay);
  });
}
