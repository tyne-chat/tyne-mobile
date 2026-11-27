// Fork: Stage 4 `safety` pass consuming shared `DartFileIR` (`ClassIR`,
// `GuardSemantics`, `enclosingSymbol`, `DirectiveTable`).
// Fork: CLI linter imports analyzer from transitive SDK deps.
// ignore_for_file: depend_on_referenced_packages

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

import '../../fork_lint_reviewed.dart';
import '../ir.dart';
import '../source_unit.dart';

const Set<String> kAllSafetyRules = <String>{
  'dispose-ref',
  'unmounted-listener',
  'chat-layout',
  'build-network',
  'keepalive-reset',
};

final RegExp _chatPath = RegExp('(^|/)lib/features/chat/');
final RegExp _chatPanelOrListPath = RegExp(
  '(^|/)lib/features/chat/presentation/(pages/|widgets/(channel|messages)/)',
);
final RegExp _httpMethod = RegExp(
  r'^(get|post|put|patch|delete|head|fetch|request|getUri|postUri|putUri|patchUri|deleteUri)$',
);
final RegExp _repoNetworkVerb = RegExp(
  r'^(fetch|get|load|list|search|query|create|update|edit|delete|remove|send|add|put|patch|post|sync|ensure|resolve)\w*$',
);

Set<String> _collectAssignedOrResetFields(
  FunctionBody body,
  Map<String, MethodDeclaration> methodsByName, [
  Set<String>? visitedHelpers,
]) {
  final Set<String> touched = <String>{};
  final Set<String> seen = visitedHelpers ?? <String>{};
  body.accept(
    _FieldResetCollector(
      onFieldTouched: touched.add,
      onHelperCalled: (String helper) {
        if (seen.add(helper)) {
          final MethodDeclaration? m = methodsByName[helper];
          if (m != null) {
            touched.addAll(
              _collectAssignedOrResetFields(m.body, methodsByName, seen),
            );
          }
        }
      },
    ),
  );
  return touched;
}

class _FieldResetCollector extends RecursiveAstVisitor<void> {
  _FieldResetCollector({
    required this.onFieldTouched,
    required this.onHelperCalled,
  });

  final void Function(String field) onFieldTouched;
  final void Function(String helper) onHelperCalled;

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  void _touchTarget(Expression? expr) {
    final String? name = DartFileIR.fieldTargetName(expr);
    if (name != null) {
      onFieldTouched(name);
    }
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _touchTarget(node.leftHandSide);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    final String op = node.operator.lexeme;
    if (op == '++' || op == '--') {
      _touchTarget(node.operand);
    }
    super.visitPrefixExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    final String op = node.operator.lexeme;
    if (op == '++' || op == '--') {
      _touchTarget(node.operand);
    }
    super.visitPostfixExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final String method = node.methodName.name;
    final Expression? target = node.target;
    if (method == 'clear' || method == 'reset' || method == 'cancel') {
      _touchTarget(target);
    }
    if (target == null || target is ThisExpression) {
      onHelperCalled(method);
    }
    super.visitMethodInvocation(node);
  }
}

void _collectOnDisposeInvocationResets(
  MethodInvocation call,
  Map<String, MethodDeclaration> methodsByName,
  Set<String> out,
) {
  if (call.methodName.name != 'onDispose' ||
      call.argumentList.arguments.isEmpty) {
    return;
  }
  final Argument arg = call.argumentList.arguments.first;
  if (arg is FunctionExpression) {
    out.addAll(_collectAssignedOrResetFields(arg.body, methodsByName));
    return;
  }
  if (arg is Expression) {
    final String? methodName = DartFileIR.fieldTargetName(arg.unParenthesized);
    final MethodDeclaration? helper = methodName == null
        ? null
        : methodsByName[methodName];
    if (helper != null) {
      out.addAll(_collectAssignedOrResetFields(helper.body, methodsByName));
    }
  }
}

Set<String> _collectUnconditionalOnDisposeResets(
  DartFileIR ir,
  FunctionBody buildBody,
  Map<String, MethodDeclaration> methodsByName,
) {
  final Set<String> reset = <String>{};
  if (buildBody is! BlockFunctionBody) {
    return reset;
  }
  for (final Statement stmt in buildBody.block.statements) {
    if (ir.containsSyncControlExitOrAwait(stmt)) {
      break;
    }
    if (stmt is! ExpressionStatement) {
      continue;
    }
    final Expression expr = stmt.expression.unParenthesized;
    if (expr is MethodInvocation && expr.target?.toSource() == 'ref') {
      _collectOnDisposeInvocationResets(expr, methodsByName, reset);
    } else if (expr is CascadeExpression && expr.target.toSource() == 'ref') {
      for (final Expression section in expr.cascadeSections) {
        if (section is MethodInvocation) {
          _collectOnDisposeInvocationResets(section, methodsByName, reset);
        }
      }
    }
  }
  return reset;
}

