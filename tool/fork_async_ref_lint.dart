// Fork: backwards-compatible wrapper delegating mobile `async-ref` checks to
// the unified 4-stage compiler pipeline (`tool/fork_lint.dart` /
// `tool/fork_lint/engine.dart`, tyne-chat/tyne#943, tyne-chat/tyne#953).

import 'fork_lint/engine.dart';
import 'fork_lint_reviewed.dart';

/// Returns unguarded post-`await` `WidgetRef` / `BuildContext` uses in [source]
/// on [lines] (`null` checks every line), excluding entries matched by
/// [reviewed] when supplied.
List<String> lintAsyncRefSource(
  String file,
  String source,
  Set<int>? lines, {
  ReviewedLintCatalog? reviewed,
}) => lintDartFileWithPipeline(
  file,
  source,
  lines,
  linters: const <String>['async-ref'],
  reviewed: reviewed,
).problems;

void main(List<String> args) => runForkLintCli(
  args,
  defaultLinters: const <String>['async-ref'],
  singleFileLinter:
      (
        String file,
        String source,
        Set<int>? lines, {
        Set<String>? rules,
        ReviewedLintCatalog? reviewed,
      }) => lintAsyncRefSource(file, source, lines, reviewed: reviewed),
  failureFooter: (int count) =>
      '\n$count unguarded WidgetRef/BuildContext read(s) after `await`. '
      'Pre-capture providers before `await`, guard with `mounted` / '
      '`context.mounted` / `ref.context.mounted`, mark fork lines with '
      '`// async-ref-ignore: <reason>`, or record reviewed upstream entries '
      'in `$kDefaultReviewedLintPath`.',
);
