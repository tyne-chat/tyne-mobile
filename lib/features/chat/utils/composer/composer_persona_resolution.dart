// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/features/chat/domain/cloud_composer_attachments.dart';
import 'package:fluxer_app/features/chat/providers/upload/cloud_upload_controller.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/domain/persona_matcher.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:fluxer_app/features/signal_bar/providers/signal_persona_affirmation.dart';
import 'package:fluxer_app/features/ui/toast/fluxer_toast.dart';
import 'package:fluxer_app/features/ui/toast/toast_provider.dart';
import 'package:fluxer_app/l10n/app_locale_provider.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';

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

/// Who a message about to be sent goes out as, and its text without the tag.
///
/// Null means the send is held: the account had personas when the list last
/// loaded on this device, but the list (or, with personas chosen per channel,
/// the per-channel selections) has not loaded even after a wait, so sending
/// now could put the message under the account (tyne-chat/tyne#30). Other
/// accounts never wait. The caller then sends nothing and keeps what
/// was typed. A toast says why, with a "Send as @name" action when
/// [onSendAsAccount] is given: it should start the same send again, which then
/// goes out as the account once.
Future<OutgoingMessageResolution?> resolveOutgoingPersona({
  required WidgetRef ref,
  required String rawText,
  required String channelId,
  bool allowEmptyContent = false,
  bool? hasAttachments,
  String? personaChannelId,
  VoidCallback? onSendAsAccount,
}) => _resolveOutgoingPersona(
  ref.read,
  rawText: rawText,
  channelId: channelId,
  allowEmptyContent: allowEmptyContent,
  hasAttachments: hasAttachments,
  personaChannelId: personaChannelId,
  onSendAsAccount: onSendAsAccount,
);

/// What a forward and its comment go out as in [channelId]. They are one thing
/// said by one speaker, so a tag in [comment] decides for both. Without one they
/// use the persona selected where the forward started, which is the one on
/// screen, and then the destination's, so that the account does not turn up in
/// a channel where a persona was chosen. Call it once per destination. Null
/// when held, as [resolveOutgoingPersona] says.
Future<OutgoingMessageResolution?> resolveForwardPersona(
  SignalProviderReader read, {
  required String sourceChannelId,
  required String channelId,
  required String comment,
  VoidCallback? onSendAsAccount,
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
    onSendAsAccount: onSendAsAccount,
  );
}

