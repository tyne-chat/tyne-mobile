import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:fluxer_app/core/observability/reporting_consent/app_foreground_session_watchdog.dart';
import 'package:path_provider/path_provider.dart';

/// Fork: where upstream's watchdog keeps its marker file; tests point it at a temporary directory.
@visibleForTesting
Directory? forkForegroundSessionMarkerDirectory;

/// Fork: ends the foreground session as if the app had left the screen, by removing the marker
/// upstream's watchdog keeps while the app is on screen (`kAppForegroundSessionMarkerName`).
///
/// The update installer's screens sit over the app without stopping it, and the installer then
/// kills it to replace it: without this, the next start takes that for a crash. If the user backs
/// out of the installer instead, upstream's watchdog writes the marker again when the app resumes.
Future<void> forkEndAppForegroundSession() async {
  final Directory directory =
      forkForegroundSessionMarkerDirectory ??
      await getApplicationSupportDirectory();
  final File marker = File(
    '${directory.path}/$kAppForegroundSessionMarkerName',
  );
  if (marker.existsSync()) {
    marker.deleteSync();
  }
}
