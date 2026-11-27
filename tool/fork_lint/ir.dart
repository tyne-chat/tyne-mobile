// Fork: Stage 3 of the mobile custom compiler-pipeline linter — shared
// `DartFileIR` providing memoized enclosing symbols, AST semantics, control-flow
// dominance/exits, guard checks, class tables, and def-use flow analysis.
// Fork: CLI linter imports analyzer from transitive SDK deps.
// ignore_for_file: depend_on_referenced_packages

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../fork_lint_reviewed.dart';
import 'source_unit.dart';

final RegExp _stateSuperclass = RegExp(
  r'^(State|ConsumerState|_?ConsumerState)\b',
);
final RegExp _consumerStateSuperclass = RegExp(r'^(ConsumerState)\b');
final RegExp _widgetSuperclass = RegExp(
  r'^(StatelessWidget|StatefulWidget|ConsumerWidget|ConsumerStatefulWidget|HookWidget|HookConsumerWidget)\b',
);

final RegExp kNotShownSinkCall = RegExp(
  '^(print|debugPrint|log|assert|Key|ValueKey|ObjectKey|PageStorageKey|GlobalKey'
  r'|\w*Exception|\w*Error|Uri|RegExp|DateFormat|NumberFormat'
  r'|FlutterErrorDetails|ErrorDescription|ErrorSummary|ErrorHint|Diagnostics\w*)$',
);
final RegExp kNotShownSinkTarget = RegExp(
  r'^(_?log(ger)?|_?logger|Logger|developer|AppLogger|_?talker|Talker)$',
);
final RegExp kUiSinkCall = RegExp(r'^(show[A-Z]\w*|userFacingErrorMessage)$');
final RegExp kTextSinkWidget = RegExp(
  r'^(Text|SelectableText|TextSpan|Tooltip)$',
);

/// Tracks mutable-field mutation sites across a class for `keepalive-reset`.
class ClassFieldUsage {
  int increments = 0;
  int decrements = 0;
  int methodResets = 0;
  final List<AssignmentExpression> assignments = <AssignmentExpression>[];
}

class _ClassFieldUsageCollector extends RecursiveAstVisitor<void> {
  final Map<String, ClassFieldUsage> byField = <String, ClassFieldUsage>{};

  ClassFieldUsage _usage(String name) =>
      byField.putIfAbsent(name, ClassFieldUsage.new);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final String? name = DartFileIR.fieldTargetName(node.leftHandSide);
    if (name != null) {
      _usage(name).assignments.add(node);
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    final String op = node.operator.lexeme;
    final String? name = DartFileIR.fieldTargetName(node.operand);
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
    final String? name = DartFileIR.fieldTargetName(node.operand);
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
      final String? name = DartFileIR.fieldTargetName(node.target);
      if (name != null) {
        _usage(name).methodResets++;
      }
    }
    super.visitMethodInvocation(node);
  }
}

