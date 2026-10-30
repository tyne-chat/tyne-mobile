import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_dart/export.dart';

/// Fork: the routes of server commands that the phone uses.
class GuildCommandsRepository {
  const GuildCommandsRepository(this._client);

  final FluxerClient _client;

  /// Every command of every community the user belongs to, in one request.
  Future<List<GuildCommandResponseSchema>> listMine() {
    return _client.guildCommands.listMyGuildCommands();
  }

  Future<List<GuildCommandResponseSchema>> listForGuild(String guildId) {
    return _client.guildCommands.listGuildCommands(guildId: guildId);
  }

  Future<void> run({
    required String channelId,
    required String commandId,
    required String input,
    required String? personaId,
    required String nonce,
  }) async {
    await _client.guildCommands.runGuildCommand(
      channelId: channelId,
      commandId: commandId,
      body: GuildCommandRunRequestSchema(
        nonce: nonce,
        input: input.isEmpty
            ? const JsonNullable<String>.undefined()
            : JsonNullable<String>.of(input),
        personaId: personaId == null
            ? const JsonNullable<String>.undefined()
            : JsonNullable<String>.of(personaId),
      ),
    );
  }
}

final Provider<GuildCommandsRepository> guildCommandsRepositoryProvider =
    Provider<GuildCommandsRepository>(
      (Ref ref) => GuildCommandsRepository(ref.watch(fluxerClientProvider)),
    );
