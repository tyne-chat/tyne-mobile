import 'dart:async';

import 'package:fluxer_app/core/providers/app/app_ui_lifecycle_provider.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/providers/gateway/gateway_ready_provider.dart';
import 'package:fluxer_app/features/channels/data/read_state_write_batcher.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Fork imports.
// ignore: directives_ordering
import 'package:fluxer_app/features/channels/data/fork_read_state_write_batcher.dart';

part 'read_state_write_batcher_provider.g.dart';

@Riverpod(keepAlive: true)
class ReadStateOverlayVersion extends _$ReadStateOverlayVersion {
  @override
  int build() => 0;

  void bump() => state++;
}

@Riverpod(keepAlive: true)
ReadStateWriteBatcher readStateWriteBatcher(Ref ref) {
  // Fork: a batcher that stores acks as soon as they are queued (tyne-chat/tyne#466).
  final batcher = ForkReadStateWriteBatcher(
    database: ref.watch(fluxerDatabaseProvider),
    onOverlayChanged: () {
      if (!ref.mounted) {
        return;
      }
      ref.read(readStateOverlayVersionProvider.notifier).bump();
    },
  );

  ref
    ..listen<bool>(appUiForegroundProvider, (prev, next) {
      if ((prev ?? false) && !next) {
        unawaited(batcher.flushAll());
      }
    })
    ..listen<bool>(gatewayReadyProvider, (prev, next) {
      if ((prev ?? false) && !next) {
        unawaited(batcher.flushAll());
      }
    })
    ..onDispose(() {
      unawaited(batcher.dispose());
    });
  return batcher;
}
