import 'dart:math' as math;

import 'package:fluxer_app/core/api/attachment_request_auth.dart';
import 'package:fluxer_app/core/api/session_auth_interceptor.dart';
import 'package:fluxer_app/core/instance/instance_endpoints.dart';
import 'package:fluxer_app/features/chat/utils/attachments/attachment_display_utils.dart';
import 'package:fluxer_app/features/chat/utils/media/hdr_aware_image_url.dart';

/// Shared media-proxy image size ladder.
///
/// Must stay identical to:
/// - `fluxer/packages/constants/src/MediaProxyImageSizes.ts`
/// - `fluxer/fluxer_media_proxy/src/constants.rs` (`IMAGE_SIZES`)
/// Verified by `test/features/chat/utils/media/fork_media_proxy_sizing_test.dart`.
const List<int> kForkMediaProxyImageSizes = <int>[
  16,
  20,
  22,
  24,
  28,
  32,
  40,
  44,
  48,
  56,
  60,
  64,
  80,
  96,
  100,
  128,
  160,
  240,
  256,
  300,
  320,
  480,
  512,
  600,
  640,
  1024,
  1280,
  1536,
  2048,
  3072,
  4096,
  8192,
  16384,
];

const int kForkMediaProxyMaxDimension = 16384;
const int kForkApiAttachmentMaxDimension = 8192;
const double _kMediaProxyDownscaleTolerance = 1.1;
const double _kMediaProxyDownscaleMinDpr = 2;

const Set<String> _kOwnedTransformParams = <String>{
  'width',
  'height',
  'format',
  'fmt',
  'quality',
  'animated',
};

const Set<String> _kServerTransformParams = <String>{
  'width',
  'height',
  'format',
  'fmt',
  'quality',
  'effort',
  'animated',
};

/// Sanitizes [devicePixelRatio], matching web's `mediaDevicePixelRatio()`.
double forkSanitizeDevicePixelRatio(double devicePixelRatio) {
  if (!devicePixelRatio.isFinite || devicePixelRatio <= 0) {
    return 1;
  }
  return devicePixelRatio;
}

/// Snaps [logicalPixels] * [devicePixelRatio] onto [kForkMediaProxyImageSizes].
int forkSnapMediaProxyImageSize(
  double logicalPixels,
  double devicePixelRatio, {
  bool allowDownscale = false,
  int maxDimension = kForkMediaProxyMaxDimension,
}) {
  final double safeDpr = forkSanitizeDevicePixelRatio(devicePixelRatio);
  final double safeLogical = logicalPixels.isFinite && logicalPixels > 0
      ? logicalPixels
      : 0;
  final double target = safeLogical * safeDpr;
  if (allowDownscale && safeDpr >= _kMediaProxyDownscaleMinDpr) {
    int? below;
    for (final int rung in kForkMediaProxyImageSizes) {
      if (rung > target) {
        break;
      }
      below = rung;
    }
    if (below != null && target / below <= _kMediaProxyDownscaleTolerance) {
      return math.min(below, maxDimension);
    }
  }
  for (final int rung in kForkMediaProxyImageSizes) {
    if (target <= rung) {
      return math.min(rung, maxDimension);
    }
  }
  return math.min(kForkMediaProxyImageSizes.last, maxDimension);
}

