// Fork: AST safety checks for the mobile rules in AGENTS.md and
// lib/features/chat/AGENTS.md (tyne-chat/tyne#945):
//
//   dart run tool/fork_safety_lint.dart [--upstream <git ref>] [--all] [--include-reviewed] [--check-reviewed] [--reviewed <path>] [--rule <r1,r2>] [<file>...]
//
// Rules (all run in a single AST parse pass per file unless `--rule` filters):
// 1. `dispose-ref`: reading `WidgetRef` (`ref`) or `BuildContext` (`context`)
//    inside `State.dispose()`.
// 2. `unmounted-listener`: calling `setState` or reading `State.ref` /
//    `State.context` inside deferred callbacks (`ref.listenManual`, stream
//    `.listen`, `addPostFrameCallback`, `Timer`, `Future.delayed`) in a `State`
//    subclass without checking `mounted` / `context.mounted` /
//    `ref.context.mounted`.
// 3. `chat-layout`: synchronous state/provider mutations (`setState`,
//    `.state =`, `ref.invalidate`, `notifyListeners`) inside
//    `didChangeDependencies`, `LayoutBuilder` / `SliverLayoutBuilder`, or
//    `NotificationListener` callbacks, plus bare `LayoutBuilder` in chat panel
//    / page / message-list files (`RebuildSafeLayoutBuilder` required).
// 4. `build-network`: synchronous HTTP / Dio / REST / repository network calls
//    inside `build()` or `_build*()` widget methods (outside event callbacks),
//    including inline `FutureBuilder(future: dio.get(...))` (tyne-chat/tyne#114).
// 5. `keepalive-reset`: `@Riverpod(keepAlive: true)` notifier classes whose
//    mutable non-final instance fields are not reset in `build()`, excluding
//    unconditional top-of-`build()` `ref.onDispose(...)` cleanups, pure `++`
//    monotonic `int` counters, `try`/`finally` single-flight mutexes,
//    sequential `Future` queues, and `.whenComplete()` single-worker guards.
//
// Suppress a deliberate exception on fork lines with
// `// safety-lint-ignore: <reason>` on its line or the line above; reviewed
// upstream `--all` findings live in `tool/fork_lint_reviewed.json`
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

const Set<String> kAllSafetyRules = <String>{
  'dispose-ref',
  'unmounted-listener',
  'chat-layout',
  'build-network',
  'keepalive-reset',
};

final RegExp _generated = RegExp(
  r'(\.(g|freezed|pb|pbenum|pbjson|pbserver|fcm|mocks)\.dart$|/generated/)',
);
final RegExp _generatedHeader = RegExp(
  'GENERATED CODE - DO NOT MODIFY BY HAND|This is a generated file|@generated',
);
final RegExp _ignore = RegExp(r'safety-lint-ignore:\s*\S');

final RegExp _stateSuperclass = RegExp(
  r'^(State|ConsumerState|_?ConsumerState)\b',
);
final RegExp _consumerStateSuperclass = RegExp(r'^(ConsumerState)\b');
final RegExp _widgetSuperclass = RegExp(
  r'^(StatelessWidget|StatefulWidget|ConsumerWidget|ConsumerStatefulWidget|HookWidget|HookConsumerWidget)\b',
);
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

bool _hasMountedCheckBefore(AstNode body, int targetOffset) {
  bool found = false;
  body.accept(
    _MountedFinder(limitOffset: targetOffset, onFound: () => found = true),
  );
  return found;
}

class _MountedFinder extends RecursiveAstVisitor<void> {
  _MountedFinder({required this.limitOffset, required this.onFound});

  final int limitOffset;
  final void Function() onFound;

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Nested closures have their own mounted checks.
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.offset >= limitOffset) {
      return;
    }
    if (node.name == 'mounted') {
      onFound();
    }
  }
}

