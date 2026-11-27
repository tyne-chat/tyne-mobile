import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/providers/gateway/gateway_connection_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/voice/providers/voice_session_provider.dart';
import 'package:fluxer_dart/gateway.dart';

import '../../helpers/chat_view_model_pagination_test_harness.dart';
import '../../helpers/open_test_database.dart';

class _FakeVoiceGatewayConnection extends Fake implements GatewayConnection {
  @override
  GatewayState get state => GatewayState.connected;

  @override
  bool updateVoiceState(GatewayVoiceStateUpdate update) => true;
}

Future<void> _pumpMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('keepAlive reset Batch 7 regressions', () {
    test('ChatViewModel clears parked windows when invalidated', () async {
      final String msg1Id = paginationSnowflakeForIndex(1);
      final String msg2Id = paginationSnowflakeForIndex(2);
      final String msg3Id = paginationSnowflakeForIndex(3);
      final FluxerDatabase db = openTestDatabase();
      await db.channelDao.upsertChannel(
        ChannelsCompanion.insert(
          id: 'channel-1',
          guildId: 'guild-1',
          name: 'general',
          lastMessageId: Value<String?>(msg1Id),
        ),
      );
      await db.channelDao.upsertChannel(
        ChannelsCompanion.insert(
          id: 'channel-2',
          guildId: 'guild-1',
          name: 'random',
          lastMessageId: Value<String?>(msg2Id),
        ),
      );

      final PaginatingAdapter adapter = PaginatingAdapter(
        messagesByChannel: <String, List<Map<String, Object?>>>{
          'channel-1': <Map<String, Object?>>[
            paginationMessageJson(
              id: msg1Id,
              channelId: 'channel-1',
              authorId: 'other',
            ),
          ],
          'channel-2': <Map<String, Object?>>[
            paginationMessageJson(
              id: msg2Id,
              channelId: 'channel-2',
              authorId: 'other',
            ),
          ],
        },
      );
      final ProviderContainer container = paginationContainer(db, adapter);
      addTearDown(container.dispose);

      final ChatViewModel vm = container.read(chatViewModelProvider.notifier);
      await vm.switchChannel('channel-1');
      await paginationFlushAsync();
      expect(
        container.read(chatViewModelProvider).messages.map((m) => m.id),
        <String>[msg1Id],
      );

      await vm.switchChannel('channel-2');
      await paginationFlushAsync();

      adapter.messagesByChannel['channel-1'] = <Map<String, Object?>>[
        paginationMessageJson(
          id: msg3Id,
          channelId: 'channel-1',
          authorId: 'other',
        ),
      ];
      await (db.delete(
        db.messages,
      )..where((t) => t.channelId.equals('channel-1'))).go();
      await db.channelDao.upsertChannel(
        ChannelsCompanion.insert(
          id: 'channel-1',
          guildId: 'guild-1',
          name: 'general',
          lastMessageId: Value<String?>(msg3Id),
        ),
      );

      container.invalidate(chatViewModelProvider);
      await container
          .read(chatViewModelProvider.notifier)
          .switchChannel('channel-1');
      await paginationFlushAsync();

      expect(
        container.read(chatViewModelProvider).messages.map((m) => m.id),
        <String>[msg3Id],
      );
    });

    test(
      'ChatViewModel clears _draftMemo when invalidated so switching back does not flash a deleted draft',
      () async {
        final String msg1Id = paginationSnowflakeForIndex(1);
        final String msg2Id = paginationSnowflakeForIndex(2);
        final FluxerDatabase db = openTestDatabase();
        await db.channelDao.upsertChannel(
          ChannelsCompanion.insert(
            id: 'channel-1',
            guildId: 'guild-1',
            name: 'general',
            lastMessageId: Value<String?>(msg1Id),
          ),
        );
        await db.channelDao.upsertChannel(
          ChannelsCompanion.insert(
            id: 'channel-2',
            guildId: 'guild-1',
            name: 'random',
            lastMessageId: Value<String?>(msg2Id),
          ),
        );

        final PaginatingAdapter adapter = PaginatingAdapter(
          messagesByChannel: <String, List<Map<String, Object?>>>{
            'channel-1': <Map<String, Object?>>[
              paginationMessageJson(
                id: msg1Id,
                channelId: 'channel-1',
                authorId: 'other',
              ),
            ],
            'channel-2': <Map<String, Object?>>[
              paginationMessageJson(
                id: msg2Id,
                channelId: 'channel-2',
                authorId: 'other',
              ),
            ],
          },
        );
        final ProviderContainer container = paginationContainer(db, adapter);
        addTearDown(container.dispose);

        final ChatViewModel vm = container.read(chatViewModelProvider.notifier);
        await vm.switchChannel('channel-1');
        await paginationFlushAsync();
        vm.updateMessageText('stale draft');

        await vm.switchChannel('channel-2');
        await paginationFlushAsync();
        await db.composerDraftDao.deleteDraft('channel-1');

        container.invalidate(chatViewModelProvider);
        final Future<void> switching = container
            .read(chatViewModelProvider.notifier)
            .switchChannel('channel-1');
        expect(container.read(chatViewModelProvider).messageText, isEmpty);

        await switching;
        await paginationFlushAsync();
      },
    );

    test(
      'VoiceSession clears _expectedChannelId across account switch',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        final FluxerDatabase db = openTestDatabase();
        final ProviderContainer container = ProviderContainer(
          overrides: [
            fluxerDatabaseProvider.overrideWithValue(db),
            gatewayConnectionProvider.overrideWithValue(
              _FakeVoiceGatewayConnection(),
            ),
          ],
        );
        addTearDown(container.dispose);

        container.read(currentUserIdProvider.notifier).set('user-a');
        final bool joined = await container
            .read(voiceSessionProvider.notifier)
            .connectToVoiceChannel(
              guildId: null,
              channelId: 'dm-1',
              skipChannelGate: true,
              initialSelfMute: true,
            );
        expect(joined, isTrue);
        expect(container.read(voiceSessionProvider).isConnecting, isTrue);

        container.read(currentUserIdProvider.notifier).set('user-b');
        expect(container.read(voiceSessionProvider).isInVoice, isFalse);

        container
            .read(voiceSessionProvider.notifier)
            .handleVoiceServerUpdate(
              const VoiceServerUpdateEvent(
                token: '',
                endpoint: '',
                connectionId: 'conn-1',
                channelId: 'dm-1',
              ),
            );
        await _pumpMicrotasks();

        expect(container.read(voiceSessionProvider).errorMessage, isNull);
      },
    );

    test(
      'VoiceSession clears _lastConnectRequestAt throttle across account switch',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        final FluxerDatabase db = openTestDatabase();
        final ProviderContainer container = ProviderContainer(
          overrides: [
            fluxerDatabaseProvider.overrideWithValue(db),
            gatewayConnectionProvider.overrideWithValue(
              _FakeVoiceGatewayConnection(),
            ),
          ],
        );
        addTearDown(container.dispose);

        container.read(currentUserIdProvider.notifier).set('user-a');
        final bool userAJoined = await container
            .read(voiceSessionProvider.notifier)
            .connectToVoiceChannel(
              guildId: null,
              channelId: 'dm-1',
              skipChannelGate: true,
              initialSelfMute: true,
            );
        expect(userAJoined, isTrue);

        container.read(currentUserIdProvider.notifier).set('user-b');
        final bool userBJoined = await container
            .read(voiceSessionProvider.notifier)
            .connectToVoiceChannel(
              guildId: null,
              channelId: 'dm-2',
              skipChannelGate: true,
              initialSelfMute: true,
            );

        expect(userBJoined, isTrue);
        expect(container.read(voiceSessionProvider).channelId, 'dm-2');
      },
    );
  });
}
