// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: where a profile leads to an account's "Personas (N)" gallery
// (tyne-chat/tyne#189). One rule: wherever a profile shows the account's
// display tag (after the account's name, and after a persona's name), the
// "Personas (N)" pill follows it; and the same count opens the first row of
// the mutuals section (alone in a section on your own profile). Both show for
// others once they have a public persona, on your own profile always, and
// never when the server will not show the account's profile.

import 'dart:async';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/profile/domain/persona_image_urls.dart';
import 'package:fluxer_app/features/profile/presentation/sheets/persona_gallery_sheet.dart';
import 'package:fluxer_app/features/profile/providers/public_persona_list_provider.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/icons/phosphor.dart';

/// Whose personas a profile leads to, or null where it leads to none
/// (webhooks, bots, system accounts).
PersonaGalleryOwner? personaGalleryOwnerFor({
  required String userId,
  required bool isSelf,
  required String name,
  required String? avatarUrl,
  required int? avatarColor,
  String? guildId,
  bool hidden = false,
}) {
  if (hidden || userId.isEmpty) {
    return null;
  }
  return (
    userId: userId,
    isSelf: isSelf,
    name: name,
    avatarUrl: avatarUrl,
    avatarColor: avatarColor,
    guildId: guildId,
  );
}

PersonaGallerySummary _watchSummary(WidgetRef ref, PersonaGalleryOwner owner) =>
    ref.watch(
      personaGallerySummaryProvider((
        userId: owner.userId,
        isSelf: owner.isSelf,
      )),
    );

void _openGallery(
  BuildContext context,
  PersonaGalleryOwner owner,
  PersonaGallerySummary summary,
) {
  unawaited(
    PersonaGallerySheet.show(context, owner: owner, count: summary.count),
  );
}

/// What follows an account's name in its profile header: its display tag and
/// the "Personas (N)" pill. Null when the profile leads to no personas.
Widget? accountPersonaNameTrailing(PersonaGalleryOwner? owner) =>
    owner == null ? null : AccountPersonaNameTrailing(owner: owner);

/// The account's display tag, then the "Personas (N)" pill.
class AccountPersonaNameTrailing extends ConsumerWidget {
  const AccountPersonaNameTrailing({required this.owner, super.key});

  final PersonaGalleryOwner owner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PersonaGallerySummary summary = _watchSummary(ref, owner);
    final Widget? tag = PersonaDisplayTag.orNull(
      ownerUserId: owner.userId,
      text: summary.displayTagText,
      icon: summary.displayTagIcon,
    );
    if (tag == null && !summary.visible) {
      return const SizedBox.shrink();
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: <Widget>[
        ?tag,
        if (summary.visible) PersonaGalleryPill(owner: owner),
      ],
    );
  }
}

/// An account's display tag as messages and persona profiles draw it: its
/// text in a tag (with the icon), or the icon alone.
class PersonaDisplayTag extends StatelessWidget {
  const PersonaDisplayTag._({required this.text, required this.iconUrl});

  /// The tag, or null when the account has none.
  static Widget? orNull({
    required String ownerUserId,
    required String? text,
    required String? icon,
  }) {
    final String? trimmed = text?.trim();
    final String? iconUrl = personaTagIconUrl(
      ownerUserId: ownerUserId,
      icon: icon,
    );
    if ((trimmed == null || trimmed.isEmpty) && iconUrl == null) {
      return null;
    }
    return PersonaDisplayTag._(
      text: trimmed == null || trimmed.isEmpty ? null : trimmed,
      iconUrl: iconUrl,
    );
  }

  final String? text;
  final String? iconUrl;

  @override
  Widget build(BuildContext context) {
    final String? label = text;
    if (label != null) {
      return FluxerUserTag(label: label, iconUrl: iconUrl);
    }
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: iconUrl!,
        width: 16,
        height: 16,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox(width: 16, height: 16),
      ),
    );
  }
}

/// The small "Personas (N)" pill after a display tag; nothing when the
/// account shows no personas to this viewer.
class PersonaGalleryPill extends ConsumerWidget {
  const PersonaGalleryPill({required this.owner, super.key});

