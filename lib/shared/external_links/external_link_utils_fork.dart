// Fork: the instance's own hosts are trusted links (tyne-chat/tyne#875).
//
// Upstream trusts a fixed list of Fluxer's domains (`implicitlyTrustedDomains`), so on another
// instance a link to its own media, such as an attachment's download, asked for the external-link
// warning. The web app trusts the hosts of the instance's configured endpoints
// (`TrustedDomain.ts`); this does the same with the endpoints the app has loaded.

import 'package:fluxer_app/core/instance/instance_endpoints.dart';

/// Whether [hostname] is the host of one of the instance's own endpoints.
bool forkIsInstanceHost(String hostname) {
  final String host = hostname.toLowerCase();
  if (host.isEmpty) {
    return false;
  }
  return forkInstanceEndpoints().any(
    (String endpoint) => Uri.tryParse(endpoint)?.host.toLowerCase() == host,
  );
}

/// The instance's endpoints whose hosts are trusted, as the web app's list.
List<String> forkInstanceEndpoints() => <String>[
  InstanceEndpoints.webApp,
  InstanceEndpoints.api,
  InstanceEndpoints.media,
  InstanceEndpoints.staticCdn,
  InstanceEndpoints.invite,
  InstanceEndpoints.gift,
];
