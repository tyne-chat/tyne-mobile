// Fork: tests for lib/core/instance/fork_discovery_failure_report.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/instance/fork_discovery_failure_report.dart';
import 'package:fluxer_app/core/instance/well_known_compat.dart';

void main() {
  tearDown(() => forkOnWellKnownParseFailure = null);

  // A document whose fields are wrong enough to fail, with a value that must
  // not leave the phone.
  Map<String, dynamic> unreadableDocument() => <String, dynamic>{
    'api_code_version': 'secret-looking-value',
    'endpoints': 'secret-looking-value',
  };

  test('a document that fails to parse is reported and still throws', () {
    Object? seen;
    forkOnWellKnownParseFailure = (Object error, StackTrace _) => seen = error;

    expect(() => parseWellKnownFluxer(unreadableDocument()), throwsA(anything));
    expect(seen, isNotNull);
  });

  test('a run of failures is reported once', () {
    final List<ForkDiscoveryParseFailure> sent = <ForkDiscoveryParseFailure>[];
    forkOnWellKnownParseFailure = ForkDiscoveryFailureReport(
      (ForkDiscoveryParseFailure failure, StackTrace _) => sent.add(failure),
    ).report;

    for (int i = 0; i < 5; i++) {
      expect(
        () => parseWellKnownFluxer(unreadableDocument()),
        throwsA(anything),
      );
    }

    expect(sent, hasLength(1));
  });

  test('the report names the field and carries nothing from the document', () {
    final List<ForkDiscoveryParseFailure> sent = <ForkDiscoveryParseFailure>[];
    forkOnWellKnownParseFailure = ForkDiscoveryFailureReport(
      (ForkDiscoveryParseFailure failure, StackTrace _) => sent.add(failure),
    ).report;

    expect(() => parseWellKnownFluxer(unreadableDocument()), throwsA(anything));

    expect(sent.single.toString(), contains('WellKnownFluxerResponse.'));
    expect(sent.single.toString(), isNot(contains('secret-looking-value')));
  });
}
