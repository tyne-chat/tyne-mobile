import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/features/channels/domain/channel_permission_spec.dart';
import 'package:fluxer_app/features/settings/domain/guild/roles/guild_role_permission_spec.dart';

import '../../../helpers/test_l10n.dart';

// The fork's commands section is tested on its own, not through
// generateChannelPermissionSpec, whose signature upstream changes. Upstream's
// channel_permission_spec_test.dart pins the rows of "Messages & media", which
// shows the fork's row is not there (tyne-chat/tyne#915).
void main() {
  test('the commands section lists Use external commands', () {
    final GuildPermissionCategorySpec category = forkChannelCommandsCategory(
      testL10n,
    );

    expect(category.title, 'Commands');
    expect(
      category.permissions.map((GuildPermissionEntry e) => e.flag).toList(),
      <Permission>[Permission.useExternalCommands],
    );
    final GuildPermissionEntry entry = category.permissions.single;
    expect(entry.title, 'Use external commands');
    expect(
      entry.description,
      'Use commands from other communities in this channel.',
    );
  });
}