bool _isIdentifierValueRead(SimpleIdentifier node) {
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

bool _isCheckingMountedProperty(SimpleIdentifier node) {
  final AstNode? parent = node.parent;
  if (parent is PrefixedIdentifier &&
      identical(parent.prefix, node) &&
      parent.identifier.name == 'mounted') {
    return true;
  }
  if (parent is PrefixedIdentifier &&
      identical(parent.prefix, node) &&
      parent.identifier.name == 'context') {
    final AstNode? grand = parent.parent;
    if (grand is PropertyAccess && grand.propertyName.name == 'mounted') {
      return true;
    }
  }
  if (parent is PropertyAccess &&
      identical(parent.target, node) &&
      parent.propertyName.name == 'mounted') {
    return true;
  }
  return false;
}

bool _isKeepAliveRiverpodAnnotation(Annotation annotation) {
  final String name = annotation.name.name;
  if (name != 'Riverpod') {
    return false;
  }
  final ArgumentList? args = annotation.arguments;
  if (args == null) {
    return false;
  }
  for (final Argument arg in args.arguments) {
    if (arg is NamedArgument &&
        arg.name.lexeme == 'keepAlive' &&
        arg.argumentExpression is BooleanLiteral &&
        (arg.argumentExpression as BooleanLiteral).value) {
      return true;
    }
  }
  return false;
}

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

String? _fieldTargetName(Expression? expr) {
  if (expr is SimpleIdentifier) {
    return expr.name;
  }
  if (expr is PropertyAccess && expr.target is ThisExpression) {
    return expr.propertyName.name;
  }
  if (expr is PrefixedIdentifier && expr.prefix.name == 'this') {
    return expr.identifier.name;
  }
  return null;
}

class _FieldResetCollector extends RecursiveAstVisitor<void> {
  _FieldResetCollector({
    required this.onFieldTouched,
    required this.onHelperCalled,
  });

  final void Function(String field) onFieldTouched;
  final void Function(String helper) onHelperCalled;

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Listener closures inside `build()` (`ref.onDispose(() => _sub = null)`)
    // do NOT run synchronously when `build()` re-runs!
  }

  void _touchTarget(Expression? expr) {
    final String? name = _fieldTargetName(expr);
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

class _SyncControlExitOrAwaitFinder extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Nested closures do not interrupt synchronous execution of the outer block.
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    found = true;
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    found = true;
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    found = true;
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    found = true;
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    found = true;
  }
}

bool _containsSyncControlExitOrAwait(AstNode node) {
  final _SyncControlExitOrAwaitFinder finder = _SyncControlExitOrAwaitFinder();
  node.accept(finder);
  return finder.found;
}

class _ClassFieldUsage {
  int increments = 0;
  int decrements = 0;
  int methodResets = 0;
  final List<AssignmentExpression> assignments = <AssignmentExpression>[];
}

class _ClassFieldUsageCollector extends RecursiveAstVisitor<void> {
  final Map<String, _ClassFieldUsage> byField = <String, _ClassFieldUsage>{};

