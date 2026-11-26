// Fork: tyne-chat/tyne#940. Tracks local reaction mutations across concurrent
// page fetches (`toggleReaction`, `_forkRemoveOwnReactions`, and
// `removeAllReactionsOnMessage`), mirroring upstream's `_localMutations` for
// deletes/edits/attachments. Because guild sessions exclude themselves from
// `MESSAGE_REACTION_ADD`/`REMOVE` echoes, an overlapping `GET /messages` that
// read pre-mutation state would otherwise wipe out both UI state and Drift.
import 'dart:convert';

import 'package:fluxer_app/core/database/daos/message_dao.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/utils/reactions/own_reactions.dart';

enum ForkReactionMutationKind { toggle, clearAll }

class ForkPendingReactionOp {
  ForkPendingReactionOp({
    required this.kind,
    required this.startOrdinal,
    this.emoji = '',
    this.emojiId,
    this.animated = false,
    this.isAdd = false,
    this.personaId,
  });

  final ForkReactionMutationKind kind;
  final int startOrdinal;
  final String emoji;
  final String? emojiId;
  final bool animated;
  final bool isAdd;
  final String? personaId;

  int? ackOrdinal;

  bool appliesToFetch(int fetchOrdinal) =>
      ackOrdinal == null || fetchOrdinal < ackOrdinal!;
}

class ForkPendingReactionMutations {
  final Map<String, List<ForkPendingReactionOp>> _opsByMessage =
      <String, List<ForkPendingReactionOp>>{};

  bool get isEmpty => _opsByMessage.isEmpty;

  bool get isNotEmpty => _opsByMessage.isNotEmpty;

  int get count => _opsByMessage.values.fold<int>(
    0,
    (int sum, List<ForkPendingReactionOp> ops) => sum + ops.length,
  );

  void clear() => _opsByMessage.clear();

  int recordToggle(
    String messageId, {
    required int startOrdinal,
    required String emoji,
    required bool isAdd,
    required String? personaId,
    String? emojiId,
    bool animated = false,
  }) {
    _opsByMessage
        .putIfAbsent(messageId, () => <ForkPendingReactionOp>[])
        .add(
          ForkPendingReactionOp(
            kind: ForkReactionMutationKind.toggle,
            startOrdinal: startOrdinal,
            emoji: emoji,
            emojiId: emojiId,
            animated: animated,
            isAdd: isAdd,
            personaId: personaId,
          ),
        );
    return startOrdinal;
  }

  int recordClearAll(String messageId, {required int startOrdinal}) {
    _opsByMessage
        .putIfAbsent(messageId, () => <ForkPendingReactionOp>[])
        .add(
          ForkPendingReactionOp(
            kind: ForkReactionMutationKind.clearAll,
            startOrdinal: startOrdinal,
          ),
        );
    return startOrdinal;
  }

  void acknowledge(
    String messageId,
    int startOrdinal, {
    required int ackOrdinal,
  }) {
    final List<ForkPendingReactionOp>? ops = _opsByMessage[messageId];
    if (ops == null) {
      return;
    }
    for (final ForkPendingReactionOp op in ops) {
      if (op.startOrdinal == startOrdinal) {
        op.ackOrdinal = ackOrdinal;
        return;
      }
    }
  }

  void withdraw(String messageId, int startOrdinal) {
    final List<ForkPendingReactionOp>? ops = _opsByMessage[messageId];
    if (ops == null) {
      return;
    }
    ops.removeWhere(
      (ForkPendingReactionOp op) => op.startOrdinal == startOrdinal,
    );
    if (ops.isEmpty) {
      _opsByMessage.remove(messageId);
    }
  }

  void retire({required int? oldestOutstanding}) {
    if (_opsByMessage.isEmpty) {
      return;
    }
    _opsByMessage.removeWhere((_, List<ForkPendingReactionOp> ops) {
      ops.removeWhere((ForkPendingReactionOp op) {
        final int? ack = op.ackOrdinal;
        if (ack == null) {
          return false;
        }
        return oldestOutstanding == null || oldestOutstanding >= ack;
      });
      return ops.isEmpty;
    });
  }

