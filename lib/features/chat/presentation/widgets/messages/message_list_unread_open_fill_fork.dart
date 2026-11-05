part of 'message_list.dart';

// Fork: tyne-chat/tyne#495. Upstream's unread open lowers NEW only while the
// open settles, and only when the rows below it fall more than
// _kUnreadOpenFillSlop short of the lower half. A shortfall within the slop,
// a row below NEW that gets shorter (a reloaded window, an image that loads),
// or a list that grows taller (the signal bar collapsing, the keyboard
// closing) leaves empty space below the newest row, and nothing fits it
// again: the underfill reanchor that does this for jumps and restored anchors
// skips the unread layout. Once the open has settled, this checks after every
// frame, for as long as the list stays in its unread layout, and lowers NEW
// until the rows reach the bottom, the same way the settle passes do.
//
// The check uses the slivers' layout extents, not where rows are painted:
// rows slide into place after a window swap, and a check that measured them
// mid-slide saw no gap and did nothing. A shorter row or a finished slide
// changes no scroll metric while the list fits on screen, so no notification
// would say when to look; a post-frame check costs a few additions, and when
// nothing changes no frame runs.
final Expando<bool> _forkUnreadOpenFillWatched = Expando<bool>(
  'forkUnreadOpenFillWatched',
);

extension _ForkUnreadOpenFill on _MessageListState {
  /// Called from upstream's settle end.
  void _forkWatchUnreadOpenFill() {
    if (!_unreadOpenLayout) {
      return;
    }
    // The list stays hidden while the open settles, and the frame settle end
    // schedules is the first to show it: fill now, not after that frame, or
    // it shows the gap for one frame.
    _forkFillUnreadOpenBottom();
    if (_forkUnreadOpenFillWatched[this] ?? false) {
      return;
    }
    _forkUnreadOpenFillWatched[this] = true;
    _forkUnreadOpenFillAfterFrame();
  }

  void _forkUnreadOpenFillAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_unreadOpenLayout) {
        _forkUnreadOpenFillWatched[this] = null;
        return;
      }
      _forkFillUnreadOpenBottom();
      _forkUnreadOpenFillAfterFrame();
    });
  }

  void _forkFillUnreadOpenBottom() {
    if (_unreadOpenSettling ||
        _anchorId == null ||
        !_scrollController.hasClients ||
        _isUserDrivenScroll) {
      return;
    }
    final ScrollPosition position = _scrollController.listPosition!;
    if (!position.hasContentDimensions ||
        position.maxScrollExtent > 0 ||
        position.pixels <
            position.maxScrollExtent - kMessageListMetricsEpsilon) {
      return;
    }
    final ChatViewState state = ref.read(chatViewModelProvider);
    if (state.hasMoreNewerMessages || state.messages.isEmpty) {
      return;
    }
    final RenderObject? center = _unreadCenterKey.currentContext
        ?.findRenderObject();
    final RenderObject? parent = center?.parent;
    if (center is! RenderSliver ||
        parent is! RenderViewport ||
        !parent.hasSize ||
        parent.size.height <= 0) {
      return;
    }
    final RenderViewport viewport = parent;
    // Everything from NEW down: the rows, any trailing filler, the inset.
    double below = 0;
    for (
      RenderSliver? sliver = center;
      sliver != null;
      sliver = viewport.childAfter(sliver)
    ) {
      final SliverGeometry? geometry = sliver.geometry;
      if (geometry == null) {
        return;
      }
      below += geometry.scrollExtent;
    }
    final double height = viewport.size.height;
    final double gap = (1 - viewport.anchor) * height - below + position.pixels;
    if (gap <= kMessageListMetricsEpsilon) {
      return;
    }
    final double nextFraction = (1 - below / height).clamp(
      _kUnreadOpenAnchor,
      1.0,
    );
    if ((nextFraction - viewport.anchor).abs() * height <=
        kMessageListMetricsEpsilon) {
      return;
    }
    _anchorFraction = nextFraction;
    viewport.anchor = nextFraction;
    // Rebuild too: MessageListViewport hands its anchorFraction to the scroll
    // view, and a rebuild of that from a stale widget would put the old
    // anchor back. setState is protected outside the State class; this is
    // what it does once its callback has run.
    (context as Element).markNeedsBuild();
    // Upstream's passes keep the leading pad only while NEW sits at the
    // middle; below it, the pad would leave space above the oldest row.
    if (nextFraction > _kUnreadOpenAnchor + 0.02 && _openPad.value > 0) {
      _setUnreadLeadingPad(0, notify: true);
    }
  }
}
