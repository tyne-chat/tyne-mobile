// Fork: Stage 1 of the mobile custom compiler-pipeline linter — single git
// discovery pass for fork-added and fork-modified Dart files under `lib/`.

import 'dart:collection';
import 'dart:io';

const List<String> kAllMobileLinters = <String>[
  'string',
  'async-ref',
  'safety',
];

final RegExp _generatedPath = RegExp(
  r'(\.(g|freezed|pb|pbenum|pbjson|pbserver|fcm|mocks)\.dart$|/generated/)',
);

String _git(List<String> args) {
  final ProcessResult result = Process.runSync('git', args);
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    exit(2);
  }
  return result.stdout as String;
}

Map<String, Set<int>?> _forkChanges(String upstream) {
  final String base = _git(<String>['merge-base', 'HEAD', upstream]).trim();
  final Map<String, Set<int>?> changes = <String, Set<int>?>{};
  final Set<String> added = _git(<String>[
    'diff',
    '--name-only',
    '--no-renames',
    '--diff-filter=A',
    base,
    '--',
    'lib',
  ]).split('\n').where((String f) => f.isNotEmpty).toSet();
  String? current;
  final RegExp hunk = RegExp(r'^@@ -\S+ \+(\d+)(?:,(\d+))? @@');
  for (final String line in _git(<String>[
    'diff',
    '-U0',
    '--no-color',
    '--no-renames',
    '--diff-filter=M',
    base,
    '--',
    'lib',
  ]).split('\n')) {
    if (line.startsWith('+++ ')) {
      current = line.substring('+++ b/'.length);
      changes[current] = <int>{};
    } else if (current != null) {
      final RegExpMatch? match = hunk.firstMatch(line);
      if (match == null) {
        continue;
      }
      final int start = int.parse(match[1]!);
      final int count = match[2] == null ? 1 : int.parse(match[2]!);
      for (int i = 0; i < count; i++) {
        changes[current]!.add(start + i);
      }
    }
  }
  for (final String file in <String>[
    ...added,
    ..._git(<String>[
      'ls-files',
      '--others',
      '--exclude-standard',
      '--',
      'lib',
    ]).split('\n'),
  ]) {
    if (file.isNotEmpty) {
      changes[file] = null;
    }
  }
  return changes;
}

/// Discovers target Dart files and edited line sets (null = whole file) once
/// across all active mobile linters.
SplayTreeMap<String, Set<int>?> discoverMobileTargets({
  required String upstream,
  required bool all,
  required List<String> given,
}) {
  final Map<String, Set<int>?> rawTargets;
  if (all) {
    final Iterable<String> files = given.isNotEmpty
        ? given
        : _git(<String>['ls-files', '--', 'lib']).split('\n');
    rawTargets = <String, Set<int>?>{
      for (final String f in files)
        if (f.isNotEmpty) f: null,
    };
  } else {
    final Map<String, Set<int>?> changes = _forkChanges(upstream);
    rawTargets = given.isEmpty
        ? changes
        : <String, Set<int>?>{
            for (final String f in given)
              f: changes.containsKey(f) ? changes[f] : <int>{},
          };
  }

  final SplayTreeMap<String, Set<int>?> filtered =
      SplayTreeMap<String, Set<int>?>();
  for (final MapEntry<String, Set<int>?> entry in rawTargets.entries) {
    final String file = entry.key;
    if (!file.endsWith('.dart') ||
        _generatedPath.hasMatch(file) ||
        !File(file).existsSync()) {
      continue;
    }
    filtered[file] = entry.value;
  }
  return filtered;
}
