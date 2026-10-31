import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/chat/domain/composer_slash_command.dart';
import 'package:fluxer_app/features/guild_commands/data/guild_commands_repository.dart';
import 'package:fluxer_app/features/guilds/domain/guild.dart';
import 'package:fluxer_app/features/guilds/providers/organized_guild_list_provider.dart';
import 'package:fluxer_dart/export.dart';

/// With more stale communities than this, one request reloads them all.
const int _maxGuildRefreshes = 3;

/// After a failed request, nothing is asked again for this long.
const Duration _failureCooldown = Duration(seconds: 30);

/// How long the `/` list waits for the first load before showing the built-ins.
const Duration _listWait = Duration(milliseconds: 800);

/// The user's communities in sidebar order, which decides between two commands
/// of one name.
final Provider<List<({String id, String name})>> guildCommandsSidebarProvider =
    Provider<List<({String id, String name})>>(
      (Ref ref) => <({String id, String name})>[
        for (final Guild guild in flattenOrganizedGuildList(
          ref.watch(organizedGuildListProvider),
        ))
          (id: guild.id, name: guild.name),
      ],
    );

final Provider<DateTime Function()> guildCommandsClockProvider =
    Provider<DateTime Function()>((Ref ref) => DateTime.now);

@immutable
class GuildCommandsState {
  const GuildCommandsState({
    this.byGuild = const <String, List<GuildCommandResponseSchema>>{},
    this.loaded = false,
  });

  final Map<String, List<GuildCommandResponseSchema>> byGuild;
  final bool loaded;
}

/// The commands usable in a channel, in precedence order: its community first,
/// then the sidebar's. Another community's need Use External Commands in a
/// community channel; in DMs every community's work.
List<GuildCommandResponseSchema> usableGuildCommands(
  GuildCommandsState state, {
  required List<String> sidebarGuildIds,
  required String? channelGuildId,
  required int channelPermissionBits,
}) {
  final bool inDm = channelGuildId == null || channelGuildId.isEmpty;
  final bool external =
      inDm || channelPermissionBits & Permission.useExternalCommands.value != 0;
  final List<String> order = <String>[
    if (!inDm) channelGuildId,
    if (external) ...sidebarGuildIds.where((String id) => id != channelGuildId),
  ];
  return <GuildCommandResponseSchema>[
    for (final String guildId in order) ...?state.byGuild[guildId],
  ];
}

/// Fork: the commands of every community the user belongs to, for the composer
/// (the server repository's docs/design/server-commands.md, "Mobile client").
/// Loaded with one request on first use; an event or joining a community marks
/// it stale, and the next use fetches only that community.
class GuildCommandsNotifier extends Notifier<GuildCommandsState> {
  Future<void>? _listRequest;
  final Map<String, Future<void>> _guildRequests = <String, Future<void>>{};
  final Set<String> _stale = <String>{};
  Set<String> _knownGuildIds = const <String>{};
  DateTime? _failedAt;
  int _session = 0;

  @override
  GuildCommandsState build() {
    // Another account has other communities.
    ref.watch(currentUserIdProvider);
    _session += 1;
    _listRequest = null;
    _guildRequests.clear();
    _stale.clear();
    _knownGuildIds = const <String>{};
    _failedAt = null;
    return const GuildCommandsState();
  }

  void markStale(String guildId) {
    if (state.loaded) {
      _stale.add(guildId);
    }
  }

  bool get _coolingDown {
    final DateTime? failedAt = _failedAt;
    return failedAt != null &&
        ref.read(guildCommandsClockProvider)().difference(failedAt) <
            _failureCooldown;
  }

  /// Joining marks a community stale; leaving drops its commands. Read at each
  /// use, so a community that is never used costs nothing.
  void _followSidebar() {
    if (!state.loaded) {
      return;
    }
    final Set<String> current = <String>{
      for (final ({String id, String name}) guild in ref.read(
        guildCommandsSidebarProvider,
      ))
        guild.id,
    };
    if (current.isEmpty) {
      return;
    }
    _stale.addAll(current.difference(_knownGuildIds));
    final Set<String> left = _knownGuildIds.difference(current);
    _knownGuildIds = current;
    if (left.isEmpty) {
      return;
    }
    _stale.removeAll(left);
    state = GuildCommandsState(
      loaded: true,
      byGuild: <String, List<GuildCommandResponseSchema>>{
        for (final MapEntry<String, List<GuildCommandResponseSchema>> entry
            in state.byGuild.entries)
          if (!left.contains(entry.key)) entry.key: entry.value,
      },
    );
  }

  /// Loads every community's commands once, sharing the request, then refreshes
  /// stale ones. A use sends at most [_maxGuildRefreshes] requests: beyond that,
  /// the list request reloads them all.
  Future<void> ensureLoaded() async {
    _followSidebar();
    if (!state.loaded || _stale.length > _maxGuildRefreshes) {
      if (_coolingDown) {
        return;
      }
      await (_listRequest ??= _fetchAll().whenComplete(() {
        _listRequest = null;
      }));
      return;
    }
    await Future.wait(_stale.toList().map(_refreshGuild));
  }

