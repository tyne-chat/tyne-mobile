// Fork: finds unguarded `WidgetRef` and `BuildContext` uses after `await` in
// the fork's code, which neither `flutter analyze` nor `riverpod_lint` catches
// here (`use_build_context_synchronously` is off in upstream's analysis
// options, and ignores `WidgetRef` altogether) (tyne-chat/tyne#943).
//
//   dart run tool/fork_async_ref_lint.dart [--upstream <git ref>] [--all] [<file>...]
//
// Checks `async` methods, functions and closures in the fork's files and
// changed lines under `lib/` against the merge base with `<git ref>` (default
// `upstream/canary`), working tree and untracked files included; `--all`
// checks every line of the files given (or every file under `lib/`).
//
// Tracked targets per `async` body:
// - `WidgetRef` parameters, and `ref` inside `ConsumerState` subclasses;
// - `BuildContext` parameters, and `context` inside `State` / `ConsumerState`
//   subclasses (unless shadowed by a non-`BuildContext` local).
//
// After an `await`, a tracked target must be guarded (`mounted`,
// `<ctx>.mounted`, or `<ref>.context.mounted`) before it is read again, and
// each new `await` invalidates earlier guards. A false positive that is safe
// for an external reason gets `// async-ref-ignore: <reason>` on its line or
// the line above.
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
final RegExp _ignore = RegExp(r'async-ref-ignore:\s*\S');

final RegExp _stateSuperclass = RegExp(
  r'^(State|ConsumerState|_?ConsumerState)\b',
);
final RegExp _consumerStateSuperclass = RegExp(r'^(ConsumerState)\b');

