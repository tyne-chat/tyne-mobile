// Fork: shared rebase-safe allowlist for upstream findings reported in `--all`
// scans of Tyne's mobile AST linters (`fork_async_ref_lint.dart`,
// `fork_safety_lint.dart`, `fork_string_lint.dart`). Keeping reviewed upstream
// exceptions in `tool/fork_lint_reviewed.json` avoids inserting inline
// `*-ignore:` comments into untouched upstream files that would cause nightly
// rebase conflicts (tyne-chat/tyne#946).
// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';

const String kDefaultReviewedLintPath = 'tool/fork_lint_reviewed.json';

const Set<String> kValidReviewedLinters = <String>{
  'async-ref',
  'safety',
  'string',
};

const Set<String> kValidSafetyRuleNames = <String>{
  'dispose-ref',
  'unmounted-listener',
  'chat-layout',
  'build-network',
  'keepalive-reset',
};

const Set<String> _validTopLevelKeys = <String>{'version', 'entries'};

const Set<String> _validEntryKeys = <String>{
  'linter',
  'file',
  'rule',
  'enclosing',
  'symbol',
  'target',
  'code',
  'reason',
};

String _classOrTypeName(AstNode node) {
  if (node is ClassDeclaration) {
    return node.classKeyword.next?.lexeme ?? '';
  }
  if (node is EnumDeclaration) {
    return node.enumKeyword.next?.lexeme ?? '';
  }
  if (node is MixinDeclaration) {
    return node.name.lexeme;
  }
  if (node is ExtensionDeclaration) {
    return node.name?.lexeme ?? '';
  }
  return '';
}

/// Returns the enclosing `Type.member`, `Type`, or top-level `function` name
/// for [node] so allowlist entries stay resilient across upstream line shifts.
String enclosingAstSymbol(AstNode node) {
  String? memberName;
  bool hasMember = false;
  String? typeName;

  for (AstNode? cur = node.parent; cur != null; cur = cur.parent) {
    if (!hasMember) {
      if (cur is MethodDeclaration) {
        memberName = cur.name.lexeme;
        hasMember = true;
      } else if (cur is ConstructorDeclaration) {
        memberName = cur.name?.lexeme ?? '';
        hasMember = true;
      } else if (cur is FunctionDeclaration && cur.parent is CompilationUnit) {
        memberName = cur.name.lexeme;
        hasMember = true;
      }
    }
    if (typeName == null &&
        (cur is ClassDeclaration ||
            cur is MixinDeclaration ||
            cur is EnumDeclaration ||
            cur is ExtensionDeclaration)) {
      final String candidate = _classOrTypeName(cur);
      if (candidate.isNotEmpty) {
        typeName = candidate;
      }
    }
  }

  if (typeName != null && hasMember) {
    return (memberName == null || memberName.isEmpty)
        ? typeName
        : '$typeName.$memberName';
  }
  if (typeName != null) {
    return typeName;
  }
  return memberName ?? '';
}

/// A candidate lint finding evaluated against [ReviewedLintCatalog].
class ReviewedLintCandidate {
  const ReviewedLintCandidate({
    required this.linter,
    required this.rule,
    required this.file,
    required this.enclosing,
    required this.sourceLine,
    this.symbol,
    this.target,
  });

  final String linter;
  final String rule;
  final String file;
  final String enclosing;
  final String sourceLine;
  final String? symbol;
  final String? target;
}

String _requireNonEmptyString(Map<String, Object?> map, String key, int index) {
  final Object? value = map[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException(
      'Entry #$index in reviewed lint catalog must have a non-empty `$key`.',
    );
  }
  return value.trim();
}

String? _optionalNonEmptyString(
  Map<String, Object?> map,
  String key,
  int index,
) {
  if (!map.containsKey(key) || map[key] == null) {
    return null;
  }
  final Object? value = map[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException(
      'Entry #$index `$key` in reviewed lint catalog must be a non-empty string when provided.',
    );
  }
  return value.trim();
}