bool _isFalseLiteral(Expression expr) {
  final Expression unwrapped = expr.unParenthesized;
  return unwrapped is BooleanLiteral && !unwrapped.value;
}

bool _isTrueLiteral(Expression expr) {
  final Expression unwrapped = expr.unParenthesized;
  return unwrapped is BooleanLiteral && unwrapped.value;
}

bool _isNullLiteral(Expression expr) => expr.unParenthesized is NullLiteral;

bool _isResetAssignmentForKind(
  AssignmentExpression node,
  String fieldName, {
  required bool isBool,
}) {
  if (DartFileIR.fieldTargetName(node.leftHandSide) != fieldName ||
      node.operator.lexeme != '=') {
    return false;
  }
  return isBool
      ? _isFalseLiteral(node.rightHandSide)
      : _isNullLiteral(node.rightHandSide);
}

bool _isNullableFutureType(String? typeSrc) =>
    typeSrc != null &&
    (typeSrc == 'Future?' ||
        (typeSrc.startsWith('Future<') && typeSrc.endsWith('?')));

bool _isNonNullFutureType(String? typeSrc) =>
    typeSrc != null &&
    (typeSrc == 'Future' ||
        (typeSrc.startsWith('Future<') && !typeSrc.endsWith('?')));

bool _isFutureValueInitializer(Expression? init) {
  if (init == null) {
    return false;
  }
  final Expression unwrapped = init.unParenthesized;
  if (unwrapped is MethodInvocation && unwrapped.methodName.name == 'value') {
    final String? targetSrc = unwrapped.target?.toSource();
    return targetSrc != null &&
        (targetSrc == 'Future' || targetSrc.startsWith('Future<'));
  }
  if (unwrapped is InstanceCreationExpression) {
    final String nameSrc = unwrapped.constructorName.toSource();
    return nameSrc == 'Future.value' || nameSrc.startsWith('Future<');
  }
  return false;
}

bool _isPureMonotonicIntCounter(
  VariableDeclaration field,
  String? typeSrc,
  ClassFieldUsage? usage,
) {
  if (typeSrc != 'int' || field.initializer is! IntegerLiteral) {
    return false;
  }
  return usage != null &&
      usage.increments >= 1 &&
      usage.decrements == 0 &&
      usage.assignments.isEmpty &&
      usage.methodResets == 0;
}

bool _isIdentityComparisonWithField(
  Expression cond,
  String fieldName,
  String localVarName,
) {
  final Expression unwrapped = cond.unParenthesized;
  if (unwrapped is MethodInvocation &&
      unwrapped.target == null &&
      unwrapped.methodName.name == 'identical' &&
      unwrapped.argumentList.arguments.length == 2) {
    final Argument a0 = unwrapped.argumentList.arguments[0];
    final Argument a1 = unwrapped.argumentList.arguments[1];
    if (a0 is Expression && a1 is Expression) {
      final String? n0 = DartFileIR.fieldTargetName(a0.unParenthesized);
      final String? n1 = DartFileIR.fieldTargetName(a1.unParenthesized);
      if ((n0 == fieldName && n1 == localVarName) ||
          (n1 == fieldName && n0 == localVarName)) {
        return true;
      }
    }
  }
  if (unwrapped is BinaryExpression && unwrapped.operator.lexeme == '==') {
    final String? l = DartFileIR.fieldTargetName(
      unwrapped.leftOperand.unParenthesized,
    );
    final String? r = DartFileIR.fieldTargetName(
      unwrapped.rightOperand.unParenthesized,
    );
    return (l == fieldName && r == localVarName) ||
        (r == fieldName && l == localVarName);
  }
  return false;
}

bool _blockUnconditionallyResetsField(
  DartFileIR ir,
  Block block,
  String fieldName, {
  required bool isBool,
  String? matchLocalVar,
}) {
  for (final Statement stmt in block.statements) {
    if (stmt is ExpressionStatement) {
      final Expression expr = stmt.expression.unParenthesized;
      if (expr is AssignmentExpression &&
          _isResetAssignmentForKind(expr, fieldName, isBool: isBool)) {
        return true;
      }
    }
    if (stmt is IfStatement &&
        !isBool &&
        matchLocalVar != null &&
        stmt.elseStatement == null &&
        _isIdentityComparisonWithField(
          stmt.expression,
          fieldName,
          matchLocalVar,
        )) {
      final Statement thenStmt = stmt.thenStatement;
      if (thenStmt is Block &&
          _blockUnconditionallyResetsField(
            ir,
            thenStmt,
            fieldName,
            isBool: false,
            matchLocalVar: matchLocalVar,
          )) {
        return true;
      }
      if (thenStmt is ExpressionStatement &&
          thenStmt.expression.unParenthesized is AssignmentExpression &&
          _isResetAssignmentForKind(
            thenStmt.expression.unParenthesized as AssignmentExpression,
            fieldName,
            isBool: false,
          )) {
        return true;
      }
    }
    if (stmt is TryStatement &&
        stmt.finallyBlock != null &&
        _blockUnconditionallyResetsField(
          ir,
          stmt.finallyBlock!,
          fieldName,
          isBool: isBool,
          matchLocalVar: matchLocalVar,
        )) {
      return true;
    }
    if (ir.containsSyncControlExitOrAwait(stmt)) {
      return false;
    }
  }
  return false;
}

