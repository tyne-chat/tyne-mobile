import 'dart:async';
import 'dart:typed_data';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:fluxer_app/core/api/fork_call_site_interceptor.dart';
import 'package:fluxer_app/core/api/fork_dio_response_cleanup.dart';
import 'package:fluxer_app/core/api/retry_after.dart';
import 'package:fluxer_app/core/bootstrap/image_cache_config.dart';
import 'package:fluxer_app/features/chat/utils/attachments/attachment_display_utils.dart';
import 'package:fluxer_app/features/chat/utils/media/fork_media_proxy_sizing.dart';
import 'package:fluxer_app/features/settings/providers/preferences/appearance_preferences_provider.dart';
import 'package:fluxer_app/features/ui/media_viewer/attachment_media_viewer.dart';
import 'package:fluxer_app/features/ui/media_viewer/fork_viewer_items.dart';

const int kForkViewerPreloadMaxBytesPerSession = 50 << 20;
const int kForkViewerPreloadMaxSingleItemBytes = 20 << 20;
const Duration kForkViewerPreloadInactivityTimeout = Duration(seconds: 10);
const Duration kForkViewerPreloadMin429Cooldown = Duration(seconds: 10);
const Duration kForkViewerForegroundMaxRateLimitHold = Duration(seconds: 15);
const int kForkViewerPreloadMaxConsecutive404s = 2;

/// Evaluates transport-based preload radius from `connectivity_plus` results.
///
/// Note: `connectivity_plus` reports transport types without an OS metering
/// flag, so Wi-Fi/Ethernet (including Wi-Fi + VPN) gets radius 4, cellular /
/// VPN-only / unknown gets radius 1, and offline (`none` / empty) gets 0.
int forkPreloadRadiusForConnectivity(List<ConnectivityResult> results) {
  if (results.isEmpty ||
      results.every((ConnectivityResult r) => r == ConnectivityResult.none)) {
    return 0;
  }
  if (results.contains(ConnectivityResult.mobile)) {
    return 1;
  }
  if (results.contains(ConnectivityResult.wifi) ||
      results.contains(ConnectivityResult.ethernet)) {
    return 4;
  }
  return 1;
}

/// Computes closest-first neighbor indices (`+1, -1, +2, -2, ...`) around
/// [settledIndex] within `[0, itemCount)`. Never clamps out-of-range offsets.
List<int> forkViewerPreloadCandidateIndices({
  required int settledIndex,
  required int itemCount,
  required int radius,
}) {
  if (itemCount <= 1 || radius <= 0) {
    return const <int>[];
  }
  final List<int> indices = <int>[];
  for (int offset = 1; offset <= radius; offset++) {
    final int next = settledIndex + offset;
    if (next >= 0 && next < itemCount) {
      indices.add(next);
    }
    final int prev = settledIndex - offset;
    if (prev >= 0 && prev < itemCount) {
      indices.add(prev);
    }
  }
  return indices;
}

/// Handle returned to the foreground viewer when the user swipes onto the
/// neighbor currently being prefetched by [ForkMediaViewerPreloader].
class ForkPromotedTransfer {
  ForkPromotedTransfer({
    required this.url,
    required this.done,
    required this.cancelAndAwaitUnwind,
    required this.readDidCacheFresh,
    required this.readReceivedBytes,
    required this.readHeadersReceived,
    required this.readRateLimitUntil,
    required this.readNow,
  });

  final String url;
  final Future<void> done;
  final Future<void> Function() cancelAndAwaitUnwind;
  final bool Function() readDidCacheFresh;
  final int Function() readReceivedBytes;
  final bool Function() readHeadersReceived;
  final DateTime? Function() readRateLimitUntil;
  final DateTime Function() readNow;

  bool get didCacheFresh => readDidCacheFresh();
  int get receivedBytes => readReceivedBytes();
  bool get headersReceived => readHeadersReceived();
  DateTime? get rateLimitUntil => readRateLimitUntil();
  DateTime now() => readNow();
}

typedef ForkPreloadRadiusProvider = Future<int> Function();

Dio _createDefaultPreloaderDio() {
  return Dio(
    BaseOptions(
      connectTimeout: kForkViewerPreloadInactivityTimeout,
      receiveTimeout: kForkViewerPreloadInactivityTimeout,
      followRedirects: false,
      validateStatus: (int? status) =>
          status != null && status >= 200 && status < 400,
    ),
  )..interceptors.add(ForkCallSiteInterceptor());
}

