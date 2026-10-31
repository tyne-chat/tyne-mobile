import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/features/guild_commands/providers/guild_command_editing.dart';
import 'package:fluxer_app/features/settings/domain/guild/guild_settings_tab.dart';
import 'package:fluxer_app/features/settings/domain/guild/roles/guild_role_permission_spec.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations_en.dart';

void main() {
  group('who may edit a command', () {
    bool canEdit(int permissions, String creatorId) => canEditGuildCommand(
      permissions: permissions,
      creatorId: creatorId,
      currentUserId: 'me',
    );

    test("Manage Commands edits anyone's", () {
      expect(canEdit(Permission.manageCommands.value, 'other'), isTrue);
    });

    test("Create Commands edits only one's own", () {
      expect(canEdit(Permission.createCommands.value, 'me'), isTrue);
      expect(canEdit(Permission.createCommands.value, 'other'), isFalse);
    });

    test("neither edits nothing, even one's own", () {
      expect(canEdit(Permission.useExternalCommands.value, 'me'), isFalse);
    });

    test('the community owner, with every bit, edits anything', () {
      expect(canEdit(allPermissions, 'other'), isTrue);
    });
  });

  group('the permission bits', () {
    test('match the server', () {
      expect(Permission.createCommands.value, 1 << 62);
      expect(Permission.manageCommands.value, 1 << 61);
      expect(Permission.useExternalCommands.value, 1 << 59);
    });

    test('are all inside the mask, and new roles may use external ones', () {
      for (final Permission permission in Permission.values) {
        expect(allPermissions & permission.value, permission.value);
      }
      expect(
        defaultPermissions & Permission.useExternalCommands.value,
        isNot(0),
      );
    });

    test('have labels in the role editor', () {
      final FluxerLocalizationsEn l10n = FluxerLocalizationsEn();
      for (final Permission permission in <Permission>[
        Permission.createCommands,
        Permission.manageCommands,
        Permission.useExternalCommands,
      ]) {
        expect(permissionTitle(l10n, permission), isNotEmpty);
        expect(permissionDescription(l10n, permission), isNotNull);
      }
    });
  });

  group('a basic template in the preview', () {
    test('fills in the person and the input, however they are spaced', () {
      expect(
        fillBasicGuildCommandTemplate(
          '# {{ person }} hugs {{input}} <:tuck:5>',
          person: '<@1>',
          input: 'you',
        ),
        '# <@1> hugs you <:tuck:5>',
      );
    });
  });

  test('the Commands tab survives a round trip through its query', () {
    expect(
      guildSettingsTabFromQuery(
        guildSettingsTabQuery(GuildSettingsTab.commands),
      ),
      GuildSettingsTab.commands,
    );
    expect(
      guildSettingsTabPath('1', GuildSettingsTab.commands),
      endsWith('/commands'),
    );
  });

  test("a chip's request to open a command is taken once", () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(guildCommandEditRequestProvider.notifier).request('g', '7');
    expect(container.read(guildCommandEditRequestProvider), (
      guildId: 'g',
      commandId: '7',
    ));
    container.read(guildCommandEditRequestProvider.notifier).consume();
    expect(container.read(guildCommandEditRequestProvider), isNull);
  });
}