Future<OutgoingMessageResolution?> _resolveOutgoingPersona(
  SignalProviderReader read, {
  required String rawText,
  required String channelId,
  bool allowEmptyContent = false,
  bool? hasAttachments,
  String? personaChannelId,
  VoidCallback? onSendAsAccount,
}) async {
  // Whose selection applies. The composer of a thread or post that does not
  // exist yet has no channel of its own to send in ([channelId] is empty) and
  // names the channel it is opened from here.
  final String selectionChannelId = personaChannelId ?? channelId;
  if (read(
    personaSendAsAccountOnceProvider.notifier,
  ).take(selectionChannelId)) {
    return OutgoingMessageResolution(text: rawText, personaData: null);
  }
  if (!_personasReady(read)) {
    final OutgoingMessageResolution? escaped = await _escapeWithoutPersonas(
      read,
      rawText,
      selectionChannelId,
    );
    if (escaped != null) {
      return escaped;
    }
    // Only an account that had personas when the list last loaded here waits
    // and can be held. Without one (or before the list has loaded once on
    // this device) a send goes out as before, at once.
    if (read(myPersonasProvider.notifier).hadPersonas &&
        !await _waitForPersonas(read)) {
      _showSendHeld(read, selectionChannelId, onSendAsAccount);
      return null;
    }
  }
  final personas = read(myPersonasProvider).asData?.value ?? const [];
  final activeState = read(activePersonaProvider);
  // A composer that keeps its own files (the forum post sheet) says so itself.
  final String? accountUserId = signalReaderAccountUserId(read);
  final bool hasPendingAttachments =
      hasAttachments ??
      channelId.isNotEmpty &&
          accountUserId != null &&
          read(
            cloudUploadControllerProvider(
              accountUserId,
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

/// Channels whose next send goes out as the account, once: what "Send as
/// @name" asks for after a send was held (tyne-chat/tyne#30).
class PersonaSendAsAccountOnce extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void mark(String channelId) {
    state = <String>{...state, channelId};
  }

  /// Whether [channelId] was marked, forgetting the mark.
  bool take(String channelId) {
    if (!state.contains(channelId)) {
      return false;
    }
    state = <String>{...state}..remove(channelId);
    return true;
  }
}

final personaSendAsAccountOnceProvider =
    NotifierProvider<PersonaSendAsAccountOnce, Set<String>>(
      PersonaSendAsAccountOnce.new,
    );

/// Whether the device knows who a message goes out as: the persona list has
/// loaded and, when personas are chosen per channel, so have the per-channel
/// selections. Before the settings arrive the device takes the selection to
/// be for every channel.
bool _personasReady(SignalProviderReader read) {
  final List<Persona>? personas = read(myPersonasProvider).asData?.value;
  if (personas == null) {
    return false;
  }
  return personas.isEmpty ||
      read(activePersonaProvider).scope != PersonaScope.channel ||
      read(activePersonaProvider.notifier).channelStatesLoaded;
}

/// Waits for what [_personasReady] needs, sharing loads in flight.
Future<bool> _waitForPersonas(SignalProviderReader read) async {
  final List<Persona>? personas = await read(
    myPersonasProvider.notifier,
  ).whenLoaded();
  if (personas == null) {
    return false;
  }
  if (personas.isEmpty ||
      read(activePersonaProvider).scope != PersonaScope.channel) {
    return true;
  }
  return read(activePersonaProvider.notifier).whenChannelStatesLoaded();
}

/// A leading backslash with a persona selected means "as the account", which
/// needs no persona list, so it neither waits nor is held. As in the matcher,
/// `\\` also deselects the persona, and so does `\` in "last" mode.
Future<OutgoingMessageResolution?> _escapeWithoutPersonas(
  SignalProviderReader read,
  String rawText,
  String selectionChannelId,
) async {
  final ActivePersonaState activeState = read(activePersonaProvider);
  if (!rawText.startsWith(r'\') ||
      activeState.latchedIdFor(selectionChannelId) == null) {
    return null;
  }
  final bool clearsLatch = rawText.startsWith(r'\\');
  final String rest = rawText.substring(clearsLatch ? 2 : 1);
  if (clearsLatch || activeState.mode == PersonaMode.last) {
    await read(
      activePersonaProvider.notifier,
    ).unlatch(channelId: selectionChannelId);
  }
  return OutgoingMessageResolution(
    text: rest.startsWith(' ') ? rest.substring(1) : rest,
    personaData: null,
    wasEscaped: true,
    clearedLatch: clearsLatch,
  );
}

void _showSendHeld(
  SignalProviderReader read,
  String selectionChannelId,
  VoidCallback? onSendAsAccount,
) {
  final ForkLocalizations l10n = read(appLocalizationsProvider).fork;
  final String username = read(userSettingsViewModelProvider).username;
  read(toastProvider.notifier).show(
    FluxerToast(
      message: l10n.personaSendHeldNotLoaded,
      variant: FluxerToastVariant.warning,
      duration: const Duration(seconds: 8),
      action: onSendAsAccount == null
          ? null
          : FluxerToastAction(
              label: l10n.personaSendAsAccountAction(username),
              onPressed: () {
                try {
                  read(
                    personaSendAsAccountOnceProvider.notifier,
                  ).mark(selectionChannelId);
                } on Object catch (_) {
                  // The composer that held it is gone; there is nothing to
                  // send again.
                  return;
                }
                onSendAsAccount();
              },
            ),
    ),
  );
}
