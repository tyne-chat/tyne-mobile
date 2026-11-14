// Fork: what the fork's scenario tests of the message list share. They run
// the real message list on the real chat (view model, repository, paging)
// against the fake server of test/helpers/fork_message_gap_harness.dart, and
// move the list with gestures, as a reader does.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' hide Message;
import 'package:fluxer_app/core/providers/app/app_ui_lifecycle_provider.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/router/route_state_providers.dart';
import 'package:fluxer_app/features/channels/data/ack_batcher.dart';
import 'package:fluxer_app/features/channels/providers/ack_batcher_provider.dart';
import 'package:fluxer_app/features/channels/providers/channel_providers.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/messages/message_item.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/chat/providers/core/message_pagination_coordinator.dart';
import 'package:fluxer_app/shared/services/guild_member_hydration_service.dart';
import 'package:fluxer_dart/export.dart';

import '../../../../../helpers/fork_message_gap_harness.dart';
import '../../../../../helpers/instance_runtime_config_override.dart';
import '../../../../../helpers/noop_guild_member_hydration_service.dart';
import '../../../../../helpers/open_test_database.dart';
import 'message_list_send_ack_anchor_test.dart' hide main;
import 'message_list_test_harness.dart'
    show messageListScrollPosition, messageListScrollable;

/// The open channel of a scenario: the list on screen, the chat behind it and
/// the server it talks to.
class ForkListScenario {
  ForkListScenario({
    required this.database,
    required this.server,
    required this.container,
  });

  final FluxerDatabase database;
  final GapServer server;
  final ProviderContainer container;

  ChatViewModel get chat => container.read(chatViewModelProvider.notifier);

  ChatViewState get state => container.read(chatViewModelProvider);

  /// The server's index of a message in the list, as in `#950`.
  int serverIndexOf(String messageId) => server.historyIds.indexOf(messageId);

  int get oldestLoaded => serverIndexOf(state.messages.first.id);

  int get newestLoaded => serverIndexOf(state.messages.last.id);
}

/// Opens the scenario's channel on a phone-sized list. The server holds
/// [historyLength] messages; the list starts on the newest page, or where
/// what [beforeOpen] stored (a read mark) makes it open.
///
/// The paging pump reads the test's clock, so its pauses pass with the frames
/// a test pumps and not with the time the test happens to take.
Future<ForkListScenario> openForkListScenario(
  WidgetTester tester, {
  required int historyLength,
  Future<void> Function(FluxerDatabase database)? beforeOpen,
}) async {
  tester.view.physicalSize = const Size(420, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final FluxerDatabase database = openTestDatabase();
  final GapServer server = GapServer(historyLength: historyLength);
  await tester.runAsync(() async {
    await seedGapChannels(database, historyLength: historyLength);
    await beforeOpen?.call(database);
  });
  final Dio dio = Dio(BaseOptions(baseUrl: 'https://api.fluxer.app/v1'))
    ..httpClientAdapter = server;
  final FluxerClient client = FluxerClient(
    dio,
    baseUrl: 'https://api.fluxer.app/v1',
  );
  final ProviderContainer container = ProviderContainer(
    overrides: [
      instanceRuntimeConfigOverride(),
      fluxerDatabaseProvider.overrideWithValue(database),
      appUiForegroundProvider.overrideWithValue(true),
      fluxerDioProvider.overrideWithValue(dio),
      fluxerClientProvider.overrideWithValue(client),
      currentUserIdProvider.overrideWithValue('me'),
      activeChannelIdProvider.overrideWithValue(kGapChannelId),
      ackBatcherProvider.overrideWith((ref) {
        final AckBatcher batcher = AckBatcher(
          client: client,
          batchDelay: Duration.zero,
        );
        ref.onDispose(() {
          unawaited(batcher.dispose());
        });
        return batcher;
      }),
      guildMemberHydrationServiceProvider.overrideWithValue(
        NoopGuildMemberHydrationService(database: database),
      ),
      messagePaginationCoordinatorProvider.overrideWith((ref) {
        final MessagePaginationCoordinator coordinator =
            MessagePaginationCoordinator(ref, now: tester.binding.clock.now);
        ref.onDispose(coordinator.dispose);
        return coordinator;
      }),
      ...forkUpstream.messageListUiOverrides(),
    ],
  );
  addTearDown(container.dispose);
  // In the app the channel's header watches the channel, which is what lets
  // the list find it for the start-of-channel header.
  final ProviderSubscription<Object?> channel = container.listen(
    channelByIdProvider(kGapChannelId),
    (_, _) {},
  );
  addTearDown(channel.close);

  await tester.pumpWidget(forkUpstream.messageListApp(container));
  await tester.pump();
  await tester.runAsync(
    () => container
        .read(chatViewModelProvider.notifier)
        .switchChannel(kGapChannelId),
  );
  await settleForkList(tester);
  return ForkListScenario(
    database: database,
    server: server,
    container: container,
  );
}

/// Frames and real async work in turn, so requests, database reads and the
/// list's post-frame work all get to run. Each round is one 16 ms frame.
Future<void> settleForkList(WidgetTester tester, {int rounds = 30}) async {
  for (int i = 0; i < rounds; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() async {
      for (int j = 0; j < 4; j++) {
        await pumpEventQueue();
      }
    });
  }
}

/// Lets the older page the app is waiting for arrive, and holds the next one,
/// so that each call lands exactly one page.
Future<void> landForkOlderPage(WidgetTester tester, ForkListScenario s) async {
  s.server
    ..releaseBeforeFetch()
    ..holdBeforeFetch = true;
  await settleForkList(tester);
}

Future<void> landForkNewerPage(WidgetTester tester, ForkListScenario s) async {
  s.server
    ..releaseAfterFetch()
    ..holdAfterFetch = true;
  await settleForkList(tester);
}

Future<void> closeForkListScenario(WidgetTester tester) async {
  // Past the timers a jump leaves behind (its highlight clears after 2 s).
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
}

/// Whether any message row is on screen: the reader sees messages, not only
/// the loading skeleton.
bool forkListShowsMessages(WidgetTester tester) {
  final Rect viewport = tester.getRect(messageListScrollable());
  for (final Element element in find.byType(MessageItem).evaluate()) {
    final RenderObject? box = element.renderObject;
    if (box is! RenderBox || !box.attached || !box.hasSize) {
      continue;
    }
    final Rect rect = box.localToGlobal(Offset.zero) & box.size;
    if (rect.bottom > viewport.top && rect.top < viewport.bottom) {
      return true;
    }
  }
  return false;
}

/// Flings toward older messages (a finger moving down) or newer ones until
/// the list rests against that end of what it can scroll to, which with
/// pages still loading is the far end of the skeleton.
Future<void> flingForkListToEnd(
  WidgetTester tester, {
  required bool towardOlder,
}) async {
  final ScrollPosition position = messageListScrollPosition(tester);
  bool atEnd() => towardOlder
      ? position.pixels <= position.minScrollExtent + 1
      : position.pixels >= position.maxScrollExtent - 1;
  for (int i = 0; i < 40 && !atEnd(); i++) {
    await tester.fling(
      messageListScrollable(),
      Offset(0, towardOlder ? 300 : -300),
      7000,
      warnIfMissed: false,
    );
    for (int frame = 0; frame < 10 && !atEnd(); frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }
  expect(atEnd(), isTrue, reason: 'the flings did not reach the end');
  // The fling comes to rest; the list sees the scroll end.
  await settleForkList(tester, rounds: 6);
}
