// Fork: Stage 4 `async-ref` pass consuming shared `DartFileIR` (`ClassIR`,
// `ControlFlowIR.statementAlwaysExits`, `GuardSemantics`, `enclosingSymbol`).
// Fork: CLI linter imports analyzer from transitive SDK deps.
// ignore_for_file: depend_on_referenced_packages

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

import '../../fork_lint_reviewed.dart';
import '../ir.dart';
import '../source_unit.dart';

const Set<String> kAllAsyncRefRules = <String>{'async-ref'};

String? _parameterTypeName(FormalParameter param) {
  for (final Object entity in param.childEntities) {
    if (entity is TypeAnnotation) {
      return entity.toSource().replaceAll('?', '');
    }
    if (entity is FormalParameter) {
      return _parameterTypeName(entity);
    }
  }
  return null;
}

({Set<String> refs, Set<String> contexts, Set<String> allParamNames})
_extractParameters(FormalParameterList? params) {
  final Set<String> refs = <String>{};
  final Set<String> contexts = <String>{};
  final Set<String> allNames = <String>{};
  if (params == null) {
    return (refs: refs, contexts: contexts, allParamNames: allNames);
  }
  for (final FormalParameter param in params.parameters) {
    final String? name = param.name?.lexeme;
    if (name == null) {
      continue;
    }
    allNames.add(name);
    final String? typeName = _parameterTypeName(param);
    if (typeName == 'WidgetRef') {
      refs.add(name);
    } else if (typeName == 'BuildContext') {
      contexts.add(name);
    }
  }
  return (refs: refs, contexts: contexts, allParamNames: allNames);
}

class _AsyncBodyAnalyzer extends RecursiveAstVisitor<void> {
  _AsyncBodyAnalyzer({
    required this.ir,
    required this.reviewed,
    required this.scope,
    required this.problems,
  });

  final DartFileIR ir;
  final ReviewedLintCatalog? reviewed;
  final AsyncScopeInfo scope;
  final List<String> problems;

  bool _seenAwait = false;
  int _awaitCount = 0;
  final Set<String> _guarded = <String>{};
  final Set<String> _shadowedLocals = <String>{};

  bool _isGuardedRef(String name) {
    if (_guarded.contains(name) || _guarded.contains('__state_mounted__')) {
      return true;
    }
    if (scope.inConsumerStateClass &&
        name == 'ref' &&
        _guarded.contains('context')) {
      return true;
    }
    if (scope.contextNames.isNotEmpty &&
        scope.contextNames.any(_guarded.contains)) {
      return true;
    }
    return false;
  }

  bool _isGuardedContext(String name) {
    if (_guarded.contains(name) || _guarded.contains('__state_mounted__')) {
      return true;
    }
    if (scope.inConsumerStateClass &&
        name == 'context' &&
        _guarded.contains('ref')) {
      return true;
    }
    if (scope.widgetRefNames.isNotEmpty &&
        scope.widgetRefNames.any(_guarded.contains)) {
      return true;
    }
    return false;
  }

  bool _isNullCheckOnly(SimpleIdentifier node) {
    AstNode child = node;
    AstNode? parent = node.parent;
    while (parent is ParenthesizedExpression) {
      child = parent;
      parent = parent.parent;
    }
    if (parent is BinaryExpression &&
        (parent.operator.lexeme == '==' || parent.operator.lexeme == '!=')) {
      final Expression? other = identical(parent.leftOperand, child)
          ? parent.rightOperand
          : identical(parent.rightOperand, child)
          ? parent.leftOperand
          : null;
      return other != null && other.unParenthesized is NullLiteral;
    }
    if (parent is ArgumentList && parent.arguments.length == 2) {
      final AstNode? call = parent.parent;
      if (call is MethodInvocation &&
          call.target == null &&
          call.methodName.name == 'identical') {
        final Argument a0 = parent.arguments[0];
        final Argument a1 = parent.arguments[1];
        if (identical(a0, child) &&
            a1 is Expression &&
            a1.unParenthesized is NullLiteral) {
          return true;
        }
        if (identical(a1, child) &&
            a0 is Expression &&
            a0.unParenthesized is NullLiteral) {
          return true;
        }
      }
    }
    return false;
  }

