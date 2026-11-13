// Fork: works around a Flutter engine bug that stops animated GIF emoji whose
// first frame is opaque (tyne-chat/tyne#615).
//
// Until Flutter 3.50 the engine decodes every frame of an animation into a
// bitmap with the alpha type Skia reports for the whole image, which for a GIF
// is that of frame 0. When frame 0 declares no transparent colour and a later
// frame has transparent pixels (a "restore to background" disposal clears the
// canvas), Skia refuses that frame and the engine throws `Could not getPixels
// for frame N`, so the emoji falls back to its still image. The media proxy
// makes such GIFs whenever it resizes an emoji whose first frame is opaque.
// Fixed in the engine by flutter/flutter#193113, released in Flutter 3.50.0.
//
// Before decoding, this marks frame 0 transparent at a palette index frame 0
// does not use: no pixel changes, and Skia reports the image as having alpha.
//
// REMOVE this file, its call in `fork_synced_emoji_image_cache.dart` and its
// tests once every build of the app (the builder image and the iOS workflows)
// uses Flutter 3.50 or later: tyne-chat/tyne#617 lists them. The test "the
// engine still needs it" in `test/core/media/fork_gif_first_frame_alpha_test.dart`
// fails on such a Flutter.

import 'dart:typed_data';

const int _extensionIntroducer = 0x21;
const int _imageSeparator = 0x2C;
const int _graphicControlLabel = 0xF9;
const int _maxCodeCount = 4096;

/// [bytes] with frame 0 marked as having a transparent colour, when [bytes] is
/// an animated GIF whose frame 0 covers the whole image and declares none;
/// otherwise [bytes] itself. The colour is one frame 0 does not use, so no
/// pixel changes. A file it cannot read is returned as it is.
Uint8List forkGifWithTransparentFirstFrame(Uint8List bytes) {
  try {
    return _withTransparentFirstFrame(bytes) ?? bytes;
  } on _MalformedGif {
    return bytes;
  }
}

Uint8List? _withTransparentFirstFrame(Uint8List bytes) {
  // Animation, and the graphic control extension that declares a transparent
  // colour, are GIF89a's.
  if (bytes.length < 13 ||
      String.fromCharCodes(bytes.sublist(0, 6)) != 'GIF89a') {
    return null;
  }
  final _GifReader reader = _GifReader(bytes)..skip(6);
  final int width = reader.uint16();
  final int height = reader.uint16();
  final int screenFlags = reader.byte();
  reader.skip(2);
  final int globalColours = (screenFlags & 0x80) == 0
      ? 0
      : _colourTableSize(screenFlags);
  reader.skip(3 * globalColours);

  // The graphic control extension that applies to frame 0, if any.
  int? control;
  while (true) {
    final int introducer = reader.byte();
    if (introducer == _imageSeparator) {
      break;
    }
    if (introducer != _extensionIntroducer) {
      return null;
    }
    final int start = reader.position - 1;
    if (reader.byte() == _graphicControlLabel) {
      if (reader.peek() != 4) {
        throw const _MalformedGif();
      }
      control = start;
    }
    reader.skipSubBlocks();
  }
  if (control != null && (bytes[control + 3] & 0x01) != 0) {
    return null;
  }
  final int descriptor = reader.position - 1;
  final int left = reader.uint16();
  final int top = reader.uint16();
  final int frameWidth = reader.uint16();
  final int frameHeight = reader.uint16();
  // A frame 0 that leaves part of the image uncovered already counts as
  // having alpha.
  if (left != 0 || top != 0 || frameWidth < width || frameHeight < height) {
    return null;
  }
  final int frameFlags = reader.byte();
  final int localColours = (frameFlags & 0x80) == 0
      ? 0
      : _colourTableSize(frameFlags);
  reader.skip(3 * localColours);
  final int colours = localColours != 0 ? localColours : globalColours;
  final int minimumCodeSize = reader.byte();
  final BytesBuilder data = BytesBuilder(copy: false);
  reader.readSubBlocks(data);
  if (colours == 0 || !_hasAnotherFrame(reader)) {
    return null;
  }

  final List<bool>? used = _usedIndices(data.takeBytes(), minimumCodeSize);
  if (used == null) {
    return null;
  }
  int? transparent;
  for (int index = colours - 1; index >= 0; index -= 1) {
    if (index >= used.length || !used[index]) {
      transparent = index;
      break;
    }
  }
  if (transparent == null) {
    return null;
  }

  if (control != null) {
    final Uint8List patched = Uint8List.fromList(bytes);
    patched[control + 3] |= 0x01;
    patched[control + 6] = transparent;
    return patched;
  }
  return (BytesBuilder(copy: false)
        ..add(Uint8List.sublistView(bytes, 0, descriptor))
        ..add(<int>[
          _extensionIntroducer,
          _graphicControlLabel,
          4,
          0x01,
          0,
          0,
          transparent,
          0,
        ])
        ..add(Uint8List.sublistView(bytes, descriptor)))
      .takeBytes();
}