bool _hasKeepAliveRiverpodAnnotation(Annotation annotation) {
  if (annotation.name.name != 'Riverpod') {
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

/// Pre-indexed metadata for one [ClassDeclaration], reused by `safety` and `async-ref`.
class ClassIR {
  ClassIR({
    required this.node,
    required this.name,
    required this.superclass,
    required this.isStateClass,
    required this.isConsumerStateClass,
    required this.isWidgetClass,
    required this.isKeepAliveRiverpod,
    required this.methodsByName,
    required this.mutableFields,
  });

  factory ClassIR.fromDeclaration(ClassDeclaration node) {
    final String className = node.classKeyword.next?.lexeme ?? '<unnamed>';
    final String? superclass = node.extendsClause?.superclass.name.lexeme;
    final bool isState =
        superclass != null && _stateSuperclass.hasMatch(superclass);
    final bool isConsumerState =
        superclass != null && _consumerStateSuperclass.hasMatch(superclass);
    final bool isWidget =
        isState ||
        (superclass != null && _widgetSuperclass.hasMatch(superclass));
    final bool isKeepAlive = node.metadata.any(_hasKeepAliveRiverpodAnnotation);

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
        final String? typeSrc = member.fields.type?.toSource().replaceAll(
          RegExp(r'\s+'),
          '',
        );
        for (final VariableDeclaration variable in member.fields.variables) {
          mutableFields.add((field: variable, typeSrc: typeSrc));
        }
      }
    }

    return ClassIR(
      node: node,
      name: className,
      superclass: superclass,
      isStateClass: isState,
      isConsumerStateClass: isConsumerState,
      isWidgetClass: isWidget,
      isKeepAliveRiverpod: isKeepAlive,
      methodsByName: methods,
      mutableFields: mutableFields,
    );
  }

  final ClassDeclaration node;
  final String name;
  final String? superclass;
  final bool isStateClass;
  final bool isConsumerStateClass;
  final bool isWidgetClass;
  final bool isKeepAliveRiverpod;
  final Map<String, MethodDeclaration> methodsByName;
  final List<({VariableDeclaration field, String? typeSrc})> mutableFields;

  Map<String, ClassFieldUsage>? _fieldUsages;

  Map<String, ClassFieldUsage> get fieldUsages {
    if (_fieldUsages == null) {
      final _ClassFieldUsageCollector collector = _ClassFieldUsageCollector();
      node.accept(collector);
      _fieldUsages = collector.byField;
    }
    return _fieldUsages!;
  }
}

/// Scope descriptor passed to [GuardSemantics] helpers.
class AsyncScopeInfo {
  const AsyncScopeInfo({
    required this.inStateClass,
    required this.stateHasContext,
    required this.inConsumerStateClass,
    required this.widgetRefNames,
    required this.contextNames,
  });

  final bool inStateClass;
  final bool stateHasContext;
  final bool inConsumerStateClass;
  final Set<String> widgetRefNames;
  final Set<String> contextNames;
}

class _SyncControlExitOrAwaitFinder extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitFunctionExpression(FunctionExpression node) {}

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

class _MountedFinder extends RecursiveAstVisitor<void> {
  _MountedFinder({required this.limitOffset, required this.onFound});

  final int limitOffset;
  final void Function() onFound;

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.offset < limitOffset && node.name == 'mounted') {
      onFound();
    }
  }
}

/// Shared guard and lifecycle mount semantics used across `safety` and `async-ref`.
class GuardSemantics {
  GuardSemantics._();

