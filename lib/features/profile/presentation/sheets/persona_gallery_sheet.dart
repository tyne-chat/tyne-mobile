// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: an account's "Personas (N)" gallery (tyne-chat/tyne#189): its public
// personas as cards, rows or avatars, searched and sorted on the device. In
// your own gallery a bar says how many others see, a switch adds your
// unlisted and private personas (dimmed, with a badge), and "Manage personas"
// opens the Personas settings. Tapping a persona opens its profile, with the
// others in the same order a swipe away.
//
// Requests: none of its own. Someone else's list is the one their profile
// already loaded (`publicPersonaListProvider`); your own is your own list.
// Never shown here: how often or when a persona was used. "Most used" is the
// server's order for someone else's personas, and "Recently used" is offered
// to the owner only.

import 'dart:async';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/rendering.dart' show SliverConstraints;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/constants/media_proxy_sizes.dart';
import 'package:fluxer_app/core/media/fluxer_media_url.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/pickers/picker_search_input.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/domain/persona_color.dart';
import 'package:fluxer_app/features/profile/domain/persona_gallery.dart';
import 'package:fluxer_app/features/profile/domain/persona_image_urls.dart';
import 'package:fluxer_app/features/profile/domain/public_persona.dart';
import 'package:fluxer_app/features/profile/presentation/sheets/persona_profile_pager.dart';
import 'package:fluxer_app/features/profile/providers/persona_gallery_view_provider.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/features/profile/providers/public_persona_list_provider.dart';
import 'package:fluxer_app/features/settings/domain/user_settings_section.dart';
import 'package:fluxer_app/features/settings/presentation/user_settings_modal.dart';
import 'package:fluxer_app/features/settings/providers/persona_settings_launch_provider.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/icons/phosphor.dart';
import 'package:fluxer_app/shared/utils/user_date_formatting.dart';

/// Opens an account's persona gallery.
class PersonaGallerySheet {
  PersonaGallerySheet._();

  /// [count] is the number of public personas, for the title.
  static Future<void> show(
    BuildContext context, {
    required PersonaGalleryOwner owner,
    required int count,
  }) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    return FluxerBottomSheet.showScrollable<void>(
      context,
      title: l10n.fork.personaGalleryTitle(count),
      useRootNavigator: true,
      builder:
          (
            BuildContext sheetContext,
            ScrollController scrollController,
            VoidCallback close,
          ) => PersonaGalleryBody(
            owner: owner,
            scrollController: scrollController,
            onClose: close,
          ),
    );
  }
}

/// What the gallery has to show.
sealed class _GalleryData {
  const _GalleryData();
}

final class _Loading extends _GalleryData {
  const _Loading();
}

final class _Failed extends _GalleryData {
  const _Failed(this.retry);

  final VoidCallback retry;
}

final class _Loaded extends _GalleryData {
  const _Loaded({required this.all, this.nameOrder});

  /// Everything the viewer may list: the public personas, and for the owner
  /// also the others.
  final List<Persona> all;

  /// The device's name order of the owner's personas.
  final List<String>? nameOrder;
}

class PersonaGalleryBody extends ConsumerStatefulWidget {
  const PersonaGalleryBody({
    required this.owner,
    required this.scrollController,
    required this.onClose,
    super.key,
  });

  final PersonaGalleryOwner owner;
  final ScrollController scrollController;
  final VoidCallback onClose;

  @override
  ConsumerState<PersonaGalleryBody> createState() => _PersonaGalleryBodyState();
}

