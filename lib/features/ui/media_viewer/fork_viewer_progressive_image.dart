import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:fluxer_app/core/api/attachment_request_auth.dart';
import 'package:fluxer_app/features/accessibility/presentation/allow_image_frame_animation.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/media/chat_network_image.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/media/media_load_error_placeholder.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/media/media_thumb_hash_placeholder.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/media/retrying_network_image.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/media/seen_media_urls.dart';
import 'package:fluxer_app/features/chat/utils/attachments/attachment_display_utils.dart';
import 'package:fluxer_app/features/chat/utils/media/fork_media_proxy_sizing.dart';
import 'package:fluxer_app/features/chat/utils/media/fork_rendered_thumbnail_registry.dart';
import 'package:fluxer_app/features/chat/utils/media/hdr_aware_image_url.dart';
import 'package:fluxer_app/features/settings/providers/preferences/appearance_preferences_provider.dart';
import 'package:fluxer_app/features/ui/media_viewer/attachment_media_viewer.dart';
import 'package:fluxer_app/features/ui/media_viewer/fork_media_viewer_preloader.dart';
import 'package:fluxer_app/features/ui/media_viewer/fork_viewer_items.dart';
import 'package:fluxer_app/material_ui.dart';

const Duration kForkViewerSpinnerDelay = Duration(milliseconds: 180);
const Duration kForkViewerCrossfadeDuration = Duration(milliseconds: 120);
const Duration kForkViewerPromotedStallTimeout = Duration(milliseconds: 2500);

/// Renders a cached thumbnail strictly from Flutter's in-memory `ImageCache`
/// or `BaseCacheManager`'s disk cache (accepting stale `validTill` entries)
/// with **zero** network GETs. Falls back to [fallback] on miss or decode error.
class ForkCacheOnlyPreviewImage extends StatefulWidget {
  const ForkCacheOnlyPreviewImage({
    required this.descriptor,
    required this.fit,
    required this.fallback,
    this.width,
    this.height,
    this.cacheManager,
    this.onCacheStateResolved,
    super.key,
  });

  final ForkThumbnailDescriptor descriptor;
  final BoxFit fit;
  final Widget fallback;
  final double? width;
  final double? height;
  final BaseCacheManager? cacheManager;
  final ValueChanged<bool>? onCacheStateResolved;

  @override
  State<ForkCacheOnlyPreviewImage> createState() =>
      _ForkCacheOnlyPreviewImageState();
}

class _ForkCacheOnlyPreviewImageState extends State<ForkCacheOnlyPreviewImage> {
  ImageProvider? _resolvedProvider;
  int _lookupGeneration = 0;
  int _reportedGeneration = -1;
  bool? _reportedState;

  @override
  void initState() {
    super.initState();
    _resolveCacheOnly();
  }

