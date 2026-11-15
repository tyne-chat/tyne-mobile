// Fork: a sticker keeps the uploaded file when it fits the limits, instead of
// being squared to 320×320 and re-encoded (tyne-chat/tyne#658). The media proxy
// scales stickers for display, keeping their shape (tyne-chat/tyne#659), so the
// stored original costs only storage. A still image over the limits is shrunk,
// keeping its shape, to the largest size up to [kForkStickerMaxSide] whose PNG
// fits the byte limit. Animated stickers and SVGs go through upstream's
// optimizer, which sends them as they are or refuses them. The web app does the
// same (ForkStickerUpload.ts), except that it compresses an image that is too
// heavy to a lossy WebP at its size; the image package encodes no lossy WebP,
// so the phone shrinks such an image instead.
import 'dart:convert';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fluxer_app/features/settings/utils/expressions/expression_image_optimizer.dart';
import 'package:fluxer_app/shared/utils/image_utils.dart';
import 'package:image/image.dart' as img;

/// The largest side a sticker keeps. The sticker settings text says 2048 too.
const int kForkStickerMaxSide = 2048;

/// The smallest longer side a shrunk sticker is tried at before giving up.
const int _kMinSide = 128;

/// The sticker image to send, base64-encoded as the create request takes it.
Future<String> forkPrepareGuildStickerImage({
  required Uint8List bytes,
  required int maxSizeBytes,
}) async {
  if (isSvgBytes(bytes) || ImageUtils.checkAnimated(bytes).isAnimated) {
    return optimizeGuildStickerImage(bytes: bytes, maxSizeBytes: maxSizeBytes);
  }
  final img.Decoder? decoder = img.findDecoderForData(bytes);
  final img.DecodeInfo? info = decoder?.startDecode(bytes);
  final bool withinSide =
      info == null || math.max(info.width, info.height) <= kForkStickerMaxSide;
  // A format the image package cannot read (AVIF) is the server's to accept
  // or refuse when it fits the byte limit.
  if (withinSide && bytes.length <= maxSizeBytes) {
    return base64Encode(bytes);
  }
  final Uint8List? png = await Isolate.run(
    () => forkShrinkStickerToFit(bytes, maxSizeBytes),
  );
  if (png == null) {
    throw ExpressionImageOptimizationException(
      reason: ExpressionImageOptimizationReason.processed,
      actualSizeBytes: bytes.length,
      maxSizeBytes: maxSizeBytes,
    );
  }
  return base64Encode(png);
}

/// [bytes] as a PNG, upright and shrunk with its shape kept to the largest
/// longer side up to [kForkStickerMaxSide] whose PNG is at most [maxSizeBytes],
/// trying sides 15% apart. Null if it cannot be decoded, or if no side down to
/// 128 px fits.
Uint8List? forkShrinkStickerToFit(Uint8List bytes, int maxSizeBytes) {
  final img.Image? decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return null;
  }
  final img.Image upright = img.bakeOrientation(decoded);
  final int longest = math.max(upright.width, upright.height);
  final int smallest = math.min(_kMinSide, longest);
  for (
    int side = math.min(longest, kForkStickerMaxSide);
    side >= smallest;
    side = (side * 0.85).floor()
  ) {
    final double scale = side / longest;
    final img.Image sized = side == longest
        ? upright
        : img.copyResize(
            upright,
            width: math.max(1, (upright.width * scale).round()),
            height: math.max(1, (upright.height * scale).round()),
            interpolation: img.Interpolation.cubic,
          );
    final Uint8List png = img.encodePng(sized);
    if (png.length <= maxSizeBytes) {
      return png;
    }
  }
  return null;
}
