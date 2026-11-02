import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/guilds/utils/guild_features.dart';
import 'package:fluxer_app/features/settings/data/guild_settings_repository.dart';
import 'package:fluxer_app/features/settings/providers/guild/guild_emoji_settings_provider.dart';
import 'package:fluxer_app/features/settings/providers/guild/guild_settings_repository_provider.dart';
import 'package:fluxer_app/features/settings/providers/guild/guild_sticker_settings_provider.dart';
import 'package:fluxer_dart/export.dart';

const String _guildId = 'g1';

class _Settings implements GuildSettingsRepository {
  List<String>? sent;

  @override
  Future<GuildResponse> updateGuild({
    required String guildId,
    required GuildUpdateRequest body,
  }) {
    sent = body.features;
    return Future<GuildResponse>.error(_Sent());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The request is all these tests look at.
class _Sent implements Exception {}

void main() {
  group('reading the flags (tyne-chat/tyne#452)', () {
    test('a community is opted out unless it has the flag', () {
      expect(isCloneEmojiAllowed(const <String>[]), isFalse);
      expect(isCloneStickerAllowed(const <String>[]), isFalse);
    });

    test('the opt-in flags turn cloning on', () {
      expect(isCloneEmojiAllowed(const ['CLONE_EMOJI_ENABLED']), isTrue);
      expect(isCloneStickerAllowed(const ['CLONE_STICKER_ENABLED']), isTrue);
    });

    test('the retired flags mean nothing', () {
      expect(isCloneEmojiAllowed(const ['CLONE_EMOJI_DISABLED']), isFalse);
      expect(isCloneStickerAllowed(const ['CLONE_STICKER_DISABLED']), isFalse);
    });
  });

  group('writing the flags', () {
    ({ProviderContainer container, _Settings settings}) setUpContainer() {
      final _Settings settings = _Settings();
      final ProviderContainer container = ProviderContainer(
        overrides: [
          guildSettingsRepositoryProvider.overrideWithValue(settings),
        ],
      );
      addTearDown(container.dispose);
      return (container: container, settings: settings);
    }

    test('switching emoji cloning on sends the opt-in flag', () async {
      final setup = setUpContainer();

      await expectLater(
        setup.container
            .read(guildEmojiSettingsProvider(_guildId).notifier)
            .toggleCloneAllowed(currentFeatures: const [], allowed: true),
        throwsA(isA<_Sent>()),
      );

      expect(setup.settings.sent, contains('CLONE_EMOJI_ENABLED'));
      expect(setup.settings.sent, isNot(contains('CLONE_EMOJI_DISABLED')));
    });

    test('switching sticker cloning off removes the opt-in flag', () async {
      final setup = setUpContainer();

      await expectLater(
        setup.container
            .read(guildStickerSettingsProvider(_guildId).notifier)
            .toggleCloneAllowed(
              currentFeatures: const ['CLONE_STICKER_ENABLED'],
              allowed: false,
            ),
        throwsA(isA<_Sent>()),
      );

      expect(setup.settings.sent, isNot(contains('CLONE_STICKER_ENABLED')));
      expect(setup.settings.sent, isNot(contains('CLONE_STICKER_DISABLED')));
    });
  });
}