class _PersonaGalleryBodyState extends ConsumerState<PersonaGalleryBody> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  PersonaGallerySort _sort = PersonaGallerySort.name;
  bool _showHidden = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  _GalleryData _watchData() {
    final PersonaGalleryOwner owner = widget.owner;
    if (owner.isSelf) {
      final AsyncValue<List<Persona>> mine = ref.watch(myPersonasProvider);
      final List<Persona>? personas = mine.asData?.value;
      if (personas == null) {
        return mine.hasError
            ? _Failed(() => ref.invalidate(myPersonasProvider))
            : const _Loading();
      }
      return _Loaded(
        all: personas.where((Persona p) => !p.isDeleted).toList(),
        nameOrder: <String>[
          for (final Persona p in ref.watch(sortedPersonasProvider)) p.id,
        ],
      );
    }
    final PublicPersonaListResult? result = ref
        .watch(publicPersonaListProvider(owner.userId))
        .value;
    return switch (result) {
      null => const _Loading(),
      PublicPersonaListLoaded(:final PublicPersonaList list) => _Loaded(
        all: <Persona>[
          // Tags are the owner's business: never listed for anyone else.
          for (final PublicPersona p in list.personas)
            p.toPersona().copyWith(personaTags: const <PersonaTag>[]),
        ],
      ),
      PublicPersonaListForbidden() || PublicPersonaListFailed() => _Failed(
        () => ref.invalidate(publicPersonaListProvider(owner.userId)),
      ),
    };
  }

  void _openManage() {
    final BuildContext host = Navigator.of(
      context,
      rootNavigator: true,
    ).context;
    widget.onClose();
    unawaited(
      UserSettingsModal.show(
        host,
        initialSection: UserSettingsSection.personas,
      ),
    );
  }

  /// None of your personas is public: the settings open on the unlisted
  /// ones, ready to select (tyne-chat/tyne#542).
  void _openChooseFeatured() {
    ref
        .read(personaSettingsLaunchProvider.notifier)
        .next = const PersonaSettingsLaunch(
      filter: PersonaVisibilityFilter.unlisted,
      selecting: true,
    );
    _openManage();
  }

  void _openPersona(List<Persona> shown, int index) {
    unawaited(
      PersonaProfilePager.show(
        context,
        ownerUserId: widget.owner.userId,
        personaIds: <String>[for (final Persona p in shown) p.id],
        initialIndex: index,
        guildId: widget.owner.guildId,
      ),
    );
  }

  Future<void> _chooseSort() async {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    await FluxerBottomSheet.show<void>(
      context,
      title: l10n.fork.personaGallerySortBy,
      variant: FluxerBottomSheetVariant.menu,
      builder: (BuildContext sheetContext, VoidCallback close) =>
          FluxerBottomSheetContent(
            scrollable: false,
            child: FluxerBottomSheetGroupColumn(
              children: <Widget>[
                FluxerMenuGroup(
                  children: <Widget>[
                    for (final PersonaGallerySort sort in personaGallerySorts(
                      isOwner: widget.owner.isSelf,
                    ))
                      FluxerBottomSheetMenuItem(
                        label: _sortLabel(l10n, sort),
                        isSelected: sort == _sort,
                        onTap: () {
                          setState(() => _sort = sort);
                          close();
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final layout = context.layout;
    final PersonaGalleryOwner owner = widget.owner;
    final PersonaGalleryView view = ref.watch(personaGalleryViewProvider);
    final _GalleryData data = _watchData();

    final List<Widget> header = <Widget>[];
    final List<Widget> content = <Widget>[];
    switch (data) {
      case _Loading():
        content.add(
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: FluxerLoadingSpinner()),
            ),
          ),
        );
      case _Failed(:final VoidCallback retry):
        content.add(
          SliverToBoxAdapter(
            child: _GalleryMessage(
              key: const ValueKey<String>('persona-gallery-failed'),
              icon: PhosphorIconsFill.warningCircle,
              text: l10n.fork.personaGalleryLoadFailed,
              action: FluxerButton.secondary(
                size: FluxerButtonSize.compact,
                fitContent: true,
                label: l10n.retry,
                onPressed: retry,
              ),
            ),
          ),
        );
      case _Loaded(:final List<Persona> all, :final List<String>? nameOrder):
        final List<Persona> public = all.where(isPublicPersona).toList();
        final bool hasHidden = owner.isSelf && public.length < all.length;
        final List<Persona> base = owner.isSelf && _showHidden && hasHidden
            ? all
            : public;
        final List<Persona> shown = sortPersonaGallery(
          filterPersonaGallery(base, _query),
          _sort,
          isOwner: owner.isSelf,
          nameOrder: nameOrder,
        );
        if (owner.isSelf) {
          header
            ..add(
              _OwnGalleryBar(
                publicCount: public.length,
                showHidden: hasHidden ? _showHidden : null,
                onShowHiddenChanged: (bool value) =>
                    setState(() => _showHidden = value),
                onManage: _openManage,
                onChooseFeatured: _openChooseFeatured,
              ),
            )
            ..add(SizedBox(height: layout.s3));
        }
        header.addAll(<Widget>[
          PickerSearchInput.inline(
            controller: _search,
            hintText: owner.isSelf
                ? l10n.fork.personaGallerySearchOwn
                : l10n.fork.personaGallerySearchOther(owner.name),
            onChanged: (String value) => setState(() => _query = value),
            onCleared: () => setState(() => _query = ''),
          ),
          SizedBox(height: layout.s3),
          Wrap(
            spacing: layout.s2,
            runSpacing: layout.s2,
            children: <Widget>[
              for (final PersonaGalleryView option in PersonaGalleryView.values)
                _GalleryChip(
                  key: ValueKey<String>('persona-gallery-view-${option.name}'),
                  label: _viewLabel(l10n, option),
                  selected: option == view,
                  onTap: () => unawaited(
                    ref
                        .read(personaGalleryViewProvider.notifier)
                        .choose(option),
                  ),
                ),
            ],
          ),
          SizedBox(height: layout.s2),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _query.trim().isEmpty
                      ? l10n.fork.personaGalleryCount(base.length)
                      : l10n.fork.personaGalleryCountFiltered(
                          shown.length,
                          base.length,
                        ),
                  key: const ValueKey<String>('persona-gallery-count'),
                  style: context.textStyles.bodySmall.copyWith(
                    color: context.colors.textPrimaryMuted,
                  ),
                ),
              ),
              _SortButton(
                label: _sortLabel(l10n, _sort),
                semanticLabel: l10n.fork.personaGallerySortBy,
                onTap: () => unawaited(_chooseSort()),
              ),
            ],
          ),
          SizedBox(height: layout.s3),
        ]);
        if (shown.isEmpty && _query.trim().isNotEmpty) {
          content.add(
            SliverToBoxAdapter(
              child: _GalleryMessage(
                key: const ValueKey<String>('persona-gallery-no-match'),
                icon: PhosphorIconsBold.magnifyingGlass,
                text: l10n.fork.personaGalleryNoMatch,
              ),
            ),
          );
        } else if (shown.isNotEmpty) {
          content.add(
            _PersonaGalleryItems(
              view: view,
              owner: owner,
              personas: shown,
              onOpen: (int index) => _openPersona(shown, index),
            ),
          );
        }
    }

    return CustomScrollView(
      controller: widget.scrollController,
      slivers: <Widget>[
        SliverPadding(
          padding: EdgeInsets.fromLTRB(layout.s4, layout.s1, layout.s4, 0),
          sliver: SliverList.list(children: header),
        ),
        for (final Widget sliver in content)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: layout.s4),
            sliver: sliver,
          ),
        SliverToBoxAdapter(
          child: SizedBox(
            height:
                layout.s4 + FluxerBottomSheet.scrollBottomPaddingOf(context),
          ),
        ),
      ],
    );
  }
}

