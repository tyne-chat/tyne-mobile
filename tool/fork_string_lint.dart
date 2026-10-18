// Fork: finds hard-coded user-facing strings in the fork's code, which
// `flutter test test/l10n_fork` cannot see because they never reach a fork
// catalogue (tyne-chat/tyne#184).
//
//   dart run tool/fork_string_lint.dart [--upstream <git ref>] [--all] [<file>...]
//
// Reports string literals in places users read them (`Text(...)`, user-facing
// named arguments such as `label:` or `errorMessage:`, toasts and error
// dialogs) in the fork's files under lib/. Only files the fork added and lines
// it changed against the merge base with <git ref> (default upstream/canary)
// are checked, working tree and untracked files included; --all checks every
// line of the files given (or of every file under lib/). A literal that really
// is not to be translated gets `// i18n-ignore: <reason>` on its line or the
// line above (or above the statement, declaration or argument it is part of).
// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

final RegExp _generated = RegExp(
  r'(\.(g|freezed|pb|pbenum|pbjson|pbserver|fcm|mocks)\.dart$|/generated/)',
);
final RegExp _generatedHeader = RegExp(
  'GENERATED CODE - DO NOT MODIFY BY HAND|This is a generated file|@generated',
);
final RegExp _ignore = RegExp(r'i18n-ignore:\s*\S');

// Named arguments, variables and fields whose value is shown to people.
final RegExp _uiName = RegExp(
  r'^(label|title|subtitle|text|message|tooltip|hint|description|placeholder|content|displayName|semanticLabel|semanticsLabel)$'
  r'|(Label|Title|Text|Message|Msg|Tooltip|Hint|Description|Placeholder|Caption|Heading)$',
);
// Names that look like the above but are for logs and diagnostics.
final RegExp _notUiName = RegExp('^(debug|log|diagnostic|restoration)');
// Widgets and calls whose first positional argument is shown to people.
final RegExp _textWidget = RegExp(r'^(Text|SelectableText|TextSpan|Tooltip)$');
// Calls whose string arguments are shown to people.
final RegExp _uiCall = RegExp(r'^(show[A-Z]\w*|userFacingErrorMessage)$');
final RegExp _notUiCall = RegExp('^showDebug');
// Calls whose arguments are never shown.
final RegExp _notShownCall = RegExp(
  '^(print|debugPrint|log|assert|Key|ValueKey|ObjectKey|PageStorageKey|GlobalKey'
  r'|\w*Exception|\w*Error|Uri|RegExp|DateFormat|NumberFormat)$',
);
final RegExp _notShownTarget = RegExp(
  r'^(_?log(ger)?|_?logger|Logger|developer|AppLogger)$',
);

bool _isUiName(String name) =>
    _uiName.hasMatch(name) && !_notUiName.hasMatch(name);

String _calleeName(AstNode node) {
  if (node is MethodInvocation) {
    return node.methodName.name;
  }
  if (node is InstanceCreationExpression) {
    final String source = node.constructorName.toSource().split('<').first;
    final List<String> parts = source.split('.');
    // `Text.rich` is named after its class; `prefix.Text` after its last part.
    return parts.length > 1 && RegExp('^[a-z]').hasMatch(parts.last)
        ? parts[parts.length - 2]
        : parts.last;
  }
  if (node is FunctionExpressionInvocation) {
    return node.function.toSource();
  }
  return '';
}

String _targetName(AstNode node) {
  if (node is MethodInvocation) {
    Expression? target = node.target;
    while (target is MethodInvocation || target is PropertyAccess) {
      target = target is MethodInvocation
          ? target.target
          : (target! as PropertyAccess).target;
    }
    return target?.toSource() ?? '';
  }
  return '';
}

String _textOf(StringLiteral node) {
  if (node is SimpleStringLiteral) {
    return node.value;
  }
  if (node is AdjacentStrings) {
    return node.strings.map(_textOf).join();
  }
  if (node is StringInterpolation) {
    return node.elements
        .whereType<InterpolationString>()
        .map((e) => e.value)
        .join();
  }
  return '';
}

