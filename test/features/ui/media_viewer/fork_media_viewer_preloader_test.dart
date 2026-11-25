// Fork (tyne-chat/tyne#887): unit tests for ForkMediaViewerPreloader,
// RFC 9111 cacheability, connectivity radius, byte budgets, promotion, and backoff.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:file/file.dart' as file_pkg;
import 'package:file/local.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/attachment_request_auth.dart';
import 'package:fluxer_app/features/settings/providers/preferences/appearance_preferences_provider.dart';
import 'package:fluxer_app/features/ui/media_viewer/attachment_media_viewer.dart';
import 'package:fluxer_app/features/ui/media_viewer/fork_media_viewer_preloader.dart';

const String _kMediaBase = 'https://media.tyne.test';

class _PutRecord {
  _PutRecord({
    required this.url,
    required this.bytes,
    required this.maxAge,
    this.eTag,
  });

  final String url;
  final Uint8List bytes;
  final Duration maxAge;
  final String? eTag;
}

class _FakeCacheManager implements BaseCacheManager {
  _FakeCacheManager(this._rootDir, {this.throwOnLookup = false});

  final Directory _rootDir;
  final bool throwOnLookup;
  final LocalFileSystem _fs = const LocalFileSystem();
  final Map<String, FileInfo> _entries = <String, FileInfo>{};
  final List<_PutRecord> puts = <_PutRecord>[];
  int _seq = 0;