  @override
  void didUpdateWidget(ForkCacheOnlyPreviewImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.descriptor != widget.descriptor ||
        oldWidget.cacheManager != widget.cacheManager) {
      _resolvedProvider = null;
      _reportedState = null;
      _resolveCacheOnly();
    }
  }

  void _resolveCacheOnly() {
    final int gen = ++_lookupGeneration;
    final String url = widget.descriptor.url;
    if (url.isEmpty) {
      _reportCacheState(gen, false);
      return;
    }

    final ImageProvider ramProvider = ResizeImage.resizeIfNeeded(
      widget.descriptor.memCacheWidth,
      widget.descriptor.memCacheHeight,
      CachedNetworkImageProvider(
        url,
        headers: AttachmentRequestAuth.headersFor(url),
        cacheManager: widget.cacheManager,
      ),
    );

    final Future<Object> keyFuture = ramProvider.obtainKey(
      ImageConfiguration.empty,
    );
    if (keyFuture is SynchronousFuture<Object>) {
      Object? syncKey;
      unawaited(keyFuture.then((Object k) => syncKey = k));
      if (syncKey != null && _isInMemoryImageCache(syncKey!)) {
        _resolvedProvider = ramProvider;
        return;
      }
      unawaited(_lookupDiskCache(gen, url));
      return;
    }

    unawaited(
      keyFuture.then((Object key) async {
        if (!mounted || gen != _lookupGeneration) {
          return;
        }
        if (_isInMemoryImageCache(key)) {
          setState(() => _resolvedProvider = ramProvider);
          return;
        }
        await _lookupDiskCache(gen, url);
      }),
    );
  }

  bool _isInMemoryImageCache(Object key) {
    final ImageCacheStatus status = PaintingBinding.instance.imageCache
        .statusForKey(key);
    return status.keepAlive || status.live;
  }

  Future<void> _lookupDiskCache(int gen, String url) async {
    try {
      final BaseCacheManager cm =
          widget.cacheManager ?? CachedNetworkImageProvider.defaultCacheManager;
      // Accept ANY cached file (including stale validTill) since no network
      // refresh is performed on cache-only previews. Usability is reported once
      // `Image.frameBuilder` decodes a real frame (so corrupt files never
      // suppress full-res error recovery).
      final FileInfo? fileInfo = await cm.getFileFromCache(url);
      if (!mounted || gen != _lookupGeneration) {
        return;
      }
      if (fileInfo != null && fileInfo.file.existsSync()) {
        final ImageProvider diskProvider = ResizeImage.resizeIfNeeded(
          widget.descriptor.memCacheWidth,
          widget.descriptor.memCacheHeight,
          FileImage(fileInfo.file),
        );
        setState(() => _resolvedProvider = diskProvider);
        return;
      }
      _reportCacheState(gen, false);
    } on Object {
      if (!mounted || gen != _lookupGeneration) {
        return;
      }
      _reportCacheState(gen, false);
    }
  }

  void _reportCacheState(int gen, bool hasCachedPreview) {
    if (_reportedGeneration == gen && _reportedState == hasCachedPreview) {
      return;
    }
    _reportedGeneration = gen;
    _reportedState = hasCachedPreview;
    final ValueChanged<bool>? callback = widget.onCacheStateResolved;
    if (callback == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted || gen != _lookupGeneration) {
        return;
      }
      callback(hasCachedPreview);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final ImageProvider? provider = _resolvedProvider;
    if (provider == null) {
      return widget.fallback;
    }
    final int gen = _lookupGeneration;
    return Image(
      image: provider,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      gaplessPlayback: true,
      frameBuilder:
          (
            BuildContext context,
            Widget child,
            int? frame,
            bool wasSynchronouslyLoaded,
          ) {
            if (wasSynchronouslyLoaded || frame != null) {
              _reportCacheState(gen, true);
              return child;
            }
            return widget.fallback;
          },
      errorBuilder: (BuildContext _, Object _, StackTrace? _) {
        _reportCacheState(gen, false);
        return widget.fallback;
      },
    );
  }
}

/// Unified viewer page image entry point called from `_buildMediaPage`.
///
/// Enforces:
/// 1. Transient-page gate (`shouldLoadFullRes == false` -> cache-only preview
///    or thumbhash, 0 full-res GETs).
/// 2. Promoted in-flight preloader handoff BEFORE renderer selection (covering
///    both progressive and single-layer items, with cancel-and-await-unwind on
///    fallback).
/// 3. Single-layer path (when no distinct preview / equal URL / animated / SVG)
///    with `forkOnImageLoaded` wired so preloading always unlocks.
/// 4. Progressive 2-layer path with intrinsic-capped `scaleDown` sizing,
///    `BoxFit.contain` on both layers, delayed 180 ms spinner at 1x scale,
///    and keeping the cached thumbnail visible if full-res fails terminally.
class ForkViewerPageImage extends StatefulWidget {
  const ForkViewerPageImage({
    required this.item,
    required this.imageUrl,
    required this.decodeCap,
    required this.isPortrait,
    required this.shouldLoadFullRes,
    required this.errorPlaceholder,
    this.preloader,
    this.cacheManager,
    this.onFullResLoaded,
    this.onFullResUnrecoverable,
    this.spinnerDelay = kForkViewerSpinnerDelay,
    this.promotedStallTimeout = kForkViewerPromotedStallTimeout,
    super.key,
  });

