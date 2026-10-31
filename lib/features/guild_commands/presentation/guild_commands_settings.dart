import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/pickers/picker_search_input.dart';
import 'package:fluxer_app/features/guild_commands/presentation/guild_command_editor.dart';
import 'package:fluxer_app/features/guild_commands/providers/guild_command_editing.dart';
import 'package:fluxer_app/features/guilds/providers/guild_permissions_provider.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button.dart';
import 'package:fluxer_app/features/ui/spinner/fluxer_loading_spinner.dart';
import 'package:fluxer_app/features/ui/tappable/fluxer_gesture_detector.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_dart/export.dart';

const int _maxCommands = 500;

/// Fork: the Commands tab of community settings: the list, with the editor in a
/// sheet over it. A chip can ask for a command to open directly.
class GuildCommandsSettings extends ConsumerStatefulWidget {
  const GuildCommandsSettings({required this.guildId, super.key});

  final String guildId;

  @override
  ConsumerState<GuildCommandsSettings> createState() =>
      _GuildCommandsSettingsState();
}

class _GuildCommandsSettingsState extends ConsumerState<GuildCommandsSettings> {
  final TextEditingController _search = TextEditingController();

  /// A command a chip asked to open, until the list that holds it is in.
  String? _pendingId;
  bool _isOpening = false;
  int _permissions = 0;

  @override
  void initState() {
    super.initState();
    final GuildCommandEdit? request = ref.read(guildCommandEditRequestProvider);
    if (request?.guildId == widget.guildId) {
      _pendingId = request?.commandId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(guildCommandEditRequestProvider.notifier).consume();
        }
      });
    }
    unawaited(_loadPermissions());
  }

  Future<void> _loadPermissions() async {
    final int permissions = await ref
        .read(guildPermissionsProvider.notifier)
        .getPermissions(widget.guildId);
    if (mounted) {
      setState(() => _permissions = permissions);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Opens the editor on a command, or on a new one without [id].
  Future<void> _open(
    String? id,
    List<GuildCommandResponseSchema> commands,
  ) async {
    if (_isOpening) {
      return;
    }
    _isOpening = true;
    try {
      final int permissions = await ref
          .read(guildPermissionsProvider.notifier)
          .getPermissions(widget.guildId);
      if (!mounted) {
        return;
      }
      final GuildCommandResponseSchema? command = commands
          .where((GuildCommandResponseSchema c) => c.id == id)
          .firstOrNull;
      await GuildCommandEditorSheet.show(
        context,
        guildId: widget.guildId,
        command: command,
        taken: <String>{
          for (final GuildCommandResponseSchema c in commands)
            if (c.id != id) c.name,
        },
        editable:
            command == null ||
            canEditGuildCommand(
              permissions: permissions,
              creatorId: command.creatorId,
              currentUserId: ref.read(currentUserIdProvider),
            ),
      );
    } finally {
      _isOpening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GuildCommandEdit?>(guildCommandEditRequestProvider, (
      _,
      GuildCommandEdit? request,
    ) {
      if (request?.guildId == widget.guildId) {
        ref.read(guildCommandEditRequestProvider.notifier).consume();
        setState(() => _pendingId = request?.commandId);
      }
    });
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final AsyncValue<List<GuildCommandResponseSchema>> commands = ref.watch(
      guildCommandsSettingsProvider(widget.guildId),
    );
    return commands.when(
      loading: () => const Center(child: FluxerLoadingSpinner()),
      error: (Object error, StackTrace _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.fork.guildCommandsLoadFailed,
            style: TextStyle(color: context.colors.textTertiary),
          ),
        ),
      ),
      data: (List<GuildCommandResponseSchema> list) {
        final String? pendingId = _pendingId;
        if (pendingId != null) {
          _pendingId = null;
          if (list.any((GuildCommandResponseSchema c) => c.id == pendingId)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                unawaited(_open(pendingId, list));
              }
            });
          }
        }
        return _CommandList(
          commands: list,
          search: _search,
          canCreate:
              _permissions & Permission.createCommands.value != 0 &&
              list.length < _maxCommands,
          onChanged: () => setState(() {}),
          onNew: () => unawaited(_open(null, list)),
          onOpen: (String id) => unawaited(_open(id, list)),
        );
      },
    );
  }
}

class _CommandList extends StatelessWidget {
  const _CommandList({
    required this.commands,
    required this.search,
    required this.canCreate,
    required this.onChanged,
    required this.onNew,
    required this.onOpen,
  });

  final List<GuildCommandResponseSchema> commands;
  final TextEditingController search;
  final bool canCreate;
  final VoidCallback onChanged;
  final VoidCallback onNew;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final String query = search.text.trim().toLowerCase();
    final List<GuildCommandResponseSchema> shown = <GuildCommandResponseSchema>[
      for (final GuildCommandResponseSchema command in commands)
        if (command.name.contains(query) ||
            command.description.toLowerCase().contains(query))
          command,
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(
          l10n.fork.guildCommandsSubtitle,
          style: TextStyle(color: context.colors.textTertiary),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                l10n.fork.guildCommandsSlots,
                style: context.textStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${commands.length} / $_maxCommands', // i18n-ignore: two numbers.
              style: TextStyle(color: context.colors.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (canCreate) ...<Widget>[
          FluxerButton.primary(
            label: l10n.fork.guildCommandsNew,
            onPressed: onNew,
          ),
          const SizedBox(height: 12),
        ],
        if (commands.isNotEmpty)
          PickerSearchInput(
            hintText: l10n.fork.guildCommandsSearch,
            controller: search,
            horizontalPadding: 0,
            onChanged: (_) => onChanged(),
          ),
        if (commands.isEmpty) ...<Widget>[
          const SizedBox(height: 16),
          Text(
            l10n.fork.guildCommandsEmptyTitle,
            style: context.textStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.fork.guildCommandsEmptyBody,
            style: TextStyle(color: context.colors.textTertiary),
          ),
        ],
        for (final GuildCommandResponseSchema command in shown)
          FluxerGestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onOpen(command.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '/${command.name}', // i18n-ignore: a name its community typed.
                    style: context.textStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (command.description.isNotEmpty)
                    Text(
                      command.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.colors.textTertiary),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
