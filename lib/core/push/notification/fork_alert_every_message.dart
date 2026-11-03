// Fork: the device's "alert for every message" setting (tyne-chat/tyne#468).
//
// Kept on the device, not synced: it decides how this phone alerts. Read with
// SharedPreferencesAsync, which keeps no in-memory copy, so a change made in
// the app is seen by the background isolate that shows pushes.

import 'package:shared_preferences/shared_preferences.dart';

const String _key = 'fork_push_alert_every_message';

/// Whether every message alerts. Off by default.
Future<bool> readForkPushAlertEveryMessage() async {
  try {
    return await SharedPreferencesAsync().getBool(_key) ?? false;
  } on Object {
    return false;
  }
}

Future<void> writeForkPushAlertEveryMessage({required bool enabled}) async {
  try {
    await SharedPreferencesAsync().setBool(_key, enabled);
  } on Object {
    return;
  }
}