  final AttachmentMediaViewerItem item;
  final String imageUrl;
  final int? decodeCap;
  final bool isPortrait;
  final bool shouldLoadFullRes;
  final Widget errorPlaceholder;
  final ForkMediaViewerPreloader? preloader;
  final BaseCacheManager? cacheManager;
  final VoidCallback? onFullResLoaded;

  /// Called when the full-resolution image cannot be decoded (or is too large),
  /// so no retry will fix it. Not called for network or HTTP failures, which
  /// keep retrying: the viewer starts neighbour preloading only after a load or
  /// this, so preloads never compete with a page that is still retrying.
  final VoidCallback? onFullResUnrecoverable;
  final Duration spinnerDelay;
  final Duration promotedStallTimeout;

  @override
  State<ForkViewerPageImage> createState() => _ForkViewerPageImageState();
}

class _ForkViewerPageImageState extends State<ForkViewerPageImage> {
  bool _awaitingPromoted = false;
  ForkPromotedTransfer? _promotedHandle;
  int _handoffGeneration = 0;

  bool _wasSeenBeforeLoad = false;
  bool _hasCachedPreview = false;
  bool _fullResLoaded = false;
  bool _fadeCompleted = false;
  bool _fullResFailed = false;
  bool _showSpinner = false;
  double _lastBuiltFullResOpacity = 1;
  Timer? _spinnerTimer;
  Timer? _promotedWatchdog;
  Timer? _rateLimitHoldTimer;

