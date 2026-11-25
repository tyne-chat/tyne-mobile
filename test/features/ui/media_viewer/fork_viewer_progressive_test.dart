// Fork (tyne-chat/tyne#887): tests for progressive cached-thumbnail -> full-res
// viewer swap, download invariance, concrete ForkGalleryPreviewScope isolation,
// ForumPostCard/ForumPostTile handoff, cache lifecycle, mature media reveal
// persistence, scroll settle gating, and 56 dp strip fallback.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:file/file.dart' as file_pkg;
import 'package:file/local.dart';
import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/attachment_request_auth.dart';
import 'package:fluxer_app/core/bootstrap/image_cache_config.dart';
import 'package:fluxer_app/core/instance/instance_endpoints.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/attachments/attachment_media_grid.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/media/chat_network_image.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/media/media_load_error_placeholder.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/media/seen_media_urls.dart';
import 'package:fluxer_app/features/chat/utils/media/fork_rendered_thumbnail_registry.dart';
import 'package:fluxer_app/features/forum/presentation/forum_post_actions.dart';
import 'package:fluxer_app/features/forum/presentation/widgets/forum_post_card.dart';
import 'package:fluxer_app/features/mature_content/domain/mature_content_types.dart';
import 'package:fluxer_app/features/mature_content/providers/mature_content_agreements_provider.dart';
import 'package:fluxer_app/features/settings/providers/preferences/appearance_preferences_provider.dart';
import 'package:fluxer_app/features/settings/providers/preferences/chat_preferences_provider.dart';
import 'package:fluxer_app/features/ui/media_viewer/attachment_media_viewer.dart';
import 'package:fluxer_app/features/ui/media_viewer/fork_media_viewer_preloader.dart';
import 'package:fluxer_app/features/ui/media_viewer/fork_viewer_items.dart';
import 'package:fluxer_app/features/ui/media_viewer/fork_viewer_progressive_image.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/providers/input_modality_provider.dart';
import 'package:fluxer_app/shared/utils/snowflake_time.dart';
import 'package:riverpod/src/framework.dart' show Override;

import '../../../helpers/core_test_provider_overrides.dart';
import '../../../helpers/test_l10n.dart';

// Valid 1x1 transparent PNG.
final Uint8List _kTinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==',
);

class _FakeCacheManager implements BaseCacheManager {
  _FakeCacheManager(this._rootDir);

  final Directory _rootDir;
  final LocalFileSystem _fs = const LocalFileSystem();
  final Map<String, FileInfo> _entries = <String, FileInfo>{};
  final List<String> getFileStreamCalls = <String>[];
  int _seq = 0;

  void seed(String key, Uint8List bytes, {DateTime? validTill}) {
    final File f = File('${_rootDir.path}/entry_${_seq++}.png')
      ..writeAsBytesSync(bytes);
    _entries[key] = FileInfo(
      _fs.file(f.path),
      FileSource.Cache,
      validTill ?? DateTime.now().add(const Duration(hours: 1)),
      key,
    );
  }

