// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/profile/data/known_personas.dart';
import 'package:fluxer_dart/export.dart';

/// A persona named by its owner and its ID.
typedef PersonaLookupPair = ({String userId, String personaId});

class _PendingLookup {
  _PendingLookup(this.pair);

  final PersonaLookupPair pair;
  final List<Completer<PersonaLookupItemSchema?>> waiting =
      <Completer<PersonaLookupItemSchema?>>[];
}

String _keyOf(PersonaLookupPair pair) => '${pair.userId}:${pair.personaId}';

/// Fork: collects persona lookups made close together into one request to
/// `POST /personas/lookup`. Lookups of the same persona share one answer, and
/// a persona whose lookup failed is not asked for again until a cooldown has
/// passed, so code that looks personas up while building cannot flood the
/// server (the global rate limit ends the session).
class PersonaLookupBatcher {
  PersonaLookupBatcher(
    this._send, {
    this.delay = const Duration(milliseconds: 50),
    this.failureCooldown = const Duration(minutes: 1),
    this.notFoundCooldown = const Duration(minutes: 10),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// The most personas one request takes.
  static const int maxPerRequest = 100;

  final Future<List<PersonaLookupItemSchema>> Function(
    List<PersonaLookupPair> pairs,
  )
  _send;
  final Duration delay;
  final Duration failureCooldown;
  final Duration notFoundCooldown;
  final DateTime Function() _now;

  final Map<String, _PendingLookup> _pending = <String, _PendingLookup>{};
  final Map<String, Future<PersonaLookupItemSchema?>> _inFlight =
      <String, Future<PersonaLookupItemSchema?>>{};
  final Map<String, DateTime> _failedUntil = <String, DateTime>{};
  final Map<String, DateTime> _notFoundUntil = <String, DateTime>{};
  Timer? _timer;
  int _generation = 0;

  /// Looks up one persona; null when it is not found or the request fails.
  /// [force] asks again for a persona answered as not found, but never inside
  /// the cooldown after a failure.
  Future<PersonaLookupItemSchema?> lookup(
    PersonaLookupPair pair, {
    bool force = false,
  }) {
    final String key = _keyOf(pair);
    final DateTime now = _now();
    final DateTime? failedUntil = _failedUntil[key];
    if (failedUntil != null && failedUntil.isAfter(now)) {
      return Future<PersonaLookupItemSchema?>.value();
    }
    final DateTime? notFoundUntil = _notFoundUntil[key];
    if (!force && notFoundUntil != null && notFoundUntil.isAfter(now)) {
      return Future<PersonaLookupItemSchema?>.value();
    }
    final Future<PersonaLookupItemSchema?>? flying = _inFlight[key];
    if (flying != null) {
      return flying;
    }
    final Completer<PersonaLookupItemSchema?> completer =
        Completer<PersonaLookupItemSchema?>();
    (_pending[key] ??= _PendingLookup(pair)).waiting.add(completer);
    _timer ??= Timer(delay, _flush);
    return completer.future;
  }

  /// Forgets everything, as when the account changes; answers still on their
  /// way are dropped.
  void reset() {
    _timer?.cancel();
    _timer = null;
    for (final _PendingLookup pending in _pending.values) {
      for (final Completer<PersonaLookupItemSchema?> c in pending.waiting) {
        c.complete();
      }
    }
    _pending.clear();
    _inFlight.clear();
    _failedUntil.clear();
    _notFoundUntil.clear();
    _generation++;
  }

  void _flush() {
    _timer = null;
    final List<MapEntry<String, _PendingLookup>> batch = _pending.entries
        .toList();
    _pending.clear();
    for (int i = 0; i < batch.length; i += maxPerRequest) {
      final int end = i + maxPerRequest < batch.length
          ? i + maxPerRequest
          : batch.length;
      unawaited(_sendChunk(batch.sublist(i, end)));
    }
  }

  Future<void> _sendChunk(List<MapEntry<String, _PendingLookup>> chunk) async {
    final int generation = _generation;
    final Completer<Map<String, PersonaLookupItemSchema>?> answer =
        Completer<Map<String, PersonaLookupItemSchema>?>();
    for (final MapEntry<String, _PendingLookup> entry in chunk) {
      _inFlight[entry.key] = answer.future.then(
        (Map<String, PersonaLookupItemSchema>? found) => found?[entry.key],
      );
    }
    Map<String, PersonaLookupItemSchema>? found;
    try {
      final List<PersonaLookupItemSchema> items = await _send(
        <PersonaLookupPair>[
          for (final MapEntry<String, _PendingLookup> entry in chunk)
            entry.value.pair,
        ],
      );
      found = <String, PersonaLookupItemSchema>{
        for (final PersonaLookupItemSchema item in items)
          _keyOf((userId: item.userId, personaId: item.id)): item,
      };
    } on Object {
      found = null;
    }
    answer.complete(found);
    final bool current = generation == _generation;
    final DateTime now = _now();
    for (final MapEntry<String, _PendingLookup> entry in chunk) {
      final PersonaLookupItemSchema? item = found?[entry.key];
      if (current) {
        // The answer itself is delivered through the completers below.
        unawaited(_inFlight.remove(entry.key));
        if (found == null) {
          _failedUntil[entry.key] = now.add(failureCooldown);
        } else if (item == null) {
          _notFoundUntil[entry.key] = now.add(notFoundCooldown);
        } else {
          _notFoundUntil.remove(entry.key);
        }
      }
      for (final Completer<PersonaLookupItemSchema?> c in entry.value.waiting) {
        c.complete(current ? item : null);
      }
    }
  }
}

/// Fork: the one batcher every persona lookup of this account goes through.
final personaLookupBatcherProvider = Provider<PersonaLookupBatcher>((ref) {
  final Dio dio = ref.watch(fluxerDioProvider);
  final PersonaLookupBatcher batcher = PersonaLookupBatcher((
    List<PersonaLookupPair> pairs,
  ) async {
    final Response<dynamic> response = await dio.post<dynamic>(
      '/personas/lookup',
      data: <String, dynamic>{
        'personas': <Map<String, String>>[
          for (final PersonaLookupPair pair in pairs)
            <String, String>{
              'user_id': pair.userId,
              'persona_id': pair.personaId,
            },
        ],
      },
    );
    final Object? data = response.data;
    return <PersonaLookupItemSchema>[
      if (data is List)
        for (final Object? item in data)
          if (item is Map)
            PersonaLookupItemSchema.fromJson(Map<String, Object?>.from(item)),
    ];
  });
  ref.onDispose(batcher.reset);
  return batcher;
});

/// Fork: what a message from a persona shows, looked up by ID (which also
/// names a private persona) and remembered with its owner.
// The family type is long and says nothing the next line does not.
// ignore: specify_nonobvious_property_types
final personaLookupProvider = FutureProvider.autoDispose
    .family<PersonaLookupItemSchema?, PersonaLookupPair>((
      ref,
      PersonaLookupPair pair,
    ) async {
      final PersonaLookupItemSchema? item = await ref
          .watch(personaLookupBatcherProvider)
          .lookup(pair);
      if (item != null) {
        await upsertKnownPersonaFromLookup(
          ref.read(fluxerDatabaseProvider),
          item,
        );
      }
      return item;
    });
