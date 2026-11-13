// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/features/chat/presentation/sheets/persona_picker_sheet.dart';
import 'package:fluxer_app/features/profile/data/known_personas.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/domain/persona_image_urls.dart';
import 'package:fluxer_app/features/profile/domain/persona_matcher.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:fluxer_app/features/ui/avatar/fluxer_avatar.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/utils/fluxer_haptics.dart';

class PersonaComposerPill extends ConsumerWidget {
  const PersonaComposerPill({
    required this.text,
    this.hasAttachments = false,
    this.channelId,
    this.personaChannelId,
    super.key,
  });

  final String text;
  final bool hasAttachments;

  /// The channel this pill's composer writes to. Left out by composers for a
  /// thread or post that does not exist yet.
  final String? channelId;

  /// The channel whose persona selection this pill shows and changes, when it
  /// is not [channelId]: the channel a new thread or post is opened from.
  final String? personaChannelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personasAsync = ref.watch(myPersonasProvider);
    final personas = personasAsync.asData?.value ?? const [];
    final activeState = ref.watch(activePersonaProvider);
    final String? selectionChannelId = personaChannelId ?? channelId;
    final String? latchedId = activeState.latchedIdFor(selectionChannelId);

    if (!watchPersonaPillVisible(ref)) {
      return const SizedBox.shrink();
    }
    // Before the list loads, a selected persona is drawn from the device's
    // copy of it.
    final bool listMissing = personasAsync.asData == null;
    final KnownPersona? knownLatched = listMissing && latchedId != null
        ? ref.watch(knownPersonaProvider(latchedId)).asData?.value
        : null;

    final l10n = FluxerLocalizations.of(context);
    final userSettings = ref.watch(userSettingsViewModelProvider);

    final PreviewResult preview = previewPersona(
      text,
      personas,
      latchedId,
      hasAttachments: hasAttachments,
    );

    final Persona? effectivePersona = preview.persona;
    final bool isFromTag = preview.isFromTag;
    final bool isLatched = latchedId != null;

    final String? avatarUrl = effectivePersona != null
        ? personaImageHash(effectivePersona.avatarHash)
        : knownLatched != null
        ? personaImageHash(knownLatched.avatar)
        : userSettings.avatarUrl;
    final String fallbackName = effectivePersona != null
        ? effectivePersona.name
        : knownLatched != null
        ? knownLatched.name
        : (userSettings.displayName.isNotEmpty
              ? userSettings.displayName
              : userSettings.username);
    final int? avatarColor =
        effectivePersona?.color ??
        knownLatched?.color ??
        userSettings.avatarColor;

    final String tooltip = isFromTag && effectivePersona != null
        ? l10n.fork.personaSendingAsTag(effectivePersona.name)
        : isLatched && effectivePersona != null
        ? l10n.fork.personaSendingAsLatched(effectivePersona.name)
        : isLatched && knownLatched != null
        ? l10n.fork.personaSendingAsLatched(knownLatched.name)
        : l10n.fork.personaSendingAsRoot(userSettings.username);

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FluxerHaptics.light();
          unawaited(
            PersonaPickerSheet.show(
              context,
              signalChannelId: channelId,
              personaChannelId: selectionChannelId,
            ),
          );
        },
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          // The avatar alone, whether the persona is latched, matched by its
          // tag or the account itself: no ring and no badge
          // (tyne-chat/tyne#626). The border stays, transparent, so the avatar
          // keeps its size.
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.transparent, width: 1.2),
            ),
            child: ClipOval(
              child: FluxerAvatar.user(
                userId: userSettings.userId,
                imageUrl: avatarUrl,
                fallbackText: fallbackName,
                avatarColor: avatarColor,
                size: 28,
                showStatus: false,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Whether the composer shows the persona pill: the account has personas, or
/// their list has not loaded yet and it had personas when it last did. Sends
/// are held then (tyne-chat/tyne#30), and the pill, with the picker it opens,
/// is how the selection is seen and changed back to the account.
bool watchPersonaPillVisible(WidgetRef ref) {
  final List<Persona>? personas = ref.watch(myPersonasProvider).asData?.value;
  if (personas != null) {
    return personas.isNotEmpty;
  }
  return ref.read(myPersonasProvider.notifier).hadPersonas;
}
