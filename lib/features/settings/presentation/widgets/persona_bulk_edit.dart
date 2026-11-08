// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: the pieces of the Personas settings page's select mode
// (tyne-chat/tyne#542): the visibility filter chips with their counts, the
// bar on top while selecting, the action bar at the bottom, and the
// confirmation before making personas public or private, or deleting them.
// The page (`user_persona_settings.dart`) holds the state and does the work.

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/settings/providers/persona_settings_launch_provider.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// The label of [filter]'s chip.
String personaVisibilityFilterLabel(
  FluxerLocalizations l10n,
  PersonaVisibilityFilter filter,
) => switch (filter) {
  PersonaVisibilityFilter.all => l10n.fork.personaFilterAll,
  PersonaVisibilityFilter.public => l10n.fork.personaVisibilityPublic,
  PersonaVisibilityFilter.unlisted => l10n.fork.personaVisibilityUnlisted,
  PersonaVisibilityFilter.private => l10n.fork.personaVisibilityPrivate,
};

/// "All N", "Public N", "Unlisted N", "Private N", as the members list's
/// filter chips.
class PersonaVisibilityChips extends StatelessWidget {
  const PersonaVisibilityChips({
    required this.counts,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final Map<PersonaVisibilityFilter, int> counts;
  final PersonaVisibilityFilter selected;
  final ValueChanged<PersonaVisibilityFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: PersonaVisibilityFilter.values.length,
        separatorBuilder: (BuildContext context, int index) =>
            SizedBox(width: context.layout.s2),
        itemBuilder: (BuildContext context, int index) {
          final PersonaVisibilityFilter filter =
              PersonaVisibilityFilter.values[index];
          return _FilterChip(
            key: ValueKey<String>('persona-filter-${filter.name}'),
            label: personaVisibilityFilterLabel(l10n, filter),
            count: counts[filter] ?? 0,
            isActive: filter == selected,
            onTap: () => onSelected(filter),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
    super.key,
  });

  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color foreground = isActive
        ? colors.textOnBrandPrimary
        : colors.textSecondary;
    return FluxerTappable(
      onTap: onTap,
      selected: isActive,
      semanticLabel: '$label $count',
      excludeChildSemantics: true,
      builder: (BuildContext context, Set<WidgetState> states) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? colors.brandPrimary : colors.backgroundSecondary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: context.textStyles.label.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: context.textStyles.label.copyWith(
                color: foreground.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The bar on top while selecting: leave select mode, how many are
/// selected, and select all that show, or none when all are.
class PersonaSelectionBar extends StatelessWidget {
  const PersonaSelectionBar({
    required this.selectedCount,
    required this.allShownSelected,
    required this.canSelectAll,
    required this.onClose,
    required this.onSelectAll,
    super.key,
  });

  final int selectedCount;
  final bool allShownSelected;

  /// Whether anything shows to select.
  final bool canSelectAll;
  final VoidCallback onClose;

  /// Selects every persona that shows, or clears them when all are.
  final VoidCallback onSelectAll;

  @override
  Widget build(BuildContext context) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final colors = context.colors;
    final layout = context.layout;
    return Container(
      key: const ValueKey<String>('persona-selection-bar'),
      padding: EdgeInsets.symmetric(horizontal: layout.s2, vertical: layout.s1),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        border: Border(bottom: BorderSide(color: colors.borderColor)),
      ),
      child: Row(
        children: <Widget>[
          FluxerButton.ghost(
            key: const ValueKey<String>('persona-selection-close'),
            size: FluxerButtonSize.compact,
            isSquare: true,
            icon: PhosphorIconsBold.x,
            semanticLabel: l10n.uiClose,
            onPressed: onClose,
          ),
          SizedBox(width: layout.s2),
          Expanded(
            child: Text(
              l10n.fork.personaBulkSelectedCount(selectedCount),
              style: context.textStyles.bodyMedium.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          FluxerCheckbox(
            key: const ValueKey<String>('persona-select-all'),
            value: allShownSelected,
            enabled: canSelectAll,
            label: l10n.fork.personaBulkSelectAll,
            onChanged: (_) => onSelectAll(),
          ),
          SizedBox(width: layout.s2),
        ],
      ),
    );
  }
}

/// The actions at the bottom while personas are selected: Public, Unlisted,
/// Private and Delete. A visibility none of the selected would change to is
/// disabled.
class PersonaBulkActionBar extends StatelessWidget {
  const PersonaBulkActionBar({
    required this.canMakePublic,
    required this.canMakeUnlisted,
    required this.canMakePrivate,
    required this.busy,
    required this.onVisibility,
    required this.onDelete,
    super.key,
  });

  final bool canMakePublic;
  final bool canMakeUnlisted;
  final bool canMakePrivate;

  /// A change is under way: nothing can be pressed.
  final bool busy;
  final ValueChanged<String> onVisibility;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final colors = context.colors;
    final layout = context.layout;
    return DecoratedBox(
      key: const ValueKey<String>('persona-bulk-actions'),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        border: Border(top: BorderSide(color: colors.borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: layout.s2,
            vertical: layout.s1_5,
          ),
          child: Row(
            children: <Widget>[
              _BarButton(
                key: const ValueKey<String>('persona-bulk-public'),
                icon: PhosphorIconsBold.globeSimple,
                label: l10n.fork.personaVisibilityPublic,
                semanticLabel: l10n.fork.personaBulkMakePublic,
                onTap: busy || !canMakePublic
                    ? null
                    : () => onVisibility('public'),
              ),
              _BarButton(
                key: const ValueKey<String>('persona-bulk-unlisted'),
                icon: PhosphorIconsBold.eyeSlash,
                label: l10n.fork.personaVisibilityUnlisted,
                semanticLabel: l10n.fork.personaBulkMakeUnlisted,
                onTap: busy || !canMakeUnlisted
                    ? null
                    : () => onVisibility('unlisted'),
              ),
              _BarButton(
                key: const ValueKey<String>('persona-bulk-private'),
                icon: PhosphorIconsBold.lockSimple,
                label: l10n.fork.personaVisibilityPrivate,
                semanticLabel: l10n.fork.personaBulkMakePrivate,
                onTap: busy || !canMakePrivate
                    ? null
                    : () => onVisibility('private'),
              ),
              _BarButton(
                key: const ValueKey<String>('persona-bulk-delete'),
                icon: PhosphorIconsBold.trash,
                label: l10n.fork.personaDeleteConfirm,
                semanticLabel: l10n.fork.personaDeleteConfirm,
                danger: true,
                onTap: busy ? null : onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.onTap,
    this.danger = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final String semanticLabel;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool enabled = onTap != null;
    final Color color = danger ? colors.textDanger : colors.textPrimary;
    return Expanded(
      child: FluxerTappable(
        onTap: onTap,
        enabled: enabled,
        button: true,
        semanticLabel: semanticLabel,
        excludeChildSemantics: true,
        builder: (BuildContext context, Set<WidgetState> states) => Opacity(
          opacity: enabled ? 1 : 0.4,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 22, color: color),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.smallText.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks before a bulk change: [confirmLabel] or Cancel. True when confirmed.
Future<bool> confirmPersonaBulkAction(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool danger = false,
}) async {
  final FluxerLocalizations l10n = FluxerLocalizations.of(context);
  final bool? result = await FluxerBottomSheet.show<bool>(
    context,
    title: title,
    useRootNavigator: true,
    builder: (BuildContext sheetContext, VoidCallback close) {
      final layout = sheetContext.layout;
      void confirm() =>
          Navigator.of(sheetContext, rootNavigator: true).pop(true);
      void cancel() =>
          Navigator.of(sheetContext, rootNavigator: true).pop(false);
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: layout.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              body,
              style: sheetContext.textStyles.bodySmall.copyWith(
                color: sheetContext.colors.textPrimary,
              ),
            ),
            SizedBox(height: layout.s4),
            if (danger)
              FluxerButton.dangerPrimary(
                key: const ValueKey<String>('persona-bulk-confirm'),
                label: confirmLabel,
                onPressed: confirm,
              )
            else
              FluxerButton.primary(
                key: const ValueKey<String>('persona-bulk-confirm'),
                label: confirmLabel,
                onPressed: confirm,
              ),
            SizedBox(height: layout.s2),
            FluxerButton.secondary(label: l10n.cancel, onPressed: cancel),
          ],
        ),
      );
    },
  );
  return result ?? false;
}