class _ScopeInfo {
  const _ScopeInfo({
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

bool _statementAlwaysExits(Statement stmt) {
  if (stmt is ReturnStatement ||
      stmt is ThrowExpression ||
      stmt is BreakStatement ||
      stmt is ContinueStatement) {
    return true;
  }
  if (stmt is ExpressionStatement && stmt.expression is ThrowExpression) {
    return true;
  }
  if (stmt is Block) {
    return stmt.statements.any(_statementAlwaysExits);
  }
  if (stmt is IfStatement && stmt.elseStatement != null) {
    return _statementAlwaysExits(stmt.thenStatement) &&
        _statementAlwaysExits(stmt.elseStatement!);
  }
  return false;
}

/// Names guarded when [condition] is TRUE (e.g. `if (context.mounted) { ... }`).
Set<String> _positivelyGuardedTargets(Expression condition, _ScopeInfo scope) {
  final Expression unwrapped = condition.unParenthesized;
  if (unwrapped is SimpleIdentifier && unwrapped.name == 'mounted') {
    if (scope.inStateClass) {
      return <String>{'__state_mounted__'};
    }
    return const <String>{};
  }
  if (unwrapped is PrefixedIdentifier &&
      unwrapped.identifier.name == 'mounted') {
    final String target = unwrapped.prefix.name;
    if (target == 'this' && scope.inStateClass) {
      return <String>{'__state_mounted__'};
    }
    if (scope.contextNames.contains(target) ||
        (scope.stateHasContext && target == 'context')) {
      return <String>{target};
    }
  }
  if (unwrapped is PropertyAccess && unwrapped.propertyName.name == 'mounted') {
    final Expression? target = unwrapped.target;
    if (target is ThisExpression && scope.inStateClass) {
      return <String>{'__state_mounted__'};
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
      ..._positivelyGuardedTargets(unwrapped.leftOperand, scope),
      ..._positivelyGuardedTargets(unwrapped.rightOperand, scope),
    };
  }
  return const <String>{};
}

/// Names guarded for the rest of a block when `if (condition) return;` exits.
Set<String> _negatedExitGuardedTargets(Expression condition, _ScopeInfo scope) {
  final Expression unwrapped = condition.unParenthesized;
  if (unwrapped is PrefixExpression && unwrapped.operator.lexeme == '!') {
    return _positivelyGuardedTargets(unwrapped.operand, scope);
  }
  if (unwrapped is BinaryExpression && unwrapped.operator.lexeme == '||') {
    return <String>{
      ..._negatedExitGuardedTargets(unwrapped.leftOperand, scope),
      ..._negatedExitGuardedTargets(unwrapped.rightOperand, scope),
    };
  }
  if (unwrapped is ConditionalExpression) {
    final Set<String> a = _negatedExitGuardedTargets(
      unwrapped.thenExpression,
      scope,
    );
    final Set<String> b = _negatedExitGuardedTargets(
      unwrapped.elseExpression,
      scope,
    );
    if (a.isNotEmpty || b.isNotEmpty) {
      return <String>{...a, ...b};
    }
  }
  return const <String>{};
}

class _AsyncBodyAnalyzer extends RecursiveAstVisitor<void> {
  _AsyncBodyAnalyzer({
    required this.file,
    required this.lineInfo,
    required this.lines,
    required this.ignored,
    required this.scope,
    required this.problems,
  });

  final String file;
  final LineInfo lineInfo;
  final Set<int>? lines;
  final Set<int> ignored;
  final _ScopeInfo scope;
  final List<String> problems;

  bool _seenAwait = false;
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

  bool _isCheckingMountedItself(SimpleIdentifier node) {
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

  bool _isIdentifierRead(SimpleIdentifier node) {
    if (node.inDeclarationContext()) {
      return false;
    }
    final AstNode? parent = node.parent;
    if (parent is Label) {
      return false;
    }
    // Property name on another target (`foo.context` or `foo.ref`), except
    // `this.context` / `this.ref`.
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

  void _report(AstNode node, String kind, String name) {
    final CharacterLocation loc = lineInfo.getLocation(node.offset);
    final int line = loc.lineNumber;
    if (lines != null && !lines!.contains(line)) {
      return;
    }
    if (ignored.contains(line)) {
      return;
    }
    problems.add(
      '$file:$line:${loc.columnNumber}: unguarded $kind `$name` after `await`',
    );
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Nested closures execute on their own schedule; outer visitor walks them
    // separately with their own parameters and async state.
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    // Handled by the outer unit visitor.
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    node.initializer?.accept(this);
    final String name = node.name.lexeme;
    // Track local declarations that shadow `State.context` / `State.ref`.
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
  void visitAwaitExpression(AwaitExpression node) {
    // Evaluate operand BEFORE the await suspends!
    node.expression.accept(this);
    _seenAwait = true;
    _guarded.clear();
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (node.operator.lexeme == '&&') {
      node.leftOperand.accept(this);
      final Set<String> added = _positivelyGuardedTargets(
        node.leftOperand,
        scope,
      );
      final Set<String> saved = Set<String>.of(_guarded);
      _guarded.addAll(added);
      node.rightOperand.accept(this);
      if (_seenAwait) {
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
    final Set<String> pos = _positivelyGuardedTargets(node.condition, scope);
    final Set<String> neg = _negatedExitGuardedTargets(node.condition, scope);

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
    final Set<String> posGuards = _positivelyGuardedTargets(
      node.expression,
      scope,
    );
    final Set<String> exitGuards = _negatedExitGuardedTargets(
      node.expression,
      scope,
    );

    final bool savedAwait = _seenAwait;
    final Set<String> savedGuarded = Set<String>.of(_guarded);

    _guarded.addAll(posGuards);
    node.thenStatement.accept(this);
    final bool thenAwait = _seenAwait;
    final Set<String> thenGuarded = Set<String>.of(_guarded);
    final bool thenExits = _statementAlwaysExits(node.thenStatement);

    if (node.elseStatement == null) {
      if (thenExits) {
        // `if (!mounted) return;` -> falling through keeps savedAwait and gains
        // exitGuards!
        _seenAwait = savedAwait;
        _guarded
          ..clear()
          ..addAll(savedGuarded)
          ..addAll(exitGuards);
      } else if (!savedAwait && thenAwait) {
        // Skip path never awaited (still mounted); `then` path awaited and
        // holds `thenGuarded` at fall-through.
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
    final bool elseExits = _statementAlwaysExits(node.elseStatement!);

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
      }
      final bool caseExits = member.statements.any(_statementAlwaysExits);
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
        !_isIdentifierRead(node) ||
        _isCheckingMountedItself(node)) {
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

class _UnitVisitor extends RecursiveAstVisitor<void> {
  _UnitVisitor(this.file, this.lineInfo, this.lines, this.ignored);

  final String file;
  final LineInfo lineInfo;
  final Set<int>? lines;
  final Set<int> ignored;
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
      final _ScopeInfo scope = _ScopeInfo(
        inStateClass: stateHasMounted,
        stateHasContext: stateHasContext,
        inConsumerStateClass: stateHasRef,
        widgetRefNames: Set<String>.of(nextRefs),
        contextNames: Set<String>.of(nextContexts),
      );
      body.accept(
        _AsyncBodyAnalyzer(
          file: file,
          lineInfo: lineInfo,
          lines: lines,
          ignored: ignored,
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
    final String? superclass = node.extendsClause?.superclass.name.lexeme;
    final bool prevState = _inStateClass;
    final bool prevConsumer = _inConsumerStateClass;
    _inStateClass = superclass != null && _stateSuperclass.hasMatch(superclass);
    _inConsumerStateClass =
        superclass != null && _consumerStateSuperclass.hasMatch(superclass);
    super.visitClassDeclaration(node);
    _inStateClass = prevState;
    _inConsumerStateClass = prevConsumer;
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

/// Returns unguarded post-`await` `WidgetRef` / `BuildContext` uses in [source]
/// on [lines] (`null` checks every line).
List<String> lintAsyncRefSource(String file, String source, Set<int>? lines) {
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
  final _UnitVisitor visitor = _UnitVisitor(
    file,
    result.lineInfo,
    lines,
    ignored,
  );
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
      lintAsyncRefSource(file, File(file).readAsStringSync(), targets[file]),
    );
  }
  problems.forEach(print);
  if (problems.isNotEmpty) {
    stderr.writeln(
      '\n${problems.length} unguarded WidgetRef/BuildContext read(s) after '
      '`await`. Pre-capture providers before `await`, guard with `mounted` / '
      '`context.mounted` / `ref.context.mounted`, or mark with '
      '`// async-ref-ignore: <reason>`.',
    );
    exit(1);
  }
}
