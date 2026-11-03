// Fork: stores each read mark (ack) as soon as it is queued, as before upstream's 70fc7129e
// (tyne-chat/tyne#466).
//
// Since that commit, ReadStateWriteBatcher.enqueueAck keeps an ack in memory until flushAll (app sent
// to the background, gateway lost). Several screens read read_states straight from the database: the
// unread DM list, the chat's NEW divider, the quick switcher. Without this, the database catches up
// only when the server answers the ack, about three seconds later, and never for the user's own
// messages, which the server acks without a MESSAGE_ACK. So those screens showed read messages, and
// the user's own, as unread.
//
// Each ack is written at the end of the current event. That is before the message write batcher
// moves the channel's last message, so an unread state never shows in between. Upstream's tests build
// a plain ReadStateWriteBatcher and keep its behaviour. Remove this when upstream stores acks promptly
// or makes those screens read the in-memory cursor.
import 'dart:async';

import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_app/features/channels/data/read_state_write_batcher.dart';

class ForkReadStateWriteBatcher extends ReadStateWriteBatcher {
  ForkReadStateWriteBatcher({required super.database, super.onOverlayChanged});

  final Set<String> _queued = <String>{};
  bool _scheduled = false;
  bool _stopped = false;

  @override
  void enqueueAck({
    required String channelId,
    required String messageId,
    required bool clearSticky,
  }) {
    super.enqueueAck(
      channelId: channelId,
      messageId: messageId,
      clearSticky: clearSticky,
    );
    if (_stopped || channelId.isEmpty) {
      return;
    }
    _queued.add(channelId);
    if (_scheduled) {
      return;
    }
    _scheduled = true;
    scheduleMicrotask(() => unawaited(_writeQueued()));
  }

  // Only a new ack schedules a write. A failed write keeps its ack pending for the next one or for
  // upstream's flushAll, and is never retried in a loop.
  Future<void> _writeQueued() async {
    _scheduled = false;
    final List<String> channelIds = _queued.toList();
    _queued.clear();
    for (final String channelId in channelIds) {
      if (_stopped || !hasOverlay(channelId)) {
        continue;
      }
      try {
        // An unseeded cursor (Mark as read, the Escape key) would be written without the stored
        // row's pin timestamp, version and flags, and could replace a newer stored ack.
        if (peekCursor(channelId) == null) {
          await ensureCursor(channelId);
        }
        await flushAck(channelId);
      } on Object catch (e, st) {
        talker.error(
          '[ForkReadStateWriteBatcher] ack write failed for $channelId',
          e,
          st,
        );
      }
    }
  }

  @override
  Future<void> dispose() {
    _stopped = true;
    _queued.clear();
    return super.dispose();
  }
}
