// Fork: Stage 4 orchestration engine and CLI runner for the mobile unified
// custom AST compiler-pipeline linter (`tool/fork_lint.dart`).
// Fork: CLI linter prints diagnostics to stdout.
// ignore_for_file: avoid_print

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import '../fork_lint_reviewed.dart';
import 'discovery.dart';
import 'ir.dart';
import 'passes/async_ref_pass.dart';
import 'passes/safety_pass.dart';
import 'passes/string_pass.dart';
import 'source_unit.dart';

typedef DartPipelineResult = ({
  List<String> problems,
  Map<String, List<String>> problemsByLinter,
  int parseCount,
  DartFileIR? ir,
});

final Map<String, String> _ruleOwner = <String, String>{
  for (final String r in kAllSafetyRules) r: 'safety',
  for (final String r in kAllAsyncRefRules) r: 'async-ref',
  for (final String r in kAllStringRules) r: 'string',
};

/// Programmatic single-file entry point sharing one `parseString` + `DartFileIR`
/// across all requested [linters].
DartPipelineResult lintDartFileWithPipeline(
  String file,
  String source,
  Set<int>? lines, {
  Iterable<String> linters = kAllMobileLinters,
  Set<String> safetyRules = kAllSafetyRules,
  ReviewedLintCatalog? reviewed,
  void Function(String file)? onParse,
}) {
  final Set<String> active = linters.toSet();
  final Map<String, List<String>> byLinter = <String, List<String>>{
    for (final String l in active) l: <String>[],
  };

  final DartSourceUnit unit = DartSourceUnit.parse(
    file,
    source,
    lines: lines,
    onParse: onParse,
  );
  if (unit.isGenerated || unit.unit == null) {
    return (
      problems: const <String>[],
      problemsByLinter: byLinter,
      parseCount: 0,
      ir: null,
    );
  }

  final DartFileIR ir = DartFileIR.build(unit);
  if (active.contains('string')) {
    byLinter['string']!.addAll(runStringPass(ir, reviewed: reviewed));
  }
  if (active.contains('async-ref')) {
    byLinter['async-ref']!.addAll(runAsyncRefPass(ir, reviewed: reviewed));
  }
  if (active.contains('safety')) {
    byLinter['safety']!.addAll(
      runSafetyPass(ir, rules: safetyRules, reviewed: reviewed),
    );
  }

  final List<String> combined = <String>[
    for (final String l in linters)
      if (byLinter.containsKey(l)) ...byLinter[l]!,
  ];

  return (
    problems: combined,
    problemsByLinter: byLinter,
    parseCount: 1,
    ir: ir,
  );
}

String? _optionValue(List<String> args, String name) {
  final int index = args.indexOf(name);
  if (index == -1 || index + 1 >= args.length) {
    return null;
  }
  return args[index + 1];
}

({
  Set<String> activeLinters,
  Set<String> safetyRules,
  Map<String, Set<String>> rulesByLinter,
})
_parseSelection(List<String> args, List<String> defaultLinters) {
  final String? rawLinters = _optionValue(args, '--linter');
  final String? rawRules = _optionValue(args, '--rule');

  Set<String>? selectedLinters;
  if (rawLinters != null && rawLinters.isNotEmpty) {
    selectedLinters = rawLinters
        .split(',')
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toSet();
    for (final String l in selectedLinters) {
      if (!kAllMobileLinters.contains(l)) {
        stderr.writeln(
          'Unknown linter: $l. Available: ${kAllMobileLinters.join(', ')}',
        );
        exit(2);
      }
    }
  }

  final Map<String, Set<String>> rulesByLinter = <String, Set<String>>{};
  Set<String>? inferredLinters;
  if (rawRules != null && rawRules.isNotEmpty) {
    final List<String> chosen = rawRules
        .split(',')
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList();
    inferredLinters = <String>{};
    for (final String r in chosen) {
      final String? owner = _ruleOwner[r];
      if (owner == null ||
          (selectedLinters != null && !selectedLinters.contains(owner))) {
        stderr.writeln(
          'Unknown rule: $r. Available: ${_ruleOwner.keys.join(', ')}',
        );
        exit(2);
      }
      inferredLinters.add(owner);
      rulesByLinter.putIfAbsent(owner, () => <String>{}).add(r);
    }
  }

  final Set<String> active =
      selectedLinters ?? inferredLinters ?? defaultLinters.toSet();
  final Set<String> safetyRules = rulesByLinter['safety'] ?? kAllSafetyRules;
  return (
    activeLinters: active,
    safetyRules: safetyRules,
    rulesByLinter: rulesByLinter,
  );
}