  bool get _isProgressiveEligible {
    final ForkThumbnailDescriptor? preview = widget.item.forkPreview;
    if (preview == null || preview.url.isEmpty) {
      return false;
    }
    if (preview.url == widget.imageUrl) {
      return false;
    }
    if (forkIsExplicitlyAnimatedViewerItem(widget.item)) {
      return false;
    }
    if (isSvgImageMedia(
      url: widget.imageUrl,
      filename: widget.item.filename,
      contentType: widget.item.contentType,
    )) {
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    if (widget.shouldLoadFullRes) {
      _beginForegroundLoadIfNeeded();
    }
  }

  @override
  void didUpdateWidget(ForkViewerPageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool urlChanged = oldWidget.imageUrl != widget.imageUrl;
    if (urlChanged) {
      _resetLoadState();
    }
    if (widget.shouldLoadFullRes &&
        (!oldWidget.shouldLoadFullRes || urlChanged)) {
      _beginForegroundLoadIfNeeded();
    } else if (!widget.shouldLoadFullRes && oldWidget.shouldLoadFullRes) {
      _cancelPromotedHandle();
      _cancelSpinnerTimer();
    }
  }

  @override
  void dispose() {
    _cancelPromotedHandle();
    _cancelSpinnerTimer();
    super.dispose();
  }

  void _cancelPromotedHandle() {
    _handoffGeneration += 1;
    _promotedWatchdog?.cancel();
    _promotedWatchdog = null;
    _rateLimitHoldTimer?.cancel();
    _rateLimitHoldTimer = null;
    final ForkPromotedTransfer? handle = _promotedHandle;
    _promotedHandle = null;
    _awaitingPromoted = false;
    if (handle != null) {
      unawaited(handle.cancelAndAwaitUnwind());
    }
  }

  void _resetLoadState() {
    _cancelPromotedHandle();
    _wasSeenBeforeLoad = false;
    _hasCachedPreview = false;
    _fullResLoaded = false;
    _fadeCompleted = false;
    _fullResFailed = false;
    _showSpinner = false;
    _lastBuiltFullResOpacity = 1.0;
    _cancelSpinnerTimer();
  }

  void _beginForegroundLoadIfNeeded() {
    if (widget.imageUrl.isEmpty) {
      return;
    }
    // Snapshot prior-seen state BEFORE RetryingNetworkImage marks SeenMediaUrls
    // on frame completion so first network loads play the 120 ms crossfade.
    if (!_fullResLoaded) {
      _wasSeenBeforeLoad = SeenMediaUrls.contains(widget.imageUrl);
    }
    if (!_fullResLoaded && !_fullResFailed && _isProgressiveEligible) {
      _armSpinnerTimer();
    }
    final Duration? existingHold = widget.preloader
        ?.remainingForegroundRateLimitHold(widget.imageUrl);
    if (existingHold != null && existingHold > Duration.zero) {
      final int gen = ++_handoffGeneration;
      _awaitingPromoted = true;
      if (!_fullResLoaded && !_fullResFailed) {
        _armSpinnerTimer();
      }
      _rateLimitHoldTimer?.cancel();
      _rateLimitHoldTimer = Timer(existingHold, () {
        if (!mounted || gen != _handoffGeneration) {
          return;
        }
        _rateLimitHoldTimer = null;
        setState(() => _awaitingPromoted = false);
      });
      return;
    }
    final ForkPromotedTransfer? handle = widget.preloader?.promoteInFlight(
      widget.imageUrl,
    );
    if (handle == null) {
      return;
    }
    final int gen = ++_handoffGeneration;
    _promotedHandle = handle;
    _awaitingPromoted = true;
    if (!_fullResLoaded && !_fullResFailed) {
      _armSpinnerTimer();
    }
    unawaited(_awaitPromotedTransfer(gen, handle));
  }

  Future<void> _awaitPromotedTransfer(
    int gen,
    ForkPromotedTransfer handle,
  ) async {
    int lastObservedBytes = handle.receivedBytes;
    bool wasHeadersReceived = handle.headersReceived;
    _promotedWatchdog?.cancel();
    _promotedWatchdog = Timer.periodic(widget.promotedStallTimeout, (
      Timer timer,
    ) {
      if (!mounted || gen != _handoffGeneration) {
        timer.cancel();
        return;
      }
      if (!handle.headersReceived) {
        // Pre-header wait (connect + proxy transform TTFB) is bounded by the
        // preloader's own inactivityTimeout (10 s) so 3 s transforms aren't
        // aborted prematurely and duplicated.
        return;
      }
      if (!wasHeadersReceived) {
        wasHeadersReceived = true;
        lastObservedBytes = handle.receivedBytes;
        return;
      }
      final int currentBytes = handle.receivedBytes;
      if (currentBytes > lastObservedBytes) {
        lastObservedBytes = currentBytes;
        return;
      }
      // No body-byte progress over the stall grace window: abort and fall back
      // to foreground loading immediately.
      timer.cancel();
      unawaited(handle.cancelAndAwaitUnwind());
    });
    bool holdForRateLimit = false;
    try {
      await handle.done;
      if (!mounted || gen != _handoffGeneration) {
        return;
      }
      if (!handle.didCacheFresh) {
        await handle.cancelAndAwaitUnwind();
      }
      if (!mounted || gen != _handoffGeneration) {
        return;
      }
      final DateTime? rateLimitUntil = handle.rateLimitUntil;
      if (!handle.didCacheFresh && rateLimitUntil != null) {
        final Duration remaining = rateLimitUntil.difference(handle.now());
        if (remaining > Duration.zero) {
          holdForRateLimit = true;
          _rateLimitHoldTimer?.cancel();
          _rateLimitHoldTimer = Timer(remaining, () {
            if (!mounted || gen != _handoffGeneration) {
              return;
            }
            _rateLimitHoldTimer = null;
            setState(() => _awaitingPromoted = false);
          });
        }
      }
    } on Object {
      await handle.cancelAndAwaitUnwind();
    } finally {
      _promotedWatchdog?.cancel();
      _promotedWatchdog = null;
      if (identical(_promotedHandle, handle)) {
        _promotedHandle = null;
      }
      if (mounted && gen == _handoffGeneration) {
        setState(() {
          if (!holdForRateLimit) {
            _awaitingPromoted = false;
          }
          _promotedHandle = null;
        });
      }
    }
  }

  void _armSpinnerTimer() {
    _spinnerTimer?.cancel();
    _spinnerTimer = Timer(widget.spinnerDelay, () {
      if (!mounted || _fullResLoaded || _fullResFailed) {
        return;
      }
      setState(() => _showSpinner = true);
    });
  }

  void _cancelSpinnerTimer() {
    _spinnerTimer?.cancel();
    _spinnerTimer = null;
  }

  void _handleFullResLoaded() {
    if (!mounted) {
      return;
    }
    _cancelSpinnerTimer();
    // Skip crossfade and unmount preview/thumbhash immediately unless a 0.0 -> 1.0
    // AnimatedOpacity transition will genuinely start on the next build (i.e.,
    // unseen URL, decoded preview present, AND AnimatedOpacity was previously
    // built at 0.0 rather than coalescing both completions before a build).
    final bool willAnimateOpacity =
        !_wasSeenBeforeLoad &&
        _hasCachedPreview &&
        _lastBuiltFullResOpacity == 0.0;
    final bool instantFade = !willAnimateOpacity;
    if (!_fullResLoaded ||
        _showSpinner ||
        _fullResFailed ||
        (instantFade && !_fadeCompleted)) {
      setState(() {
        _fullResLoaded = true;
        if (instantFade) {
          _fadeCompleted = true;
        }
        _fullResFailed = false;
        _showSpinner = false;
      });
    }
    widget.onFullResLoaded?.call();
  }

  void _handleFullResFailure(ForkImageLoadFailure failure) {
    if (!mounted) {
      return;
    }
    if (failure.isPermanent ||
        failure.failures > kMediaLoadRetryDelays.length) {
      _cancelSpinnerTimer();
      setState(() {
        _fullResFailed = true;
        _showSpinner = false;
      });
    }
    if (failure.undecodable) {
      widget.onFullResUnrecoverable?.call();
    }
  }

  Widget _buildThumbHashFallback() {
    final String? thumbHash = widget.item.forkPreview?.thumbHash;
    if (thumbHash != null && thumbHash.isNotEmpty) {
      return MediaThumbHashPlaceholder(thumbHash: thumbHash);
    }
    return const SizedBox.shrink();
  }

  Widget _buildTransientOrHandoffContent() {
    final ForkThumbnailDescriptor? preview = widget.item.forkPreview;
    final Widget fallback = _buildThumbHashFallback();
    final Widget base = preview != null && preview.url.isNotEmpty
        ? ForkCacheOnlyPreviewImage(
            descriptor: preview,
            fit: BoxFit.contain,
            cacheManager: widget.cacheManager,
            fallback: fallback,
            onCacheStateResolved: (bool cached) {
              if (!mounted) {
                return;
              }
              if (_fullResLoaded && !cached && !_fadeCompleted) {
                setState(() {
                  _hasCachedPreview = false;
                  _fadeCompleted = true;
                });
              } else if (cached != _hasCachedPreview) {
                setState(() => _hasCachedPreview = cached);
              }
            },
          )
        : fallback;
    return _wrapWithIntrinsicScaleDownBox(
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: <Widget>[
          base,
          if (_awaitingPromoted && _showSpinner) _buildSpinnerOverlay(),
        ],
      ),
    );
  }

