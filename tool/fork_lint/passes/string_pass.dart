// Fork: Stage 4 `string` pass consuming shared `DartFileIR` (`VarFlowAnalyzer`,
// `logOnlyPrivateNamedParams`, `bodyCallsPaint`, `enclosingSymbol`).
// Fork: CLI linter imports analyzer from transitive SDK deps.
// ignore_for_file: depend_on_referenced_packages

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

import '../../fork_lint_reviewed.dart';
import '../ir.dart';
import '../source_unit.dart';

const Set<String> kAllStringRules = <String>{'string-lint'};

final RegExp _uiName = RegExp(
  r'^(label|title|subtitle|text|message|tooltip|hint|description|placeholder|content|displayName|semanticLabel|semanticsLabel)$'
  r'|(Label|Title|Text|Message|Msg|Tooltip|Hint|Description|Placeholder|Caption|Heading)$',
);
final RegExp _notUiName = RegExp('^(debug|log|diagnostic|restoration)');
final RegExp _notUiCall = RegExp('^showDebug');

bool _isUiName(String name) =>
    _uiName.hasMatch(name) && !_notUiName.hasMatch(name);

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
        .map((InterpolationString e) => e.value)
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

bool _localVariableFlowsOnlyToNotShown(
  DartFileIR ir,
  VariableDeclaration decl,
) {
  final AstNode? stmt = decl.parent?.parent;
  final AstNode? block = stmt?.parent;
  if (stmt is! VariableDeclarationStatement || block is! Block) {
    return false;
  }
  return ir.varFlowFor(block).flowsOnlyToNotShown(decl.name.lexeme);
}

String? _sinkOf(
  DartFileIR ir,
  StringLiteral literal, {
  required Set<String> logOnlyPrivateNamedParams,
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
      final String callee = DartFileIR.calleeName(call);
      if (kNotShownSinkCall.hasMatch(callee)) {
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
    final String callee = DartFileIR.calleeName(call);
    final bool first =
        parent.arguments
            .where((Argument a) => a is! NamedArgument)
            .firstOrNull ==
        child;
    if (first && kTextSinkWidget.hasMatch(callee)) {
      return '$callee()';
    }
    if (kUiSinkCall.hasMatch(callee) && !_notUiCall.hasMatch(callee)) {
      return '$callee()';
    }
    return null;
  }
  if (parent is VariableDeclaration && parent.initializer == child) {
    if (!_isUiName(parent.name.lexeme)) {
      return null;
    }
    if (_localVariableFlowsOnlyToNotShown(ir, parent)) {
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

bool _isOffscreenTextPainterNode(DartFileIR ir, AstNode node) {
  if ((node is MethodInvocation || node is InstanceCreationExpression) &&
      DartFileIR.calleeName(node) == 'TextPainter') {
    final FunctionBody? body = node.thisOrAncestorOfType<FunctionBody>();
    return body != null && !ir.bodyCallsPaint(body);
  }
  return false;
}

bool _hasOffscreenTextPainterAncestor(DartFileIR ir, AstNode start) {
  for (AstNode? cur = start.parent; cur != null; cur = cur.parent) {
    if (_isOffscreenTextPainterNode(ir, cur)) {
      return true;
    }
    if (cur is FunctionBody) {
      return false;
    }
  }
  return false;
}

bool _isExcluded(DartFileIR ir, StringLiteral literal, String file) {
  if (file.endsWith('/fluxer_widget_preview.dart') ||
      file.contains('lib/features/ui/preview/')) {
    return true;
  }
  for (AstNode? node = literal.parent; node != null; node = node.parent) {
    if (node is Annotation || node is Directive || node is AssertStatement) {
      return true;
    }
    if ((node is FunctionDeclaration || node is MethodDeclaration) &&
        (node as AnnotatedNode).metadata.any(
          (Annotation a) => a.name.name.endsWith('Preview'),
        )) {
      return true;
    }
  }
  for (AstNode? node = literal.parent; node != null; node = node.parent) {
    if (node is MethodInvocation || node is InstanceCreationExpression) {
      final String callee = DartFileIR.calleeName(node);
      if (kNotShownSinkCall.hasMatch(callee)) {
        return true;
      }
      if (kNotShownSinkTarget.hasMatch(DartFileIR.targetRootName(node))) {
        return true;
      }
      if (_isOffscreenTextPainterNode(ir, node)) {
        return true;
      }
      if (kUiSinkCall.hasMatch(callee) || kTextSinkWidget.hasMatch(callee)) {
        return callee == 'TextSpan' &&
            _hasOffscreenTextPainterAncestor(ir, node);
      }
    }
  }
  return false;
}

class _StringVisitor extends RecursiveAstVisitor<void> {
  _StringVisitor({
    required this.ir,
    required this.reviewed,
    required this.logOnlyPrivateNamedParams,
  });

  final DartFileIR ir;
  final ReviewedLintCatalog? reviewed;
  final Set<String> logOnlyPrivateNamedParams;
  final List<String> problems = <String>[];

  void _check(StringLiteral node) {
    if (_isMultiplierInterpolation(node)) {
      return;
    }
    final DartSourceUnit unit = ir.sourceUnit;
    final String text = _textOf(node);
    final CharacterLocation location = unit.lineInfo!.getLocation(node.offset);
    final int line = location.lineNumber;
    if (!RegExp(r'\p{L}', unicode: true).hasMatch(text) ||
        !unit.isLineEnabled(line)) {
      return;
    }
    final int holderLine = unit.lineInfo!
        .getLocation(_holderOf(node).offset)
        .lineNumber;
    final Set<int> ignored = unit.directives.i18nIgnoredLines;
    if (ignored.contains(line) ||
        (line - holderLine <= 3 && ignored.contains(holderLine))) {
      return;
    }
    final String? sink = _sinkOf(
      ir,
      node,
      logOnlyPrivateNamedParams: logOnlyPrivateNamedParams,
    );
    if (sink == null) {
      return;
    }
    final bool loose =
        sink.endsWith('()') &&
        kTextSinkWidget.hasMatch(sink.substring(0, sink.length - 2));
    if (!loose && !_looksLikeProse(text)) {
      return;
    }
    if (_isExcluded(ir, node, unit.file)) {
      return;
    }
    if (reviewed != null) {
      if (reviewed!.matches(
        ReviewedLintCandidate(
          linter: 'string',
          rule: 'string-lint',
          file: unit.file,
          enclosing: ir.enclosingSymbol(node),
          target: sink,
          sourceLine: unit.sourceLineAt(line),
        ),
      )) {
        return;
      }
    }
    final String shown = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    problems.add(
      '${unit.file}:$line:${location.columnNumber}: $sink: "$shown"',
    );
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

/// Runs the Stage 4 `string` pass over a shared [DartFileIR].
List<String> runStringPass(DartFileIR ir, {ReviewedLintCatalog? reviewed}) {
  if (ir.sourceUnit.isGenerated || ir.sourceUnit.unit == null) {
    return const <String>[];
  }
  final _StringVisitor visitor = _StringVisitor(
    ir: ir,
    reviewed: reviewed,
    logOnlyPrivateNamedParams: ir.logOnlyPrivateNamedParams,
  );
  ir.sourceUnit.unit!.accept(visitor);
  return visitor.problems;
}
