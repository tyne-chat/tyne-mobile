// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: the pieces of the Personas settings page's select mode
// (tyne-chat/tyne#542): the visibility filter chips with their counts, the
// bar on top while selecting, the action bar at the bottom with its
// Visibility and Mentions sheets (tyne-chat/tyne#652), and the confirmation
// before making personas public or private, or deleting them.
// The page (`user_persona_settings.dart`) holds the state and does the work.

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/profile/domain/persona_mention_setting.dart';
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

/// The value standing for "Follow Visibility" in the Mentions sheet: a
/// persona's stored mention setting is then null (tyne-chat/tyne#652).
const String kPersonaFollowVisibility = 'follow';

/// The actions at the bottom while personas are selected: Groups, Visibility,
/// Mentions and Delete. Visibility and Mentions open a sheet of their values;
/// a value every selected persona has already is shown picked, and one none
/// of them would change to is disabled.
class PersonaBulkActionBar extends StatelessWidget {
  const PersonaBulkActionBar({
    required this.canMakePublic,
    required this.canMakeUnlisted,
    required this.canMakePrivate,
    required this.sharedVisibility,
    required this.sharedMentionableBy,
    required this.busy,
    required this.onVisibility,
    required this.onMentionableBy,
    required this.onDelete,
    this.onGroups,
    super.key,
  });

  final bool canMakePublic;
  final bool canMakeUnlisted;
  final bool canMakePrivate;

  /// The visibility every selected persona has, or null when they differ.
  final String? sharedVisibility;

  /// The stored mention setting every selected persona has
  /// ([kPersonaFollowVisibility] for none), or null when they differ.
  final String? sharedMentionableBy;

  /// A change is under way: nothing can be pressed.
  final bool busy;
  final ValueChanged<String> onVisibility;

  /// Gets a mention setting, or null to follow visibility.
  final ValueChanged<String?> onMentionableBy;
  final VoidCallback onDelete;

  /// Opens the Groups sheet (tyne-chat/tyne#829); no Groups button without it.
  final VoidCallback? onGroups;

  Future<void> _chooseVisibility(BuildContext context) async {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final String? picked = await choosePersonaBulkOption(
      context,
      key: const ValueKey<String>('persona-bulk-visibility-sheet'),
      title: l10n.fork.personaVisibilityLabel,
      current: sharedVisibility,
      items: <FluxerRadioItem<String>>[
        FluxerRadioItem<String>(
          value: 'public',
          label: l10n.fork.personaVisibilityPublic,
          enabled: canMakePublic,
        ),
        FluxerRadioItem<String>(
          value: 'unlisted',
          label: l10n.fork.personaVisibilityUnlisted,
          enabled: canMakeUnlisted,
        ),
        FluxerRadioItem<String>(
          value: 'private',
          label: l10n.fork.personaVisibilityPrivate,
          enabled: canMakePrivate,
        ),
      ],
    );
    if (picked != null) {
      onVisibility(picked);
    }
  }

  Future<void> _chooseMentionableBy(BuildContext context) async {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final String? picked = await choosePersonaBulkOption(
      context,
      key: const ValueKey<String>('persona-bulk-mentions-sheet'),
      title: l10n.fork.personaMentionableByLabel,
      current: sharedMentionableBy,
      items: <FluxerRadioItem<String>>[
        FluxerRadioItem<String>(
          value: PersonaMentionableBy.everyone,
          label: l10n.fork.personaBulkMentionsEveryone,
        ),
        FluxerRadioItem<String>(
          value: PersonaMentionableBy.self,
          label: l10n.fork.personaBulkMentionsSelf,
        ),
        FluxerRadioItem<String>(
          value: PersonaMentionableBy.nobody,
          label: l10n.fork.personaBulkMentionsNobody,
        ),
        FluxerRadioItem<String>(
          value: kPersonaFollowVisibility,
          label: l10n.fork.personaMentionableByFollowVisibility,
        ),
      ],
    );
    if (picked != null && picked != sharedMentionableBy) {
      onMentionableBy(picked == kPersonaFollowVisibility ? null : picked);
    }
  }

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
              if (onGroups case final VoidCallback openGroups)
                _BarButton(
                  key: const ValueKey<String>('persona-bulk-groups'),
                  icon: PhosphorIconsBold.folder,
                  label: l10n.fork.personaGroups,
                  semanticLabel: l10n.fork.personaGroups,
                  onTap: busy ? null : openGroups,
                ),
              _BarButton(
                key: const ValueKey<String>('persona-bulk-visibility'),
                icon: PhosphorIconsBold.eye,
                label: l10n.fork.personaVisibilityLabel,
                semanticLabel: l10n.fork.personaVisibilityLabel,
                onTap: busy ? null : () => _chooseVisibility(context),
              ),
              _BarButton(
                key: const ValueKey<String>('persona-bulk-mentions'),
                icon: PhosphorIconsBold.at,
                label: l10n.fork.personaBulkMentions,
                semanticLabel: l10n.fork.personaMentionableByLabel,
                onTap: busy ? null : () => _chooseMentionableBy(context),
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

/// A sheet of the values one bulk action can give the selection: the one
/// picked, or null when it is closed without a pick.
Future<String?> choosePersonaBulkOption(
  BuildContext context, {
  required String title,
  required String? current,
  required List<FluxerRadioItem<String>> items,
  Key? key,
}) => FluxerBottomSheet.show<String>(
  context,
  title: title,
  useRootNavigator: true,
  builder: (BuildContext sheetContext, VoidCallback close) => Padding(
    key: key,
    padding: EdgeInsets.symmetric(horizontal: sheetContext.layout.s4),
    child: FluxerRadioGroup<String>(
      value: current,
      items: items,
      onChanged: (String value) =>
          Navigator.of(sheetContext, rootNavigator: true).pop(value),
    ),
  ),
);

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

/// On a persona row whose persona nobody gets in mention suggestions
/// (tyne-chat/tyne#652): an @ struck through, as on the web. Phosphor has no
/// such icon, so the line is painted over its @.
class PersonaNotMentionableIcon extends StatelessWidget {
  const PersonaNotMentionableIcon({required this.color, super.key});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    return Semantics(
      label: l10n.fork.personaNotMentionable,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: 14,
        child: CustomPaint(
          foregroundPainter: _StrikePainter(color),
          child: PhosphorIcon(PhosphorIconsBold.at, size: 14, color: color),
        ),
      ),
    );
  }
}

class _StrikePainter extends CustomPainter {
  const _StrikePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = size.width / 10
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.16, size.height * 0.16),
      Offset(size.width * 0.84, size.height * 0.84),
      paint,
    );
  }

  @override
  bool shouldRepaint(_StrikePainter oldDelegate) => oldDelegate.color != color;
}
