part of 'message_list.dart';

// Fork: tyne-chat/tyne#633. The list holds at most kMaxLoadedMessagesHard
// messages; at that size the chat loads no further page. Upstream makes room
// when a scroll comes to rest, or after a while without one, by keeping the
// messages around the rows that are laid out. A reader who scrolls faster
// than pages arrive ends on the skeleton beyond the loaded messages, where no
// row is laid out: upstream's trim then kept everything, the list stayed
// full, and nothing asked for the next page until the reader scrolled back to
// the messages.
//
// Here the list makes room there too. The reader is past one end of the
// loaded messages, so the messages at that end are the ones they reach first:
// those stay, the far end goes, and paging starts again as after any trim.

/// What the list draws between the older skeleton and the oldest message:
/// the top padding of the rows (MessageListViewport) and a date divider
/// (`_buildDateSeparator`: its content between 8 px of padding on each side).
const double _kForkAboveOldestMessage = 8 + 8 + kDateDividerContentHeight + 8;

extension _ForkSkeletonTrim on _MessageListState {
  /// Called from upstream's trim when it finds no laid-out row to keep.
  void _forkTrimPastLoadedRows(ChatViewState state) {
    final List<Message> messages = state.messages;
    if (!_scrollController.hasClients || messages.isEmpty) {
      return;
    }
    final ScrollPosition position = _scrollController.listPosition!;
    // A jump that is under way decides what the list holds and shows.
    if (!position.hasContentDimensions || _isJumpOwningViewport()) {
      return;
    }
    final RenderObject? viewport = position.context.notificationContext
        ?.findRenderObject();
    if (viewport is! RenderBox || !viewport.hasSize) {
      return;
    }
    final double toOldest = -_centerLeadingDistance(position);
    final double toNewest = -_rawTrailingDistance(position);
    final bool pastOldest =
        state.hasMoreMessages && _leadingFillerExtent > 0 && toOldest > 0;
    final bool pastNewest =
        state.hasMoreNewerMessages && _trailingFillerExtent > 0 && toNewest > 0;
    if (pastOldest == pastNewest) {
      return;
    }
    final double viewportTop = viewport.localToGlobal(Offset.zero).dy;
    final double viewportHeight = position.viewportDimension;
    // Where the nearest loaded message is, from where the skeleton ends, so
    // that the skeleton stays where it is on screen. Above the oldest message
    // the list draws the rows' top padding and that message's date divider,
    // both of a fixed height; below the newest it draws nothing.
    final int nearest = pastOldest ? 0 : messages.length - 1;
    final double nearestEdge = pastOldest
        ? viewportTop + toOldest + _kForkAboveOldestMessage
        : viewportTop + viewportHeight - toNewest;
    final _AttachedRows rows = (
      id: messages[nearest].id,
      first: nearest,
      last: nearest,
      firstId: messages[nearest].id,
      firstTop: nearestEdge,
      lastId: messages[nearest].id,
      lastBottom: nearestEdge,
      viewportTop: viewportTop,
      viewportHeight: viewportHeight,
    );
    final ({int start, int end})? span = _trimSpan(
      messages.length,
      nearest,
      rows,
    );
    if (span == null) {
      return;
    }
    // The list leaves the layout of an open at NEW, as upstream's other
    // moves of the anchor do: that layout belongs to the anchor it had.
    _unreadOpenLayout = false;
    _setUnreadLeadingPad(0);
    _moveAnchorToAttachedEdge(rows, anchorNewer: pastNewest);
    _chatViewModel.trimToSpan(
      firstId: messages[span.start].id,
      lastId: messages[span.end].id,
    );
    final int epoch = _uiEpoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runIfSameEpoch(epoch, () {
        _publishDemandGeometry();
        _demandSource.onWindowTrimmed();
      });
    });
  }
}
