import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kAppForegroundSessionActiveKey = 'app_foreground_session_active';

class AppForegroundSessionBootstrapResult {
  const AppForegroundSessionBootstrapResult({required this.hadForegroundCrash});

  final bool hadForegroundCrash;
}

AppForegroundSessionBootstrapResult? _bootstrapResult;

AppForegroundSessionBootstrapResult get cachedAppForegroundSessionBootstrap =>
    _bootstrapResult ??
    const AppForegroundSessionBootstrapResult(hadForegroundCrash: false);

Future<AppForegroundSessionBootstrapResult>
bootstrapAppForegroundSession() async {
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  final bool hadForegroundCrash =
      preferences.getBool(kAppForegroundSessionActiveKey) ?? false;
  // Fork: only a process on screen marks the session active. The full app can start without a
  // screen, and Android ending such a process was then reported as a crash (tyne-chat/tyne#210).
  await preferences.setBool(
    kAppForegroundSessionActiveKey,
    WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
  );
  _bootstrapResult = AppForegroundSessionBootstrapResult(
    hadForegroundCrash: hadForegroundCrash,
  );
  return _bootstrapResult!;
}

Future<void> setAppForegroundSessionActive({required bool active}) async {
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.setBool(kAppForegroundSessionActiveKey, active);
}

void installAppForegroundSessionLifecycleBinding() {
  final WidgetsBinding binding = WidgetsBinding.instance;
  if (binding.lifecycleState == AppLifecycleState.resumed) {
    unawaited(setAppForegroundSessionActive(active: true));
  }
  binding.addObserver(_AppForegroundSessionLifecycleObserver());
}

class _AppForegroundSessionLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(setAppForegroundSessionActive(active: true));
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(setAppForegroundSessionActive(active: false));
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }
}
