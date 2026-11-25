import 'dart:collection';

import 'package:fluxer_app/material_ui.dart';

/// Describes the exact thumbnail URL and decode dimensions rendered by a chat,
/// embed, forum, or audio-cover tile so the full-screen viewer can reuse the
/// exact cached image without re-fetching or recomputing grid layout.
@immutable
class ForkThumbnailDescriptor {
  const ForkThumbnailDescriptor({
    required this.url,
    this.memCacheWidth,
    this.memCacheHeight,
    this.thumbHash,
  });

  final String url;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final String? thumbHash;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ForkThumbnailDescriptor &&
            other.url == url &&
            other.memCacheWidth == memCacheWidth &&
            other.memCacheHeight == memCacheHeight &&
            other.thumbHash == thumbHash;
  }

  @override
  int get hashCode =>
      Object.hash(url, memCacheWidth, memCacheHeight, thumbHash);
}

/// Holds the descriptor of the thumbnail a single tile last laid out, for a
/// tap handler that sits above the tile's `LayoutBuilder`.
///
/// The thumbnail URL depends on the width the tile gets at layout, which the
/// tap handler outside the builder cannot know, so the builder records it here
/// and the tap reads it. A tap always follows a layout, so the value is the one
/// on screen. Create one per build, next to the tap handler that reads it.
class ForkRenderedPreviewSlot {
  ForkThumbnailDescriptor? descriptor;
}

/// Wraps a multi-tile gallery widget (e.g. `AttachmentMediaGrid`) so each
/// concrete mounted instance owns its own sibling descriptor map, avoiding
/// cross-surface collisions when the same message is rendered simultaneously
/// in different containers (such as Chat and Pins at different widths).
class ForkGalleryPreviewScope extends StatefulWidget {
  const ForkGalleryPreviewScope({required this.child, super.key});

  final Widget child;

  static void maybeRegister(
    BuildContext context,
    String sourceKey,
    ForkThumbnailDescriptor descriptor,
  ) {
    if (sourceKey.isEmpty || descriptor.url.isEmpty) {
      return;
    }
    final _ForkGalleryPreviewInherited? scope = context
        .getInheritedWidgetOfExactType<_ForkGalleryPreviewInherited>();
    scope?.descriptors[sourceKey] = descriptor;
  }

  static Map<String, ForkThumbnailDescriptor>? maybeRead(BuildContext context) {
    final _ForkGalleryPreviewInherited? scope = context
        .getInheritedWidgetOfExactType<_ForkGalleryPreviewInherited>();
    if (scope == null || scope.descriptors.isEmpty) {
      return null;
    }
    return Map<String, ForkThumbnailDescriptor>.unmodifiable(scope.descriptors);
  }

  @override
  State<ForkGalleryPreviewScope> createState() =>
      _ForkGalleryPreviewScopeState();
}

class _ForkGalleryPreviewScopeState extends State<ForkGalleryPreviewScope> {
  final Map<String, ForkThumbnailDescriptor> _descriptors =
      <String, ForkThumbnailDescriptor>{};

  @override
  Widget build(BuildContext context) {
    return _ForkGalleryPreviewInherited(
      descriptors: _descriptors,
      child: widget.child,
    );
  }
}

class _ForkGalleryPreviewInherited extends InheritedWidget {
  const _ForkGalleryPreviewInherited({
    required this.descriptors,
    required super.child,
  });

  final Map<String, ForkThumbnailDescriptor> descriptors;

  @override
  bool updateShouldNotify(_ForkGalleryPreviewInherited oldWidget) => false;
}

/// Scoped in-memory LRU fallback registry for surfaces whose viewer-launch
/// callback cannot receive the descriptor directly (e.g. `ForumPostTile` /
/// `ForumPostCard` -> `openForumPostMedia`, keyed by `'forum:${post.id}'`).
///
/// Cleared only when the disk cache is cleared (`clearFluxerNetworkImageCaches`)
/// or on auth/session change — never on RAM-only memory trims.
// Global registry mirrors `SeenMediaUrls` lifecycle across widget trees.
// ignore: avoid_classes_with_only_static_members
abstract final class ForkRenderedThumbnailRegistry {
  static const int _kMaxEntries = 256;
  static final LinkedHashMap<(Object, String), ForkThumbnailDescriptor>
  _entries = LinkedHashMap<(Object, String), ForkThumbnailDescriptor>();

  static void register({
    required Object scopeToken,
    required String sourceKey,
    required ForkThumbnailDescriptor descriptor,
  }) {
    if (sourceKey.isEmpty || descriptor.url.isEmpty) {
      return;
    }
    final (Object, String) key = (scopeToken, sourceKey);
    _entries.remove(key);
    _entries[key] = descriptor;
    while (_entries.length > _kMaxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  static ForkThumbnailDescriptor? lookup({
    required Object scopeToken,
    required String sourceKey,
  }) {
    if (sourceKey.isEmpty) {
      return null;
    }
    final (Object, String) key = (scopeToken, sourceKey);
    final ForkThumbnailDescriptor? value = _entries.remove(key);
    if (value != null) {
      _entries[key] = value;
    }
    return value;
  }

  static void clear() {
    _entries.clear();
  }
}
