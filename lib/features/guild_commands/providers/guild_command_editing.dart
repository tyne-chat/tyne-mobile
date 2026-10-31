import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/features/guild_commands/data/guild_commands_repository.dart';
import 'package:fluxer_dart/export.dart';

/// One community's commands with their templates, for the settings tab.
final FutureProviderFamily<List<GuildCommandResponseSchema>, String>
guildCommandsSettingsProvider = FutureProvider.autoDispose
    .family<List<GuildCommandResponseSchema>, String>((
      Ref ref,
      String guildId,
    ) async {
      final List<GuildCommandResponseSchema> commands = await ref
          .read(guildCommandsRepositoryProvider)
          .listForGuild(guildId);
      return <GuildCommandResponseSchema>[...commands]
        ..sort((GuildCommandResponseSchema a, GuildCommandResponseSchema b) {
          return a.name.compareTo(b.name);
        });
    });

/// The server's rule for changing a command: Manage Commands, or Create
/// Commands for one's own.
bool canEditGuildCommand({
  required int permissions,
  required String creatorId,
  required String? currentUserId,
}) {
  if (permissions & Permission.manageCommands.value != 0) {
    return true;
  }
  return permissions & Permission.createCommands.value != 0 &&
      creatorId == currentUserId;
}

/// A command to open in a community's settings tab.
typedef GuildCommandEdit = ({String guildId, String commandId});

/// Holds a [GuildCommandEdit] until that community's tab takes it.
class GuildCommandEditRequest extends Notifier<GuildCommandEdit?> {
  @override
  GuildCommandEdit? build() => null;

  void request(String guildId, String commandId) {
    state = (guildId: guildId, commandId: commandId);
  }

  void consume() => state = null;
}

final NotifierProvider<GuildCommandEditRequest, GuildCommandEdit?>
guildCommandEditRequestProvider =
    NotifierProvider<GuildCommandEditRequest, GuildCommandEdit?>(
      GuildCommandEditRequest.new,
    );

/// `/name ` to put in the composer of a channel, from a tap on a chip.
typedef GuildCommandInsert = ({String channelId, String name});

class PendingGuildCommandInsert extends Notifier<GuildCommandInsert?> {
  @override
  GuildCommandInsert? build() => null;

  void emit(String channelId, String name) {
    state = (channelId: channelId, name: name);
  }

  void consume() => state = null;
}

final NotifierProvider<PendingGuildCommandInsert, GuildCommandInsert?>
pendingGuildCommandInsertProvider =
    NotifierProvider<PendingGuildCommandInsert, GuildCommandInsert?>(
      PendingGuildCommandInsert.new,
    );

final RegExp _basicOutput = RegExp(r'\{\{\s*(?:person|input)\s*\}\}');

/// What a basic template becomes; the server does the same for a real run.
String fillBasicGuildCommandTemplate(
  String template, {
  required String person,
  required String input,
}) {
  return template.replaceAllMapped(_basicOutput, (Match match) {
    return match.group(0)!.contains('person') ? person : input;
  });
}