  void _report(AstNode node, String kind, String name) {
    final DartSourceUnit unit = ir.sourceUnit;
    final CharacterLocation loc = unit.lineInfo!.getLocation(node.offset);
    final int line = loc.lineNumber;
    if (!unit.isLineEnabled(line) ||
        unit.directives.asyncRefIgnoredLines.contains(line)) {
      return;
    }
    if (reviewed != null) {
      if (reviewed!.matches(
        ReviewedLintCandidate(
          linter: 'async-ref',
          rule: 'async-ref',
          file: unit.file,
          enclosing: ir.enclosingSymbol(node),
          target: name,
          sourceLine: unit.sourceLineAt(line),
        ),
      )) {
        return;
      }
    }
    problems.add(
      '${unit.file}:$line:${loc.columnNumber}: unguarded $kind `$name` after `await`',
    );
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {}

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    node.initializer?.accept(this);
    final String name = node.name.lexeme;
    final AstNode? list = node.parent;
    String? typeName;
    if (list is VariableDeclarationList) {
      typeName = list.type?.toSource().replaceAll('?', '');
    }
    if (typeName == 'WidgetRef') {
      scope.widgetRefNames.add(name);
    } else if (typeName == 'BuildContext') {
      scope.contextNames.add(name);
    } else if (name == 'context' || name == 'ref') {
      _shadowedLocals.add(name);
    }
  }

  @override
  void visitBlock(Block node) {
    for (final Statement stmt in node.statements) {
      stmt.accept(this);
      if (ir.statementAlwaysExits(stmt)) {
        break;
      }
    }
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    node.rightHandSide.accept(this);
    node.leftHandSide.accept(this);
    if (node.leftHandSide is SimpleIdentifier) {
      _guarded.remove((node.leftHandSide as SimpleIdentifier).name);
    }
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    node.expression.accept(this);
    _seenAwait = true;
    _awaitCount++;
    _guarded.clear();
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final String op = node.operator.lexeme;
    if (op == '&&' || op == '||') {
      node.leftOperand.accept(this);
      final Set<String> added = op == '&&'
          ? GuardSemantics.positivelyGuardedTargets(node.leftOperand, scope)
          : GuardSemantics.negatedExitGuardedTargets(node.leftOperand, scope);
      final int beforeRightAwait = _awaitCount;
      final Set<String> saved = Set<String>.of(_guarded);
      _guarded.addAll(added);
      node.rightOperand.accept(this);
      if (_awaitCount == beforeRightAwait) {
        _guarded
          ..clear()
          ..addAll(saved);
      }
      return;
    }
    super.visitBinaryExpression(node);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    node.condition.accept(this);
    final Set<String> pos = GuardSemantics.positivelyGuardedTargets(
      node.condition,
      scope,
    );
    final Set<String> neg = GuardSemantics.negatedExitGuardedTargets(
      node.condition,
      scope,
    );

    final bool savedAwait = _seenAwait;
    final Set<String> savedGuarded = Set<String>.of(_guarded);

    _guarded.addAll(pos);
    node.thenExpression.accept(this);
    final bool thenAwait = _seenAwait;

    _seenAwait = savedAwait;
    _guarded
      ..clear()
      ..addAll(savedGuarded)
      ..addAll(neg);
    node.elseExpression.accept(this);
    final bool elseAwait = _seenAwait;

    _seenAwait = thenAwait || elseAwait;
    if (_seenAwait != savedAwait) {
      _guarded.clear();
    } else {
      _guarded
        ..clear()
        ..addAll(savedGuarded);
    }
  }

