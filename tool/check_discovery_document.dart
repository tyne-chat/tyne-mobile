// Fork: parses a saved discovery document with the app's own parser, so a build
// that cannot read production's document is not released (tyne-chat/tyne#459).
// Fetching it is the caller's job, so a network failure and a parse failure stay
// two different errors.
//
//   curl -fsS https://<instance>/api/.well-known/fluxer -o discovery.json
//   dart run tool/check_discovery_document.dart discovery.json

import 'dart:convert';
import 'dart:io';

import 'package:fluxer_app/core/instance/instance_config_snapshot.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('usage: check_discovery_document.dart <file>');
    exitCode = 2;
    return;
  }
  try {
    final Object? document = jsonDecode(File(args.single).readAsStringSync());
    final int version = InstanceConfigSnapshot.parseWellKnown(
      document! as Map<String, dynamic>,
    ).apiCodeVersion;
    stdout.writeln(
      'This build parses the document (API code version $version).',
    );
  } on Object catch (error) {
    stderr.writeln('This build cannot parse the discovery document:\n$error');
    exitCode = 1;
  }
}