/// One reviewed upstream exception recorded outside upstream source files.
class ReviewedLintEntry {
  const ReviewedLintEntry({
    required this.linter,
    required this.file,
    required this.reason,
    this.rule,
    this.enclosing,
    this.symbol,
    this.target,
    this.code,
  });

  factory ReviewedLintEntry.fromJson(Object? raw, int index) {
    if (raw is! Map<String, Object?>) {
      throw FormatException(
        'Entry #$index in reviewed lint catalog must be a JSON object.',
      );
    }
    for (final String key in raw.keys) {
      if (!_validEntryKeys.contains(key)) {
        throw FormatException(
          'Unknown key `$key` in entry #$index of reviewed lint catalog.',
        );
      }
    }
    final String linter = _requireNonEmptyString(raw, 'linter', index);
    if (!kValidReviewedLinters.contains(linter)) {
      throw FormatException(
        'Entry #$index has invalid linter `$linter` '
        '(expected one of: ${kValidReviewedLinters.join(', ')}).',
      );
    }
    final String file = _requireNonEmptyString(raw, 'file', index);
    if (file.startsWith('/') || file.contains(r'\')) {
      throw FormatException(
        'Entry #$index `file` must be a repository-relative forward-slash path: `$file`.',
      );
    }
    final String reason = _requireNonEmptyString(raw, 'reason', index);
    final String? rule = _optionalNonEmptyString(raw, 'rule', index);
    final String? enclosing = _optionalNonEmptyString(raw, 'enclosing', index);
    final String? symbol = _optionalNonEmptyString(raw, 'symbol', index);
    final String? target = _optionalNonEmptyString(raw, 'target', index);
    final String? code = _optionalNonEmptyString(raw, 'code', index);

    if (linter == 'safety') {
      if (rule == null || !kValidSafetyRuleNames.contains(rule)) {
        throw FormatException(
          'Entry #$index for `safety` must specify a valid `rule` '
          '(${kValidSafetyRuleNames.join(', ')}).',
        );
      }
      if (enclosing == null && symbol == null && code == null) {
        throw FormatException(
          'Entry #$index (`$file`) must narrow matches with `enclosing`, '
          '`symbol`, or `code`.',
        );
      }
    } else {
      if (rule != null &&
          !((linter == 'async-ref' && rule == 'async-ref') ||
              (linter == 'string' && rule == 'string-lint'))) {
        throw FormatException(
          'Entry #$index has invalid `rule` `$rule` for linter `$linter`.',
        );
      }
      if (enclosing == null &&
          symbol == null &&
          target == null &&
          code == null) {
        throw FormatException(
          'Entry #$index (`$file`) must narrow matches with `enclosing`, '
          '`symbol`, `target`, or `code`.',
        );
      }
    }

    return ReviewedLintEntry(
      linter: linter,
      file: file,
      reason: reason,
      rule: rule,
      enclosing: enclosing,
      symbol: symbol,
      target: target,
      code: code,
    );
  }

  final String linter;
  final String file;
  final String? rule;
  final String? enclosing;
  final String? symbol;
  final String? target;
  final String? code;
  final String reason;

  bool matches(ReviewedLintCandidate candidate) {
    if (candidate.linter != linter || candidate.file != file) {
      return false;
    }
    if (rule != null && candidate.rule != rule) {
      return false;
    }
    if (enclosing != null && candidate.enclosing != enclosing) {
      return false;
    }
    if (symbol != null) {
      final String candidateSymbol = candidate.symbol ?? '';
      if (symbol!.endsWith('.*')) {
        final String prefix = symbol!.substring(0, symbol!.length - 1);
        if (!candidateSymbol.startsWith(prefix)) {
          return false;
        }
      } else if (candidateSymbol != symbol) {
        return false;
      }
    }
    if (target != null && candidate.target != target) {
      return false;
    }
    if (code != null && !candidate.sourceLine.contains(code!)) {
      return false;
    }
    return true;
  }

  String describe() {
    final List<String> parts = <String>['linter=$linter', 'file=$file'];
    if (rule != null) {
      parts.add('rule=$rule');
    }
    if (enclosing != null) {
      parts.add('enclosing=$enclosing');
    }
    if (symbol != null) {
      parts.add('symbol=$symbol');
    }
    if (target != null) {
      parts.add('target=$target');
    }
    if (code != null) {
      parts.add('code=$code');
    }
    return parts.join(' ');
  }
}

/// Loaded allowlist catalog with per-entry hit counters for staleness checks.
class ReviewedLintCatalog {
  ReviewedLintCatalog._(this.entries, this.sourcePath);

