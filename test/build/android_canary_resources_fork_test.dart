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
          '(in tyne-tools scripts/install_icon_kit.py for the generated ones).',
    );
  });

  // Tyne's icons have the format and size of upstream's; only the artwork is
  // Tyne's. The notification icon was a bitmap where upstream's is a vector
  // (tyne-chat/tyne#870).
  test(
    "the notification icon upstream asks for is Tyne's, in upstream's form",
    () {
      final String channels = File(
        '${root.path}/lib/core/push/android/channels.dart',
      ).readAsStringSync();
      final RegExpMatch? match = RegExp(
        r"kAndroidPushNotificationIcon\s*=\s*'@drawable/([a-z0-9_]+)'",
      ).firstMatch(channels);
      expect(
        match,
        isNotNull,
        reason: 'kAndroidPushNotificationIcon not found',
      );
      final String name = match!.group(1)!;
      final File ours = File('${canaryRes.path}/drawable/$name.xml');
      final File upstreams = File('${mainRes.path}/drawable/$name.xml');
      expect(ours.existsSync(), isTrue, reason: '${ours.path} is missing');
      expect(
        upstreams.existsSync(),
        isTrue,
        reason: '${upstreams.path} is gone',
      );
      final String tyne = ours.readAsStringSync();
      final String upstream = upstreams.readAsStringSync();
      expect(tyne, contains('installed from the icon kit'));
      expect(_rootElement(tyne), _rootElement(upstream));
      for (final String attribute in <String>[
        'android:width',
        'android:height',
        'android:viewportWidth',
        'android:viewportHeight',
      ]) {
        expect(
          _attribute(tyne, attribute),
          _attribute(upstream, attribute),
          reason: "$attribute of $name differs from upstream's",
        );
      }
    },
  );

  // Upstream's launch screens (e46d14911, 2026-11) name their mark in the
  // splash styles and in launch_background.xml, under names the canary source
  // set did not replace yet, so v1.2.17 started with Fluxer's mark and was
  // retracted. Every mark a launch screen shows has to be Tyne's; only the
  // starfield behind it is upstream's.
  test("the marks upstream's launch screens show are Tyne's", () {
    const Set<String> backgrounds = <String>{'splash_starfield'};
    final Set<String> marks = <String>{};
    for (final File file in _files(mainRes)) {
      final String name = file.uri.pathSegments.last;
      if (name == 'styles.xml') {
        marks.addAll(
          RegExp('windowSplashScreen(?:Animated)?Icon">@drawable/([a-z0-9_]+)')
              .allMatches(file.readAsStringSync())
              .map((RegExpMatch m) => m.group(1)!),
        );
      } else if (name == 'launch_background.xml') {
        marks.addAll(
          RegExp('@drawable/([a-z0-9_]+)')
              .allMatches(file.readAsStringSync())
              .map((RegExpMatch m) => m.group(1)!),
        );
      }
    }
    marks.removeAll(backgrounds);
    expect(marks, isNotEmpty, reason: 'no launch screen marks found');
    for (final String mark in marks) {
      final File override = File('${canaryRes.path}/drawable/$mark.xml');
      expect(
        override.existsSync(),
        isTrue,
        reason: '$mark is shown at launch but has no Tyne version in canary',
      );
      expect(
        override.readAsStringSync(),
        contains('installed from the icon kit'),
        reason: '$mark should come from tyne-tools scripts/install_icon_kit.py',
      );
    }
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

String? _rootElement(String xml) =>
    RegExp(r'<([a-z-]+)\s+xmlns:android').firstMatch(xml)?.group(1);

String? _attribute(String xml, String attribute) =>
    RegExp('$attribute="([^"]*)"').firstMatch(xml)?.group(1);

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
