// Fork: tyne-chat/tyne#942. Keeps message action sheets and context menus
// working when the originating MessageItem unmounts while the overlay is open
// (for example, when hiding the soft keyboard triggers an underfill _reanchor
// in MessageList and increments _anchorEpoch).
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/features/chat/domain/chat_fullscreen_video_launch_context.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/message_actions/message_bottom_sheet.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/message_actions/quick_reaction_row.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/messages/message_reactions_bar.dart';
import 'package:fluxer_app/features/chat/providers/pickers/expression_usage_provider.dart';
import 'package:fluxer_app/features/ui/emoji_picker/fluxer_selected_emoji.dart';
import 'package:fluxer_app/material_ui.dart';

class ForkMessageActionHostHandle {
  ForkMessageActionHostHandle._(this._state);

  final _ForkMessageActionHostState _state;

  bool get mounted => _state.mounted;
  BuildContext get context => _state.context;
  WidgetRef get ref => _state.ref;
}

/// Provides a [BuildContext] and [WidgetRef] above `MessageListViewport`'s
/// `KeyedSubtree(ValueKey<int>(anchorEpoch))` so post-sheet menu actions keep
/// working if a row unmounts while its sheet or context menu is open.
class ForkMessageActionHost extends ConsumerStatefulWidget {
  const ForkMessageActionHost({required this.child, super.key});

  final Widget child;

  static ForkMessageActionHostHandle? maybeOf(BuildContext context) {
    return context
        .getInheritedWidgetOfExactType<_ForkMessageActionHostScope>()
        ?.handle;
  }

  @override
  ConsumerState<ForkMessageActionHost> createState() =>
      _ForkMessageActionHostState();
}

class _ForkMessageActionHostState extends ConsumerState<ForkMessageActionHost> {
  late final ForkMessageActionHostHandle _handle =
      ForkMessageActionHostHandle._(this);

  @override
  Widget build(BuildContext context) {
    return _ForkMessageActionHostScope(handle: _handle, child: widget.child);
  }
}

class _ForkMessageActionHostScope extends InheritedWidget {
  const _ForkMessageActionHostScope({
    required this.handle,
    required super.child,
  });

  final ForkMessageActionHostHandle handle;

  @override
  bool updateShouldNotify(_ForkMessageActionHostScope oldWidget) =>
      !identical(handle, oldWidget.handle);
}

/// Wraps `MessageListBody` in [ForkMessageActionHost] on one line.
Widget forkHostBody(Widget child) => ForkMessageActionHost(child: child);

/// Captures everything a message sheet or context menu needs before awaiting
/// user input so unmounting the originating `MessageItem` neither throws on a
/// disposed `WidgetRef` / `State.context` nor drops the chosen action.
class ForkMessageActionSession {
  ForkMessageActionSession({
    required BuildContext itemContext,
    required this.message,
    required this.previewRoleGuildId,
    required this.onReaction,
    required this.baseCallbacks,
  }) : _host = ForkMessageActionHost.maybeOf(itemContext),
       _navigator = Navigator.maybeOf(itemContext),
       _container = ProviderScope.containerOf(itemContext, listen: false);

  final ForkMessageActionHostHandle? _host;
  final NavigatorState? _navigator;
  final ProviderContainer _container;
  final Message message;
  final String? previewRoleGuildId;
  final ReactionToggleCallback? onReaction;
  final MessageActionCallbacks baseCallbacks;

  void dispatchQuickReaction(QuickReactionItem item) {
    final NavigatorState? navigator = _navigator;
    if (navigator != null && !navigator.mounted) {
      return;
    }
    final String? usageKey = quickReactionUsageKey(item);
    if (usageKey != null) {
      unawaited(
        _container
            .read(expressionUsageProvider(ExpressionUsageKind.emoji).notifier)
            .track(usageKey),
      );
    }
    switch (item) {
      case UnicodeQuickReaction(:final emoji):
        onReaction?.call(emoji);
      case CustomQuickReaction(:final emoji):
        onReaction?.call(
          emoji.name,
          emojiId: emoji.id,
          animated: emoji.animated,
        );
    }
  }

  MessageActionCallbacks get callbacks => MessageActionCallbacks(
    onReply: baseCallbacks.onReply,
    onForward: baseCallbacks.onForward,
    onEdit: baseCallbacks.onEdit,
    onDelete: baseCallbacks.onDelete,
    onRetry: baseCallbacks.onRetry,
    onDeleteFailed: baseCallbacks.onDeleteFailed,
    onMarkAsUnread: baseCallbacks.onMarkAsUnread,
    onRemoveAllReactions: baseCallbacks.onRemoveAllReactions,
    onReport: baseCallbacks.onReport,
    onAddReaction: _openAddReactionSheet,
    onDeleteAttachment: baseCallbacks.onDeleteAttachment,
    onEditAttachmentAltText: baseCallbacks.onEditAttachmentAltText,
  );

  void _openAddReactionSheet() {
    final BuildContext? targetContext = _survivingContext();
    if (targetContext == null) {
      return;
    }
    final ReactionToggleCallback? reaction = onReaction;
    unawaited(
      openReactionPickerSheet(
        targetContext,
        channelId: message.channelId,
        messageId: message.id,
        onEmojiSelected: (FluxerSelectedEmoji emoji) {
          if (reaction != null) {
            dispatchSelectedEmojiReaction(emoji, reaction);
          }
        },
      ),
    );
  }

  BuildContext? _survivingContext() {
    final ForkMessageActionHostHandle? host = _host;
    if (host != null && host.mounted) {
      return host.context;
    }
    final OverlayState? overlay = _navigator?.overlay;
    if (overlay != null && overlay.mounted) {
      return overlay.context;
    }
    return null;
  }

  void dispatchAfterUnmounted(
    MessageAction? action, {
    required VoidCallback? onDelete,
  }) {
    if (action == null) {
      return;
    }
    if (action == MessageAction.delete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onDelete?.call();
      });
      return;
    }
    final ForkMessageActionHostHandle? host = _host;
    if (host == null || !host.mounted) {
      return;
    }
    unawaited(
      dispatchMessageAction(
        ref: host.ref,
        context: host.context,
        message: message,
        action: action,
        callbacks: callbacks,
        previewRoleGuildId: previewRoleGuildId,
      ),
    );
  }
}

/// Ensures an unexpected error in [onQuickReaction] is reported without
/// aborting the `Navigator.pop()` that follows it in the sheet or menu.
ValueChanged<QuickReactionItem>? forkGuardedQuickReaction(
  ValueChanged<QuickReactionItem>? onQuickReaction,
) {
  if (onQuickReaction == null) {
    return null;
  }
  return (QuickReactionItem item) {
    try {
      onQuickReaction(item);
    } on Object catch (exception, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'gesture',
          // i18n-ignore: internal FlutterError diagnostic context, not UI text
          context: ErrorDescription('while handling a quick reaction'),
        ),
      );
    }
  };
}
