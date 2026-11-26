// Fork: AST safety checks for the mobile rules in AGENTS.md and
// lib/features/chat/AGENTS.md (tyne-chat/tyne#945):
//
//   dart run tool/fork_safety_lint.dart [--upstream <git ref>] [--all] [--rule <r1,r2>] [<file>...]
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
//    mutable non-final instance fields are not reset in `build()`.
//
// Suppress a deliberate exception with `// safety-lint-ignore: <reason>` on its
// line or the line above.
// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

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
final RegExp _chatPath = RegExp(r'(^|/)lib/features/chat/');
final RegExp _chatPanelOrListPath = RegExp(
  r'(^|/)lib/features/chat/presentation/(pages/|widgets/(channel|messages)/)',
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

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final Expression lhs = node.leftHandSide;
    if (lhs is SimpleIdentifier) {
      onFieldTouched(lhs.name);
    } else if (lhs is PropertyAccess && lhs.target is ThisExpression) {
      onFieldTouched(lhs.propertyName.name);
    } else if (lhs is PrefixedIdentifier && lhs.prefix.name == 'this') {
      onFieldTouched(lhs.identifier.name);
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final String method = node.methodName.name;
    final Expression? target = node.target;
    if (method == 'clear' || method == 'reset' || method == 'cancel') {
      if (target is SimpleIdentifier) {
        onFieldTouched(target.name);
      } else if (target is PropertyAccess && target.target is ThisExpression) {
        onFieldTouched(target.propertyName.name);
      } else if (target is PrefixedIdentifier && target.prefix.name == 'this') {
        onFieldTouched(target.identifier.name);
      }
    }
    if (target == null || target is ThisExpression) {
      onHelperCalled(method);
    }
    super.visitMethodInvocation(node);
  }
}

class _SafetyVisitor extends RecursiveAstVisitor<void> {
  _SafetyVisitor({
    required this.file,
    required this.lineInfo,
    required this.lines,
    required this.ignored,
    required this.enabledRules,
  });

  final String file;
  final LineInfo lineInfo;
  final Set<int>? lines;
  final Set<int> ignored;
  final Set<String> enabledRules;
  final List<String> problems = <String>[];

  bool _inStateClass = false;
  bool _inConsumerStateClass = false;
  bool _inWidgetClass = false;
  bool _inDisposeMethod = false;
  bool _inDidChangeDependencies = false;
  bool _inBuildMethod = false;

  void _report(AstNode node, String rule, String message) {
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
    final List<VariableDeclaration> mutableFields = <VariableDeclaration>[];
    for (final ClassMember member
        in node.body.childEntities.whereType<ClassMember>()) {
      if (member is MethodDeclaration) {
        methods[member.name.lexeme] = member;
      } else if (member is FieldDeclaration &&
          !member.isStatic &&
          !member.fields.isFinal &&
          !member.fields.isConst) {
        mutableFields.addAll(member.fields.variables);
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
    );
    final String className = node.classKeyword.next?.lexeme ?? '<unnamed>';
    for (final VariableDeclaration field in mutableFields) {
      final String fieldName = field.name.lexeme;
      if (!resetInBuild.contains(fieldName)) {
        _report(
          field,
          'keepalive-reset',
          'mutable field `$fieldName` on `@Riverpod(keepAlive: true)` '
              'notifier `$className` is not reset in `build()`',
        );
      }
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
/// checks every line) and [rules] (defaults to [kAllSafetyRules]).
List<String> lintSafetySource(
  String file,
  String source,
  Set<int>? lines, {
  Set<String> rules = kAllSafetyRules,
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
    lines: lines,
    ignored: ignored,
    enabledRules: rules,
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
  final int ruleIndex = args.indexOf('--rule');
  final Set<String> rules = ruleIndex == -1
      ? kAllSafetyRules
      : args[ruleIndex + 1]
            .split(',')
            .map((String s) => s.trim())
            .where((String s) => s.isNotEmpty)
            .toSet();
  final List<String> given = <String>[
    for (int i = 0; i < args.length; i++)
      if (!args[i].startsWith('--') &&
          (i == 0 || (args[i - 1] != '--upstream' && args[i - 1] != '--rule')))
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
      lintSafetySource(
        file,
        File(file).readAsStringSync(),
        targets[file],
        rules: rules,
      ),
    );
  }
  problems.forEach(print);
  if (problems.isNotEmpty) {
    stderr.writeln(
      '\n${problems.length} fork safety lint violation(s). Fix the code per '
      'AGENTS.md, or mark a deliberate exception with '
      '`// safety-lint-ignore: <reason>`.',
    );
    exit(1);
  }
}