  _ClassFieldUsage _usage(String name) =>
      byField.putIfAbsent(name, _ClassFieldUsage.new);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final String? name = _fieldTargetName(node.leftHandSide);
    if (name != null) {
      _usage(name).assignments.add(node);
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    final String op = node.operator.lexeme;
    final String? name = _fieldTargetName(node.operand);
    if (name != null) {
      if (op == '++') {
        _usage(name).increments++;
      } else if (op == '--') {
        _usage(name).decrements++;
      }
    }
    super.visitPrefixExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    final String op = node.operator.lexeme;
    final String? name = _fieldTargetName(node.operand);
    if (name != null) {
      if (op == '++') {
        _usage(name).increments++;
      } else if (op == '--') {
        _usage(name).decrements++;
      }
    }
    super.visitPostfixExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final String method = node.methodName.name;
    if (method == 'clear' || method == 'reset' || method == 'cancel') {
      final String? name = _fieldTargetName(node.target);
      if (name != null) {
        _usage(name).methodResets++;
      }
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
    final String? methodName = _fieldTargetName(arg.unParenthesized);
    final MethodDeclaration? helper = methodName == null
        ? null
        : methodsByName[methodName];
    if (helper != null) {
      out.addAll(_collectAssignedOrResetFields(helper.body, methodsByName));
    }
  }
}

Set<String> _collectUnconditionalOnDisposeResets(
  FunctionBody buildBody,
  Map<String, MethodDeclaration> methodsByName,
) {
  final Set<String> reset = <String>{};
  if (buildBody is! BlockFunctionBody) {
    return reset;
  }
  for (final Statement stmt in buildBody.block.statements) {
    if (_containsSyncControlExitOrAwait(stmt)) {
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
  if (_fieldTargetName(node.leftHandSide) != fieldName ||
      node.operator.lexeme != '=') {
    return false;
  }
  return isBool
      ? _isFalseLiteral(node.rightHandSide)
      : _isNullLiteral(node.rightHandSide);
}

String? _normalizedTypeSource(TypeAnnotation? type) =>
    type?.toSource().replaceAll(RegExp(r'\s+'), '');

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
  _ClassFieldUsage? usage,
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
      final String? n0 = _fieldTargetName(a0.unParenthesized);
      final String? n1 = _fieldTargetName(a1.unParenthesized);
      if ((n0 == fieldName && n1 == localVarName) ||
          (n1 == fieldName && n0 == localVarName)) {
        return true;
      }
    }
  }
  if (unwrapped is BinaryExpression && unwrapped.operator.lexeme == '==') {
    final String? l = _fieldTargetName(unwrapped.leftOperand.unParenthesized);
    final String? r = _fieldTargetName(unwrapped.rightOperand.unParenthesized);
    return (l == fieldName && r == localVarName) ||
        (r == fieldName && l == localVarName);
  }
  return false;
}

bool _blockUnconditionallyResetsField(
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
          stmt.finallyBlock!,
          fieldName,
          isBool: isBool,
          matchLocalVar: matchLocalVar,
        )) {
      return true;
    }
    if (_containsSyncControlExitOrAwait(stmt)) {
      return false;
    }
  }
  return false;
}

bool _isProtectedByFinallyReset(
  AssignmentExpression assignment,
  String fieldName, {
  required bool isBool,
}) {
  // Case 1: already inside `try { ... } finally { _field = false/null; }`.
  AstNode? cur = assignment.parent;
  AstNode child = assignment;
  while (cur != null && cur is! FunctionBody && cur is! ClassDeclaration) {
    if (cur is TryStatement &&
        identical(cur.body, child) &&
        cur.finallyBlock != null &&
        _blockUnconditionallyResetsField(
          cur.finallyBlock!,
          fieldName,
          isBool: isBool,
        )) {
      return true;
    }
    child = cur;
    cur = cur.parent;
  }

  // Case 2: statement `_field = true/future;` immediately followed (before any
  // control exit or `await`) by `try { ... } finally { _field = false/null; }`.
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
          nextStmt.finallyBlock!,
          fieldName,
          isBool: isBool,
        )) {
      return true;
    }
    if (_containsSyncControlExitOrAwait(nextStmt)) {
      return false;
    }
  }
  return false;
}

bool _isTryFinallyScopedMutex(
  VariableDeclaration field,
  String fieldName,
  String? typeSrc,
  _ClassFieldUsage? usage,
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
    if (!_isProtectedByFinallyReset(a, fieldName, isBool: isBool)) {
      return false;
    }
  }
  return nonResetWrites >= 1;
}

class _LocalVarInitCollector extends RecursiveAstVisitor<void> {
  final Map<String, Expression> initializers = <String, Expression>{};

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Only collect local variables in the enclosing function body.
  }

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
  final String? targetName = _fieldTargetName(unwrapped);
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
  _ClassFieldUsage? usage,
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
  void visitFunctionExpression(FunctionExpression node) {
    // Only look for synchronous `.whenComplete(...)` registration in the
    // sibling statement, not inside an unrelated nested closure.
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'whenComplete' &&
        node.argumentList.arguments.isNotEmpty &&
        node.argumentList.arguments.first is FunctionExpression) {
      if (requiredTargetName == null ||
          _fieldTargetName(node.target?.unParenthesized) ==
              requiredTargetName) {
        matches.add(node);
      }
    }
    super.visitMethodInvocation(node);
  }
}

