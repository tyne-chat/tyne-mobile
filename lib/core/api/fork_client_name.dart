// Fork: the name the desktop app gives itself in its user agent (tyne-chat/tyne#941).
//
// Upstream calls its desktop client "Fluxer Oxygen", after its internal name for the desktop app.
// That name means nothing to Tyne's users, so builds that carry the fork's name (FORK_APP_NAME)
// call it "<name> Desktop", as they did before upstream's rename. Builds with upstream's name keep
// upstream's, which upstream's tests expect.

import 'package:fluxer_app/core/instance/instance_constants.dart';

const String _upstreamProductName = 'Fluxer';

String forkDesktopClientName() =>
    forkDesktopClientNameFor(InstanceConstants.defaultProductName);

String forkDesktopClientNameFor(String productName) {
  if (productName == _upstreamProductName) {
    return '$_upstreamProductName Oxygen';
  }
  return '$productName Desktop';
}
