// Fork: backwards-compatible wrapper delegating mobile `string` checks to the
// unified 4-stage compiler pipeline (`tool/fork_lint.dart` /
// `tool/fork_lint/engine.dart`, tyne-chat/tyne#184, tyne-chat/tyne#953).

import 'fork_lint/engine.dart';
import 'fork_lint_reviewed.dart';

/// The problems in one file's [source], on the given [lines] (null for every
/// line), excluding entries matched by [reviewed] when supplied.
List<String> lintSource(
  String file,
  String source,
  Set<int>? lines, {
  ReviewedLintCatalog? reviewed,
}) => lintDartFileWithPipeline(
  file,
  source,
  lines,
  linters: const <String>['string'],
  reviewed: reviewed,
).problems;

void main(List<String> args) => runForkLintCli(
  args,
  defaultLinters: const <String>['string'],
  singleFileLinter:
      (
        String file,
        String source,
        Set<int>? lines, {
        Set<String>? rules,
        ReviewedLintCatalog? reviewed,
      }) => lintSource(file, source, lines, reviewed: reviewed),
  failureFooter: (int count) =>
      '\n$count hard-coded user-facing string(s). Move each into l10n_fork '
      '(see l10n_fork/README.md), mark fork lines with `// i18n-ignore: '
      '<reason>`, or record reviewed upstream entries in '
      '`$kDefaultReviewedLintPath`.',
);
