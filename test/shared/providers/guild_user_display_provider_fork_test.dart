// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: a name already shown asks for its member again once a READY leaves the
// cached row unconfirmed, though the row itself did not change
// (tyne-chat/tyne#614).

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/gateway/fork_member_confirmation.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/providers/gateway/gateway_session_recovery_provider.dart';
import 'package:fluxer_app/features/members/providers/guild_member_chunk_waiter.dart';
import 'package:fluxer_app/shared/providers/guild_user_display_provider.dart';
import 'package:fluxer_app/shared/services/guild_member_hydration_service.dart';
import 'package:fluxer_app/shared/utils/guild_user_display.dart';
import 'package:fluxer_dart/export.dart';

import '../../helpers/open_test_database.dart';

class _RecordingHydrationService extends GuildMemberHydrationService {
  _RecordingHydrationService({required super.database})
    : super(
        client: FluxerClient(
          Dio(BaseOptions(baseUrl: 'https://test.fluxer.invalid/v1')),
        ),
        chunkWaiter: GuildMemberChunkWaiter(),
        readGateway: () => null,
      );

  final List<List<String>> requested = <List<String>>[];

  @override
  void requestHydration({
    required String guildId,
    required Iterable<String> userIds,
    void Function(String userId)? onMemberFetched,
  }) => requested.add(userIds.toList());
}

void main() {
  test(
    'a READY that leaves a shown member unconfirmed asks for it once',
    () async {
      final FluxerDatabase db = openTestDatabase();
      await db.userDao.upsertUser(
        UsersCompanion.insert(id: 'user-1', username: 'silvia'),
      );
      await db.memberDao.upsertMember(
        MembersCompanion.insert(
          userId: 'user-1',
          guildId: 'guild-1',
          nick: const Value('Silvia'),
          roleIdsJson: const Value('[]'),
        ),
      );
      final _RecordingHydrationService service = _RecordingHydrationService(
        database: db,
      );
      final ProviderContainer container = ProviderContainer(
        overrides: [
          fluxerDatabaseProvider.overrideWithValue(db),
          guildMemberHydrationServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);
      final ProviderSubscription<AsyncValue<GuildUserDisplay?>> sub = container
          .listen(
            guildUserDisplayProvider(('user-1', 'guild-1')),
            (_, _) {},
            fireImmediately: true,
          );
      addTearDown(sub.close);
      await pumpEventQueue();
      // Upstream asks while the member row is still loading.
      final int before = service.requested.length;

      ForkMemberConfirmation.of(
        db,
      ).startConnection(cacheKept: true, guildIds: <String>['guild-1']);
      container.read(gatewayFullRecoveryProvider.notifier).bump();
      await pumpEventQueue();
      expect(service.requested, hasLength(before + 1));
      expect(service.requested.last, <String>['user-1']);

      ForkMemberConfirmation.of(
        db,
      ).claimRequests('guild-1', <String>['user-1']);
      container.read(gatewayFullRecoveryProvider.notifier).bump();
      await pumpEventQueue();
      expect(service.requested, hasLength(before + 1));
    },
  );
}
