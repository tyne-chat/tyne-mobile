// Fork: the desktop client's name in the user agent (tyne-chat/tyne#941). Upstream's
// fluxer_platform_test.dart covers builds with upstream's name ("Fluxer Oxygen").

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_properties.dart';
import 'package:fluxer_app/core/api/fork_client_name.dart';
import 'package:fluxer_app/core/instance/instance_constants.dart';

void main() {
  group('forkDesktopClientNameFor', () {
    test('builds with the fork name call the desktop client Desktop', () {
      expect(forkDesktopClientNameFor('Tyne'), 'Tyne Desktop');
    });

    test('builds with upstream name keep upstream name', () {
      expect(forkDesktopClientNameFor('Fluxer'), 'Fluxer Oxygen');
    });

    test('defaults to the build product name', () {
      expect(
        forkDesktopClientName(),
        forkDesktopClientNameFor(InstanceConstants.defaultProductName),
      );
    });
  });

  test('desktop user agents use the fork desktop client name', () {
    for (final TargetPlatform platform in <TargetPlatform>[
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.linux,
    ]) {
      final String userAgent = buildFluxerClientUserAgent(
        clientPlatform: resolveClientPlatform(platform),
        clientVersion: '1.0.0',
        releaseChannel: 'beta',
        systemToken: resolveUserAgentSystemToken(platform),
      );
      expect(userAgent, startsWith('${forkDesktopClientName()}/1.0.0 ('));
    }
  });
}
