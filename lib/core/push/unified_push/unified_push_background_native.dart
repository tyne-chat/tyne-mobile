import 'dart:io';

import 'package:flutter/services.dart';

const MethodChannel _kUnifiedPushBackgroundChannel = MethodChannel(
  'com.fluxer/unified_push_background',
);

Future<void> prepareUnifiedPushBackgroundNative() async {
  if (!Platform.isAndroid) {
    return;
  }
  try {
    await _kUnifiedPushBackgroundChannel.invokeMethod<void>('prepare');
  } on Object {
    return;
  }
}

// Fork: `handled` tells native how many pushes this isolate has handled, so it ends the push
// session only when every push it delivered is done (tyne-chat/tyne#474).
Future<void> finishUnifiedPushBackgroundNative({int? handled}) async {
  if (!Platform.isAndroid) {
    return;
  }
  try {
    await _kUnifiedPushBackgroundChannel.invokeMethod<void>(
      'finish',
      handled == null ? null : <String, Object?>{'handled': handled},
    );
  } on Object {
    return;
  }
}