bool _isProtectedByFinallyReset(
  DartFileIR ir,
  AssignmentExpression assignment,
  String fieldName, {
  required bool isBool,
}) {
  AstNode? cur = assignment.parent;
  AstNode child = assignment;
  while (cur != null && cur is! FunctionBody && cur is! ClassDeclaration) {
    if (cur is TryStatement &&
        identical(cur.body, child) &&
        cur.finallyBlock != null &&
        _blockUnconditionallyResetsField(
          ir,
          cur.finallyBlock!,
          fieldName,
          isBool: isBool,
        )) {
      return true;
    }
    child = cur;
    cur = cur.parent;
  }

  final AstNode? stmt = assignment.parent;
  final AstNode? block = stmt?.parent;
  if (stmt is! ExpressionStatement || block is! Block) {
    return false;
  }
  final int index = block.statements.indexOf(stmt);
  if (index == -1) {
    return false;
  }
  for (int i = index + 1; i < block.statements.length; i++) {
    final Statement nextStmt = block.statements[i];
    if (nextStmt is TryStatement &&
        nextStmt.finallyBlock != null &&
        _blockUnconditionallyResetsField(
          ir,
          nextStmt.finallyBlock!,
          fieldName,
          isBool: isBool,
        )) {
      return true;
    }
    if (ir.containsSyncControlExitOrAwait(nextStmt)) {
      return false;
    }
  }
  return false;
}

bool _isTryFinallyScopedMutex(
  DartFileIR ir,
  VariableDeclaration field,
  String fieldName,
  String? typeSrc,
  ClassFieldUsage? usage,
) {
  final bool isBool =
      typeSrc == 'bool' &&
      field.initializer != null &&
      _isFalseLiteral(field.initializer!);
  final bool isFuture =
      _isNullableFutureType(typeSrc) &&
      (field.initializer == null || _isNullLiteral(field.initializer!));
  if (!isBool && !isFuture) {
    return false;
  }
  if (usage == null ||
      usage.increments > 0 ||
      usage.decrements > 0 ||
      usage.methodResets > 0 ||
      usage.assignments.isEmpty) {
    return false;
  }
  int nonResetWrites = 0;
  for (final AssignmentExpression a in usage.assignments) {
    if (a.operator.lexeme != '=') {
      return false;
    }
    final bool isReset = isBool
        ? _isFalseLiteral(a.rightHandSide)
        : _isNullLiteral(a.rightHandSide);
    if (isReset) {
      continue;
    }
    nonResetWrites++;
    if (!_isProtectedByFinallyReset(ir, a, fieldName, isBool: isBool)) {
      return false;
    }
  }
  return nonResetWrites >= 1;
}

class _LocalVarInitCollector extends RecursiveAstVisitor<void> {
  final Map<String, Expression> initializers = <String, Expression>{};

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.initializer != null) {
      initializers[node.name.lexeme] = node.initializer!;
    }
    super.visitVariableDeclaration(node);
  }
}

Map<String, Expression> _collectBodyLocalInitializers(
  AssignmentExpression node,
) {
  final FunctionBody? body = node.thisOrAncestorOfType<FunctionBody>();
  if (body == null) {
    return const <String, Expression>{};
  }
  final _LocalVarInitCollector collector = _LocalVarInitCollector();
  body.visitChildren(collector);
  return collector.initializers;
}

bool _expressionChainsFromField(
  Expression expr,
  String fieldName,
  Map<String, Expression> localInits,
  Set<String> visitedLocals, {
  required bool sawCombinator,
}) {
  final Expression unwrapped = expr.unParenthesized;
  if (unwrapped is MethodInvocation) {
    final String name = unwrapped.methodName.name;
    final Expression? target = unwrapped.target;
    if (target != null &&
        (name == 'then' || name == 'catchError' || name == 'whenComplete')) {
      return _expressionChainsFromField(
        target,
        fieldName,
        localInits,
        visitedLocals,
        sawCombinator: true,
      );
    }
    return false;
  }
  final String? targetName = DartFileIR.fieldTargetName(unwrapped);
  if (targetName == fieldName && sawCombinator) {
    return true;
  }
  if (unwrapped is SimpleIdentifier &&
      localInits.containsKey(unwrapped.name) &&
      visitedLocals.add(unwrapped.name)) {
    return _expressionChainsFromField(
      localInits[unwrapped.name]!,
      fieldName,
      localInits,
      visitedLocals,
      sawCombinator: sawCombinator,
    );
  }
  return false;
}

