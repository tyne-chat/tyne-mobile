import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/synced_preferences/engine/synced_preference_field.dart';
import 'package:fluxer_app/core/synced_preferences/engine/synced_preferences_dirty.dart';
import 'package:fluxer_app/features/emoji/data/emoji_pins_storage.dart';
import 'package:fluxer_app/features/emoji/domain/emoji_pins.dart';

/// Fork: the signed-in account's pinned emojis (tyne-chat/tyne#140), kept in
/// its `user_preferences` row and synced by `EmojiPinsSyncedField`. That
/// adapter writes what other devices send straight to the row and invalidates
/// this provider, so applying it never marks the field dirty.
class EmojiPinsNotifier extends AsyncNotifier<EmojiPins> {
  @override
  Future<EmojiPins> build() async {
    final String? userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      return EmojiPins.empty;
    }
    return ref
        .read(fluxerDatabaseProvider)
        .userPreferencesDao
        .getEmojiPins(userId);
  }

  /// Pins [key] for [personaId] (for the account without one), or unpins it
  /// when it is pinned there. Returns whether it is pinned afterwards, which is
  /// false too when a pin is refused (`EmojiPins.withPin`).
  Future<bool> togglePin(String key, {String? personaId}) async {
    final EmojiPins current = await future;
    final bool pinned = current.isPinnedIn(key, personaId: personaId);
    final EmojiPins? next = pinned
        ? current.withoutPin(key, personaId: personaId)
        : current.withPin(key, personaId: personaId);
    if (next == null) {
      return false;
    }
    await _save(current, next);
    return !pinned;
  }

  /// Drops a deleted persona's pins.
  Future<void> forgetPersona(String personaId) async {
    final EmojiPins current = await future;
    await _save(current, current.withoutPersona(personaId));
  }

  Future<void> _save(EmojiPins current, EmojiPins next) async {
    if (identical(current, next)) {
      return;
    }
    state = AsyncData<EmojiPins>(next);
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }
    await ref
        .read(fluxerDatabaseProvider)
        .userPreferencesDao
        .setEmojiPins(userId, next);
    ref.markSyncedDirty(SyncedPreferenceField.emojiPins);
  }
}

final AsyncNotifierProvider<EmojiPinsNotifier, EmojiPins> emojiPinsProvider =
    AsyncNotifierProvider<EmojiPinsNotifier, EmojiPins>(EmojiPinsNotifier.new);
