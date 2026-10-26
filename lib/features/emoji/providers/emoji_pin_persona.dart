import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/domain/persona_matcher.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';

/// Reads a provider once: the `read` of a `WidgetRef`, a `Ref` or a
/// `ProviderContainer`.
typedef EmojiPinProviderReader = T Function<T>(ProviderListenable<T> provider);

/// Fork: the persona whose pins count in [channelId] (tyne-chat/tyne#237), for
/// "Pin for this persona" and the quick reactions, as the web's
/// `PersonaStore.getEffectiveReactionPersona(channelId, null, draft)` has it:
/// the persona a tag in the open channel's draft names, else the one selected
/// for the channel, else null for the account. Without personas it reads
/// nothing else.
String? emojiPinPersonaIdFor(EmojiPinProviderReader read, String? channelId) {
  final List<Persona> personas =
      read(myPersonasProvider).asData?.value ?? const <Persona>[];
  if (personas.isEmpty) {
    return null;
  }
  final String? latchedId = read(activePersonaProvider).latchedIdFor(channelId);
  final ChatViewState chat = read(chatViewModelProvider);
  if (channelId != null &&
      channelId.isNotEmpty &&
      chat.channelId == channelId) {
    final PreviewResult preview = previewPersona(
      chat.messageText,
      personas,
      latchedId,
      hasAttachments: false,
    );
    if (preview.isFromTag && preview.persona != null) {
      return preview.persona!.id;
    }
  }
  return latchedId;
}
