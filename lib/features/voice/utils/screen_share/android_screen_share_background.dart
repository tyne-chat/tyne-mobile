import 'package:fluxer_voice/fluxer_voice.dart';

// Fork imports.
// ignore: directives_ordering
import 'package:fluxer_app/core/instance/instance_constants.dart';

Future<bool> isAndroidScreenShareBackgroundRunning() {
  return FluxerVoiceScreenShareService.instance.isRunning();
}

Future<bool> enableAndroidScreenShareBackground({
  required String notificationText,
}) {
  return FluxerVoiceScreenShareService.instance.start(
    title: InstanceConstants.defaultProductName,
    text: notificationText,
  );
}

Future<void> disableAndroidScreenShareBackground() {
  return FluxerVoiceScreenShareService.instance.stop();
}
