// Fork: finds hard-coded user-facing strings in the fork's code, which
// `flutter test test/l10n_fork` cannot see because they never reach a fork
// catalogue (tyne-chat/tyne#184).
//
//   dart run tool/fork_string_lint.dart [--upstream <git ref>] [--all] [--include-reviewed] [--check-reviewed] [--reviewed <path>] [<file>...]
//
// Reports string literals in places users read them (`Text(...)`, user-facing
// named arguments such as `label:` or `errorMessage:`, toasts and error
// dialogs) in the fork's files under lib/. Excludes logger targets (`talker`,
// `logger`), Flutter diagnostic types (`FlutterErrorDetails`, `ErrorDescription`,
// etc.), widget preview files/annotations, offscreen `TextPainter` metrics,
// numeric multiplier suffixes (`'${rate}x'`), local variables whose only reads
// feed excluded sinks, and same-file private helper parameters whose values
// flow solely to excluded sinks. Only files the fork added and lines it
// changed against the merge base with <git ref> (default upstream/canary) are
// checked, working tree and untracked files included; --all checks every line
// of the files given (or of every file under lib/). A literal that really is
// not to be translated gets `// i18n-ignore: <reason>` on its line or the line
// above (or above the statement, declaration or argument it is part of) on fork
// lines; reviewed upstream `--all` findings live in `tool/fork_lint_reviewed.json`
// (`--check-reviewed` validates they still match, `--include-reviewed` lists
// them too) so upstream files stay untouched.
// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

import 'fork_lint_reviewed.dart';

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
  r'|\w*Exception|\w*Error|Uri|RegExp|DateFormat|NumberFormat'
  r'|FlutterErrorDetails|ErrorDescription|ErrorSummary|ErrorHint|Diagnostics\w*)$',
);
final RegExp _notShownTarget = RegExp(
  r'^(_?log(ger)?|_?logger|Logger|developer|AppLogger|_?talker|Talker)$',
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

bool _isMultiplierInterpolation(StringLiteral node) {
  if (node is! StringInterpolation || node.elements.length != 3) {
    return false;
  }
  final InterpolationElement e0 = node.elements[0];
  final InterpolationElement e1 = node.elements[1];
  final InterpolationElement e2 = node.elements[2];
  return e0 is InterpolationString &&
      !RegExp(r'\p{L}', unicode: true).hasMatch(e0.value) &&
      e1 is InterpolationExpression &&
      e2 is InterpolationString &&
      e2.value == 'x';
}

bool _isInsideNotShownSink(AstNode start) {
  for (AstNode? node = start.parent; node != null; node = node.parent) {
    if (node is MethodInvocation || node is InstanceCreationExpression) {
      if (_notShownCall.hasMatch(_calleeName(node))) {
        return true;
      }
      if (_notShownTarget.hasMatch(_targetName(node))) {
        return true;
      }
      if (_uiCall.hasMatch(_calleeName(node)) ||
          _textWidget.hasMatch(_calleeName(node))) {
        return false;
      }
    }
  }
  return false;
}

class _PaintMethodFinder extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'paint') {
      found = true;
      return;
    }
    super.visitMethodInvocation(node);
  }
}

bool _bodyCallsPaint(FunctionBody body) {
  final _PaintMethodFinder finder = _PaintMethodFinder();
  body.accept(finder);
  return finder.found;
}

bool _isSimpleValueRead(SimpleIdentifier node) {
  if (node.inDeclarationContext()) {
    return false;
  }
  final AstNode? parent = node.parent;
  if (parent is Label) {
    return false;
  }
  if (parent is PropertyAccess && identical(parent.propertyName, node)) {
    return parent.target is ThisExpression;
  }
  if (parent is PrefixedIdentifier && identical(parent.identifier, node)) {
    return parent.prefix.name == 'this';
  }
  if (parent is MethodInvocation &&
      identical(parent.methodName, node) &&
      parent.target != null &&
      parent.target is! ThisExpression) {
    return false;
  }
  return true;
}