bool _whenCompleteClosureResetsField(
  FunctionExpression callback,
  String fieldName, {
  required bool isBool,
  String? matchLocalVar,
}) {
  final FunctionBody body = callback.body;
  if (body is BlockFunctionBody) {
    return _blockUnconditionallyResetsField(
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
  VariableDeclaration field,
  String fieldName,
  String? typeSrc,
  _ClassFieldUsage? usage,
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
        if (_whenCompleteClosureResetsField(cb, fieldName, isBool: true)) {
          found = true;
          break;
        }
      }
      if (found) {
        break;
      }
      if (_containsSyncControlExitOrAwait(nextStmt)) {
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
  VariableDeclaration field,
  String fieldName,
  String? typeSrc,
  _ClassFieldUsage? usage,
  Set<String> verifiedBoolWorkers,
) {
  if (_isWhenCompleteWorkerBool(field, fieldName, typeSrc, usage)) {
    return true;
  }
  if (usage == null ||
      usage.increments > 0 ||
      usage.decrements > 0 ||
      usage.methodResets > 0 ||
      usage.assignments.isEmpty) {
    return false;
  }

  // Nullable `Future<T>?` worker cleared via `.whenComplete(() => field = null)`.
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
        if (_whenCompleteClosureResetsField(cb, fieldName, isBool: false)) {
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
            if (_containsSyncControlExitOrAwait(nextStmt)) {
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

  // Non-nullable `Future<void>` idle future paired with a verified bool
  // worker flag reset inside `.whenComplete(...)` (e.g. `_realtimeWorkerIdle`).
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
            _whenCompleteClosureResetsField(cb, flagName, isBool: true),
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
    required this.file,
    required this.lineInfo,
    required this.sourceLines,
    required this.lines,
    required this.ignored,
    required this.reviewed,
    required this.enabledRules,
  });

  final String file;
  final LineInfo lineInfo;
  final List<String> sourceLines;
  final Set<int>? lines;
  final Set<int> ignored;
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
    final CharacterLocation loc = lineInfo.getLocation(node.offset);
    final int line = loc.lineNumber;
    if (lines != null && !lines!.contains(line)) {
      return;
    }
    if (ignored.contains(line)) {
      return;
    }
    if (reviewed != null) {
      final String sourceLine = (line >= 1 && line <= sourceLines.length)
          ? sourceLines[line - 1]
          : '';
      if (reviewed!.matches(
        ReviewedLintCandidate(
          linter: 'safety',
          rule: rule,
          file: file,
          enclosing: enclosingAstSymbol(node),
          symbol: symbol,
          sourceLine: sourceLine,
        ),
      )) {
        return;
      }
    }
    problems.add('$file:$line:${loc.columnNumber}: [$rule] $message');
  }

  void _checkKeepAliveClass(ClassDeclaration node) {
    if (!enabledRules.contains('keepalive-reset')) {
      return;
    }
    if (!node.metadata.any(_isKeepAliveRiverpodAnnotation)) {
      return;
    }
    final Map<String, MethodDeclaration> methods =
        <String, MethodDeclaration>{};
    final List<({VariableDeclaration field, String? typeSrc})> mutableFields =
        <({VariableDeclaration field, String? typeSrc})>[];
    for (final ClassMember member
        in node.body.childEntities.whereType<ClassMember>()) {
      if (member is MethodDeclaration) {
        methods[member.name.lexeme] = member;
      } else if (member is FieldDeclaration &&
          !member.isStatic &&
          !member.fields.isFinal &&
          !member.fields.isConst) {
        final String? typeSrc = _normalizedTypeSource(member.fields.type);
        for (final VariableDeclaration variable in member.fields.variables) {
          mutableFields.add((field: variable, typeSrc: typeSrc));
        }
      }
    }
    if (mutableFields.isEmpty) {
      return;
    }
    final MethodDeclaration? buildMethod = methods['build'];
    if (buildMethod == null) {
      return;
    }
    final Set<String> resetInBuild = _collectAssignedOrResetFields(
      buildMethod.body,
      methods,
    )..addAll(_collectUnconditionalOnDisposeResets(buildMethod.body, methods));

    final List<({VariableDeclaration field, String? typeSrc})> unreset =
        mutableFields
            .where((entry) => !resetInBuild.contains(entry.field.name.lexeme))
            .toList();
    if (unreset.isEmpty) {
      return;
    }

    final _ClassFieldUsageCollector usageCollector =
        _ClassFieldUsageCollector();
    node.accept(usageCollector);
    final Set<String> verifiedBoolWorkers = <String>{
      for (final entry in unreset)
        if (_isWhenCompleteWorkerBool(
          entry.field,
          entry.field.name.lexeme,
          entry.typeSrc,
          usageCollector.byField[entry.field.name.lexeme],
        ))
          entry.field.name.lexeme,
    };

    final String className = node.classKeyword.next?.lexeme ?? '<unnamed>';
    for (final entry in unreset) {
      final VariableDeclaration field = entry.field;
      final String fieldName = field.name.lexeme;
      final String? typeSrc = entry.typeSrc;
      final _ClassFieldUsage? usage = usageCollector.byField[fieldName];
      if (_isPureMonotonicIntCounter(field, typeSrc, usage) ||
          _isTryFinallyScopedMutex(field, fieldName, typeSrc, usage) ||
          _isSequentialFutureQueue(field, fieldName, typeSrc, usage) ||
          _isWhenCompleteWorkerField(
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
            'notifier `$className` is not reset in `build()`',
        symbol: '$className.$fieldName',
      );
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _checkKeepAliveClass(node);
    final String? superclass = node.extendsClause?.superclass.name.lexeme;
    final bool prevState = _inStateClass;
    final bool prevConsumer = _inConsumerStateClass;
    final bool prevWidget = _inWidgetClass;

    _inStateClass = superclass != null && _stateSuperclass.hasMatch(superclass);
    _inConsumerStateClass =
        superclass != null && _consumerStateSuperclass.hasMatch(superclass);
    _inWidgetClass =
        _inStateClass ||
        (superclass != null && _widgetSuperclass.hasMatch(superclass));

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
    // Entering a closure leaves synchronous `dispose`, `didChangeDependencies`,
    // and `build` execution unless checked specifically below.
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
        _isIdentifierValueRead(node) &&
        !_isCheckingMountedProperty(node)) {
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
      // Riverpod's `ref.listen(...)` / `ref..listen(...)` inside `build()` is
      // automatically cancelled when the widget unmounts; `Stream.listen(...)`
      // is not.
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
          if (!_hasMountedCheckBefore(closure.body, m.offset)) {
            _report(
              m,
              'unmounted-listener',
              '`setState` in `$sourceDesc` callback without `mounted` check',
            );
          }
        },
        onIdentifier: (SimpleIdentifier id) {
          if (!_isIdentifierValueRead(id) || _isCheckingMountedProperty(id)) {
            return;
          }
          if (paramNames.contains(id.name)) {
            return;
          }
          if (_inConsumerStateClass && id.name == 'ref') {
            if (!_hasMountedCheckBefore(closure.body, id.offset)) {
              _report(
                id,
                'unmounted-listener',
                '`ref` read in `$sourceDesc` callback without `mounted` check',
              );
            }
          } else if (id.name == 'context') {
            if (!_hasMountedCheckBefore(closure.body, id.offset)) {
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
    // Direct Dio / HTTP transport calls: `dio.get(...)`, `http.post(...)`,
    // `ref.read(fluxerDioProvider).get(...)`.
    if (_httpMethod.hasMatch(method) &&
        (RegExp(
              r'(^|\.)_?(dio|http|httpClient)$',
              caseSensitive: false,
            ).hasMatch(targetSrc) ||
            targetSrc.contains('DioProvider'))) {
      return true;
    }
    // Repository / API client network calls on `ref.read(*RepositoryProvider)`
    // or `ref.read(fluxerClientProvider)...`.
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

    // Timer / Timer.periodic in State class -> unmounted-listener check.
    if (_inStateClass && typeName == 'Timer') {
      for (final Argument arg in node.argumentList.arguments) {
        if (arg is FunctionExpression) {
          _checkDeferredCallbackBody(arg, 'Timer');
        }
      }
    }

    // Bare LayoutBuilder in chat panel/list/page files + layout mutation check.
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

    // NotificationListener<ScrollNotification>(onNotification: ...)
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

    // Constructor-like invocations without `new`/`const` when unresolved by AST
    // (parseString without type resolution represents `LayoutBuilder(...)` and
    // `Timer(...)` as MethodInvocation!).
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

    // Deferred callbacks in State subclasses.
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

    // Synchronous mutations in didChangeDependencies under lib/features/chat/.
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

    // Synchronous network calls inside build() / _build*().
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
    if (_inDidChangeDependencies && _chatPath.hasMatch(file)) {
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
  void visitFunctionExpression(FunctionExpression node) {
    // Nested closures inside the callback run on their own schedule.
  }

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
  void visitFunctionExpression(FunctionExpression node) {
    // Nested closures (`addPostFrameCallback((_) { setState(...); })`,
    // `onTap: () => ...`) do not run synchronously during layout!
  }

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

String _git(List<String> args) {
  final ProcessResult result = Process.runSync('git', args);
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    exit(2);
  }
  return result.stdout as String;
}

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
  ]).split('\n').where((String f) => f.isNotEmpty).toSet();
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

/// Runs the mobile AST safety checks on [source], filtered to [lines] (`null`
/// checks every line), [rules] (defaults to [kAllSafetyRules]), and
/// optional [reviewed] exceptions.
List<String> lintSafetySource(
  String file,
  String source,
  Set<int>? lines, {
  Set<String> rules = kAllSafetyRules,
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
  final _SafetyVisitor visitor = _SafetyVisitor(
    file: file,
    lineInfo: result.lineInfo,
    sourceLines: sourceLines,
    lines: lines,
    ignored: ignored,
    reviewed: reviewed,
    enabledRules: rules,
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
  final int ruleIndex = effectiveArgs.indexOf('--rule');
  final Set<String> rules = ruleIndex == -1
      ? kAllSafetyRules
      : effectiveArgs[ruleIndex + 1]
            .split(',')
            .map((String s) => s.trim())
            .where((String s) => s.isNotEmpty)
            .toSet();
  final List<String> given = <String>[
    for (int i = 0; i < effectiveArgs.length; i++)
      if (!effectiveArgs[i].startsWith('--') &&
          (i == 0 ||
              (effectiveArgs[i - 1] != '--upstream' &&
                  effectiveArgs[i - 1] != '--rule')))
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
      lintSafetySource(
        file,
        File(file).readAsStringSync(),
        targets[file],
        rules: rules,
        reviewed: catalog,
      ),
    );
  }
  finishReviewedCheckOrNotes(
    linter: 'safety',
    catalog: catalog,
    checkReviewed: reviewedArgs.checkReviewed,
    reportAllSummary: all,
    allFilesScanned: given.isEmpty,
    rules: rules,
  );
  problems.forEach(print);
  if (problems.isNotEmpty) {
    stderr.writeln(
      '\n${problems.length} fork safety lint violation(s). Fix the code per '
      'AGENTS.md, mark fork lines with `// safety-lint-ignore: <reason>`, or '
      'record reviewed upstream entries in `$kDefaultReviewedLintPath`.',
    );
    exit(1);
  }
}