String _viewLabel(FluxerLocalizations l10n, PersonaGalleryView view) =>
    switch (view) {
      PersonaGalleryView.gallery => l10n.fork.personaGalleryViewGallery,
      PersonaGalleryView.list => l10n.fork.personaGalleryViewList,
      PersonaGalleryView.avatars => l10n.fork.personaGalleryViewAvatars,
    };

String _sortLabel(FluxerLocalizations l10n, PersonaGallerySort sort) =>
    switch (sort) {
      PersonaGallerySort.name => l10n.fork.personaGallerySortName,
      PersonaGallerySort.mostUsed => l10n.fork.personaGallerySortMostUsed,
      PersonaGallerySort.recentlyUsed =>
        l10n.fork.personaGallerySortRecentlyUsed,
    };

/// The top of your own gallery: how many personas others see (or that none
/// is public yet), "Manage personas", and the switch for the others.
class _OwnGalleryBar extends StatelessWidget {
  const _OwnGalleryBar({
    required this.publicCount,
    required this.showHidden,
    required this.onShowHiddenChanged,
    required this.onManage,
    required this.onChooseFeatured,
  });

  final int publicCount;

  /// Null when every persona is public, so there is nothing to add.
  final bool? showHidden;
  final ValueChanged<bool> onShowHiddenChanged;
  final VoidCallback onManage;

