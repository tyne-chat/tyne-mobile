// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/features/chat/domain/cloud_composer_attachments.dart';
import 'package:fluxer_app/features/chat/providers/upload/cloud_upload_controller.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/domain/persona_matcher.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/features/signal_bar/providers/signal_persona_affirmation.dart';

class OutgoingMessageResolution {
  const OutgoingMessageResolution({
    required this.text,
    required this.personaData,
    this.persona,
    this.wasEscaped = false,
    this.clearedLatch = false,
    this.matched = false,
  });

  final String text;
  final Map<String, dynamic>? personaData;
  final Persona? persona;
  final bool wasEscaped;
  final bool clearedLatch;
  final bool matched;
}

Future<OutgoingMessageResolution> resolveOutgoingPersona({
  required WidgetRef ref,
  required String rawText,
  required String channelId,
  bool allowEmptyContent = false,
  bool? hasAttachments,
  String? personaChannelId,
}) => _resolveOutgoingPersona(
  ref.read,
  rawText: rawText,
  channelId: channelId,
  allowEmptyContent: allowEmptyContent,
  hasAttachments: hasAttachments,
  personaChannelId: personaChannelId,
);

/// What a forward and its comment go out as in [channelId]. They are one thing
/// said by one speaker, so a tag in [comment] decides for both. Without one they
/// use the persona selected where the forward started, which is the one on
/// screen, and then the destination's, so that the account does not turn up in
/// a channel where a persona was chosen. Call it once per destination.
Future<OutgoingMessageResolution> resolveForwardPersona(
  SignalProviderReader read, {
  required String sourceChannelId,
  required String channelId,
  required String comment,
}) {
  final Persona? sourcePersona = latchedPersonaFor(
    read(activePersonaProvider),
    read(myPersonasProvider).asData?.value ?? const <Persona>[],
    sourceChannelId,
  );
  return _resolveOutgoingPersona(
    read,
    rawText: comment,
    channelId: channelId,
    allowEmptyContent: true,
    hasAttachments: false,
    personaChannelId: sourcePersona == null ? channelId : sourceChannelId,
  );
}

Future<OutgoingMessageResolution> _resolveOutgoingPersona(
  SignalProviderReader read, {
  required String rawText,
  required String channelId,
  bool allowEmptyContent = false,
  bool? hasAttachments,
  String? personaChannelId,
}) async {
  final personas = read(myPersonasProvider).asData?.value ?? const [];
  final activeState = read(activePersonaProvider);
  // Whose selection applies. The composer of a thread or post that does not
  // exist yet has no channel of its own to send in ([channelId] is empty) and
  // names the channel it is opened from here.
  final String selectionChannelId = personaChannelId ?? channelId;
  // A composer that keeps its own files (the forum post sheet) says so itself.
  final bool hasPendingAttachments =
      hasAttachments ??
      channelId.isNotEmpty &&
          read(
            cloudUploadControllerProvider(
              channelId,
            ).select((CloudComposerAttachments a) => a.items.isNotEmpty),
          );

  final String? latchedId = activeState.latchedIdFor(selectionChannelId);
  final MatchResult matchResult = matchPersona(
    rawText,
    personas,
    latchedId,
    hasAttachments: hasPendingAttachments,
    allowEmptyContent: allowEmptyContent,
  );

  // The message is being sent in this channel, so the signals lit in it name
  // whoever it goes out as. A thread or post that does not exist yet passes no
  // channel and changes nothing.
  affirmSignalPersona(
    read,
    channelId,
    matchResult.matched ? matchResult.persona : null,
  );

  if (matchResult.clearedLatch ||
      (matchResult.wasEscaped && activeState.mode == PersonaMode.last)) {
    await read(
      activePersonaProvider.notifier,
    ).unlatch(channelId: selectionChannelId);
  } else if (matchResult.matched && matchResult.persona != null) {
    unawaited(
      read(activePersonaProvider.notifier).recordUsage(matchResult.persona!.id),
    );
    if (activeState.mode == PersonaMode.last &&
        latchedId != matchResult.persona!.id) {
      await read(activePersonaProvider.notifier).setActivePersona(
        matchResult.persona!.id,
        mode: PersonaMode.last,
        channelId: selectionChannelId,
      );
    }
  }

  final String finalOutgoingText = matchResult.matched || matchResult.wasEscaped
      ? matchResult.strippedContent
      : rawText;

  Map<String, dynamic>? personaData;
  if (matchResult.matched && matchResult.persona != null) {
    final systemTag = read(systemDisplayTagProvider);
    personaData = matchResult.persona!.toSubprofilePayload(
      displayTagText: systemTag.text,
      displayTagIcon: systemTag.iconUrl,
    );
  }

  return OutgoingMessageResolution(
    text: finalOutgoingText,
    personaData: personaData,
    persona: matchResult.persona,
    wasEscaped: matchResult.wasEscaped,
    clearedLatch: matchResult.clearedLatch,
    matched: matchResult.matched,
  );
}
