// Fork: a sticker keeps the uploaded file when it fits the limits, and only an
// image over them is shrunk, keeping its shape (tyne-chat/tyne#658). Tests of
// fork_sticker_image.dart, next to upstream's expression_image_optimizer_test.
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/settings/utils/expressions/expression_image_optimizer.dart';
import 'package:fluxer_app/features/settings/utils/expressions/fork_sticker_image.dart';
import 'package:image/image.dart' as img;

const int _limit = 512 * 1024;

/// A [width]×[height] PNG: transparent with a coloured band down each side, or
/// noise all over when [noisy], which no PNG level compresses much.
Uint8List _png(int width, int height, {bool noisy = false}) {
  final img.Image image = img.Image(
    width: width,
    height: height,
    numChannels: 4,
  );
  final math.Random random = math.Random(7);
  for (final img.Pixel pixel in image) {
    if (noisy) {
      pixel.setRgba(
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256),
        255,
      );
    } else if (pixel.x < width ~/ 5 || pixel.x >= width - width ~/ 5) {
      pixel.setRgba(200, 40, 40, 255);
    }
  }
  return img.encodePng(image);
}

img.Image _decode(String base64Image) =>
    img.decodeImage(base64Decode(base64Image))!;

void main() {
  test('an image within both limits is sent byte for byte', () async {
    final Uint8List png = _png(900, 500);

    final String sent = await forkPrepareGuildStickerImage(
      bytes: png,
      maxSizeBytes: _limit,
    );

    expect(base64Decode(sent), png);
  });

  test(
    'an image larger than 2048 px is shrunk to 2048 with its shape',
    () async {
      final Uint8List png = _png(3000, 1000);
      expect(png.length, lessThan(_limit));

      final img.Image sent = _decode(
        await forkPrepareGuildStickerImage(bytes: png, maxSizeBytes: _limit),
      );

      expect(sent.width, kForkStickerMaxSide);
      expect(sent.height, 683);
    },
  );

  test('an image over the byte limit is shrunk until its PNG fits, keeping '
      'its shape', () async {
    final Uint8List png = _png(800, 600, noisy: true);
    expect(png.length, greaterThan(_limit));

    final String sent = await forkPrepareGuildStickerImage(
      bytes: png,
      maxSizeBytes: _limit,
    );
    final img.Image image = _decode(sent);

    expect(base64Decode(sent).length, lessThanOrEqualTo(_limit));
    expect(image.width, lessThan(800));
    expect(image.width / image.height, closeTo(800 / 600, 0.01));
  });

  test('an image that fits at no size down to 128 px is refused', () async {
    await expectLater(
      forkPrepareGuildStickerImage(
        bytes: _png(300, 300, noisy: true),
        maxSizeBytes: 1000,
      ),
      throwsA(
        isA<ExpressionImageOptimizationException>().having(
          (ExpressionImageOptimizationException e) => e.reason,
          'reason',
          ExpressionImageOptimizationReason.processed,
        ),
      ),
    );
  });

  test('an animated GIF and an SVG are sent as they are', () async {
    final img.Image first = img.Image(width: 300, height: 100);
    final img.Image second = img.Image(width: 300, height: 100);
    img.fill(second, color: img.ColorRgb8(40, 80, 220));
    first.addFrame(second);
    final Uint8List gif = img.encodeGif(first);
    final Uint8List svg = Uint8List.fromList(
      utf8.encode(
        '<svg xmlns="http://www.w3.org/2000/svg" width="900" height="300"/>',
      ),
    );

    for (final Uint8List bytes in <Uint8List>[gif, svg]) {
      final String sent = await forkPrepareGuildStickerImage(
        bytes: bytes,
        maxSizeBytes: _limit,
      );
      expect(base64Decode(sent), bytes);
    }
  });
}
