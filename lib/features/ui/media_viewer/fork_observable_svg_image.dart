import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluxer_app/core/api/attachment_request_auth.dart';
import 'package:fluxer_app/core/api/fork_dio_response_cleanup.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/media/retrying_network_image.dart';
import 'package:fluxer_app/material_ui.dart';

const int kForkMaxSvgBytes = 20 << 20;
const Duration _kSvgInactivityTimeout = Duration(seconds: 10);
const Duration _kSvgTotalTimeout = Duration(seconds: 30);
const int _kSvgMaxRedirects = 3;

final Dio _defaultPlainSvgDio = Dio(
  BaseOptions(
    connectTimeout: _kSvgInactivityTimeout,
    receiveTimeout: _kSvgInactivityTimeout,
    followRedirects: true,
    maxRedirects: _kSvgMaxRedirects,
    responseType: ResponseType.stream,
  ),
);

/// Single-GET, decode-verified SVG network widget.
///
/// Uses a dedicated plain [Dio] (no `ForkCallSiteInterceptor`, no session auth
/// interceptors — only [AttachmentRequestAuth.headersFor], which is `null` for
/// third-party hosts), streams raw SVG UTF-8 XML bytes with an immediate
/// streaming cap of [maxBytes] (default 20 MiB) and bounded redirects, compiles
/// them once via [SvgBytesLoader.loadBytes], renders via a preloaded
/// [BytesLoader] (zero second fetch, zero second parse), and reports [onLoaded]
/// / [onLoadFailure] post-frame strictly after SVG decode finishes.
class ForkObservableSvgNetworkImage extends StatefulWidget {
  const ForkObservableSvgNetworkImage({
    required this.imageUrl,
    required this.fit,
    required this.errorPlaceholder,
    this.width,
    this.height,
    this.placeholder,
    this.onLoaded,
    this.onLoadFailure,
    this.dio,
    this.maxBytes = kForkMaxSvgBytes,
    this.cancelCleanupTimeout = kForkStreamCancelTimeout,
    super.key,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget errorPlaceholder;
  final VoidCallback? onLoaded;
  final ForkImageLoadFailureCallback? onLoadFailure;
  final Dio? dio;
  final int maxBytes;
  final Duration cancelCleanupTimeout;

  @override
  State<ForkObservableSvgNetworkImage> createState() =>
      _ForkObservableSvgNetworkImageState();
}

class _ForkObservableSvgNetworkImageState
    extends State<ForkObservableSvgNetworkImage> {
  CancelToken? _cancelToken;
  int _generation = 0;
  _PreloadedSvgBytesLoader? _loader;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_fetchAndDecode());
  }