Future<int> _defaultPreloadRadiusProvider() async {
  try {
    final List<ConnectivityResult> results = await Connectivity()
        .checkConnectivity();
    return forkPreloadRadiusForConnectivity(results);
  } on Object {
    return 1;
  }
}

/// Bounded, cancellable, closest-first disk preloader for
/// `AttachmentMediaViewerShell`.
///
/// - Enforces strict concurrency = 1 (slot held until cancelled transfer
///   unwinds in `finally`).
/// - Restricted strictly to non-API active-instance media-endpoint URLs
///   ([forkIsPreloadableMediaUrl]), rejecting API attachments and third-party
///   origins on both initial requests and `3xx` redirects.
/// - Streams chunks into a bounded in-memory [BytesBuilder] before
///   `BaseCacheManager.putFile` with a uniform 20 MiB per-item cap and a
///   50 MiB session byte budget (including promoted transfers and aborts),
///   avoiding `Directory.systemTemp` failures on Android and orphaned `.tmp`
///   files on crash.
/// - Honors RFC 9111 `Cache-Control: no-store` / `no-cache` / `max-age` / `Age`
///   and elapsed transfer time at write time.
class ForkMediaViewerPreloader {
  ForkMediaViewerPreloader({
    required this.items,
    required this.readHdrDisplayMode,
    BaseCacheManager? cacheManager,
    Dio? dio,
    ForkPreloadRadiusProvider? readPreloadRadius,
    this.readMediaEndpoint,
    DateTime Function()? now,
    this.maxBytesPerSession = kForkViewerPreloadMaxBytesPerSession,
    this.maxSingleItemBytes = kForkViewerPreloadMaxSingleItemBytes,
    this.inactivityTimeout = kForkViewerPreloadInactivityTimeout,
    this.min429Cooldown = kForkViewerPreloadMin429Cooldown,
    this.maxForegroundRateLimitHold = kForkViewerForegroundMaxRateLimitHold,
    this.cancelCleanupTimeout = kForkStreamCancelTimeout,
  }) : _cacheManager =
           cacheManager ?? CachedNetworkImageProvider.defaultCacheManager,
       _dio = dio ?? _createDefaultPreloaderDio(),
       _ownsDio = dio == null,
       _readPreloadRadius = readPreloadRadius ?? _defaultPreloadRadiusProvider,
       _now = now ?? DateTime.now {
    forkEnsureResponseCleanupAdapter(_dio);
  }

  final List<AttachmentMediaViewerItem> items;
  final HdrDisplayMode Function() readHdrDisplayMode;
  final BaseCacheManager _cacheManager;
  final Dio _dio;
  final bool _ownsDio;
  final ForkPreloadRadiusProvider _readPreloadRadius;
  final String? Function()? readMediaEndpoint;
  final DateTime Function() _now;
  final int maxBytesPerSession;
  final int maxSingleItemBytes;
  final Duration inactivityTimeout;
  final Duration min429Cooldown;
  final Duration maxForegroundRateLimitHold;
  final Duration cancelCleanupTimeout;

  bool _disposed = false;
  bool _sessionAborted = false;
  DateTime? _cooldownUntil;
  final Map<String, DateTime> _foregroundHoldUntilByUrl = <String, DateTime>{};
  int _epoch = 0;
  int _spentBytes = 0;
  int _consecutive404s = 0;
  final Set<String> _completedUrls = <String>{};
  final Set<String> _failedUrls = <String>{};

  _ActiveTransfer? _active;
  Future<void>? _pumpFuture;
  int? _pendingSettledIndex;
  int? _lastScheduledIndex;
  bool _lastScheduleCompleted = false;
  int _lastKnownRadius = 4;

  int get spentBytes => _spentBytes;

  /// Returns any remaining foreground rate-limit hold for [url] recorded when a
  /// speculative or promoted request for [url] received a `429`, bounded by
  /// [maxForegroundRateLimitHold] so swiping away and back preserves the hold
  /// consistently without blocking foreground retry indefinitely.
  Duration? remainingForegroundRateLimitHold(String url) {
    final DateTime? until = _foregroundHoldUntilByUrl[url];
    if (until == null) {
      return null;
    }
    final Duration remaining = until.difference(_now());
    if (remaining <= Duration.zero) {
      _foregroundHoldUntilByUrl.remove(url);
      return null;
    }
    return remaining;
  }

