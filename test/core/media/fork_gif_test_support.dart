// Fork: builds small GIF files for the tests of tyne-chat/tyne#615.

import 'dart:typed_data';

/// One frame of [forkTestGif]: palette indices, row by row, for its rectangle
/// (the whole image unless [width] and [height] are given).
class ForkTestGifFrame {
  const ForkTestGifFrame(
    this.indices, {
    this.left = 0,
    this.top = 0,
    this.width,
    this.height,
    this.disposal = 1,
    this.delay = 10,
    this.transparentIndex,
    this.control = true,
  });

  final List<int> indices;
  final int left;
  final int top;
  final int? width;
  final int? height;

  /// 1 keeps the frame, 2 restores its rectangle to the background.
  final int disposal;

  /// In hundredths of a second.
  final int delay;
  final int? transparentIndex;

  /// Whether the frame has a graphic control extension.
  final bool control;
}

/// A GIF of [width] x [height] with [palette] (RGB triples, a power of two of
/// them) as its global colour table, looping forever when it has more than one
/// frame. The LZW data writes every pixel as a literal code.
Uint8List forkTestGif({
  required int width,
  required int height,
  required List<List<int>> palette,
  required List<ForkTestGifFrame> frames,
  String version = 'GIF89a',
}) {
  final int bits = palette.length.bitLength - 1;
  assert(1 << bits == palette.length && bits >= 1, 'Palette of 2^n colours.');
  final BytesBuilder out = BytesBuilder()
    ..add(version.codeUnits)
    ..add(_uint16(width))
    ..add(_uint16(height))
    ..addByte(0x80 | ((bits - 1) << 4) | (bits - 1))
    ..addByte(0)
    ..addByte(0);
  for (final List<int> colour in palette) {
    out.add(colour);
  }
  if (frames.length > 1) {
    out
      ..add(<int>[0x21, 0xFF, 11])
      ..add('NETSCAPE2.0'.codeUnits)
      ..add(<int>[3, 1, 0, 0, 0]);
  }
  for (final ForkTestGifFrame frame in frames) {
    final int? transparent = frame.transparentIndex;
    if (frame.control) {
      out
        ..add(<int>[0x21, 0xF9, 4])
        ..addByte((frame.disposal << 2) | (transparent == null ? 0 : 1))
        ..add(_uint16(frame.delay))
        ..add(<int>[transparent ?? 0, 0]);
    }
    out
      ..addByte(0x2C)
      ..add(_uint16(frame.left))
      ..add(_uint16(frame.top))
      ..add(_uint16(frame.width ?? width))
      ..add(_uint16(frame.height ?? height))
      ..addByte(0);
    final int minimumCodeSize = bits < 2 ? 2 : bits;
    out.addByte(minimumCodeSize);
    final Uint8List data = _lzwLiterals(frame.indices, minimumCodeSize);
    for (int start = 0; start < data.length; start += 255) {
      final int end = start + 255 < data.length ? start + 255 : data.length;
      out
        ..addByte(end - start)
        ..add(data.sublist(start, end));
    }
    out.addByte(0);
  }
  out.addByte(0x3B);
  return out.takeBytes();
}

/// LZW data that writes each index as a literal, with a clear code before the
/// table would grow into a wider code.
Uint8List _lzwLiterals(List<int> indices, int minimumCodeSize) {
  final int clear = 1 << minimumCodeSize;
  final int width = minimumCodeSize + 1;
  final int perClear = clear - 2;
  final List<int> codes = <int>[];
  for (int index = 0; index < indices.length; index += 1) {
    if (index % perClear == 0) {
      codes.add(clear);
    }
    codes.add(indices[index]);
  }
  codes.add(clear + 1);
  final List<int> bytes = <int>[];
  int buffer = 0;
  int count = 0;
  for (final int code in codes) {
    buffer |= code << count;
    count += width;
    while (count >= 8) {
      bytes.add(buffer & 0xFF);
      buffer >>= 8;
      count -= 8;
    }
  }
  if (count > 0) {
    bytes.add(buffer & 0xFF);
  }
  return Uint8List.fromList(bytes);
}

List<int> _uint16(int value) => <int>[value & 0xFF, value >> 8];