  final PersonaGalleryOwner owner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PersonaGallerySummary summary = _watchSummary(ref, owner);
    if (!summary.visible) {
      return const SizedBox.shrink();
    }
    final colors = context.colors;
    final String label = FluxerLocalizations.of(
      context,
    ).fork.personaGalleryTitle(summary.count);
    return FluxerTappable(
      key: const ValueKey<String>('persona-gallery-pill'),
      onTap: () => _openGallery(context, owner, summary),
      button: true,
      semanticLabel: label,
      excludeChildSemantics: true,
      builder: (BuildContext context, Set<WidgetState> states) => Container(
        constraints: const BoxConstraints(minHeight: 18),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: states.contains(WidgetState.pressed)
              ? colors.backgroundModifierSelected
              : colors.backgroundTertiary,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            PhosphorIcon(
              PhosphorIconsBold.usersThree,
              size: 11,
              color: colors.textSecondary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: context.textStyles.smallText.copyWith(
                  color: colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The "Personas (N)" row, or, when the list could not be loaded, the row
/// that says so and offers Retry.
class PersonaGalleryRow extends ConsumerWidget {
  const PersonaGalleryRow({required this.owner, super.key});

  final PersonaGalleryOwner owner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PersonaGallerySummary summary = _watchSummary(ref, owner);
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    const Widget leading = _RowIcon();
    if (summary.failed) {
      void retry() => ref.invalidate(publicPersonaListProvider(owner.userId));
      return FluxerListRow(
        key: const ValueKey<String>('persona-gallery-row-failed'),
        leading: leading,
        title: l10n.fork.personaGalleryLoadFailed,
        trailing: FluxerButton.secondary(
          size: FluxerButtonSize.superCompact,
          fitContent: true,
          label: l10n.retry,
          onPressed: retry,
        ),
        onTap: retry,
      );
    }
    return FluxerListRow(
      key: const ValueKey<String>('persona-gallery-row'),
      leading: leading,
      title: l10n.fork.personaGalleryTitle(summary.count),
      trailing: const PhosphorIcon(PhosphorIconsBold.caretRight, size: 18),
      onTap: () => _openGallery(context, owner, summary),
    );
  }
}

/// The first rows of someone else's mutuals section: "Personas (N)" when they
/// show personas to this viewer, the failed row when the list did not load,
/// else none. Watches the list, so call it while building.
List<Widget> personaGalleryLeadingRows(
  WidgetRef ref,
  PersonaGalleryOwner? owner,
) {
  if (owner == null || owner.isSelf) {
    return const <Widget>[];
  }
  final PersonaGallerySummary summary = _watchSummary(ref, owner);
  if (!summary.visible && !summary.failed) {
    return const <Widget>[];
  }
  return <Widget>[PersonaGalleryRow(owner: owner)];
}

/// Your own profile has no mutuals section: the "Personas (N)" row stands in
/// a section of its own at that place, followed by [gap].
List<Widget> ownPersonaGallerySection(
  PersonaGalleryOwner? owner, {
  required double gap,
}) {
  if (owner == null || !owner.isSelf) {
    return const <Widget>[];
  }
  return <Widget>[
    _OwnPersonaGallerySection(owner: owner),
    SizedBox(height: gap),
  ];
}

class _OwnPersonaGallerySection extends StatelessWidget {
  const _OwnPersonaGallerySection({required this.owner});

  final PersonaGalleryOwner owner;

  @override
  Widget build(BuildContext context) {
    return FluxerListSection(
      backgroundColor: context.colors.backgroundSecondary,
      children: <Widget>[PersonaGalleryRow(owner: owner)],
    );
  }
}

/// The row's icon, drawn as the mutuals rows' `FluxerAvatar.icon` is. It is
/// not one, so that a profile has the one `FluxerAvatar` upstream's tests
/// look for: your own has no mutuals rows.
class _RowIcon extends StatelessWidget {
  const _RowIcon();

  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: context.colors.backgroundTertiary,
        borderRadius: BorderRadius.circular(_size / 2),
      ),
      child: Center(
        child: Icon(
          PhosphorIconsFill.identificationCard,
          size: _size / 2,
          color: context.colors.textPrimary,
        ),
      ),
    );
  }
}