int _colourTableSize(int flags) => 2 << (flags & 0x07);

bool _hasAnotherFrame(_GifReader reader) {
  while (!reader.atEnd) {
    final int introducer = reader.byte();
    if (introducer == _imageSeparator) {
      return true;
    }
    if (introducer != _extensionIntroducer) {
      return false;
    }
    reader
      ..skip(1)
      ..skipSubBlocks();
  }
  return false;
}

/// Which palette indices frame 0's LZW data draws, or null if the data is not
/// valid LZW. Every index a frame draws is first written as a literal code, so
/// following the code widths is enough: the strings need not be rebuilt.
List<bool>? _usedIndices(Uint8List data, int minimumCodeSize) {
  if (minimumCodeSize < 1 || minimumCodeSize > 8) {
    return null;
  }
  final int clear = 1 << minimumCodeSize;
  final int end = clear + 1;
  final List<bool> used = List<bool>.filled(clear, false);
  int width = minimumCodeSize + 1;
  int next = clear + 2;
  bool afterClear = true;
  int bit = 0;
  final int bits = data.length * 8;
  while (bit + width <= bits) {
    int code = 0;
    for (int offset = 0; offset < width; offset += 1) {
      final int at = bit + offset;
      code |= ((data[at >> 3] >> (at & 7)) & 1) << offset;
    }
    bit += width;
    if (code == clear) {
      width = minimumCodeSize + 1;
      next = clear + 2;
      afterClear = true;
      continue;
    }
    if (code == end) {
      break;
    }
    if (afterClear) {
      // The first code after a clear code is a literal.
      if (code >= clear) {
        return null;
      }
      used[code] = true;
      afterClear = false;
      continue;
    }
    if (code > next) {
      return null;
    }
    if (code < clear) {
      used[code] = true;
    }
    if (next < _maxCodeCount) {
      next += 1;
      if (next == 1 << width && width < 12) {
        width += 1;
      }
    }
  }
  return used;
}

class _MalformedGif implements Exception {
  const _MalformedGif();
}

class _GifReader {
  _GifReader(this._bytes);

  final Uint8List _bytes;
  int position = 0;

  bool get atEnd => position >= _bytes.length;

  int peek() {
    if (atEnd) {
      throw const _MalformedGif();
    }
    return _bytes[position];
  }

  int byte() {
    final int value = peek();
    position += 1;
    return value;
  }

  int uint16() => byte() | (byte() << 8);

  void skip(int count) {
    if (position + count > _bytes.length) {
      throw const _MalformedGif();
    }
    position += count;
  }

  void skipSubBlocks() {
    for (int size = byte(); size != 0; size = byte()) {
      skip(size);
    }
  }

  void readSubBlocks(BytesBuilder out) {
    for (int size = byte(); size != 0; size = byte()) {
      final int start = position;
      skip(size);
      out.add(Uint8List.sublistView(_bytes, start, position));
    }
  }
}