  Future<void> _fetchAll() async {
    final int session = _session;
    try {
      final List<GuildCommandResponseSchema> commands = await ref
          .read(guildCommandsRepositoryProvider)
          .listMine();
      if (session != _session) {
        return;
      }
      final Map<String, List<GuildCommandResponseSchema>> grouped =
          <String, List<GuildCommandResponseSchema>>{};
      for (final GuildCommandResponseSchema command in commands) {
        (grouped[command.guildId] ??= <GuildCommandResponseSchema>[]).add(
          command,
        );
      }
      _stale.clear();
      _failedAt = null;
      _knownGuildIds = <String>{
        for (final ({String id, String name}) guild in ref.read(
          guildCommandsSidebarProvider,
        ))
          guild.id,
      };
      state = GuildCommandsState(byGuild: grouped, loaded: true);
    } on Exception catch (error) {
      debugPrint('[GuildCommands] Failed to load commands: $error');
      if (session == _session) {
        _failedAt = ref.read(guildCommandsClockProvider)();
      }
    }
  }

  Future<void> _refreshGuild(String guildId) async {
    if (_coolingDown) {
      return;
    }
    await (_guildRequests[guildId] ??= _fetchGuild(guildId).whenComplete(() {
      _guildRequests.remove(guildId)?.ignore();
    }));
  }

  Future<void> _fetchGuild(String guildId) async {
    final int session = _session;
    try {
      final List<GuildCommandResponseSchema> commands = await ref
          .read(guildCommandsRepositoryProvider)
          .listForGuild(guildId);
      if (session != _session) {
        return;
      }
      _stale.remove(guildId);
      state = GuildCommandsState(
        loaded: true,
        byGuild: <String, List<GuildCommandResponseSchema>>{
          ...state.byGuild,
          guildId: commands,
        },
      );
    } on Exception catch (error) {
      debugPrint('[GuildCommands] Failed to refresh commands: $error');
      if (session == _session) {
        _failedAt = ref.read(guildCommandsClockProvider)();
      }
    }
  }

  GuildCommandResponseSchema? findById(String commandId) {
    for (final List<GuildCommandResponseSchema> commands
        in state.byGuild.values) {
      for (final GuildCommandResponseSchema command in commands) {
        if (command.id == commandId) {
          return command;
        }
      }
    }
    return null;
  }

  /// [ensureLoaded], without holding up the `/` list on a slow connection.
  Future<void> loadForList() async {
    try {
      await ensureLoaded().timeout(_listWait);
    } on TimeoutException {
      // The built-ins show now, and the commands from the next keystroke on.
    }
  }

  List<GuildCommandResponseSchema> _usable({
    required String? channelGuildId,
    required int channelPermissionBits,
  }) {
    return usableGuildCommands(
      state,
      sidebarGuildIds: <String>[
        for (final ({String id, String name}) guild in ref.read(
          guildCommandsSidebarProvider,
        ))
          guild.id,
      ],
      channelGuildId: channelGuildId,
      channelPermissionBits: channelPermissionBits,
    );
  }

  /// The command `/name` runs in a channel; null when there is none.
  GuildCommandResponseSchema? resolve(
    String name, {
    required String? channelGuildId,
    required int channelPermissionBits,
  }) {
    for (final GuildCommandResponseSchema command in _usable(
      channelGuildId: channelGuildId,
      channelPermissionBits: channelPermissionBits,
    )) {
      if (command.name == name) {
        return command;
      }
    }
    return null;
  }

  /// [builtIns] and the commands usable in a channel, one per name: the one
  /// `/name` runs. Picking one inserts `/name ` as text, so the input is typed
  /// in the normal composer, with mentions and emoji working.
  List<ComposerSlashCommand> composerCommands(
    List<ComposerSlashCommand> builtIns, {
    required String? channelGuildId,
    required int channelPermissionBits,
  }) {
    final Map<String, String> communityNames = <String, String>{
      for (final ({String id, String name}) guild in ref.read(
        guildCommandsSidebarProvider,
      ))
        guild.id: guild.name,
    };
    final Set<String> taken = <String>{
      for (final ComposerSlashCommand command in builtIns) command.name,
    };
    return <ComposerSlashCommand>[
      ...builtIns,
      for (final GuildCommandResponseSchema command in _usable(
        channelGuildId: channelGuildId,
        channelPermissionBits: channelPermissionBits,
      ))
        if (taken.add('/${command.name}'))
          ComposerActionSlashCommand(
            name: '/${command.name}',
            description: <String>[
              if (command.description.isNotEmpty) command.description,
              ?communityNames[command.guildId],
            ].join(' · '),
          ),
    ];
  }
}

final NotifierProvider<GuildCommandsNotifier, GuildCommandsState>
guildCommandsProvider =
    NotifierProvider<GuildCommandsNotifier, GuildCommandsState>(
      GuildCommandsNotifier.new,
    );
