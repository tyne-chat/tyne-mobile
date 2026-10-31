import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/permissions/channel_permission_cache_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/channels/providers/channel_providers.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/messages/message_double_tap_exemption.dart';
import 'package:fluxer_app/features/guild_commands/providers/guild_command_editing.dart';
import 'package:fluxer_app/features/guild_commands/providers/guild_commands_providers.dart';
import 'package:fluxer_app/features/guilds/providers/guild_permissions_provider.dart';
import 'package:fluxer_app/features/settings/domain/guild/guild_settings_tab.dart';
import 'package:fluxer_app/features/ui/action_menu/fluxer_action_menu.dart';
import 'package:fluxer_app/features/ui/tappable/fluxer_gesture_detector.dart';
import 'package:fluxer_app/features/ui/toast/fluxer_toast.dart';
import 'package:fluxer_app/features/ui/toast/toast_provider.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_dart/export.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Fork: the `/name` chip after the timestamp of a message made by a server
/// command. A tap puts `/name ` in an empty message box; a long press offers
/// the command's editor to those who may change it.
class GuildCommandChip extends ConsumerWidget {
  const GuildCommandChip({required this.message, super.key});

  final Message message;

  Future<GuildCommandResponseSchema?> _usable(WidgetRef ref) async {
    final GuildCommandsNotifier commands = ref.read(
      guildCommandsProvider.notifier,
    );
    await commands.ensureLoaded();
    final GuildCommandResponseSchema? command = commands.resolve(
      message.commandName!,
      channelGuildId: ref
          .read(channelByIdProvider(message.channelId))
          .value
          ?.guildId,
      channelPermissionBits:
          ref.read(channelPermissionCacheProvider)[message.channelId] ?? 0,
    );
    return command?.id == message.commandId ? command : null;
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final GuildCommandResponseSchema? command = await _usable(ref);
    if (command != null) {
      ref
          .read(pendingGuildCommandInsertProvider.notifier)
          .emit(message.channelId, command.name);
      return;
    }
    ref
        .read(toastProvider.notifier)
        .show(
          FluxerToast(
            message: l10n.fork.guildCommandMadeWith(message.commandName!),
          ),
        );
  }

  Future<void> _onLongPress(
    BuildContext context,
    WidgetRef ref,
    Offset position,
  ) async {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final String guildId = message.commandGuildId!;
    final GuildCommandsNotifier commands = ref.read(
      guildCommandsProvider.notifier,
    );
    await commands.ensureLoaded();
    final int permissions = await ref
        .read(guildPermissionsProvider.notifier)
        .getPermissions(guildId);
    final GuildCommandResponseSchema? command = commands.findById(
      message.commandId!,
    );
    if (command == null ||
        !canEditGuildCommand(
          permissions: permissions,
          creatorId: command.creatorId,
          currentUserId: ref.read(currentUserIdProvider),
        ) ||
        !context.mounted) {
      return;
    }
    await FluxerActionMenu.show(
      context,
      position: position,
      builder: (BuildContext menuContext, VoidCallback close) => <Widget>[
        FluxerMenuItem(
          label: l10n.fork.guildCommandEdit(command.name),
          icon: PhosphorIconsBold.pencilSimple,
          onPressed: () {
            close();
            ref
                .read(guildCommandEditRequestProvider.notifier)
                .request(guildId, command.id);
            unawaited(
              context.push(
                guildSettingsTabPath(guildId, GuildSettingsTab.commands),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MessageDoubleTapExempt(
      child: FluxerGestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => unawaited(_onTap(context, ref)),
        onLongPressStart: (LongPressStartDetails details) =>
            unawaited(_onLongPress(context, ref, details.globalPosition)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: context.colors.backgroundSecondary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '/${message.commandName}', // i18n-ignore: a name its community typed.
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.timestamp.copyWith(
              color: context.colors.textLink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