  @override
  Future<FileInfo?> getFileFromCache(
    String key, {
    bool ignoreMemCache = false,
  }) async {
    if (throwOnLookup) {
      throw StateError('disk cache db corrupt');
    }
    return _entries[key];
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
    final String cacheKey = key ?? url;
    final File f = File('${_rootDir.path}/put_${_seq++}.$fileExtension')
      ..writeAsBytesSync(fileBytes);
    final file_pkg.File wrapped = _fs.file(f.path);
    final Uint8List data = Uint8List.fromList(fileBytes);
    _entries[cacheKey] = FileInfo(
      wrapped,
      FileSource.Online,
      DateTime.now().add(maxAge),
      cacheKey,
    );
    puts.add(
      _PutRecord(url: cacheKey, bytes: data, maxAge: maxAge, eTag: eTag),
    );
    return wrapped;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this.handler);

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

Dio _dioWithAdapter(_FakeHttpClientAdapter adapter) {
  return Dio(
    BaseOptions(
      followRedirects: false,
      validateStatus: (int? status) =>
          status != null && status >= 200 && status < 400,
    ),
  )..httpClientAdapter = adapter;
}

AttachmentMediaViewerItem _mediaItem(
  int index, {
  String? url,
  String? proxyUrl,
  bool isMatureMedia = false,
  bool animated = false,
  int? forkSizeBytes,
  String? contentType = 'image/jpeg',
  String? filename,
}) {
  final String resolved =
      url ?? '$_kMediaBase/attachments/1/$index/p$index.jpg';
  return AttachmentMediaViewerItem(
    url: resolved,
    filename: filename ?? 'p$index.jpg',
    forkSizeBytes: forkSizeBytes,
    proxyUrl: proxyUrl ?? resolved,
    isMatureMedia: isMatureMedia,
    animated: animated,
    contentType: contentType,
  );
}

Future<void> _pumpEventQueue([int turns = 20]) async {
  for (int i = 0; i < turns; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('tyne_preloader_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('candidate ordering & connectivity radius', () {
    test(
      'orders closest-first from interior, boundaries, and bounds 100-item gallery',
      () {
        expect(
          forkViewerPreloadCandidateIndices(
            settledIndex: 5,
            itemCount: 20,
            radius: 4,
          ),
          <int>[6, 4, 7, 3, 8, 2, 9, 1],
        );
        expect(
          forkViewerPreloadCandidateIndices(
            settledIndex: 0,
            itemCount: 20,
            radius: 4,
          ),
          <int>[1, 2, 3, 4],
        );
        expect(
          forkViewerPreloadCandidateIndices(
            settledIndex: 9,
            itemCount: 10,
            radius: 4,
          ),
          <int>[8, 7, 6, 5],
        );
        expect(
          forkViewerPreloadCandidateIndices(
            settledIndex: 50,
            itemCount: 100,
            radius: 4,
          ),
          hasLength(8),
        );
        expect(
          forkViewerPreloadCandidateIndices(
            settledIndex: 5,
            itemCount: 20,
            radius: 1,
          ),
          <int>[6, 4],
        );
        expect(
          forkViewerPreloadCandidateIndices(
            settledIndex: 5,
            itemCount: 20,
            radius: 0,
          ),
          isEmpty,
        );
      },
    );

    test('maps List<ConnectivityResult> matrix accurately', () {
      expect(
        forkPreloadRadiusForConnectivity(<ConnectivityResult>[
          ConnectivityResult.wifi,
        ]),
        4,
      );
      expect(
        forkPreloadRadiusForConnectivity(<ConnectivityResult>[
          ConnectivityResult.ethernet,
        ]),
        4,
      );
      expect(
        forkPreloadRadiusForConnectivity(<ConnectivityResult>[
          ConnectivityResult.vpn,
          ConnectivityResult.wifi,
        ]),
        4,
      );
      expect(
        forkPreloadRadiusForConnectivity(<ConnectivityResult>[
          ConnectivityResult.mobile,
        ]),
        1,
      );
      expect(
        forkPreloadRadiusForConnectivity(<ConnectivityResult>[
          ConnectivityResult.vpn,
        ]),
        1,
      );
      expect(
        forkPreloadRadiusForConnectivity(<ConnectivityResult>[
          ConnectivityResult.other,
        ]),
        1,
      );
      expect(
        forkPreloadRadiusForConnectivity(<ConnectivityResult>[
          ConnectivityResult.none,
        ]),
        0,
      );
      expect(forkPreloadRadiusForConnectivity(<ConnectivityResult>[]), 0);
    });
  });

  group('concurrency, idempotence, cancellation, and promotion', () {
    test(
      'enforces strict concurrency = 1, downloads closest-first +4/-4, and is idempotent per settled index',
      () async {
        final _FakeCacheManager cache = _FakeCacheManager(tempDir);
        final List<AttachmentMediaViewerItem> items = List.generate(
          15,
          _mediaItem,
        );
        int activeCount = 0;
        int maxActive = 0;
        final List<String> fetchedUrls = <String>[];
        final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter((
          RequestOptions options,
          _,
          _,
        ) async {
          activeCount++;
          if (activeCount > maxActive) {
            maxActive = activeCount;
          }
          fetchedUrls.add(options.uri.toString());
          await Future<void>.delayed(const Duration(milliseconds: 5));
          activeCount--;
          return ResponseBody.fromBytes(
            Uint8List.fromList(<int>[1, 2, 3, 4]),
            200,
          );
        });

        // Second scheduleAround for same index while active is a no-op (no abort/restart).
        final ForkMediaViewerPreloader preloader =
            ForkMediaViewerPreloader(
                items: items,
                readHdrDisplayMode: () => HdrDisplayMode.full,
                cacheManager: cache,
                dio: _dioWithAdapter(adapter),
                readPreloadRadius: () async => 4,
                readMediaEndpoint: () => _kMediaBase,
              )
              ..scheduleAround(5)
              ..scheduleAround(5);
        await Future<void>.delayed(const Duration(milliseconds: 120));

        expect(maxActive, 1);
        expect(fetchedUrls, <String>[
          for (final int idx in <int>[6, 4, 7, 3, 8, 2, 9, 1]) items[idx].url,
        ]);
        expect(cache.puts, hasLength(8));
        preloader.dispose();
      },
    );

    test(
      'pauseSpeculation keeps active transfer alive for destination promotion on settle',
      () async {
        final _FakeCacheManager cache = _FakeCacheManager(tempDir);
        final List<AttachmentMediaViewerItem> items = List.generate(
          4,
          _mediaItem,
        );
        final StreamController<Uint8List> item1Stream =
            StreamController<Uint8List>();
        final Completer<void> item1Started = Completer<void>();
        bool item1Cancelled = false;

        final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter((
          RequestOptions options,
          _,
          Future<void>? cancelFuture,
        ) async {
          if (options.uri.toString() == items[1].url) {
            if (!item1Started.isCompleted) {
              item1Started.complete();
            }
            unawaited(cancelFuture?.then((_) => item1Cancelled = true));
            return ResponseBody(item1Stream.stream, 200);
          }
          return ResponseBody.fromBytes(Uint8List.fromList(<int>[9, 9]), 200);
        });

        final ForkMediaViewerPreloader preloader = ForkMediaViewerPreloader(
          items: items,
          readHdrDisplayMode: () => HdrDisplayMode.full,
          cacheManager: cache,
          dio: _dioWithAdapter(adapter),
          readPreloadRadius: () async => 4,
          readMediaEndpoint: () => _kMediaBase,
        )..scheduleAround(0);
        await item1Started.future;

        // Drag starts -> pauseSpeculation keeps item 1 alive.
        preloader.pauseSpeculation();
        expect(item1Cancelled, isFalse);

        // Settles on item 1 -> onNavigationStarted(nextTargetUrl) preserves it for promotion!
        preloader.onNavigationStarted(nextTargetUrl: items[1].url);
        final ForkPromotedTransfer? promoted = preloader.promoteInFlight(
          items[1].url,
        );
        expect(promoted, isNotNull);
        expect(item1Cancelled, isFalse);

        item1Stream.add(Uint8List.fromList(<int>[10, 20, 30]));
        await item1Stream.close();
        await promoted!.done;

        expect(promoted.receivedBytes, 3);
        expect(promoted.didCacheFresh, isTrue);
        expect(cache.puts.map((p) => p.url), contains(items[1].url));
        expect(preloader.promoteInFlight(items[1].url), isNull);
        preloader.dispose();
      },
    );

    test(
      'slow-but-progressing promoted stream survives past inactivityTimeout, '
      'while stalled stream aborts cleanly on cancelAndAwaitUnwind',
      () async {
        final _FakeCacheManager cache = _FakeCacheManager(tempDir);
        final List<AttachmentMediaViewerItem> items = List.generate(
          3,
          _mediaItem,
        );
        final StreamController<Uint8List> slowStream =
            StreamController<Uint8List>();
        final Completer<void> started = Completer<void>();

        final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter((
          RequestOptions options,
          _,
          _,
        ) async {
          if (!started.isCompleted) {
            started.complete();
          }
          return ResponseBody(slowStream.stream, 200);
        });

        final ForkMediaViewerPreloader preloader = ForkMediaViewerPreloader(
          items: items,
          readHdrDisplayMode: () => HdrDisplayMode.full,
          cacheManager: cache,
          dio: _dioWithAdapter(adapter),
          readPreloadRadius: () async => 1,
          readMediaEndpoint: () => _kMediaBase,
          inactivityTimeout: const Duration(milliseconds: 60),
        )..scheduleAround(0);
        await started.future;
        preloader.onNavigationStarted(nextTargetUrl: items[1].url);
        final ForkPromotedTransfer promoted = preloader.promoteInFlight(
          items[1].url,
        )!;

        for (int i = 0; i < 3; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          slowStream.add(Uint8List.fromList(<int>[i + 1]));
        }
        await slowStream.close();
        await promoted.done;
        expect(promoted.didCacheFresh, isTrue);

        final StreamController<Uint8List> stalledStream =
            StreamController<Uint8List>();
        final Completer<void> started2 = Completer<void>();
        final _FakeHttpClientAdapter adapter2 = _FakeHttpClientAdapter((
          RequestOptions options,
          _,
          _,
        ) async {
          if (!started2.isCompleted) {
            started2.complete();
          }
          return ResponseBody(stalledStream.stream, 200);
        });
        final ForkMediaViewerPreloader preloader2 = ForkMediaViewerPreloader(
          items: items,
          readHdrDisplayMode: () => HdrDisplayMode.full,
          cacheManager: _FakeCacheManager(tempDir),
          dio: _dioWithAdapter(adapter2),
          readPreloadRadius: () async => 1,
          readMediaEndpoint: () => _kMediaBase,
          inactivityTimeout: const Duration(seconds: 5),
        )..scheduleAround(0);
        await started2.future;
        preloader2.onNavigationStarted(nextTargetUrl: items[1].url);
        final ForkPromotedTransfer promoted2 = preloader2.promoteInFlight(
          items[1].url,
        )!;
        await promoted2.cancelAndAwaitUnwind();
        expect(promoted2.didCacheFresh, isFalse);
        await stalledStream.close();
        preloader.dispose();
        preloader2.dispose();
      },
    );

    test(
      'enforces both maxSingleItemBytes and maxBytesPerSession uniformly on promoted transfers',
      () async {
        final _FakeCacheManager cache = _FakeCacheManager(tempDir);
        final List<AttachmentMediaViewerItem> items = List.generate(
          3,
          _mediaItem,
        );
        final StreamController<Uint8List> item2Stream =
            StreamController<Uint8List>();
        final Completer<void> item2Started = Completer<void>();

        final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter((
          RequestOptions options,
          _,
          _,
        ) async {
          if (options.uri.toString() == items[1].url) {
            // Spends 8 bytes of the 12-byte session budget.
            return ResponseBody.fromBytes(Uint8List(8), 200);
          }
          if (!item2Started.isCompleted) {
            item2Started.complete();
          }
          return ResponseBody(item2Stream.stream, 200);
        });

        final ForkMediaViewerPreloader preloader = ForkMediaViewerPreloader(
          items: items,
          readHdrDisplayMode: () => HdrDisplayMode.full,
          cacheManager: cache,
          dio: _dioWithAdapter(adapter),
          readPreloadRadius: () async => 2,
          readMediaEndpoint: () => _kMediaBase,
          maxBytesPerSession: 12,
          maxSingleItemBytes: 10,
        )..scheduleAround(0);

        await item2Started.future;
        preloader.onNavigationStarted(nextTargetUrl: items[2].url);
        final ForkPromotedTransfer promoted = preloader.promoteInFlight(
          items[2].url,
        )!;

        // 8 + 6 = 14 > 12 session cap -> promoted transfer aborts cleanly (even though 6 <= 10 single cap).
        item2Stream.add(Uint8List(6));
        await promoted.done;
        expect(promoted.didCacheFresh, isFalse);
        expect(cache.puts.map((p) => p.url), <String>[items[1].url]);
        await item2Stream.close();
        preloader.dispose();
      },
    );
  });

  group('security, origin scoping, budgets, RFC 9111, and error backoff', () {
    test(
      'skips API-proxied, external, SVG, animated, mature (unconditionally), and cross-origin 3xx redirects',
      () async {
        const String apiBase = 'https://media.tyne.test/api/v1';
        AttachmentRequestAuth.update(
          token: 'test-token',
          baseUrl: apiBase,
          mintToken: null,
        );
        addTearDown(
          () => AttachmentRequestAuth.update(
            token: null,
            baseUrl: null,
            mintToken: null,
          ),
        );
        final _FakeCacheManager cache = _FakeCacheManager(tempDir);
        final List<AttachmentMediaViewerItem> items =
            <AttachmentMediaViewerItem>[
              _mediaItem(0),
              _mediaItem(
                1,
                url: '$apiBase/channels/100/attachments/1/api.jpg',
                proxyUrl: '$apiBase/channels/100/attachments/1/api.jpg',
              ),
              _mediaItem(
                2,
                url: 'https://thirdparty.example/pic.jpg',
                proxyUrl: 'https://thirdparty.example/pic.jpg',
              ),
              _mediaItem(3, isMatureMedia: true),
              _mediaItem(4, animated: true, filename: 'anim.gif'),
              _mediaItem(5, contentType: 'image/svg+xml', filename: 'vec.svg'),
              _mediaItem(6), // Redirects cross-origin -> rejected
              _mediaItem(7), // Redirects same-origin -> accepted
            ];

        final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter((
          RequestOptions options,
          _,
          _,
        ) async {
          final String url = options.uri.toString();
          if (url == items[6].url) {
            return ResponseBody.fromString(
              '',
              302,
              headers: <String, List<String>>{
                'location': <String>['https://evil.example/leak.jpg'],
              },
            );
          }
          if (url == items[7].url) {
            return ResponseBody.fromString(
              '',
              302,
              headers: <String, List<String>>{
                'location': <String>['$_kMediaBase/attachments/1/7/final.jpg'],
              },
            );
          }
          return ResponseBody.fromBytes(
            Uint8List.fromList(<int>[7, 7, 7]),
            200,
          );
        });

        // Mature items are never preloaded.
        final ForkMediaViewerPreloader preloader = ForkMediaViewerPreloader(
          items: items,
          readHdrDisplayMode: () => HdrDisplayMode.full,
          cacheManager: cache,
          dio: _dioWithAdapter(adapter),
          readPreloadRadius: () async => 8,
          readMediaEndpoint: () => _kMediaBase,
        )..scheduleAround(0);
        await Future<void>.delayed(const Duration(milliseconds: 80));

        final List<String> requested = adapter.requests
            .map((RequestOptions r) => r.uri.toString())
            .toList();
        expect(requested, isNot(contains(items[1].url)));
        expect(requested, isNot(contains(items[2].url)));
        expect(requested, isNot(contains(items[3].url)));
        expect(requested, isNot(contains(items[4].url)));
        expect(requested, isNot(contains(items[5].url)));
        expect(requested, isNot(contains('https://evil.example/leak.jpg')));
        expect(requested, contains('$_kMediaBase/attachments/1/7/final.jpg'));
        expect(cache.puts.map((p) => p.url), <String>[items[7].url]);
        preloader.dispose();
      },
    );

    test(
      'enforces session byte budget and memoizes no-store / oversized items across reschedules',
      () async {
        final _FakeCacheManager cache = _FakeCacheManager(tempDir);
        final List<AttachmentMediaViewerItem>
        items = <AttachmentMediaViewerItem>[
          _mediaItem(0),
          // Pre-admission reject: declared size > remaining 20 bytes
          _mediaItem(1, forkSizeBytes: 50),
          // no-store -> memoized, never re-requested on subsequent settle
          _mediaItem(2),
          // Content-Length > maxSingleItemBytes (15) -> memoized, never re-requested
          _mediaItem(3),
          // Streaming chunk succeeds with 12 bytes (8 remaining)
          _mediaItem(4),
          // Streaming chunk exceeds remaining 8 bytes -> aborted & charged (0 remaining)
          _mediaItem(5),
          // Budget exhausted -> 0 GETs
          _mediaItem(6),
        ];

        final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter((
          RequestOptions options,
          _,
          _,
        ) async {
          final String url = options.uri.toString();
          if (url == items[2].url) {
            return ResponseBody.fromBytes(
              Uint8List(4),
              200,
              headers: <String, List<String>>{
                'cache-control': <String>['no-store'],
              },
            );
          }
          if (url == items[3].url) {
            return ResponseBody.fromBytes(
              Uint8List(18),
              200,
              headers: <String, List<String>>{
                'content-length': <String>['18'],
              },
            );
          }
          if (url == items[4].url) {
            return ResponseBody.fromBytes(Uint8List(12), 200);
          }
          if (url == items[5].url) {
            return ResponseBody(
              Stream<Uint8List>.fromIterable(<Uint8List>[
                Uint8List(6),
                Uint8List(6),
              ]),
              200,
            );
          }
          return ResponseBody.fromBytes(Uint8List(4), 200);
        });

        final ForkMediaViewerPreloader preloader = ForkMediaViewerPreloader(
          items: items,
          readHdrDisplayMode: () => HdrDisplayMode.full,
          cacheManager: cache,
          dio: _dioWithAdapter(adapter),
          readPreloadRadius: () async => 6,
          readMediaEndpoint: () => _kMediaBase,
          maxBytesPerSession: 20,
          maxSingleItemBytes: 15,
        )..scheduleAround(0);
        await Future<void>.delayed(const Duration(milliseconds: 80));

        final List<String> requested = adapter.requests
            .map((RequestOptions r) => r.uri.toString())
            .toList();
        expect(requested, isNot(contains(items[1].url)));
        expect(requested, isNot(contains(items[6].url)));
        expect(cache.puts.map((p) => p.url), <String>[items[4].url]);

        // Verify memoization on a fresh preloader with plenty of budget:
        final _FakeHttpClientAdapter memoAdapter = _FakeHttpClientAdapter((
          RequestOptions options,
          _,
          _,
        ) async {
          if (options.uri.toString() == items[2].url) {
            return ResponseBody.fromBytes(
              Uint8List(4),
              200,
              headers: <String, List<String>>{
                'cache-control': <String>['no-store'],
              },
            );
          }
          return ResponseBody.fromBytes(
            Uint8List(18),
            200,
            headers: <String, List<String>>{
              'content-length': <String>['18'],
            },
          );
        });
        final ForkMediaViewerPreloader memoPreloader = ForkMediaViewerPreloader(
          items: <AttachmentMediaViewerItem>[items[0], items[2], items[3]],
          readHdrDisplayMode: () => HdrDisplayMode.full,
          cacheManager: _FakeCacheManager(tempDir),
          dio: _dioWithAdapter(memoAdapter),
          readPreloadRadius: () async => 2,
          readMediaEndpoint: () => _kMediaBase,
          maxBytesPerSession: 1000,
          maxSingleItemBytes: 15,
        )..scheduleAround(0);
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(memoAdapter.requests, hasLength(2));
        // Navigate & reschedule: no-store and oversized URLs are NOT re-requested!
        memoPreloader
          ..onNavigationStarted()
          ..scheduleAround(1);
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(
          memoAdapter.requests.where((r) => r.uri.toString() == items[2].url),
          hasLength(1),
        );
        expect(
          memoAdapter.requests.where((r) => r.uri.toString() == items[3].url),
          hasLength(1),
        );
        preloader.dispose();
        memoPreloader.dispose();
      },
    );

    test(
      'honors RFC 9111 no-store, no-cache, Age, and elapsed transfer duration',
      () async {
        final _FakeCacheManager cache = _FakeCacheManager(tempDir);
        final List<AttachmentMediaViewerItem> items = List.generate(
          5,
          _mediaItem,
        );
        DateTime clock = DateTime.utc(2026, 11, 24, 12);

        final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter((
          RequestOptions options,
          _,
          _,
        ) async {
          final String url = options.uri.toString();
          if (url == items[1].url) {
            return ResponseBody.fromBytes(
              Uint8List(4),
              200,
              headers: <String, List<String>>{
                'cache-control': <String>['no-store'],
              },
            );
          }
          if (url == items[2].url) {
            return ResponseBody.fromBytes(
              Uint8List(4),
              200,
              headers: <String, List<String>>{
                'cache-control': <String>['no-cache, max-age=600'],
              },
            );
          }
          if (url == items[3].url) {
            clock = clock.add(const Duration(seconds: 15));
            return ResponseBody.fromBytes(
              Uint8List(4),
              200,
              headers: <String, List<String>>{
                'cache-control': <String>['max-age=60'],
                'age': <String>['50'],
              },
            );
          }
          clock = clock.add(const Duration(seconds: 5));
          return ResponseBody.fromBytes(
            Uint8List(4),
            200,
            headers: <String, List<String>>{
              'cache-control': <String>['public, max-age=120'],
              'age': <String>['20'],
            },
          );
        });

        final ForkMediaViewerPreloader preloader = ForkMediaViewerPreloader(
          items: items,
          readHdrDisplayMode: () => HdrDisplayMode.full,
          cacheManager: cache,
          dio: _dioWithAdapter(adapter),
          readPreloadRadius: () async => 4,
          readMediaEndpoint: () => _kMediaBase,
          now: () => clock,
        )..scheduleAround(0);
        await Future<void>.delayed(const Duration(milliseconds: 80));

        expect(cache.puts, hasLength(1));
        expect(cache.puts.single.url, items[4].url);
        expect(cache.puts.single.maxAge, const Duration(seconds: 95));
        preloader.dispose();
      },
    );

    test(
      'pauses on 429 HTTP-date & promoted 429, stops on 401/403, permanently aborts after 2x 404, catches cache errors',
      () async {
        final List<AttachmentMediaViewerItem> items = List.generate(
          5,
          _mediaItem,
        );

        // 1) 429 with HTTP-date Retry-After 60s in the future.
        DateTime clock = DateTime.utc(2026, 11, 24, 12);
        final _FakeHttpClientAdapter adapter429 = _FakeHttpClientAdapter((
          RequestOptions options,
          _,
          _,
        ) async {
          if (options.uri.toString() == items[1].url) {
            return ResponseBody.fromString(
              '',
              429,
              headers: <String, List<String>>{
                'retry-after': <String>['Tue, 24 Nov 2026 12:01:00 GMT'],
              },
            );
          }
          return ResponseBody.fromBytes(Uint8List(4), 200);
        });
        final ForkMediaViewerPreloader p429 = ForkMediaViewerPreloader(
          items: items,
          readHdrDisplayMode: () => HdrDisplayMode.full,
          cacheManager: _FakeCacheManager(tempDir),
          dio: _dioWithAdapter(adapter429),
          readPreloadRadius: () async => 4,
          readMediaEndpoint: () => _kMediaBase,
          now: () => clock,
        )..scheduleAround(0);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(adapter429.requests, hasLength(1));
        // Still within 60s HTTP-date cooldown (at +45s) -> 0 additional requests.
        clock = clock.add(const Duration(seconds: 45));
        p429.scheduleAround(0);
        await _pumpEventQueue();
        expect(adapter429.requests, hasLength(1));
        // Past 60s deadline (at +65s) -> resumes.
        clock = clock.add(const Duration(seconds: 20));
        p429.scheduleAround(0);
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(adapter429.requests.length, greaterThan(1));
        p429.dispose();

        // 2) 429 received AFTER promotion still sets session cooldown!
        final DateTime promoClock = DateTime.utc(2026, 11, 24, 12);
        final Completer<ResponseBody> delayed429 = Completer<ResponseBody>();
        final Completer<void> promoStarted = Completer<void>();
        final _FakeHttpClientAdapter adapterPromo429 = _FakeHttpClientAdapter((
          RequestOptions options,
          _,
          _,
        ) async {
          if (options.uri.toString() == items[1].url) {
            if (!promoStarted.isCompleted) {
              promoStarted.complete();
            }
            return await delayed429.future;
          }
          return ResponseBody.fromBytes(Uint8List(4), 200);
        });
        final ForkMediaViewerPreloader pPromo429 = ForkMediaViewerPreloader(
          items: items,
          readHdrDisplayMode: () => HdrDisplayMode.full,
          cacheManager: _FakeCacheManager(tempDir),
          dio: _dioWithAdapter(adapterPromo429),
          readPreloadRadius: () async => 4,
          readMediaEndpoint: () => _kMediaBase,
          now: () => promoClock,
        )..scheduleAround(0);
        await promoStarted.future;
        pPromo429.onNavigationStarted(nextTargetUrl: items[1].url);
        final ForkPromotedTransfer promo = pPromo429.promoteInFlight(
          items[1].url,
        )!;
        delayed429.complete(
          ResponseBody.fromString(
            '',
            429,
            headers: <String, List<String>>{
              'retry-after': <String>['30'],
            },
          ),
        );
        await promo.done;
        // Now scheduleAround(1) within 30s cooldown -> 0 requests!
        pPromo429.scheduleAround(1);
        await _pumpEventQueue();
        expect(adapterPromo429.requests, hasLength(1));
        pPromo429.dispose();

        // 3) 403 stops preloader permanently for session.
        final _FakeHttpClientAdapter adapter403 = _FakeHttpClientAdapter((
          RequestOptions options,
          _,
          _,
        ) async {
          return ResponseBody.fromString('', 403);
        });
        final ForkMediaViewerPreloader p403 = ForkMediaViewerPreloader(
          items: items,
          readHdrDisplayMode: () => HdrDisplayMode.full,
          cacheManager: _FakeCacheManager(tempDir),
          dio: _dioWithAdapter(adapter403),
          readPreloadRadius: () async => 4,
          readMediaEndpoint: () => _kMediaBase,
        )..scheduleAround(0);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(adapter403.requests, hasLength(1));
        p403.scheduleAround(1);
        await _pumpEventQueue();
        expect(adapter403.requests, hasLength(1));
        p403.dispose();

        // 4) 2 consecutive 404s hold the concurrency=1 slot until raw adapter
        // error-body cleanup finishes, then permanently abort the session.
        final Completer<void> first404CancelDone = Completer<void>();
        bool first404CancelCalled = false;
        int req404Count = 0;
        final StreamController<Uint8List> first404Stream =
            StreamController<Uint8List>(
              onCancel: () {
                first404CancelCalled = true;
                return first404CancelDone.future;
              },
            );
        final _FakeHttpClientAdapter adapter404 = _FakeHttpClientAdapter((
          RequestOptions options,
          _,
          _,
        ) async {
          if (req404Count++ == 0) {
            return ResponseBody(first404Stream.stream, 404);
          }
          return ResponseBody.fromString('', 404);
        });
        final ForkMediaViewerPreloader p404 = ForkMediaViewerPreloader(
          items: items,
          readHdrDisplayMode: () => HdrDisplayMode.full,
          cacheManager: _FakeCacheManager(tempDir),
          dio: _dioWithAdapter(adapter404),
          readPreloadRadius: () async => 4,
          readMediaEndpoint: () => _kMediaBase,
        )..scheduleAround(0);
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(first404CancelCalled, isTrue);
        // Slot stays held until raw 404 error stream cleanup completes!
        expect(adapter404.requests, hasLength(1));
        first404CancelDone.complete();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(adapter404.requests, hasLength(2));
        // Subsequent scheduleAround for a different index must issue 0 requests!
        p404.scheduleAround(2);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(adapter404.requests, hasLength(2));
        unawaited(first404Stream.close());
        p404.dispose();

        // 5) Throwing cache lookup is caught cleanly with 0 uncaught async errors and stops session.
        final _FakeHttpClientAdapter adapterCacheErr = _FakeHttpClientAdapter((
          RequestOptions options,
          _,
          _,
        ) async {
          return ResponseBody.fromBytes(Uint8List(4), 200);
        });
        final ForkMediaViewerPreloader pCacheErr = ForkMediaViewerPreloader(
          items: items,
          readHdrDisplayMode: () => HdrDisplayMode.full,
          cacheManager: _FakeCacheManager(tempDir, throwOnLookup: true),
          dio: _dioWithAdapter(adapterCacheErr),
          readPreloadRadius: () async => 4,
          readMediaEndpoint: () => _kMediaBase,
        )..scheduleAround(0);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(adapterCacheErr.requests, isEmpty);
        pCacheErr.scheduleAround(1);
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(adapterCacheErr.requests, isEmpty);
        pCacheErr.dispose();
      },
    );

    test(
      'holds concurrency=1 slot and promotion unwind until raw adapter sub.cancel() finishes, bounded by cancelCleanupTimeout',
      () async {
        final _FakeCacheManager cache = _FakeCacheManager(tempDir);
        final List<AttachmentMediaViewerItem> items = List.generate(
          4,
          _mediaItem,
        );
        final Completer<void> item1Started = Completer<void>();
        final Completer<void> cancelCleanupDone = Completer<void>();
        bool cancelCalled = false;
        final StreamController<Uint8List> item1Stream =
            StreamController<Uint8List>(
              onListen: () {
                if (!item1Started.isCompleted) {
                  item1Started.complete();
                }
              },
              onCancel: () {
                cancelCalled = true;
                return cancelCleanupDone.future;
              },
            );

        // Return raw stream directly from the adapter (no response interceptor)
        // so Dio 5.11's handleResponseStream wraps it and our tracking adapter
        // proves raw-stream cancellation is genuinely awaited (F-036).
        int item1Calls = 0;
        final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter((
          RequestOptions options,
          _,
          _,
        ) async {
          if (options.uri.toString() == items[1].url && item1Calls++ == 0) {
            return ResponseBody(item1Stream.stream, 200);
          }
          return ResponseBody.fromBytes(Uint8List(8), 200);
        });
        final Dio dio = _dioWithAdapter(adapter);

        final ForkMediaViewerPreloader preloader = ForkMediaViewerPreloader(
          items: items,
          readHdrDisplayMode: () => HdrDisplayMode.full,
          cacheManager: cache,
          dio: dio,
          readPreloadRadius: () async => 1,
          readMediaEndpoint: () => _kMediaBase,
        )..scheduleAround(0);

        await item1Started.future;
        preloader.onNavigationStarted(nextTargetUrl: items[1].url);
        final ForkPromotedTransfer promoted = preloader.promoteInFlight(
          items[1].url,
        )!;

        // Start cancelling promoted transfer AND schedule next page (index 2 -> item 3).
        bool unwindFinished = false;
        unawaited(
          promoted.cancelAndAwaitUnwind().then((_) => unwindFinished = true),
        );
        preloader.scheduleAround(2);
        await Future<void>.delayed(const Duration(milliseconds: 30));

        // While item1Stream.onCancel is still pending, neither cancelAndAwaitUnwind
        // nor the next speculative request may proceed!
        expect(cancelCalled, isTrue);
        expect(unwindFinished, isFalse);
        expect(adapter.requests, hasLength(1));

        cancelCleanupDone.complete();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(unwindFinished, isTrue);
        expect(adapter.requests.length, greaterThan(1));
        unawaited(item1Stream.close());
        preloader.dispose();

        // Permanently hung stream onCancel is bounded by cancelCleanupTimeout (F-042).
        final Completer<void> hungStarted = Completer<void>();
        final StreamController<Uint8List> hungStream =
            StreamController<Uint8List>(
              onListen: () {
                if (!hungStarted.isCompleted) {
                  hungStarted.complete();
                }
              },
              onCancel: () => Completer<void>().future,
            );
        int hungCalls = 0;
        final _FakeHttpClientAdapter hungAdapter = _FakeHttpClientAdapter((
          RequestOptions options,
          _,
          _,
        ) async {
          if (options.uri.toString() == items[1].url && hungCalls++ == 0) {
            return ResponseBody(hungStream.stream, 200);
          }
          return ResponseBody.fromBytes(Uint8List(8), 200);
        });
        final ForkMediaViewerPreloader hungPreloader = ForkMediaViewerPreloader(
          items: items,
          readHdrDisplayMode: () => HdrDisplayMode.full,
          cacheManager: _FakeCacheManager(tempDir),
          dio: _dioWithAdapter(hungAdapter),
          readPreloadRadius: () async => 1,
          readMediaEndpoint: () => _kMediaBase,
          cancelCleanupTimeout: const Duration(milliseconds: 60),
        )..scheduleAround(0);

        await hungStarted.future;
        hungPreloader.onNavigationStarted(nextTargetUrl: items[1].url);
        final ForkPromotedTransfer promotedHung = hungPreloader.promoteInFlight(
          items[1].url,
        )!;
        bool hungUnwindFinished = false;
        unawaited(
          promotedHung.cancelAndAwaitUnwind().then(
            (_) => hungUnwindFinished = true,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(hungUnwindFinished, isFalse);
        await Future<void>.delayed(const Duration(milliseconds: 80));
        expect(hungUnwindFinished, isTrue);
        // Once cleanup times out without confirming transport closure, further
        // speculation in that session is permanently stopped (F-036).
        hungPreloader.scheduleAround(2);
        await Future<void>.delayed(const Duration(milliseconds: 40));
        expect(hungAdapter.requests, hasLength(1));
        unawaited(hungStream.close());
        hungPreloader.dispose();

        // Pre-header cancellation (before adapter.fetch resolves) also holds
        // the concurrency=1 slot and promotion unwind until the underlying
        // connect/fetch cancellation finishes (F-045).
        final Completer<void> preHeaderFetchEntered = Completer<void>();
        final Completer<void> preHeaderCancelUnwound = Completer<void>();
        bool preHeaderCancelObserved = false;
        int preHeaderCalls = 0;
        final _FakeHttpClientAdapter preHeaderAdapter = _FakeHttpClientAdapter((
          RequestOptions options,
          _,
          Future<void>? cancelFuture,
        ) async {
          if (options.uri.toString() == items[1].url && preHeaderCalls++ == 0) {
            if (!preHeaderFetchEntered.isCompleted) {
              preHeaderFetchEntered.complete();
            }
            unawaited(
              cancelFuture?.then((_) => preHeaderCancelObserved = true),
            );
            await preHeaderCancelUnwound.future;
            throw DioException.requestCancelled(
              requestOptions: options,
              reason: 'cancelled during connect',
            );
          }
          return ResponseBody.fromBytes(Uint8List(8), 200);
        });
        final ForkMediaViewerPreloader preHeaderPreloader =
            ForkMediaViewerPreloader(
              items: items,
              readHdrDisplayMode: () => HdrDisplayMode.full,
              cacheManager: _FakeCacheManager(tempDir),
              dio: _dioWithAdapter(preHeaderAdapter),
              readPreloadRadius: () async => 1,
              readMediaEndpoint: () => _kMediaBase,
            )..scheduleAround(0);

        await preHeaderFetchEntered.future;
        preHeaderPreloader.onNavigationStarted(nextTargetUrl: items[1].url);
        final ForkPromotedTransfer promotedPreHeader = preHeaderPreloader
            .promoteInFlight(items[1].url)!;
        bool preHeaderUnwound = false;
        unawaited(
          promotedPreHeader.cancelAndAwaitUnwind().then(
            (_) => preHeaderUnwound = true,
          ),
        );
        preHeaderPreloader.scheduleAround(2);
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(preHeaderCancelObserved, isTrue);
        expect(preHeaderUnwound, isFalse);
        expect(preHeaderAdapter.requests, hasLength(1));

        preHeaderCancelUnwound.complete();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(preHeaderUnwound, isTrue);
        expect(preHeaderAdapter.requests.length, greaterThan(1));
        preHeaderPreloader.dispose();

        // Same-origin 302 redirect waits for redirect-body cleanup before
        // following Location, and aborts without issuing the follow-up GET if
        // redirect-body cleanup times out (F-048).
        final Completer<void> redirectCancelGate = Completer<void>();
        final StreamController<Uint8List> redirectStream =
            StreamController<Uint8List>(
              onCancel: () => redirectCancelGate.future,
            );
        int redirCalls = 0;
        final _FakeHttpClientAdapter redirAdapter = _FakeHttpClientAdapter((
          RequestOptions options,
          _,
          _,
        ) async {
          if (redirCalls++ == 0) {
            return ResponseBody(
              redirectStream.stream,
              302,
              headers: <String, List<String>>{
                'location': <String>['$_kMediaBase/attachments/1/99/final.jpg'],
              },
            );
          }
          return ResponseBody.fromBytes(Uint8List(8), 200);
        });
        final ForkMediaViewerPreloader redirPreloader =
            ForkMediaViewerPreloader(
              items: items,
              readHdrDisplayMode: () => HdrDisplayMode.full,
              cacheManager: _FakeCacheManager(tempDir),
              dio: _dioWithAdapter(redirAdapter),
              readPreloadRadius: () async => 1,
              readMediaEndpoint: () => _kMediaBase,
              cancelCleanupTimeout: const Duration(milliseconds: 50),
            )..scheduleAround(0);

        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(redirAdapter.requests, hasLength(1));
        // Let the 50ms cleanup timeout elapse without completing redirectCancelGate:
        // must NOT issue the follow-up redirect GET!
        await Future<void>.delayed(const Duration(milliseconds: 70));
        expect(redirAdapter.requests, hasLength(1));
        unawaited(redirectStream.close());
        redirPreloader.dispose();
      },
    );
  });
}
