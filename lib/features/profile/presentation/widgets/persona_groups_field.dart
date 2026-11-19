// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: the persona editor's Groups field (tyne-chat/tyne#829): a chip for
// each group the persona is in, with a cross to take it out, and "Add to
// group", which lists the other groups and "New group…". The editor keeps
// the changes and sends them with Save; only "New group…" makes the group at
// once (one request), so that the persona can be put in it.

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

class PersonaGroupsField extends ConsumerWidget {
  const PersonaGroupsField({
    required this.chosenIds,
    required this.onAdd,
    required this.onRemove,
    this.enabled = true,
    super.key,
  });

  /// The groups the persona is in as the form stands.
  final Set<String> chosenIds;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final colors = context.colors;
    final layout = context.layout;
    final textStyles = context.textStyles;
    final List<PersonaGroup> groups = ref.watch(personaGroupsProvider);
    final List<PersonaGroup> chosen = <PersonaGroup>[
      for (final PersonaGroup g in groups)
        if (chosenIds.contains(g.id)) g,
    ];
    return Column(
      key: const ValueKey<String>('persona-groups-field'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.fork.personaGroups,
          style: textStyles.label.copyWith(color: colors.textPrimary),
        ),
        SizedBox(height: layout.s2),
        Wrap(
          spacing: layout.s2,
          runSpacing: layout.s2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            for (final PersonaGroup group in chosen)
              Container(
                key: ValueKey<String>('persona-group-chip-${group.id}'),
                // The cross's own hit area is the chip's height, so the chip
                // needs no top or bottom padding.
                padding: const EdgeInsetsDirectional.only(start: 10),
                decoration: BoxDecoration(
                  color: colors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textStyles.bodySmall.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    FluxerTappable(
                      onTap: enabled ? () => onRemove(group.id) : null,
                      enabled: enabled,
                      button: true,
                      minSize: const Size(40, 40),
                      semanticLabel: l10n.fork.personaGroupRemoveFrom(
                        group.name,
                      ),
                      excludeChildSemantics: true,
                      builder: (BuildContext context, Set<WidgetState> _) =>
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: Center(
                              child: PhosphorIcon(
                                PhosphorIconsBold.x,
                                size: 14,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            Builder(
              builder: (BuildContext buttonContext) => FluxerButton.secondary(
                key: const ValueKey<String>('persona-group-add'),
                size: FluxerButtonSize.small,
                fitContent: true,
                icon: PhosphorIconsBold.plus,
                label: l10n.fork.personaGroupAddTo,
                onPressed: enabled
                    ? () =>
                          unawaited(_openMenu(buttonContext, ref, groups, l10n))
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openMenu(
    BuildContext context,
    WidgetRef ref,
    List<PersonaGroup> groups,
    FluxerLocalizations l10n,
  ) {
    final List<PersonaGroup> others = <PersonaGroup>[
      for (final PersonaGroup g in groups)
        if (!chosenIds.contains(g.id)) g,
    ];
    return FluxerActionMenu.show(
      context,
      position: _centerOf(context),
      builder: (BuildContext menuContext, VoidCallback close) => <Widget>[
        for (final PersonaGroup group in others)
          FluxerMenuItem(
            label: group.name,
            icon: PhosphorIconsBold.folder,
            onPressed: () {
              close();
              onAdd(group.id);
            },
          ),
        if (others.isNotEmpty) const FluxerMenuDivider(),
        FluxerMenuItem(
          label: l10n.fork.personaGroupNewEllipsis,
          icon: PhosphorIconsBold.plus,
          onPressed: () {
            close();
            unawaited(_createAndAdd(context, ref, l10n));
          },
        ),
      ],
    );
  }

  Future<void> _createAndAdd(
    BuildContext context,
    WidgetRef ref,
    FluxerLocalizations l10n,
  ) async {
    final String? name = await showPersonaGroupNameDialog(
      context,
      title: l10n.fork.personaGroupNew,
      confirmLabel: l10n.fork.personaGroupCreate,
    );
    if (name == null || !context.mounted) {
      return;
    }
    final PersonaGroupsNotifier groups = ref.read(
      personaGroupsProvider.notifier,
    );
    final Toast toasts = ref.read(toastProvider.notifier);
    try {
      final PersonaGroup? group = await groups.create(name);
      if (group != null && context.mounted) {
        onAdd(group.id);
      }
    } on Object catch (err, st) {
      talker.warning('[PersonaGroupsField] Creating a group failed', err, st);
      toasts.show(
        FluxerToast(
          message: userFacingErrorMessage(err, l10n.fork.personaGroupFailed),
          variant: FluxerToastVariant.danger,
        ),
      );
    }
  }
}

Offset _centerOf(BuildContext context) {
  final RenderObject? box = context.findRenderObject();
  if (box is RenderBox && box.hasSize) {
    return box.localToGlobal(box.size.center(Offset.zero));
  }
  return Offset.zero;
}
