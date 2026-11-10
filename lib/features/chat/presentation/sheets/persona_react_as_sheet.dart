import 'package:fluxer_app/features/chat/presentation/sheets/persona_reaction_sheet.dart';
import 'package:fluxer_app/material_ui.dart';

/// "React as…": the account's identities for one emoji on one message, each
/// with a toggle. The list itself is `persona_reaction_sheet.dart`'s, shared
/// with the "Your reactions" sheet a reaction chip opens.
class PersonaReactAsSheet {
  PersonaReactAsSheet._();

  /// [onReacted] runs once the sheet has closed, if a reaction was changed.
  static Future<void> show(
    BuildContext context, {
    required String channelId,
    required String messageId,
    required String emoji,
    String? emojiId,
    bool animated = false,
    VoidCallback? onReacted,
  }) => showPersonaReactionSheet(
    context,
    channelId: channelId,
    messageId: messageId,
    emoji: emoji,
    emojiId: emojiId,
    animated: animated,
    reactAs: true,
    onReacted: onReacted,
  );
}
