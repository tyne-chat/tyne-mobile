// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: a persona's profile opened from an account's "Personas (N)" gallery
// (tyne-chat/tyne#189). A swipe sideways goes to the next or previous persona
// in the gallery's order; each page is the usual persona profile
// (`UserProfileView` with a persona id).
//
// Every page scrolls with the sheet's one controller, so dragging any of them
// down still closes the sheet. A page for someone else's persona fetches that
// persona's profile when it is first shown, as opening it from a message
// does (`publicPersonaProvider`, once per session): one request per persona
// swiped to, at the pace of the swipes.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/features/profile/presentation/widgets/user_profile_view.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/providers/input_modality_provider.dart';

class PersonaProfilePager {
  PersonaProfilePager._();

  /// Opens the profile of `personaIds[initialIndex]`, an account's persona,
  /// with the others a swipe away.
  static Future<void> show(
    BuildContext context, {
    required String ownerUserId,
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
    required this.personaIds,
    required this.initialIndex,
    required this.scrollController,
    required this.onClose,
    this.guildId,
    super.key,
  });

  final String ownerUserId;
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
      itemBuilder: (BuildContext context, int index) => UserProfileView(
        key: ValueKey<String>('persona-page-${widget.personaIds[index]}'),
        userId: widget.ownerUserId,
        personaId: widget.personaIds[index],
        guildId: widget.guildId,
        autoFocusNote: false,
        scrollController: widget.scrollController,
        onCloseRequested: widget.onClose,
        showTopHandle: showTopHandle,
      ),
    );
  }
}
