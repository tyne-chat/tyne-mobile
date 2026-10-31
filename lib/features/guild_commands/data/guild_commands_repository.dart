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

  Future<void> create({
    required String guildId,
    required String name,
    required String description,
    required String template,
    required GuildCommandInputMode inputMode,
    required String hint,
    required List<GuildCommandCounterInputSchema> counters,
  }) async {
    await _client.guildCommands.createGuildCommand(
      guildId: guildId,
      body: GuildCommandCreateRequestSchema(
        name: name,
        description: JsonNullable<String>.of(description),
        template: template,
        inputMode: inputMode,
        inputHint: _hint(hint),
        counters: counters,
      ),
    );
  }

  Future<void> update({
    required String guildId,
    required String commandId,
    required String name,
    required String description,
    required String template,
    required GuildCommandInputMode inputMode,
    required String hint,
    required List<GuildCommandCounterInputSchema> counters,
  }) async {
    await _client.guildCommands.updateGuildCommand(
      guildId: guildId,
      commandId: commandId,
      body: GuildCommandUpdateRequestSchema(
        name: name,
        description: JsonNullable<String>.of(description),
        template: template,
        inputMode: inputMode,
        inputHint: _hint(hint),
        counters: counters,
      ),
    );
  }

  /// Fills in a script without posting it. A script with a problem comes back
  /// as an answer, not a failed request.
  Future<GuildCommandPreviewResponseSchema> preview({
    required String guildId,
    required String template,
    required String input,
    required String? channelId,
    required List<String> counterNames,
    required int run,
  }) {
    return _client.guildCommands.previewGuildCommand(
      guildId: guildId,
      body: GuildCommandPreviewRequestSchema(
        template: template,
        input: input.isEmpty
            ? const JsonNullable<String>.undefined()
            : JsonNullable<String>.of(input),
        channelId: channelId == null
            ? const JsonNullable<SnowflakeType>.undefined()
            : JsonNullable<SnowflakeType>.of(channelId),
        counters: <GuildCommandCounterInputSchema>[
          for (final String name in counterNames)
            GuildCommandCounterInputSchema(
              name: name,
              per: const <GuildCommandCounterPart>[],
            ),
        ],
        run: counterNames.isEmpty ? null : run,
      ),
    );
  }

  /// Deletes all of a counter's counts.
  Future<void> resetCounter({
    required String guildId,
    required String commandId,
    required String counterId,
  }) {
    return _client.guildCommands.resetGuildCommandCounter(
      guildId: guildId,
      commandId: commandId,
      counterId: counterId,
    );
  }

  Future<void> delete({required String guildId, required String commandId}) {
    return _client.guildCommands.deleteGuildCommand(
      guildId: guildId,
      commandId: commandId,
    );
  }

  JsonNullable<String> _hint(String hint) =>
      JsonNullable<String>.of(hint.isEmpty ? null : hint);

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
