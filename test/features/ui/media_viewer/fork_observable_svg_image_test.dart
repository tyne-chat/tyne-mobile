// Fork (tyne-chat/tyne#887): tests for ForkObservableSvgNetworkImage (single-GET
// decode-ordered SVG rendering, streaming byte limit, and header hygiene).

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/media/retrying_network_image.dart';
import 'package:fluxer_app/features/ui/media_viewer/fork_observable_svg_image.dart';
import 'package:fluxer_app/material_ui.dart';

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

void main() {
  group('ForkObservableSvgNetworkImage', () {
    testWidgets(
      'fetches SVG in a single GET, fires onLoaded only after valid compile, '
      'fires onLoadFailure on malformed 200 XML, and sends no auth headers to third parties',
      (WidgetTester tester) async {
        const String validSvg =
            '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"> '
            '<rect width="24" height="24" fill="#ff0000"/></svg>';
        final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter((
          RequestOptions options,
          _,
          _,
        ) async {
          if (options.uri.path.contains('bad.svg')) {
            return ResponseBody.fromString('not valid xml <<<', 200);
          }
          if (options.uri.path.contains('down.svg')) {
            return ResponseBody.fromString('unavailable', 503);
          }
          return ResponseBody.fromBytes(
            Uint8List.fromList(utf8.encode(validSvg)),
            200,
          );
        });
        final Dio dio = Dio()..httpClientAdapter = adapter;

        int loaded = 0;
        int failed = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ForkObservableSvgNetworkImage(
                imageUrl: 'https://thirdparty.example/good.svg',
                fit: BoxFit.contain,
                errorPlaceholder: const Text('ERR'),
                onLoaded: () => loaded++,
                onLoadFailure: (_) => failed++,
                dio: dio,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(adapter.requests, hasLength(1));
        final Map<String, Object?> headers = adapter.requests.single.headers;
        expect(headers.containsKey('Authorization'), isFalse);
        expect(headers.containsKey('X-Tyne-Call-Site'), isFalse);
        expect(loaded, 1);
        expect(failed, 0);

        int badLoaded = 0;
        int badFailed = 0;
        ForkImageLoadFailure? badFailure;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ForkObservableSvgNetworkImage(
                imageUrl: 'https://thirdparty.example/bad.svg',
                fit: BoxFit.contain,
                errorPlaceholder: const Text('ERR'),
                onLoaded: () => badLoaded++,
                onLoadFailure: (ForkImageLoadFailure failure) {
                  badFailed++;
                  badFailure = failure;
                },
                dio: dio,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(badLoaded, 0);
        expect(badFailed, 1);
        expect(find.text('ERR'), findsOneWidget);
        // Malformed SVG arrived intact: retrying cannot fix it.
        expect(badFailure?.undecodable, isTrue);

        // A server error is a transport failure, not an undecodable image.
        ForkImageLoadFailure? downFailure;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ForkObservableSvgNetworkImage(
                imageUrl: 'https://thirdparty.example/down.svg',
                fit: BoxFit.contain,
                errorPlaceholder: const Text('ERR'),
                onLoadFailure: (ForkImageLoadFailure failure) =>
                    downFailure = failure,
                dio: dio,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(downFailure, isNotNull);
        expect(downFailure!.undecodable, isFalse);
      },
    );

    testWidgets(
      'aborts oversized chunked SVG stream without Content-Length as soon as limit is crossed',
      (WidgetTester tester) async {
        bool cancelled = false;
        bool streamCancelled = false;
        int chunksEmitted = 0;
        final Completer<void> fetchStarted = Completer<void>();
        final StreamController<Uint8List> stream = StreamController<Uint8List>(
          onCancel: () {
            streamCancelled = true;
            return (Completer<void>()..complete()).future;
          },
        );
        final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter((
          RequestOptions options,
          _,
          Future<void>? cancelFuture,
        ) async {
          if (!fetchStarted.isCompleted) {
            fetchStarted.complete();
          }
          unawaited(cancelFuture?.then((_) => cancelled = true));
          return ResponseBody(stream.stream, 200);
        });
        final Dio dio = Dio()..httpClientAdapter = adapter;

        int loaded = 0;
        int failed = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ForkObservableSvgNetworkImage(
                imageUrl: 'https://thirdparty.example/huge.svg',
                fit: BoxFit.contain,
                errorPlaceholder: const Text('TOO_BIG'),
                onLoaded: () => loaded++,
                onLoadFailure: (_) => failed++,
                dio: dio,
                maxBytes: 64,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 10));
        expect(fetchStarted.isCompleted, isTrue);
        await tester.pump(const Duration(milliseconds: 10));

        // Emit two 40-byte chunks (total 80 > 64 limit) without closing stream.
        chunksEmitted++;
        stream.add(Uint8List(40));
        await tester.pump(const Duration(milliseconds: 10));
        expect(cancelled, isFalse);
        expect(streamCancelled, isFalse);

        chunksEmitted++;
        stream.add(Uint8List(40));
        for (int i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 10));
        }

        expect(cancelled, isTrue);
        expect(streamCancelled, isTrue);
        expect(chunksEmitted, 2);
        expect(loaded, 0);
        expect(failed, 1);
        expect(find.text('TOO_BIG'), findsOneWidget);
        unawaited(stream.close());
      },
    );

    testWidgets(
      'oversized Content-Length with delayed stream cancel does not update stale generation or disposed widget',
      (WidgetTester tester) async {
        const String validSvg =
            '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"> '
            '<rect width="24" height="24" fill="#00ff00"/></svg>';
        final Completer<void> cancelGate1 = Completer<void>();
        final StreamController<Uint8List> stream1 = StreamController<Uint8List>(
          onCancel: () => cancelGate1.future,
        );
        final Completer<void> cancelGate2 = Completer<void>();
        final StreamController<Uint8List> stream2 = StreamController<Uint8List>(
          onCancel: () => cancelGate2.future,
        );

        final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter((
          RequestOptions options,
          _,
          _,
        ) async {
          if (options.uri.path.contains('huge1.svg')) {
            return ResponseBody(
              stream1.stream,
              200,
              headers: <String, List<String>>{
                Headers.contentLengthHeader: <String>['999999'],
              },
            );
          }
          if (options.uri.path.contains('huge2.svg')) {
            return ResponseBody(
              stream2.stream,
              200,
              headers: <String, List<String>>{
                Headers.contentLengthHeader: <String>['999999'],
              },
            );
          }
          return ResponseBody.fromBytes(
            Uint8List.fromList(utf8.encode(validSvg)),
            200,
          );
        });
        final Dio dio = Dio()..httpClientAdapter = adapter;

        // 1) Stale generation: switch URL while oversized Content-Length drain is awaiting cancelGate1.
        int loaded = 0;
        int failed = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ForkObservableSvgNetworkImage(
                imageUrl: 'https://thirdparty.example/huge1.svg',
                fit: BoxFit.contain,
                errorPlaceholder: const Text('STALE_ERR'),
                onLoaded: () => loaded++,
                onLoadFailure: (_) => failed++,
                dio: dio,
                maxBytes: 256,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 20));

        // Update widget to valid SVG while `_drainSilently(body)` is still suspended on cancelGate1!
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ForkObservableSvgNetworkImage(
                imageUrl: 'https://thirdparty.example/good2.svg',
                fit: BoxFit.contain,
                errorPlaceholder: const Text('STALE_ERR'),
                onLoaded: () => loaded++,
                onLoadFailure: (_) => failed++,
                dio: dio,
                maxBytes: 256,
              ),
            ),
          ),
        );
        for (int i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 20));
        }
        expect(loaded, 1);
        expect(failed, 0);

        // Now complete cancelGate1 -> stale generation must NOT overwrite good2.svg with STALE_ERR!
        cancelGate1.complete();
        await tester.pump(const Duration(milliseconds: 20));
        await tester.pump();
        expect(failed, 0);
        expect(find.text('STALE_ERR'), findsNothing);
        unawaited(stream1.close());

        // 2) Disposal while oversized Content-Length drain is awaiting cancelGate2 -> no setState after dispose!
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ForkObservableSvgNetworkImage(
                key: const ValueKey<String>('dispose_svg'),
                imageUrl: 'https://thirdparty.example/huge2.svg',
                fit: BoxFit.contain,
                errorPlaceholder: const Text('DISPOSED_ERR'),
                onLoadFailure: (_) => failed++,
                dio: dio,
                maxBytes: 64,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 20));
        await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
        cancelGate2.complete();
        await tester.pump(const Duration(milliseconds: 20));
        await tester.pump();
        expect(failed, 0);
        unawaited(stream2.close());
      },
    );
  });
}
