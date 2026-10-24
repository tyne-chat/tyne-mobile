// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/profile/data/known_personas.dart';
import 'package:fluxer_app/features/profile/data/persona_lookup.dart';
import 'package:fluxer_app/features/profile/providers/public_persona_provider.dart';
import 'package:fluxer_dart/export.dart';

/// Fork: another account changed its personas without saying which (the
/// server never names a private persona in an event). Shortly after, the
/// personas of that account this device holds are fetched again, in one
/// request for all accounts collected, and nothing is fetched if it holds
/// none. One edit arrives once per community the two accounts share, plus
/// once for direct messages, all at the same moment, hence the [delay].
class PersonaRefresher {
  PersonaRefresher({
    required this.heldPersonaIds,
    required this.lookup,
    required this.apply,
    this.onRefreshed,
    this.delay = const Duration(seconds: 1),
  });

  /// The personas of an account this device shows or has stored.
  final Future<List<String>> Function(String userId) heldPersonaIds;
  final Future<PersonaLookupItemSchema?> Function(
    PersonaLookupPair pair, {
    bool force,
  })
  lookup;

  /// Shows a persona fetched again where it appears.
  final Future<void> Function(PersonaLookupItemSchema item) apply;

  /// Called once per batch with the accounts it covered.
  final void Function(Set<String> userIds)? onRefreshed;
  final Duration delay;

  final Set<String> _pendingUserIds = <String>{};
  Timer? _timer;
  Completer<void>? _idle;

  /// Completes once the refreshes requested so far have been fetched and
  /// shown.
  @visibleForTesting
  Future<void> get idle => _idle?.future ?? Future<void>.value();

  void request(String userId) {
    if (userId.isEmpty) {
      return;
    }
    _pendingUserIds.add(userId);
    if (_timer == null) {
      _idle ??= Completer<void>();
      _timer = Timer(delay, () => unawaited(_flush()));
    }
  }

  Future<void> _flush() async {
    _timer = null;
    try {
      final Set<String> userIds = Set<String>.of(_pendingUserIds);
      _pendingUserIds.clear();
      onRefreshed?.call(userIds);
      final List<PersonaLookupPair> pairs = <PersonaLookupPair>[
        for (final String userId in userIds)
          for (final String personaId in await heldPersonaIds(userId))
            (userId: userId, personaId: personaId),
      ];
      if (pairs.isEmpty) {
        return;
      }
      final List<PersonaLookupItemSchema?> found = await Future.wait(
        <Future<PersonaLookupItemSchema?>>[
          for (final PersonaLookupPair pair in pairs) lookup(pair, force: true),
        ],
      );
      for (final PersonaLookupItemSchema item
          in found.whereType<PersonaLookupItemSchema>()) {
        await apply(item);
      }
    } finally {
      if (_timer == null) {
        final Completer<void>? idle = _idle;
        _idle = null;
        idle?.complete();
      }
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _pendingUserIds.clear();
    final Completer<void>? idle = _idle;
    _idle = null;
    idle?.complete();
  }
}

/// How long to collect "this account changed its personas" events before
/// fetching; tests shorten it.
final personaRefreshDelayProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 1),
);

/// Fork: the refresher for this account's view of other accounts' personas.
final personaRefresherProvider = Provider<PersonaRefresher>((ref) {
  final PersonaLookupBatcher batcher = ref.watch(personaLookupBatcherProvider);
  final PersonaRefresher refresher = PersonaRefresher(
    heldPersonaIds: (String userId) =>
        knownPersonaIdsOf(ref.read(fluxerDatabaseProvider), userId),
    lookup: batcher.lookup,
    apply: (PersonaLookupItemSchema item) async {
      await upsertKnownPersonaFromLookup(
        ref.read(fluxerDatabaseProvider),
        item,
      );
      ref
          .read(chatViewModelProvider.notifier)
          .onPersonaUpdated(
            personaId: item.id,
            name: item.name,
            avatar: item.avatar,
            tag: item.displayTagText,
            tagIcon: item.displayTagIcon,
          );
    },
    // A profile card of that account may have just become private.
    onRefreshed: (_) => ref.invalidate(publicPersonaProvider),
    delay: ref.watch(personaRefreshDelayProvider),
  );
  ref.onDispose(refresher.dispose);
  return refresher;
});
