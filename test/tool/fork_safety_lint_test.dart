// Fork: unit tests for tool/fork_safety_lint.dart (tyne-chat/tyne#945).

import 'package:flutter_test/flutter_test.dart';

import '../../tool/fork_lint_reviewed.dart';
import '../../tool/fork_safety_lint.dart';
import '../../tool/fork_string_lint.dart' as string_lint;

List<String> _lint(
  String source, {
  String file = 'lib/example.dart',
  Set<int>? lines,
  Set<String> rules = kAllSafetyRules,
}) => lintSafetySource(file, source, lines, rules: rules);

void main() {
  test('dispose-ref flags ref and context reads inside State.dispose()', () {
    final List<String> problems = _lint('''
class _ExampleState extends ConsumerState<ExampleWidget> {
  late final SomeCoordinator _coord;

  @override
  void initState() {
    super.initState();
    _coord = ref.read(coordProvider);
  }

  @override
  void dispose() {
    ref.read(coordProvider).cleanup();
    Navigator.of(context);
    _coord.cleanup();
    super.dispose();
  }
}
''');
    expect(problems, <String>[
      'lib/example.dart:12:5: [dispose-ref] `ref` read inside `State.dispose()` (cache the provider/notifier in a field in `initState` instead)',
      'lib/example.dart:13:18: [dispose-ref] `context` read inside `State.dispose()`',
    ]);
  });

  test('unmounted-listener flags unguarded setState/ref in deferred callbacks', () {
    expect(
      _lint('''
class _ExampleState extends ConsumerState<ExampleWidget> {
  void setup(Stream<int> stream) {
    ref.listenManual(activeChannelIdProvider, (prev, next) {
      ref.read(otherProvider);
    });
    stream.listen((value) {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(otherProvider);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(activeChannelIdProvider, (prev, next) {
      ref.read(otherProvider);
      setState(() {});
    });
    ref
      ..listen(activeChannelIdProvider, (prev, next) {
        ref.read(otherProvider);
      });
    return const SizedBox.shrink();
  }
}
'''),
      <String>[
        'lib/example.dart:4:7: [unmounted-listener] `ref` read in `listenManual` callback without `mounted` check',
        'lib/example.dart:7:7: [unmounted-listener] `setState` in `listen` callback without `mounted` check',
      ],
    );
  });

  test(
    'chat-layout flags bare LayoutBuilder in chat panel/list paths and sync layout mutations',
    () {
      final List<String> problems = _lint('''
class _PanelState extends ConsumerState<PanelWidget> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref.read(someNotifierProvider.notifier).state = 1;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        setState(() {});
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {});
        });
        return const SizedBox.shrink();
      },
    );
  }
}
''', file: 'lib/features/chat/presentation/widgets/channel/example_panel.dart');
      expect(problems, <String>[
        'lib/features/chat/presentation/widgets/channel/example_panel.dart:5:5: [chat-layout] synchronous `ref.read(someNotifierProvider.notifier).state = ...` inside `didChangeDependencies`',
        'lib/features/chat/presentation/widgets/channel/example_panel.dart:10:12: [chat-layout] bare `LayoutBuilder` in chat list/panel path (use `RebuildSafeLayoutBuilder`, or mark `// safety-lint-ignore: <reason>` if this subtree never holds `MessageList`)',
        'lib/features/chat/presentation/widgets/channel/example_panel.dart:12:9: [chat-layout] synchronous `setState` inside `LayoutBuilder` (defer to `addPostFrameCallback` with a `mounted` check)',
      ]);
    },
  );

  test('build-network flags direct Dio/repository calls in build()', () {
    expect(
      _lint('''
class ExampleTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(fluxerDioProvider).get('/users/@me');
    return FutureBuilder(
      future: ref.read(memberRepositoryProvider).fetchMember('g1', 'u1'),
      builder: (_, _) => GestureDetector(
        onTap: () => ref.read(fluxerDioProvider).post('/ack'),
      ),
    );
  }
}
'''),
      <String>[
        'lib/example.dart:4:5: [build-network] direct network call `ref.read(fluxerDioProvider).get()` inside `build()` (triggers a request per rebuild; see AGENTS.md "Network calls")',
        'lib/example.dart:6:15: [build-network] direct network call `ref.read(memberRepositoryProvider).fetchMember()` inside `build()` (triggers a request per rebuild; see AGENTS.md "Network calls")',
      ],
    );
  });

  test('keepalive-reset flags mutable fields not reset in keepAlive build()', () {
    expect(
      _lint(r'''
@Riverpod(keepAlive: true)
class MyKeptNotifier extends _$MyKeptNotifier {
  String? _currentGuildId;
  String? _staleTracker;
  final Map<String, int> _cache = <String, int>{};

  @override
  int build() {
    _currentGuildId = null;
    _cache.clear();
    return 0;
  }
}
'''),
      <String>[
        'lib/example.dart:4:11: [keepalive-reset] mutable field `_staleTracker` on `@Riverpod(keepAlive: true)` notifier `MyKeptNotifier` is not reset in `build()`',
      ],
    );
  });

  test('respects safety-lint-ignore with a non-empty reason', () {
    expect(
      _lint('''
class _ExampleState extends ConsumerState<ExampleWidget> {
  @override
  void dispose() {
    // safety-lint-ignore: verified safe in test
    ref.read(coordProvider);
    // safety-lint-ignore:
    Navigator.of(context);
    super.dispose();
  }
}
'''),
      <String>[
        'lib/example.dart:7:18: [dispose-ref] `context` read inside `State.dispose()`',
      ],
    );
  });

  test('treats ++/-- increments in keepAlive build() as field resets', () {
    expect(
      _lint(r'''
@Riverpod(keepAlive: true)
class MyCounterNotifier extends _$MyCounterNotifier {
  int _prefixGen = 0;
  int _postfixToken = 0;
  int _decremented = 10;
  int _thisPrefixed = 0;

  @override
  int build() {
    ++_prefixGen;
    _postfixToken++;
    --_decremented;
    this._thisPrefixed++;
    return _prefixGen;
  }
}
'''),
      isEmpty,
    );
  });

  test(
    'suppresses reviewed chat-layout, keepalive-reset, and string-lint entries across line shifts',
    () {
      final ReviewedLintCatalog
      catalog = ReviewedLintCatalog.fromEntries(<ReviewedLintEntry>[
        const ReviewedLintEntry(
          linter: 'safety',
          rule: 'chat-layout',
          file: 'lib/features/chat/presentation/widgets/messages/skeleton.dart',
          enclosing: 'LeafSkeleton.build',
          reason: 'pure leaf sizing builder',
        ),
        const ReviewedLintEntry(
          linter: 'safety',
          rule: 'keepalive-reset',
          file: 'lib/features/example_provider.dart',
          symbol: 'ReviewedNotifier.*',
          reason: 'onDispose tear-off cleans timers and monotonic counter',
        ),
        const ReviewedLintEntry(
          linter: 'string',
          file: 'lib/features/example_widget.dart',
          enclosing: 'ExampleWidget.build',
          target: 'Text()',
          reason: 'reviewed literal',
        ),
      ]);

      const String chatSource = '''
class LeafSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, _) => const SizedBox());
}
''';
      expect(
        lintSafetySource(
          'lib/features/chat/presentation/widgets/messages/skeleton.dart',
          '\n\n$chatSource',
          null,
          reviewed: catalog,
        ),
        isEmpty,
      );

      const String providerSource = r'''
@Riverpod(keepAlive: true)
class ReviewedNotifier extends _$ReviewedNotifier {
  int _nextId = 0;
  @override
  int build() => 0;
}

@Riverpod(keepAlive: true)
class UnreviewedNotifier extends _$UnreviewedNotifier {
  String? _leaked;
  @override
  int build() => 0;
}
''';
      expect(
        lintSafetySource(
          'lib/features/example_provider.dart',
          providerSource,
          null,
          reviewed: catalog,
        ),
        <String>[
          'lib/features/example_provider.dart:10:11: [keepalive-reset] mutable field `_leaked` on `@Riverpod(keepAlive: true)` notifier `UnreviewedNotifier` is not reset in `build()`',
        ],
      );

      expect(
        string_lint.lintSource(
          'lib/features/example_widget.dart',
          '''
class ExampleWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Text('Upstream brand');
}
''',
          null,
          reviewed: catalog,
        ),
        isEmpty,
      );

      expect(catalog.unmatchedEntries('safety'), isEmpty);
      expect(catalog.unmatchedEntries('string'), isEmpty);
      expect(
        () => ReviewedLintCatalog.fromJsonString(
          '{"version":1,"entries":[{"linter":"safety","file":"lib/a.dart","enclosing":"Foo.build","reason":"missing rule"}]}',
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'exempts sound keepAlive patterns (onDispose, ++ counters, try/finally mutexes, Future queues, whenComplete workers) (tyne-chat/tyne#950)',
    () {
      expect(
        _lint(r'''
@Riverpod(keepAlive: true)
class SafeMutexAndQueueNotifier extends _$SafeMutexAndQueueNotifier {
  int _nextId = 0;
  Timer? _timer;
  bool _busy = false;
  Future<void>? _inFlight;
  Future<void> _queue = Future<void>.value();
  Future<void>? _reconcileInFlight;
  bool _workerActive = false;
  Future<void> _workerIdle = Future<void>.value();

  @override
  int build() {
    ref.onDispose(_cancelTimer);
    return 0;
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  int nextId() => _nextId++;

  Future<void> runBusy() async {
    _busy = true;
    try {
      await Future<void>.delayed(Duration.zero);
    } finally {
      _busy = false;
    }
  }

  Future<void> runInFlight(Completer<void> completer) async {
    _inFlight = completer.future;
    try {
      await Future<void>.delayed(Duration.zero);
    } finally {
      try {
        await Future<void>.delayed(Duration.zero);
      } finally {
        _inFlight = null;
      }
    }
  }

  Future<void> enqueue(Future<void> Function() task) {
    final Future<void> previous = _queue;
    final Future<void> next = previous.then((_) => task());
    _queue = next;
    return next;
  }

  Future<void> reconcile() {
    final Future<void> run = Future<void>.value();
    _reconcileInFlight = run;
    return run.whenComplete(() {
      if (identical(_reconcileInFlight, run)) {
        _reconcileInFlight = null;
      }
    });
  }

  void pumpWorker() {
    _workerActive = true;
    _workerIdle = Future<void>.value().whenComplete(() {
      _workerActive = false;
    });
  }
}
'''),
        isEmpty,
      );
    },
  );

  test(
    'still flags conditional onDispose, un-reset mutexes, assigned ints, and unchained Future fields (tyne-chat/tyne#950)',
    () {
      final List<String> problems = _lint(r'''
@Riverpod(keepAlive: true)
class LeakyNotifier extends _$LeakyNotifier {
  Timer? _conditionalTimer;
  int _unusedCounter = 0;
  int _assignedCounter = 0;
  bool _unresetBusy = false;
  Future<void> _unchainedFuture = Future<void>.value();
  bool _notWorkerBool = false;
  Future<void> _unrelatedFuture = Future<void>.value();

  @override
  int build() {
    if (_assignedCounter > 0) {
      return 1;
    }
    ref.onDispose(() {
      _conditionalTimer?.cancel();
      _conditionalTimer = null;
    });
    return 0;
  }

  void mutate() {
    _assignedCounter = 5;
    _assignedCounter++;
    _unresetBusy = true;
    _unchainedFuture = Future<void>.delayed(Duration.zero);
    _unrelatedFuture = Future<void>.value().whenComplete(() {
      _notWorkerBool = false;
    });
  }
}
''');
      expect(problems, <String>[
        'lib/example.dart:3:10: [keepalive-reset] mutable field `_conditionalTimer` on `@Riverpod(keepAlive: true)` notifier `LeakyNotifier` is not reset in `build()`',
        'lib/example.dart:4:7: [keepalive-reset] mutable field `_unusedCounter` on `@Riverpod(keepAlive: true)` notifier `LeakyNotifier` is not reset in `build()`',
        'lib/example.dart:5:7: [keepalive-reset] mutable field `_assignedCounter` on `@Riverpod(keepAlive: true)` notifier `LeakyNotifier` is not reset in `build()`',
        'lib/example.dart:6:8: [keepalive-reset] mutable field `_unresetBusy` on `@Riverpod(keepAlive: true)` notifier `LeakyNotifier` is not reset in `build()`',
        'lib/example.dart:7:16: [keepalive-reset] mutable field `_unchainedFuture` on `@Riverpod(keepAlive: true)` notifier `LeakyNotifier` is not reset in `build()`',
        'lib/example.dart:8:8: [keepalive-reset] mutable field `_notWorkerBool` on `@Riverpod(keepAlive: true)` notifier `LeakyNotifier` is not reset in `build()`',
        'lib/example.dart:9:16: [keepalive-reset] mutable field `_unrelatedFuture` on `@Riverpod(keepAlive: true)` notifier `LeakyNotifier` is not reset in `build()`',
      ]);
    },
  );
}
