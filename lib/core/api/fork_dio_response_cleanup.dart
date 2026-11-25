import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

const Duration kForkStreamCancelTimeout = Duration(seconds: 2);
const String _kForkResponseCleanupKey = '_forkResponseCleanup';

/// Wraps [dio]'s [HttpClientAdapter] idempotently so raw adapter response
/// streams (both `2xx` streams and `4xx`/`5xx` error streams wrapped by Dio's
/// `handleResponseStream`) expose an awaitable, timeout-bounded transport
/// cleanup hook via [forkAwaitResponseCleanup].
void forkEnsureResponseCleanupAdapter(Dio dio) {
  final HttpClientAdapter current = dio.httpClientAdapter;
  if (current is! _ForkTrackingHttpClientAdapter) {
    dio.httpClientAdapter = _ForkTrackingHttpClientAdapter(current);
  }
}

/// Cancels and awaits cleanup of the underlying adapter fetch and response
/// stream associated with [options] (falling back to [fallbackBody] if
/// untracked), bounded by [timeout] so a hung socket close can never wedge
/// callers.
///
/// Returns `true` when cleanup completed within [timeout], or `false` if
/// [timeout] elapsed while transport cleanup was still hung.
Future<bool> forkAwaitResponseCleanup(
  RequestOptions? options, {
  ResponseBody? fallbackBody,
  Duration timeout = kForkStreamCancelTimeout,
}) {
  final Object? tracker = options?.extra[_kForkResponseCleanupKey];
  if (tracker is _ForkTrackedResponseCleanup) {
    return tracker.cancelAndCleanup(timeout: timeout);
  }
  if (fallbackBody != null) {
    return _awaitBoundedCancel(
      () => fallbackBody.stream.listen((_) {}).cancel(),
      timeout: timeout,
    );
  }
  return Future<bool>.value(true);
}

Future<bool> _awaitBoundedCancel(
  Future<void> Function() action, {
  required Duration timeout,
}) {
  late final Future<void> work;
  try {
    work = action();
  } on Object {
    return Future<bool>.value(true);
  }
  if (timeout <= Duration.zero) {
    return work.then<bool>((_) => true, onError: (Object _) => true);
  }
  final Completer<bool> bounded = Completer<bool>();
  final Timer timer = Timer(timeout, () {
    if (!bounded.isCompleted) {
      bounded.complete(false);
    }
  });
  unawaited(
    work.catchError((Object _) {}).whenComplete(() {
      timer.cancel();
      if (!bounded.isCompleted) {
        bounded.complete(true);
      }
    }),
  );
  return bounded.future;
}

class _ForkTrackingHttpClientAdapter implements HttpClientAdapter {
  _ForkTrackingHttpClientAdapter(this._inner);

  final HttpClientAdapter _inner;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final _ForkTrackedResponseCleanup tracker = _ForkTrackedResponseCleanup();
    options.extra[_kForkResponseCleanupKey] = tracker;
    final Future<ResponseBody> fetchFuture = _inner.fetch(
      options,
      requestStream,
      cancelFuture,
    );
    tracker.attachFetch(fetchFuture);
    unawaited(cancelFuture?.whenComplete(tracker.cancelAndCleanup));
    final ResponseBody raw = await fetchFuture;
    raw.stream = tracker.attachRawStream(raw.stream);
    return raw;
  }

  @override
  void close({bool force = false}) => _inner.close(force: force);
}

class _ForkTrackedResponseCleanup {
  _ForkTrackedResponseCleanup() {
    _controller = StreamController<Uint8List>(
      onListen: _onListen,
      onPause: () => _rawSub?.pause(),
      onResume: () => _rawSub?.resume(),
      onCancel: cancelAndCleanup,
    );
  }

  Future<ResponseBody>? _fetchFuture;
  Stream<Uint8List>? _rawStream;
  late final StreamController<Uint8List> _controller;
  StreamSubscription<Uint8List>? _rawSub;
  Future<void>? _cleanupFuture;
  bool _finished = false;
  bool _cancelled = false;
  bool _rawStreamCancelled = false;

  void attachFetch(Future<ResponseBody> fetchFuture) {
    _fetchFuture = fetchFuture;
    unawaited(fetchFuture.then<void>((_) {}, onError: (Object _) {}));
  }

  Stream<Uint8List> attachRawStream(Stream<Uint8List> rawStream) {
    _rawStream = rawStream;
    return _controller.stream;
  }

  void _onListen() {
    final Stream<Uint8List>? rawStream = _rawStream;
    if (_finished || _cancelled || rawStream == null) {
      if (!_controller.isClosed) {
        unawaited(_controller.close());
      }
      return;
    }
    _rawSub = rawStream.listen(
      (Uint8List chunk) {
        if (!_controller.isClosed) {
          _controller.add(chunk);
        }
      },
      onError: (Object error, StackTrace stack) {
        _finished = true;
        if (!_controller.isClosed) {
          _controller.addError(error, stack);
          unawaited(_controller.close());
        }
      },
      onDone: () {
        _finished = true;
        if (!_controller.isClosed) {
          unawaited(_controller.close());
        }
      },
      cancelOnError: true,
    );
  }

  Future<bool> cancelAndCleanup({Duration timeout = kForkStreamCancelTimeout}) {
    final Future<void>? inFlight = _cleanupFuture;
    if (inFlight != null) {
      return _awaitBoundedCancel(() => inFlight, timeout: timeout);
    }
    if (_finished) {
      return Future<bool>.value(true);
    }
    final Future<void> started = _performCancel();
    _cleanupFuture = started;
    return _awaitBoundedCancel(() => started, timeout: timeout);
  }

  Future<void> _performCancel() async {
    _cancelled = true;
    _finished = true;
    final Future<ResponseBody>? pendingFetch = _fetchFuture;
    Stream<Uint8List>? lateStream;
    if (pendingFetch != null && _rawStream == null) {
      try {
        final ResponseBody lateBody = await pendingFetch;
        lateStream = lateBody.stream;
      } on Object {
        // Pre-header adapter cancellation completed with an exception.
      }
    }
    final StreamSubscription<Uint8List>? sub = _rawSub;
    _rawSub = null;
    try {
      if (sub != null) {
        _rawStreamCancelled = true;
        await sub.cancel();
      } else if (!_rawStreamCancelled) {
        final Stream<Uint8List>? target = _rawStream ?? lateStream;
        if (target != null && !identical(target, _controller.stream)) {
          _rawStreamCancelled = true;
          await target.listen((_) {}).cancel();
        }
      }
    } on Object {
      // Ignore stream cancellation cleanup errors.
    } finally {
      if (!_controller.isClosed) {
        unawaited(_controller.close());
      }
    }
  }
}
