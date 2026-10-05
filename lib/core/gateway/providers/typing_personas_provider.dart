// Fork: the persona each user is typing as (tyne-chat/tyne#136), kept out of
// upstream's TypingIndicators so that class stays as upstream has it.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/gateway/providers/gateway_event_providers.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_dart/models/message_subprofile_response_schema.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'typing_personas_provider.g.dart';

/// Who each user is typing as, per channel: the `subprofile` of their last
/// typing event. A user typing as the account has no entry.
///
/// Upstream's [TypingIndicators] decides who is typing and when that ends;
/// this only names the persona. Read it through
/// [channelTypingSubprofileProvider], which shows an entry only while
/// [TypingIndicators] still has the user typing. The map starts empty for each
/// signed-in user.
@Riverpod(keepAlive: true)
class TypingPersonas extends _$TypingPersonas {
  @override
  Map<String, Map<String, MessageSubprofileResponseSchema>> build() {
    ref.watch(currentUserIdProvider);
    return const <String, Map<String, MessageSubprofileResponseSchema>>{};
  }

  /// Records who [userId] is typing as in [channelId]: [subprofile], or the
  /// account when it is null. Entries of users who are no longer typing are
  /// dropped on the way, so the map holds only current typers.
  void record(
    String channelId,
    String userId,
    MessageSubprofileResponseSchema? subprofile,
  ) {
    final Map<String, Map<String, DateTime>> typing = ref.read(
      typingIndicatorsProvider,
    );
    final Map<String, Map<String, MessageSubprofileResponseSchema>> next =
        <String, Map<String, MessageSubprofileResponseSchema>>{};
    state.forEach((
      String entryChannelId,
      Map<String, MessageSubprofileResponseSchema> entries,
    ) {
      final Map<String, DateTime>? typers = typing[entryChannelId];
      final Map<String, MessageSubprofileResponseSchema> kept =
          <String, MessageSubprofileResponseSchema>{
            for (final MapEntry<String, MessageSubprofileResponseSchema> entry
                in entries.entries)
              if (typers?.containsKey(entry.key) ?? false)
                entry.key: entry.value,
          };
      if (kept.isNotEmpty) {
        next[entryChannelId] = kept;
      }
    });
    if (subprofile != null) {
      (next[channelId] ??=
              <String, MessageSubprofileResponseSchema>{})[userId] =
          subprofile;
    } else {
      next[channelId]?.remove(userId);
      if (next[channelId]?.isEmpty ?? false) {
        next.remove(channelId);
      }
    }
    state = next;
  }
}

/// The persona a user is typing as in a channel, while they are typing; null
/// when they type as the account or are not typing.
// Riverpod's family type cannot be written out here; the right-hand side states it.
// ignore: specify_nonobvious_property_types
final channelTypingSubprofileProvider = Provider.autoDispose
    .family<
      MessageSubprofileResponseSchema?,
      (String channelId, String userId)
    >((Ref ref, (String channelId, String userId) args) {
      final bool isTyping = ref.watch(
        typingIndicatorsProvider.select(
          (Map<String, Map<String, DateTime>> typing) =>
              typing[args.$1]?.containsKey(args.$2) ?? false,
        ),
      );
      if (!isTyping) {
        return null;
      }
      return ref.watch(
        typingPersonasProvider.select(
          (
            Map<String, Map<String, MessageSubprofileResponseSchema>> personas,
          ) => personas[args.$1]?[args.$2],
        ),
      );
    });
