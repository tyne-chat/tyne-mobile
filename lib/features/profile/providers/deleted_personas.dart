// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: the account's deleted personas, and Restore, for the Deleted personas
// section at the end of the Personas settings page (tyne-chat/tyne#610; the
// web app's `DeletedPersonasSection`).
//
// Requests: one `GET /users/@me/personas/deleted` when the person asks for the
// list, shared while it runs. A failure waits for Retry; nothing asks again by
// itself. One `POST /users/@me/personas/deleted/<id>/restore` per Restore, one
// at a time. The server then sends `USER_PERSONAS_UPDATE`, which reloads the
// persona list once, as any persona change does; the restored persona shows
// at once from the answer. The state lives while the section is on screen,
// so opening the page again asks again.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';

enum DeletedPersonasStatus { closed, loading, failed, ready }

@immutable
class DeletedPersonasState {
  const DeletedPersonasState({
    this.status = DeletedPersonasStatus.closed,
    this.personas = const <Persona>[],
    this.restoringId,
  });

  final DeletedPersonasStatus status;

  /// The deleted personas, the most recently deleted first.
  final List<Persona> personas;

  /// The persona being restored, while its request runs.
  final String? restoringId;
}

/// A restored persona, and what it came back without because another persona
/// holds it now.
@immutable
class PersonaRestoreResult {
  const PersonaRestoreResult({
    required this.name,
    this.droppedTags = const <PersonaTag>[],
    this.droppedSignatureEmojis = const <String>[],
  });

  final String name;
  final List<PersonaTag> droppedTags;

  /// The names of the signature emojis left off.
  final List<String> droppedSignatureEmojis;
}

class DeletedPersonasNotifier extends Notifier<DeletedPersonasState> {
  Future<void>? _loading;

  @override
  DeletedPersonasState build() => const DeletedPersonasState();

  /// Asks for the list, or joins the request already running.
  Future<void> load() => _loading ??= _load().whenComplete(() {
    _loading = null;
  });

  Future<void> _load() async {
    state = DeletedPersonasState(
      status: DeletedPersonasStatus.loading,
      personas: state.personas,
    );
    try {
      final Response<dynamic> response = await ref
          .read(fluxerDioProvider)
          .get<dynamic>('/users/@me/personas/deleted');
      if (!ref.mounted) {
        return;
      }
      state = DeletedPersonasState(
        status: DeletedPersonasStatus.ready,
        personas: _personasFrom(response.data),
      );
    } on Object catch (err, st) {
      talker.warning(
        '[DeletedPersonas] Failed to load deleted personas: $err',
        err,
        st,
      );
      if (!ref.mounted) {
        return;
      }
      state = const DeletedPersonasState(status: DeletedPersonasStatus.failed);
    }
  }

  /// Brings back the deleted persona [id] and shows it in the persona list.
  /// Null, with nothing sent, while another restore runs or when [id] is not
  /// in the list. Throws when the server refuses, and the list stays as it
  /// was.
  Future<PersonaRestoreResult?> restore(String id) async {
    final Persona? deleted = state.personas
        .where((Persona p) => p.id == id)
        .firstOrNull;
    if (state.restoringId != null || deleted == null) {
      return null;
    }
    final MyPersonasNotifier myPersonas = ref.read(myPersonasProvider.notifier);
    _setRestoring(id);
    try {
      final Response<dynamic> response = await ref
          .read(fluxerDioProvider)
          .post<dynamic>('/users/@me/personas/deleted/$id/restore');
      final Object? data = response.data;
      final Map<String, dynamic>? body = data is Map
          ? Map<String, dynamic>.from(data)
          : null;
      final Object? persona = body?['persona'];
      if (persona is Map) {
        myPersonas.upsertPersona(
          Persona.fromJson(Map<String, dynamic>.from(persona)),
        );
      } else {
        await myPersonas.reloadSilently();
      }
      if (ref.mounted) {
        state = DeletedPersonasState(
          status: state.status,
          personas: <Persona>[
            for (final Persona p in state.personas)
              if (p.id != id) p,
          ],
        );
      }
      return PersonaRestoreResult(
        name: deleted.name,
        droppedTags: <PersonaTag>[
          for (final Object? tag
              in body?['dropped_tags'] as List<dynamic>? ?? const <dynamic>[])
            if (tag is Map) PersonaTag.fromJson(Map<String, dynamic>.from(tag)),
        ],
        droppedSignatureEmojis: <String>[
          for (final Object? emoji
              in body?['dropped_signature_emojis'] as List<dynamic>? ??
                  const <dynamic>[])
            if (emoji is Map && emoji['name'] is String)
              emoji['name'] as String,
        ],
      );
    } finally {
      if (ref.mounted && state.restoringId == id) {
        _setRestoring(null);
      }
    }
  }

  /// Puts personas just deleted on this device at the top of the list, when
  /// it is showing. Nothing is asked of the server.
  void personasDeleted(Iterable<Persona> personas) {
    if (state.status != DeletedPersonasStatus.ready) {
      return;
    }
    final DateTime now = DateTime.now();
    final Set<String> ids = <String>{for (final Persona p in personas) p.id};
    state = DeletedPersonasState(
      status: state.status,
      restoringId: state.restoringId,
      personas: <Persona>[
        for (final Persona p in personas) p.copyWith(deletedAt: now),
        for (final Persona p in state.personas)
          if (!ids.contains(p.id)) p,
      ],
    );
  }

  void _setRestoring(String? id) {
    state = DeletedPersonasState(
      status: state.status,
      personas: state.personas,
      restoringId: id,
    );
  }

  static List<Persona> _personasFrom(Object? data) => <Persona>[
    if (data is List)
      for (final Object? item in data)
        if (item is Map) Persona.fromJson(Map<String, dynamic>.from(item)),
  ];
}

/// Fork: the deleted personas for the Personas settings page's last section.
final NotifierProvider<DeletedPersonasNotifier, DeletedPersonasState>
deletedPersonasProvider =
    NotifierProvider.autoDispose<DeletedPersonasNotifier, DeletedPersonasState>(
      DeletedPersonasNotifier.new,
    );
