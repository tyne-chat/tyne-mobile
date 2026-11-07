import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Tyne's artwork lives in the `canary` source set and takes the place of
// upstream's by resource name (android/AGENTS.md, "The fork's changes"). When
// upstream renames a resource, the fork's file stops replacing anything and
// upstream's artwork ships again, with no conflict to say so: upstream's
// renamed notification icon brought Fluxer's logo back to the status bar
// (tyne-chat/tyne#532).
void main() {
  final Directory root = _findProjectRoot(Directory.current);
  final Directory canaryRes = Directory(
    '${root.path}/android/app/src/canary/res',
  );
  final Directory mainRes = Directory('${root.path}/android/app/src/main/res');

  test("every canary resource that is not Tyne's own replaces one in main", () {
    final List<String> orphans = <String>[];
    for (final File file in _files(canaryRes)) {
      final String type = _resourceType(file);
      if (type == 'values') {
        final Set<String> mainNames = _files(mainRes)
            .where((File f) => _resourceType(f) == 'values')
            .expand(_valueNames)
            .toSet();
        for (final String name in _valueNames(file)) {
          if (!name.startsWith('tyne_') && !mainNames.contains(name)) {
            orphans.add('${_relative(canaryRes, file)}: $name');
          }
        }
        continue;
      }
      final String name = _resourceName(file);
      if (name.startsWith('tyne_')) {
        continue;
      }
      final bool replaced = _files(
        mainRes,
      ).any((File f) => _resourceType(f) == type && _resourceName(f) == name);
      if (!replaced) {
        orphans.add(_relative(canaryRes, file));
      }
    }
    expect(
      orphans,
      isEmpty,
      reason:
          'These canary resources match nothing in main/res, so upstream '
          'renamed or removed what they replaced. Give them the new name '
          '(in tyne-tools scripts/brand_icons.py for the generated ones).',
    );
  });

  test("the notification icon upstream asks for is Tyne's", () {
    final String channels = File(
      '${root.path}/lib/core/push/android/channels.dart',
    ).readAsStringSync();
    final RegExpMatch? match = RegExp(
      r"kAndroidPushNotificationIcon\s*=\s*'@drawable/([a-z0-9_]+)'",
    ).firstMatch(channels);
    expect(match, isNotNull, reason: 'kAndroidPushNotificationIcon not found');
    final File alias = File(
      '${canaryRes.path}/drawable/${match!.group(1)}.xml',
    );
    expect(alias.existsSync(), isTrue, reason: '${alias.path} is missing');
    expect(
      alias.readAsStringSync(),
      contains('@drawable/tyne_notification_glyph'),
    );
  });
}

Iterable<File> _files(Directory dir) => dir
    .listSync(recursive: true)
    .whereType<File>()
    .where((File f) => !f.uri.pathSegments.last.startsWith('.'));

// `drawable-xhdpi` and `mipmap-anydpi-v26` are drawable and mipmap resources.
String _resourceType(File file) => file.parent.uri.pathSegments
    .lastWhere((String s) => s.isNotEmpty)
    .split('-')
    .first;

String _resourceName(File file) => file.uri.pathSegments.last.split('.').first;

Iterable<String> _valueNames(File file) => RegExp(
  r'<(?!resources)[a-z-]+\s+name="([^"]+)"',
).allMatches(file.readAsStringSync()).map((RegExpMatch m) => m.group(1)!);

String _relative(Directory base, File file) =>
    file.path.substring(base.path.length + 1);

Directory _findProjectRoot(Directory start) {
  Directory? current = start;
  while (current != null) {
    if (File('${current.path}/pubspec.yaml').existsSync()) {
      return current;
    }
    current = current.parent;
  }
  throw StateError('Could not find project root (pubspec.yaml)');
}
