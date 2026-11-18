// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: "Forward as ..." in the Forward sheet (tyne-chat/tyne#817), shaped like
// the new thread sheet's "Sending as" row.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/domain/forward_as.dart';
import 'package:fluxer_app/features/chat/presentation/sheets/persona_picker_sheet.dart';
import 'package:fluxer_app/features/chat/utils/composer/composer_persona_resolution.dart';
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
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Who the forward goes out as: [picked], else the default the row shows.
ForwardAs chosenForwardAs(
  WidgetRef ref, {
  required ForwardAs? picked,
  required String sourceChannelId,
}) => picked ?? defaultForwardAs(ref.read, sourceChannelId: sourceChannelId);

/// Who the forward and its comment go out as, and a tap to change it. It shows
/// what will be sent: a tag in the comment still decides, as it does in the
/// message box. Renders nothing for a user without personas.
class ForwardAsPersonaRow extends ConsumerWidget {
  const ForwardAsPersonaRow({
    required this.sourceChannelId,
    required this.comment,
    required this.picked,
    required this.onPick,
    super.key,
  });

  final String sourceChannelId;

  /// The comment as typed so far.
  final String comment;

  /// The sheet's pick, null until someone picks.
  final ForwardAs? picked;
  final ValueChanged<ForwardAs> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Persona> personas =
        ref.watch(myPersonasProvider).asData?.value ?? const <Persona>[];
    if (personas.isEmpty) {
      return const SizedBox.shrink();
    }
    ref.watch(activePersonaProvider);
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final userSettings = ref.watch(userSettingsViewModelProvider);
    final ForwardAs chosen = chosenForwardAs(
      ref,
      picked: picked,
      sourceChannelId: sourceChannelId,
    );
    final MatchResult said = matchPersona(
      comment,
      personas,
      chosen.persona?.id,
      hasAttachments: false,
      allowEmptyContent: true,
    );
    final Persona? shown = said.isFromTag
        ? said.persona
        : said.wasEscaped
        ? null
        : chosen.persona;
    final String accountName = userSettings.displayName.isNotEmpty
        ? userSettings.displayName
        : userSettings.username;
    final String name = shown?.name ?? accountName;
    final String label = l10n.fork.forwardAsName(name);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        key: const ValueKey<String>('forward-as-persona-row'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FluxerHaptics.light();
          unawaited(
            PersonaPickerSheet.show(
              context,
              showModes: false,
              selectedPersonaId: chosen.persona?.id,
              title: l10n.fork.forwardAs,
              onSelectPersona: (Persona persona) =>
                  onPick(ForwardAs.persona(persona)),
              onSelectRoot: () => onPick(const ForwardAs.account()),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.only(bottom: context.layout.s2),
          child: Row(
            children: <Widget>[
              ClipOval(
                child: FluxerAvatar.user(
                  userId: userSettings.userId,
                  imageUrl: shown != null
                      ? personaImageHash(shown.avatarHash)
                      : userSettings.avatarUrl,
                  fallbackText: name,
                  avatarColor: shown?.color ?? userSettings.avatarColor,
                  size: 24,
                  showStatus: false,
                ),
              ),
              SizedBox(width: context.layout.s2),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodySmall.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
              PhosphorIcon(
                PhosphorIconsBold.caretRight,
                size: 14,
                color: context.colors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