bool _expressionCarriesReadSafely(
  SimpleIdentifier read,
  Expression initializer,
) {
  if (identical(read, initializer)) {
    return true;
  }
  AstNode child = read;
  for (AstNode? cur = read.parent; cur != null; cur = cur.parent) {
    final bool allowedWrapper =
        cur is StringInterpolation ||
        cur is InterpolationExpression ||
        cur is AdjacentStrings ||
        cur is ParenthesizedExpression ||
        cur is AsExpression ||
        (cur is PostfixExpression && cur.operator.lexeme == '!') ||
        (cur is BinaryExpression &&
            (cur.operator.lexeme == '??' || cur.operator.lexeme == '+')) ||
        (cur is ConditionalExpression && !identical(cur.condition, child));
    if (!allowedWrapper && !identical(cur, initializer)) {
      return false;
    }
    if (identical(cur, initializer)) {
      return cur is SimpleIdentifier || allowedWrapper;
    }
    child = cur;
  }
  return false;
}

class _ScopeVariableCollector extends RecursiveAstVisitor<void> {
  final Set<String> mutatedOrShadowed = <String>{};
  final Map<String, VariableDeclaration> localInits =
      <String, VariableDeclaration>{};
  final Map<String, List<SimpleIdentifier>> readsByVar =
      <String, List<SimpleIdentifier>>{};

