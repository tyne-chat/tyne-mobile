import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/signal_bar/data/signal_bar_snapshot.dart';
import 'package:fluxer_app/features/signal_bar/domain/signal_bar_models.dart';
import 'package:fluxer_app/features/signal_bar/providers/signal_bar_providers.dart';

/// Keeps the device's copy of the signal bar in step with what the app shows
/// (tyne-chat/tyne#645): every change of the bar, a channel or the account's
/// signals everywhere schedules one write a second later. The first strip
/// mounted starts it; it lives as long as the app.
final Provider<void> signalBarSnapshotWriterProvider = Provider<void>((
  Ref ref,
) {
  final SignalBarSnapshotStore store = ref.watch(
    signalBarSnapshotStoreProvider,
  );
  void schedule() {
    final String? userId = ref.read(currentUserIdProvider);
    final SignalBarConfig config = ref.read(signalBarConfigProvider);
    if (userId == null || config.version < 0) {
      return;
    }
    store.schedule(
      userId,
      SignalBarSnapshot(
        config: config,
        chats: ref.read(channelSignalsProvider.notifier).snapshotChats(),
        summary: ref.read(mySignalsProvider).summary,
      ),
    );
  }

  ref
    ..listen<SignalBarConfig>(signalBarConfigProvider, (_, _) => schedule())
    ..listen<Map<String, List<SignalEntry>>>(
      channelSignalsProvider,
      (_, _) => schedule(),
    )
    ..listen<UserSignalsSummary?>(
      mySignalsProvider.select((MySignalsState state) => state.summary),
      (_, _) => schedule(),
    );
});