  Widget _wrapWithIntrinsicScaleDownBox({required Widget child}) {
    final int? sourceW = widget.item.width;
    final int? sourceH = widget.item.height;
    if (sourceW == null || sourceH == null || sourceW <= 0 || sourceH <= 0) {
      return child;
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (!constraints.maxWidth.isFinite ||
            !constraints.maxHeight.isFinite ||
            constraints.maxWidth <= 0 ||
            constraints.maxHeight <= 0) {
          return child;
        }
        final double w = sourceW.toDouble();
        final double h = sourceH.toDouble();
        final double scale = math.min(
          1,
          math.min(constraints.maxWidth / w, constraints.maxHeight / h),
        );
        return SizedBox(width: w * scale, height: h * scale, child: child);
      },
    );
  }

  Widget _buildSpinnerOverlay() {
    return IgnorePointer(
      child: Align(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
          ),
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.isEmpty) {
      return widget.errorPlaceholder;
    }

    // 1. Transient page gate (strip jump intermediate pages, reversed drags).
    if (!widget.shouldLoadFullRes) {
      return _buildTransientOrHandoffContent();
    }

    // 2. Promoted in-flight preloader handoff (or Retry-After hold) BEFORE
    //    renderer selection.
    if (_awaitingPromoted) {
      return _buildTransientOrHandoffContent();
    }

    // 3. Single-layer path (no distinct preview / equal URL / animated / SVG).
    if (!_isProgressiveEligible) {
      return AllowImageFrameAnimation(
        child: ChatNetworkImage(
          forkOnImageLoaded: _handleFullResLoaded,
          forkOnLoadFailure: _handleFullResFailure,
          imageUrl: widget.imageUrl,
          filename: widget.item.filename,
          contentType: widget.item.contentType,
          memCacheWidth: widget.isPortrait ? null : widget.decodeCap,
          memCacheHeight: widget.isPortrait ? widget.decodeCap : null,
          errorPlaceholder: widget.errorPlaceholder,
        ),
      );
    }

    // 4. Progressive 2-layer path: cache-only preview -> full-res swap.
    final ForkThumbnailDescriptor preview = widget.item.forkPreview!;
    final bool keepThumbnailOnError = _hasCachedPreview;
    final Widget fullRes = AllowImageFrameAnimation(
      child: ChatNetworkImage(
        forkOnImageLoaded: _handleFullResLoaded,
        forkOnLoadFailure: _handleFullResFailure,
        forkMaxRetries: keepThumbnailOnError
            ? kMediaLoadRetryDelays.length
            : null,
        imageUrl: widget.imageUrl,
        filename: widget.item.filename,
        contentType: widget.item.contentType,
        memCacheWidth: widget.isPortrait ? null : widget.decodeCap,
        memCacheHeight: widget.isPortrait ? widget.decodeCap : null,
        errorPlaceholder: keepThumbnailOnError
            ? const SizedBox.shrink()
            : widget.errorPlaceholder,
      ),
    );

    final double targetOpacity = _fullResLoaded || !keepThumbnailOnError
        ? 1.0
        : 0.0;
    _lastBuiltFullResOpacity = targetOpacity;

    final Widget content = Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: <Widget>[
        if (!_fadeCompleted)
          ForkCacheOnlyPreviewImage(
            descriptor: preview,
            fit: BoxFit.contain,
            cacheManager: widget.cacheManager,
            fallback: _buildThumbHashFallback(),
            onCacheStateResolved: (bool cached) {
              if (!mounted) {
                return;
              }
              if (_fullResLoaded && !cached && !_fadeCompleted) {
                setState(() {
                  _hasCachedPreview = false;
                  _fadeCompleted = true;
                });
              } else if (cached != _hasCachedPreview) {
                setState(() => _hasCachedPreview = cached);
              }
            },
          ),
        AnimatedOpacity(
          opacity: targetOpacity,
          duration: _wasSeenBeforeLoad
              ? Duration.zero
              : kForkViewerCrossfadeDuration,
          onEnd: () {
            if (mounted && _fullResLoaded && !_fadeCompleted) {
              setState(() => _fadeCompleted = true);
            }
          },
          child: fullRes,
        ),
        if (_showSpinner && !_fullResLoaded && !_fullResFailed)
          _buildSpinnerOverlay(),
      ],
    );

    return _wrapWithIntrinsicScaleDownBox(child: content);
  }
}