  void _markShadow(String name) => mutatedOrShadowed.add(name);

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final String name = node.name.lexeme;
    if (localInits.containsKey(name)) {
      mutatedOrShadowed.add(name);
    } else if (node.initializer != null) {
      localInits[name] = node;
    }
    super.visitVariableDeclaration(node);
  }

  @override
  void visitRegularFormalParameter(RegularFormalParameter node) {
    final String? name = node.name?.lexeme;
    if (name != null) {
      _markShadow(name);
    }
    super.visitRegularFormalParameter(node);
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    _markShadow(node.name.lexeme);
    super.visitSuperFormalParameter(node);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _markShadow(node.name.lexeme);
    super.visitFieldFormalParameter(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (node.leftHandSide is SimpleIdentifier) {
      mutatedOrShadowed.add((node.leftHandSide as SimpleIdentifier).name);
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if ((node.operator.lexeme == '++' || node.operator.lexeme == '--') &&
        node.operand is SimpleIdentifier) {
      mutatedOrShadowed.add((node.operand as SimpleIdentifier).name);
    }
    super.visitPrefixExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if ((node.operator.lexeme == '++' || node.operator.lexeme == '--') &&
        node.operand is SimpleIdentifier) {
      mutatedOrShadowed.add((node.operand as SimpleIdentifier).name);
    }
    super.visitPostfixExpression(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (_isSimpleValueRead(node)) {
      readsByVar.putIfAbsent(node.name, () => <SimpleIdentifier>[]).add(node);
    }
    super.visitSimpleIdentifier(node);
  }
}

class _VarFlowAnalyzer {
  _VarFlowAnalyzer(AstNode scopeNode) {
    scopeNode.accept(_collector);
  }

  final _ScopeVariableCollector _collector = _ScopeVariableCollector();

  bool flowsOnlyToNotShown(String varName, {Set<String>? visiting}) {
    final Set<String> seen = visiting ?? <String>{};
    if (!seen.add(varName)) {
      return false;
    }
    if (_collector.mutatedOrShadowed.contains(varName)) {
      return false;
    }
    final List<SimpleIdentifier>? reads = _collector.readsByVar[varName];
    if (reads == null || reads.isEmpty) {
      return false;
    }
    for (final SimpleIdentifier read in reads) {
      if (_isInsideNotShownSink(read)) {
        continue;
      }
      final VariableDeclaration? initDecl = read
          .thisOrAncestorOfType<VariableDeclaration>();
      if (initDecl != null &&
          initDecl.initializer != null &&
          identical(_collector.localInits[initDecl.name.lexeme], initDecl) &&
          _expressionCarriesReadSafely(read, initDecl.initializer!) &&
          flowsOnlyToNotShown(
            initDecl.name.lexeme,
            visiting: Set<String>.of(seen),
          )) {
        continue;
      }
      return false;
    }
    return true;
  }
}

bool _localVariableFlowsOnlyToNotShown(VariableDeclaration decl) {
  final AstNode? stmt = decl.parent?.parent;
  final AstNode? block = stmt?.parent;
  if (stmt is! VariableDeclarationStatement || block is! Block) {
    return false;
  }
  final _VarFlowAnalyzer analyzer = _VarFlowAnalyzer(block);
  return analyzer.flowsOnlyToNotShown(decl.name.lexeme);
}

Set<String> _collectLogOnlyPrivateNamedParams(CompilationUnit unit) {
  final Set<String> allowed = <String>{};
  final Set<String> rejected = <String>{};

  void inspectCallable(
    String name,
    FormalParameterList? params,
    FunctionBody body,
  ) {
    if (!name.startsWith('_') || params == null) {
      return;
    }
    final List<String> namedParams = <String>[
      for (final FormalParameter p in params.parameters)
        if (p.isNamed && p.name != null) p.name!.lexeme,
    ];
    if (namedParams.isEmpty) {
      return;
    }
    // Check direct body mutations/inner-closure shadows separately from top-level
    // parameter declarations.
    final _ScopeVariableCollector bodyCollector = _ScopeVariableCollector();
    body.accept(bodyCollector);
    final _VarFlowAnalyzer analyzer = _VarFlowAnalyzer(body);
    for (final String param in namedParams) {
      final String key = '$name:$param';
      if (!bodyCollector.mutatedOrShadowed.contains(param) &&
          analyzer.flowsOnlyToNotShown(param)) {
        allowed.add(key);
      } else {
        rejected.add(key);
      }
    }
  }

  unit.accept(_PrivateCallableCollector(onCallable: inspectCallable));
  return allowed.difference(rejected);
}

class _PrivateCallableCollector extends RecursiveAstVisitor<void> {
  _PrivateCallableCollector({required this.onCallable});

  final void Function(
    String name,
    FormalParameterList? params,
    FunctionBody body,
  )
  onCallable;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    onCallable(node.name.lexeme, node.parameters, node.body);
    super.visitMethodDeclaration(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    onCallable(
      node.name.lexeme,
      node.functionExpression.parameters,
      node.functionExpression.body,
    );
    super.visitFunctionDeclaration(node);
  }
}

// Where a literal ends up: a description of the place users read it, or null.
String? _sinkOf(
  StringLiteral literal, {
  Set<String> logOnlyPrivateNamedParams = const <String>{},
}) {
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
    if (call != null) {
      final String callee = _calleeName(call);
      if (_notShownCall.hasMatch(callee)) {
        return null;
      }
      final bool selfOrBareCall =
          call is MethodInvocation &&
          (call.target == null || call.target is ThisExpression);
      if (selfOrBareCall &&
          logOnlyPrivateNamedParams.contains('$callee:$name')) {
        return null;
      }
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
    if (!_isUiName(parent.name.lexeme)) {
      return null;
    }
    if (_localVariableFlowsOnlyToNotShown(parent)) {
      return null;
    }
    return 'variable ${parent.name.lexeme}';
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

bool _isOffscreenTextPainterNode(AstNode node) {
  if ((node is MethodInvocation || node is InstanceCreationExpression) &&
      _calleeName(node) == 'TextPainter') {
    final FunctionBody? body = node.thisOrAncestorOfType<FunctionBody>();
    return body != null && !_bodyCallsPaint(body);
  }
  return false;
}

bool _hasOffscreenTextPainterAncestor(AstNode start) {
  for (AstNode? cur = start.parent; cur != null; cur = cur.parent) {
    if (_isOffscreenTextPainterNode(cur)) {
      return true;
    }
    if (cur is FunctionBody) {
      return false;
    }
  }
  return false;
}

// Whether a literal sits somewhere nobody reads it.
bool _isExcluded(StringLiteral literal, String file) {
  if (file.endsWith('/fluxer_widget_preview.dart') ||
      file.contains('lib/features/ui/preview/')) {
    return true;
  }
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
      final String callee = _calleeName(node);
      if (_notShownCall.hasMatch(callee)) {
        return true;
      }
      if (_notShownTarget.hasMatch(_targetName(node))) {
        return true;
      }
      if (_isOffscreenTextPainterNode(node)) {
        return true;
      }
      // A call that shows its argument decides; one further out does not
      // (unless this `TextSpan` feeds an enclosing offscreen `TextPainter`).
      if (_uiCall.hasMatch(callee) || _textWidget.hasMatch(callee)) {
        return callee == 'TextSpan' && _hasOffscreenTextPainterAncestor(node);
      }
    }
  }
  return false;
}

class _Visitor extends RecursiveAstVisitor<void> {
  _Visitor(
    this.file,
    this.lineInfo,
    this.sourceLines,
    this.lines,
    this.ignored,
    this.reviewed,
    this.logOnlyPrivateNamedParams,
  );

  final String file;
  final LineInfo lineInfo;
  final List<String> sourceLines;
  final Set<int>? lines;
  final Set<int> ignored;
  final ReviewedLintCatalog? reviewed;
  final Set<String> logOnlyPrivateNamedParams;
  final List<String> problems = <String>[];

  void _check(StringLiteral node) {
    if (_isMultiplierInterpolation(node)) {
      return;
    }
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
    final String? sink = _sinkOf(
      node,
      logOnlyPrivateNamedParams: logOnlyPrivateNamedParams,
    );
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
    if (_isExcluded(node, file)) {
      return;
    }
    if (reviewed != null) {
      final String sourceLine = (line >= 1 && line <= sourceLines.length)
          ? sourceLines[line - 1]
          : '';
      if (reviewed!.matches(
        ReviewedLintCandidate(
          linter: 'string',
          rule: 'string-lint',
          file: file,
          enclosing: enclosingAstSymbol(node),
          target: sink,
          sourceLine: sourceLine,
        ),
      )) {
        return;
      }
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
/// line), excluding entries matched by [reviewed] when supplied.
List<String> lintSource(
  String file,
  String source,
  Set<int>? lines, {
  ReviewedLintCatalog? reviewed,
}) {
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
  final Set<String> logOnlyPrivateNamedParams =
      _collectLogOnlyPrivateNamedParams(result.unit);
  final _Visitor visitor = _Visitor(
    file,
    result.lineInfo,
    sourceLines,
    lines,
    ignored,
    reviewed,
    logOnlyPrivateNamedParams,
  );
  result.unit.accept(visitor);
  return visitor.problems;
}

void main(List<String> args) {
  final ReviewedCliArgs reviewedArgs = extractReviewedCliArgs(args);
  final List<String> effectiveArgs = reviewedArgs.restArgs;
  final bool all =
      effectiveArgs.contains('--all') || reviewedArgs.checkReviewed;
  final int upstreamIndex = effectiveArgs.indexOf('--upstream');
  final String upstream = upstreamIndex == -1
      ? 'upstream/canary'
      : effectiveArgs[upstreamIndex + 1];
  final List<String> given = <String>[
    for (int i = 0; i < effectiveArgs.length; i++)
      if (!effectiveArgs[i].startsWith('--') &&
          (i == 0 || effectiveArgs[i - 1] != '--upstream'))
        effectiveArgs[i],
  ];
  final ReviewedLintCatalog? catalog = loadReviewedCatalogOrExit(
    reviewedArgs.reviewedPath,
    includeReviewed: reviewedArgs.includeReviewed,
    checkReviewed: reviewedArgs.checkReviewed,
  );
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
      lintSource(
        file,
        File(file).readAsStringSync(),
        targets[file],
        reviewed: catalog,
      ),
    );
  }
  finishReviewedCheckOrNotes(
    linter: 'string',
    catalog: catalog,
    checkReviewed: reviewedArgs.checkReviewed,
    reportAllSummary: all,
    allFilesScanned: given.isEmpty,
  );
  problems.forEach(print);
  if (problems.isNotEmpty) {
    stderr.writeln(
      '\n${problems.length} hard-coded user-facing string(s). Move each into '
      'l10n_fork (see l10n_fork/README.md), mark fork lines with '
      '`// i18n-ignore: <reason>`, or record reviewed upstream entries in '
      '`$kDefaultReviewedLintPath`.',
    );
    exit(1);
  }
}
