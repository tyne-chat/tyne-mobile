// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: the account's persona groups (tyne-chat/tyne#829), for the Personas
// settings page and the persona editor.
//
// Requests: one `GET /users/@me/personas/groups` when something first reads
// the groups (the settings page or the editor), shared while it runs. A
// failure leaves the list empty and is not asked again by itself: the next
// READY asks again (`reloadPersonaGroupsIfLoaded`), and nothing asks per
// build. Every change is one request (create, rename, delete, or one
// `PATCH …/groups/members` for any number of memberships), never retried; a
// failure is the caller's to show. The server then sends the account's
// sessions `USER_PERSONA_GROUPS_UPDATE` with the whole list, which replaces
// this one without a request.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/providers/app/account_user_id.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_app/features/profile/domain/persona_group.dart';

class PersonaGroupsNotifier extends Notifier<List<PersonaGroup>> {
  Future<void>? _inFlight;

  /// Bumped by every build, that is every account change: an answer to a
  /// request made before it belongs to the previous account and is dropped.
  /// Riverpod keeps this instance across builds, so the counter only grows.
  int _epoch = 0;

  /// Bumped by every build and every change that knows better than a load in
  /// flight, so that the load's older answer is dropped.
  int _generation = 0;

  @override
  List<PersonaGroup> build() {
    final String? account = accountUserIdOrNull(ref, watch: true);
    _epoch++;
    _generation++;
    _inFlight = null;
    // Signed out: nothing to load, and no request without an account.
    if (account != null && account.isNotEmpty) {
      unawaited(reloadSilently());
    }
    return const <PersonaGroup>[];
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
      final Dio dio = ref.read(fluxerDioProvider);
      final Response<dynamic> response = await dio.get<dynamic>(
        '/users/@me/personas/groups',
      );
      if (!ref.mounted || generation != _generation) {
        return;
      }
      state = PersonaGroup.listFromJson(response.data);
    } on Object catch (err, st) {
      talker.warning(
        '[PersonaGroupsNotifier] Failed to load persona groups: $err',
        err,
        st,
      );
    }
  }

  /// Whether an answer to a request made at [epoch] still belongs here.
  bool _current(int epoch) => ref.mounted && epoch == _epoch;

  /// The whole list, from `USER_PERSONA_GROUPS_UPDATE` or a change's answer.
  void replaceAll(List<PersonaGroup> groups) {
    _generation++;
    state = List<PersonaGroup>.unmodifiable(groups);
  }

  /// Makes a group named [name], with [personaIds] in it.
  Future<PersonaGroup?> create(
    String name, {
    List<String> personaIds = const <String>[],
  }) async {
    final int epoch = _epoch;
    final Dio dio = ref.read(fluxerDioProvider);
    final Response<dynamic> response = await dio.post<dynamic>(
      '/users/@me/personas/groups',
      data: <String, Object?>{
        'name': name,
        if (personaIds.isNotEmpty) 'persona_ids': personaIds,
      },
    );
    final PersonaGroup? group = PersonaGroup.fromJson(response.data);
    if (group != null && _current(epoch)) {
      replaceAll(<PersonaGroup>[
        for (final PersonaGroup g in state)
          if (g.id != group.id) g,
        group,
      ]);
    }
    return group;
  }

  Future<void> rename(String groupId, String name) async {
    final int epoch = _epoch;
    final Dio dio = ref.read(fluxerDioProvider);
    await dio.patch<dynamic>(
      '/users/@me/personas/groups/$groupId',
      data: <String, Object?>{'name': name},
    );
    if (_current(epoch)) {
      replaceAll(<PersonaGroup>[
        for (final PersonaGroup g in state)
          if (g.id == groupId) g.copyWith(name: name) else g,
      ]);
    }
  }

  /// Deletes the group; its personas stay as they are.
  Future<void> delete(String groupId) async {
    final int epoch = _epoch;
    final Dio dio = ref.read(fluxerDioProvider);
    await dio.delete<dynamic>('/users/@me/personas/groups/$groupId');
    if (_current(epoch)) {
      replaceAll(<PersonaGroup>[
        for (final PersonaGroup g in state)
          if (g.id != groupId) g,
      ]);
    }
  }

  /// Sends [changes] in one request, and nothing when there are none.
  Future<void> changeMembers(List<PersonaGroupMemberChange> changes) async {
    final List<PersonaGroupMemberChange> real = <PersonaGroupMemberChange>[
      for (final PersonaGroupMemberChange c in changes)
        if (!c.isEmpty) c,
    ];
    if (real.isEmpty) {
      return;
    }
    final int epoch = _epoch;
    final Dio dio = ref.read(fluxerDioProvider);
    final Response<dynamic> response = await dio.patch<dynamic>(
      '/users/@me/personas/groups/members',
      data: <String, Object?>{
        'changes': <Map<String, Object?>>[
          for (final PersonaGroupMemberChange c in real) c.toJson(),
        ],
      },
    );
    if (_current(epoch) && response.data is List) {
      replaceAll(PersonaGroup.listFromJson(response.data));
    }
  }
}

/// Fork: the account's persona groups (tyne-chat/tyne#829). It watches the
/// signed-in account, so every way of changing account (switch, Add Account,
/// sign-out, a stored account taking over) starts it again; account switches
/// also invalidate it (`resetPersonaStateForAccountChange`).
final NotifierProvider<PersonaGroupsNotifier, List<PersonaGroup>>
personaGroupsProvider =
    NotifierProvider<PersonaGroupsNotifier, List<PersonaGroup>>(
      PersonaGroupsNotifier.new,
    );

/// At READY: loads the groups again where something already reads them, since
/// changes made while disconnected sent no event here. Nothing otherwise.
void reloadPersonaGroupsIfLoaded(Ref ref) {
  if (ref.exists(personaGroupsProvider)) {
    unawaited(ref.read(personaGroupsProvider.notifier).reloadSilently());
  }
}

/// `USER_PERSONA_GROUPS_UPDATE`: the whole list replaces the one held here.
/// Nothing is loaded when nothing reads the groups yet.
void applyPersonaGroupsEvent(Ref ref, Object? data) {
  if (ref.exists(personaGroupsProvider)) {
    ref
        .read(personaGroupsProvider.notifier)
        .replaceAll(PersonaGroup.listFromJson(data));
  }
}