  /// Opens the settings to pick personas to make public, when none is.
  final VoidCallback onChooseFeatured;

  @override
  Widget build(BuildContext context) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final colors = context.colors;
    final layout = context.layout;
    final bool? hidden = showHidden;
    return Container(
      key: const ValueKey<String>('persona-gallery-own-bar'),
      padding: EdgeInsets.all(layout.s3),
      decoration: BoxDecoration(
        color: FluxerBottomSheet.cardColorOf(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            publicCount == 0
                ? l10n.fork.personaGalleryNonePublic
                : l10n.fork.personaGalleryOthersSee(publicCount),
            style: context.textStyles.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: layout.s2),
          Wrap(
            spacing: layout.s2,
            runSpacing: layout.s2,
            children: <Widget>[
              if (publicCount == 0)
                FluxerButton.primary(
                  key: const ValueKey<String>(
                    'persona-gallery-choose-featured',
                  ),
                  size: FluxerButtonSize.compact,
                  fitContent: true,
                  icon: PhosphorIconsBold.star,
                  label: l10n.fork.personaGalleryChooseFeatured,
                  onPressed: onChooseFeatured,
                ),
              FluxerButton.secondary(
                size: FluxerButtonSize.compact,
                fitContent: true,
                icon: PhosphorIconsBold.gear,
                label: l10n.fork.personaGalleryManage,
                onPressed: onManage,
              ),
            ],
          ),
          if (hidden != null) ...<Widget>[
            SizedBox(height: layout.s2),
            FluxerTappable(
              key: const ValueKey<String>('persona-gallery-show-hidden'),
              onTap: () => onShowHiddenChanged(!hidden),
              toggled: hidden,
              semanticLabel: l10n.fork.personaGalleryShowHidden,
              excludeChildSemantics: true,
              builder: (BuildContext context, Set<WidgetState> states) =>
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: layout.s1),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            l10n.fork.personaGalleryShowHidden,
                            style: context.textStyles.bodyMedium.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        SizedBox(width: layout.s2),
                        FluxerSwitchControl(value: hidden),
                      ],
                    ),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GalleryChip extends StatelessWidget {
  const _GalleryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return FluxerTappable(
      onTap: onTap,
      selected: selected,
      semanticLabel: label,
      excludeChildSemantics: true,
      builder: (BuildContext context, Set<WidgetState> states) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? colors.brandPrimary
              : FluxerBottomSheet.cardColorOf(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: context.textStyles.label.copyWith(
            color: selected ? colors.textOnBrandPrimary : colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.label,
    required this.semanticLabel,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return FluxerTappable(
      key: const ValueKey<String>('persona-gallery-sort'),
      onTap: onTap,
      button: true,
      semanticLabel: '$semanticLabel: $label',
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
    );
  }
}

class _GalleryMessage extends StatelessWidget {
  const _GalleryMessage({
    required this.icon,
    required this.text,
    this.action,
    super.key,
  });

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;
    final Widget? trailing = action;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: layout.s6),
      child: Column(
        children: <Widget>[
          PhosphorIcon(icon, size: 36, color: colors.textPrimaryMuted),
          SizedBox(height: layout.s2),
          Text(
            text,
            textAlign: TextAlign.center,
            style: context.textStyles.bodySmall.copyWith(
              color: colors.textPrimaryMuted,
            ),
          ),
          if (trailing != null) ...<Widget>[
            SizedBox(height: layout.s3),
            trailing,
          ],
        ],
      ),
    );
  }
}

/// What the gallery draws of one persona, worked out once per item.
class _PersonaLook {
  _PersonaLook(this.persona, PersonaGalleryOwner owner)
    : ownerUserId = owner.userId,
      hasOwnAvatar = personaImageHash(persona.avatarHash) != null,
      color = resolvePersonaColor(
        color: persona.color,
        avatarColor: persona.avatarColor,
        avatarHash: persona.avatarHash,
      ),
      bio = personaBioPlainText(persona.bio) {
    smallAvatarUrl =
        personaAvatarUrl(
          ownerUserId: owner.userId,
          hash: persona.avatarHash,
          animated: false,
        ) ??
        owner.avatarUrl;
    largeAvatarUrl =
        personaAvatarUrl(
          ownerUserId: owner.userId,
          hash: persona.avatarHash,
          size: MediaProxySizes.avatarProfile,
          animated: false,
        ) ??
        owner.avatarUrl ??
        FluxerMediaUrl.defaultAvatar(userId: owner.userId);
    bannerUrl = personaBannerUrl(
      ownerUserId: owner.userId,
      hash: persona.bannerHash,
      size: 480,
      animated: false,
    );
    avatarColor = hasOwnAvatar ? persona.avatarColor : owner.avatarColor;
  }

