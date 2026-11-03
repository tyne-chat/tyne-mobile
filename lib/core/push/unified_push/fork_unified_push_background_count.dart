// Fork: counts the pushes this isolate has handled (tyne-chat/tyne#474).
//
// The push engine is kept between pushes, and each push opens a short session in native code (a
// foreground service and a wake lock). Native counts the pushes it hands over; after each handled
// push, the background isolate reports its own count, and native ends the session only when the
// two agree. A report for the first push of a burst then cannot end the session while a later one
// is still in flight.

import 'package:flutter/foundation.dart';
import 'package:fluxer_app/core/push/unified_push/unified_push_background_native.dart';

int _handled = 0;

/// Reports the count to native; replaced in tests, where the platform channel is not Android's.
@visibleForTesting
Future<void> Function(int handled) forkReportUnifiedPushHandled =
    (int handled) => finishUnifiedPushBackgroundNative(handled: handled);

/// Pushes this isolate has handled.
int get forkUnifiedPushHandledCount => _handled;

/// Counts one handled push and, in the background isolate, reports the count.
Future<void> forkNoteUnifiedPushMessageHandled({
  required bool backgroundMode,
}) async {
  _handled += 1;
  if (backgroundMode) {
    await forkReportUnifiedPushHandled(_handled);
  }
}

@visibleForTesting
void resetForkUnifiedPushHandledCount() {
  _handled = 0;
}
