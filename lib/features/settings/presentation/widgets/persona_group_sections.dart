// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: persona groups on the Personas settings page (tyne-chat/tyne#829): a
// group's section header with its fold and its menu, the menu itself, and the
// select mode's Groups sheet. The page (`user_persona_settings.dart`) holds the
// selection and does the rest; which personas show in which section is
// `buildPersonaGroupSections` (profile `domain/persona_group.dart`).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/api/dio_error_message.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/profile/domain/persona_group.dart';
import 'package:fluxer_app/features/profile/presentation/widgets/persona_group_name_dialog.dart';
import 'package:fluxer_app/features/profile/providers/persona_groups_provider.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// The heading of a section of the persona list: a tap folds or unfolds it.
/// [onOptions] (a group's, not "Not in a group"'s) opens the group's menu at
/// the position it is given.
class PersonaGroupSectionHeader extends StatelessWidget {
  const PersonaGroupSectionHeader({
    required this.title,
    required this.count,
    required this.folded,
    required this.onToggle,
    this.onOptions,
    super.key,
  });

  final String title;
  final int count;
  final bool folded;
  final VoidCallback onToggle;
  final ValueChanged<Offset>? onOptions;

  @override
  Widget build(BuildContext context) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final colors = context.colors;
    final layout = context.layout;
    final textStyles = context.textStyles;
    final ValueChanged<Offset>? options = onOptions;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.borderColor)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: FluxerTappable(
              onTap: onToggle,
              button: true,
              expanded: !folded,
              minSize: const Size(0, 48),
              semanticLabel: '$title $count',
              excludeChildSemantics: true,
              builder: (BuildContext context, Set<WidgetState> _) => Padding(
                padding: EdgeInsets.symmetric(vertical: layout.s2),
                child: Row(
                  children: <Widget>[
                    AnimatedRotation(
                      // Folded, the caret points at the title: right, or left
                      // in a right-to-left language.
                      turns: folded
                          ? (Directionality.of(context) == TextDirection.rtl
                                ? 0.25
                                : -0.25)
                          : 0,
                      duration: const Duration(milliseconds: 150),
                      child: PhosphorIcon(
                        PhosphorIconsBold.caretDown,
                        size: 14,
                        color: colors.textPrimaryMuted,
                      ),
                    ),
                    SizedBox(width: layout.s2),
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textStyles.bodyMedium.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: layout.s2),
                    Text(
                      '$count',
                      style: textStyles.bodySmall.copyWith(
                        color: colors.textPrimaryMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (options != null)
            Builder(
              // The regular size: 44 dp, a full touch target.
              builder: (BuildContext buttonContext) => FluxerButton.ghost(
                isSquare: true,
                icon: PhosphorIconsBold.dotsThree,
                semanticLabel: l10n.fork.personaGroupOptions(title),
                onPressed: () => options(_centerOf(buttonContext)),
              ),
            ),
        ],
      ),
    );
  }
}

/// A group's menu: Rename group, Select the personas in it (off for a group
/// with no persona shown), Delete group.
Future<void> showPersonaGroupMenu(
  BuildContext context, {
  required Offset position,
  required VoidCallback onRename,
  required VoidCallback onSelectMembers,
  required VoidCallback onDelete,
  bool canSelectMembers = true,
}) {
  final FluxerLocalizations l10n = FluxerLocalizations.of(context);
  return FluxerActionMenu.show(
    context,
    position: position,
    builder: (BuildContext menuContext, VoidCallback close) => <Widget>[
      FluxerMenuItem(
        label: l10n.fork.personaGroupRename,
        icon: PhosphorIconsBold.pencilSimple,
        onPressed: () {
          close();
          onRename();
        },
      ),
      FluxerMenuItem(
        label: l10n.fork.personaGroupSelectMembers,
        icon: PhosphorIconsBold.checkSquare,
        // An empty group would start Select mode with nothing selected.
        enabled: canSelectMembers,
        onPressed: () {
          close();
          onSelectMembers();
        },
      ),
      const FluxerMenuDivider(),
      FluxerMenuItem(
        label: l10n.fork.personaGroupDelete,
        icon: PhosphorIconsBold.trash,
        isDanger: true,
        onPressed: () {
          close();
          onDelete();
        },
      ),
    ],
  );
}

/// A box showing [tick]: ticked, a dash, or empty.
class PersonaGroupTickBox extends StatelessWidget {
  const PersonaGroupTickBox({required this.tick, super.key});

  final PersonaGroupTick tick;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool filled = tick != PersonaGroupTick.none;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: filled ? colors.brandPrimary : null,
        borderRadius: BorderRadius.circular(5),
        border: filled
            ? null
            : Border.all(color: colors.textPrimaryMuted, width: 2),
      ),
      child: switch (tick) {
        PersonaGroupTick.all => Icon(
          PhosphorIconsBold.check,
          size: 14,
          color: colors.textOnBrandPrimary,
        ),
        PersonaGroupTick.some => Icon(
          PhosphorIconsBold.minus,
          size: 14,
          color: colors.textOnBrandPrimary,
        ),
        PersonaGroupTick.none => null,
      },
    );
  }
}

/// The select mode's Groups sheet for the personas with [selectedIds]. True
/// when its Done sent the changes (or there were none), so that select mode
/// can end.
Future<bool> showPersonaGroupsSheet(
  BuildContext context, {
  required List<String> selectedIds,
}) async {
  final FluxerLocalizations l10n = FluxerLocalizations.of(context);
  final bool? done = await FluxerBottomSheet.show<bool>(
    context,
    title: l10n.fork.personaGroups,
    useRootNavigator: true,
    builder: (BuildContext sheetContext, VoidCallback close) =>
        PersonaGroupsSheetBody(selectedIds: selectedIds),
  );
  return done ?? false;
}

