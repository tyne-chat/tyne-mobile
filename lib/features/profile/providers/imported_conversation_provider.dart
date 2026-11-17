// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: your DM with a Discord import placeholder that holds the imported
// history (tyne-chat/tyne#696). Once closed it can be opened again, so the
// placeholder's profile offers Open DM, but only when there is one.
//
// Requests: one per placeholder, shared by everything that shows its
// profile, and the answer is kept until the app restarts, since only an
// import changes it. A failure is kept for a minute after nothing shows it,
// so reopening the profile does not repeat it at once; the next profile
// opened after that asks again.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_dart/export.dart';

/// How long a failure stays after nothing shows it any more; tests change it.
final Provider<Duration> importedConversationFailureCooldownProvider =
    Provider<Duration>((Ref ref) => const Duration(minutes: 1));

/// The id of your DM with the placeholder with this id when it holds
/// messages, else null. Ask it only for placeholders.
final FutureProviderFamily<String?, String>
importedConversationProvider = FutureProvider.autoDispose.family<String?, String>(
  (Ref ref, String userId) async {
    // Whose DMs they are depends on who asks.
    ref.watch(currentUserIdProvider);
    final Duration cooldown = ref.watch(
      importedConversationFailureCooldownProvider,
    );
    final KeepAliveLink link = ref.keepAlive();
    bool failed = false;
    bool unwatched = false;
    Timer? release;
    void releaseLater() {
      release?.cancel();
      release = Timer(cooldown, link.close);
    }

    ref
      ..onCancel(() {
        unwatched = true;
        if (failed) {
          releaseLater();
        }
      })
      ..onResume(() {
        unwatched = false;
        release?.cancel();
        release = null;
      })
      ..onDispose(() => release?.cancel());
    try {
      final ImportedConversationResponse response = await ref
          .watch(fluxerClientProvider)
          .users
          .getImportedConversation(userId: userId);
      return response.channelId;
    } on Object catch (err, st) {
      talker.warning(
        '[importedConversationProvider] Failed to ask for the imported conversation with $userId: $err',
        err,
        st,
      );
    }
    failed = true;
    if (unwatched) {
      releaseLater();
    }
    return null;
  },
  // A failure is an answer of none here, never an error, so Riverpod has
  // nothing to repeat; and it must not.
  retry: (int retryCount, Object error) => null,
);