  final Persona persona;
  final String ownerUserId;
  final bool hasOwnAvatar;

  /// The persona's colour (`resolvePersonaColor`), or null.
  final int? color;

  /// The bio as plain text, or null.
  final String? bio;
  late final String? smallAvatarUrl;
  late final String? largeAvatarUrl;
  late final String? bannerUrl;
  late final int? avatarColor;

  bool get isHidden => !isPublicPersona(persona);

  Color? get flutterColor {
    final int? value = color;
    return value == null ? null : Color(value | 0xFF000000);
  }

  /// The banner's fill: the persona's colour, else, for a persona showing the
  /// account's avatar, that avatar's colour.
  Color bannerFill(BuildContext context) {
    final int? value = color ?? (hasOwnAvatar ? null : avatarColor);
    return value == null
        ? context.colors.backgroundModifierSelected
        : Color(value | 0xFF000000);
  }
}

class _PersonaGalleryItems extends StatelessWidget {
  const _PersonaGalleryItems({
    required this.view,
    required this.owner,
    required this.personas,
    required this.onOpen,
  });

  final PersonaGalleryView view;
  final PersonaGalleryOwner owner;
  final List<Persona> personas;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    _PersonaLook look(int index) => _PersonaLook(personas[index], owner);
    switch (view) {
      case PersonaGalleryView.gallery:
        final int rows = (personas.length + 1) ~/ 2;
        return SliverList.builder(
          itemCount: rows,
          itemBuilder: (BuildContext context, int row) {
            final int first = row * 2;
            final int second = first + 1;
            return Padding(
              padding: EdgeInsets.only(bottom: layout.s3),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: _PersonaCard(
                        look: look(first),
                        isOwner: owner.isSelf,
                        onTap: () => onOpen(first),
                      ),
                    ),
                    SizedBox(width: layout.s3),
                    Expanded(
                      child: second < personas.length
                          ? _PersonaCard(
                              look: look(second),
                              isOwner: owner.isSelf,
                              onTap: () => onOpen(second),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      case PersonaGalleryView.list:
        return SliverLayoutBuilder(
          builder: (BuildContext context, SliverConstraints constraints) {
            final bool roomForDate = constraints.crossAxisExtent >= 400;
            return SliverList.separated(
              itemCount: personas.length,
              separatorBuilder: (BuildContext context, int index) => Divider(
                height: 1,
                thickness: 1,
                color: context.colors.backgroundHeaderSecondary.withValues(
                  alpha: 0.3,
                ),
              ),
              itemBuilder: (BuildContext context, int index) => _PersonaRow(
                look: look(index),
                isOwner: owner.isSelf,
                showCreated: roomForDate,
                onTap: () => onOpen(index),
              ),
            );
          },
        );
      case PersonaGalleryView.avatars:
        return SliverLayoutBuilder(
          builder: (BuildContext context, SliverConstraints constraints) {
            final double gap = layout.s3;
            final double tile = (constraints.crossAxisExtent - gap * 2) / 3;
            final double nameHeight =
                MediaQuery.textScalerOf(context).scale(13) * 1.4;
            return SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: gap,
                crossAxisSpacing: gap,
                mainAxisExtent: tile + layout.s1_5 + nameHeight + 2,
              ),
              itemCount: personas.length,
              itemBuilder: (BuildContext context, int index) =>
                  _AvatarTile(look: look(index), onTap: () => onOpen(index)),
            );
          },
        );
    }
  }
}

/// "Unlisted" or "Private", on a persona only its owner sees.
class _VisibilityBadge extends StatelessWidget {
  const _VisibilityBadge({
    required this.visibility,
    this.onImage = false,
    this.iconOnly = false,
  });