/// Resolves a single aspect-preserving `width` parameter for `fluxer_media_proxy`.
///
/// Always emits at most a single dimension (`width`) because `fluxer_media_proxy`
/// treats requests carrying both `width` and `height` as `ResizeMode::Cover`
/// (server-side center-cropping).
///
/// Returns `null` when dimensions are missing/non-positive or when no downscale
/// is needed.
int? forkResolveProxyRequestWidth({
  required double layoutWidth,
  required double layoutHeight,
  required double devicePixelRatio,
  required int? sourceWidth,
  required int? sourceHeight,
  bool cover = false,
  double? maxCoverAspectMultiplier,
  int maxDimension = kForkMediaProxyMaxDimension,
}) {
  if (sourceWidth == null ||
      sourceHeight == null ||
      sourceWidth <= 0 ||
      sourceHeight <= 0) {
    return null;
  }
  if (!layoutWidth.isFinite ||
      !layoutHeight.isFinite ||
      layoutWidth <= 0 ||
      layoutHeight <= 0) {
    return null;
  }
  double effectiveWidth = layoutWidth;
  double effectiveHeight = layoutHeight;
  if (cover) {
    effectiveWidth = math.max(
      layoutWidth,
      layoutHeight * sourceWidth / sourceHeight,
    );
    effectiveHeight = math.max(
      layoutHeight,
      layoutWidth * sourceHeight / sourceWidth,
    );
    if (maxCoverAspectMultiplier != null &&
        maxCoverAspectMultiplier.isFinite &&
        maxCoverAspectMultiplier > 0) {
      final double maxEdge =
          math.max(layoutWidth, layoutHeight) * maxCoverAspectMultiplier;
      effectiveWidth = math.min(effectiveWidth, maxEdge);
      effectiveHeight = math.min(effectiveHeight, maxEdge);
    }
  }
  final double longestLayoutEdge = math.max(effectiveWidth, effectiveHeight);
  final int snappedLongestEdge = forkSnapMediaProxyImageSize(
    longestLayoutEdge,
    devicePixelRatio,
    allowDownscale: true,
    maxDimension: maxDimension,
  );
  final int sourceLongestEdge = math.max(sourceWidth, sourceHeight);
  if (snappedLongestEdge >= sourceLongestEdge) {
    return null;
  }
  final int cap = math.min(sourceWidth, maxDimension);
  // Exact integer ceil-division avoids IEEE-754 +1 px overshoot on landscape images.
  final int width =
      ((sourceWidth * snappedLongestEdge + sourceLongestEdge - 1) ~/
              sourceLongestEdge)
          .clamp(1, cap);
  if (width >= sourceWidth) {
    return null;
  }
  return width;
}

bool _isHttpUri(Uri? uri) =>
    uri != null &&
    uri.hasScheme &&
    (uri.scheme == 'http' || uri.scheme == 'https') &&
    uri.host.isNotEmpty;

/// Whether [url] targets the active instance's media proxy endpoint.
bool forkIsMediaEndpointUrl(
  String url, {
  String? mediaEndpoint,
  String? contentType,
  String? filename,
}) {
  final String trimmed = url.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  final Uri? target = Uri.tryParse(trimmed);
  if (!_isHttpUri(target)) {
    return false;
  }
  if (isSvgImageMedia(
    url: trimmed,
    filename: filename,
    contentType: contentType,
  )) {
    return false;
  }
  final String rawBase = (mediaEndpoint ?? InstanceEndpoints.media).trim();
  final Uri? base = Uri.tryParse(rawBase);
  if (!_isHttpUri(base)) {
    return false;
  }
  return isRequestUnderBaseUrl(target!, base!);
}

/// Whether [url] is eligible for speculative background preloading.
///
/// Explicitly rejects authenticated API attachment URLs first (even when the
/// media endpoint shares a host/root path with the API attachment route), and
/// requires the active instance's media endpoint.
bool forkIsPreloadableMediaUrl(
  String url, {
  String? mediaEndpoint,
  String? contentType,
  String? filename,
}) {
  if (AttachmentRequestAuth.isApiAttachmentUrl(url)) {
    return false;
  }
  return forkIsMediaEndpointUrl(
    url,
    mediaEndpoint: mediaEndpoint,
    contentType: contentType,
    filename: filename,
  );
}

/// Whether [url] points to a Fluxer media proxy or trusted API attachment route
/// that accepts image transform query parameters.
bool forkIsTransformableMediaUrl(
  String url, {
  String? mediaEndpoint,
  String? contentType,
  String? filename,
}) {
  final String trimmed = url.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  final Uri? target = Uri.tryParse(trimmed);
  if (!_isHttpUri(target)) {
    return false;
  }
  if (isSvgImageMedia(
    url: trimmed,
    filename: filename,
    contentType: contentType,
  )) {
    return false;
  }
  if (AttachmentRequestAuth.isApiAttachmentUrl(trimmed)) {
    return true;
  }
  return forkIsMediaEndpointUrl(
    trimmed,
    mediaEndpoint: mediaEndpoint,
    contentType: contentType,
    filename: filename,
  );
}