  factory ReviewedLintCatalog.empty({
    String sourcePath = kDefaultReviewedLintPath,
  }) => ReviewedLintCatalog._(const <ReviewedLintEntry>[], sourcePath);

  factory ReviewedLintCatalog.fromEntries(
    List<ReviewedLintEntry> entries, {
    String sourcePath = kDefaultReviewedLintPath,
  }) => ReviewedLintCatalog._(
    List<ReviewedLintEntry>.unmodifiable(entries),
    sourcePath,
  );

  factory ReviewedLintCatalog.fromJsonString(
    String raw, {
    String sourcePath = kDefaultReviewedLintPath,
  }) {
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      throw FormatException(
        'Reviewed lint catalog `$sourcePath` must contain a JSON object.',
      );
    }
    for (final String key in decoded.keys) {
      if (!_validTopLevelKeys.contains(key)) {
        throw FormatException(
          'Unknown top-level key `$key` in reviewed lint catalog `$sourcePath`.',
        );
      }
    }
    if (decoded['version'] != 1) {
      throw FormatException(
        'Reviewed lint catalog `$sourcePath` must specify `"version": 1`.',
      );
    }
    final Object? rawEntries = decoded['entries'];
    if (rawEntries is! List<Object?>) {
      throw FormatException(
        'Reviewed lint catalog `$sourcePath` must have an `"entries"` list.',
      );
    }
    final List<ReviewedLintEntry> parsed = <ReviewedLintEntry>[
      for (int i = 0; i < rawEntries.length; i++)
        ReviewedLintEntry.fromJson(rawEntries[i], i),
    ];
    return ReviewedLintCatalog.fromEntries(parsed, sourcePath: sourcePath);
  }

  factory ReviewedLintCatalog.load([String path = kDefaultReviewedLintPath]) {
    final File file = File(path);
    if (!file.existsSync()) {
      return ReviewedLintCatalog.empty(sourcePath: path);
    }
    return ReviewedLintCatalog.fromJsonString(
      file.readAsStringSync(),
      sourcePath: path,
    );
  }

  final List<ReviewedLintEntry> entries;
  final String sourcePath;
  final Map<int, int> _matchCounts = <int, int>{};
  final Map<String, int> _suppressedByLinter = <String, int>{};

  bool matches(ReviewedLintCandidate candidate) {
    bool matched = false;
    for (int i = 0; i < entries.length; i++) {
      if (entries[i].matches(candidate)) {
        _matchCounts[i] = (_matchCounts[i] ?? 0) + 1;
        matched = true;
      }
    }
    if (matched) {
      _suppressedByLinter[candidate.linter] =
          (_suppressedByLinter[candidate.linter] ?? 0) + 1;
    }
    return matched;
  }

  int suppressedCount(String linter) => _suppressedByLinter[linter] ?? 0;

  int entryCountFor(String linter, {Set<String>? rules}) => entries
      .where(
        (ReviewedLintEntry e) =>
            e.linter == linter &&
            (e.rule == null || rules == null || rules.contains(e.rule)),
      )
      .length;

  List<ReviewedLintEntry> unmatchedEntries(
    String linter, {
    Set<String>? rules,
  }) {
    final List<ReviewedLintEntry> unmatched = <ReviewedLintEntry>[];
    for (int i = 0; i < entries.length; i++) {
      final ReviewedLintEntry entry = entries[i];
      if (entry.linter != linter) {
        continue;
      }
      if (entry.rule != null && rules != null && !rules.contains(entry.rule)) {
        continue;
      }
      if ((_matchCounts[i] ?? 0) == 0) {
        unmatched.add(entry);
      }
    }
    return unmatched;
  }
}