  static bool isCheckingMountedProperty(SimpleIdentifier node) {
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

  static bool hasMountedCheckBefore(AstNode body, int targetOffset) {
    bool found = false;
    body.accept(
      _MountedFinder(limitOffset: targetOffset, onFound: () => found = true),
    );
    return found;
  }

  static Set<String> positivelyGuardedTargets(
    Expression condition,
    AsyncScopeInfo scope,
  ) {
    final Expression unwrapped = condition.unParenthesized;
    if (unwrapped is SimpleIdentifier && unwrapped.name == 'mounted') {
      return scope.inStateClass
          ? const <String>{'__state_mounted__'}
          : const <String>{};
    }
    if (unwrapped is PrefixedIdentifier &&
        unwrapped.identifier.name == 'mounted') {
      final String target = unwrapped.prefix.name;
      if (target == 'this' && scope.inStateClass) {
        return const <String>{'__state_mounted__'};
      }
      if (scope.contextNames.contains(target) ||
          (scope.stateHasContext && target == 'context')) {
        return <String>{target};
      }
    }
    if (unwrapped is PropertyAccess &&
        unwrapped.propertyName.name == 'mounted') {
      final Expression? target = unwrapped.target;
      if (target is ThisExpression && scope.inStateClass) {
        return const <String>{'__state_mounted__'};
      }
      if (target is PrefixedIdentifier &&
          target.identifier.name == 'context' &&
          (scope.widgetRefNames.contains(target.prefix.name) ||
              (scope.inConsumerStateClass && target.prefix.name == 'ref'))) {
        return <String>{target.prefix.name};
      }
      if (target is SimpleIdentifier &&
          (scope.contextNames.contains(target.name) ||
              (scope.stateHasContext && target.name == 'context'))) {
        return <String>{target.name};
      }
    }
    if (unwrapped is BinaryExpression && unwrapped.operator.lexeme == '&&') {
      return <String>{
        ...positivelyGuardedTargets(unwrapped.leftOperand, scope),
        ...positivelyGuardedTargets(unwrapped.rightOperand, scope),
      };
    }
    return const <String>{};
  }

  static String? _nonNullCheckedIdentifier(Expression expr) {
    final Expression unwrapped = expr.unParenthesized;
    if (unwrapped is BinaryExpression && unwrapped.operator.lexeme == '!=') {
      final Expression left = unwrapped.leftOperand.unParenthesized;
      final Expression right = unwrapped.rightOperand.unParenthesized;
      if (right is NullLiteral && left is SimpleIdentifier) {
        return left.name;
      }
      if (left is NullLiteral && right is SimpleIdentifier) {
        return right.name;
      }
    }
    return null;
  }

  static Set<String> negatedExitGuardedTargets(
    Expression condition,
    AsyncScopeInfo scope,
  ) {
    final Expression unwrapped = condition.unParenthesized;
    if (unwrapped is PrefixExpression && unwrapped.operator.lexeme == '!') {
      return positivelyGuardedTargets(unwrapped.operand, scope);
    }
    if (unwrapped is BinaryExpression && unwrapped.operator.lexeme == '||') {
      return <String>{
        ...negatedExitGuardedTargets(unwrapped.leftOperand, scope),
        ...negatedExitGuardedTargets(unwrapped.rightOperand, scope),
      };
    }
    if (unwrapped is BinaryExpression && unwrapped.operator.lexeme == '&&') {
      final Set<String> result = <String>{};
      final String? leftNonNull = _nonNullCheckedIdentifier(
        unwrapped.leftOperand,
      );
      if (leftNonNull != null &&
          negatedExitGuardedTargets(
            unwrapped.rightOperand,
            scope,
          ).contains(leftNonNull)) {
        result.add(leftNonNull);
      }
      final String? rightNonNull = _nonNullCheckedIdentifier(
        unwrapped.rightOperand,
      );
      if (rightNonNull != null &&
          negatedExitGuardedTargets(
            unwrapped.leftOperand,
            scope,
          ).contains(rightNonNull)) {
        result.add(rightNonNull);
      }
      return result;
    }
    if (unwrapped is ConditionalExpression) {
      final Set<String> a = negatedExitGuardedTargets(
        unwrapped.thenExpression,
        scope,
      );
      final Set<String> b = negatedExitGuardedTargets(
        unwrapped.elseExpression,
        scope,
      );
      if (a.isNotEmpty || b.isNotEmpty) {
        return <String>{...a, ...b};
      }
    }
    return const <String>{};
  }
}

class _ScopeVariableCollector extends RecursiveAstVisitor<void> {
  final Set<String> mutatedOrShadowed = <String>{};
  final Map<String, VariableDeclaration> localInits =
      <String, VariableDeclaration>{};
  final Map<String, List<SimpleIdentifier>> readsByVar =
      <String, List<SimpleIdentifier>>{};

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
      mutatedOrShadowed.add(name);
    }
    super.visitRegularFormalParameter(node);
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    mutatedOrShadowed.add(node.name.lexeme);
    super.visitSuperFormalParameter(node);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    mutatedOrShadowed.add(node.name.lexeme);
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
    if (DartFileIR.isValueRead(node)) {
      readsByVar.putIfAbsent(node.name, () => <SimpleIdentifier>[]).add(node);
    }
    super.visitSimpleIdentifier(node);
  }
}