  bool _isCandidateUrlFor(int settledIndex, String targetUrl) {
    if (_lastKnownRadius <= 0 || targetUrl.isEmpty) {
      return false;
    }
    final HdrDisplayMode mode = readHdrDisplayMode();
    final List<int> candidates = forkViewerPreloadCandidateIndices(
      settledIndex: settledIndex,
      itemCount: items.length,
      radius: _lastKnownRadius,
    );
    for (final int index in candidates) {
      if (forkViewerImageUrl(items[index], mode) == targetUrl) {
        return true;
      }
    }
    return false;
  }

  /// Called when [settledIndex] is settled and its foreground full-res image
  /// has finished loading (or completed terminally).
  ///
  /// Idempotent for the same [settledIndex] while its pass is already running
  /// or finished (unless interrupted by navigation or paused for a cooldown
  /// that has since expired). Preserves an already-running speculative transfer
  /// when its URL belongs to [settledIndex]'s candidate window (e.g. after a
  /// cancelled/reversed drag returning to the same page).
  void scheduleAround(int settledIndex) {
    if (_disposed || _sessionAborted || items.length <= 1) {
      return;
    }
    if (settledIndex < 0 || settledIndex >= items.length) {
      return;
    }
    final DateTime? cooldownUntil = _cooldownUntil;
    if (cooldownUntil != null && _now().isBefore(cooldownUntil)) {
      return;
    }
    if (settledIndex == _lastScheduledIndex &&
        (_pumpFuture != null || _lastScheduleCompleted)) {
      return;
    }
    _lastScheduledIndex = settledIndex;
    _lastScheduleCompleted = false;
    _pendingSettledIndex = settledIndex;
    _epoch += 1;
    final _ActiveTransfer? active = _active;
    if (active != null &&
        !active.promoted &&
        !_isCandidateUrlFor(settledIndex, active.url)) {
      active.cancelToken.cancel('rescheduled');
    }
    _pumpFuture ??= _runLoop();
  }

  /// Pauses launching new speculative candidates while the user is actively
  /// dragging without cancelling an already-running transfer whose destination
  /// is not yet known (so swiping onto a prefetched neighbor can promote it).
  void pauseSpeculation() {
    if (_disposed) {
      return;
    }
    _epoch += 1;
    _pendingSettledIndex = null;
    _lastScheduledIndex = null;
    _lastScheduleCompleted = false;
  }

  /// Called when the user navigates toward a known [nextTargetUrl] (or settles
  /// on a destination). Obsolete speculative work aborts immediately; if
  /// [nextTargetUrl] matches the active transfer, it is kept alive for
  /// promotion via [promoteInFlight].
  void onNavigationStarted({String? nextTargetUrl}) {
    if (_disposed) {
      return;
    }
    _epoch += 1;
    _pendingSettledIndex = null;
    _lastScheduledIndex = null;
    _lastScheduleCompleted = false;
    final _ActiveTransfer? active = _active;
    if (active != null &&
        !active.promoted &&
        (nextTargetUrl == null || active.url != nextTargetUrl)) {
      active.cancelToken.cancel('navigated_away');
    }
  }

  /// Promotes an active speculative transfer for [url] to foreground ownership
  /// so the foreground awaits the same HTTP download without duplicating it.
  ForkPromotedTransfer? promoteInFlight(String url) {
    final _ActiveTransfer? active = _active;
    if (active == null ||
        active.promoted ||
        active.url != url ||
        active.cancelToken.isCancelled) {
      return null;
    }
    active.promoted = true;
    return ForkPromotedTransfer(
      url: url,
      done: active.completer.future,
      cancelAndAwaitUnwind: () async {
        if (!active.cancelToken.isCancelled) {
          active.cancelToken.cancel('foreground_fallback');
        }
        await active.completer.future;
      },
      readDidCacheFresh: () => active.didCacheFresh,
      readReceivedBytes: () => active.receivedBytes,
      readHeadersReceived: () => active.headersReceived,
      readRateLimitUntil: () => active.rateLimitUntil,
      readNow: _now,
    );
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _epoch += 1;
    _pendingSettledIndex = null;
    _lastScheduledIndex = null;
    _lastScheduleCompleted = false;
    final _ActiveTransfer? active = _active;
    if (active != null && !active.cancelToken.isCancelled) {
      active.cancelToken.cancel('disposed');
    }
    if (_ownsDio) {
      _dio.close(force: true);
    }
  }

