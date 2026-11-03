// Fork: the image cache that keeps animated custom emoji in step
// (tyne-chat/tyne#91).
//
// Upstream draws animated custom emoji in several places (messages, reactions,
// the picker, the composer, sheets, settings), each with a
// `CachedNetworkImage`. Rather than a hook in each, the app's binding installs
// this cache (`FluxerAppZoomBinding.createImageCache`). It recognises those
// images by their URL and loads them with `ForkSyncedEmojiCompleter`, from the
// same disk-cache entry `cached_network_image_ce` would read, so no extra
// downloads; every other image takes Flutter's path unchanged. If upstream
// changes how it builds those images, the guard tests in
// `test/core/media/fork_synced_emoji_image_cache_test.dart` fail; at runtime
// the emoji fall back to upstream's behaviour.

import 'dart:ui' as ui;

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:fluxer_app/core/media/fork_synced_emoji_clock.dart';
import 'package:fluxer_app/core/media/fork_synced_emoji_completer.dart';

/// Decodes the bytes of an image file into a codec.
typedef ForkSyncedEmojiDecoder = Future<ui.Codec> Function(Uint8List bytes);

/// Whether [url] is an animated custom emoji from the media proxy:
/// `.../emojis/<id>.<ext>?animated=true...`, as `FluxerMediaUrl.customEmoji`
/// builds it.
bool isForkSyncedEmojiUrl(String url) {
  final Uri? uri = Uri.tryParse(url);
  if (uri == null) {
    return false;
  }
  final List<String> segments = uri.pathSegments;
  return segments.length >= 2 &&
      segments[segments.length - 2] == 'emojis' &&
      uri.queryParameters['animated'] == 'true';
}

/// Whether the cache loads [provider] with the shared clocks. Images decoded at
/// a reduced size, or not meant to animate, keep upstream's loading.
bool isForkSyncedEmojiProvider(CachedNetworkImageProvider provider) =>
    provider.animate &&
    provider.maxWidth == null &&
    provider.maxHeight == null &&
    isForkSyncedEmojiUrl(provider.url);

class ForkSyncedEmojiImageCache extends ImageCache {
  ForkSyncedEmojiImageCache({
    ForkSyncedEmojiClock? clock,
    ForkSyncedEmojiDecoder? decode,
  }) : _clock = clock ?? ForkSyncedEmojiClock.instance,
       _decode = decode ?? _decodeWithBinding;

  final ForkSyncedEmojiClock _clock;
  final ForkSyncedEmojiDecoder _decode;

  @override
  ImageStreamCompleter? putIfAbsent(
    Object key,
    ImageStreamCompleter Function() loader, {
    ImageErrorListener? onError,
  }) {
    if (key is! CachedNetworkImageProvider || !isForkSyncedEmojiProvider(key)) {
      return super.putIfAbsent(key, loader, onError: onError);
    }
    return super.putIfAbsent(key, () => _load(key), onError: onError);
  }

  ImageStreamCompleter _load(CachedNetworkImageProvider key) {
    final ForkSyncedEmojiCompleter completer = ForkSyncedEmojiCompleter(
      codecs: _loadCodecs(key),
      scale: key.scale,
      minimumFrameDuration: key.minimumGifFrameDuration,
      clock: _clock,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', key),
      ],
      // As upstream's provider does: a failed load is not kept, so the image
      // can load again the next time a widget asks for it.
      onLoadFailed: () => evict(key),
    );
    final void Function(Object)? errorListener = key.errorListener;
    if (errorListener != null) {
      completer.addEphemeralErrorListener(
        (Object error, StackTrace? stack) => errorListener(error),
      );
    }
    return completer;
  }

  // The file `cached_network_image_ce` reads for the same provider: same URL,
  // cache key, headers and cache manager.
  Stream<ui.Codec> _loadCodecs(CachedNetworkImageProvider key) async* {
    final BaseCacheManager cacheManager =
        key.cacheManager ?? CachedNetworkImageProvider.defaultCacheManager;
    final Stream<FileResponse> files = cacheManager.getFileStream(
      key.url,
      key: key.cacheKey,
      headers: key.headers,
      withProgress: false,
    );
    await for (final FileResponse response in files) {
      if (response is! FileInfo) {
        continue;
      }
      final Uint8List bytes = await response.file.readAsBytes();
      final String? unsupported = ImageFormatDetector.detectUnsupportedFormat(
        bytes,
      );
      if (unsupported != null) {
        throw UnsupportedImageFormatException(
          bytes: bytes,
          url: key.url,
          detectedFormat: unsupported,
        );
      }
      yield await _decode(bytes);
    }
  }
}

Future<ui.Codec> _decodeWithBinding(Uint8List bytes) async {
  final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(
    bytes,
  );
  return PaintingBinding.instance.instantiateImageCodecWithSize(buffer);
}