/// Renders a 56 dp viewer bottom-strip thumbnail.
///
/// Reuses `item.forkPreview` strictly through cache-only lookup (accepting
/// stale disk entries so expired signed URLs stay visible with 0 network GETs),
/// falling back to a snapped 56 dp thumbnail URL only on cache miss.
class ForkViewerStripThumbnail extends StatefulWidget {
  const ForkViewerStripThumbnail({
    required this.item,
    required this.hdrDisplayMode,
    required this.decodeCap,
    required this.isLandscape,
    required this.devicePixelRatio,
    this.cacheManager,
    this.mediaEndpoint,
    super.key,
  });

  final AttachmentMediaViewerItem item;
  final HdrDisplayMode hdrDisplayMode;
  final int? decodeCap;
  final bool isLandscape;
  final double devicePixelRatio;
  final BaseCacheManager? cacheManager;
  final String? mediaEndpoint;

  @override
  State<ForkViewerStripThumbnail> createState() =>
      _ForkViewerStripThumbnailState();
}

class _ForkViewerStripThumbnailState extends State<ForkViewerStripThumbnail> {
  bool? _hasCachedPreview;

  @override
  void didUpdateWidget(ForkViewerStripThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.forkPreview != widget.item.forkPreview) {
      _hasCachedPreview = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    const Widget errorPlaceholder = MediaLoadErrorPlaceholder(showLabel: false);
    final ForkThumbnailDescriptor? preview = widget.item.forkPreview;
    if (preview != null &&
        preview.url.isNotEmpty &&
        (_hasCachedPreview ?? true)) {
      return ForkCacheOnlyPreviewImage(
        descriptor: preview,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        cacheManager: widget.cacheManager,
        fallback: _hasCachedPreview == null
            ? _buildFallbackPlaceholder()
            : _buildSizedNetworkFallback(errorPlaceholder),
        onCacheStateResolved: (bool cached) {
          if (mounted && _hasCachedPreview != cached) {
            setState(() => _hasCachedPreview = cached);
          }
        },
      );
    }
    return _buildSizedNetworkFallback(errorPlaceholder);
  }

