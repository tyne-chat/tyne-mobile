import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/synced_preferences/engine/synced_field_adapter.dart';
import 'package:fluxer_app/core/synced_preferences/fields/chat_input_synced_field.dart';
import 'package:fluxer_app/core/synced_preferences/fields/emoji_pins_synced_field.dart';

/// Fork: the adapters of the fork's own top-level fields, and of upstream's
/// that upstream's app does not read (`chat_input`). The store registers
/// them after upstream's (`registerDefaultSyncedFieldAdapters`), so upstream's
/// list and its test stay as upstream has them.
void registerForkSyncedFieldAdapters({
  required void Function(SyncedFieldAdapter<Object?> adapter) registerAdapter,
  required Ref ref,
}) {
  registerAdapter(EmojiPinsSyncedField(ref));
  registerAdapter(ChatInputSyncedField(ref));
}
