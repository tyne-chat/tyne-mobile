// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/providers/multi_persona_reactions_provider.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Fork: the small caret at the end of a reaction chip that says a tap opens
/// "Your reactions" instead of reacting (tyne-chat/tyne#86). It shows on a chip
/// one of the account's identities reacted with, for an account that has
/// personas, while "React as several personas at once" is on: the cases in
/// which `openOwnReactionsSheetOnChipTap` opens the sheet.
///
/// A chip nobody of yours reacted with reads no provider at all.
class PersonaReactionChipCaret extends ConsumerWidget {
  const PersonaReactionChipCaret({
    required this.reaction,
    required this.messageId,
    required this.color,
    super.key,
  });

  final Reaction reaction;

  /// Null where a tap cannot open the sheet (system messages).
  final String? messageId;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!reaction.hasReacted || messageId == null) {
      return const SizedBox.shrink();
    }
    if (!ref.watch(multiPersonaReactionsProvider)) {
      return const SizedBox.shrink();
    }
    final bool hasPersonas = ref.watch(
      myPersonasProvider.select(
        (AsyncValue<List<Persona>> personas) =>
            personas.asData?.value.isNotEmpty ?? false,
      ),
    );
    if (!hasPersonas) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 3),
      child: Icon(PhosphorIconsBold.caretDown, size: 12, color: color),
    );
  }
}
