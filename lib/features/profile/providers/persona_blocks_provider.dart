// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: the personas this account has blocked (tyne-chat/tyne#921). A blocked
// persona's messages collapse into the "blocked messages" row, or are hidden
// with "Hide messages from blocked users", exactly as a blocked account's are
// (`ChannelCollapseContext.forkBlockedPersonaKeys`). Nothing else changes.
//
// Requests: one `GET /users/@me/personas/blocks` when the message list (or
// anything else) first reads the list, shared while it runs, and one at each
// READY once it is read, since changes made while disconnected sent no event.
// A failure leaves the list as it was and is not asked again by itself: the
// next READY or account change asks again, and nothing asks per build. A block
// or an unblock is one request, never retried; a failure is the caller's to
// show. The server then sends the account's sessions
// `USER_PERSONA_BLOCKS_UPDATE` with the whole list, which replaces this one
// without a request.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/providers/app/account_user_id.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_app/features/chat/utils/messages/fork_blocked_persona.dart';
import 'package:fluxer_dart/export.dart';

/// The keys of a list as the server sends it: `[{user_id, persona_id}, …]`,
/// bare or as the event's `{blocks: […]}`. Entries that cannot be read are
/// skipped.
Set<String> personaBlockKeysFromJson(Object? data) {
  final Object? list = data is Map ? data['blocks'] : data;
  if (list is! List) {
    return const <String>{};
  }
  final Set<String> keys = <String>{};
  for (final Object? entry in list) {
    if (entry is Map) {
      final Object? userId = entry['user_id'];
      final Object? personaId = entry['persona_id'];
      if (userId is String &&
          userId.isNotEmpty &&
          personaId is String &&
          personaId.isNotEmpty) {
        keys.add(personaBlockKey(userId, personaId));
      }
    }
  }
  return Set<String>.unmodifiable(keys);
}

Set<String> _keysOf(List<PersonaBlockResponseSchema> blocks) =>
    Set<String>.unmodifiable(
      blocks
          .where(
            (PersonaBlockResponseSchema b) =>
                b.userId.isNotEmpty && b.personaId.isNotEmpty,
          )
          .map(
            (PersonaBlockResponseSchema b) =>
                personaBlockKey(b.userId, b.personaId),
          ),
    );

class PersonaBlocksNotifier extends Notifier<Set<String>> {
  Future<void>? _inFlight;

  /// Bumped by every build, that is every account change: an answer to a
  /// request made before it belongs to the previous account and is dropped.
  int _epoch = 0;

  /// Bumped by every build and every newer list, so that an older load's
  /// answer is dropped.
  int _generation = 0;

  @override
  Set<String> build() {
    final String? account = accountUserIdOrNull(ref, watch: true);
    _epoch++;
    _generation++;
    _inFlight = null;
    // Signed out: nothing to load, and no request without an account.
    if (account != null && account.isNotEmpty) {
      unawaited(reloadSilently());
    }
    return const <String>{};
  }

  /// Loads the list again, sharing a load already under way.
  Future<void> reloadSilently() {
    final Future<void>? running = _inFlight;
    if (running != null) {
      return running;
    }
    late final Future<void> load;
    load = _load(_generation).whenComplete(() {
      if (identical(_inFlight, load)) {
        _inFlight = null;
      }
    });
    _inFlight = load;
    return load;
  }

  Future<void> _load(int generation) async {
    try {
      final FluxerClient client = ref.read(fluxerClientProvider);
      final List<PersonaBlockResponseSchema> blocks = await client.personas
          .listMyPersonaBlocks();
      if (!ref.mounted || generation != _generation) {
        return;
      }
      state = _keysOf(blocks);
    } on Object catch (err, st) {
      talker.warning(
        '[PersonaBlocksNotifier] Failed to load blocked personas: $err',
        err,
        st,
      );
    }
  }

  /// The whole list, from `USER_PERSONA_BLOCKS_UPDATE`.
  void replaceKeys(Set<String> keys) {
    _generation++;
    state = Set<String>.unmodifiable(keys);
  }

  bool isBlocked(String userId, String personaId) =>
      state.contains(personaBlockKey(userId, personaId));

  /// Blocks another account's persona. Throws when the request fails.
  Future<void> block(String userId, String personaId) async {
    final int epoch = _epoch;
    final List<PersonaBlockResponseSchema> blocks = await ref
        .read(fluxerClientProvider)
        .personas
        .blockPersona(userId: userId, personaId: personaId);
    if (ref.mounted && epoch == _epoch) {
      replaceKeys(_keysOf(blocks));
    }
  }

  /// Unblocks a persona. Throws when the request fails.
  Future<void> unblock(String userId, String personaId) async {
    final int epoch = _epoch;
    final List<PersonaBlockResponseSchema> blocks = await ref
        .read(fluxerClientProvider)
        .personas
        .unblockPersona(userId: userId, personaId: personaId);
    if (ref.mounted && epoch == _epoch) {
      replaceKeys(_keysOf(blocks));
    }
  }
}

/// Fork: the keys (`personaBlockKey`) of the personas this account has
/// blocked (tyne-chat/tyne#921). It watches the signed-in account, so every
/// way of changing account starts it again.
final NotifierProvider<PersonaBlocksNotifier, Set<String>>
blockedPersonaKeysProvider =
    NotifierProvider<PersonaBlocksNotifier, Set<String>>(
      PersonaBlocksNotifier.new,
    );

/// At READY: loads the list again where something already reads it, since
/// changes made while disconnected sent no event here. Nothing otherwise.
void reloadPersonaBlocksIfLoaded(Ref ref) {
  if (ref.read(blockedPersonaKeysProvider.exists)) {
    unawaited(ref.read(blockedPersonaKeysProvider.notifier).reloadSilently());
  }
}

/// `USER_PERSONA_BLOCKS_UPDATE`: the whole list replaces the one held here.
/// Nothing is loaded when nothing reads the list yet.
void applyPersonaBlocksEvent(Ref ref, Object? data) {
  if (ref.read(blockedPersonaKeysProvider.exists)) {
    ref
        .read(blockedPersonaKeysProvider.notifier)
        .replaceKeys(personaBlockKeysFromJson(data));
  }
}
