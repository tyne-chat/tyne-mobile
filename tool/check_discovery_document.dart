// Fork: parses a saved discovery document with the app's own parser, so a build
// that cannot read production's document is not released (tyne-chat/tyne#459).
// Fetching it is the caller's job, so a network failure and a parse failure stay
// two different errors. It runs under `flutter test`, not `dart run`: the parser
// imports Flutter (upstream's instance_endpoint_normalizer.dart), which a plain
// Dart VM cannot load.
//
//   curl -fsS https://<instance>/api/.well-known/fluxer -o discovery.json
//   DISCOVERY_DOCUMENT=discovery.json flutter test tool/check_discovery_document.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/instance/instance_config_snapshot.dart';

void main() {
  test('this build parses the discovery document', () {
    final String? path = Platform.environment['DISCOVERY_DOCUMENT'];
    if (path == null || path.isEmpty) {
      fail('Set DISCOVERY_DOCUMENT to the saved discovery document.');
    }
    final Object? document = jsonDecode(File(path).readAsStringSync());
    final int version = InstanceConfigSnapshot.parseWellKnown(
      document! as Map<String, dynamic>,
    ).apiCodeVersion;
    // ignore: avoid_print // Fork: the release script shows this line.
    print('This build parses the document (API code version $version).');
  });
}
