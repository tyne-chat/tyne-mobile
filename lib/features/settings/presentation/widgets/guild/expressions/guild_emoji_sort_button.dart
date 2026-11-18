// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: the sort and grouping menu of a community's emoji settings
// (tyne-chat/tyne#775). The button is shaped like the persona gallery's sort
// button; its sheet holds two groups of choices, like the forum's sort and view
// sheet.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/settings/domain/guild/expressions/guild_emoji_list_order.dart';
import 'package:fluxer_app/features/settings/providers/guild/guild_emoji_list_order_provider.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/icons/phosphor.dart';
import 'package:fluxer_app/shared/providers/input_modality_provider.dart';

/// A row with the sort button at its end, under the emoji search field.
class GuildEmojiSortRow extends ConsumerWidget {
  const GuildEmojiSortRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final GuildEmojiListOrder order = ref.watch(guildEmojiListOrderProvider);
    final String label = order.sort == GuildEmojiListSort.recent
        ? l10n.fork.guildEmojiSortRecent
        : l10n.fork.guildEmojiSortName;
    final colors = context.colors;
    // The same gutter and spacing as the search field above and the upload
    // card below.
    return Padding(
      padding: usesDesktopPointerUi(context)
          ? const EdgeInsets.only(bottom: 16)
          : EdgeInsets.fromLTRB(
              context.layout.s4,
              context.layout.s2,
              context.layout.s4,
              0,
            ),
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: FluxerTappable(
          key: const ValueKey<String>('guild-emoji-sort'),
          onTap: () => unawaited(_showSheet(context)),
          button: true,
          semanticLabel: '${l10n.fork.guildEmojiSortAndGroup}: $label',
          excludeChildSemantics: true,
          builder: (BuildContext context, Set<WidgetState> states) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                PhosphorIcon(
                  PhosphorIconsBold.sortAscending,
                  size: 14,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: context.textStyles.label.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                PhosphorIcon(
                  PhosphorIconsBold.caretDown,
                  size: 12,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSheet(BuildContext context) => FluxerBottomSheet.show<void>(
    context,
    title: FluxerLocalizations.of(context).fork.guildEmojiSortAndGroup,
    variant: FluxerBottomSheetVariant.menu,
    builder: (BuildContext sheetContext, VoidCallback close) =>
        const FluxerBottomSheetContent(child: _SortGroupChoices()),
  );
}

class _SortGroupChoices extends ConsumerWidget {
  const _SortGroupChoices();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final GuildEmojiListOrder order = ref.watch(guildEmojiListOrderProvider);
    final GuildEmojiListOrderNotifier notifier = ref.read(
      guildEmojiListOrderProvider.notifier,
    );
    return FluxerBottomSheetGroupColumn(
      children: <Widget>[
        FluxerMenuGroup(
          children: <Widget>[
            FluxerBottomSheetMenuRadioItem(
              key: const ValueKey<String>('guild-emoji-sort-name'),
              label: l10n.fork.guildEmojiSortName,
              isSelected: order.sort == GuildEmojiListSort.name,
              onTap: () =>
                  unawaited(notifier.chooseSort(GuildEmojiListSort.name)),
            ),
            FluxerBottomSheetMenuRadioItem(
              key: const ValueKey<String>('guild-emoji-sort-recent'),
              label: l10n.fork.guildEmojiSortRecent,
              isSelected: order.sort == GuildEmojiListSort.recent,
              onTap: () =>
                  unawaited(notifier.chooseSort(GuildEmojiListSort.recent)),
            ),
          ],
        ),
        FluxerMenuGroup(
          children: <Widget>[
            FluxerBottomSheetMenuRadioItem(
              key: const ValueKey<String>('guild-emoji-group-split'),
              label: l10n.fork.guildEmojiGroupSplit,
              isSelected: order.grouping == GuildEmojiListGrouping.split,
              onTap: () => unawaited(
                notifier.chooseGrouping(GuildEmojiListGrouping.split),
              ),
            ),
            FluxerBottomSheetMenuRadioItem(
              key: const ValueKey<String>('guild-emoji-group-together'),
              label: l10n.fork.guildEmojiGroupTogether,
              isSelected: order.grouping == GuildEmojiListGrouping.together,
              onTap: () => unawaited(
                notifier.chooseGrouping(GuildEmojiListGrouping.together),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
