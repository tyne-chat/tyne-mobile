import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/synced_preferences/engine/proto_synced_field_adapter.dart';
import 'package:fluxer_app/core/synced_preferences/engine/synced_preference_field.dart';
import 'package:fluxer_app/core/synced_preferences/generated/fluxer/user/preferences/v1/fork_emoji_pins.pb.dart'
    as pins_pb;
import 'package:fluxer_app/core/synced_preferences/generated/fluxer/user/preferences/v1/preferences.pb.dart'
    as pb;
import 'package:fluxer_app/features/emoji/data/emoji_pins_storage.dart';
import 'package:fluxer_app/features/emoji/domain/emoji_pins.dart';
import 'package:fluxer_app/features/emoji/providers/emoji_pins_provider.dart';

/// Fork: the pinned emojis, the fork's top-level field 2200 (`emoji_pins`,
/// tyne-chat/tyne#140), which the web writes too.
///
/// Remote wins, as for favourites. A field missing from the blob means nobody
/// has pinned yet, not that pins were cleared: the web sends an empty message
/// when the last pin goes. So there is no `clearedRemoteValue`, and pins made
/// here before any other device pinned are kept and pushed.
class EmojiPinsSyncedField
    extends ProtoSyncedFieldAdapter<EmojiPins, pins_pb.EmojiPinsState> {
  EmojiPinsSyncedField(this._ref);

  final Ref _ref;

  @override
  SyncedPreferenceField get field => SyncedPreferenceField.emojiPins;

  @override
  bool get keepsUnpushedEditsAcrossLaunches => true;

  @override
  EmojiPins readLocal() {
    throw UnsupportedError('Use readLocalValue for the pinned emojis');
  }

  @override
  Future<EmojiPins> readLocalValue() async {
    final String? userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      return EmojiPins.empty;
    }
    return _ref
        .read(fluxerDatabaseProvider)
        .userPreferencesDao
        .getEmojiPins(userId);
  }

  @override
  Future<void> applyRemote(EmojiPins value) async {
    final String? userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }
    await _ref
        .read(fluxerDatabaseProvider)
        .userPreferencesDao
        .setEmojiPins(userId, value);
    _ref.invalidate(emojiPinsProvider);
  }

  @override
  bool hasField(pb.SyncedPreferences message) => message.hasEmojiPins();

  @override
  pins_pb.EmojiPinsState readSubMessage(pb.SyncedPreferences message) =>
      message.emojiPins;

  @override
  EmojiPins fromProto(pins_pb.EmojiPinsState proto) =>
      EmojiPins.fromProto(proto);

  @override
  void writeProto(pins_pb.EmojiPinsState proto, EmojiPins local) {
    local.writeProto(proto);
  }

  @override
  pins_pb.EmojiPinsState createEmptyProto() => pins_pb.EmojiPinsState();

  @override
  pb.SyncedPreferences wrapProto(pins_pb.EmojiPinsState proto) =>
      pb.SyncedPreferences(emojiPins: proto);

  @override
  bool statesEqual(EmojiPins a, EmojiPins b) => a == b;

  @override
  bool hasLocalData(EmojiPins local) => !local.isEmpty;
}
