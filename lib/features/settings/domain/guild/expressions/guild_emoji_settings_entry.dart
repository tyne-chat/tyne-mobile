import 'package:fluxer_app/features/settings/domain/guild/expressions/guild_expression_uploader.dart';
import 'package:fluxer_dart/export.dart';

// Fork imports.
// ignore: directives_ordering
import 'package:fluxer_app/shared/utils/emoji/fork_custom_emoji_name_order.dart';

class GuildEmojiSettingsEntry {
  const GuildEmojiSettingsEntry({
    required this.id,
    required this.name,
    required this.animated,
    required this.uploader,
  });

  final String id;
  final String name;
  final bool animated;
  final GuildExpressionUploader uploader;

  factory GuildEmojiSettingsEntry.fromResponse(
    GuildEmojiWithUserResponse response,
  ) {
    return GuildEmojiSettingsEntry(
      id: response.id,
      name: response.name,
      animated: response.animated,
      uploader: GuildExpressionUploader.fromResponse(response.user),
    );
  }
}

int compareGuildEmojiSettingsEntriesByName(
  GuildEmojiSettingsEntry left,
  GuildEmojiSettingsEntry right,
) => compareCustomEmojiNames(left.name, left.id, right.name, right.id);
