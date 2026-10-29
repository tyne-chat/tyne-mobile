import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/synced_preferences/engine/proto_synced_field_adapter.dart';
import 'package:fluxer_app/core/synced_preferences/engine/synced_preference_field.dart';
import 'package:fluxer_app/core/synced_preferences/generated/fluxer/user/preferences/v1/preferences.pb.dart'
    as pb;
import 'package:fluxer_app/features/settings/providers/preferences/convert_emoticons_preference.dart';

/// Fork: upstream's top-level `chat_input` (112), which upstream's app does not
/// read. The phone takes `convert_emoticons` from it, the web's "Turn text
/// smileys into emoji" (tyne-chat/tyne#260).
///
/// Written as the web writes it: `true`, or the field left out when off. A push
/// starts from the server's copy, so the other fields in `chat_input` (the old
/// `save_camera_captures_to_device`, read by `SaveCameraUploadsSyncedField`)
/// go back as they came. A blob without `chat_input` means off, as on the web.
class ChatInputSyncedField
    extends ProtoSyncedFieldAdapter<bool, pb.ChatInputSettings> {
  ChatInputSyncedField(this._ref);

  final Ref _ref;

  @override
  SyncedPreferenceField get field => SyncedPreferenceField.chatInput;

  @override
  bool readLocal() => _ref.read(convertEmoticonsPreferenceProvider);

  @override
  Future<void> applyRemote(bool value) => _ref
      .read(convertEmoticonsPreferenceProvider.notifier)
      .applySynced(value: value);

  @override
  bool hasField(pb.SyncedPreferences message) => message.hasChatInput();

  @override
  pb.ChatInputSettings readSubMessage(pb.SyncedPreferences message) =>
      message.chatInput;

  @override
  bool fromProto(pb.ChatInputSettings proto) => proto.convertEmoticons;

  @override
  void writeProto(pb.ChatInputSettings proto, bool local) {
    if (local) {
      proto.convertEmoticons = true;
    } else {
      proto.clearConvertEmoticons();
    }
  }

  @override
  pb.ChatInputSettings createEmptyProto() => pb.ChatInputSettings();

  @override
  pb.SyncedPreferences wrapProto(pb.ChatInputSettings proto) =>
      pb.SyncedPreferences(chatInput: proto);

  @override
  bool statesEqual(bool a, bool b) => a == b;

  @override
  bool hasLocalData(bool local) => local;

  @override
  bool? clearedRemoteValue() => false;
}