  @override
  void didUpdateWidget(ForkObservableSvgNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl || oldWidget.dio != widget.dio) {
      _cancelActive();
      _loader = null;
      _failed = false;
      unawaited(_fetchAndDecode());
    }
  }

  @override
  void dispose() {
    _cancelActive();
    super.dispose();
  }

  void _cancelActive() {
    _generation += 1;
    _cancelToken?.cancel();
    _cancelToken = null;
  }

  Future<void> _fetchAndDecode() async {
    final int gen = ++_generation;
    final CancelToken token = CancelToken();
    _cancelToken = token;
    final Dio client = widget.dio ?? _defaultPlainSvgDio;
    forkEnsureResponseCleanupAdapter(client);
    final String url = widget.imageUrl;
    final int limit = widget.maxBytes;
    Timer? inactivityTimer;
    Timer? totalTimer;
    try {
      totalTimer = Timer(_kSvgTotalTimeout, () {
        if (!token.isCancelled) {
          token.cancel('svg_total_timeout');
        }
      });
      final Response<ResponseBody> response = await client.get<ResponseBody>(
        url,
        cancelToken: token,
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: true,
          maxRedirects: _kSvgMaxRedirects,
          receiveTimeout: _kSvgInactivityTimeout,
          headers: AttachmentRequestAuth.headersFor(url),
        ),
      );
      final ResponseBody? body = response.data;
      if (!mounted || gen != _generation) {
        await forkAwaitResponseCleanup(
          response.requestOptions,
          fallbackBody: body,
          timeout: widget.cancelCleanupTimeout,
        );
        return;
      }
      if (body == null) {
        _markFailed(gen, undecodable: false);
        return;
      }

      // Reject oversized Content-Length before buffering any chunks.
      final int? contentLength = int.tryParse(
        response.headers.value(Headers.contentLengthHeader) ?? '',
      );
      if (contentLength != null && contentLength > limit) {
        token.cancel('svg_content_length_exceeded');
        await forkAwaitResponseCleanup(
          response.requestOptions,
          fallbackBody: body,
          timeout: widget.cancelCleanupTimeout,
        );
        if (!mounted || gen != _generation) {
          return;
        }
        _markFailed(gen, undecodable: true);
        return;
      }

      void resetInactivityTimer() {
        inactivityTimer?.cancel();
        inactivityTimer = Timer(_kSvgInactivityTimeout, () {
          if (!token.isCancelled) {
            token.cancel('svg_inactivity_timeout');
          }
        });
      }

      resetInactivityTimer();
      final BytesBuilder builder = BytesBuilder(copy: false);
      int received = 0;
      bool aborted = false;
      Future<void>? cancelSubFuture;
      final Completer<void> done = Completer<void>();
      late final StreamSubscription<Uint8List> sub;
      sub = body.stream.listen(
        (Uint8List chunk) {
          resetInactivityTimer();
          received += chunk.length;
          if (received > limit || token.isCancelled) {
            aborted = true;
            if (!token.isCancelled) {
              token.cancel('svg_size_limit_exceeded');
            }
            cancelSubFuture ??= sub.cancel();
            if (!done.isCompleted) {
              done.complete();
            }
            return;
          }
          builder.add(chunk);
        },
        onError: (Object error, StackTrace stack) {
          aborted = true;
          if (!done.isCompleted) {
            done.completeError(error, stack);
          }
        },
        onDone: () {
          if (!done.isCompleted) {
            done.complete();
          }
        },
        cancelOnError: true,
      );

      unawaited(
        token.whenCancel.then((_) {
          aborted = true;
          cancelSubFuture ??= sub.cancel();
          if (!done.isCompleted) {
            done.complete();
          }
        }),
      );

      await done.future;
      inactivityTimer?.cancel();
      totalTimer.cancel();
      if (aborted || token.isCancelled || cancelSubFuture != null) {
        await forkAwaitResponseCleanup(
          response.requestOptions,
          timeout: widget.cancelCleanupTimeout,
        );
      }

      if (!mounted || gen != _generation) {
        return;
      }
      if (aborted || token.isCancelled || received == 0 || received > limit) {
        // Too large to load is not fixed by retrying; the rest are transport failures.
        _markFailed(gen, undecodable: received > limit);
        return;
      }
      final Uint8List rawBytes = builder.takeBytes();
      final ByteData compiled = await SvgBytesLoader(
        rawBytes,
      ).loadBytes(context);
      if (!mounted || gen != _generation) {
        return;
      }
      setState(() {
        _loader = _PreloadedSvgBytesLoader(compiled);
        _failed = false;
      });
      _notifyPostFrame(gen, () => widget.onLoaded?.call());
    } on DioException catch (error) {
      final Object? errData = error.response?.data;
      await forkAwaitResponseCleanup(
        error.requestOptions,
        fallbackBody: errData is ResponseBody ? errData : null,
        timeout: widget.cancelCleanupTimeout,
      );
      if (!mounted || gen != _generation) {
        return;
      }
      _markFailed(gen, undecodable: false);
    } on Object {
      if (!mounted || gen != _generation) {
        return;
      }
      // The bytes arrived but did not parse as SVG.
      _markFailed(gen, undecodable: true);
    } finally {
      inactivityTimer?.cancel();
      totalTimer?.cancel();
      if (identical(_cancelToken, token)) {
        _cancelToken = null;
      }
    }
  }

  void _markFailed(int gen, {required bool undecodable}) {
    if (!mounted || gen != _generation) {
      return;
    }
    setState(() {
      _loader = null;
      _failed = true;
    });
    _notifyPostFrame(
      gen,
      () => widget.onLoadFailure?.call(
        ForkImageLoadFailure(
          failures: 1,
          isPermanent: true,
          undecodable: undecodable,
        ),
      ),
    );
  }

  void _notifyPostFrame(int gen, VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted || gen != _generation) {
        return;
      }
      callback();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return widget.errorPlaceholder;
    }
    final _PreloadedSvgBytesLoader? loader = _loader;
    if (loader == null) {
      return widget.placeholder ??
          SizedBox(width: widget.width, height: widget.height);
    }
    return SvgPicture(
      loader,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }
}

class _PreloadedSvgBytesLoader extends BytesLoader {
  const _PreloadedSvgBytesLoader(this.compiled);

  final ByteData compiled;

  @override
  Future<ByteData> loadBytes(BuildContext? context) =>
      SynchronousFuture<ByteData>(compiled);

  @override
  String toString() => '_PreloadedSvgBytesLoader(${compiled.lengthInBytes}B)';
}