  @override
  void visitIfStatement(IfStatement node) {
    node.expression.accept(this);
    final Set<String> posGuards = GuardSemantics.positivelyGuardedTargets(
      node.expression,
      scope,
    );
    final Set<String> exitGuards = GuardSemantics.negatedExitGuardedTargets(
      node.expression,
      scope,
    );

    final bool savedAwait = _seenAwait;
    final Set<String> savedGuarded = Set<String>.of(_guarded);

    _guarded.addAll(posGuards);
    node.thenStatement.accept(this);
    final bool thenAwait = _seenAwait;
    final Set<String> thenGuarded = Set<String>.of(_guarded);
    final bool thenExits = ir.statementAlwaysExits(node.thenStatement);

    if (node.elseStatement == null) {
      if (thenExits) {
        _seenAwait = savedAwait;
        _guarded
          ..clear()
          ..addAll(savedGuarded)
          ..addAll(exitGuards);
      } else if (!savedAwait && thenAwait) {
        _seenAwait = true;
        _guarded
          ..clear()
          ..addAll(thenGuarded);
      } else {
        _seenAwait = savedAwait || thenAwait;
        _guarded
          ..clear()
          ..addAll(savedGuarded.intersection(thenGuarded));
      }
      return;
    }

    _seenAwait = savedAwait;
    _guarded
      ..clear()
      ..addAll(savedGuarded)
      ..addAll(exitGuards);
    node.elseStatement!.accept(this);
    final bool elseAwait = _seenAwait;
    final Set<String> elseGuarded = Set<String>.of(_guarded);
    final bool elseExits = ir.statementAlwaysExits(node.elseStatement!);

    if (thenExits && !elseExits) {
      _seenAwait = elseAwait;
      _guarded
        ..clear()
        ..addAll(elseGuarded);
    } else if (elseExits && !thenExits) {
      _seenAwait = thenAwait;
      _guarded
        ..clear()
        ..addAll(thenGuarded);
    } else if (!thenAwait && elseAwait) {
      _seenAwait = true;
      _guarded
        ..clear()
        ..addAll(elseGuarded);
    } else if (thenAwait && !elseAwait) {
      _seenAwait = true;
      _guarded
        ..clear()
        ..addAll(thenGuarded);
    } else {
      _seenAwait = thenAwait || elseAwait;
      _guarded
        ..clear()
        ..addAll(thenGuarded.intersection(elseGuarded));
    }
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    node.expression.accept(this);
    final bool savedAwait = _seenAwait;
    final Set<String> savedGuarded = Set<String>.of(_guarded);

    bool anyFallthrough = false;
    bool anyFallthroughAwaited = false;
    Set<String>? fallthroughGuarded;

    for (final SwitchMember member in node.members) {
      _seenAwait = savedAwait;
      _guarded
        ..clear()
        ..addAll(savedGuarded);
      for (final Statement stmt in member.statements) {
        stmt.accept(this);
        if (ir.statementAlwaysExits(stmt)) {
          break;
        }
      }
      final bool caseExits = member.statements.any(ir.statementAlwaysExits);
      if (!caseExits) {
        anyFallthrough = true;
        if (_seenAwait) {
          anyFallthroughAwaited = true;
          fallthroughGuarded = fallthroughGuarded == null
              ? Set<String>.of(_guarded)
              : fallthroughGuarded.intersection(_guarded);
        }
      }
    }

    if (!anyFallthrough) {
      _seenAwait = savedAwait;
      _guarded
        ..clear()
        ..addAll(savedGuarded);
    } else if (anyFallthroughAwaited) {
      _seenAwait = true;
      _guarded
        ..clear()
        ..addAll(fallthroughGuarded ?? const <String>{});
    } else {
      _seenAwait = savedAwait;
      _guarded
        ..clear()
        ..addAll(savedGuarded);
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (!_seenAwait ||
        !DartFileIR.isValueRead(node, excludePlainAssignmentTarget: true) ||
        GuardSemantics.isCheckingMountedProperty(node) ||
        _isNullCheckOnly(node)) {
      return;
    }
    final String name = node.name;
    if (_shadowedLocals.contains(name)) {
      return;
    }
    final bool isWidgetRef =
        scope.widgetRefNames.contains(name) ||
        (scope.inConsumerStateClass && name == 'ref');
    if (isWidgetRef && !_isGuardedRef(name)) {
      _report(node, 'WidgetRef', name);
      return;
    }
    final bool isBuildContext =
        scope.contextNames.contains(name) ||
        (scope.stateHasContext && name == 'context');
    if (isBuildContext && !_isGuardedContext(name)) {
      _report(node, 'BuildContext', name);
    }
  }
}

class _AsyncRefUnitVisitor extends RecursiveAstVisitor<void> {
  _AsyncRefUnitVisitor(this.ir, this.reviewed);

