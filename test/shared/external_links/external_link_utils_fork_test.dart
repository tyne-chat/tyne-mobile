// Fork: the instance's own hosts are trusted links (tyne-chat/tyne#875).

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/instance/instance_endpoints.dart';
import 'package:fluxer_app/shared/external_links/external_link_utils.dart';

void main() {
  setUp(() {
    InstanceEndpoints.webApp = 'https://chat.example';
    InstanceEndpoints.media = 'https://media.example/media';
    InstanceEndpoints.staticCdn = 'https://static.example';
    InstanceEndpoints.api = 'https://api.example/api';
  });
  tearDown(InstanceEndpoints.resetToDefaults);

  test('trusts the hosts of the instance endpoints without asking', () {
    for (final String host in <String>[
      'chat.example',
      'media.example',
      'static.example',
      'api.example',
      'MEDIA.example',
    ]) {
      expect(
        isTrustedDomain(host, trustedDomains: const <String>[]),
        isTrue,
        reason: host,
      );
    }
  });

  test(
    'still asks for any other host, subdomains of the instance included',
    () {
      for (final String host in <String>[
        'example.org',
        'evil.media.example',
        'example',
        '',
      ]) {
        expect(
          isTrustedDomain(host, trustedDomains: const <String>[]),
          isFalse,
          reason: host,
        );
      }
    },
  );

  test('trusts the default instance before its endpoints are loaded', () {
    InstanceEndpoints.resetToDefaults();
    final String host = Uri.parse(InstanceEndpoints.defaultMedia).host;
    expect(isTrustedDomain(host, trustedDomains: const <String>[]), isTrue);
  });
}
