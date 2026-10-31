import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';

/// Fork: a guild's permissions as they were when READY last emptied
/// `guildPermissionsProvider`. Every READY does, reconnects included, and each
/// guild comes back as READY is processed. Until then the settings screens read
/// this, so that "not worked out yet" is not taken for "no permissions", which
/// would throw someone out of the tab they are editing (tyne-chat/tyne#274).
class HeldGuildPermissions extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() {
    ref.watch(currentUserIdProvider);
    return const <String, int>{};
  }

  void hold(Map<String, int> permissions) {
    if (permissions.isNotEmpty) {
      state = <String, int>{...state, ...permissions};
    }
  }

  void forget(String guildId) {
    if (state.containsKey(guildId)) {
      state = <String, int>{...state}..remove(guildId);
    }
  }
}

final NotifierProvider<HeldGuildPermissions, Map<String, int>>
heldGuildPermissionsProvider =
    NotifierProvider<HeldGuildPermissions, Map<String, int>>(
      HeldGuildPermissions.new,
    );