class PersonaGroupsSheetBody extends ConsumerStatefulWidget {
  const PersonaGroupsSheetBody({required this.selectedIds, super.key});

  final List<String> selectedIds;

  @override
  ConsumerState<PersonaGroupsSheetBody> createState() =>
      _PersonaGroupsSheetBodyState();
}

class _PersonaGroupsSheetBodyState
    extends ConsumerState<PersonaGroupsSheetBody> {
  /// The rows tapped, with what they show now.
  final Map<String, PersonaGroupTick> _wanted = <String, PersonaGroupTick>{};
  bool _busy = false;

  Future<void> _newGroup() async {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final String? name = await showPersonaGroupNameDialog(
      context,
      title: l10n.fork.personaGroupNew,
      confirmLabel: l10n.fork.personaGroupCreate,
    );
    if (name == null || !mounted) {
      return;
    }
    final Toast toasts = ref.read(toastProvider.notifier);
    setState(() => _busy = true);
    try {
      // Made with the selected personas in it, so its row shows a tick.
      await ref
          .read(personaGroupsProvider.notifier)
          .create(name, personaIds: widget.selectedIds);
    } on Object catch (err, st) {
      talker.warning('[PersonaGroupsSheet] Creating a group failed', err, st);
      toasts.show(
        FluxerToast(
          message: userFacingErrorMessage(err, l10n.fork.personaGroupFailed),
          variant: FluxerToastVariant.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _done(List<PersonaGroup> groups) async {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final List<PersonaGroupMemberChange> changes =
        personaGroupChangesForSelection(
          groups: groups,
          selectedIds: widget.selectedIds,
          wanted: _wanted,
        );
    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    if (changes.isEmpty) {
      navigator.pop(true);
      return;
    }
    final Toast toasts = ref.read(toastProvider.notifier);
    setState(() => _busy = true);
    try {
      await ref.read(personaGroupsProvider.notifier).changeMembers(changes);
      if (mounted) {
        navigator.pop(true);
      }
    } on Object catch (err, st) {
      talker.warning('[PersonaGroupsSheet] Changing groups failed', err, st);
      toasts.show(
        FluxerToast(
          message: userFacingErrorMessage(err, l10n.fork.personaGroupFailed),
          variant: FluxerToastVariant.danger,
        ),
      );
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final colors = context.colors;
    final layout = context.layout;
    final textStyles = context.textStyles;
    final List<PersonaGroup> groups = ref.watch(personaGroupsProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.symmetric(horizontal: layout.s2),
            children: <Widget>[
              for (final PersonaGroup group in groups)
                _row(
                  key: ValueKey<String>('persona-groups-sheet-${group.id}'),
                  tick:
                      _wanted[group.id] ??
                      personaGroupTick(group, widget.selectedIds),
                  label: group.name,
                  onTap: () => setState(() {
                    _wanted[group.id] = nextPersonaGroupTick(
                      _wanted[group.id] ??
                          personaGroupTick(group, widget.selectedIds),
                    );
                  }),
                ),
              FluxerTappable(
                key: const ValueKey<String>('persona-groups-sheet-new'),
                onTap: _busy ? null : () => unawaited(_newGroup()),
                enabled: !_busy,
                button: true,
                minSize: const Size(0, 48),
                semanticLabel: l10n.fork.personaGroupNewEllipsis,
                excludeChildSemantics: true,
                builder: (BuildContext context, Set<WidgetState> _) => Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: layout.s2,
                    vertical: layout.s3,
                  ),
                  child: Row(
                    children: <Widget>[
                      PhosphorIcon(
                        PhosphorIconsBold.plus,
                        size: 20,
                        color: colors.textPrimary,
                      ),
                      SizedBox(width: layout.s3),
                      Text(
                        l10n.fork.personaGroupNewEllipsis,
                        style: textStyles.bodyMedium.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(layout.s4, layout.s2, layout.s4, 0),
          child: FluxerButton.primary(
            key: const ValueKey<String>('persona-groups-sheet-done'),
            label: l10n.fork.personaGroupsDone,
            isLoading: _busy,
            onPressed: _busy ? null : () => unawaited(_done(groups)),
          ),
        ),
      ],
    );
  }

  Widget _row({
    required Key key,
    required PersonaGroupTick tick,
    required String label,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    final layout = context.layout;
    // The row's own node carries the box's state, so a dash is "mixed" to a
    // screen reader, not "not checked" (upstream's FluxerTappable has no mixed
    // state); the tappable's label and tap join this node.
    return Semantics(
      container: true,
      checked: tick == PersonaGroupTick.all,
      mixed: tick == PersonaGroupTick.some,
      child: FluxerTappable(
        key: key,
        onTap: _busy ? null : onTap,
        enabled: !_busy,
        minSize: const Size(0, 48),
        semanticLabel: label,
        excludeChildSemantics: true,
        builder: (BuildContext context, Set<WidgetState> _) => Padding(
          padding: EdgeInsets.symmetric(
            horizontal: layout.s2,
            vertical: layout.s3,
          ),
          child: Row(
            children: <Widget>[
              PersonaGroupTickBox(tick: tick),
              SizedBox(width: layout.s3),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodyMedium.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Offset _centerOf(BuildContext context) {
  final RenderObject? box = context.findRenderObject();
  if (box is RenderBox && box.hasSize) {
    return box.localToGlobal(box.size.center(Offset.zero));
  }
  return Offset.zero;
}
