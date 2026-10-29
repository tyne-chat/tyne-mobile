import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/synced_preferences/engine/synced_preference_field.dart';
import 'package:fluxer_app/core/synced_preferences/engine/synced_preferences_dirty.dart';
import 'package:fluxer_app/features/chat/utils/composer/emoticon_conversion.dart';

/// Fork: whether text emoticons are turned into emoji when a message is sent or
/// edited (tyne-chat/tyne#260). It is the web app's "Turn text smileys into
/// emoji", `ChatInputSettings.convert_emoticons` in the synced preferences
/// (`ChatInputSyncedField`), so it follows the account across the web, desktop
/// and phones. Off until the server says otherwise, as on the web; held in
/// memory and refilled at each hydrate, like upstream's other chat input
/// settings.
class ConvertEmoticonsPreference extends Notifier<bool> {
  @override
  bool build() {
    ref.watch(currentUserIdProvider);
    return false;
  }

  Future<void> applySynced({required bool value}) async {
    state = value;
    _preloadIfOn();
  }

  Future<void> setConvertEmoticons({required bool value}) async {
    state = value;
    _preloadIfOn();
    ref.markSyncedDirty(SyncedPreferenceField.chatInput);
  }

  void _preloadIfOn() {
    if (state) {
      unawaited(preloadEmoticonTable());
    }
  }
}

final NotifierProvider<ConvertEmoticonsPreference, bool>
convertEmoticonsPreferenceProvider =
    NotifierProvider<ConvertEmoticonsPreference, bool>(
      ConvertEmoticonsPreference.new,
    );

/// Fork: [text] with its emoticons turned into emoji when the setting is on
/// and the table has loaded; otherwise [text] unchanged.
String convertOutgoingEmoticons(Ref ref, String text) {
  if (text.isEmpty || !ref.read(convertEmoticonsPreferenceProvider)) {
    return text;
  }
  final Map<String, String>? table = emoticonTableSync;
  if (table == null) {
    unawaited(preloadEmoticonTable());
    return text;
  }
  return convertEmoticonsToEmoji(text, table);
}
