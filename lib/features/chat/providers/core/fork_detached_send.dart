// Fork: tyne-chat/tyne#212. A message list that does not reach the newest
// messages holds loaded history only. A message the user sends from it joins
// it only when the send moves the list to the newest messages ("Scroll to
// bottom when sending a message"), and a delivered send leaves it.
//
// Otherwise the delivered message becomes the list's last message. The next
// newer page then asks for messages after it, gets none, and the list counts
// as reaching the newest messages with the ones in between never loaded. The
// delivered message loads in its place with the newer pages instead.
// Upstream's web app keeps sends out of such a list too
// (`ignorePastVisibleWindow` in ChannelIncomingMessageStateMachine.ts).
import 'package:fluxer_app/features/chat/domain/message.dart';

/// The list once the user's [sent] messages are shown in it.
List<Message> forkMessagesWithOwnSend(
  List<Message> messages,
  List<Message> sent, {
  required bool hasMoreNewerMessages,
  required bool movesToNewest,
}) {
  if (hasMoreNewerMessages && !movesToNewest) {
    return messages;
  }
  return <Message>[...messages, ...sent];
}

/// The list once the send shown as [localId] is delivered, if the list does
/// not reach the newest messages and is not on its way there: without the
/// send's row. Null otherwise, and the delivered message replaces the row.
List<Message>? forkMessagesAfterDetachedDelivery(
  List<Message> messages,
  String localId, {
  required bool hasMoreNewerMessages,
  required bool jumpingToNewest,
}) {
  if (!hasMoreNewerMessages || jumpingToNewest) {
    return null;
  }
  return <Message>[
    for (final Message message in messages)
      if (message.id != localId) message,
  ];
}
