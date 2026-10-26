import 'package:drift/drift.dart';
import 'package:fluxer_app/core/database/daos/user_preferences_dao.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/features/emoji/domain/emoji_pins.dart';

/// Fork: the pinned emojis' column of `user_preferences`, one row per account
/// (tyne-chat/tyne#140).
extension EmojiPinsStorage on UserPreferencesDao {
  Future<EmojiPins> getEmojiPins(String userId) async =>
      EmojiPins.fromJson((await getPreferences(userId))?.emojiPinsJson);

  Future<void> setEmojiPins(String userId, EmojiPins pins) => savePreferences(
    UserPreferencesTableCompanion(
      userId: Value<String>(userId),
      emojiPinsJson: Value<String>(pins.toJson()),
    ),
  );
}
