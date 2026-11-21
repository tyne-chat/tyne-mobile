import 'dart:async';

import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/talker.dart';

/// Fork: closes the database when its provider is disposed, with any error logged.
///
/// Riverpod drops the future of `ref.onDispose(db.close)`, so an error from `close()` was left
/// unhandled in whatever zone disposed the provider. In a test without a Flutter binding the
/// database never opens (its file is found through a platform channel), and `close()` rethrows
/// that failure one event-loop turn later, after the test has finished: upstream's
/// `account_scoped_memory_test.dart` failed on it now and then (tyne-chat/tyne#823). The app
/// never disposes the database provider, so this changes nothing there.
extension ForkDatabaseClose on FluxerDatabase {
  void closeOnDispose() {
    unawaited(
      close().catchError((Object error, StackTrace stackTrace) {
        talker.warning('[Database] close failed', error, stackTrace);
      }),
    );
  }
}
