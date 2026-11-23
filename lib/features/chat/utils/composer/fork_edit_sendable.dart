// Fork: whether an edit in the composer can be saved (tyne-chat/tyne#904).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/domain/persona_matcher.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_markdown/fluxer_markdown.dart';

/// While a message is being edited, whether the composer's text can be saved;
/// null when no message is being edited, so that upstream's rule applies.
///
/// See [forkEditHasSendableContentFromParts] for the rule.
bool? forkEditHasSendableContent(
  WidgetRef ref,
  String wireText, {
  required bool hasPendingUploads,
}) {
  final Message? editing = ref.read(chatViewModelProvider).editingMessage;
  if (editing == null) {
    return null;
  }
  return forkEditHasSendableContentFromParts(
    editing: editing,
    wireText: wireText,
    hasPendingUploads: hasPendingUploads,
    personas: ref.read(myPersonasProvider).asData?.value ?? const <Persona>[],
  );
}

/// An edit replaces the text with whatever follows the persona tag, a tag
/// changes the persona, and an edit cannot leave a message with nothing in it.
///
/// - Text left after the tag: the edit can be saved.
/// - No text left, on a message with attachments or stickers (or files being
///   added): the edit removes the text, and a tag also changes the persona.
///   It can be saved when it does either, so an empty box on a message that
///   never had text still offers nothing to save.
/// - No text left on a message with nothing else: it cannot be saved. A tag
///   with nothing after it counts as no text, as an empty box does.
bool forkEditHasSendableContentFromParts({
  required Message editing,
  required String wireText,
  required bool hasPendingUploads,
  required List<Persona> personas,
}) {
  final EditMatchResult match = matchEditMessage(
    content: wireText.trim(),
    personas: personas,
    currentPersonaId: editing.personaId,
    originalContent: editing.content,
  );
  if (hasVisibleContent(match.finalContent)) {
    return true;
  }
  if (hasPendingUploads) {
    return true;
  }
  if (editing.attachments.isEmpty && !editing.hasStickers) {
    return false;
  }
  return hasVisibleContent(editing.content) || match.shouldUpdatePersona;
}