  @override
  Future<FileInfo?> getFileFromCache(
    String key, {
    bool ignoreMemCache = false,
  }) async {
    return _entries[key];
  }

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) {
    getFileStreamCalls.add(url);
    final FileInfo? existing = _entries[key ?? url];
    if (existing != null) {
      return Stream<FileResponse>.value(existing);
    }
    return Stream<FileResponse>.error(Exception('network disabled in test'));
  }

  @override
  Future<file_pkg.File> putFile(
    String url,
    List<int> fileBytes, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) async {
    final File f = File('${_rootDir.path}/put_${_seq++}.$fileExtension')
      ..writeAsBytesSync(fileBytes);
    final file_pkg.File wrapped = _fs.file(f.path);
    _entries[key ?? url] = FileInfo(
      wrapped,
      FileSource.Online,
      DateTime.now().add(maxAge),
      key ?? url,
    );
    return wrapped;
  }

  @override
  Future<void> emptyCache() async {
    _entries.clear();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDioAdapter implements HttpClientAdapter {
  _FakeDioAdapter(this.handler);

  final Future<ResponseBody> Function(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  )
  handler;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {}
}

class _MousePrimaryModality extends InputModalityNotifier {
  @override
  bool build() => false;
}

class _TouchPrimaryModality extends InputModalityNotifier {
  @override
  bool build() => true;
}

Widget _app(
  Widget child, {
  List<Override> extraOverrides = const <Override>[],
}) {
  final colorTheme = buildDarkColorTheme();
  return ProviderScope(
    overrides: coreTestProviderOverrides(extra: extraOverrides),
    child: MaterialApp(
      locale: kTestLocale,
      localizationsDelegates: fluxerLocalizationsDelegates,
      supportedLocales: FluxerLocalizations.supportedLocales,
      theme: buildFluxerTheme(
        colorTheme: colorTheme,
        textTheme: FluxerTextTheme.fromColors(colorTheme),
        layoutTheme: FluxerLayoutTheme.scaled(),
      ),
      home: Scaffold(body: child),
    ),
  );
}

Future<void> _immediateCancelFuture() => (Completer<void>()..complete()).future;

/// Pumps interleaved real-async and fake-async widget turns until [condition]
/// holds (needed for real `dart:io` + `dart:ui` image codec multi-hop awaits
/// inside `testWidgets`).
Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  int maxTurns = 30,
}) async {
  for (int i = 0; i < maxTurns && !condition(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 15)),
    );
    await tester.pump();
  }
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('tyne_viewer_prog_test_');
    ForkRenderedThumbnailRegistry.clear();
  });

  tearDown(() {
    ForkRenderedThumbnailRegistry.clear();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('download invariance & animation predicate', () {
    test('forkResolveOriginalDownloadUrl never resolves a transformed thumbnail', () {
      const String media = 'https://media.tyne.test';
      const Attachment normal = Attachment(
        id: '1',
        filename: 'photo.png',
        url: '$media/attachments/1/1/photo.png',
        proxyUrl: '$media/attachments/1/1/photo.png?ex=1&hm=abc',
        contentType: 'image/png',
      );
      expect(
        forkResolveOriginalDownloadUrl(normal),
        '$media/attachments/1/1/photo.png?ex=1&hm=abc',
      );

      // If Fluxer proxyUrl carries transform params, fall back to untransformed
      // original url — including external URLs with their own format/width query params.
      const Attachment transformedProxy = Attachment(
        id: '2',
        filename: 'photo.png',
        url: 'https://origin.example/original.png?format=jpg&width=1200',
        proxyUrl:
            '$media/attachments/1/2/photo.png?format=webp&quality=high&width=640',
        contentType: 'image/png',
      );
      expect(
        forkResolveOriginalDownloadUrl(transformedProxy, mediaEndpoint: media),
        'https://origin.example/original.png?format=jpg&width=1200',
      );

      // If both Fluxer media URLs carry transform params, return null rather than downloading a thumb.
      const Attachment onlyThumb = Attachment(
        id: '3',
        filename: 'photo.png',
        url: '$media/attachments/1/3/photo.png?format=webp&width=320',
        proxyUrl: '$media/attachments/1/3/photo.png?format=webp&width=320',
        contentType: 'image/png',
      );
      expect(
        forkResolveOriginalDownloadUrl(onlyThumb, mediaEndpoint: media),
        isNull,
      );

      // Expired attachment -> null.
      const Attachment expired = Attachment(
        id: '4',
        filename: 'photo.png',
        url: '$media/attachments/1/4/photo.png',
        expired: true,
      );
      expect(forkResolveOriginalDownloadUrl(expired), isNull);

      // Viewer item preserves original download URL while carrying WebP forkPreview.
      final List<AttachmentMediaViewerItem>
      items = forkViewerItemsFromAttachments(
        const <Attachment>[normal],
        tappedIndex: 0,
        tappedPreview: const ForkThumbnailDescriptor(
          url:
              '$media/attachments/1/1/photo.png?format=webp&quality=high&width=640',
          memCacheWidth: 640,
        ),
      );
      expect(items.single.downloadUrl, normal.proxyUrl);
      expect(items.single.forkPreview!.url, contains('format=webp'));
    });

    test('static webp and avif are NOT treated as animated; gifs ARE', () {
      const AttachmentMediaViewerItem staticWebp = AttachmentMediaViewerItem(
        url: 'https://media.tyne.test/attachments/1/1/pic.webp',
        filename: 'pic.webp',
        contentType: 'image/webp',
      );
      const AttachmentMediaViewerItem staticAvif = AttachmentMediaViewerItem(
        url: 'https://media.tyne.test/attachments/1/1/pic.avif',
        filename: 'pic.avif',
        contentType: 'image/avif',
      );
      const AttachmentMediaViewerItem gifByType = AttachmentMediaViewerItem(
        url: 'https://media.tyne.test/attachments/1/1/loop',
        filename: 'loop',
        contentType: 'image/gif',
      );
      const AttachmentMediaViewerItem animQuery = AttachmentMediaViewerItem(
        url: 'https://media.tyne.test/attachments/1/1/anim.webp?animated=true',
        filename: 'anim.webp',
        contentType: 'image/webp',
      );
      const AttachmentMediaViewerItem
      animProxyQuery = AttachmentMediaViewerItem(
        url: 'https://origin.example/clip',
        proxyUrl:
            'https://media.tyne.test/external/sig/clip?format=webp&animated=true',
        filename: 'clip',
        contentType: 'image/webp',
      );
      expect(forkIsExplicitlyAnimatedViewerItem(staticWebp), isFalse);
      expect(forkIsExplicitlyAnimatedViewerItem(staticAvif), isFalse);
      expect(forkIsExplicitlyAnimatedViewerItem(gifByType), isTrue);
      expect(forkIsExplicitlyAnimatedViewerItem(animQuery), isTrue);
      expect(forkIsExplicitlyAnimatedViewerItem(animProxyQuery), isTrue);
    });
  });

  group('ForkGalleryPreviewScope isolation & registry lifecycle', () {
    testWidgets(
      'two AttachmentMediaGrid surfaces rendering the same message at different '
      'widths do not collide',
      (WidgetTester tester) async {
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);

        final String base = InstanceEndpoints.media;
        final List<Attachment> sharedAttachments = <Attachment>[
          Attachment(
            id: 'a1',
            filename: 'one.png',
            url: '$base/attachments/1/1/one.png',
            proxyUrl: '$base/attachments/1/1/one.png',
            contentType: 'image/png',
            width: 4000,
            height: 3000,
          ),
          Attachment(
            id: 'a2',
            filename: 'two.png',
            url: '$base/attachments/1/2/two.png',
            proxyUrl: '$base/attachments/1/2/two.png',
            contentType: 'image/png',
            width: 4000,
            height: 3000,
          ),
        ];

        await tester.pumpWidget(
          _app(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  key: const ValueKey<String>('narrowGrid'),
                  width: 180,
                  child: AttachmentMediaGrid(
                    attachments: sharedAttachments,
                    revealSpoilers: true,
                    dimensionSize: MediaDimensionSize.large,
                    messageId: 'same-msg',
                  ),
                ),
                SizedBox(
                  key: const ValueKey<String>('wideGrid'),
                  width: 440,
                  child: AttachmentMediaGrid(
                    attachments: sharedAttachments,
                    revealSpoilers: true,
                    dimensionSize: MediaDimensionSize.large,
                    messageId: 'same-msg',
                  ),
                ),
              ],
            ),
          ),
        );
        await tester.pump();

        final Element narrowInner = tester.element(
          find
              .descendant(
                of: find.byKey(const ValueKey<String>('narrowGrid')),
                matching: find.byType(ChatNetworkImage),
              )
              .first,
        );
        final Element wideInner = tester.element(
          find
              .descendant(
                of: find.byKey(const ValueKey<String>('wideGrid')),
                matching: find.byType(ChatNetworkImage),
              )
              .first,
        );

        final Map<String, ForkThumbnailDescriptor>? narrowMap =
            ForkGalleryPreviewScope.maybeRead(narrowInner);
        final Map<String, ForkThumbnailDescriptor>? wideMap =
            ForkGalleryPreviewScope.maybeRead(wideInner);

        expect(narrowMap, isNotNull);
        expect(wideMap, isNotNull);
        final String key = sharedAttachments.first.proxyUrl!;
        expect(narrowMap![key]!.url, isNot(equals(wideMap![key]!.url)));
        final int narrowCap =
            narrowMap[key]!.memCacheWidth ?? narrowMap[key]!.memCacheHeight!;
        final int wideCap =
            wideMap[key]!.memCacheWidth ?? wideMap[key]!.memCacheHeight!;
        expect(narrowCap, lessThan(wideCap));
      },
    );

    test('clearFluxerImageCache preserves ForkRenderedThumbnailRegistry while '
        'clearFluxerNetworkImageCaches clears it', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      const ForkThumbnailDescriptor desc = ForkThumbnailDescriptor(
        url:
            'https://media.tyne.test/attachments/1/1/p.png?format=webp&width=320',
        memCacheWidth: 320,
      );
      ForkRenderedThumbnailRegistry.register(
        scopeToken: 'forum:42',
        sourceKey: 'https://media.tyne.test/attachments/1/1/p.png',
        descriptor: desc,
      );
      clearFluxerImageCache();
      expect(
        ForkRenderedThumbnailRegistry.lookup(
          scopeToken: 'forum:42',
          sourceKey: 'https://media.tyne.test/attachments/1/1/p.png',
        ),
        desc,
      );

      final BaseCacheManager original =
          CachedNetworkImageProvider.defaultCacheManager;
      CachedNetworkImageProvider.defaultCacheManager = _FakeCacheManager(
        tempDir,
      );
      addTearDown(
        () => CachedNetworkImageProvider.defaultCacheManager = original,
      );
      await clearFluxerNetworkImageCaches();
      expect(
        ForkRenderedThumbnailRegistry.lookup(
          scopeToken: 'forum:42',
          sourceKey: 'https://media.tyne.test/attachments/1/1/p.png',
        ),
        isNull,
      );

      // Auth/session change clears registry unconditionally even when
      // InstanceEndpoints.proxyAttachmentsThroughApi is false.
      InstanceEndpoints.proxyAttachmentsThroughApi = false;
      ForkRenderedThumbnailRegistry.register(
        scopeToken: 'forum:99',
        sourceKey: 'https://media.tyne.test/attachments/1/2/p.png',
        descriptor: desc,
      );
      AttachmentRequestAuth.update(
        token: 'user-a',
        baseUrl: 'https://api.tyne.test/v1',
        mintToken: null,
      );
      addTearDown(
        () => AttachmentRequestAuth.update(
          token: null,
          baseUrl: null,
          mintToken: null,
        ),
      );
      expect(
        ForkRenderedThumbnailRegistry.lookup(
          scopeToken: 'forum:99',
          sourceKey: 'https://media.tyne.test/attachments/1/2/p.png',
        ),
        isNull,
      );
    });

    testWidgets(
      'ForumPostCard falls back to static WebP _previewUrl for animated or dimensionless attachments',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);

        final String postId = snowflakeFromDateTime(DateTime.utc(2026, 11, 20));
        const Channel forum = Channel(
          id: '100',
          guildId: 'g1',
          name: 'art',
          type: ChannelType.guildForum,
        );
        final Channel post = Channel(
          id: postId,
          guildId: 'g1',
          name: 'Animated & dimensionless',
          type: ChannelType.publicThread,
          parentId: '100',
        );
        final String base = InstanceEndpoints.media;
        final Attachment animatedGif = Attachment(
          id: '10',
          filename: 'anim.gif',
          url: '$base/attachments/1/10/anim.gif',
          proxyUrl: '$base/attachments/1/10/anim.gif',
          contentType: 'image/gif',
          width: 800,
          height: 600,
        );
        final Attachment noDims = Attachment(
          id: '11',
          filename: 'nodims.heic',
          url: '$base/attachments/1/11/nodims.heic',
          proxyUrl: '$base/attachments/1/11/nodims.heic',
          contentType: 'image/heic',
        );

        for (final Attachment att in <Attachment>[animatedGif, noDims]) {
          await tester.pumpWidget(
            MaterialApp(
              locale: kTestLocale,
              localizationsDelegates: fluxerLocalizationsDelegates,
              supportedLocales: FluxerLocalizations.supportedLocales,
              theme: buildFluxerTheme(
                colorTheme: buildDarkColorTheme(),
                textTheme: FluxerTextTheme.fromColors(buildDarkColorTheme()),
                layoutTheme: FluxerLayoutTheme.scaled(),
              ),
              home: Scaffold(
                body: SizedBox(
                  width: 390,
                  child: ForumPostCard(
                    data: ForumPostCardData(
                      forum: forum,
                      post: post,
                      firstMessageLoaded: true,
                      firstMessage: Message(
                        id: postId,
                        channelId: postId,
                        authorId: 'u1',
                        authorName: 'Alice',
                        content: 'Hi',
                        timestamp: DateTime.utc(2026, 11, 20),
                        attachments: <Attachment>[att],
                      ),
                    ),
                    onTap: () {},
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          final Uri uri = Uri.parse(
            tester
                .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
                .imageUrl,
          );
          expect(uri.queryParameters['format'], 'webp', reason: att.filename);
          expect(uri.queryParameters['animated'], isNull, reason: att.filename);
        }
      },
    );

    testWidgets(
      'ForumPostTile registers DPR-sharp thumbnail and openForumPostMedia hands it to viewer',
      (WidgetTester tester) async {
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        final String postId = snowflakeFromDateTime(DateTime.utc(2026, 11, 20));
        final String mediaUrl =
            '${InstanceEndpoints.media}/attachments/1/9/forum.png';
        final Attachment photo = Attachment(
          id: '9',
          filename: 'forum.png',
          url: mediaUrl,
          proxyUrl: mediaUrl,
          contentType: 'image/png',
          width: 4000,
          height: 3000,
        );
        const Channel forum = Channel(
          id: '100',
          guildId: 'g1',
          name: 'art',
          type: ChannelType.guildForum,
        );
        final Channel post = Channel(
          id: postId,
          guildId: 'g1',
          name: 'Showcase',
          type: ChannelType.publicThread,
          parentId: '100',
        );
        final Message starter = Message(
          id: postId,
          channelId: postId,
          authorId: 'u1',
          authorName: 'Alice',
          content: 'Check this out',
          timestamp: DateTime.utc(2026, 11, 20),
          attachments: <Attachment>[photo],
        );

        await tester.pumpWidget(
          _app(
            Consumer(
              builder: (BuildContext context, WidgetRef ref, _) => SizedBox(
                width: 180,
                height: 220,
                child: ForumPostTile(
                  data: ForumPostCardData(
                    forum: forum,
                    post: post,
                    firstMessageLoaded: true,
                    firstMessage: starter,
                  ),
                  onTap: () {},
                  onOpenMedia: (Attachment att) => openForumPostMedia(
                    context,
                    ref,
                    forum: forum,
                    post: post,
                    message: starter,
                    attachment: att,
                    onViewPost: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final CachedNetworkImage tileImg = tester.widget<CachedNetworkImage>(
          find.byType(CachedNetworkImage),
        );
        final Uri tileUri = Uri.parse(tileImg.imageUrl);
        expect(tileUri.queryParameters['format'], 'webp');
        expect(tileUri.queryParameters['quality'], 'high');
        expect(tileUri.queryParameters['width'], isNotNull);
        expect(tileUri.queryParameters['height'], isNull);
        expect(tileImg.memCacheWidth ?? tileImg.memCacheHeight, isNotNull);

        final ForkThumbnailDescriptor? registered =
            ForkRenderedThumbnailRegistry.lookup(
              scopeToken: 'forum:$postId',
              sourceKey: mediaUrl,
            );
        expect(registered, isNotNull);
        expect(registered!.url, tileImg.imageUrl);

        // Tap top of ForumPostTile to launch openForumPostMedia.
        await tester.tapAt(
          tester.getRect(find.byType(ForumPostTile)).topCenter +
              const Offset(0, 40),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        final AttachmentMediaViewerShell shell = tester
            .widget<AttachmentMediaViewerShell>(
              find.byType(AttachmentMediaViewerShell),
            );
        expect(shell.items.single.forkPreview?.url, tileImg.imageUrl);
        expect(shell.items.single.downloadUrl, mediaUrl);
      },
    );
  });

  group('progressive viewer swap, sizing, spinner, and error fallback', () {
    testWidgets(
      'small 200x200 image does not upscale inside 400x800 viewport and '
      'shows delayed 180ms spinner only while full-res is loading',
      (WidgetTester tester) async {
        final _FakeCacheManager cache = _FakeCacheManager(tempDir);
        const String thumbUrl =
            'https://media.tyne.test/attachments/1/1/s.png?format=webp&width=160';
        const String fullUrl = 'https://media.tyne.test/attachments/1/1/s.png';
        cache.seed(thumbUrl, _kTinyPng);

        const AttachmentMediaViewerItem item = AttachmentMediaViewerItem(
          url: fullUrl,
          filename: 's.png',
          forkPreview: ForkThumbnailDescriptor(url: thumbUrl),
          width: 200,
          height: 200,
          proxyUrl: fullUrl,
          contentType: 'image/png',
        );

        await tester.pumpWidget(
          _app(
            SizedBox(
              width: 400,
              height: 800,
              child: Center(
                child: ForkViewerPageImage(
                  item: item,
                  imageUrl: fullUrl,
                  decodeCap: 2048,
                  isPortrait: false,
                  shouldLoadFullRes: true,
                  errorPlaceholder: const MediaLoadErrorPlaceholder(),
                  cacheManager: cache,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Intrinsic-capped scaleDown keeps 200x200 (never upscales to 400x400).
        final Size renderedSize = tester.getSize(
          find.byType(ForkViewerPageImage),
        );
        expect(renderedSize, const Size(200, 200));

        // 0 preview network fetches via cacheManager.getFileStream.
        expect(cache.getFileStreamCalls, isNot(contains(thumbUrl)));

        // Spinner absent at 100 ms, visible after 180 ms.
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(CircularProgressIndicator), findsNothing);
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'keeps valid cached disk thumbnail visible on real terminal full-res failure '
      'with 0 preview GETs, while corrupt preview shows errorPlaceholder',
      (WidgetTester tester) async {
        final BaseCacheManager originalCm =
            CachedNetworkImageProvider.defaultCacheManager;
        final _FakeCacheManager cache = _FakeCacheManager(tempDir);
        CachedNetworkImageProvider.defaultCacheManager = cache;
        addTearDown(
          () => CachedNetworkImageProvider.defaultCacheManager = originalCm,
        );

        const String thumbUrl =
            'https://media.tyne.test/attachments/1/2/p.png?format=webp&width=320';
        const String fullUrl = 'https://media.tyne.test/attachments/1/2/p.png';
        cache.seed(thumbUrl, _kTinyPng);

        int terminalFailureCount = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: ForkViewerPageImage(
                  item: const AttachmentMediaViewerItem(
                    url: fullUrl,
                    filename: 'p.png',
                    forkPreview: ForkThumbnailDescriptor(url: thumbUrl),
                    width: 800,
                    height: 600,
                    proxyUrl: fullUrl,
                    contentType: 'image/png',
                  ),
                  imageUrl: fullUrl,
                  decodeCap: 2048,
                  isPortrait: false,
                  shouldLoadFullRes: true,
                  errorPlaceholder: const Text('ERR_PLACEHOLDER'),
                  cacheManager: cache,
                  onFullResUnrecoverable: () => terminalFailureCount++,
                ),
              ),
            ),
          ),
        );
        // Allow ForkCacheOnlyPreviewImage to mount FileImage, decode from disk
        // (multi-hop dart:io + dart:ui codec), and deliver onCacheStateResolved(true).
        await _pumpUntil(
          tester,
          () => find.byType(Image).evaluate().isNotEmpty,
        );
        await tester.pump();
        for (int i = 0; i < 12; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 15)),
          );
          await tester.pump();
        }
        // Pump past RetryingNetworkImage's 1s + 2s + 4s + 8s = 15s retry delays
        // (forkMaxRetries: kMediaLoadRetryDelays.length == 4).
        for (int i = 0; i < 18; i++) {
          await tester.pump(const Duration(seconds: 1));
        }
        await tester.pump();

        // Network failures are not unrecoverable: retrying may still load the
        // page, so the viewer must not start neighbour preloading off them.
        expect(terminalFailureCount, 0);
        expect(find.text('ERR_PLACEHOLDER'), findsNothing);
        expect(
          find.descendant(
            of: find.byType(ForkCacheOnlyPreviewImage),
            matching: find.byType(Image),
          ),
          findsOneWidget,
        );
        expect(cache.getFileStreamCalls, isNot(contains(thumbUrl)));

        // Corrupt preview + failing full-res: corrupt preview must NOT suppress errorPlaceholder.
        const String corruptThumbUrl =
            'https://media.tyne.test/attachments/1/2/corrupt.png?format=webp&width=320';
        const String corruptFullUrl =
            'https://media.tyne.test/attachments/1/2/corrupt.png';
        cache.seed(corruptThumbUrl, Uint8List.fromList(<int>[0, 1, 2, 3, 4]));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: ForkViewerPageImage(
                  item: const AttachmentMediaViewerItem(
                    url: corruptFullUrl,
                    filename: 'corrupt.png',
                    forkPreview: ForkThumbnailDescriptor(url: corruptThumbUrl),
                    width: 800,
                    height: 600,
                    proxyUrl: corruptFullUrl,
                    contentType: 'image/png',
                  ),
                  imageUrl: corruptFullUrl,
                  decodeCap: 2048,
                  isPortrait: false,
                  shouldLoadFullRes: true,
                  errorPlaceholder: const Text('ERR_PLACEHOLDER'),
                  cacheManager: cache,
                ),
              ),
            ),
          ),
        );
        for (int i = 0; i < 12; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 15)),
          );
          await tester.pump();
        }
        for (int i = 0; i < 18; i++) {
          await tester.pump(const Duration(seconds: 1));
        }
        await tester.pump();
        expect(find.text('ERR_PLACEHOLDER'), findsOneWidget);
        expect(cache.getFileStreamCalls, isNot(contains(corruptThumbUrl)));

        // Stale disk entry still renders with 0 preview GETs; missing resolves false with 0 GETs.
        final _FakeCacheManager staleCache = _FakeCacheManager(tempDir)
          ..seed(
            thumbUrl,
            _kTinyPng,
            validTill: DateTime.now().subtract(const Duration(hours: 1)),
          );
        bool? staleResolved;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ForkCacheOnlyPreviewImage(
                descriptor: const ForkThumbnailDescriptor(url: thumbUrl),
                fit: BoxFit.contain,
                cacheManager: staleCache,
                fallback: const Text('FALLBACK_STALE'),
                onCacheStateResolved: (bool cached) => staleResolved = cached,
              ),
            ),
          ),
        );
        await _pumpUntil(tester, () => staleResolved != null);
        expect(staleResolved, isTrue);
        expect(find.byType(Image), findsOneWidget);
        expect(staleCache.getFileStreamCalls, isEmpty);

        final _FakeCacheManager emptyCache = _FakeCacheManager(tempDir);
        bool? missingResolved;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ForkCacheOnlyPreviewImage(
                descriptor: const ForkThumbnailDescriptor(url: thumbUrl),
                fit: BoxFit.contain,
                cacheManager: emptyCache,
                fallback: const Text('FALLBACK_MISSING'),
                onCacheStateResolved: (bool cached) => missingResolved = cached,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 20));
        expect(missingResolved, isFalse);
        expect(find.text('FALLBACK_MISSING'), findsOneWidget);
        expect(emptyCache.getFileStreamCalls, isEmpty);
      },
    );

    testWidgets(
      'first raster load uses 120ms crossfade while revisit uses Duration.zero',
      (WidgetTester tester) async {
        final BaseCacheManager originalCm =
            CachedNetworkImageProvider.defaultCacheManager;
        final _FakeCacheManager cache = _FakeCacheManager(tempDir);
        CachedNetworkImageProvider.defaultCacheManager = cache;
        addTearDown(
          () => CachedNetworkImageProvider.defaultCacheManager = originalCm,
        );
        addTearDown(SeenMediaUrls.clear);
        SeenMediaUrls.clear();

        const String thumbUrl =
            'https://media.tyne.test/attachments/1/7/xfade.png?format=webp&width=320';
        const String fullUrl =
            'https://media.tyne.test/attachments/1/7/xfade.png';
        cache
          ..seed(thumbUrl, _kTinyPng)
          ..seed(fullUrl, _kTinyPng);

        const AttachmentMediaViewerItem item = AttachmentMediaViewerItem(
          url: fullUrl,
          filename: 'xfade.png',
          forkPreview: ForkThumbnailDescriptor(url: thumbUrl),
          width: 400,
          height: 300,
          proxyUrl: fullUrl,
          contentType: 'image/png',
        );

        // First open (unseen): AnimatedOpacity duration must be 120 ms!
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: ForkViewerPageImage(
                  key: const ValueKey<String>('first'),
                  item: item,
                  imageUrl: fullUrl,
                  decodeCap: 2048,
                  isPortrait: false,
                  shouldLoadFullRes: true,
                  errorPlaceholder: const Text('ERR'),
                  cacheManager: cache,
                ),
              ),
            ),
          ),
        );
        await _pumpUntil(tester, () => SeenMediaUrls.contains(fullUrl));
        final AnimatedOpacity firstFade = tester.widget<AnimatedOpacity>(
          find.byType(AnimatedOpacity),
        );
        expect(firstFade.duration, kForkViewerCrossfadeDuration);

        // Now fullUrl is in SeenMediaUrls -> revisit uses Duration.zero!
        expect(SeenMediaUrls.contains(fullUrl), isTrue);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: ForkViewerPageImage(
                  key: const ValueKey<String>('revisit'),
                  item: item,
                  imageUrl: fullUrl,
                  decodeCap: 2048,
                  isPortrait: false,
                  shouldLoadFullRes: true,
                  errorPlaceholder: const Text('ERR'),
                  cacheManager: cache,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        final AnimatedOpacity revisitFade = tester.widget<AnimatedOpacity>(
          find.byType(AnimatedOpacity),
        );
        expect(revisitFade.duration, Duration.zero);
      },
    );

    testWidgets(
      'cancels promoted transfer on navigation/dispose and aborts stalled promotion after grace period',
      (WidgetTester tester) async {
        final BaseCacheManager originalCm =
            CachedNetworkImageProvider.defaultCacheManager;
        final _FakeCacheManager fakeCache = _FakeCacheManager(tempDir);
        CachedNetworkImageProvider.defaultCacheManager = fakeCache;
        addTearDown(
          () => CachedNetworkImageProvider.defaultCacheManager = originalCm,
        );

        const String mediaBase = 'https://media.tyne.test';
        final List<AttachmentMediaViewerItem> items = List.generate(
          3,
          (int i) => AttachmentMediaViewerItem(
            url: '$mediaBase/attachments/1/$i/prom$i.png',
            filename: 'prom$i.png',
            proxyUrl: '$mediaBase/attachments/1/$i/prom$i.png',
            width: 400,
            height: 300,
            contentType: 'image/png',
          ),
        );

        // Part 1: navigating away (shouldLoadFullRes -> false) cancels promoted handle.
        final StreamController<Uint8List> stream1 = StreamController<Uint8List>(
          onCancel: _immediateCancelFuture,
        );
        final Completer<void> started1 = Completer<void>();
        bool cancelled1 = false;
        final _FakeDioAdapter adapter1 = _FakeDioAdapter((
          RequestOptions options,
          _,
          Future<void>? cancelFuture,
        ) async {
          if (!started1.isCompleted) {
            started1.complete();
          }
          unawaited(cancelFuture?.then((_) => cancelled1 = true));
          return ResponseBody(stream1.stream, 200);
        });
        final ForkMediaViewerPreloader preloader1 = ForkMediaViewerPreloader(
          items: items,
          readHdrDisplayMode: () => HdrDisplayMode.full,
          cacheManager: fakeCache,
          dio: Dio()..httpClientAdapter = adapter1,
          readPreloadRadius: () async => 1,
          readMediaEndpoint: () => mediaBase,
        );
        addTearDown(preloader1.dispose);
        preloader1.scheduleAround(0);
        await tester.pump(const Duration(milliseconds: 10));
        expect(started1.isCompleted, isTrue);
        preloader1.onNavigationStarted(nextTargetUrl: items[1].url);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ForkViewerPageImage(
                item: items[1],
                imageUrl: items[1].url,
                decodeCap: 2048,
                isPortrait: false,
                shouldLoadFullRes: true,
                errorPlaceholder: const Text('ERR'),
                preloader: preloader1,
                cacheManager: fakeCache,
              ),
            ),
          ),
        );
        expect(cancelled1, isFalse);

        // Transition shouldLoadFullRes to false -> cancels promoted transfer!
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ForkViewerPageImage(
                item: items[1],
                imageUrl: items[1].url,
                decodeCap: 2048,
                isPortrait: false,
                shouldLoadFullRes: false,
                errorPlaceholder: const Text('ERR'),
                preloader: preloader1,
                cacheManager: fakeCache,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 10));
        expect(cancelled1, isTrue);
        unawaited(stream1.close());

        // Part 2: stalled promoted transfer falls back to foreground after promotedStallTimeout.
        final StreamController<Uint8List> stream2 = StreamController<Uint8List>(
          onCancel: _immediateCancelFuture,
        );
        final Completer<void> started2 = Completer<void>();
        bool cancelled2 = false;
        final _FakeDioAdapter adapter2 = _FakeDioAdapter((
          RequestOptions options,
          _,
          Future<void>? cancelFuture,
        ) async {
          if (!started2.isCompleted) {
            started2.complete();
          }
          unawaited(cancelFuture?.then((_) => cancelled2 = true));
          return ResponseBody(stream2.stream, 200);
        });
        final ForkMediaViewerPreloader preloader2 = ForkMediaViewerPreloader(
          items: items,
          readHdrDisplayMode: () => HdrDisplayMode.full,
          cacheManager: fakeCache,
          dio: Dio()..httpClientAdapter = adapter2,
          readPreloadRadius: () async => 1,
          readMediaEndpoint: () => mediaBase,
        );
        addTearDown(preloader2.dispose);
        preloader2.scheduleAround(0);
        await tester.pump(const Duration(milliseconds: 10));
        expect(started2.isCompleted, isTrue);
        preloader2.onNavigationStarted(nextTargetUrl: items[1].url);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ForkViewerPageImage(
                key: const ValueKey<String>('stalled'),
                item: items[1],
                imageUrl: items[1].url,
                decodeCap: 2048,
                isPortrait: false,
                shouldLoadFullRes: true,
                errorPlaceholder: const Text('ERR'),
                preloader: preloader2,
                cacheManager: fakeCache,
                promotedStallTimeout: const Duration(milliseconds: 50),
              ),
            ),
          ),
        );
        expect(find.byType(ChatNetworkImage), findsNothing);
        await tester.pump(const Duration(milliseconds: 60));
        for (int i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 10));
        }
        expect(cancelled2, isTrue);
        expect(find.byType(ChatNetworkImage), findsOneWidget);
        unawaited(stream2.close());
      },
    );

    testWidgets(
      'PageView swipe onto an actively preloading neighbor promotes it without cancelling',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        const String mediaBase = 'https://media.tyne.test';
        final BaseCacheManager originalCm =
            CachedNetworkImageProvider.defaultCacheManager;
        final _FakeCacheManager cache = _FakeCacheManager(tempDir);
        CachedNetworkImageProvider.defaultCacheManager = cache;
        addTearDown(
          () => CachedNetworkImageProvider.defaultCacheManager = originalCm,
        );

        final List<AttachmentMediaViewerItem> items = List.generate(
          3,
          (int i) => AttachmentMediaViewerItem(
            url: '$mediaBase/attachments/1/$i/swipe$i.png',
            filename: 'swipe$i.png',
            proxyUrl: '$mediaBase/attachments/1/$i/swipe$i.png',
            width: 400,
            height: 300,
            contentType: 'image/png',
          ),
        );
        // Seed page 0 so it finishes loading immediately and starts preloading page 1.
        cache.seed(items[0].url, _kTinyPng);

        final StreamController<Uint8List> page1Stream =
            StreamController<Uint8List>(onCancel: _immediateCancelFuture);
        final Completer<void> page1Started = Completer<void>();
        bool page1Cancelled = false;
        int page1Calls = 0;
        final _FakeDioAdapter adapter = _FakeDioAdapter((
          RequestOptions options,
          _,
          Future<void>? cancelFuture,
        ) async {
          if (options.uri.toString() == items[1].url && page1Calls++ == 0) {
            if (!page1Started.isCompleted) {
              page1Started.complete();
            }
            unawaited(cancelFuture?.then((_) => page1Cancelled = true));
            return ResponseBody(page1Stream.stream, 200);
          }
          return ResponseBody.fromBytes(_kTinyPng, 200);
        });

        final ForkMediaViewerPreloader preloader = ForkMediaViewerPreloader(
          items: items,
          readHdrDisplayMode: () => HdrDisplayMode.full,
          cacheManager: cache,
          dio: Dio()..httpClientAdapter = adapter,
          readPreloadRadius: () async => 1,
          readMediaEndpoint: () => mediaBase,
        );
        addTearDown(preloader.dispose);

        await tester.pumpWidget(
          _app(
            AttachmentMediaViewerShell(
              items: items,
              initialIndex: 0,
              forkPreloader: preloader,
            ),
            extraOverrides: <Override>[
              inputModalityProvider.overrideWith(_MousePrimaryModality.new),
            ],
          ),
        );
        await _pumpUntil(tester, () => page1Started.isCompleted);
        await tester.pump(const Duration(milliseconds: 10));
        expect(page1Started.isCompleted, isTrue);
        expect(page1Cancelled, isFalse);

        // Swipe PageView left from page 0 to page 1.
        await tester.drag(find.byType(PageView), const Offset(-320, 0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Page 1's speculative transfer MUST still be alive (promoted, NOT cancelled)!
        expect(page1Cancelled, isFalse);
        expect(
          adapter.requests.where((r) => r.uri.toString() == items[1].url),
          hasLength(1),
        );

        page1Stream.add(_kTinyPng);
        unawaited(page1Stream.close());
        await tester.pump(const Duration(milliseconds: 20));
        await _pumpUntil(tester, () => SeenMediaUrls.contains(items[1].url));
        expect(
          adapter.requests.where((r) => r.uri.toString() == items[1].url),
          hasLength(1),
        );
      },
    );

    testWidgets(
      'RAM-cached preview resolves synchronously with 0 disk/network lookups',
      (WidgetTester tester) async {
        const String thumbUrl =
            'https://media.tyne.test/attachments/1/3/ram.png?format=webp&width=320';
        final _FakeCacheManager cache = _FakeCacheManager(tempDir);
        final CachedNetworkImageProvider provider = CachedNetworkImageProvider(
          thumbUrl,
          cacheManager: cache,
        );
        final Object key = await provider.obtainKey(ImageConfiguration.empty);

        // Seed Flutter's RAM ImageCache directly with a 1x1 decoded ui.Image.
        final ui.Image decoded = (await tester.runAsync(() async {
          final ui.Codec codec = await ui.instantiateImageCodec(_kTinyPng);
          final ui.FrameInfo frame = await codec.getNextFrame();
          return frame.image;
        }))!;
        addTearDown(decoded.dispose);
        PaintingBinding.instance.imageCache.putIfAbsent(
          key,
          () => OneFrameImageStreamCompleter(
            Future<ImageInfo>.value(ImageInfo(image: decoded.clone())),
          ),
        );
        addTearDown(PaintingBinding.instance.imageCache.clear);

        bool? resolvedCached;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ForkCacheOnlyPreviewImage(
                descriptor: const ForkThumbnailDescriptor(url: thumbUrl),
                fit: BoxFit.contain,
                cacheManager: cache,
                fallback: const Text('NO_RAM_HIT'),
                onCacheStateResolved: (bool cached) => resolvedCached = cached,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(resolvedCached, isTrue);
        expect(find.text('NO_RAM_HIT'), findsNothing);
        expect(find.byType(Image), findsOneWidget);
        expect(cache.getFileStreamCalls, isEmpty);
      },
    );
  });

  group('neighbour preloading waits for the settled page', () {
    Future<
      ({
        List<AttachmentMediaViewerItem> items,
        _FakeCacheManager cache,
        _FakeDioAdapter adapter,
        ForkMediaViewerPreloader preloader,
      })
    >
    pumpGallery(WidgetTester tester, String name) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      const String mediaBase = 'https://media.tyne.test';
      final BaseCacheManager originalCm =
          CachedNetworkImageProvider.defaultCacheManager;
      final _FakeCacheManager cache = _FakeCacheManager(tempDir);
      CachedNetworkImageProvider.defaultCacheManager = cache;
      addTearDown(
        () => CachedNetworkImageProvider.defaultCacheManager = originalCm,
      );
      final List<AttachmentMediaViewerItem> items = List.generate(
        3,
        (int i) => AttachmentMediaViewerItem(
          url: '$mediaBase/attachments/1/$i/$name$i.png',
          filename: '$name$i.png',
          proxyUrl: '$mediaBase/attachments/1/$i/$name$i.png',
          width: 400,
          height: 300,
          contentType: 'image/png',
        ),
      );
      final _FakeDioAdapter adapter = _FakeDioAdapter(
        (RequestOptions _, _, _) async =>
            ResponseBody.fromBytes(_kTinyPng, 200),
      );
      final ForkMediaViewerPreloader preloader = ForkMediaViewerPreloader(
        items: items,
        readHdrDisplayMode: () => HdrDisplayMode.full,
        cacheManager: cache,
        dio: Dio()..httpClientAdapter = adapter,
        readPreloadRadius: () async => 1,
        readMediaEndpoint: () => mediaBase,
      );
      addTearDown(preloader.dispose);
      return (
        items: items,
        cache: cache,
        adapter: adapter,
        preloader: preloader,
      );
    }

    Widget shell(
      List<AttachmentMediaViewerItem> items,
      ForkMediaViewerPreloader preloader,
    ) => _app(
      AttachmentMediaViewerShell(
        items: items,
        initialIndex: 0,
        forkPreloader: preloader,
      ),
      extraOverrides: <Override>[
        inputModalityProvider.overrideWith(_MousePrimaryModality.new),
      ],
    );

    testWidgets(
      'sends no neighbour request while the settled page fails on the network, then preloads once it loads',
      (WidgetTester tester) async {
        final setup = await pumpGallery(tester, 'netfail');

        // Page 0 is not in the cache, so every foreground attempt fails with a
        // network error and keeps retrying (1 s, 2 s, 4 s, 8 s, then 16 s).
        await tester.pumpWidget(shell(setup.items, setup.preloader));
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(seconds: 1));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
        }
        expect(
          setup.cache.getFileStreamCalls
              .where((String url) => url == setup.items[0].url)
              .length,
          greaterThanOrEqualTo(4),
        );
        expect(setup.adapter.requests, isEmpty);

        // The connection recovers: the next retry loads page 0, and only then
        // does the preloader fetch its neighbour, once.
        setup.cache.seed(setup.items[0].url, _kTinyPng);
        for (int i = 0; i < 20 && setup.adapter.requests.isEmpty; i++) {
          await tester.pump(const Duration(seconds: 1));
          await _pumpUntil(
            tester,
            () => setup.adapter.requests.isNotEmpty,
            maxTurns: 3,
          );
        }
        expect(
          setup.adapter.requests.map((RequestOptions r) => r.uri.toString()),
          <String>[setup.items[1].url],
        );
      },
    );

    testWidgets('preloads neighbours when the settled page cannot be decoded', (
      WidgetTester tester,
    ) async {
      final setup = await pumpGallery(tester, 'undecodable');
      // The bytes arrive but are not an image: retrying cannot fix that.
      setup.cache.seed(
        setup.items[0].url,
        Uint8List.fromList(<int>[0, 1, 2, 3, 4, 5, 6, 7]),
      );

      await tester.pumpWidget(shell(setup.items, setup.preloader));
      await _pumpUntil(
        tester,
        () => find.byType(MediaLoadErrorPlaceholder).evaluate().isNotEmpty,
        maxTurns: 100,
      );
      // The page shows its error (and so does its strip thumbnail).
      expect(find.byType(MediaLoadErrorPlaceholder), findsWidgets);
      // Dio's request path needs fake time to advance, not only microtasks.
      for (int i = 0; i < 20 && setup.adapter.requests.isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        await _pumpUntil(
          tester,
          () => setup.adapter.requests.isNotEmpty,
          maxTurns: 3,
        );
      }
      expect(
        setup.adapter.requests.map((RequestOptions r) => r.uri.toString()),
        <String>[setup.items[1].url],
      );
    });
  });

  group('mature media fail-closed & reveal persistence across PageView', () {
    testWidgets('withholds mature page when channelId is null', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final List<AttachmentMediaViewerItem> items = List.generate(
        3,
        (int i) => AttachmentMediaViewerItem(
          url: 'https://media.tyne.test/attachments/1/$i/m$i.png',
          filename: 'm$i.png',
          isMatureMedia: i == 0,
          width: 800,
          height: 600,
        ),
      );

      await tester.pumpWidget(
        _app(AttachmentMediaViewerShell(items: items, initialIndex: 0)),
      );
      await tester.pump();
      expect(find.byType(ForkViewerPageImage), findsNothing);
    });

    testWidgets(
      'persists reveal across PageView disposal/remount while keeping strip hidden',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final List<AttachmentMediaViewerItem> items = List.generate(
          5,
          (int i) => AttachmentMediaViewerItem(
            url: 'https://media.tyne.test/attachments/1/$i/m$i.png',
            filename: 'm$i.png',
            isMatureMedia: i == 0,
            width: 800,
            height: 600,
          ),
        );

        await tester.pumpWidget(
          _app(
            AttachmentMediaViewerShell(
              items: items,
              initialIndex: 0,
              channelId: 'channel-1',
            ),
            extraOverrides: <Override>[
              inputModalityProvider.overrideWith(_MousePrimaryModality.new),
              matureMediaPolicyProvider(
                const MatureMediaPolicyRequest(
                  channelId: 'channel-1',
                  isMatureMedia: true,
                ),
              ).overrideWith(
                (ref) => const MatureMediaPolicy(
                  shouldBlur: true,
                  shouldBlock: false,
                  canReveal: true,
                ),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Before reveal: Reveal button visible; strip tile 0 is hidden.
        expect(find.text('Reveal'), findsOneWidget);
        expect(find.byType(ForkViewerStripThumbnail), findsNWidgets(4));

        // Tap Reveal -> revealed! (Wait past ancestor DoubleTapGestureRecognizer timeout.)
        await tester.tap(find.text('Reveal'));
        await tester.pump(kDoubleTapTimeout);
        await tester.pump();
        expect(find.text('Reveal'), findsNothing);
        // Strip stays unconditionally hidden for mature item 0 even after reveal.
        expect(find.byType(ForkViewerStripThumbnail), findsNWidgets(4));

        // Jump to page 4 (unmounts page 0 from PageView) and back to page 0.
        final PageController controller =
            tester.widget<PageView>(find.byType(PageView)).controller!
              ..jumpToPage(4);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        controller.jumpToPage(0);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Reveal state persisted across unmount/remount!
        expect(find.text('Reveal'), findsNothing);
      },
    );
  });

  group('scroll settle gating & strip thumbnail fallback', () {
    testWidgets(
      'strip jump 0 -> 9 activates full-res only for pages 0 and 9 (0 transient pages)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final List<AttachmentMediaViewerItem> items = List.generate(
          10,
          (int i) => AttachmentMediaViewerItem(
            url: 'https://media.tyne.test/attachments/1/$i/p$i.png',
            filename: 'p$i.png',
            forkPreview: ForkThumbnailDescriptor(
              url:
                  'https://media.tyne.test/attachments/1/$i/p$i.png?format=webp&width=320',
            ),
            width: 800,
            height: 600,
          ),
        );

        await tester.pumpWidget(
          _app(
            AttachmentMediaViewerShell(items: items, initialIndex: 0),
            extraOverrides: <Override>[
              inputModalityProvider.overrideWith(_MousePrimaryModality.new),
            ],
          ),
        );
        await tester.pump();

        // Record every ForkViewerPageImage that ever had shouldLoadFullRes == true.
        final Set<String> activatedUrls = <String>{};
        void recordActive() {
          for (final ForkViewerPageImage w
              in tester.widgetList<ForkViewerPageImage>(
                find.byType(ForkViewerPageImage),
              )) {
            if (w.shouldLoadFullRes) {
              activatedUrls.add(w.imageUrl);
            }
          }
        }

        recordActive();
        expect(activatedUrls, <String>{items[0].url});

        // Tap the last strip thumbnail (index 9).
        final Finder stripTiles = find.byType(ForkViewerStripThumbnail);
        expect(stripTiles, findsNWidgets(10));
        await tester.ensureVisible(stripTiles.last);
        await tester.tap(stripTiles.last, warnIfMissed: false);
        // Sample mid-flight frames during the 180ms animation.
        for (int i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 35));
          recordActive();
        }
        await tester.pump(const Duration(milliseconds: 100));
        recordActive();

        expect(activatedUrls, <String>{items[0].url, items[9].url});
      },
    );

    testWidgets(
      'reversed drag back to page 0 never activates full-res for page 1',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final List<AttachmentMediaViewerItem> items = List.generate(
          3,
          (int i) => AttachmentMediaViewerItem(
            url: 'https://media.tyne.test/attachments/1/$i/drag$i.png',
            filename: 'drag$i.png',
            forkPreview: ForkThumbnailDescriptor(
              url:
                  'https://media.tyne.test/attachments/1/$i/drag$i.png?format=webp&width=320',
            ),
            width: 800,
            height: 600,
          ),
        );

        await tester.pumpWidget(
          _app(AttachmentMediaViewerShell(items: items, initialIndex: 0)),
        );
        await tester.pump();

        final Set<String> activatedUrls = <String>{};
        void recordActive() {
          for (final ForkViewerPageImage w
              in tester.widgetList<ForkViewerPageImage>(
                find.byType(ForkViewerPageImage),
              )) {
            if (w.shouldLoadFullRes) {
              activatedUrls.add(w.imageUrl);
            }
          }
        }

        recordActive();
        final Offset center = tester.getCenter(find.byType(PageView));
        final TestGesture gesture = await tester.startGesture(center);
        await gesture.moveBy(const Offset(-120, 0));
        await tester.pump(const Duration(milliseconds: 16));
        recordActive();
        await gesture.moveBy(const Offset(100, 0));
        await tester.pump(const Duration(milliseconds: 16));
        recordActive();
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 500));
        recordActive();

        expect(activatedUrls, <String>{items[0].url});
      },
    );

    testWidgets(
      'ForkViewerStripThumbnail falls back to single-width 56dp thumbnail when uncached',
      (WidgetTester tester) async {
        const String mediaBase = 'https://media.tyne.test';
        const String fullUrl = '$mediaBase/attachments/1/1/big.jpg';
        final _FakeCacheManager emptyCache = _FakeCacheManager(tempDir);

        await tester.pumpWidget(
          _app(
            SizedBox(
              width: 56,
              height: 56,
              child: ForkViewerStripThumbnail(
                item: const AttachmentMediaViewerItem(
                  url: fullUrl,
                  filename: 'big.jpg',
                  width: 4000,
                  height: 3000,
                  proxyUrl: fullUrl,
                  contentType: 'image/jpeg',
                ),
                hdrDisplayMode: HdrDisplayMode.full,
                devicePixelRatio: 3,
                decodeCap: 168,
                isLandscape: true,
                cacheManager: emptyCache,
                mediaEndpoint: mediaBase,
              ),
            ),
          ),
        );
        await tester.pump();

        final ChatNetworkImage stripImg = tester.widget<ChatNetworkImage>(
          find.byType(ChatNetworkImage),
        );
        final Uri uri = Uri.parse(stripImg.imageUrl);
        expect(uri.queryParameters['format'], 'webp');
        expect(uri.queryParameters['quality'], 'high');
        expect(uri.queryParameters['width'], isNotNull);
        expect(uri.queryParameters['height'], isNull);
        expect(int.parse(uri.queryParameters['width']!), lessThan(1000));
      },
    );

    testWidgets(
      'unmounts ForkCacheOnlyPreviewImage immediately when preview is uncached or loses decode race to full-res',
      (WidgetTester tester) async {
        final BaseCacheManager originalCm =
            CachedNetworkImageProvider.defaultCacheManager;
        final _FakeCacheManager cache = _FakeCacheManager(tempDir);
        CachedNetworkImageProvider.defaultCacheManager = cache;
        addTearDown(
          () => CachedNetworkImageProvider.defaultCacheManager = originalCm,
        );
        addTearDown(SeenMediaUrls.clear);
        SeenMediaUrls.clear();

        const String thumbUrl =
            'https://media.tyne.test/attachments/1/99/uncached.png?format=webp&width=320';
        const String fullUrl =
            'https://media.tyne.test/attachments/1/99/uncached.png';
        // Seed ONLY fullUrl (preview is a cache miss with a thumbHash fallback).
        cache.seed(fullUrl, _kTinyPng);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: ForkViewerPageImage(
                  item: const AttachmentMediaViewerItem(
                    url: fullUrl,
                    filename: 'uncached.png',
                    forkPreview: ForkThumbnailDescriptor(url: thumbUrl),
                    width: 400,
                    height: 300,
                    proxyUrl: fullUrl,
                    contentType: 'image/png',
                  ),
                  imageUrl: fullUrl,
                  decodeCap: 2048,
                  isPortrait: false,
                  shouldLoadFullRes: true,
                  errorPlaceholder: const Text('ERR'),
                  cacheManager: cache,
                ),
              ),
            ),
          ),
        );
        await _pumpUntil(tester, () => SeenMediaUrls.contains(fullUrl));
        await tester.pump();

        // Even though AnimatedOpacity never transitioned (1.0 -> 1.0), the
        // preview layer must be unmounted once full-res loads!
        expect(find.byType(ForkCacheOnlyPreviewImage), findsNothing);

        // Part 2 (F-034): sub-frame coalesced race where preview's post-frame
        // callback sets _hasCachedPreview = true at the end of frame 1 (while
        // _lastBuiltFullResOpacity is still 1.0) AND async full-res completes
        // before frame 2 ever builds AnimatedOpacity(opacity: 0.0).
        const String thumbUrl2 =
            'https://media.tyne.test/attachments/1/99/coalesced.png?format=webp&width=320';
        const String fullUrl2 =
            'https://media.tyne.test/attachments/1/99/coalesced.png';
        final ui.Image decoded = (await tester.runAsync(() async {
          final ui.Codec codec = await ui.instantiateImageCodec(_kTinyPng);
          final ui.FrameInfo frame = await codec.getNextFrame();
          return frame.image;
        }))!;
        addTearDown(decoded.dispose);
        addTearDown(PaintingBinding.instance.imageCache.clear);

        final Object thumbKey2 = await CachedNetworkImageProvider(
          thumbUrl2,
          cacheManager: cache,
        ).obtainKey(ImageConfiguration.empty);
        final Object fullKey2 = await const CachedNetworkImageProvider(
          fullUrl2,
        ).obtainKey(ImageConfiguration.empty);
        final Completer<ImageInfo> fullDecodeCompleter = Completer<ImageInfo>();
        PaintingBinding.instance.imageCache.putIfAbsent(
          thumbKey2,
          () => OneFrameImageStreamCompleter(
            Future<ImageInfo>.value(ImageInfo(image: decoded.clone())),
          ),
        );
        PaintingBinding.instance.imageCache.putIfAbsent(
          fullKey2,
          () => OneFrameImageStreamCompleter(fullDecodeCompleter.future),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: ForkViewerPageImage(
                  key: const ValueKey<String>('coalesced_race'),
                  item: const AttachmentMediaViewerItem(
                    url: fullUrl2,
                    filename: 'coalesced.png',
                    forkPreview: ForkThumbnailDescriptor(url: thumbUrl2),
                    width: 400,
                    height: 300,
                    proxyUrl: fullUrl2,
                    contentType: 'image/png',
                  ),
                  imageUrl: fullUrl2,
                  decodeCap: null,
                  isPortrait: false,
                  shouldLoadFullRes: true,
                  errorPlaceholder: const Text('ERR'),
                  cacheManager: cache,
                ),
              ),
            ),
          ),
        );
        // Complete full-res asynchronously right after frame 1's post-frame
        // callbacks ran (_hasCachedPreview == true, _lastBuiltFullResOpacity == 1.0)
        // and before frame 2 builds!
        fullDecodeCompleter.complete(ImageInfo(image: decoded.clone()));
        await tester.pump();
        expect(SeenMediaUrls.contains(fullUrl2), isTrue);
        expect(find.byType(ForkCacheOnlyPreviewImage), findsNothing);
      },
    );

    testWidgets(
      'promoted 429 holds foreground GET until Retry-After deadline expires, and pre-header TTFB wait is not treated as a stall',
      (WidgetTester tester) async {
        final BaseCacheManager originalCm =
            CachedNetworkImageProvider.defaultCacheManager;
        final _FakeCacheManager fakeCache = _FakeCacheManager(tempDir);
        CachedNetworkImageProvider.defaultCacheManager = fakeCache;
        addTearDown(
          () => CachedNetworkImageProvider.defaultCacheManager = originalCm,
        );
        addTearDown(SeenMediaUrls.clear);
        SeenMediaUrls.clear();

        const String mediaBase = 'https://media.tyne.test';
        final List<AttachmentMediaViewerItem> items = List.generate(
          3,
          (int i) => AttachmentMediaViewerItem(
            url: '$mediaBase/attachments/1/$i/rl$i.png',
            filename: 'rl$i.png',
            proxyUrl: '$mediaBase/attachments/1/$i/rl$i.png',
            width: 400,
            height: 300,
            contentType: 'image/png',
          ),
        );

        // 1) Promoted 429 with Retry-After: 30 -> foreground issues 0 GETs before 30s!
        DateTime clock = DateTime.utc(2026, 11, 24, 12);
        final Completer<ResponseBody> response429 = Completer<ResponseBody>();
        final Completer<void> started429 = Completer<void>();
        final _FakeDioAdapter adapter429 = _FakeDioAdapter((
          RequestOptions options,
          _,
          _,
        ) async {
          if (!started429.isCompleted) {
            started429.complete();
          }
          return await response429.future;
        });
        final ForkMediaViewerPreloader preloader429 = ForkMediaViewerPreloader(
          items: items,
          readHdrDisplayMode: () => HdrDisplayMode.full,
          cacheManager: fakeCache,
          dio: Dio(
            BaseOptions(
              followRedirects: false,
              validateStatus: (int? s) => s != null && s >= 200 && s < 400,
            ),
          )..httpClientAdapter = adapter429,
          readPreloadRadius: () async => 1,
          readMediaEndpoint: () => mediaBase,
          now: () => clock,
        );
        addTearDown(preloader429.dispose);

        preloader429.scheduleAround(0);
        await tester.pump(const Duration(milliseconds: 10));
        expect(started429.isCompleted, isTrue);
        preloader429.onNavigationStarted(nextTargetUrl: items[1].url);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ForkViewerPageImage(
                key: const ValueKey<String>('rl429'),
                item: items[1],
                imageUrl: items[1].url,
                decodeCap: 2048,
                isPortrait: false,
                shouldLoadFullRes: true,
                errorPlaceholder: const Text('ERR'),
                preloader: preloader429,
                cacheManager: fakeCache,
              ),
            ),
          ),
        );

        response429.complete(
          ResponseBody.fromString(
            '',
            429,
            headers: <String, List<String>>{
              'retry-after': <String>['120'],
            },
          ),
        );
        await tester.pump(const Duration(milliseconds: 20));

        // At +5s: 0 foreground getFileStream calls!
        clock = clock.add(const Duration(seconds: 5));
        await tester.pump(const Duration(seconds: 5));
        expect(fakeCache.getFileStreamCalls, isEmpty);
        expect(find.byType(ChatNetworkImage), findsNothing);

        // Swiping away (shouldLoadFullRes -> false) and back (true) at +5s
        // still honors the remaining foreground hold (F-043 / F-013)!
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ForkViewerPageImage(
                key: const ValueKey<String>('rl429'),
                item: items[1],
                imageUrl: items[1].url,
                decodeCap: 2048,
                isPortrait: false,
                shouldLoadFullRes: false,
                errorPlaceholder: const Text('ERR'),
                preloader: preloader429,
                cacheManager: fakeCache,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ForkViewerPageImage(
                key: const ValueKey<String>('rl429'),
                item: items[1],
                imageUrl: items[1].url,
                decodeCap: 2048,
                isPortrait: false,
                shouldLoadFullRes: true,
                errorPlaceholder: const Text('ERR'),
                preloader: preloader429,
                cacheManager: fakeCache,
              ),
            ),
          ),
        );
        clock = clock.add(const Duration(seconds: 5));
        await tester.pump(const Duration(seconds: 5));
        expect(fakeCache.getFileStreamCalls, isEmpty);
        expect(find.byType(ChatNetworkImage), findsNothing);

        // At +16s (past 15s kForkViewerForegroundMaxRateLimitHold cap, even
        // though Retry-After was 120s): foreground GET IS allowed so the
        // visible page never freezes for minutes, while speculative preloading
        // STILL honors the full 120s Retry-After!
        clock = clock.add(const Duration(seconds: 6));
        await tester.pump(const Duration(seconds: 6));
        for (int i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 20));
        }
        expect(find.byType(ChatNetworkImage), findsOneWidget);
        expect(fakeCache.getFileStreamCalls, contains(items[1].url));

        preloader429.scheduleAround(0);
        await tester.pump(const Duration(milliseconds: 20));
        expect(adapter429.requests, hasLength(1));

        // 2) Pre-header TTFB wait (120ms) > promotedStallTimeout (50ms) does NOT abort healthy transform!
        bool preHeaderCancelled = false;
        final Completer<void> preHeaderStarted = Completer<void>();
        final _FakeDioAdapter slowHeaderAdapter = _FakeDioAdapter((
          RequestOptions options,
          _,
          Future<void>? cancelFuture,
        ) async {
          if (!preHeaderStarted.isCompleted) {
            preHeaderStarted.complete();
          }
          unawaited(cancelFuture?.then((_) => preHeaderCancelled = true));
          await Future<void>.delayed(const Duration(milliseconds: 120));
          return ResponseBody.fromBytes(_kTinyPng, 200);
        });
        final ForkMediaViewerPreloader preloaderSlowHeader =
            ForkMediaViewerPreloader(
              items: items,
              readHdrDisplayMode: () => HdrDisplayMode.full,
              cacheManager: fakeCache,
              dio: Dio()..httpClientAdapter = slowHeaderAdapter,
              readPreloadRadius: () async => 1,
              readMediaEndpoint: () => mediaBase,
            );
        addTearDown(preloaderSlowHeader.dispose);

        preloaderSlowHeader.scheduleAround(0);
        await tester.pump(const Duration(milliseconds: 10));
        expect(preHeaderStarted.isCompleted, isTrue);
        preloaderSlowHeader.onNavigationStarted(nextTargetUrl: items[1].url);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ForkViewerPageImage(
                key: const ValueKey<String>('slow_headers'),
                item: items[1],
                imageUrl: items[1].url,
                decodeCap: 2048,
                isPortrait: false,
                shouldLoadFullRes: true,
                errorPlaceholder: const Text('ERR'),
                preloader: preloaderSlowHeader,
                cacheManager: fakeCache,
                promotedStallTimeout: const Duration(milliseconds: 50),
              ),
            ),
          ),
        );

        // Pump 80ms (> 50ms stall timeout, still waiting on headers at 120ms): NOT cancelled!
        await tester.pump(const Duration(milliseconds: 80));
        expect(preHeaderCancelled, isFalse);
        // Pump past 120ms so headers + body complete and cache cleanly in 1 request!
        await tester.pump(const Duration(milliseconds: 80));
        expect(preHeaderCancelled, isFalse);
        expect(slowHeaderAdapter.requests, hasLength(1));
      },
    );

    testWidgets(
      'reversed drag returning to same page keeps in-flight neighbor preload alive, and mid-jump drag cancels strip jump settle',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        const String mediaBase = 'https://media.tyne.test';
        final BaseCacheManager originalCm =
            CachedNetworkImageProvider.defaultCacheManager;
        final _FakeCacheManager cache = _FakeCacheManager(tempDir);
        CachedNetworkImageProvider.defaultCacheManager = cache;
        addTearDown(
          () => CachedNetworkImageProvider.defaultCacheManager = originalCm,
        );
        addTearDown(SeenMediaUrls.clear);
        SeenMediaUrls.clear();

        final List<AttachmentMediaViewerItem> items = List.generate(
          6,
          (int i) => AttachmentMediaViewerItem(
            url: '$mediaBase/attachments/1/$i/rev$i.png',
            filename: 'rev$i.png',
            proxyUrl: '$mediaBase/attachments/1/$i/rev$i.png',
            width: 800,
            height: 600,
            contentType: 'image/png',
          ),
        );
        cache.seed(items[0].url, _kTinyPng);

        final StreamController<Uint8List> page1Stream =
            StreamController<Uint8List>(onCancel: _immediateCancelFuture);
        final Completer<void> page1Started = Completer<void>();
        bool page1Cancelled = false;
        int page1Calls = 0;
        final _FakeDioAdapter adapter = _FakeDioAdapter((
          RequestOptions options,
          _,
          Future<void>? cancelFuture,
        ) async {
          if (options.uri.toString() == items[1].url && page1Calls++ == 0) {
            if (!page1Started.isCompleted) {
              page1Started.complete();
            }
            unawaited(cancelFuture?.then((_) => page1Cancelled = true));
            return ResponseBody(page1Stream.stream, 200);
          }
          return ResponseBody.fromBytes(_kTinyPng, 200);
        });

        final ForkMediaViewerPreloader preloader = ForkMediaViewerPreloader(
          items: items,
          readHdrDisplayMode: () => HdrDisplayMode.full,
          cacheManager: cache,
          dio: Dio()..httpClientAdapter = adapter,
          readPreloadRadius: () async => 2,
          readMediaEndpoint: () => mediaBase,
        );
        addTearDown(preloader.dispose);

        await tester.pumpWidget(
          _app(
            AttachmentMediaViewerShell(
              items: items,
              initialIndex: 0,
              forkPreloader: preloader,
            ),
            extraOverrides: <Override>[
              inputModalityProvider.overrideWith(_MousePrimaryModality.new),
            ],
          ),
        );
        await _pumpUntil(tester, () => page1Started.isCompleted);
        await tester.pump(const Duration(milliseconds: 10));
        expect(page1Started.isCompleted, isTrue);
        expect(page1Cancelled, isFalse);

        // 1) Start a swipe and release back on page 0 -> page 1 preload MUST stay alive!
        final Offset center = tester.getCenter(find.byType(PageView));
        final TestGesture revGesture = await tester.startGesture(center);
        await revGesture.moveBy(const Offset(-100, 0));
        await tester.pump(const Duration(milliseconds: 16));
        await revGesture.moveBy(const Offset(100, 0));
        await tester.pump(const Duration(milliseconds: 16));
        await revGesture.up();
        await tester.pump(const Duration(milliseconds: 400));

        expect(page1Cancelled, isFalse);
        expect(
          adapter.requests.where((r) => r.uri.toString() == items[1].url),
          hasLength(1),
        );

        // 2) Tap strip tile 5 (starts 180ms animateToPage), then grab mid-scroll at 60ms!
        final Finder stripTiles = find.byType(ForkViewerStripThumbnail);
        await tester.ensureVisible(stripTiles.last);
        await tester.tap(stripTiles.last, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 60));

        final Set<String> midDragActivated = <String>{};
        void recordActive() {
          for (final ForkViewerPageImage w
              in tester.widgetList<ForkViewerPageImage>(
                find.byType(ForkViewerPageImage),
              )) {
            if (w.shouldLoadFullRes) {
              midDragActivated.add(w.imageUrl);
            }
          }
        }

        // Grab PageView mid-animation and hold drag without releasing yet.
        final TestGesture midJumpDrag = await tester.startGesture(center);
        await midJumpDrag.moveBy(const Offset(60, 0));
        await tester.pump(const Duration(milliseconds: 16));
        recordActive();

        // While user is still dragging mid-jump, animateToPage's cancelled Future
        // must NOT have prematurely settled onto an intermediate transient page!
        expect(midDragActivated, <String>{items[0].url});

        await midJumpDrag.up();
        await tester.pump(const Duration(milliseconds: 500));
        preloader.dispose();
        unawaited(page1Stream.close());
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 11));
      },
    );

    testWidgets(
      'touch-mode pointer-down hold mid strip-jump does not prematurely settle fractional intermediate page',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final List<AttachmentMediaViewerItem> items = List.generate(
          6,
          (int i) => AttachmentMediaViewerItem(
            url: 'https://media.tyne.test/attachments/1/$i/hold$i.png',
            filename: 'hold$i.png',
            forkPreview: ForkThumbnailDescriptor(
              url:
                  'https://media.tyne.test/attachments/1/$i/hold$i.png?format=webp&width=320',
            ),
            width: 800,
            height: 600,
          ),
        );

        await tester.pumpWidget(
          _app(
            AttachmentMediaViewerShell(items: items, initialIndex: 0),
            extraOverrides: <Override>[
              inputModalityProvider.overrideWith(_TouchPrimaryModality.new),
            ],
          ),
        );
        await tester.pump();

        final Set<String> activatedUrls = <String>{};
        void recordActive() {
          for (final ForkViewerPageImage w
              in tester.widgetList<ForkViewerPageImage>(
                find.byType(ForkViewerPageImage),
              )) {
            if (w.shouldLoadFullRes) {
              activatedUrls.add(w.imageUrl);
            }
          }
        }

        recordActive();
        expect(activatedUrls, <String>{items[0].url});

        // In touch mode, controls start hidden (tyne-chat/tyne#866); single-tap
        // the page first so the thumbnail strip becomes interactive.
        await tester.tap(find.byType(PageView));
        await tester.pump(kDoubleTapTimeout);
        await tester.pump();

        // Tap strip tile 5 -> starts 180ms animateToPage(5).
        // Step in 200 us increments until DrivenScrollActivity is mid-flight
        // right on intermediate page 2 (|page - 2| < 0.01), testing mid-jump
        // holds inside the alignment tolerance (F-040 / F-050 / F-051)!
        final Finder stripTiles = find.byType(ForkViewerStripThumbnail);
        await tester.ensureVisible(stripTiles.last);
        await tester.tap(stripTiles.last, warnIfMissed: false);
        await tester.pump();
        final PageController controller = tester
            .widget<PageView>(find.byType(PageView))
            .controller!;
        for (
          int step = 0;
          step < 600 && (controller.page! - 2).abs() >= 0.008;
          step++
        ) {
          await tester.pump(const Duration(microseconds: 200));
        }
        final double midPage = controller.page!;
        expect((midPage - 2).abs(), lessThan(0.01));

        // Touch down on PageView with ZERO drag movement -> triggers
        // _handleTouchPageDragDown -> position.hold(), cancelling animateToPage
        // and emitting ScrollEndNotification at a fractional page (F-040)!
        final Offset center = tester.getCenter(find.byType(PageView));
        final TestGesture hold = await tester.startGesture(center);
        await tester.pump(const Duration(milliseconds: 16));
        recordActive();

        // While holding at a fractional page, NO intermediate rounded page may activate!
        expect(activatedUrls, <String>{items[0].url});

        await hold.up();
        await tester.pump(const Duration(milliseconds: 500));
      },
    );

    testWidgets(
      'single-tapping idle touch viewer to toggle controls keeps preloading remaining neighbors',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        const String mediaBase = 'https://media.tyne.test';
        final BaseCacheManager originalCm =
            CachedNetworkImageProvider.defaultCacheManager;
        final _FakeCacheManager cache = _FakeCacheManager(tempDir);
        CachedNetworkImageProvider.defaultCacheManager = cache;
        addTearDown(
          () => CachedNetworkImageProvider.defaultCacheManager = originalCm,
        );
        addTearDown(SeenMediaUrls.clear);
        SeenMediaUrls.clear();

        final List<AttachmentMediaViewerItem> items = List.generate(
          4,
          (int i) => AttachmentMediaViewerItem(
            url: '$mediaBase/attachments/1/$i/tap$i.png',
            filename: 'tap$i.png',
            proxyUrl: '$mediaBase/attachments/1/$i/tap$i.png',
            width: 800,
            height: 600,
            contentType: 'image/png',
          ),
        );
        cache.seed(items[0].url, _kTinyPng);

        final StreamController<Uint8List> n1Stream =
            StreamController<Uint8List>(onCancel: _immediateCancelFuture);
        final Completer<void> n1Started = Completer<void>();
        final Completer<void> n2Requested = Completer<void>();
        int n1Calls = 0;
        final _FakeDioAdapter adapter = _FakeDioAdapter((
          RequestOptions options,
          _,
          _,
        ) async {
          final String reqUrl = options.uri.toString();
          if (reqUrl == items[1].url && n1Calls++ == 0) {
            if (!n1Started.isCompleted) {
              n1Started.complete();
            }
            return ResponseBody(n1Stream.stream, 200);
          }
          if (reqUrl == items[2].url && !n2Requested.isCompleted) {
            n2Requested.complete();
          }
          return ResponseBody.fromBytes(_kTinyPng, 200);
        });

        final ForkMediaViewerPreloader preloader = ForkMediaViewerPreloader(
          items: items,
          readHdrDisplayMode: () => HdrDisplayMode.full,
          cacheManager: cache,
          dio: Dio()..httpClientAdapter = adapter,
          readPreloadRadius: () async => 3,
          readMediaEndpoint: () => mediaBase,
        );
        addTearDown(preloader.dispose);

        await tester.pumpWidget(
          _app(
            AttachmentMediaViewerShell(
              items: items,
              initialIndex: 0,
              forkPreloader: preloader,
            ),
            extraOverrides: <Override>[
              inputModalityProvider.overrideWith(_TouchPrimaryModality.new),
            ],
          ),
        );
        await _pumpUntil(tester, () => n1Started.isCompleted);
        await tester.pump(const Duration(milliseconds: 10));
        expect(n1Started.isCompleted, isTrue);

        // Single-tap the page to show controls while neighbor 1 is in flight (F-044 / F-046)!
        await tester.tap(find.byType(PageView));
        await tester.pump(kDoubleTapTimeout);
        await tester.pump();

        // Finish neighbor 1 -> remaining neighbors (items[2], items[3]) MUST continue loading!
        n1Stream.add(_kTinyPng);
        unawaited(n1Stream.close());
        await _pumpUntil(tester, () => n2Requested.isCompleted);
        for (int i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 20));
        }

        final List<String> fetchedUrls = adapter.requests
            .map((RequestOptions r) => r.uri.toString())
            .toList();
        expect(fetchedUrls, <String>[items[1].url, items[2].url, items[3].url]);

        preloader.dispose();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 11));
      },
    );

    testWidgets(
      'unmounting touch viewer while pointer-down hold is active does not read Riverpod on inactive/disposing element',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final List<AttachmentMediaViewerItem> items = List.generate(
          3,
          (int i) => AttachmentMediaViewerItem(
            url: 'https://media.tyne.test/attachments/1/$i/disp$i.png',
            filename: 'disp$i.png',
            forkPreview: ForkThumbnailDescriptor(
              url:
                  'https://media.tyne.test/attachments/1/$i/disp$i.png?format=webp&width=320',
            ),
            width: 800,
            height: 600,
          ),
        );

        await tester.pumpWidget(
          _app(
            AttachmentMediaViewerShell(items: items, initialIndex: 0),
            extraOverrides: <Override>[
              inputModalityProvider.overrideWith(_TouchPrimaryModality.new),
            ],
          ),
        );
        await tester.pump();

        final Offset center = tester.getCenter(find.byType(PageView));
        // Supersede a first touch hold with a second pointer-down, then unmount
        // the entire viewer BEFORE releasing the pointer (F-047 / F-049)!
        final TestGesture hold1 = await tester.startGesture(center);
        await tester.pump(const Duration(milliseconds: 16));
        final TestGesture hold2 = await tester.startGesture(
          center + const Offset(10, 0),
        );
        await tester.pump(const Duration(milliseconds: 16));

        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.takeException(), isNull);

        await hold1.up();
        await hold2.up();
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
      },
    );
  });
}
