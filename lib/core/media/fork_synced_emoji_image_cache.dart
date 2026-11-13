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
//
// It also loads animated avatars, server icons and banners with that completer
// (tyne-chat/tyne#619), on a clock of their own. Upstream's completer asks for
// two app frames per image frame: one as soon as the next frame is decoded,
// only to read the frame's timestamp, and one when the frame is due. This one
// decodes ahead and wakes when the frame is due, so a 50-frames-a-second
// banner costs 50 app frames a second rather than 100.

import 'dart:ui' as ui;

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:fluxer_app/core/media/fork_gif_first_frame_alpha.dart';
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

/// Whether [url] is an animated avatar, server icon or banner from the media
/// proxy: `.../avatars|icons|banners/<id>/<file>?animated=true...`, as
/// `FluxerMediaUrl` builds them. Persona avatars and tag icons use the avatar
/// form (tyne-chat/tyne#619).
bool isForkAnimatedProfileMediaUrl(String url) {
  final Uri? uri = Uri.tryParse(url);
  if (uri == null) {
    return false;
  }
  final List<String> segments = uri.pathSegments;
  return segments.length >= 3 &&
      const <String>{
        'avatars',
        'icons',
        'banners',
      }.contains(segments[segments.length - 3]) &&
      uri.queryParameters['animated'] == 'true';
}

/// Whether the cache loads [provider] with the fork's completer on the
/// profile-media clock: as for emoji, only full-size images meant to animate.
bool isForkAnimatedProfileMediaProvider(CachedNetworkImageProvider provider) =>
    provider.animate &&
    provider.maxWidth == null &&
    provider.maxHeight == null &&
    isForkAnimatedProfileMediaUrl(provider.url);

class ForkSyncedEmojiImageCache extends ImageCache {
  ForkSyncedEmojiImageCache({
    ForkSyncedEmojiClock? clock,
    ForkSyncedEmojiDecoder? decode,
  }) : _clock = clock ?? ForkSyncedEmojiClock.instance,
       _decode = decode ?? _decodeWithBinding;

  final ForkSyncedEmojiClock _clock;
  final ForkSyncedEmojiDecoder _decode;

  // Avatars, icons and banners keep their own clock: in step with each other
  // where their loops match, not with the emoji.
  final ForkSyncedEmojiClock _profileMediaClock = ForkSyncedEmojiClock();

  @override
  ImageStreamCompleter? putIfAbsent(
    Object key,
    ImageStreamCompleter Function() loader, {
    ImageErrorListener? onError,
  }) {
    if (key is CachedNetworkImageProvider) {
      if (isForkSyncedEmojiProvider(key)) {
        return super.putIfAbsent(
          key,
          () => _load(key, _clock),
          onError: onError,
        );
      }
      if (isForkAnimatedProfileMediaProvider(key)) {
        return super.putIfAbsent(
          key,
          () => _load(key, _profileMediaClock),
          onError: onError,
        );
      }
    }
    return super.putIfAbsent(key, loader, onError: onError);
  }

  ImageStreamCompleter _load(
    CachedNetworkImageProvider key,
    ForkSyncedEmojiClock clock,
  ) {
    final ForkSyncedEmojiCompleter completer = ForkSyncedEmojiCompleter(
      codecs: _loadCodecs(key),
      scale: key.scale,
      minimumFrameDuration: key.minimumGifFrameDuration,
      clock: clock,
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
      // An opaque frame 0 stops Flutter before 3.50 (tyne-chat/tyne#615).
      yield await _decode(forkGifWithTransparentFirstFrame(bytes));
    }
  }
}

Future<ui.Codec> _decodeWithBinding(Uint8List bytes) async {
  final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(
    bytes,
  );
  return PaintingBinding.instance.instantiateImageCodecWithSize(buffer);
}
