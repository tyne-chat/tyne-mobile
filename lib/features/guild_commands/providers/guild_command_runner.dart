import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/api/api_exception.dart';
import 'package:fluxer_app/core/permissions/channel_permission_cache_provider.dart';
import 'package:fluxer_app/features/chat/utils/messages/client_nonce.dart';
import 'package:fluxer_app/features/guild_commands/data/guild_commands_repository.dart';
import 'package:fluxer_app/features/guild_commands/providers/guild_commands_providers.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_dart/export.dart';

/// What the composer does after a send was offered to [GuildCommandRunner].
sealed class GuildCommandRunResult {
  const GuildCommandRunResult();
}

/// Not a command: the composer sends the text as usual.
final class GuildCommandNotACommand extends GuildCommandRunResult {
  const GuildCommandNotACommand();
}

/// A run for this channel is still out, so this press does nothing.
final class GuildCommandIgnored extends GuildCommandRunResult {
  const GuildCommandIgnored();
}

/// Posted. The message arrives through the gateway, as any other message does.
final class GuildCommandPosted extends GuildCommandRunResult {
  const GuildCommandPosted();
}

/// Input may not span lines: the server refuses it.
final class GuildCommandNeedsOneLine extends GuildCommandRunResult {
  const GuildCommandNeedsOneLine(this.name);

  final String name;
}

final class GuildCommandFailed extends GuildCommandRunResult {
  const GuildCommandFailed(this.name, {required this.broken, this.detail});

  final String name;

  /// The command's own script has a problem.
  final bool broken;

  /// The server's message, already in the user's language.
  final String? detail;
}

final RegExp _commandText = RegExp(r'^/([a-z0-9_-]{1,32})(?:\s+([\s\S]*))?$');

/// A retry of the same text in this time keeps its nonce, so it cannot post twice.
const Duration _nonceLifetime = Duration(minutes: 2);

/// Fork: runs `/name input` when the composer sends
/// (the server repository's docs/design/server-commands.md, "The composer").
class GuildCommandRunner {
  GuildCommandRunner(this._ref);

  final Ref _ref;
  final Set<String> _inFlight = <String>{};
  final Map<String, ({String text, String nonce, DateTime at})> _attempts =
      <String, ({String text, String nonce, DateTime at})>{};

  String _nonceFor(String channelId, String text) {
    final DateTime now = _ref.read(guildCommandsClockProvider)();
    final ({String text, String nonce, DateTime at})? attempt =
        _attempts[channelId];
    if (attempt != null &&
        attempt.text == text &&
        now.difference(attempt.at) < _nonceLifetime) {
      return attempt.nonce;
    }
    final String nonce = clientNonceGenerator.next();
    _attempts[channelId] = (text: text, nonce: nonce, at: now);
    return nonce;
  }

  /// [resolveEmoji] turns typed `:name:` into custom emoji, as a normal send does.
  Future<GuildCommandRunResult> run({
    required String channelId,
    required String? channelGuildId,
    required String wireText,
    required String Function(String text) resolveEmoji,
  }) async {
    final RegExpMatch? match = _commandText.firstMatch(wireText.trim());
    if (match == null) {
      return const GuildCommandNotACommand();
    }
    final String name = match.group(1)!;
    final GuildCommandsNotifier commands = _ref.read(
      guildCommandsProvider.notifier,
    );
    // The list may not have loaded yet: `/tuck @Yami` must not go out as text.
    await commands.ensureLoaded();
    final GuildCommandResponseSchema? command = commands.resolve(
      name,
      channelGuildId: channelGuildId,
      channelPermissionBits:
          _ref.read(channelPermissionCacheProvider)[channelId] ?? 0,
    );
    if (command == null) {
      return const GuildCommandNotACommand();
    }
    final String input = resolveEmoji(match.group(2) ?? '').trim();
    if (input.contains('\n') || input.contains('\r')) {
      return GuildCommandNeedsOneLine(name);
    }
    if (!_inFlight.add(channelId)) {
      return const GuildCommandIgnored();
    }
    try {
      await _ref
          .read(guildCommandsRepositoryProvider)
          .run(
            channelId: channelId,
            commandId: command.id,
            input: input,
            personaId: _ref.read(activePersonaProvider).latchedIdFor(channelId),
            nonce: _nonceFor(channelId, wireText),
          );
      _attempts.remove(channelId);
      return const GuildCommandPosted();
    } on Exception catch (error) {
      debugPrint('[GuildCommands] Failed to run /$name: $error');
      final ApiException api = ApiException.from(error);
      // The command is gone, or the user left its community.
      if (api.code == 'UNKNOWN_GUILD_COMMAND') {
        commands.markStale(command.guildId);
      }
      return GuildCommandFailed(
        name,
        broken: api.code == 'GUILD_COMMAND_TEMPLATE_INVALID',
        detail: api.message,
      );
    } finally {
      _inFlight.remove(channelId);
    }
  }
}

final Provider<GuildCommandRunner> guildCommandRunnerProvider =
    Provider<GuildCommandRunner>(GuildCommandRunner.new);