bool _looksLikeProse(String text) {
  final String trimmed = text.trim();
  if (!RegExp(r'\p{L}{2,}', unicode: true).hasMatch(trimmed)) {
    return false;
  }
  if (RegExp(r'^(https?:|mailto:|/|#|\.)').hasMatch(trimmed)) {
    return false;
  }
  if (RegExp(
    r'^\p{Lu}\p{Ll}+(\p{Lu}\p{Ll}*)+$',
    unicode: true,
  ).hasMatch(trimmed)) {
    return false;
  }
  return RegExp(r'\s').hasMatch(trimmed) ||
      RegExp(r'^\p{Lu}\p{Ll}', unicode: true).hasMatch(trimmed);
}

// Where a literal ends up: a description of the place users read it, or null.
String? _sinkOf(StringLiteral literal) {
  AstNode child = literal;
  AstNode? parent = literal.parent;
  while (parent is ConditionalExpression ||
      parent is BinaryExpression ||
      parent is ParenthesizedExpression ||
      parent is AsExpression ||
      parent is PostfixExpression) {
    if (parent is ConditionalExpression && parent.condition == child) {
      return null;
    }
    if (parent is BinaryExpression &&
        parent.operator.lexeme != '??' &&
        parent.operator.lexeme != '+') {
      return null;
    }
    child = parent!;
    parent = parent.parent;
  }
  if (parent is NamedArgument) {
    final String name = parent.name.lexeme;
    if (!_isUiName(name)) {
      return null;
    }
    final AstNode? call = parent.parent?.parent;
    if (call != null && _notShownCall.hasMatch(_calleeName(call))) {
      return null;
    }
    return 'argument $name';
  }
  if (parent is ArgumentList) {
    final AstNode? call = parent.parent;
    if (call == null) {
      return null;
    }
    final String callee = _calleeName(call);
    final bool first =
        parent.arguments.where((a) => a is! NamedArgument).firstOrNull == child;
    if (first && _textWidget.hasMatch(callee)) {
      return '$callee()';
    }
    if (_uiCall.hasMatch(callee) && !_notUiCall.hasMatch(callee)) {
      return '$callee()';
    }
    return null;
  }
  if (parent is VariableDeclaration && parent.initializer == child) {
    return _isUiName(parent.name.lexeme)
        ? 'variable ${parent.name.lexeme}'
        : null;
  }
  if (parent is AssignmentExpression && parent.rightHandSide == child) {
    final Expression left = parent.leftHandSide;
    final String name = left is SimpleIdentifier
        ? left.name
        : left is PrefixedIdentifier
        ? left.identifier.name
        : left is PropertyAccess
        ? left.propertyName.name
        : '';
    return _isUiName(name) ? 'variable $name' : null;
  }
  return null;
}

// The statement, declaration or argument a literal belongs to, so that an
// i18n-ignore comment above a wrapped one covers the literal on its next line.
AstNode _holderOf(StringLiteral literal) {
  for (AstNode? node = literal.parent; node != null; node = node.parent) {
    if (node is Statement ||
        node is Declaration ||
        node is NamedArgument ||
        node is VariableDeclaration) {
      return node;
    }
  }
  return literal;
}

// Whether a literal sits somewhere nobody reads it.
bool _isExcluded(StringLiteral literal) {
  for (AstNode? node = literal.parent; node != null; node = node.parent) {
    if (node is Annotation || node is Directive || node is AssertStatement) {
      return true;
    }
    // Widget previews (`@FluxerWidgetPreview`, `@Preview`) are for developers.
    if ((node is FunctionDeclaration || node is MethodDeclaration) &&
        (node as AnnotatedNode).metadata.any(
          (a) => a.name.name.endsWith('Preview'),
        )) {
      return true;
    }
  }
  for (AstNode? node = literal.parent; node != null; node = node.parent) {
    if (node is MethodInvocation || node is InstanceCreationExpression) {
      if (_notShownCall.hasMatch(_calleeName(node))) {
        return true;
      }
      if (_notShownTarget.hasMatch(_targetName(node))) {
        return true;
      }
      // A call that shows its argument decides; one further out does not.
      if (_uiCall.hasMatch(_calleeName(node)) ||
          _textWidget.hasMatch(_calleeName(node))) {
        return false;
      }
    }
  }
  return false;
}

class _Visitor extends RecursiveAstVisitor<void> {
  _Visitor(this.file, this.lineInfo, this.lines, this.ignored);

  final String file;
  final LineInfo lineInfo;
  final Set<int>? lines;
  final Set<int> ignored;
  final List<String> problems = <String>[];

