// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: changing the visibility of, or deleting, many of the account's
// personas at once (tyne-chat/tyne#542), for the Personas settings page's
// select mode.
//
// Requests: one `PATCH /users/@me/personas/visibility` or one
// `POST /users/@me/personas/bulk-delete` per 250 personas (the server's
// limit; each request is all or nothing), and nothing at all when no persona
// would change. Undo is one more PATCH carrying each persona's previous
// visibility. Nothing is retried: a failure is the caller's to show. The
// server then sends the account's sessions one `USER_PERSONAS_UPDATE` (one
// list reload each, as for a single change), and for a delete clears the
// selection and the per-channel selections naming the deleted personas,
// which this device also does at once.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';

/// The most personas the server takes in one bulk request.
const int kPersonaBulkLimit = 250;

/// The visibilities a persona can have.
const List<String> kPersonaVisibilities = <String>[
  'public',
  'unlisted',
  'private',
];

/// A visibility change that went through, with what Undo puts back.
@immutable
class PersonaVisibilityChange {
  const PersonaVisibilityChange({
    required this.visibility,
    required this.previous,
  });

  /// The visibility the personas got.
  final String visibility;

  /// Each changed persona's visibility before, by id.
  final Map<String, String> previous;

  int get count => previous.length;
}

class PersonaBulkActions {
  PersonaBulkActions(this._ref);

  final Ref _ref;

  List<Persona> get _personas =>
      _ref.read(myPersonasProvider).asData?.value ?? const <Persona>[];

  /// Gives [visibility] to those of the personas with [ids] that do not have
  /// it yet. Null when none needed changing, and then nothing is sent.
  Future<PersonaVisibilityChange?> setVisibility(
    Iterable<String> ids,
    String visibility,
  ) async {
    final Set<String> wanted = ids.toSet();
    final Map<String, String> previous = <String, String>{
      for (final Persona p in _personas)
        if (wanted.contains(p.id) && p.visibility != visibility)
          p.id: p.visibility,
    };
    if (previous.isEmpty) {
      return null;
    }
    await _patch(<String, String>{
      for (final String id in previous.keys) id: visibility,
    });
    return PersonaVisibilityChange(visibility: visibility, previous: previous);
  }

  /// Puts back each persona's visibility from before [change], in one
  /// request, for those still there and still changed.
  Future<void> undo(PersonaVisibilityChange change) async {
    final Map<String, String> target = <String, String>{
      for (final Persona p in _personas)
        if (change.previous[p.id] case final String before
            when before != p.visibility)
          p.id: before,
    };
    if (target.isEmpty) {
      return;
    }
    await _patch(target);
  }

  /// Deletes the personas with [ids] and drops them here. Returns how many
  /// were deleted; none are asked for when none is the account's.
  Future<int> delete(Iterable<String> ids) async {
    final Set<String> wanted = ids.toSet();
    final List<String> existing = <String>[
      for (final Persona p in _personas)
        if (wanted.contains(p.id)) p.id,
    ];
    if (existing.isEmpty) {
      return 0;
    }
    final Dio dio = _ref.read(fluxerDioProvider);
    for (final List<String> chunk in _chunks(existing)) {
      await dio.post<dynamic>(
        '/users/@me/personas/bulk-delete',
        data: <String, dynamic>{'persona_ids': chunk},
      );
      _forgetDeleted(chunk);
    }
    return existing.length;
  }

  Future<void> _patch(Map<String, String> target) async {
    final Dio dio = _ref.read(fluxerDioProvider);
    for (final List<String> chunk in _chunks(target.keys.toList())) {
      final Response<dynamic> response = await dio.patch<dynamic>(
        '/users/@me/personas/visibility',
        data: <String, dynamic>{
          'personas': <Map<String, String>>[
            for (final String id in chunk)
              <String, String>{'id': id, 'visibility': target[id]!},
          ],
        },
      );
      _applyVisibility(response.data, <String, String>{
        for (final String id in chunk) id: target[id]!,
      });
    }
  }

  /// Shows the new visibilities at once, in one change of the list: those the
  /// server says it changed, or all that were asked for when its answer says
  /// nothing.
  void _applyVisibility(Object? data, Map<String, String> asked) {
    final Set<String>? changed = data is List
        ? <String>{
            for (final Object? item in data)
              if (item is Map && item['id'] is String) item['id'] as String,
          }
        : null;
    _ref.read(myPersonasProvider.notifier).replacePersonas(<Persona>[
      for (final Persona p in _personas)
        if (asked[p.id] case final String visibility
            when changed == null || changed.contains(p.id))
          p.copyWith(visibility: visibility),
    ]);
  }

  /// What the server also clears for deleted personas, done here at once so
  /// that nothing goes out as one of them before its events arrive.
  void _forgetDeleted(List<String> ids) {
    _ref.read(myPersonasProvider.notifier).removePersonas(ids);
    final ActivePersonaNotifier active = _ref.read(
      activePersonaProvider.notifier,
    );
    final ActivePersonaState state = _ref.read(activePersonaProvider);
    final Set<String> gone = ids.toSet();
    if (state.activePersonaId != null && gone.contains(state.activePersonaId)) {
      active.syncFromSettings(
        mode: state.mode,
        activeId: null,
        isLatched: false,
        scope: state.scope,
      );
    }
    for (final MapEntry<String, String> entry
        in state.channelPersonaIds.entries) {
      if (gone.contains(entry.value)) {
        active.applyChannelState(entry.key, null);
      }
    }
  }
}

Iterable<List<String>> _chunks(List<String> ids) sync* {
  for (int start = 0; start < ids.length; start += kPersonaBulkLimit) {
    final int end = start + kPersonaBulkLimit < ids.length
        ? start + kPersonaBulkLimit
        : ids.length;
    yield ids.sublist(start, end);
  }
}

/// Fork: bulk persona changes for the Personas settings page.
final Provider<PersonaBulkActions> personaBulkActionsProvider =
    Provider<PersonaBulkActions>(PersonaBulkActions.new);