  final String visibility;
  final bool onImage;

  /// Only the icon, for a small tile; the word is its semantic label.
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final colors = context.colors;
    final bool isPrivate = visibility == 'private';
    final Color foreground = onImage ? Colors.white : colors.textSecondary;
    final String label = isPrivate
        ? l10n.fork.personaVisibilityPrivate
        : l10n.fork.personaVisibilityUnlisted;
    final Widget icon = PhosphorIcon(
      isPrivate ? PhosphorIconsBold.lockSimple : PhosphorIconsBold.eyeSlash,
      size: 11,
      color: foreground,
      semanticLabel: iconOnly ? label : null,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: onImage
            ? Colors.black.withValues(alpha: 0.6)
            : colors.backgroundModifierSelected,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          icon,
          if (!iconOnly) ...<Widget>[
            const SizedBox(width: 3),
            Text(
              label,
              style: context.textStyles.smallText.copyWith(
                color: foreground,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A gallery card: banner, avatar over its corner, name in the persona's
/// colour with pronouns, and two lines of bio.
class _PersonaCard extends StatelessWidget {
  const _PersonaCard({
    required this.look,
    required this.isOwner,
    required this.onTap,
  });

  final _PersonaLook look;
  final bool isOwner;
  final VoidCallback onTap;

  static const double _avatarSize = 40;
  static const double _ring = 3;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final Persona persona = look.persona;
    final Color cardColor = FluxerBottomSheet.cardColorOf(context);
    final String? bannerUrl = look.bannerUrl;
    final String? pronouns = persona.pronouns?.trim();
    final String? bio = look.bio;
    const double half = _avatarSize / 2 + _ring;

    final Widget card = FluxerTappable(
      onTap: onTap,
      button: true,
      semanticLabel: persona.name,
      builder: (BuildContext context, Set<WidgetState> states) => DecoratedBox(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Stack(
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      AspectRatio(
                        aspectRatio: 17 / 6,
                        child: ColoredBox(
                          color: look.bannerFill(context),
                          child: bannerUrl == null
                              ? null
                              : CachedNetworkImage(
                                  imageUrl: bannerUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const SizedBox.shrink(),
                                ),
                        ),
                      ),
                      const SizedBox(height: half),
                    ],
                  ),
                  PositionedDirectional(
                    start: 8,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: cardColor, width: _ring),
                      ),
                      child: FluxerAvatar.user(
                        userId: look.ownerUserId,
                        imageUrl: look.smallAvatarUrl,
                        fallbackText: persona.name,
                        avatarColor: look.avatarColor,
                        showStatus: false,
                      ),
                    ),
                  ),
                  if (isOwner && look.isHidden)
                    PositionedDirectional(
                      top: 6,
                      end: 6,
                      child: _VisibilityBadge(
                        visibility: persona.visibility,
                        onImage: true,
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      persona.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textStyles.username.copyWith(
                        color: look.flutterColor ?? colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (pronouns != null && pronouns.isNotEmpty)
                      Text(
                        pronouns,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textStyles.bodySmall.copyWith(
                          color: colors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      bio ?? l10n.fork.personaGalleryNoBio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textStyles.bodySmall.copyWith(
                        color: bio == null
                            ? colors.textTertiary
                            : colors.textSecondary,
                        fontStyle: bio == null ? FontStyle.italic : null,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return look.isHidden ? Opacity(opacity: 0.55, child: card) : card;
  }
}

/// A list row: avatar, name, pronouns, colour dot, a line of bio and, with
/// room, when it was created; for the owner also the visibility badge and
/// the proxy tags.
class _PersonaRow extends StatelessWidget {
  const _PersonaRow({
    required this.look,
    required this.isOwner,
    required this.showCreated,
    required this.onTap,
  });

  final _PersonaLook look;
  final bool isOwner;
  final bool showCreated;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final Persona persona = look.persona;
    final String? pronouns = persona.pronouns?.trim();
    final Color? dot = look.flutterColor;
    final DateTime? created = showCreated ? personaCreatedAt(persona) : null;
    final List<String> tags = isOwner
        ? <String>[
            for (final PersonaTag tag in persona.personaTags)
              if (tag
                  .displayPattern(l10n.fork.personaTagExampleText)
                  .isNotEmpty)
                tag.displayPattern(l10n.fork.personaTagExampleText),
          ]
        : const <String>[];

    final Widget row = FluxerTappable(
      onTap: onTap,
      button: true,
      semanticLabel: persona.name,
      builder: (BuildContext context, Set<WidgetState> states) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: <Widget>[
            FluxerAvatar.user(
              userId: look.ownerUserId,
              imageUrl: look.smallAvatarUrl,
              fallbackText: persona.name,
              avatarColor: look.avatarColor,
              showStatus: false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          persona.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textStyles.username.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (pronouns != null && pronouns.isNotEmpty) ...<Widget>[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '($pronouns)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textStyles.bodySmall.copyWith(
                              color: colors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      if (dot != null) ...<Widget>[
                        const SizedBox(width: 6),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: dot,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                      if (isOwner && look.isHidden) ...<Widget>[
                        const SizedBox(width: 6),
                        _VisibilityBadge(visibility: persona.visibility),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    look.bio ?? l10n.fork.personaGalleryNoBio,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyles.bodySmall.copyWith(
                      color: look.bio == null
                          ? colors.textTertiary
                          : colors.textSecondary,
                      fontStyle: look.bio == null ? FontStyle.italic : null,
                    ),
                  ),
                  if (tags.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: <Widget>[
                        for (final String tag in tags)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.backgroundModifierSelected,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tag,
                              style: textStyles.smallText.copyWith(
                                color: colors.textSecondary,
                                fontFamily: 'monospace',
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (created != null) ...<Widget>[
              const SizedBox(width: 12),
              Text(
                l10n.fork.personaGalleryCreated(
                  formatUserMediumDate(created.toLocal(), l10n.localeName),
                ),
                style: textStyles.bodySmall.copyWith(
                  color: colors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return look.isHidden ? Opacity(opacity: 0.55, child: row) : row;
  }
}

/// A square avatar with rounded corners and a border in the persona's
/// colour, its name below.
class _AvatarTile extends StatelessWidget {
  const _AvatarTile({required this.look, required this.onTap});

  final _PersonaLook look;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Persona persona = look.persona;
    final String? imageUrl = look.largeAvatarUrl;
    final Color fallback = look.avatarColor == null
        ? colors.backgroundTertiary
        : Color(look.avatarColor! | 0xFF000000);
    final Widget letter = ColoredBox(
      color: fallback,
      child: Center(
        child: Text(
          persona.name.isEmpty
              ? '?'
              : persona.name.characters.first.toUpperCase(),
          style: context.textStyles.heading.copyWith(color: colors.textPrimary),
        ),
      ),
    );
    final Widget tile = FluxerTappable(
      onTap: onTap,
      button: true,
      semanticLabel: persona.name,
      excludeChildSemantics: true,
      builder: (BuildContext context, Set<WidgetState> states) => Column(
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: look.flutterColor ?? colors.borderColor,
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: imageUrl == null
                          ? letter
                          : CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => letter,
                            ),
                    ),
                  ),
                ),
                if (look.isHidden)
                  PositionedDirectional(
                    top: 6,
                    end: 6,
                    child: _VisibilityBadge(
                      visibility: persona.visibility,
                      onImage: true,
                      iconOnly: true,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: context.layout.s1_5),
          Text(
            persona.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: context.textStyles.bodySmall.copyWith(
              color: colors.textPrimary,
              fontSize: 13,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    return look.isHidden ? Opacity(opacity: 0.55, child: tile) : tile;
  }
}
