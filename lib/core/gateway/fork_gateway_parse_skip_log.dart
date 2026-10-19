// Fork: writes what the SDK's gateway parser skipped to App logs
// (tyne-chat/tyne#193).
//
// The parser drops list items and embedded objects it cannot parse (a member,
// a role, a channel) and reports them through `ForkGatewayParseSkips` in the
// SDK. Silently dropped, the user's own guild member went missing after READY
// for accounts with a reply mention preference set, and it took days to find.
// Talker also prints to the console, so the lines reach Android's logcat.

import 'package:flutter/foundation.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_dart/gateway_client/fork_parse_skips.dart';

/// Logs each kind of skip the first time, then again at the 10th, 100th and
/// so on with the count, so one bad field across many items cannot flood the
/// log. Stops taking new kinds after [maxKinds].
class ForkGatewayParseSkipLog {
  ForkGatewayParseSkipLog({required this.log, this.maxKinds = 50});

  final void Function(String line) log;
  final int maxKinds;
  final Map<String, int> _counts = <String, int>{};
  bool _saidTooMany = false;

  void record(String skipped, Object error) {
    final String reason = _reason(error);
    final String key = '$skipped\n$reason';
    final int? previous = _counts[key];
    if (previous == null && _counts.length >= maxKinds) {
      if (!_saidTooMany) {
        _saidTooMany = true;
        log('more than $maxKinds kinds of skipped items; not logging new ones');
      }
      return;
    }
    final int count = (previous ?? 0) + 1;
    _counts[key] = count;
    if (count == 1) {
      log('skipped a $skipped that did not parse: $reason');
    } else if (_isPowerOfTen(count)) {
      log('skipped $count of $skipped that did not parse: $reason');
    }
  }
}

String _reason(Object error) {
  final String text = '$error'.replaceAll('\n', ' ');
  return text.length <= 300 ? text : '${text.substring(0, 300)}…';
}

bool _isPowerOfTen(int value) {
  var rest = value;
  while (rest >= 10 && rest % 10 == 0) {
    rest ~/= 10;
  }
  return rest == 1 && value >= 10;
}

/// Sends what the gateway parser skips to App logs. Called once at startup.
void forkLogGatewayParseSkips() {
  final ForkGatewayParseSkipLog skipLog = ForkGatewayParseSkipLog(
    log: (String line) => talker.warning('[Gateway] Fork: $line'),
  );
  ForkGatewayParseSkips.onSkipped = skipLog.record;
}

typedef _ForkSkip = ({String skipped, String error});

/// [compute], forwarding to this isolate what the gateway parser skipped in
/// the background one: `ForkGatewayParseSkips.onSkipped` is set per isolate.
Future<R> forkComputeLoggingSkips<M, R>(
  ComputeCallback<M, R> callback,
  M message,
) async {
  final ({R result, List<_ForkSkip> skips}) out = await compute(
    _forkRunRecordingSkips<M, R>,
    (callback: callback, message: message),
  );
  for (final _ForkSkip skip in out.skips) {
    ForkGatewayParseSkips.report(skip.skipped, skip.error);
  }
  return out.result;
}

Future<({R result, List<_ForkSkip> skips})> _forkRunRecordingSkips<M, R>(
  ({ComputeCallback<M, R> callback, M message}) input,
) async {
  final List<_ForkSkip> skips = <_ForkSkip>[];
  final ForkGatewayParseSkipHandler? previous = ForkGatewayParseSkips.onSkipped;
  ForkGatewayParseSkips.onSkipped = (String skipped, Object error) =>
      skips.add((skipped: skipped, error: '$error'));
  try {
    final R result = await input.callback(input.message);
    return (result: result, skips: skips);
  } finally {
    ForkGatewayParseSkips.onSkipped = previous;
  }
}