/// Whether [url] already carries any server-recognized media transform query
/// parameter (matching `fluxer_media_proxy/src/server/params.rs:24-39`).
bool forkHasProxyTransformParams(String url) {
  final Uri? parsed = Uri.tryParse(url.trim());
  if (parsed == null) {
    return false;
  }
  for (final MapEntry<String, List<String>> entry
      in parsed.queryParametersAll.entries) {
    final String key = entry.key.toLowerCase();
    if (!_kServerTransformParams.contains(key)) {
      continue;
    }
    if (entry.value.any((String value) => value.trim().isNotEmpty)) {
      return true;
    }
  }
  return false;
}

/// Replaces owned transform parameters with `format=webp&quality=high&width=W`
/// while preserving all other query parameters (including multi-value keys).
String _replaceTransformParamsWithSizedWebp(String url, int width) {
  final Uri parsed = Uri.parse(url);
  final Map<String, List<String>> nextParams = <String, List<String>>{};
  for (final MapEntry<String, List<String>> entry
      in parsed.queryParametersAll.entries) {
    if (_kOwnedTransformParams.contains(entry.key.toLowerCase())) {
      continue;
    }
    nextParams[entry.key] = List<String>.from(entry.value);
  }
  nextParams['format'] = <String>['webp'];
  nextParams['quality'] = <String>['high'];
  nextParams['width'] = <String>[width.toString()];
  return parsed.replace(queryParameters: nextParams).toString();
}

/// Builds a single-width snapped WebP thumbnail URL for a Fluxer media/API URL.
///
/// - Direct external/non-transformable URLs are returned strictly verbatim.
/// - Confirmed animated URLs and images needing no downscale return
///   [fallbackUrl] unchanged so every call site preserves its pre-change URL.
/// - Downscaled static images on Fluxer endpoints emit
///   `format=webp&quality=high&width=<W>` (single dimension, never `height`)
///   in both `HdrDisplayMode.full` and `HdrDisplayMode.standard`.
String buildForkSizedThumbnailUrl({
  required String url,
  required String fallbackUrl,
  required double layoutWidth,
  required double layoutHeight,
  required double devicePixelRatio,
  required int? sourceWidth,
  required int? sourceHeight,
  String? contentType,
  String? filename,
  bool animated = false,
  bool cover = false,
  double? maxCoverAspectMultiplier,
  String? mediaEndpoint,
}) {
  if (url.isEmpty) {
    return url;
  }
  if (!forkIsTransformableMediaUrl(
    url,
    mediaEndpoint: mediaEndpoint,
    contentType: contentType,
    filename: filename,
  )) {
    return url;
  }
  if (animated || mediaProxyUrlIsAnimated(url)) {
    return fallbackUrl;
  }
  final int maxDimension = AttachmentRequestAuth.isApiAttachmentUrl(url)
      ? kForkApiAttachmentMaxDimension
      : kForkMediaProxyMaxDimension;
  final int? requestedWidth = forkResolveProxyRequestWidth(
    layoutWidth: layoutWidth,
    layoutHeight: layoutHeight,
    devicePixelRatio: devicePixelRatio,
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
    cover: cover,
    maxCoverAspectMultiplier: maxCoverAspectMultiplier,
    maxDimension: maxDimension,
  );
  if (requestedWidth == null) {
    return fallbackUrl;
  }
  return _replaceTransformParamsWithSizedWebp(url, requestedWidth);
}

final Expando<String> _forkOriginalDownloadUrls = Expando<String>(
  'forkOriginalDownloadUrls',
);

/// Attaches the original untransformed source URL (e.g. `EmbedMedia.url`) to
/// an [attachment] without altering its proxied `url` / `proxyUrl` fields.
void forkAttachOriginalDownloadUrl(Object attachment, String? originalUrl) {
  final String trimmed = originalUrl?.trim() ?? '';
  if (trimmed.isNotEmpty) {
    _forkOriginalDownloadUrls[attachment] = trimmed;
  }
}

/// Reads any original untransformed source URL previously attached via
/// [forkAttachOriginalDownloadUrl].
String? forkOriginalDownloadUrlOf(Object attachment) {
  return _forkOriginalDownloadUrls[attachment];
}
