// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: fakes shared by the tests of the persona reaction sheets and of the
// reaction chip that opens them (tyne-chat/tyne#86).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/providers/multi_persona_reactions_provider.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/features/settings/providers/view_models/user_settings_view_model.dart';

const String kReactionTestChannelId = 'chan_1';
const String kReactionTestMessageId = 'msg_1';

class FakeReactionUserSettings extends UserSettingsViewModel {
  @override
  UserSettingsViewState build() => const UserSettingsViewState(
    userId: 'root_user',
    username: 'tester',
    displayName: 'Root User',
    discriminator: '0001',
    avatar: null,
    avatarColor: null,
    memberSince: null,
    status: 'online',
    messageDisplayCompact: false,
    developerMode: false,
    trustedDomains: <String>[],
  );
}

/// The account's personas, already loaded. Counts how often something first
/// asked for them, and the reloads asked of it.
class FakeMyPersonas extends MyPersonasNotifier {
  FakeMyPersonas(this._personas);

  final List<Persona> _personas;
  int builds = 0;
  int reloads = 0;

  @override
  AsyncValue<List<Persona>> build() {
    builds++;
    return AsyncData<List<Persona>>(_personas);
  }

  @override
  Future<void> reloadSilently() async {
    reloads++;
  }
}

/// "React as several personas at once" with a fixed value and no device store.
class FixedMultiPersonaReactions extends MultiPersonaReactionsNotifier {
  FixedMultiPersonaReactions({required this.enabled});

  final bool enabled;

  @override
  bool build() => enabled;
}

/// The selection and the use counts of this device, fixed.
class FixedActivePersona extends ActivePersonaNotifier {
  FixedActivePersona(this._state);

  final ActivePersonaState _state;

  @override
  ActivePersonaState build() => _state;
}

typedef ReactionToggle = ({String emoji, String? personaId, bool explicitRoot});

/// A chat view model with one message. It records what the sheets ask of it
/// and applies a toggle to its state as the real one does at once, so the
/// widgets under test see the reaction change.
class FakeReactionChatViewModel extends ChatViewModel {
  FakeReactionChatViewModel({required this.reactions, this.currentId});

  final List<Reaction> reactions;

  /// What a plain reaction would be sent as: a persona's id, or null for the
  /// account.
  final String? currentId;

  final List<ReactionToggle> toggles = <ReactionToggle>[];
  final List<({String emoji, String? personaId})> onlyChoices =
      <({String emoji, String? personaId})>[];

  @override
  ChatViewState build() => ChatViewState(
    channelId: kReactionTestChannelId,
    messages: <Message>[
      Message(
        id: kReactionTestMessageId,
        channelId: kReactionTestChannelId,
        authorId: 'other_user',
        authorName: 'other',
        content: 'Hello World',
        timestamp: DateTime(2026, 11, 9),
        reactions: reactions,
      ),
    ],
    replyingTo: null,
    replyMentioning: false,
    editingMessage: null,
    messageText: '',
    scrollToBottomSignal: 0,
    isLoading: false,
    isSyncingMessages: false,
    isLoadingMore: false,
    isLoadingNewer: false,
    hasMoreMessages: false,
    hasMoreNewerMessages: false,
    errorMessage: null,
  );

  Reaction? reactionFor(String emoji) {
    for (final Reaction reaction in state.messages.single.reactions) {
      if (reaction.emoji == emoji) {
        return reaction;
      }
    }
    return null;
  }

  @override
  String? resolveEffectiveReactionPersona({
    required String emoji,
    String? emojiId,
  }) => currentId;

  @override
  Future<void> toggleReaction(
    String messageId,
    String emoji, {
    String? emojiId,
    bool animated = false,
    String? personaId,
    bool explicitRoot = false,
  }) async {
    toggles.add((
      emoji: emoji,
      personaId: personaId,
      explicitRoot: explicitRoot,
    ));
    final String? id = explicitRoot ? null : personaId ?? currentId;
    final Message message = state.messages.single;
    final Reaction? old = reactionFor(emoji);
    final bool had = old?.hasPersonaReacted(id) ?? false;
    final bool meRoot = id == null ? !had : old?.meRoot ?? false;
    final List<String> personaReactions = <String>[
      ...?old?.personaReactions.where((String other) => other != id),
      if (id != null && !had) id,
    ];
    final int count = (old?.count ?? 0) + (had ? -1 : 1);
    final Reaction? next = count <= 0
        ? null
        : Reaction(
            emoji: emoji,
            emojiId: emojiId,
            animated: animated,
            count: count,
            hasReacted: meRoot || personaReactions.isNotEmpty,
            meRoot: meRoot,
            personaReactions: personaReactions,
          );
    state = state.copyWith(
      write: (
        messages: <Message>[
          message.copyWith(
            reactions: <Reaction>[
              for (final Reaction reaction in message.reactions)
                if (reaction.emoji != emoji) reaction else ?next,
              if (old == null) ?next,
            ],
          ),
        ],
        origin: MessagesOrigin.localMutation,
      ),
    );
  }

  @override
  Future<void> reactAsOnly(
    String messageId,
    String emoji, {
    required String? personaId,
    String? emojiId,
    bool animated = false,
  }) async {
    onlyChoices.add((emoji: emoji, personaId: personaId));
  }
}