bool _isSequentialFutureQueue(
  VariableDeclaration field,
  String fieldName,
  String? typeSrc,
  ClassFieldUsage? usage,
) {
  if (!_isNonNullFutureType(typeSrc) ||
      !_isFutureValueInitializer(field.initializer)) {
    return false;
  }
  if (usage == null ||
      usage.increments > 0 ||
      usage.decrements > 0 ||
      usage.methodResets > 0 ||
      usage.assignments.isEmpty) {
    return false;
  }
  for (final AssignmentExpression a in usage.assignments) {
    if (a.operator.lexeme != '=') {
      return false;
    }
    final Map<String, Expression> localInits = _collectBodyLocalInitializers(a);
    if (!_expressionChainsFromField(
      a.rightHandSide,
      fieldName,
      localInits,
      <String>{},
      sawCombinator: false,
    )) {
      return false;
    }
  }
  return true;
}

class _WhenCompleteCallFinder extends RecursiveAstVisitor<void> {
  _WhenCompleteCallFinder({this.requiredTargetName});

  final String? requiredTargetName;
  final List<MethodInvocation> matches = <MethodInvocation>[];

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'whenComplete' &&
        node.argumentList.arguments.isNotEmpty &&
        node.argumentList.arguments.first is FunctionExpression) {
      if (requiredTargetName == null ||
          DartFileIR.fieldTargetName(node.target?.unParenthesized) ==
              requiredTargetName) {
        matches.add(node);
      }
    }
    super.visitMethodInvocation(node);
  }
}

bool _whenCompleteClosureResetsField(
  DartFileIR ir,
  FunctionExpression callback,
  String fieldName, {
  required bool isBool,
  String? matchLocalVar,
}) {
  final FunctionBody body = callback.body;
  if (body is BlockFunctionBody) {
    return _blockUnconditionallyResetsField(
      ir,
      body.block,
      fieldName,
      isBool: isBool,
      matchLocalVar: matchLocalVar,
    );
  }
  if (body is ExpressionFunctionBody) {
    final Expression expr = body.expression.unParenthesized;
    return expr is AssignmentExpression &&
        _isResetAssignmentForKind(expr, fieldName, isBool: isBool);
  }
  return false;
}

bool _isWhenCompleteWorkerBool(
  DartFileIR ir,
  VariableDeclaration field,
  String fieldName,
  String? typeSrc,
  ClassFieldUsage? usage,
) {
  if (typeSrc != 'bool' ||
      field.initializer == null ||
      !_isFalseLiteral(field.initializer!)) {
    return false;
  }
  if (usage == null ||
      usage.increments > 0 ||
      usage.decrements > 0 ||
      usage.methodResets > 0 ||
      usage.assignments.isEmpty) {
    return false;
  }
  int nonResetWrites = 0;
  for (final AssignmentExpression a in usage.assignments) {
    if (a.operator.lexeme != '=') {
      return false;
    }
    if (_isFalseLiteral(a.rightHandSide)) {
      continue;
    }
    if (!_isTrueLiteral(a.rightHandSide)) {
      return false;
    }
    nonResetWrites++;
    final AstNode? stmt = a.parent;
    final AstNode? block = stmt?.parent;
    if (stmt is! ExpressionStatement || block is! Block) {
      return false;
    }
    final int idx = block.statements.indexOf(stmt);
    if (idx == -1) {
      return false;
    }
    bool found = false;
    for (int i = idx + 1; i < block.statements.length; i++) {
      final Statement nextStmt = block.statements[i];
      final _WhenCompleteCallFinder finder = _WhenCompleteCallFinder();
      nextStmt.accept(finder);
      for (final MethodInvocation call in finder.matches) {
        final FunctionExpression cb =
            call.argumentList.arguments.first as FunctionExpression;
        if (_whenCompleteClosureResetsField(ir, cb, fieldName, isBool: true)) {
          found = true;
          break;
        }
      }
      if (found) {
        break;
      }
      if (ir.containsSyncControlExitOrAwait(nextStmt)) {
        return false;
      }
    }
    if (!found) {
      return false;
    }
  }
  return nonResetWrites >= 1;
}

