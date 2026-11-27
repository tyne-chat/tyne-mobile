// Fork: tyne-chat/tyne#946 — regression test for GuildReadState leaking an
// in-flight _seedAll across an account switch (contaminating Account B with
// Account A's guild unread state and dropping Account B's initial seed).
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/providers/app/startup_gateway_fallback_provider.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/channels/data/read_state_utils.dart';
import 'package:fluxer_app/features/guilds/providers/guild_read_state_provider.dart';
import 'package:fluxer_app/shared/utils/snowflake_time.dart';

import '../../../helpers/open_test_database.dart';

String _recentSnowflake({Duration ago = const Duration(minutes: 30)}) {
  final DateTime utc = DateTime.now().toUtc().subtract(ago);
  final int internal = (utc.millisecondsSinceEpoch - kSnowflakeEpochMs) << 22;
  return internal.toString();
}

Future<void> _seedAccountGuild({
  required FluxerDatabase db,
  required String userId,
  required String guildId,
  required String channelId,
  required String unreadMessageId,
}) async {
  await db.guildDao.upsertServer(
    ServersCompanion.insert(
      id: guildId,
      name: 'Guild $guildId',
      ownerId: Value(userId),
    ),
  );
  await db.memberDao.upsertMember(
    MembersCompanion.insert(
      userId: userId,
      guildId: guildId,
      joinedAt: Value(DateTime.utc(2026)),
    ),
  );
  await db.channelDao.upsertChannel(
    ChannelsCompanion.insert(
      id: channelId,
      guildId: guildId,
      name: 'general',
      type: const Value(0),
      lastMessageId: Value(unreadMessageId),
    ),
  );
  await db.readStateDao.upsertReadState(
    ReadStatesCompanion(
      channelId: Value(channelId),
      lastMessageId: Value(snowflakeAtPreviousMillisecond(unreadMessageId)),
    ),
  );
  await db.messageDao.upsertMessage(
    MessagesCompanion.insert(
      id: unreadMessageId,
      channelId: channelId,
      authorId: 'someone-else',
      content: 'unread hello',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        snowflakeTimestampMs(unreadMessageId),
        isUtc: true,
      ),
    ),
  );
}

void main() {
  test(
    'switching accounts while GuildReadState._seedAll is in flight seeds the new account and drops the old account state',
    () async {
      final bool prevWarn = driftRuntimeOptions.dontWarnAboutMultipleDatabases;
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      addTearDown(
        () => driftRuntimeOptions.dontWarnAboutMultipleDatabases = prevWarn,
      );
      final FluxerDatabase dbA = openTestDatabase();
      final FluxerDatabase dbB = openTestDatabase();

      final String msgA = _recentSnowflake(ago: const Duration(minutes: 20));
      final String msgB = _recentSnowflake(ago: const Duration(minutes: 10));

      await _seedAccountGuild(
        db: dbA,
        userId: 'user-a',
        guildId: 'guild-a',
        channelId: 'chan-a',
        unreadMessageId: msgA,
      );
      await _seedAccountGuild(
        db: dbB,
        userId: 'user-b',
        guildId: 'guild-b',
        channelId: 'chan-b',
        unreadMessageId: msgB,
      );

      final ProviderContainer container = ProviderContainer(
        overrides: [
          fluxerDatabaseProvider.overrideWithValue(dbA),
          currentUserIdProvider.overrideWithValue('user-a'),
          shellDataReadyProvider.overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);

      // Keep guildReadStateProvider watched across the account switch, matching
      // the live shell.
      final ProviderSubscription<Map<String, GuildReadStateEntry>> sub =
          container.listen(guildReadStateProvider, (_, _) {});
      addTearDown(sub.close);

      // Immediately switch to user-b while user-a's _seedAll(dbA, 'user-a') is
      // still awaiting SQLite queries.
      container.updateOverrides([
        fluxerDatabaseProvider.overrideWithValue(dbB),
        currentUserIdProvider.overrideWithValue('user-b'),
        shellDataReadyProvider.overrideWithValue(true),
      ]);

      // Allow all in-flight and queued seeds to finish.
      for (int i = 0; i < 40; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        final Map<String, GuildReadStateEntry> current = container.read(
          guildReadStateProvider,
        );
        if ((current['guild-b']?.hasUnread ?? false) &&
            !current.containsKey('guild-a')) {
          break;
        }
      }

      final Map<String, GuildReadStateEntry> finalState = container.read(
        guildReadStateProvider,
      );
      expect(
        finalState.containsKey('guild-a'),
        isFalse,
        reason: 'Account A guild unread state leaked into Account B',
      );
      expect(
        finalState['guild-b']?.hasUnread,
        isTrue,
        reason: 'Account B initial guild unread seed was dropped',
      );
    },
  );
}
