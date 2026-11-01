// Fork: the app's own parser against what the server may send, built from the
// server's OpenAPI spec with every optional field filled in, so a field a real
// document does not happen to carry today is still covered. In the nightly gate
// this reads the spec at the fork's latest server commit, so it also catches an
// SDK that has fallen behind the server (tyne-chat/tyne#454, #455). The API's
// tests check its real responses against the same schemas.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/instance/instance_compatibility.dart';
import 'package:fluxer_app/core/instance/instance_config_snapshot.dart';

import '../../../dart_sdk/test/serialization/fork_spec_sampler.dart';

void main() {
  const String specPath = 'fluxer/fluxer_api/src/api/openapi/openapi.json';

  test('the app parses the discovery document the spec describes', () {
    final File spec = File(specPath);
    expect(
      spec.existsSync(),
      isTrue,
      reason: 'The `fluxer` submodule must be checked out: $specPath',
    );
    final Map<String, dynamic> document =
        SpecSampler(
              jsonDecode(spec.readAsStringSync()) as Map<String, dynamic>,
            ).sample('WellKnownFluxerResponse')!
            as Map<String, dynamic>;

    // Real values: the sampler's placeholders are not a version or generation
    // this client accepts.
    document['api_code_version'] = 1;
    document['codename'] = InstanceCompatibility.currentInstanceCodename;

    expect(
      () => InstanceCompatibility.validateWellKnownDocument(
        InstanceConfigSnapshot.parseWellKnown(document),
      ),
      returnsNormally,
    );
  });
}
