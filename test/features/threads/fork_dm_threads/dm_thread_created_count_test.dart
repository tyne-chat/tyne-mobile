// Fork: a thread's red count on its "started a thread" notice
// (tyne-chat/tyne#699). A thread started from the + menu has no chip, so the
// notice carries the count instead.

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/utils/messages/system_message_text.dart';
import 'package:fluxer_app/features/threads/fork_dm_threads/dm_thread_widgets.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_dart/export.dart';

import '../../../helpers/test_l10n.dart';

Message _message({required int type, MessageReference? reference}) => Message(
  id: '10',
  channelId: '2',
  authorId: '1',
  authorName: 'Fox Mom',
  content: 'new thread',
  timestamp: DateTime.utc(2026, 11, 17),
  type: type,
  messageReference: reference,
);

List<InlineSpan> _upstreamSpans(Message message) => buildSystemMessageTextSpans(
  l10n: testL10n,
  message: message,
  authorName: message.authorName,
  textStyle: const TextStyle(),
  usernameStyle: const TextStyle(),
);

void main() {
  test("ends a thread's notice with its count, after upstream's text", () {
    final Message notice = _message(
      type: messageTypeThreadCreated,
      reference: const MessageReference(
        channelId: '30',
        messageId: null,
        type: MessageReferenceType.valueDefault,
      ),
    );
    final List<InlineSpan> spans = _upstreamSpans(notice);
    final int before = spans.length;
    forkAddThreadCreatedCount(spans, notice);
    expect(spans, hasLength(before + 1));
    final Widget child = (spans.last as WidgetSpan).child;
    expect(child, isA<ForkThreadChipCount>());
    expect((child as ForkThreadChipCount).threadId, '30');
  });

  test('leaves other notices, and one without its thread, as they are', () {
    final Message pinned = _message(type: messageTypeChannelPinnedMessage);
    final List<InlineSpan> pinnedSpans = _upstreamSpans(pinned);
    final int pinnedLength = pinnedSpans.length;
    forkAddThreadCreatedCount(pinnedSpans, pinned);
    expect(pinnedSpans, hasLength(pinnedLength));
    final Message orphan = _message(type: messageTypeThreadCreated);
    final List<InlineSpan> orphanSpans = _upstreamSpans(orphan);
    final int orphanLength = orphanSpans.length;
    forkAddThreadCreatedCount(orphanSpans, orphan);
    expect(orphanSpans, hasLength(orphanLength));
  });
}