bool _isWhenCompleteWorkerField(
  DartFileIR ir,
  VariableDeclaration field,
  String fieldName,
  String? typeSrc,
  ClassFieldUsage? usage,
  Set<String> verifiedBoolWorkers,
) {
  if (_isWhenCompleteWorkerBool(ir, field, fieldName, typeSrc, usage)) {
    return true;
  }
  if (usage == null ||
      usage.increments > 0 ||
      usage.decrements > 0 ||
      usage.methodResets > 0 ||
      usage.assignments.isEmpty) {
    return false;
  }

  final bool isNullableFuture =
      _isNullableFutureType(typeSrc) &&
      (field.initializer == null || _isNullLiteral(field.initializer!));
  if (isNullableFuture) {
    int nonResetWrites = 0;
    for (final AssignmentExpression a in usage.assignments) {
      if (a.operator.lexeme != '=') {
        return false;
      }
      if (_isNullLiteral(a.rightHandSide)) {
        continue;
      }
      nonResetWrites++;
      final Expression rhs = a.rightHandSide.unParenthesized;
      if (rhs is MethodInvocation &&
          rhs.methodName.name == 'whenComplete' &&
          rhs.argumentList.arguments.isNotEmpty &&
          rhs.argumentList.arguments.first is FunctionExpression) {
        final FunctionExpression cb =
            rhs.argumentList.arguments.first as FunctionExpression;
        if (_whenCompleteClosureResetsField(ir, cb, fieldName, isBool: false)) {
          continue;
        }
      }
      if (rhs is SimpleIdentifier &&
          a.parent is ExpressionStatement &&
          a.parent!.parent is Block) {
        final Block block = a.parent!.parent! as Block;
        final int idx = block.statements.indexOf(a.parent! as Statement);
        if (idx != -1) {
          bool found = false;
          for (int i = idx + 1; i < block.statements.length; i++) {
            final Statement nextStmt = block.statements[i];
            final _WhenCompleteCallFinder finder = _WhenCompleteCallFinder(
              requiredTargetName: rhs.name,
            );
            nextStmt.accept(finder);
            for (final MethodInvocation call in finder.matches) {
              final FunctionExpression cb =
                  call.argumentList.arguments.first as FunctionExpression;
              if (_whenCompleteClosureResetsField(
                ir,
                cb,
                fieldName,
                isBool: false,
                matchLocalVar: rhs.name,
              )) {
                found = true;
                break;
              }
            }
            if (found) {
              break;
            }
            if (ir.containsSyncControlExitOrAwait(nextStmt)) {
              return false;
            }
          }
          if (found) {
            continue;
          }
        }
      }
      return false;
    }
    return nonResetWrites >= 1;
  }

  final bool isNonNullFuture =
      _isNonNullFutureType(typeSrc) &&
      _isFutureValueInitializer(field.initializer);
  if (isNonNullFuture && verifiedBoolWorkers.isNotEmpty) {
    for (final AssignmentExpression a in usage.assignments) {
      if (a.operator.lexeme != '=') {
        return false;
      }
      final Expression rhs = a.rightHandSide.unParenthesized;
      if (rhs is! MethodInvocation ||
          rhs.methodName.name != 'whenComplete' ||
          rhs.argumentList.arguments.isEmpty ||
          rhs.argumentList.arguments.first is! FunctionExpression) {
        return false;
      }
      final FunctionExpression cb =
          rhs.argumentList.arguments.first as FunctionExpression;
      final bool clearsPairedWorker = verifiedBoolWorkers.any(
        (String flagName) =>
            _whenCompleteClosureResetsField(ir, cb, flagName, isBool: true),
      );
      if (!clearsPairedWorker) {
        return false;
      }
    }
    return true;
  }

  return false;
}

class _SafetyVisitor extends RecursiveAstVisitor<void> {
  _SafetyVisitor({
    required this.ir,
    required this.reviewed,
    required this.enabledRules,
  });

  final DartFileIR ir;
  final ReviewedLintCatalog? reviewed;
  final Set<String> enabledRules;
  final List<String> problems = <String>[];

  bool _inStateClass = false;
  bool _inConsumerStateClass = false;
  bool _inWidgetClass = false;
  bool _inDisposeMethod = false;
  bool _inDidChangeDependencies = false;
  bool _inBuildMethod = false;

  void _report(AstNode node, String rule, String message, {String? symbol}) {
    if (!enabledRules.contains(rule)) {
      return;
    }
    final DartSourceUnit unit = ir.sourceUnit;
    final CharacterLocation loc = unit.lineInfo!.getLocation(node.offset);
    final int line = loc.lineNumber;
    if (!unit.isLineEnabled(line) ||
        unit.directives.safetyIgnoredLines.contains(line)) {
      return;
    }
    if (reviewed != null) {
      if (reviewed!.matches(
        ReviewedLintCandidate(
          linter: 'safety',
          rule: rule,
          file: unit.file,
          enclosing: ir.enclosingSymbol(node),
          symbol: symbol,
          sourceLine: unit.sourceLineAt(line),
        ),
      )) {
        return;
      }
    }
    problems.add('${unit.file}:$line:${loc.columnNumber}: [$rule] $message');
  }

