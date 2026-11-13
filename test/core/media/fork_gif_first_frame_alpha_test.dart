// Fork: the workaround for animated GIF emoji whose first frame is opaque
// (tyne-chat/tyne#615). "the engine still needs it" fails once the app is
// tested on a Flutter that decodes such GIFs itself (3.50 or later): then
// delete the workaround, as that test's message says.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/media/fork_gif_first_frame_alpha.dart';

import 'fork_gif_test_support.dart';

const List<List<int>> _palette = <List<int>>[
  <int>[200, 30, 30],
  <int>[30, 200, 30],
  <int>[30, 30, 200],
  <int>[240, 240, 240],
  <int>[10, 10, 10],
  <int>[120, 120, 0],
  <int>[0, 120, 120],
  <int>[255, 0, 255],
];

// Frame 0 draws colours 0 to 2 over the whole image and is then cleared to
// the background; frame 1 is half transparent (colour 7).
final List<int> _opaqueIndices = <int>[
  for (int pixel = 0; pixel < 16; pixel += 1) pixel % 3,
];
final List<int> _halfTransparentIndices = <int>[
  for (int pixel = 0; pixel < 16; pixel += 1)
    if (pixel.isEven) 7 else 3,
];

Uint8List _gif({
  ForkTestGifFrame first = const ForkTestGifFrame(<int>[], disposal: 2),
  List<int>? firstIndices,
  bool animated = true,
  String version = 'GIF89a',
}) => forkTestGif(
  width: 4,
  height: 4,
  palette: _palette,
  version: version,
  frames: <ForkTestGifFrame>[
    ForkTestGifFrame(
      firstIndices ?? _opaqueIndices,
      left: first.left,
      top: first.top,
      width: first.width,
      height: first.height,
      disposal: first.disposal,
      delay: first.delay,
      transparentIndex: first.transparentIndex,
      control: first.control,
    ),
    if (animated)
      ForkTestGifFrame(_halfTransparentIndices, transparentIndex: 7),
  ],
);

Future<List<Uint8List>> _decodeFrames(Uint8List bytes) async {
  final ui.Codec codec = await ui.instantiateImageCodec(bytes);
  try {
    final List<Uint8List> frames = <Uint8List>[];
    for (int index = 0; index < codec.frameCount; index += 1) {
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ByteData? pixels = await frame.image.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      frame.image.dispose();
      frames.add(pixels!.buffer.asUint8List());
    }
    return frames;
  } finally {
    codec.dispose();
  }
}

/// The RGBA pixels of [indices] drawn on a cleared canvas.
Uint8List _expectedPixels(List<int> indices, {int? transparentIndex}) =>
    Uint8List.fromList(<int>[
      for (final int index in indices)
        if (index == transparentIndex) ...<int>[0, 0, 0, 0] else ...<int>[
          ..._palette[index],
          255,
        ],
    ]);

void main() {
  group('forkGifWithTransparentFirstFrame', () {
    test('marks an opaque frame 0 transparent at a colour it does not use', () {
      expect(
        forkGifWithTransparentFirstFrame(_gif()),
        _gif(
          first: const ForkTestGifFrame(
            <int>[],
            disposal: 2,
            transparentIndex: 7,
          ),
        ),
      );
    });

    test('picks the highest colour frame 0 does not use', () {
      final List<int> indices = <int>[..._opaqueIndices]..[5] = 7;
      expect(
        forkGifWithTransparentFirstFrame(_gif(firstIndices: indices)),
        _gif(
          firstIndices: indices,
          first: const ForkTestGifFrame(
            <int>[],
            disposal: 2,
            transparentIndex: 6,
          ),
        ),
      );
    });

    test('adds a graphic control extension when frame 0 has none', () {
      expect(
        forkGifWithTransparentFirstFrame(
          _gif(first: const ForkTestGifFrame(<int>[], control: false)),
        ),
        _gif(
          first: const ForkTestGifFrame(
            <int>[],
            disposal: 0,
            delay: 0,
            transparentIndex: 7,
          ),
        ),
      );
    });

    group('leaves the file as it is', () {
      final Map<String, Uint8List> files = <String, Uint8List>{
        'frame 0 already has a transparent colour': _gif(
          first: const ForkTestGifFrame(
            <int>[],
            disposal: 2,
            transparentIndex: 7,
          ),
        ),
        'a single frame': _gif(animated: false),
        'frame 0 leaves part of the image uncovered': _gif(
          firstIndices: <int>[0, 1, 2, 0, 1, 2, 0, 1, 2],
          first: const ForkTestGifFrame(
            <int>[],
            left: 1,
            width: 3,
            height: 3,
            disposal: 2,
          ),
        ),
        'frame 0 uses every colour': _gif(
          firstIndices: <int>[
            for (int pixel = 0; pixel < 16; pixel += 1) pixel % 8,
          ],
        ),
        'GIF87a': _gif(version: 'GIF87a'),
        'invalid LZW data': _gif(firstIndices: <int>[15, ..._opaqueIndices]),
        'not a GIF': Uint8List.fromList(<int>[
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
          ...List<int>.filled(32, 0),
        ]),
      };
      for (final MapEntry<String, Uint8List> file in files.entries) {
        test(file.key, () {
          expect(
            forkGifWithTransparentFirstFrame(file.value),
            same(file.value),
          );
        });
      }
    });

    test('reads a cut-off file without throwing', () {
      final Uint8List bytes = _gif();
      for (int length = 0; length < bytes.length; length += 1) {
        final Uint8List cut = Uint8List.sublistView(bytes, 0, length);
        expect(() => forkGifWithTransparentFirstFrame(cut), returnsNormally);
      }
    });
  });

  group('with Flutter', () {
    testWidgets('the engine still needs it', (WidgetTester tester) async {
      final Object? error = await tester.runAsync<Object?>(() async {
        try {
          await _decodeFrames(_gif());
        } on Object catch (error) {
          return error;
        }
        return null;
      });
      expect(
        error,
        isNotNull,
        reason:
            'This Flutter decodes animated GIFs whose frame 0 is opaque '
            '(flutter/flutter#193113, Flutter 3.50). Once every build of the '
            'app (the builder image and the iOS workflows) uses such a '
            'Flutter, delete lib/core/media/fork_gif_first_frame_alpha.dart, '
            'its call in fork_synced_emoji_image_cache.dart, this file and '
            'fork_gif_test_support.dart (tyne-chat/tyne#617).',
      );
    });

    testWidgets('every frame decodes, and no pixel changes', (
      WidgetTester tester,
    ) async {
      final List<Uint8List>? frames = await tester.runAsync(
        () => _decodeFrames(forkGifWithTransparentFirstFrame(_gif())),
      );
      expect(frames, <Uint8List>[
        _expectedPixels(_opaqueIndices),
        _expectedPixels(_halfTransparentIndices, transparentIndex: 7),
      ]);
    });
  });
}
