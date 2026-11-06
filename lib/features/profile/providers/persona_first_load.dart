// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

/// How long a send waits for the persona list, settings and per-channel
/// selections to arrive the first time, before it is held (tyne-chat/tyne#30).
const Duration kPersonaSendWait = Duration(seconds: 5);

/// The first load of something a send needs, such as the persona list.
///
/// A send that finds it missing waits for the load in flight instead of
/// asking again, and after a failure asks again at most every [retryAfter]:
/// sends repeated while the server refuses must not turn into a burst of
/// requests, which signs the user out (tyne-chat/tyne#114). Loads started
/// before [reset] (an account switch) no longer count.
class FirstLoadGate {
  FirstLoadGate({
    this.retryAfter = const Duration(seconds: 10),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Duration retryAfter;
  final DateTime Function() _now;

  Future<bool>? _inFlight;
  DateTime? _failedAt;
  int _generation = 0;

  /// Runs [load], which says whether it succeeded, as the load in flight.
  Future<bool> run(Future<bool> Function() load) {
    final int generation = _generation;
    void settle({required bool ok}) {
      if (generation == _generation) {
        _failedAt = ok ? null : _now();
      }
    }

    final Future<bool> running = load().then(
      (bool ok) {
        settle(ok: ok);
        return ok;
      },
      onError: (Object _) {
        settle(ok: false);
        return false;
      },
    );
    _inFlight = running;
    unawaited(
      running.whenComplete(() {
        if (identical(_inFlight, running)) {
          _inFlight = null;
        }
      }),
    );
    return running;
  }

  /// Waits up to [timeout] for the load in flight, or starts one with [load]
  /// unless the last one failed less than [retryAfter] ago. True if the load
  /// it waited for succeeded.
  Future<bool> wait(
    Future<bool> Function() load, {
    required Duration timeout,
  }) async {
    final DateTime? failedAt = _failedAt;
    final bool coolingDown =
        failedAt != null && _now().difference(failedAt) < retryAfter;
    final Future<bool>? pending = _inFlight ?? (coolingDown ? null : run(load));
    if (pending == null) {
      return false;
    }
    try {
      return await pending.timeout(timeout);
    } on TimeoutException {
      return false;
    }
  }

  /// Forgets the load in flight and the last failure.
  void reset() {
    _generation++;
    _inFlight = null;
    _failedAt = null;
  }
}