  void _check(StringLiteral node) {
    final String text = _textOf(node);
    final CharacterLocation location = lineInfo.getLocation(node.offset);
    final int line = location.lineNumber;
    if (!RegExp(r'\p{L}', unicode: true).hasMatch(text)) {
      return;
    }
    if (lines != null && !lines!.contains(line)) {
      return;
    }
    final int holderLine = lineInfo
        .getLocation(_holderOf(node).offset)
        .lineNumber;
    // A comment above a long statement does not cover all of it.
    if (ignored.contains(line) ||
        (line - holderLine <= 3 && ignored.contains(holderLine))) {
      return;
    }
    final String? sink = _sinkOf(node);
    if (sink == null) {
      return;
    }
    // Text widgets show anything; elsewhere only prose-like values count.
    final bool loose =
        sink.endsWith('()') &&
        _textWidget.hasMatch(sink.substring(0, sink.length - 2));
    if (!loose && !_looksLikeProse(text)) {
      return;
    }
    if (_isExcluded(node)) {
      return;
    }
    final String shown = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    problems.add('$file:$line:${location.columnNumber}: $sink: "$shown"');
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) => _check(node);

  @override
  void visitStringInterpolation(StringInterpolation node) {
    _check(node);
    super.visitStringInterpolation(node);
  }

  @override
  void visitAdjacentStrings(AdjacentStrings node) => _check(node);
}

String _git(List<String> args) {
  final ProcessResult result = Process.runSync('git', args);
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    exit(2);
  }
  return result.stdout as String;
}

// Fork files under lib/ and the lines the fork changed in each; null means
// every line (an added or untracked file).
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
  ]).split('\n').where((f) => f.isNotEmpty).toSet();
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

/// The problems in one file's [source], on the given [lines] (null for every
/// line).
List<String> lintSource(String file, String source, Set<int>? lines) {
  if (_generatedHeader.hasMatch(
    source.substring(0, source.length.clamp(0, 500)),
  )) {
    return const <String>[];
  }
  final ParseStringResult result = parseString(
    content: source,
    path: file,
    throwIfDiagnostics: false,
  );
  final Set<int> ignored = <int>{};
  final List<String> sourceLines = source.split('\n');
  for (int i = 0; i < sourceLines.length; i++) {
    if (_ignore.hasMatch(sourceLines[i])) {
      ignored.addAll(<int>[i + 1, i + 2]);
    }
  }
  final _Visitor visitor = _Visitor(file, result.lineInfo, lines, ignored);
  result.unit.accept(visitor);
  return visitor.problems;
}

void main(List<String> args) {
  final bool all = args.contains('--all');
  final int upstreamIndex = args.indexOf('--upstream');
  final String upstream = upstreamIndex == -1
      ? 'upstream/canary'
      : args[upstreamIndex + 1];
  final List<String> given = <String>[
    for (int i = 0; i < args.length; i++)
      if (!args[i].startsWith('--') && (i == 0 || args[i - 1] != '--upstream'))
        args[i],
  ];
  final Map<String, Set<int>?> targets;
  if (all) {
    final Iterable<String> files = given.isNotEmpty
        ? given
        : _git(<String>['ls-files', '--', 'lib']).split('\n');
    targets = <String, Set<int>?>{
      for (final String f in files)
        if (f.isNotEmpty) f: null,
    };
  } else {
    final Map<String, Set<int>?> changes = _forkChanges(upstream);
    targets = given.isEmpty
        ? changes
        : <String, Set<int>?>{
            for (final String f in given)
              f: changes.containsKey(f) ? changes[f] : <int>{},
          };
  }
  final List<String> problems = <String>[];
  for (final String file in targets.keys.toList()..sort()) {
    if (!file.endsWith('.dart') ||
        _generated.hasMatch(file) ||
        !File(file).existsSync()) {
      continue;
    }
    problems.addAll(
      lintSource(file, File(file).readAsStringSync(), targets[file]),
    );
  }
  problems.forEach(print);
  if (problems.isNotEmpty) {
    stderr.writeln(
      '\n${problems.length} hard-coded user-facing string(s). Move each into '
      'l10n_fork (see l10n_fork/README.md), or mark it '
      '`// i18n-ignore: <reason>`.',
    );
    exit(1);
  }
}
