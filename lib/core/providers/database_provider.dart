import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Fork imports.
// ignore: directives_ordering
import 'package:fluxer_app/core/database/fork_database_close.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
FluxerDatabase fluxerDatabase(Ref ref) {
  final db = FluxerDatabase();
  // Fork: close() fails late when the database never opened (tyne-chat/tyne#823).
  ref.onDispose(db.closeOnDispose);
  return db;
}
