// Fork: backwards-compatible wrapper delegating mobile `safety` checks to the
// unified 4-stage compiler pipeline (`tool/fork_lint.dart` /
// `tool/fork_lint/engine.dart`, tyne-chat/tyne#945, tyne-chat/tyne#953).

import 'fork_lint/engine.dart';
import 'fork_lint/passes/safety_pass.dart';
import 'fork_lint_reviewed.dart';

export 'fork_lint/passes/safety_pass.dart' show kAllSafetyRules;

/// Runs the mobile AST safety checks on [source], filtered to [lines] (`null`
/// checks every line), [rules] (defaults to [kAllSafetyRules]), and
/// optional [reviewed] exceptions.
List<String> lintSafetySource(
  String file,
  String source,
  Set<int>? lines, {
  Set<String> rules = kAllSafetyRules,
  ReviewedLintCatalog? reviewed,
}) => lintDartFileWithPipeline(
  file,
  source,
  lines,
  linters: const <String>['safety'],
  safetyRules: rules,
  reviewed: reviewed,
).problems;

void main(List<String> args) => runForkLintCli(
  args,
  defaultLinters: const <String>['safety'],
  singleFileLinter:
      (
        String file,
        String source,
        Set<int>? lines, {
        Set<String>? rules,
        ReviewedLintCatalog? reviewed,
      }) => lintSafetySource(
        file,
        source,
        lines,
        rules: rules ?? kAllSafetyRules,
        reviewed: reviewed,
      ),
  failureFooter: (int count) =>
      '\n$count fork safety lint violation(s). Fix the code per AGENTS.md, '
      'mark fork lines with `// safety-lint-ignore: <reason>`, or record '
      'reviewed upstream entries in `$kDefaultReviewedLintPath`.',
);
