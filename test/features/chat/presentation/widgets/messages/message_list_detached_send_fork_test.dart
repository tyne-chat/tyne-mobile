// Fork: tyne-chat/tyne#212 (Android). Chiara's repro of 2026-11-02, with
// "Scroll to bottom when sending a message" on: scroll far up, mark a message
// unread, swipe the app away, start it again and send. The list does not move
// to the newest messages, and the messages between the page and the reply
// never load. The chat alone jumps correctly when asked
// (chat_view_model_detached_send_fork_test.dart), so this drives the real
// message list.
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
import 'package:fluxer_app/features/channels/data/ack_batcher.dart';
import 'package:fluxer_app/features/channels/providers/ack_batcher_provider.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/shared/services/guild_member_hydration_service.dart';
import 'package:fluxer_dart/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../helpers/fork_message_gap_harness.dart';
import '../../../../../helpers/instance_runtime_config_override.dart';
import '../../../../../helpers/noop_guild_member_hydration_service.dart';
import '../../../../../helpers/open_test_database.dart';
import 'message_list_send_ack_anchor_test.dart' hide main;

ProviderContainer _container(FluxerDatabase database, GapServer server) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'https://api.fluxer.app/v1'))
    ..httpClientAdapter = server;
  final FluxerClient client = FluxerClient(
    dio,
    baseUrl: 'https://api.fluxer.app/v1',
  );
  return ProviderContainer(
    overrides: [
      instanceRuntimeConfigOverride(),
      fluxerDatabaseProvider.overrideWithValue(database),
      appUiForegroundProvider.overrideWithValue(true),
      fluxerDioProvider.overrideWithValue(dio),
      fluxerClientProvider.overrideWithValue(client),
      currentUserIdProvider.overrideWithValue('me'),
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
      ...forkUpstream.messageListUiOverrides(),
    ],
  );
}

/// Frames and real async work in turn, so requests, database reads and the
/// list's post-frame work all get to run.
Future<void> _settle(WidgetTester tester, {int rounds = 30}) async {
  for (int i = 0; i < rounds; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() async {
      for (int j = 0; j < 4; j++) {
        await pumpEventQueue();
      }
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  Future<void> sendAfterRestart(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final FluxerDatabase database = openTestDatabase();
    final GapServer server = GapServer();
    await tester.runAsync(() async {
      await seedGapChannels(database);
      // What marking #20 unread leaves behind: the mark at #19, set by hand.
      await setGapReadMark(
        database,
        gapHistoryId(19),
        manual: true,
        stickyUnreadMessageId: gapHistoryId(20),
      );
    });
    final ProviderContainer container = _container(database, server);
    addTearDown(container.dispose);
    final ChatViewModel notifier = container.read(
      chatViewModelProvider.notifier,
    );

    await tester.pumpWidget(forkUpstream.messageListApp(container));
    await tester.pump();
    await tester.runAsync(() => notifier.switchChannel(kGapChannelId));
    await _settle(tester);

    expect(server.requests.first, 'around #19');
    expect(
      gapListShape(container.read(chatViewModelProvider), server),
      'claims newest: false; gaps: []; last: #44',
    );
    final int requestsBeforeSend = server.requests.length;

    unawaited(notifier.sendMessage(text: 'reply'));
    await _settle(tester);
    await tester.runAsync(() async {
      final Map<String, Object?> sent = server.history.last;
      await storeGapCreate(database, sent);
      emitGapCreate(container, sent);
    });
    await _settle(tester);

    expect(
      gapListShape(container.read(chatViewModelProvider), server),
      gapCompleteShape(server),
      reason:
          'requests after the send: '
          '${server.requests.skip(requestsBeforeSend).toList()}',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('after marking an old message unread and restarting, a send '
      'with "scroll to bottom" on lands at the newest messages', (
    WidgetTester tester,
  ) async {
    await sendAfterRestart(tester);
  });
}