  Future<void> _runLoop() async {
    try {
      while (!_disposed && !_sessionAborted) {
        final int? settledIndex = _pendingSettledIndex;
        if (settledIndex == null) {
          break;
        }
        final int runEpoch = _epoch;
        _pendingSettledIndex = null;

        final _ActiveTransfer? prior = _active;
        if (prior != null) {
          await prior.completer.future;
          if (_disposed || _sessionAborted || runEpoch != _epoch) {
            continue;
          }
        }

        final DateTime? cooldownUntil = _cooldownUntil;
        if (cooldownUntil != null && _now().isBefore(cooldownUntil)) {
          _lastScheduledIndex = null;
          break;
        }
        if (_spentBytes >= maxBytesPerSession) {
          break;
        }

        final int radius = await _readPreloadRadius();
        _lastKnownRadius = radius;
        if (_disposed || _sessionAborted || runEpoch != _epoch) {
          continue;
        }
        if (radius <= 0) {
          break;
        }

        final List<int> candidates = forkViewerPreloadCandidateIndices(
          settledIndex: settledIndex,
          itemCount: items.length,
          radius: radius,
        );
        bool pausedByCooldown = false;
        for (final int index in candidates) {
          if (_disposed || _sessionAborted || runEpoch != _epoch) {
            break;
          }
          final DateTime? activeCooldown = _cooldownUntil;
          if (activeCooldown != null && _now().isBefore(activeCooldown)) {
            pausedByCooldown = true;
            break;
          }
          if (_spentBytes >= maxBytesPerSession) {
            break;
          }

          final AttachmentMediaViewerItem item = items[index];
          // Mature media is never fetched ahead of the user seeing it.
          if (forkIsExplicitlyAnimatedViewerItem(item) || item.isMatureMedia) {
            continue;
          }

          final HdrDisplayMode mode = readHdrDisplayMode();
          final String url = forkViewerImageUrl(item, mode);
          if (url.isEmpty ||
              _completedUrls.contains(url) ||
              _failedUrls.contains(url)) {
            continue;
          }
          if (isSvgImageMedia(
            url: url,
            filename: item.filename,
            contentType: item.contentType,
          )) {
            continue;
          }
          final String? mediaEndpoint = readMediaEndpoint?.call();
          if (!forkIsPreloadableMediaUrl(
            url,
            mediaEndpoint: mediaEndpoint,
            contentType: item.contentType,
            filename: item.filename,
          )) {
            continue;
          }

          // Pre-admission byte checks when attachment size metadata is known.
          final int? knownSize = item.forkSizeBytes;
          if (knownSize != null && knownSize > 0) {
            if (knownSize > maxSingleItemBytes ||
                _spentBytes + knownSize > maxBytesPerSession) {
              continue;
            }
          }

          // Freshness-verified disk cache check (skip only when fresh).
          // Stop session speculation cleanly if the disk cache is unavailable.
          FileInfo? cached;
          try {
            cached = await _cacheManager.getFileFromCache(url);
          } on Object {
            _sessionAborted = true;
            break;
          }
          if (_disposed || _sessionAborted || runEpoch != _epoch) {
            break;
          }
          if (cached != null && cached.validTill.isAfter(_now())) {
            _completedUrls.add(url);
            continue;
          }

          await _downloadSingle(url: url, mediaEndpoint: mediaEndpoint);
          final DateTime? postCooldown = _cooldownUntil;
          if (postCooldown != null && _now().isBefore(postCooldown)) {
            pausedByCooldown = true;
            break;
          }
        }
        if (pausedByCooldown) {
          _lastScheduledIndex = null;
          _lastScheduleCompleted = false;
        } else if (!_disposed &&
            !_sessionAborted &&
            runEpoch == _epoch &&
            settledIndex == _lastScheduledIndex) {
          _lastScheduleCompleted = true;
        }
      }
    } on Object {
      _sessionAborted = true;
    } finally {
      _pumpFuture = null;
      if (!_disposed && !_sessionAborted && _pendingSettledIndex != null) {
        _pumpFuture = _runLoop();
      }
    }
  }

