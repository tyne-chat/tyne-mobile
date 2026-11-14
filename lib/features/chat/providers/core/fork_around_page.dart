// Fork: tyne-chat/tyne#199. A jump inside the open channel (a notification
// tapped while its channel is open, the jump to the first unread message, a
// reply preview) loads the page around its target. The server fills that page
// with up to half the limit of newer messages, the target, and older ones up
// to the limit, and does not make up for a short side on the other
// (`visible_around` in the server's fluxer_messages). Upstream read a page
// shorter than the limit as the start of the channel, so a jump to a message
// with few newer ones, such as the newest, showed the start-of-channel header
// 24 messages above it and stopped loading older history.
import 'package:fluxer_app/features/channels/data/read_state_utils.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';

/// Whether messages older than [page] may exist, for a page loaded around
/// [targetId] with [limit]: only when its older side is full. A shorter older
/// side is the start of the channel. Upstream's web app decides the same way
/// (`calculateAroundPaginationState`), and `aroundPageReachesLiveTail` is the
/// same rule for the newer side.
bool forkAroundPageHasOlder(
  List<Message> page, {
  required String targetId,
  required int limit,
}) {
  final int olderLimit = limit - 1 - limit ~/ 2;
  int older = 0;
  for (final Message message in page) {
    if (compareSnowflakeIds(message.id, targetId) < 0) {
      older++;
    }
  }
  return olderLimit > 0 && older >= olderLimit;
}