  Widget _buildFallbackPlaceholder() {
    final String? thumbHash = widget.item.forkPreview?.thumbHash;
    if (thumbHash != null && thumbHash.isNotEmpty) {
      return MediaThumbHashPlaceholder(thumbHash: thumbHash);
    }
    return const SizedBox.expand();
  }

  Widget _buildSizedNetworkFallback(Widget errorPlaceholder) {
    final String fallbackUrl = buildHdrAwareDisplayImageUrl(
      url: widget.item.url,
      proxyUrl: widget.item.proxyUrl,
      mode: widget.hdrDisplayMode,
      contentType: widget.item.contentType,
      animated: widget.item.animated,
    );
    if (fallbackUrl.isEmpty) {
      return errorPlaceholder;
    }
    final bool urlIsAnimated =
        mediaProxyUrlIsAnimated(widget.item.url) ||
        (widget.item.proxyUrl != null &&
            mediaProxyUrlIsAnimated(widget.item.proxyUrl!));
    final String sourceUrl = mediaProxyUrlIsAnimated(widget.item.url)
        ? widget.item.url
        : (widget.item.proxyUrl ?? widget.item.url);
    final String stripUrl = buildForkSizedThumbnailUrl(
      url: sourceUrl,
      fallbackUrl: fallbackUrl,
      layoutWidth: 56,
      layoutHeight: 56,
      devicePixelRatio: widget.devicePixelRatio,
      sourceWidth: widget.item.width,
      sourceHeight: widget.item.height,
      contentType: widget.item.contentType,
      filename: widget.item.filename,
      animated:
          urlIsAnimated || forkIsExplicitlyAnimatedViewerItem(widget.item),
      cover: true,
      maxCoverAspectMultiplier: 4,
      mediaEndpoint: widget.mediaEndpoint,
    );
    return ChatNetworkImage(
      imageUrl: stripUrl,
      filename: widget.item.filename,
      contentType: widget.item.contentType,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      memCacheWidth: widget.isLandscape ? null : widget.decodeCap,
      memCacheHeight: widget.isLandscape ? widget.decodeCap : null,
      errorPlaceholder: errorPlaceholder,
    );
  }
}

/// Observes top-level horizontal page drags and scroll settles around
/// upstream's `PageView.builder` without wrapping or re-indenting upstream's
/// widget code.
class ForkViewerPageSettleObserver extends StatelessWidget {
  const ForkViewerPageSettleObserver({
    required this.onUserDragStart,
    required this.onPageSettled,
    required this.readSettledPage,
    required this.child,
    super.key,
  });

  final VoidCallback onUserDragStart;
  final ValueChanged<int> onPageSettled;
  final int? Function() readSettledPage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification.depth != 0 ||
            notification.metrics.axis != Axis.horizontal) {
          return false;
        }
        if ((notification is ScrollStartNotification &&
                notification.dragDetails != null) ||
            (notification is ScrollUpdateNotification &&
                notification.dragDetails != null)) {
          onUserDragStart();
        } else if (notification is ScrollEndNotification) {
          final int? settled = readSettledPage();
          if (settled != null) {
            onPageSettled(settled);
          }
        }
        return false;
      },
      child: child,
    );
  }
}
