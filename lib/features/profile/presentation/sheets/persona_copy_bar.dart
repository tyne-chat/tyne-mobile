// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:math' as math;

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button_size.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// The bar at the bottom of a new persona that starts as a copy of another
/// (tyne-chat/tyne#599): the copy is unsaved from the start, so unlike
/// upstream's `FluxerSaveBar`, whose look it shares, it is always up, and it
/// offers Cancel and Create instead of Reset and Save. It sits below the
/// form, and its bottom padding is the safe area left once the keyboard has
/// taken its share (none while the keyboard is up).
class PersonaCopyBar extends StatelessWidget {
  const PersonaCopyBar({
    required this.label,
    required this.onCancel,
    required this.onCreate,
    this.isSaving = false,
    super.key,
  });

  final String label;
  final VoidCallback onCancel;
  final VoidCallback onCreate;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.backgroundSecondaryAlt,
        border: Border(top: BorderSide(color: colors.borderColor)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: layout.s4,
          right: layout.s4,
          top: layout.s3,
          bottom: math.max(layout.s3, MediaQuery.paddingOf(context).bottom),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.bodyMedium.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(width: layout.s2),
            FluxerButton.secondary(
              onPressed: isSaving ? null : onCancel,
              label: l10n.cancel,
              size: FluxerButtonSize.small,
              fitContent: true,
            ),
            SizedBox(width: layout.s2),
            FluxerButton.primary(
              onPressed: isSaving ? null : onCreate,
              label: l10n.create,
              size: FluxerButtonSize.small,
              isLoading: isSaving,
              fitContent: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// The badge on a copy's preview banner: the copy looks like the persona it
/// came from, so this says which one is being edited, where people look
/// (tyne-chat/tyne#599, after someone edited the original thinking it was the
/// copy). Taps go through to the banner below it.
class PersonaCopyBadge extends StatelessWidget {
  const PersonaCopyBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.brandPrimary,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x73000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PhosphorIcon(
                PhosphorIconsBold.plus,
                size: 12,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: context.textStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