typedef SingleFileLintFn =
    List<String> Function(
      String file,
      String source,
      Set<int>? lines, {
      Set<String>? rules,
      ReviewedLintCatalog? reviewed,
    });

/// Shared CLI entry point powering `tool/fork_lint.dart` and all 3 legacy
/// mobile wrapper scripts.
void runForkLintCli(
  List<String> args, {
  List<String> defaultLinters = kAllMobileLinters,
  SingleFileLintFn? singleFileLinter,
  String Function(int count)? failureFooter,
}) {
  final ReviewedCliArgs reviewedArgs = extractReviewedCliArgs(args);
  final List<String> effectiveArgs = reviewedArgs.restArgs;
  final bool auditJson = effectiveArgs.contains('--audit-json');
  final bool explicitAll = effectiveArgs.contains('--all') || auditJson;
  final bool all = explicitAll || reviewedArgs.checkReviewed;
  final String upstream =
      _optionValue(effectiveArgs, '--upstream') ?? 'upstream/canary';
  final ({
    Set<String> activeLinters,
    Set<String> safetyRules,
    Map<String, Set<String>> rulesByLinter,
  })
  selection = _parseSelection(effectiveArgs, defaultLinters);

  final List<String> given = <String>[
    for (int i = 0; i < effectiveArgs.length; i++)
      if (!effectiveArgs[i].startsWith('--') &&
          (i == 0 ||
              (effectiveArgs[i - 1] != '--upstream' &&
                  effectiveArgs[i - 1] != '--rule' &&
                  effectiveArgs[i - 1] != '--linter')))
        effectiveArgs[i],
  ];

  final ReviewedLintCatalog? catalog = loadReviewedCatalogOrExit(
    reviewedArgs.reviewedPath,
    includeReviewed: !auditJson && reviewedArgs.includeReviewed,
    checkReviewed: reviewedArgs.checkReviewed || auditJson,
  );

  final SplayTreeMap<String, Set<int>?> targets = discoverMobileTargets(
    upstream: upstream,
    all: all,
    given: given,
  );

  final List<String> orderedLinters = <String>[
    for (final String l in kAllMobileLinters)
      if (selection.activeLinters.contains(l)) l,
  ];
  final Map<String, List<String>> allProblemsByLinter = <String, List<String>>{
    for (final String l in orderedLinters) l: <String>[],
  };

  for (final MapEntry<String, Set<int>?> entry in targets.entries) {
    final String source = File(entry.key).readAsStringSync();
    if (singleFileLinter != null && orderedLinters.length == 1 && !auditJson) {
      final String only = orderedLinters.first;
      allProblemsByLinter[only]!.addAll(
        singleFileLinter(
          entry.key,
          source,
          entry.value,
          rules: selection.rulesByLinter[only],
          reviewed: catalog,
        ),
      );
      continue;
    }
    final DartPipelineResult result = lintDartFileWithPipeline(
      entry.key,
      source,
      entry.value,
      linters: orderedLinters,
      safetyRules: selection.safetyRules,
      reviewed: catalog,
    );
    for (final String l in orderedLinters) {
      allProblemsByLinter[l]!.addAll(
        result.problemsByLinter[l] ?? const <String>[],
      );
    }
  }

  final List<String> allProblems = <String>[
    for (final String l in orderedLinters) ...allProblemsByLinter[l]!,
  ];

  if (auditJson) {
    final ReviewedMultiSummary summary = evaluateReviewedForLinters(
      catalog,
      orderedLinters,
      rulesByLinter: selection.rulesByLinter,
    );
    final Map<String, Object?> lintersJson = <String, Object?>{
      for (final String l in orderedLinters)
        l: <String, Object?>{
          'violations': allProblemsByLinter[l] ?? const <String>[],
          'staleReviewed': <String>[
            for (final ReviewedLintEntry e
                in summary.byLinter[l]?.staleEntries ??
                    const <ReviewedLintEntry>[])
              'Stale reviewed entry: ${e.describe()}',
          ],
          'suppressed': summary.byLinter[l]?.suppressed ?? 0,
          'entryCount': summary.byLinter[l]?.entryCount ?? 0,
        },
    };
    print(jsonEncode(<String, Object?>{'linters': lintersJson}));
    exit(0);
  }

  // Legacy `--check-reviewed` without `--all`: validate reviewed catalog only.
  if (reviewedArgs.checkReviewed && !explicitAll) {
    if (orderedLinters.length == 1) {
      final String only = orderedLinters.first;
      finishReviewedCheckOrNotes(
        linter: only,
        catalog: catalog,
        checkReviewed: true,
        reportAllSummary: true,
        allFilesScanned: given.isEmpty,
        rules: selection.rulesByLinter[only],
      );
    } else {
      if (!reviewedCatalogExists(reviewedArgs.reviewedPath)) {
        stderr.writeln(
          'Reviewed lint catalog `${catalog?.sourcePath ?? reviewedArgs.reviewedPath}` does not exist.',
        );
        exit(2);
      }
      final ReviewedMultiSummary summary = evaluateReviewedForLinters(
        catalog,
        orderedLinters,
        rulesByLinter: selection.rulesByLinter,
      );
      if (summary.allStaleEntries.isNotEmpty) {
        for (final ReviewedLintEntry entry in summary.allStaleEntries) {
          stderr.writeln('Stale reviewed entry: ${entry.describe()}');
        }
        stderr.writeln(
          '\n${summary.allStaleEntries.length} stale reviewed entry/entries in '
          '`${catalog!.sourcePath}`. Remove entries that upstream fixed, or '
          'adjust selectors if upstream renamed the symbol.',
        );
        exit(1);
      }
      for (final String l in orderedLinters) {
        final ReviewedLinterStats stats = summary.byLinter[l]!;
        print(
          '${catalog!.sourcePath} ($l): all ${stats.entryCount} reviewed '
          'entry/entries matched (${stats.suppressed} finding(s) suppressed).',
        );
      }
      exit(0);
    }
  }

  bool hasStale = false;
  if (all && catalog != null) {
    if (reviewedArgs.checkReviewed) {
      if (!reviewedCatalogExists(reviewedArgs.reviewedPath)) {
        stderr.writeln(
          'Reviewed lint catalog `${catalog.sourcePath}` does not exist.',
        );
        exit(2);
      }
      final ReviewedMultiSummary summary = evaluateReviewedForLinters(
        catalog,
        orderedLinters,
        rulesByLinter: selection.rulesByLinter,
      );
      if (summary.allStaleEntries.isNotEmpty) {
        hasStale = true;
        for (final ReviewedLintEntry entry in summary.allStaleEntries) {
          stderr.writeln('Stale reviewed entry: ${entry.describe()}');
        }
        stderr.writeln(
          '\n${summary.allStaleEntries.length} stale reviewed entry/entries in '
          '`${catalog.sourcePath}`. Remove entries that upstream fixed, or '
          'adjust selectors if upstream renamed the symbol.',
        );
      } else if (allProblems.isEmpty) {
        for (final String l in orderedLinters) {
          final ReviewedLinterStats stats = summary.byLinter[l]!;
          print(
            '${catalog.sourcePath} ($l): all ${stats.entryCount} reviewed '
            'entry/entries matched (${stats.suppressed} finding(s) suppressed).',
          );
        }
      }
    } else if (orderedLinters.length == 1) {
      final String only = orderedLinters.first;
      finishReviewedCheckOrNotes(
        linter: only,
        catalog: catalog,
        checkReviewed: false,
        reportAllSummary: true,
        allFilesScanned: given.isEmpty,
        rules: selection.rulesByLinter[only],
      );
    } else {
      final ReviewedMultiSummary summary = evaluateReviewedForLinters(
        catalog,
        orderedLinters,
        rulesByLinter: selection.rulesByLinter,
      );
      if (summary.totalSuppressed > 0) {
        stderr.writeln(
          'Suppressed ${summary.totalSuppressed} reviewed upstream '
          'finding(s) via ${catalog.sourcePath} (pass --include-reviewed to '
          'list all).',
        );
      }
      if (given.isEmpty && summary.allStaleEntries.isNotEmpty) {
        stderr.writeln(
          'Note: ${summary.allStaleEntries.length} reviewed entry/entries in '
          '`${catalog.sourcePath}` matched 0 findings (run --check-reviewed to '
          'inspect).',
        );
      }
    }
  }

  allProblems.forEach(print);
  if (allProblems.isNotEmpty) {
    final String footer = failureFooter != null
        ? failureFooter(allProblems.length)
        : '\n${allProblems.length} fork AST lint violation(s). Fix the issue '
              'per AGENTS.md, mark fork lines with the rule ignore comment, '
              'or record reviewed upstream entries in '
              '`$kDefaultReviewedLintPath`.';
    stderr.writeln(footer);
    exit(1);
  }
  if (hasStale) {
    exit(1);
  }
}