  Future<void> _downloadSingle({
    required String url,
    required String? mediaEndpoint,
  }) async {
    final _ActiveTransfer transfer = _ActiveTransfer(
      url: url,
      cancelToken: CancelToken(),
    );
    _active = transfer;
    Timer? inactivityTimer;
    void resetInactivityTimer() {
      inactivityTimer?.cancel();
      inactivityTimer = Timer(inactivityTimeout, () {
        if (!transfer.cancelToken.isCancelled) {
          transfer.cancelToken.cancel('inactivity_timeout');
        }
      });
    }

    try {
      resetInactivityTimer();
      final DateTime requestStart = _now();
      Response<ResponseBody> response = await _dio.get<ResponseBody>(
        url,
        cancelToken: transfer.cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: false,
          receiveTimeout: inactivityTimeout,
          validateStatus: (int? status) =>
              status != null && status >= 200 && status < 400,
        ),
      );

      // Permit at most one redirect, strictly within forkIsPreloadableMediaUrl.
      if (response.statusCode != null &&
          response.statusCode! >= 300 &&
          response.statusCode! < 400) {
        final String? location = response.headers.value('location');
        final bool redirectCleaned = await _cleanupResponse(
          response.requestOptions,
          response.data,
        );
        if (!redirectCleaned ||
            _sessionAborted ||
            transfer.cancelToken.isCancelled) {
          if (!transfer.promoted && !transfer.cancelToken.isCancelled) {
            _failedUrls.add(url);
          }
          return;
        }
        if (location == null || location.trim().isEmpty) {
          if (!transfer.promoted) {
            _failedUrls.add(url);
          }
          return;
        }
        final String resolvedLocation = Uri.parse(
          url,
        ).resolve(location.trim()).toString();
        if (!forkIsPreloadableMediaUrl(
          resolvedLocation,
          mediaEndpoint: mediaEndpoint,
        )) {
          if (!transfer.promoted) {
            _failedUrls.add(url);
          }
          return;
        }
        resetInactivityTimer();
        response = await _dio.get<ResponseBody>(
          resolvedLocation,
          cancelToken: transfer.cancelToken,
          options: Options(
            responseType: ResponseType.stream,
            followRedirects: false,
            receiveTimeout: inactivityTimeout,
            validateStatus: (int? status) =>
                status != null && status >= 200 && status < 300,
          ),
        );
      }

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        await _cleanupResponse(response.requestOptions, response.data);
        if (!transfer.promoted) {
          _failedUrls.add(url);
        }
        return;
      }

      transfer.headersReceived = true;
      resetInactivityTimer();

      final ResponseBody? body = response.data;
      if (body == null) {
        if (!transfer.promoted) {
          _failedUrls.add(url);
        }
        return;
      }

      // Check Cache-Control before reading payload if possible.
      final _Cacheability cacheability = _parseCacheability(response.headers);
      if (cacheability.noStoreOrNoCache) {
        _failedUrls.add(url);
        transfer.cancelToken.cancel('no_store');
        await _cleanupResponse(response.requestOptions, body);
        return;
      }

      // Check Content-Length header before streaming (uniform caps even when promoted).
      final int? contentLength = int.tryParse(
        response.headers.value(Headers.contentLengthHeader) ?? '',
      );
      if (contentLength != null && contentLength > 0) {
        if (contentLength > maxSingleItemBytes) {
          _failedUrls.add(url);
          transfer.cancelToken.cancel('content_length_exceeds_single_item_cap');
          await _cleanupResponse(response.requestOptions, body);
          return;
        }
        if (_spentBytes + contentLength > maxBytesPerSession) {
          transfer.cancelToken.cancel('content_length_exceeds_budget');
          await _cleanupResponse(response.requestOptions, body);
          return;
        }
      }

