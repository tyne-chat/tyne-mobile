// Fork: "What's new" opens Tyne's release notes, not Fluxer's patch notes
// (tyne-chat/tyne#737).
//
// A published Android build is named after its release (`1.2.25`, with the
// flavour's suffix such as `-canary`), and every published release has a
// GitHub release tagged `v1.2.25` whose notes say what changed. Test builds
// (`1.2.26-dev.lhf.1`), iOS builds and a version that cannot be read open the
// list of releases instead, so nobody lands on another release's notes.

import 'dart:io' show Platform;

import 'package:package_info_plus/package_info_plus.dart';

// The same repository the updater reads (app_update_service.dart).
// ignore: do_not_use_environment -- compile-time build config
const String _kForkReleasesRepo = String.fromEnvironment(
  'FORK_UPDATE_REPO',
  defaultValue: 'tyne-chat/tyne-mobile',
);

const String forkReleasesUrl =
    'https://github.com/$_kForkReleasesRepo/releases';

final RegExp _publishedVersion = RegExp(r'^(\d+\.\d+\.\d+)(?:-[a-z]+)?$');

/// The release notes for [version], or the list of releases when [version] is
/// not a published Android release's name.
String forkWhatsNewUrlFor(String version, {required bool isAndroid}) {
  final RegExpMatch? match = _publishedVersion.firstMatch(version.trim());
  if (!isAndroid || match == null) {
    return forkReleasesUrl;
  }
  return '$forkReleasesUrl/tag/v${match.group(1)}';
}

Future<String> forkWhatsNewUrl() async {
  try {
    final PackageInfo info = await PackageInfo.fromPlatform();
    return forkWhatsNewUrlFor(info.version, isAndroid: Platform.isAndroid);
  } on Object {
    return forkReleasesUrl;
  }
}
