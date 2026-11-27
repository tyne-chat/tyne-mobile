// Fork: unified 4-stage compiler-pipeline custom linter for Tyne mobile
// (tyne-chat/tyne#953). Parses each Dart file once, builds shared `DartFileIR`
// (classes, control flow, guard semantics, def-use flow), and runs `string`,
// `async-ref`, and `safety` passes in one command:
//
//   dart run tool/fork_lint.dart [--upstream <git ref>] [--all] [--linter <l1,l2>] [--rule <r1,r2>] [--include-reviewed] [--check-reviewed] [--audit-json] [--reviewed <path>] [<file>...]

import 'fork_lint/engine.dart';

export 'fork_lint/engine.dart'
    show DartPipelineResult, lintDartFileWithPipeline;

void main(List<String> args) => runForkLintCli(args);
