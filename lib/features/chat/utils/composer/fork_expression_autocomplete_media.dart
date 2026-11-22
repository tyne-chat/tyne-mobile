// Fork: stickers and saved media in the `:` expression autocomplete
// (tyne-chat/tyne#777). The settings "Show stickers" and "Show saved media in
// expression autocomplete" were stored but nothing read them; the web app lists
// both after the emojis (`buildEmojiAutocompleteOptions`), five of each at most.
//
// Picking one sends it at once and empties the composer, so they are offered
// only while the composer holds nothing but the `:query`, or the query and a
// persona's proxy tag (or an escape) that the send uses up: the phone's
// counterpart of the web's `isDraftUsedUpByExpression` (tyne-chat/tyne#122,
// tyne-chat/tyne#770). Any other text would be lost, so then they are not
// listed. Everything here reads data the app already holds; nothing is fetched.
import 'package:fluxer_app/features/chat/domain/favorite_meme.dart';
import 'package:fluxer_app/features/chat/providers/pickers/sticker_picker_provider.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/domain/persona_matcher.dart';

/// How many stickers, and how many saved media, the `:` list shows at most
/// (as the web app).
const int kForkExpressionMediaLimit = 5;

/// Whether the composer's [text] holds nothing that picking a sticker or saved
/// media from the `:` list would lose: outside the query between [matchStart]
/// and [matchEnd], only whitespace, or a persona tag or escape that leaves
/// nothing to send, as `resolveOutgoingPersona` reads it.
bool forkExpressionMediaDraftIsFree({
  required String text,
  required int matchStart,
  required int matchEnd,
  required List<Persona> personas,
  required String? latchedPersonaId,
}) {
  final int start = matchStart.clamp(0, text.length);
  final int end = matchEnd.clamp(start, text.length);
  final String rest = text.substring(0, start) + text.substring(end);
  if (rest.trim().isEmpty) {
    return true;
  }
  final MatchResult match = matchPersona(
    rest,
    personas,
    latchedPersonaId,
    hasAttachments: false,
    allowEmptyContent: true,
  );
  final String outgoing = match.matched || match.wasEscaped
      ? match.strippedContent
      : rest;
  return outgoing.trim().isEmpty;
}

/// The stickers the `:` list offers for [query], from the stickers that can be
/// used here ([available]): those whose name, description or a tag contains
/// it, the recently used ones ([frecent]) first, then the active community's,
/// at most [limit].
List<StickerEntry> forkExpressionStickerMatches({
  required String query,
  required List<StickerEntry> available,
  required List<StickerEntry> frecent,
  required String? activeGuildId,
  int limit = kForkExpressionMediaLimit,
}) {
  if (query.trim().isEmpty) {
    return const <StickerEntry>[];
  }
  final List<StickerEntry> matches = searchStickerEntries(available, query);
  final Set<String> matchIds = <String>{
    for (final StickerEntry s in matches) s.id,
  };
  final List<StickerEntry> ordered = <StickerEntry>[
    for (final StickerEntry s in frecent)
      if (matchIds.contains(s.id)) s,
    for (final StickerEntry s in matches)
      if (s.guildId == activeGuildId) s,
    ...matches,
  ];
  final Set<String> seen = <String>{};
  final List<StickerEntry> results = <StickerEntry>[];
  for (final StickerEntry s in ordered) {
    if (!seen.add(s.id)) {
      continue;
    }
    results.add(s);
    if (results.length >= limit) {
      break;
    }
  }
  return results;
}

/// The saved media the `:` list offers for [query]: those whose name, alt
/// text, file name or a tag contains it, in the order of [memes] (newest
/// first), at most [limit].
List<FavoriteMeme> forkExpressionMemeMatches({
  required String query,
  required List<FavoriteMeme> memes,
  int limit = kForkExpressionMediaLimit,
}) {
  final String q = query.trim().toLowerCase();
  if (q.isEmpty) {
    return const <FavoriteMeme>[];
  }
  bool matches(FavoriteMeme m) =>
      m.name.toLowerCase().contains(q) ||
      (m.altText?.toLowerCase().contains(q) ?? false) ||
      m.filename.toLowerCase().contains(q) ||
      m.tags.any((String t) => t.toLowerCase().contains(q));
  return memes.where(matches).take(limit).toList(growable: false);
}