typedef ReviewedCliArgs = ({
  String reviewedPath,
  bool includeReviewed,
  bool checkReviewed,
  List<String> restArgs,
});

/// Strips `--include-reviewed`, `--check-reviewed`, and `--reviewed <path>`
/// from [args] while leaving other flags and file arguments intact.
ReviewedCliArgs extractReviewedCliArgs(List<String> args) {
  String reviewedPath = kDefaultReviewedLintPath;
  bool includeReviewed = false;
  bool checkReviewed = false;
  final List<String> restArgs = <String>[];

  for (int i = 0; i < args.length; i++) {
    final String arg = args[i];
    if (arg == '--include-reviewed') {
      includeReviewed = true;
    } else if (arg == '--check-reviewed') {
      checkReviewed = true;
    } else if (arg == '--reviewed') {
      if (i + 1 >= args.length) {
        stderr.writeln('--reviewed requires a path argument.');
        exit(2);
      }
      reviewedPath = args[++i];
    } else {
      restArgs.add(arg);
    }
  }

  return (
    reviewedPath: reviewedPath,
    includeReviewed: includeReviewed,
    checkReviewed: checkReviewed,
    restArgs: restArgs,
  );
}

/// Loads the reviewed catalog from [reviewedPath], or returns `null` when
/// `--include-reviewed` disables allowlist filtering.
ReviewedLintCatalog? loadReviewedCatalogOrExit(
  String reviewedPath, {
  required bool includeReviewed,
  required bool checkReviewed,
}) {
  if (includeReviewed && !checkReviewed) {
    return null;
  }
  try {
    return ReviewedLintCatalog.load(reviewedPath);
  } on FormatException catch (error) {
    stderr.writeln('Invalid reviewed lint catalog: $error');
    exit(2);
  }
}

/// Completes `--check-reviewed` (exiting the process) or logs summary notes for
/// `--all` scans.
void finishReviewedCheckOrNotes({
  required String linter,
  required ReviewedLintCatalog? catalog,
  required bool checkReviewed,
  required bool reportAllSummary,
  required bool allFilesScanned,
  Set<String>? rules,
}) {
  if (catalog == null) {
    return;
  }
  if (checkReviewed) {
    if (!File(catalog.sourcePath).existsSync()) {
      stderr.writeln(
        'Reviewed lint catalog `${catalog.sourcePath}` does not exist.',
      );
      exit(2);
    }
    final List<ReviewedLintEntry> stale = catalog.unmatchedEntries(
      linter,
      rules: rules,
    );
    if (stale.isNotEmpty) {
      for (final ReviewedLintEntry entry in stale) {
        stderr.writeln('Stale reviewed entry: ${entry.describe()}');
      }
      stderr.writeln(
        '\n${stale.length} stale reviewed entry/entries in '
        '`${catalog.sourcePath}` for `$linter`. Remove entries that upstream '
        'fixed, or adjust selectors if upstream renamed the symbol.',
      );
      exit(1);
    }
    final int entryCount = catalog.entryCountFor(linter, rules: rules);
    final int suppressed = catalog.suppressedCount(linter);
    print(
      '${catalog.sourcePath} ($linter): all $entryCount reviewed entry/entries '
      'matched ($suppressed finding(s) suppressed).',
    );
    exit(0);
  }

  if (!reportAllSummary) {
    return;
  }
  final int suppressed = catalog.suppressedCount(linter);
  if (suppressed > 0) {
    stderr.writeln(
      'Suppressed $suppressed reviewed upstream finding(s) via '
      '${catalog.sourcePath} (pass --include-reviewed to list all).',
    );
  }
  if (allFilesScanned) {
    final List<ReviewedLintEntry> stale = catalog.unmatchedEntries(
      linter,
      rules: rules,
    );
    if (stale.isNotEmpty) {
      stderr.writeln(
        'Note: ${stale.length} reviewed entry/entries in '
        '`${catalog.sourcePath}` for `$linter` matched 0 findings (run '
        '--check-reviewed to inspect).',
      );
    }
  }
}
