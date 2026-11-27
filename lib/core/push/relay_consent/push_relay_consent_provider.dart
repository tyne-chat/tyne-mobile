import 'package:flutter/foundation.dart';
import 'package:fluxer_app/core/build/push_provider_guard.dart';
import 'package:fluxer_app/core/providers/instance/active_instance_provider.dart';
import 'package:fluxer_app/core/push/relay_consent/push_relay_consent_logic.dart';
import 'package:fluxer_app/core/push/relay_consent/push_relay_consent_prompt_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'push_relay_consent_provider.g.dart';

const String _kPushRelayConsentGrantedKey = 'push_relay_consent_granted';
const String _kPushRelayConsentDeclinedUsersKey =
    'push_relay_consent_declined_users';

bool pushRelayConsentIsAvailable() {
  if (!PushProviderGuard.isApple && !PushProviderGuard.isFirebaseMessaging) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android;
}

@Riverpod(keepAlive: true)
class PushRelayConsent extends _$PushRelayConsent {
  Future<void>? _loadInFlight;
  bool _isLoaded = false;
  Set<String> _declinedUserIds = <String>{};
  int _forkBuildEpoch = 0;

  @override
  bool build() {
    // Fork: reset instance fields on rebuild so invalidated keepAlive state
    // reloads cleanly instead of staying stuck at `false` (tyne-chat/tyne#946).
    _forkResetForBuild();
    return false;
  }

  void _forkResetForBuild() {
    _forkBuildEpoch += 1;
    _loadInFlight = null;
    _isLoaded = false;
    _declinedUserIds = <String>{};
  }

  Future<void> load() {
    _loadInFlight = _load();
    return _loadInFlight!;
  }

  Future<void> ensureLoaded() {
    if (_isLoaded) {
      return Future<void>.value();
    }
    return _loadInFlight ??= _load();
  }

  Future<void> _load() async {
    final int epoch = _forkBuildEpoch;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    if (!ref.mounted || epoch != _forkBuildEpoch || _isLoaded) {
      return;
    }
    _declinedUserIds =
        (preferences.getStringList(_kPushRelayConsentDeclinedUsersKey) ??
                const <String>[])
            .toSet();
    state = preferences.getBool(_kPushRelayConsentGrantedKey) ?? false;
    _isLoaded = true;
  }

  bool hasDeclined(String userId) => _declinedUserIds.contains(userId);

  Future<void> grant() async {
    _isLoaded = true;
    state = true;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_kPushRelayConsentGrantedKey, true);
  }

  Future<void> revoke({required Set<String> userIds}) async {
    _isLoaded = true;
    state = false;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_kPushRelayConsentGrantedKey, false);
    await decline(userIds);
  }

  Future<void> decline(Set<String> userIds) async {
    if (userIds.every(_declinedUserIds.contains)) {
      return;
    }
    _declinedUserIds = <String>{..._declinedUserIds, ...userIds};
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _kPushRelayConsentDeclinedUsersKey,
      _declinedUserIds.toList(),
    );
  }
}

Future<bool> ensurePushRelayConsent(
  Ref ref,
  String relayUrl, {
  required String userId,
  bool allowPrompt = true,
}) async {
  final bool isOfficialInstance = ref.read(isActiveInstanceOfficialProvider);
  final PushRelayConsent consent = ref.read(pushRelayConsentProvider.notifier);
  await consent.ensureLoaded();
  final bool isConsentGranted = ref.read(pushRelayConsentProvider);
  if (!isPushRelayConsentRequired(
    relayUrl: relayUrl,
    isConsentGranted: isConsentGranted,
    isOfficialInstance: isOfficialInstance,
  )) {
    return true;
  }
  if (allowPrompt &&
      shouldPromptForPushRelayConsent(
        relayUrl: relayUrl,
        isConsentGranted: isConsentGranted,
        hasDeclinedOnAccount: consent.hasDeclined(userId),
        isOfficialInstance: isOfficialInstance,
      )) {
    ref
        .read(pushRelayConsentPromptProvider.notifier)
        .requestPrompt(userId: userId);
  }
  return false;
}

Future<void> recordPushRelayConsentSheetResult({
  required PushRelayConsent consent,
  required bool? agreed,
  required Set<String> userIds,
}) async {
  switch (agreed) {
    case true:
      await consent.grant();
    case false:
      await consent.decline(userIds);
    case null:
      return;
  }
}