      final BytesBuilder buffer = BytesBuilder(copy: false);
      int received = 0;
      bool aborted = false;
      bool exceededSingleItemCap = false;
      Future<void>? cancelSubFuture;
      final Completer<void> streamDone = Completer<void>();
      late final StreamSubscription<Uint8List> sub;
      sub = body.stream.listen(
        (Uint8List chunk) {
          resetInactivityTimer();
          received += chunk.length;
          transfer.receivedBytes = received;
          _spentBytes += chunk.length;
          if (received > maxSingleItemBytes ||
              _spentBytes > maxBytesPerSession ||
              transfer.cancelToken.isCancelled) {
            aborted = true;
            if (received > maxSingleItemBytes) {
              exceededSingleItemCap = true;
            }
            if (!transfer.cancelToken.isCancelled) {
              transfer.cancelToken.cancel('stream_budget_exceeded');
            }
            cancelSubFuture ??= sub.cancel();
            if (!streamDone.isCompleted) {
              streamDone.complete();
            }
            return;
          }
          buffer.add(chunk);
        },
        onError: (Object error, StackTrace stack) {
          aborted = true;
          if (!streamDone.isCompleted) {
            streamDone.completeError(error, stack);
          }
        },
        onDone: () {
          if (!streamDone.isCompleted) {
            streamDone.complete();
          }
        },
        cancelOnError: true,
      );

      unawaited(
        transfer.cancelToken.whenCancel.then((_) {
          aborted = true;
          cancelSubFuture ??= sub.cancel();
          if (!streamDone.isCompleted) {
            streamDone.complete();
          }
        }),
      );

      await streamDone.future;
      inactivityTimer?.cancel();
      if (aborted ||
          transfer.cancelToken.isCancelled ||
          cancelSubFuture != null) {
        await _cleanupResponse(response.requestOptions, body);
      }

      if (exceededSingleItemCap) {
        _failedUrls.add(url);
      }
      if (aborted ||
          transfer.cancelToken.isCancelled ||
          received == 0 ||
          received > maxSingleItemBytes ||
          _spentBytes > maxBytesPerSession) {
        return;
      }

      // Compute RFC 9111 remaining freshness at write time.
      final Duration? remainingFreshness = cacheability.remainingFreshnessAt(
        requestStart: requestStart,
        writeTime: _now(),
      );
      if (remainingFreshness == null) {
        // Remaining lifetime <= 0: skip cache admission and do not re-fetch.
        _failedUrls.add(url);
        return;
      }

      final Uint8List fileBytes = buffer.takeBytes();
      await _cacheManager.putFile(
        url,
        fileBytes,
        key: url,
        eTag: response.headers.value('etag'),
        maxAge: remainingFreshness,
        fileExtension: _extensionFromUrl(url),
      );
      _consecutive404s = 0;
      _completedUrls.add(url);
      transfer.didCacheFresh = true;
    } on DioException catch (error) {
      inactivityTimer?.cancel();
      final bool wasCancelledBeforeError =
          CancelToken.isCancel(error) || transfer.cancelToken.isCancelled;
      if (!wasCancelledBeforeError) {
        _handleHttpError(url, error, transfer: transfer);
      }
      final Object? errData = error.response?.data;
      await _cleanupResponse(
        error.requestOptions,
        errData is ResponseBody ? errData : null,
      );
      if (wasCancelledBeforeError) {
        return;
      }
    } on Object {
      if (!transfer.promoted && !transfer.cancelToken.isCancelled) {
        _failedUrls.add(url);
      }
    } finally {
      inactivityTimer?.cancel();
      if (identical(_active, transfer)) {
        _active = null;
      }
      if (!transfer.completer.isCompleted) {
        transfer.completer.complete();
      }
    }
  }

  void _handleHttpError(
    String url,
    DioException error, {
    required _ActiveTransfer transfer,
  }) {
    final int? status = error.response?.statusCode;
    // Session-wide auth & rate-limit backoffs apply even if the transfer was
    // promoted to foreground while in flight.
    if (status == 401 || status == 403) {
      _sessionAborted = true;
      _failedUrls.add(url);
      return;
    }
    if (status == 429) {
      final Duration cooldown = _parseRetryAfter(error.response?.headers);
      final DateTime now = _now();
      _cooldownUntil = now.add(cooldown);
      final Duration fgCooldown = cooldown > maxForegroundRateLimitHold
          ? maxForegroundRateLimitHold
          : cooldown;
      final DateTime fgUntil = now.add(fgCooldown);
      _foregroundHoldUntilByUrl[url] = fgUntil;
      transfer.rateLimitUntil = fgUntil;
      _epoch += 1;
      _pendingSettledIndex = null;
      _lastScheduledIndex = null;
      _lastScheduleCompleted = false;
      _failedUrls.add(url);
      return;
    }
    if (transfer.promoted) {
      return;
    }
    if (status == 404) {
      _consecutive404s += 1;
      _failedUrls.add(url);
      if (_consecutive404s >= kForkViewerPreloadMaxConsecutive404s) {
        _sessionAborted = true;
        _epoch += 1;
        _pendingSettledIndex = null;
        _lastScheduledIndex = null;
        _lastScheduleCompleted = false;
      }
      return;
    }
    _consecutive404s = 0;
    _failedUrls.add(url);
  }

  Duration _parseRetryAfter(Headers? headers) {
    final int? parsedMs = featureRetryAfterMs(headers: headers, now: _now);
    if (parsedMs != null && parsedMs > 0) {
      final Duration parsed = Duration(milliseconds: parsedMs);
      return parsed > min429Cooldown ? parsed : min429Cooldown;
    }
    return min429Cooldown;
  }

  Future<bool> _cleanupResponse(
    RequestOptions options,
    ResponseBody? fallbackBody,
  ) async {
    final bool confirmedClosed = await forkAwaitResponseCleanup(
      options,
      fallbackBody: fallbackBody,
      timeout: cancelCleanupTimeout,
    );
    if (!confirmedClosed) {
      _sessionAborted = true;
    }
    return confirmedClosed;
  }
}

