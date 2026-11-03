// Fork: the image cache that keeps animated custom emoji in step
// (tyne-chat/tyne#91). The guard tests render upstream's own emoji widgets:
// they fail if upstream changes how it builds those images, which would
// quietly bring back emoji that drift apart.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/media/fluxer_media_url.dart';
import 'package:fluxer_app/core/media/fork_synced_emoji_clock.dart';
import 'package:fluxer_app/core/media/fork_synced_emoji_completer.dart';
import 'package:fluxer_app/core/media/fork_synced_emoji_image_cache.dart';
import 'package:fluxer_app/features/ui/input/emoji_inline_token.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/markdown/fluxer_markdown_adapter.dart';
import 'package:fluxer_app/shared/markdown/native_markdown_parser.dart';
import 'package:fluxer_app/shared/utils/emoji/emoji_image_cache.dart';
import 'package:fluxer_markdown/fluxer_markdown.dart';

import 'fork_synced_emoji_test_support.dart';

const String _wingsL = '1553996962712256513';
const String _wingsR = '1553996962712256512';

// The start of a GIF file: the cache checks the format before decoding.
final Uint8List _gifBytes = Uint8List.fromList('GIF89a'.codeUnits);

/// The binding of the app, with the fork's image cache, and codecs from the
/// fakes instead of the engine's decoder.
class _SyncedEmojiTestBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  ImageCache createImageCache() => ForkSyncedEmojiImageCache(
    decode: (Uint8List bytes) async =>
        FakeSyncedEmojiCodec(const <int>[30, 20, 70, 40]),
  );
}

class _FakeCacheManager implements BaseCacheManager {
  _FakeCacheManager({this.fail = false});

  final bool fail;
  final MemoryFileSystem _fs = MemoryFileSystem();
  final List<String> requests = <String>[];

  int requestsFor(String url) =>
      requests.where((String requested) => requested == url).length;

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) async* {
    requests.add(url);
    if (fail) {
      throw HttpExceptionWithStatus(502, 'Bad Gateway', uri: Uri.parse(url));
    }
    final File file = _fs.file('/file_${requests.length}')
      ..writeAsBytesSync(_gifBytes);
    yield FileInfo(
      file,
      FileSource.Online,
      DateTime.now().add(const Duration(days: 1)),
      url,
    );
  }

  @override
  Future<FileInfo?> getFileFromCache(
    String key, {
    bool ignoreMemCache = false,
  }) async => null;

  @override
  Future<void> removeFile(String key) async {}

  @override
  Future<void> emptyCache() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<File> putFile(
    String url,
    List<int> fileBytes, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) => throw UnimplementedError();
}

String _animatedUrl(String id, int size) =>
    FluxerMediaUrl.customEmoji(id: id, animated: true, size: size);

/// The animated emoji images on screen, with the frame each shows (null while
/// loading).
List<({CachedNetworkImageProvider provider, int? frame})> _emojiImages(
  WidgetTester tester,
) => <({CachedNetworkImageProvider provider, int? frame})>[
  for (final Element element in find.byType(Image).evaluate())
    if ((element.widget as Image).image
        case final CachedNetworkImageProvider provider
        when isForkSyncedEmojiUrl(provider.url))
      (
        provider: provider,
        frame: switch (find
            .descendant(
              of: find.byWidget(element.widget),
              matching: find.byType(RawImage),
            )
            .evaluate()
            .map((Element raw) => (raw.widget as RawImage).image)
            .firstOrNull) {
          final ui.Image image => syncedEmojiFrameIndexOf(image),
          null => null,
        },
      ),
];

Widget _app(Widget child) => ProviderScope(
  child: MaterialApp(
    home: Scaffold(body: Center(child: child)),
  ),
);

Widget _markdown(String data) => FluxerMarkdown(
  astParser: parseNativeFluxerMarkdownAst,
  data: data,
  config: createFluxerMarkdownConfig(),
  baseStyle: const TextStyle(fontSize: 16),
);