  final DartFileIR ir;
  final ReviewedLintCatalog? reviewed;
  final List<String> problems = <String>[];

  bool _inStateClass = false;
  bool _inConsumerStateClass = false;
  Set<String> _enclosingWidgetRefs = const <String>{};
  Set<String> _enclosingContexts = const <String>{};

  void _analyzeIfAsync(
    FunctionBody body,
    FormalParameterList? parameters, {
    required bool inheritStateFields,
  }) {
    final ({Set<String> refs, Set<String> contexts, Set<String> allParamNames})
    extracted = _extractParameters(parameters);

    final Set<String> nextRefs = <String>{
      ..._enclosingWidgetRefs.where(
        (String n) => !extracted.allParamNames.contains(n),
      ),
      ...extracted.refs,
    };
    final Set<String> nextContexts = <String>{
      ..._enclosingContexts.where(
        (String n) => !extracted.allParamNames.contains(n),
      ),
      ...extracted.contexts,
    };
    final bool stateHasMounted =
        inheritStateFields &&
        _inStateClass &&
        !extracted.allParamNames.contains('mounted');
    final bool stateHasRef =
        inheritStateFields &&
        _inConsumerStateClass &&
        !extracted.allParamNames.contains('ref');
    final bool stateHasContext =
        inheritStateFields &&
        _inStateClass &&
        !extracted.allParamNames.contains('context');

    if (body.isAsynchronous) {
      final AsyncScopeInfo scope = AsyncScopeInfo(
        inStateClass: stateHasMounted,
        stateHasContext: stateHasContext,
        inConsumerStateClass: stateHasRef,
        widgetRefNames: Set<String>.of(nextRefs),
        contextNames: Set<String>.of(nextContexts),
      );
      body.accept(
        _AsyncBodyAnalyzer(
          ir: ir,
          reviewed: reviewed,
          scope: scope,
          problems: problems,
        ),
      );
    }

    final Set<String> prevRefs = _enclosingWidgetRefs;
    final Set<String> prevContexts = _enclosingContexts;
    final bool prevState = _inStateClass;
    final bool prevConsumer = _inConsumerStateClass;
    _enclosingWidgetRefs = nextRefs;
    _enclosingContexts = nextContexts;
    _inStateClass = stateHasMounted;
    _inConsumerStateClass = stateHasRef;
    body.visitChildren(this);
    _enclosingWidgetRefs = prevRefs;
    _enclosingContexts = prevContexts;
    _inStateClass = prevState;
    _inConsumerStateClass = prevConsumer;
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final ClassIR classIR =
        ir.classesByNode[node] ?? ClassIR.fromDeclaration(node);
    final bool prevState = _inStateClass;
    final bool prevConsumer = _inConsumerStateClass;
    _inStateClass = classIR.isStateClass;
    _inConsumerStateClass = classIR.isConsumerStateClass;
    super.visitClassDeclaration(node);
    _inStateClass = prevState;
    _inConsumerStateClass = prevConsumer;
  }

  @override
  void visitBlock(Block node) {
    for (final Statement stmt in node.statements) {
      stmt.accept(this);
      if (ir.statementAlwaysExits(stmt)) {
        break;
      }
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _analyzeIfAsync(
      node.body,
      node.parameters,
      inheritStateFields: !node.isStatic,
    );
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final bool isTopLevel = node.parent is CompilationUnit;
    _analyzeIfAsync(
      node.functionExpression.body,
      node.functionExpression.parameters,
      inheritStateFields: !isTopLevel && _inStateClass,
    );
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.parent is FunctionDeclaration) {
      return;
    }
    _analyzeIfAsync(
      node.body,
      node.parameters,
      inheritStateFields: _inStateClass,
    );
  }
}

/// Runs the Stage 4 `async-ref` pass over a shared [DartFileIR].
List<String> runAsyncRefPass(DartFileIR ir, {ReviewedLintCatalog? reviewed}) {
  if (ir.sourceUnit.isGenerated || ir.sourceUnit.unit == null) {
    return const <String>[];
  }
  final _AsyncRefUnitVisitor visitor = _AsyncRefUnitVisitor(ir, reviewed);
  ir.sourceUnit.unit!.accept(visitor);
  return visitor.problems;
}