bool _isInsideNotShownSink(AstNode start) {
  for (AstNode? node = start.parent; node != null; node = node.parent) {
    if (node is MethodInvocation || node is InstanceCreationExpression) {
      final String callee = DartFileIR.calleeName(node);
      if (kNotShownSinkCall.hasMatch(callee)) {
        return true;
      }
      if (kNotShownSinkTarget.hasMatch(DartFileIR.targetRootName(node))) {
        return true;
      }
      if (kUiSinkCall.hasMatch(callee) || kTextSinkWidget.hasMatch(callee)) {
        return false;
      }
    }
  }
  return false;
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

/// Def-use analyzer over a single lexical [Block] or [FunctionBody].
class VarFlowAnalyzer {
  VarFlowAnalyzer(AstNode scopeNode) {
    scopeNode.accept(_collector);
  }

  final _ScopeVariableCollector _collector = _ScopeVariableCollector();

  Set<String> get mutatedOrShadowed => _collector.mutatedOrShadowed;

  bool flowsOnlyToNotShown(String varName, {Set<String>? visiting}) {
    final Set<String> seen = visiting ?? <String>{};
    if (!seen.add(varName) || _collector.mutatedOrShadowed.contains(varName)) {
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

class _UnitPrePass extends RecursiveAstVisitor<void> {
  final Map<ClassDeclaration, ClassIR> classesByNode =
      <ClassDeclaration, ClassIR>{};
  final List<({String name, FormalParameterList? params, FunctionBody body})>
  privateCallables =
      <({String name, FormalParameterList? params, FunctionBody body})>[];

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    classesByNode[node] = ClassIR.fromDeclaration(node);
    super.visitClassDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final String name = node.name.lexeme;
    if (name.startsWith('_') && node.parameters != null) {
      privateCallables.add((
        name: name,
        params: node.parameters,
        body: node.body,
      ));
    }
    super.visitMethodDeclaration(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final String name = node.name.lexeme;
    if (name.startsWith('_') && node.functionExpression.parameters != null) {
      privateCallables.add((
        name: name,
        params: node.functionExpression.parameters,
        body: node.functionExpression.body,
      ));
    }
    super.visitFunctionDeclaration(node);
  }
}

/// Shared Stage 3 IR built once per parsed [DartSourceUnit].
class DartFileIR {
  DartFileIR._(
    this._privateCallables, {
    required this.sourceUnit,
    required this.classesByNode,
  });

  factory DartFileIR.build(DartSourceUnit sourceUnit) {
    if (sourceUnit.isGenerated || sourceUnit.unit == null) {
      return DartFileIR._(
        const <
          ({String name, FormalParameterList? params, FunctionBody body})
        >[],
        sourceUnit: sourceUnit,
        classesByNode: const <ClassDeclaration, ClassIR>{},
      );
    }
    final _UnitPrePass pre = _UnitPrePass();
    sourceUnit.unit!.accept(pre);
    return DartFileIR._(
      pre.privateCallables,
      sourceUnit: sourceUnit,
      classesByNode: pre.classesByNode,
    );
  }

  final DartSourceUnit sourceUnit;
  final Map<ClassDeclaration, ClassIR> classesByNode;
  final List<({String name, FormalParameterList? params, FunctionBody body})>
  _privateCallables;

  final Expando<String> _enclosingCache = Expando<String>();
  final Expando<bool> _alwaysExitsCache = Expando<bool>();
  final Expando<bool> _callsPaintCache = Expando<bool>();
  final Expando<VarFlowAnalyzer> _varFlowCache = Expando<VarFlowAnalyzer>();
  Set<String>? _logOnlyPrivateNamedParams;

  /// Memoized `Type.member`, `Type`, or top-level `function` name for [node].
  String enclosingSymbol(AstNode node) {
    final String? cached = _enclosingCache[node];
    if (cached != null) {
      return cached;
    }
    final String computed = enclosingAstSymbol(node);
    _enclosingCache[node] = computed;
    return computed;
  }

  /// Memoized conservative check for whether [stmt] always exits its enclosing block.
  bool statementAlwaysExits(Statement stmt) {
    final bool? cached = _alwaysExitsCache[stmt];
    if (cached != null) {
      return cached;
    }
    bool exits = false;
    if (stmt is ReturnStatement ||
        stmt is BreakStatement ||
        stmt is ContinueStatement) {
      exits = true;
    } else if (stmt is ExpressionStatement &&
        stmt.expression is ThrowExpression) {
      exits = true;
    } else if (stmt is Block) {
      exits = stmt.statements.any(statementAlwaysExits);
    } else if (stmt is IfStatement && stmt.elseStatement != null) {
      exits =
          statementAlwaysExits(stmt.thenStatement) &&
          statementAlwaysExits(stmt.elseStatement!);
    }
    _alwaysExitsCache[stmt] = exits;
    return exits;
  }

  /// Whether [node] contains a direct synchronous return/throw/break/continue or await.
  bool containsSyncControlExitOrAwait(AstNode node) {
    final _SyncControlExitOrAwaitFinder finder =
        _SyncControlExitOrAwaitFinder();
    node.accept(finder);
    return finder.found;
  }

  /// Memoized check for whether a [FunctionBody] invokes `.paint(...)`.
  bool bodyCallsPaint(FunctionBody body) {
    final bool? cached = _callsPaintCache[body];
    if (cached != null) {
      return cached;
    }
    final _PaintMethodFinder finder = _PaintMethodFinder();
    body.accept(finder);
    final bool result = finder.found;
    _callsPaintCache[body] = result;
    return result;
  }

  /// Cached [VarFlowAnalyzer] over a lexical [Block] or [FunctionBody].
  VarFlowAnalyzer varFlowFor(AstNode scopeNode) =>
      _varFlowCache[scopeNode] ??= VarFlowAnalyzer(scopeNode);

  /// Lazy set of `_helper:namedParam` pairs whose values flow solely to excluded sinks.
  Set<String> get logOnlyPrivateNamedParams {
    if (_logOnlyPrivateNamedParams != null) {
      return _logOnlyPrivateNamedParams!;
    }
    final Set<String> allowed = <String>{};
    final Set<String> rejected = <String>{};
    for (final ({String name, FormalParameterList? params, FunctionBody body})
        item
        in _privateCallables) {
      final List<String> namedParams = <String>[
        for (final FormalParameter p
            in item.params?.parameters ?? const <FormalParameter>[])
          if (p.isNamed && p.name != null) p.name!.lexeme,
      ];
      if (namedParams.isEmpty) {
        continue;
      }
      final _ScopeVariableCollector bodyCollector = _ScopeVariableCollector();
      item.body.accept(bodyCollector);
      final VarFlowAnalyzer analyzer = varFlowFor(item.body);
      for (final String param in namedParams) {
        final String key = '${item.name}:$param';
        if (!bodyCollector.mutatedOrShadowed.contains(param) &&
            analyzer.flowsOnlyToNotShown(param)) {
          allowed.add(key);
        } else {
          rejected.add(key);
        }
      }
    }
    _logOnlyPrivateNamedParams = allowed.difference(rejected);
    return _logOnlyPrivateNamedParams!;
  }

  /// Shared identifier read predicate across `safety`, `async-ref`, and `string`.
  static bool isValueRead(
    SimpleIdentifier node, {
    bool excludePlainAssignmentTarget = false,
  }) {
    if (node.inDeclarationContext()) {
      return false;
    }
    final AstNode? parent = node.parent;
    if (parent is Label) {
      return false;
    }
    if (excludePlainAssignmentTarget &&
        parent is AssignmentExpression &&
        identical(parent.leftHandSide, node) &&
        parent.operator.lexeme == '=') {
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

  static String? fieldTargetName(Expression? expr) {
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

  static String calleeName(AstNode node) {
    if (node is MethodInvocation) {
      return node.methodName.name;
    }
    if (node is InstanceCreationExpression) {
      final String source = node.constructorName.toSource().split('<').first;
      final List<String> parts = source.split('.');
      return parts.length > 1 && RegExp('^[a-z]').hasMatch(parts.last)
          ? parts[parts.length - 2]
          : parts.last;
    }
    if (node is FunctionExpressionInvocation) {
      return node.function.toSource();
    }
    return '';
  }

  static String targetRootName(AstNode node) {
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
}