  void _checkKeepAliveClass(ClassIR classIR) {
    if (!enabledRules.contains('keepalive-reset') ||
        !classIR.isKeepAliveRiverpod ||
        classIR.mutableFields.isEmpty) {
      return;
    }
    final MethodDeclaration? buildMethod = classIR.methodsByName['build'];
    if (buildMethod == null) {
      return;
    }
    final Set<String> resetInBuild =
        _collectAssignedOrResetFields(buildMethod.body, classIR.methodsByName)
          ..addAll(
            _collectUnconditionalOnDisposeResets(
              ir,
              buildMethod.body,
              classIR.methodsByName,
            ),
          );

    final List<({VariableDeclaration field, String? typeSrc})> unreset = classIR
        .mutableFields
        .where(
          (({VariableDeclaration field, String? typeSrc}) entry) =>
              !resetInBuild.contains(entry.field.name.lexeme),
        )
        .toList();
    if (unreset.isEmpty) {
      return;
    }

    final Map<String, ClassFieldUsage> usages = classIR.fieldUsages;
    final Set<String> verifiedBoolWorkers = <String>{
      for (final ({VariableDeclaration field, String? typeSrc}) entry
          in unreset)
        if (_isWhenCompleteWorkerBool(
          ir,
          entry.field,
          entry.field.name.lexeme,
          entry.typeSrc,
          usages[entry.field.name.lexeme],
        ))
          entry.field.name.lexeme,
    };

    for (final ({VariableDeclaration field, String? typeSrc}) entry
        in unreset) {
      final VariableDeclaration field = entry.field;
      final String fieldName = field.name.lexeme;
      final String? typeSrc = entry.typeSrc;
      final ClassFieldUsage? usage = usages[fieldName];
      if (_isPureMonotonicIntCounter(field, typeSrc, usage) ||
          _isTryFinallyScopedMutex(ir, field, fieldName, typeSrc, usage) ||
          _isSequentialFutureQueue(field, fieldName, typeSrc, usage) ||
          _isWhenCompleteWorkerField(
            ir,
            field,
            fieldName,
            typeSrc,
            usage,
            verifiedBoolWorkers,
          )) {
        continue;
      }
      _report(
        field,
        'keepalive-reset',
        'mutable field `$fieldName` on `@Riverpod(keepAlive: true)` '
            'notifier `${classIR.name}` is not reset in `build()`',
        symbol: '${classIR.name}.$fieldName',
      );
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final ClassIR classIR =
        ir.classesByNode[node] ?? ClassIR.fromDeclaration(node);
    _checkKeepAliveClass(classIR);
    final bool prevState = _inStateClass;
    final bool prevConsumer = _inConsumerStateClass;
    final bool prevWidget = _inWidgetClass;

    _inStateClass = classIR.isStateClass;
    _inConsumerStateClass = classIR.isConsumerStateClass;
    _inWidgetClass = classIR.isWidgetClass;

    super.visitClassDeclaration(node);

    _inStateClass = prevState;
    _inConsumerStateClass = prevConsumer;
    _inWidgetClass = prevWidget;
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final String name = node.name.lexeme;
    final bool prevDispose = _inDisposeMethod;
    final bool prevDidChange = _inDidChangeDependencies;
    final bool prevBuild = _inBuildMethod;

    _inDisposeMethod = _inStateClass && !node.isStatic && name == 'dispose';
    _inDidChangeDependencies =
        _inStateClass && !node.isStatic && name == 'didChangeDependencies';
    _inBuildMethod =
        _inWidgetClass &&
        !node.isStatic &&
        (name == 'build' || name.startsWith('_build'));

    super.visitMethodDeclaration(node);

    _inDisposeMethod = prevDispose;
    _inDidChangeDependencies = prevDidChange;
    _inBuildMethod = prevBuild;
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    final bool prevDispose = _inDisposeMethod;
    final bool prevDidChange = _inDidChangeDependencies;
    final bool prevBuild = _inBuildMethod;

    _inDisposeMethod = false;
    _inDidChangeDependencies = false;
    _inBuildMethod = false;

    super.visitFunctionExpression(node);

    _inDisposeMethod = prevDispose;
    _inDidChangeDependencies = prevDidChange;
    _inBuildMethod = prevBuild;
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (_inDisposeMethod &&
        DartFileIR.isValueRead(node) &&
        !GuardSemantics.isCheckingMountedProperty(node)) {
      if (_inConsumerStateClass && node.name == 'ref') {
        _report(
          node,
          'dispose-ref',
          '`ref` read inside `State.dispose()` (cache the provider/notifier in '
              'a field in `initState` instead)',
        );
      } else if (node.name == 'context') {
        _report(node, 'dispose-ref', '`context` read inside `State.dispose()`');
      }
    }
    super.visitSimpleIdentifier(node);
  }

  bool _isDeferredStateCallback(
    MethodInvocation call,
    FunctionExpression closure,
  ) {
    if (!_inStateClass) {
      return false;
    }
    final String method = call.methodName.name;
    final String targetSrc = call.target?.toSource() ?? '';
    if (method == 'listenManual' && targetSrc == 'ref') {
      final NodeList<Argument> args = call.argumentList.arguments;
      return args.length >= 2 && identical(args[1], closure);
    }
    if (method == 'addPostFrameCallback') {
      return true;
    }
    if (method == 'delayed' && targetSrc == 'Future') {
      final NodeList<Argument> args = call.argumentList.arguments;
      return args.length >= 2 && identical(args[1], closure);
    }
    if (method == 'listen') {
      final bool isRiverpodRefListen =
          targetSrc == 'ref' ||
          (call.isCascaded &&
              call.parent is CascadeExpression &&
              (call.parent! as CascadeExpression).target.toSource() == 'ref');
      return !isRiverpodRefListen;
    }
    return false;
  }

  void _checkDeferredCallbackBody(
    FunctionExpression closure,
    String sourceDesc,
  ) {
    if (!enabledRules.contains('unmounted-listener')) {
      return;
    }
    final Set<String> paramNames = <String>{
      for (final FormalParameter p
          in closure.parameters?.parameters ?? const <FormalParameter>[])
        if (p.name != null) p.name!.lexeme,
    };
    closure.body.accept(
      _CallbackBodyInspector(
        onSetState: (MethodInvocation m) {
          if (!GuardSemantics.hasMountedCheckBefore(closure.body, m.offset)) {
            _report(
              m,
              'unmounted-listener',
              '`setState` in `$sourceDesc` callback without `mounted` check',
            );
          }
        },
        onIdentifier: (SimpleIdentifier id) {
          if (!DartFileIR.isValueRead(id) ||
              GuardSemantics.isCheckingMountedProperty(id) ||
              paramNames.contains(id.name)) {
            return;
          }
          if (_inConsumerStateClass && id.name == 'ref') {
            if (!GuardSemantics.hasMountedCheckBefore(
              closure.body,
              id.offset,
            )) {
              _report(
                id,
                'unmounted-listener',
                '`ref` read in `$sourceDesc` callback without `mounted` check',
              );
            }
          } else if (id.name == 'context') {
            if (!GuardSemantics.hasMountedCheckBefore(
              closure.body,
              id.offset,
            )) {
              _report(
                id,
                'unmounted-listener',
                '`context` read in `$sourceDesc` callback without `mounted` '
                    'check',
              );
            }
          }
        },
      ),
    );
  }

  void _checkLayoutSensitiveClosure(AstNode body, String contextDesc) {
    if (!enabledRules.contains('chat-layout')) {
      return;
    }
    body.accept(
      _LayoutMutationInspector(
        onMutation: (AstNode node, String what) {
          _report(
            node,
            'chat-layout',
            'synchronous `$what` inside `$contextDesc` (defer to '
                '`addPostFrameCallback` with a `mounted` check)',
          );
        },
      ),
    );
  }

  bool _looksLikeDirectNetworkCall(MethodInvocation node) {
    final String method = node.methodName.name;
    final Expression? target = node.target;
    if (target == null) {
      return false;
    }
    final String targetSrc = target.toSource();
    if (_httpMethod.hasMatch(method) &&
        (RegExp(
              r'(^|\.)_?(dio|http|httpClient)$',
              caseSensitive: false,
            ).hasMatch(targetSrc) ||
            targetSrc.contains('DioProvider'))) {
      return true;
    }
    if (targetSrc.contains('fluxerClientProvider')) {
      return true;
    }
    if (targetSrc.contains('RepositoryProvider)') &&
        _repoNetworkVerb.hasMatch(method)) {
      return true;
    }
    return false;
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final String typeName = node.constructorName.type.name.lexeme;
    final String file = ir.sourceUnit.file;

    if (_inStateClass && typeName == 'Timer') {
      for (final Argument arg in node.argumentList.arguments) {
        if (arg is FunctionExpression) {
          _checkDeferredCallbackBody(arg, 'Timer');
        }
      }
    }

    if (typeName == 'LayoutBuilder' || typeName == 'SliverLayoutBuilder') {
      if (typeName == 'LayoutBuilder' && _chatPanelOrListPath.hasMatch(file)) {
        _report(
          node.constructorName,
          'chat-layout',
          'bare `LayoutBuilder` in chat list/panel path (use '
              '`RebuildSafeLayoutBuilder`, or mark `// safety-lint-ignore: '
              '<reason>` if this subtree never holds `MessageList`)',
        );
      }
      for (final Argument arg in node.argumentList.arguments) {
        if (arg is NamedArgument &&
            arg.name.lexeme == 'builder' &&
            arg.argumentExpression is FunctionExpression) {
          _checkLayoutSensitiveClosure(
            (arg.argumentExpression as FunctionExpression).body,
            typeName,
          );
        }
      }
    }

    if (typeName == 'NotificationListener') {
      final String fullType = node.constructorName.type.toSource();
      if (fullType.contains('Scroll')) {
        for (final Argument arg in node.argumentList.arguments) {
          if (arg is NamedArgument &&
              arg.name.lexeme == 'onNotification' &&
              arg.argumentExpression is FunctionExpression) {
            _checkLayoutSensitiveClosure(
              (arg.argumentExpression as FunctionExpression).body,
              'NotificationListener<$fullType>',
            );
          }
        }
      }
    }

    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final String method = node.methodName.name;
    final String file = ir.sourceUnit.file;

    if (_inStateClass &&
        (method == 'Timer' ||
            (method == 'periodic' && node.target?.toSource() == 'Timer'))) {
      for (final Argument arg in node.argumentList.arguments) {
        if (arg is FunctionExpression) {
          _checkDeferredCallbackBody(arg, 'Timer');
        }
      }
    }

    if ((method == 'LayoutBuilder' || method == 'SliverLayoutBuilder') &&
        node.target == null) {
      if (method == 'LayoutBuilder' && _chatPanelOrListPath.hasMatch(file)) {
        _report(
          node.methodName,
          'chat-layout',
          'bare `LayoutBuilder` in chat list/panel path (use '
              '`RebuildSafeLayoutBuilder`, or mark `// safety-lint-ignore: '
              '<reason>` if this subtree never holds `MessageList`)',
        );
      }
      for (final Argument arg in node.argumentList.arguments) {
        if (arg is NamedArgument &&
            arg.name.lexeme == 'builder' &&
            arg.argumentExpression is FunctionExpression) {
          _checkLayoutSensitiveClosure(
            (arg.argumentExpression as FunctionExpression).body,
            method,
          );
        }
      }
    }

    if (method == 'NotificationListener' && node.target == null) {
      final String typeArgs = node.typeArguments?.toSource() ?? '';
      if (typeArgs.contains('Scroll')) {
        for (final Argument arg in node.argumentList.arguments) {
          if (arg is NamedArgument &&
              arg.name.lexeme == 'onNotification' &&
              arg.argumentExpression is FunctionExpression) {
            _checkLayoutSensitiveClosure(
              (arg.argumentExpression as FunctionExpression).body,
              'NotificationListener$typeArgs',
            );
          }
        }
      }
    }

    for (final Argument arg in node.argumentList.arguments) {
      if (arg is FunctionExpression && _isDeferredStateCallback(node, arg)) {
        _checkDeferredCallbackBody(arg, method);
      } else if (arg is NamedArgument &&
          arg.argumentExpression is FunctionExpression &&
          method == 'listen' &&
          _inStateClass) {
        _checkDeferredCallbackBody(
          arg.argumentExpression as FunctionExpression,
          'listen(${arg.name.lexeme})',
        );
      }
    }

    if (_inDidChangeDependencies && _chatPath.hasMatch(file)) {
      if (method == 'setState' || method == 'notifyListeners') {
        _report(
          node.methodName,
          'chat-layout',
          'synchronous `$method` inside `didChangeDependencies`',
        );
      } else if (method == 'invalidate' && node.target?.toSource() == 'ref') {
        _report(
          node,
          'chat-layout',
          'synchronous `ref.invalidate` inside `didChangeDependencies`',
        );
      }
    }

    if (_inBuildMethod && _looksLikeDirectNetworkCall(node)) {
      _report(
        node,
        'build-network',
        'direct network call `${node.target}.${node.methodName.name}()` inside '
            '`build()` (triggers a request per rebuild; see AGENTS.md '
            '"Network calls")',
      );
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (_inDidChangeDependencies && _chatPath.hasMatch(ir.sourceUnit.file)) {
      final String lhs = node.leftHandSide.toSource();
      if (lhs.endsWith('.state') || lhs.endsWith('.value')) {
        _report(
          node,
          'chat-layout',
          'synchronous `$lhs = ...` inside `didChangeDependencies`',
        );
      }
    }
    super.visitAssignmentExpression(node);
  }
}

class _CallbackBodyInspector extends RecursiveAstVisitor<void> {
  _CallbackBodyInspector({
    required this.onSetState,
    required this.onIdentifier,
  });

  final void Function(MethodInvocation node) onSetState;
  final void Function(SimpleIdentifier node) onIdentifier;

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'setState' &&
        (node.target == null || node.target is ThisExpression)) {
      onSetState(node);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    onIdentifier(node);
    super.visitSimpleIdentifier(node);
  }
}

class _LayoutMutationInspector extends RecursiveAstVisitor<void> {
  _LayoutMutationInspector({required this.onMutation});

  final void Function(AstNode node, String what) onMutation;

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final String method = node.methodName.name;
    if ((method == 'setState' || method == 'notifyListeners') &&
        (node.target == null || node.target is ThisExpression)) {
      onMutation(node.methodName, method);
    } else if (method == 'invalidate' && node.target?.toSource() == 'ref') {
      onMutation(node, 'ref.invalidate');
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final String lhs = node.leftHandSide.toSource();
    if (lhs.endsWith('.state') || lhs.endsWith('.value')) {
      onMutation(node, '$lhs = ...');
    }
    super.visitAssignmentExpression(node);
  }
}

/// Runs the Stage 4 `safety` pass over a shared [DartFileIR].
List<String> runSafetyPass(
  DartFileIR ir, {
  Set<String> rules = kAllSafetyRules,
  ReviewedLintCatalog? reviewed,
}) {
  if (ir.sourceUnit.isGenerated || ir.sourceUnit.unit == null) {
    return const <String>[];
  }
  final _SafetyVisitor visitor = _SafetyVisitor(
    ir: ir,
    reviewed: reviewed,
    enabledRules: rules,
  );
  ir.sourceUnit.unit!.accept(visitor);
  return visitor.problems;
}
