// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fork: the account's "React as several personas at once" setting
/// (tyne-chat/tyne#86), as reaction code reads it: synchronously, and without
/// starting a request.
///
/// It is the device's copy of `PersonaSettings.multiPersonaReactions`.
/// `PersonaSettingsNotifier` pushes every value the server sends here; this
/// provider never watches the settings itself, so reading it (every reacted
/// chip does, and so does every plain reaction toggle) cannot start the
/// settings request. The last value is remembered on the device, so a start
/// without network still follows the account's choice. Until a value is known
/// the setting counts as on, which is the server's default.
class MultiPersonaReactionsNotifier extends Notifier<bool> {
  static const String _prefKey = 'persona_multi_reactions';

  // Set once the server's value (or the user's change) arrived, and counted up
  // on every account change: a read of the remembered value that finishes
  // later is out of date and must not win.
  bool _known = false;
  int _generation = 0;
  Future<void> _writes = Future<void>.value();

  @override
  bool build() {
    _known = false;
    _generation++;
    unawaited(_readRemembered(_generation));
    return true;
  }

  Future<void> _readRemembered(int generation) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool? remembered = prefs.getBool(_prefKey);
      if (remembered != null &&
          ref.mounted &&
          !_known &&
          generation == _generation) {
        state = remembered;
      }
    } on Object catch (_) {
      // No preferences store (a test, a broken install): the default stands.
    }
  }

  /// Takes the value the account's settings hold and remembers it.
  void syncFromSettings({required bool enabled}) {
    _known = true;
    state = enabled;
    unawaited(
      _write((SharedPreferences prefs) => prefs.setBool(_prefKey, enabled)),
    );
  }

  /// Forgets the value when the account changes.
  Future<void> reset() {
    _known = false;
    _generation++;
    state = true;
    return _write((SharedPreferences prefs) => prefs.remove(_prefKey));
  }

  // One after the other, so a reset followed by the next account's value
  // cannot end with the value removed.
  Future<void> _write(Future<bool> Function(SharedPreferences prefs) write) {
    return _writes = _writes.then((_) async {
      try {
        await write(await SharedPreferences.getInstance());
      } on Object catch (_) {
        // Remembering is best effort.
      }
    });
  }
}

final multiPersonaReactionsProvider =
    NotifierProvider<MultiPersonaReactionsNotifier, bool>(
      MultiPersonaReactionsNotifier.new,
    );
