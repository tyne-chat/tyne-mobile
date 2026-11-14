// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: a persona's profile opened from an account's "Personas (N)" gallery
// (tyne-chat/tyne#189). A swipe sideways goes to the next or previous persona
// in the gallery's order; each page is the usual persona profile
// (`UserProfileView` with a persona id).
//
// Every page scrolls with the sheet's one controller, so dragging any of them
// down still closes the sheet. A page for someone else's persona shows the copy
// in the account's public list, which the gallery has already loaded: the
// server sends the same profile card there as for one persona, so nothing is
// asked on opening or swiping, the account's display tag shows as it does on a
// message, and the page follows the list when it is fetched again
// (tyne-chat/tyne#640). Only a persona that is no longer in the list (made
// unlisted or private, or deleted, since it loaded) is fetched on its own, as
// opening it from a message does (`publicPersonaProvider`, once per session).
// Your own personas come from your own list (`myPersonasProvider`), and your
// public list is never asked for.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/features/profile/domain/public_persona.dart';
import 'package:fluxer_app/features/profile/presentation/widgets/user_profile_view.dart';
import 'package:fluxer_app/features/profile/providers/public_persona_list_provider.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/providers/input_modality_provider.dart';

class PersonaProfilePager {
  PersonaProfilePager._();

  /// Opens the profile of `personaIds[initialIndex]`, an account's persona,
  /// with the others a swipe away. [ownerIsSelf] tells whether the account is
  /// the viewer's own.
  static Future<void> show(
    BuildContext context, {
    required String ownerUserId,
    required bool ownerIsSelf,
    required List<String> personaIds,
    required int initialIndex,
    String? guildId,
  }) {
    return FluxerBottomSheet.showScrollable<void>(
      context,
      useRootNavigator: true,
      minChildSize: 0.5,
      showDragHandle: false,
      builder:
          (
            BuildContext sheetContext,
            ScrollController scrollController,
            VoidCallback close,
          ) => PersonaProfilePagerBody(
            ownerUserId: ownerUserId,
            ownerIsSelf: ownerIsSelf,
            personaIds: personaIds,
            initialIndex: initialIndex,
            guildId: guildId,
            scrollController: scrollController,
            onClose: close,
          ),
    );
  }
}

class PersonaProfilePagerBody extends ConsumerStatefulWidget {
  const PersonaProfilePagerBody({
    required this.ownerUserId,
    required this.ownerIsSelf,
    required this.personaIds,
    required this.initialIndex,
    required this.scrollController,
    required this.onClose,
    this.guildId,
    super.key,
  });

  final String ownerUserId;
  final bool ownerIsSelf;
  final List<String> personaIds;
  final int initialIndex;
  final String? guildId;
  final ScrollController scrollController;
  final VoidCallback onClose;

  @override
  ConsumerState<PersonaProfilePagerBody> createState() =>
      _PersonaProfilePagerBodyState();
}

class _PersonaProfilePagerBodyState
    extends ConsumerState<PersonaProfilePagerBody> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex.clamp(
      0,
      widget.personaIds.isEmpty ? 0 : widget.personaIds.length - 1,
    ),
  );

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showTopHandle = !usesDesktopPointerUi(context);
    return PageView.builder(
      controller: _pages,
      itemCount: widget.personaIds.length,
      itemBuilder: (BuildContext context, int index) => _PersonaPage(
        ownerUserId: widget.ownerUserId,
        ownerIsSelf: widget.ownerIsSelf,
        personaId: widget.personaIds[index],
        guildId: widget.guildId,
        scrollController: widget.scrollController,
        onClose: widget.onClose,
        showTopHandle: showTopHandle,
      ),
    );
  }
}

/// One persona's profile: for someone else's persona, the copy in the
/// account's public list when the list holds it.
class _PersonaPage extends ConsumerWidget {
  const _PersonaPage({
    required this.ownerUserId,
    required this.ownerIsSelf,
    required this.personaId,
    required this.guildId,
    required this.scrollController,
    required this.onClose,
    required this.showTopHandle,
  });

  final String ownerUserId;
  final bool ownerIsSelf;
  final String personaId;
  final String? guildId;
  final ScrollController scrollController;
  final VoidCallback onClose;
  final bool showTopHandle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PublicPersona? listed = ownerIsSelf
        ? null
        : _listedPersona(
            ref.watch(publicPersonaListProvider(ownerUserId)).value,
            personaId,
          );
    return UserProfileView(
      key: ValueKey<String>('persona-page-$personaId'),
      userId: ownerUserId,
      personaId: personaId,
      personaProfile: listed,
      guildId: guildId,
      autoFocusNote: false,
      scrollController: scrollController,
      onCloseRequested: onClose,
      showTopHandle: showTopHandle,
    );
  }
}

/// [personaId] as the account's public list shows it, with the account's
/// display tag, or null when the list has not loaded or does not hold it.
PublicPersona? _listedPersona(
  PublicPersonaListResult? result,
  String personaId,
) {
  if (result is! PublicPersonaListLoaded) {
    return null;
  }
  final PublicPersonaList list = result.list;
  for (final PublicPersona persona in list.personas) {
    if (persona.id == personaId) {
      return persona.copyWith(
        displayTagText: list.displayTagText,
        displayTagIcon: list.displayTagIcon,
      );
    }
  }
  return null;
}
