import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kCollapsedKey = 'signal_bar_collapsed_v1';

/// Whether the strip is collapsed to just its caret: one value per account on
/// this device, for every channel, not synced, as on the web.
/// `currentUserIdProvider` rebuilds this on an account switch.
class SignalBarCollapsedNotifier extends Notifier<bool> {
  String? _storageKey;

  /// Whether the caret was pressed since [build]: a slower read of the stored
  /// value must not undo that.
  bool _pressed = false;

  @override
  bool build() {
    final String? userId = ref.watch(currentUserIdProvider);
    final String? storageKey = userId == null
        ? null
        : '${_kCollapsedKey}_$userId';
    _storageKey = storageKey;
    _pressed = false;
    if (storageKey != null) {
      unawaited(_load(storageKey));
    }
    return false;
  }

  Future<void> _load(String storageKey) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool? stored = prefs.getBool(storageKey);
      if (stored != null &&
          ref.mounted &&
          _storageKey == storageKey &&
          !_pressed) {
        state = stored;
      }
    } on Object {
      // Stays expanded, as for someone who never collapsed it.
    }
  }

  void toggle() {
    _pressed = true;
    state = !state;
    final String? storageKey = _storageKey;
    if (storageKey != null) {
      unawaited(_save(storageKey, collapsed: state));
    }
  }

  Future<void> _save(String storageKey, {required bool collapsed}) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(storageKey, collapsed);
    } on Object {
      // Holds until the app restarts, as it did before it was stored.
    }
  }
}

final NotifierProvider<SignalBarCollapsedNotifier, bool>
signalBarCollapsedProvider = NotifierProvider<SignalBarCollapsedNotifier, bool>(
  SignalBarCollapsedNotifier.new,
);
