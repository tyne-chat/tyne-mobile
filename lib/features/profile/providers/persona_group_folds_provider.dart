// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: which persona groups are folded in the Personas settings list
// (tyne-chat/tyne#829). Kept on this device only, per account, and never
// sent anywhere: one SharedPreferences entry per account holding the folded
// groups' ids (and `none` for "Not in a group").

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/providers/app/account_user_id.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersonaGroupFoldsNotifier extends Notifier<Set<String>> {
  static const String prefKeyPrefix = 'persona_group_folds_';

  String? _accountId;

  /// Whether a fold changed before the stored ones were read: the change wins.
  bool _changed = false;

  @override
  Set<String> build() {
    _accountId = accountUserIdOrNull(ref, watch: true);
    _changed = false;
    unawaited(_restore());
    return const <String>{};
  }

  String? get _prefKey {
    final String? account = _accountId;
    return account == null || account.isEmpty ? null : '$prefKeyPrefix$account';
  }

  Future<void> _restore() async {
    final String? key = _prefKey;
    if (key == null) {
      return;
    }
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? saved = prefs.getString(key);
      // Riverpod keeps this instance across account changes: folds read for
      // the previous account must not land on the next one.
      if (!ref.mounted || _changed || saved == null || key != _prefKey) {
        return;
      }
      final Object? list = jsonDecode(saved);
      if (list is List) {
        state = <String>{
          for (final Object? item in list)
            if (item is String) item,
        };
      }
    } on Object catch (_) {
      // Nothing folded.
    }
  }

  void toggle(String key) => _set(
    state.contains(key) ? (state.toSet()..remove(key)) : {...state, key},
  );

  void unfold(String key) {
    if (state.contains(key)) {
      _set(state.toSet()..remove(key));
    }
  }

  void _set(Set<String> next) {
    _changed = true;
    state = Set<String>.unmodifiable(next);
    unawaited(_save(next));
  }

  Future<void> _save(Set<String> folded) async {
    final String? key = _prefKey;
    if (key == null) {
      return;
    }
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(folded.toList()..sort()));
    } on Object catch (_) {
      // Kept for this session only.
    }
  }
}

/// Fork: the folded persona groups of the signed-in account, on this device.
final NotifierProvider<PersonaGroupFoldsNotifier, Set<String>>
personaGroupFoldsProvider =
    NotifierProvider<PersonaGroupFoldsNotifier, Set<String>>(
      PersonaGroupFoldsNotifier.new,
    );
