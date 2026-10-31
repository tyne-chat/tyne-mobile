import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/features/guild_commands/presentation/guild_commands_settings.dart';
import 'package:fluxer_app/features/settings/domain/guild/guild_settings_tab.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/guild/guild_settings_page_shell.dart';
import 'package:fluxer_app/material_ui.dart';

/// Fork: the Commands tab of community settings, as a page.
class SettingsCommandsPage extends ConsumerWidget {
  const SettingsCommandsPage({required this.guildId, super.key});

  final String guildId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GuildSettingsPageShell(
      guildId: guildId,
      tab: GuildSettingsTab.commands,
      body: GuildCommandsSettings(guildId: guildId),
    );
  }
}
