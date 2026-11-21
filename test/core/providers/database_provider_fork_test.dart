// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: disposing the database provider must not leave an error behind when the database never
// opened. Without a Flutter binding the open fails, and close() used to rethrow that failure one
// event-loop turn after the dispose, failing whichever test was running then
// (tyne-chat/tyne#823).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';

void main() {
  test('disposing a database that never opened leaves no error behind', () async {
    final ProviderContainer container = ProviderContainer();
    final db = container.read(fluxerDatabaseProvider);
    // No binding here, so finding the database file fails, and so does the open.
    await expectLater(db.customSelect('SELECT 1').get(), throwsA(anything));

    container.dispose();
    // close() waits for an event-loop turn before it gets to the failed open; any error it left
    // unhandled would land inside this test and fail it.
    await pumpEventQueue();
  });
}