void main() {
  _SyncedEmojiTestBinding();

  late BaseCacheManager previousManager;

  setUpAll(createSyncedEmojiFrameImages);

  setUp(() {
    previousManager = CachedNetworkImageProvider.defaultCacheManager;
    PaintingBinding.instance.imageCache.clear();
    ForkSyncedEmojiClock.instance.debugReset();
  });

  tearDown(() {
    CachedNetworkImageProvider.defaultCacheManager = previousManager;
    PaintingBinding.instance.imageCache.clear();
  });

  group('which images', () {
    test('animated custom emoji from FluxerMediaUrl, at every size', () {
      for (final int size in <int>[48, 96, 128, 240]) {
        expect(isForkSyncedEmojiUrl(_animatedUrl(_wingsL, size)), isTrue);
      }
    });

    test('not still emoji, stickers, avatars or other images', () {
      expect(
        isForkSyncedEmojiUrl(FluxerMediaUrl.customEmoji(id: _wingsL)),
        isFalse,
      );
      expect(
        isForkSyncedEmojiUrl(FluxerMediaUrl.sticker(id: '1', animated: true)),
        isFalse,
      );
      expect(
        isForkSyncedEmojiUrl(
          'https://media.test/avatars/1/a_abc.webp?animated=true',
        ),
        isFalse,
      );
      expect(isForkSyncedEmojiUrl('not a url ::'), isFalse);
    });

    test('not images decoded at a reduced size or told not to animate', () {
      final String url = _animatedUrl(_wingsL, 96);
      expect(
        isForkSyncedEmojiProvider(CachedNetworkImageProvider(url)),
        isTrue,
      );
      expect(
        isForkSyncedEmojiProvider(
          CachedNetworkImageProvider(url, maxWidth: 48),
        ),
        isFalse,
      );
      expect(
        isForkSyncedEmojiProvider(
          CachedNetworkImageProvider(url, animate: false),
        ),
        isFalse,
      );
    });

    testWidgets('the cache loads emoji itself and leaves the rest to Flutter', (
      WidgetTester tester,
    ) async {
      CachedNetworkImageProvider.defaultCacheManager = _FakeCacheManager();
      final ImageCache cache = PaintingBinding.instance.imageCache;
      int upstreamLoads = 0;
      ImageStreamCompleter upstream() {
        upstreamLoads += 1;
        return OneFrameImageStreamCompleter(Completer<ImageInfo>().future);
      }

      final ImageStreamCompleter? emoji = cache.putIfAbsent(
        CachedNetworkImageProvider(_animatedUrl(_wingsL, 96)),
        upstream,
      );
      final ImageStreamCompleter? sticker = cache.putIfAbsent(
        CachedNetworkImageProvider(
          FluxerMediaUrl.sticker(id: '1', animated: true),
        ),
        upstream,
      );

      expect(emoji, isA<ForkSyncedEmojiCompleter>());
      expect(sticker, isNot(isA<ForkSyncedEmojiCompleter>()));
      expect(upstreamLoads, 1);
      await tester.pump();
    });
  });

  group('requests', () {
    testWidgets('eight copies of one emoji make one request', (
      WidgetTester tester,
    ) async {
      final _FakeCacheManager manager = _FakeCacheManager();
      CachedNetworkImageProvider.defaultCacheManager = manager;

      await tester.pumpWidget(
        _app(_markdown(List<String>.filled(8, '<a:WingsL:$_wingsL>').join())),
      );
      await tester.pump();
      await tester.pump();

      final List<({CachedNetworkImageProvider provider, int? frame})> images =
          _emojiImages(tester);
      expect(images, hasLength(8));
      expect(manager.requestsFor(images.first.provider.url), 1);
      expect(manager.requests, hasLength(1));
    });

    testWidgets('a failed load is not fetched again on rebuilds', (
      WidgetTester tester,
    ) async {
      final _FakeCacheManager manager = _FakeCacheManager(fail: true);
      CachedNetworkImageProvider.defaultCacheManager = manager;
      final String url = _animatedUrl(_wingsL, 96);
      Widget images() => _app(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int copy = 0; copy < 8; copy += 1)
              CachedNetworkImage(
                imageUrl: url,
                cacheKey: 'emoji_${_wingsL}_a2_96',
                width: 16,
                height: 16,
                errorBuilder: (_, _, _) =>
                    const SizedBox.square(dimension: 16, key: Key('failed')),
              ),
          ],
        ),
      );

      await tester.pumpWidget(images());
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('failed')), findsNWidgets(8));

      for (int rebuild = 0; rebuild < 5; rebuild += 1) {
        await tester.pumpWidget(images());
        await tester.pump(const Duration(seconds: 1));
      }

      expect(manager.requestsFor(url), 1);
    });
  });

  group("upstream's emoji widgets go through the fork's cache", () {
    testWidgets('message emoji: two wings, the second added later, show the '
        'same frame', (WidgetTester tester) async {
      CachedNetworkImageProvider.defaultCacheManager = _FakeCacheManager();

      await tester.pumpWidget(_app(_markdown('<a:WingsL:$_wingsL> text')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 370));

      // An edit adds the right wing next to the left one.
      await tester.pumpWidget(
        _app(_markdown('<a:WingsL:$_wingsL> <a:WingsR:$_wingsR> text')),
      );
      await tester.pump();
      await tester.pump();

      final Set<int?> seen = <int?>{};
      for (int step = 0; step < 30; step += 1) {
        await tester.pump(const Duration(milliseconds: 9));
        final List<({CachedNetworkImageProvider provider, int? frame})> images =
            _emojiImages(tester);
        expect(images, hasLength(2));
        expect(
          images.every(
            (({CachedNetworkImageProvider provider, int? frame}) image) =>
                isForkSyncedEmojiProvider(image.provider),
          ),
          isTrue,
        );
        expect(images.first.frame, isNotNull, reason: 'step $step');
        expect(images.last.frame, images.first.frame, reason: 'step $step');
        seen.add(images.first.frame);
      }
      // 270 ms covers more than a loop: the wings flap, not stand still.
      expect(seen, <int>{0, 1, 2, 3});
    });

    testWidgets('CachedEmojiImage (picker, reactions, status)', (
      WidgetTester tester,
    ) async {
      CachedNetworkImageProvider.defaultCacheManager = _FakeCacheManager();

      await tester.pumpWidget(
        _app(
          const CachedEmojiImage(
            emojiId: _wingsL,
            animated: true,
            requestSize: 96,
            size: 32,
            pauseWhenOffscreen: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final List<({CachedNetworkImageProvider provider, int? frame})> images =
          _emojiImages(tester);
      expect(images, hasLength(1));
      expect(isForkSyncedEmojiProvider(images.single.provider), isTrue);
      expect(images.single.frame, 0);
    });

    testWidgets("the composer's emoji token", (WidgetTester tester) async {
      CachedNetworkImageProvider.defaultCacheManager = _FakeCacheManager();
      final EmojiInlineToken token = EmojiInlineToken(
        displayName: 'WingsL',
        wireText: '<a:WingsL:$_wingsL>',
      );

      await tester.pumpWidget(
        _app(
          Builder(
            builder: (BuildContext context) =>
                token.buildInline(context, const TextStyle(fontSize: 16)),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final List<({CachedNetworkImageProvider provider, int? frame})> images =
          _emojiImages(tester);
      expect(images, hasLength(1));
      expect(isForkSyncedEmojiProvider(images.single.provider), isTrue);
      expect(images.single.frame, 0);
    });
  });
}