class _ActiveTransfer {
  _ActiveTransfer({required this.url, required this.cancelToken});

  final String url;
  final CancelToken cancelToken;
  final Completer<void> completer = Completer<void>();
  bool promoted = false;
  bool didCacheFresh = false;
  bool headersReceived = false;
  DateTime? rateLimitUntil;
  int receivedBytes = 0;
}

class _Cacheability {
  const _Cacheability({
    required this.noStoreOrNoCache,
    required this.maxAgeSeconds,
    required this.ageSeconds,
  });

  final bool noStoreOrNoCache;
  final int? maxAgeSeconds;
  final int ageSeconds;

  Duration? remainingFreshnessAt({
    required DateTime requestStart,
    required DateTime writeTime,
  }) {
    if (noStoreOrNoCache) {
      return null;
    }
    final int? maxAge = maxAgeSeconds;
    if (maxAge == null) {
      return kNetworkImageDiskCacheStalePeriod;
    }
    final int elapsedSecs = writeTime.difference(requestStart).inSeconds;
    final int clampedElapsed = elapsedSecs > 0 ? elapsedSecs : 0;
    final int remainingSecs = maxAge - ageSeconds - clampedElapsed;
    if (remainingSecs <= 0) {
      return null;
    }
    final Duration remaining = Duration(seconds: remainingSecs);
    return remaining > kNetworkImageDiskCacheStalePeriod
        ? kNetworkImageDiskCacheStalePeriod
        : remaining;
  }
}

_Cacheability _parseCacheability(Headers headers) {
  final List<String>? ccValues = headers['cache-control'];
  bool noStoreOrNoCache = false;
  int? maxAgeSeconds;
  if (ccValues != null) {
    for (final String header in ccValues) {
      for (final String rawDirective in header.split(',')) {
        final String directive = rawDirective.trim().toLowerCase();
        if (directive == 'no-store' || directive == 'no-cache') {
          noStoreOrNoCache = true;
        } else if (directive.startsWith('max-age=')) {
          final int? parsed = int.tryParse(
            directive.substring('max-age='.length).trim(),
          );
          if (parsed != null) {
            maxAgeSeconds = parsed;
          }
        }
      }
    }
  }
  final int ageSeconds =
      int.tryParse(headers.value('age')?.trim() ?? '')?.clamp(0, 1 << 30) ?? 0;
  return _Cacheability(
    noStoreOrNoCache: noStoreOrNoCache,
    maxAgeSeconds: maxAgeSeconds,
    ageSeconds: ageSeconds,
  );
}

String _extensionFromUrl(String url) {
  final Uri? uri = Uri.tryParse(url);
  if (uri == null || uri.pathSegments.isEmpty) {
    return 'file';
  }
  final String last = uri.pathSegments.last;
  final int dot = last.lastIndexOf('.');
  if (dot <= 0 || dot >= last.length - 1) {
    return 'file';
  }
  final String ext = last.substring(dot + 1).toLowerCase();
  if (RegExp(r'^[a-z0-9]{1,8}$').hasMatch(ext)) {
    return ext;
  }
  return 'file';
}
