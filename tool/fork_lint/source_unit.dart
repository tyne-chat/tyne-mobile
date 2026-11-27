// Fork: Stage 2 of the mobile custom compiler-pipeline linter — single
// `parseString` pass and shared per-file `DirectiveTable`.
// Fork: CLI linter imports analyzer from transitive SDK deps.
// ignore_for_file: depend_on_referenced_packages

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';

final RegExp _generatedHeader = RegExp(
  'GENERATED CODE - DO NOT MODIFY BY HAND|This is a generated file|@generated',
);
final RegExp _safetyIgnoreRe = RegExp(r'safety-lint-ignore:\s*\S');
final RegExp _asyncRefIgnoreRe = RegExp(r'async-ref-ignore:\s*\S');
final RegExp _i18nIgnoreRe = RegExp(r'i18n-ignore:\s*\S');

/// Line-level ignore sets built in one scan over `sourceLines`.
class DirectiveTable {
  const DirectiveTable({
    required this.safetyIgnoredLines,
    required this.asyncRefIgnoredLines,
    required this.i18nIgnoredLines,
  });

  factory DirectiveTable.fromSourceLines(List<String> sourceLines) {
    final Set<int> safety = <int>{};
    final Set<int> asyncRef = <int>{};
    final Set<int> i18n = <int>{};
    for (int i = 0; i < sourceLines.length; i++) {
      final String line = sourceLines[i];
      if (_safetyIgnoreRe.hasMatch(line)) {
        safety.addAll(<int>[i + 1, i + 2]);
      }
      if (_asyncRefIgnoreRe.hasMatch(line)) {
        asyncRef.addAll(<int>[i + 1, i + 2]);
      }
      if (_i18nIgnoreRe.hasMatch(line)) {
        i18n.addAll(<int>[i + 1, i + 2]);
      }
    }
    return DirectiveTable(
      safetyIgnoredLines: safety,
      asyncRefIgnoredLines: asyncRef,
      i18nIgnoredLines: i18n,
    );
  }

  final Set<int> safetyIgnoredLines;
  final Set<int> asyncRefIgnoredLines;
  final Set<int> i18nIgnoredLines;
}

/// Parsed Dart compilation unit and line metadata shared across all Stage 3/4 passes.
class DartSourceUnit {
  DartSourceUnit._({
    required this.file,
    required this.source,
    required this.lines,
    required this.isGenerated,
    required this.unit,
    required this.lineInfo,
    required this.sourceLines,
    required this.directives,
  });

  factory DartSourceUnit.parse(
    String file,
    String source, {
    Set<int>? lines,
    void Function(String file)? onParse,
  }) {
    final String head = source.substring(0, source.length.clamp(0, 500));
    if (_generatedHeader.hasMatch(head)) {
      return DartSourceUnit._(
        file: file,
        source: source,
        lines: lines,
        isGenerated: true,
        unit: null,
        lineInfo: null,
        sourceLines: const <String>[],
        directives: const DirectiveTable(
          safetyIgnoredLines: <int>{},
          asyncRefIgnoredLines: <int>{},
          i18nIgnoredLines: <int>{},
        ),
      );
    }

    onParse?.call(file);
    final ParseStringResult parsed = parseString(
      content: source,
      path: file,
      throwIfDiagnostics: false,
    );
    final List<String> sourceLines = source.split('\n');
    return DartSourceUnit._(
      file: file,
      source: source,
      lines: lines,
      isGenerated: false,
      unit: parsed.unit,
      lineInfo: parsed.lineInfo,
      sourceLines: sourceLines,
      directives: DirectiveTable.fromSourceLines(sourceLines),
    );
  }

  final String file;
  final String source;
  final Set<int>? lines;
  final bool isGenerated;
  final CompilationUnit? unit;
  final LineInfo? lineInfo;
  final List<String> sourceLines;
  final DirectiveTable directives;

  bool isLineEnabled(int line) => lines == null || lines!.contains(line);

  String sourceLineAt(int line) =>
      (line >= 1 && line <= sourceLines.length) ? sourceLines[line - 1] : '';
}
