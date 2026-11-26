import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/synced_preferences/engine/synced_preference_field.dart';
import 'package:fluxer_app/core/synced_preferences/engine/synced_preferences_dirty.dart';

/// Fork: whether choosing an emoji in the message box adds a space after it
/// (tyne-chat/tyne#650). It mirrors the web app's "Add a space after emoji",
/// `AccessibilitySettings.space_after_emoji` (field 2229) in the synced
/// preferences (`AccessibilitySyncedField`), so it follows the account across
/// the web, desktop and phones. On by default, as before the setting existed;
/// held in memory and refilled from cached and live user settings at each
/// hydrate, like `ConvertEmoticonsPreference`.
class SpaceAfterEmojiPreference extends Notifier<bool> {
  @override
  bool build() {
    ref.watch(currentUserIdProvider);
    return true;
  }

  Future<void> applySynced({required bool value}) async {
    state = value;
  }

  Future<void> setSpaceAfterEmoji({required bool value}) async {
    state = value;
    ref.markSyncedDirty(SyncedPreferenceField.accessibility);
  }
}

final NotifierProvider<SpaceAfterEmojiPreference, bool>
spaceAfterEmojiPreferenceProvider =
    NotifierProvider<SpaceAfterEmojiPreference, bool>(
      SpaceAfterEmojiPreference.new,
    );