  List<Message> apply(List<Message> messages, {required int fetchOrdinal}) {
    if (_opsByMessage.isEmpty) {
      return messages;
    }
    List<Message>? updated;
    for (int i = 0; i < messages.length; i++) {
      final Message message = messages[i];
      final List<ForkPendingReactionOp>? ops = _opsByMessage[message.id];
      if (ops == null || ops.isEmpty) {
        continue;
      }
      final List<Reaction> nextReactions = forkApplyReactionOps(
        message.reactions,
        ops,
        fetchOrdinal: fetchOrdinal,
      );
      if (!identical(nextReactions, message.reactions)) {
        updated ??= List<Message>.of(messages);
        updated[i] = message.copyWith(reactions: nextReactions);
      }
    }
    return updated ?? messages;
  }

  /// Re-applies active reaction overlays onto [pageMessages] (which a network
  /// page fetch has just written raw to Drift) and repairs `reactions_json` in
  /// [dao] for any affected message before retiring [fetchOrdinal].
  Future<void> syncOverlaidToDatabase({
    required MessageDao dao,
    required String channelId,
    required List<Message> pageMessages,
    required int fetchOrdinal,
  }) async {
    if (_opsByMessage.isEmpty) {
      return;
    }
    for (final Message message in pageMessages) {
      final List<ForkPendingReactionOp>? ops = _opsByMessage[message.id];
      if (ops == null ||
          !ops.any(
            (ForkPendingReactionOp op) => op.appliesToFetch(fetchOrdinal),
          )) {
        continue;
      }
      final List<Reaction> overlaid = forkApplyReactionOps(
        message.reactions,
        ops,
        fetchOrdinal: fetchOrdinal,
      );
      await dao.updateReactions(
        channelId,
        message.id,
        jsonEncode(overlaid.map((Reaction r) => r.toJson()).toList()),
      );
    }
  }
}

List<Reaction> forkApplyReactionOps(
  List<Reaction> base,
  List<ForkPendingReactionOp> ops, {
  required int fetchOrdinal,
}) {
  List<Reaction> current = base;
  var changed = false;
  for (final ForkPendingReactionOp op in ops) {
    if (!op.appliesToFetch(fetchOrdinal)) {
      continue;
    }
    switch (op.kind) {
      case ForkReactionMutationKind.clearAll:
        if (current.isNotEmpty) {
          current = const <Reaction>[];
          changed = true;
        }
      case ForkReactionMutationKind.toggle:
        final List<Reaction> next = op.isAdd
            ? _withOwnReaction(
                current,
                emoji: op.emoji,
                emojiId: op.emojiId,
                animated: op.animated,
                personaId: op.personaId,
              )
            : withoutOwnReactions(
                current,
                emoji: op.emoji,
                emojiId: op.emojiId,
                ids: <String?>[op.personaId],
              );
        current = next;
        changed = true;
    }
  }
  return changed ? current : base;
}

List<Reaction> _withOwnReaction(
  List<Reaction> reactions, {
  required String emoji,
  required String? emojiId,
  required bool animated,
  required String? personaId,
}) {
  final int existingIdx = reactions.indexWhere(
    (Reaction r) => r.emoji == emoji && r.emojiId == emojiId,
  );
  final bool isRoot = personaId == null || personaId == '0';
  if (existingIdx != -1) {
    final Reaction old = reactions[existingIdx];
    if (old.hasPersonaReacted(personaId)) {
      return reactions;
    }
    final List<String> updatedPersonas = List<String>.from(
      old.personaReactions,
    );
    if (!isRoot && !updatedPersonas.contains(personaId)) {
      updatedPersonas.add(personaId);
    }
    final bool newMeRoot = isRoot || old.meRoot;
    final List<Reaction> updated = List<Reaction>.from(reactions);
    updated[existingIdx] = Reaction(
      emoji: emoji,
      emojiId: emojiId,
      animated: animated,
      count: old.count + 1,
      hasReacted: true,
      meRoot: newMeRoot,
      personaReactions: updatedPersonas,
    );
    return updated;
  }
  return <Reaction>[
    ...reactions,
    Reaction(
      emoji: emoji,
      emojiId: emojiId,
      animated: animated,
      count: 1,
      hasReacted: true,
      meRoot: isRoot,
      personaReactions: !isRoot ? <String>[personaId] : const <String>[],
    ),
  ];
}
