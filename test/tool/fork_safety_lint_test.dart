// Fork: unit tests for tool/fork_safety_lint.dart (tyne-chat/tyne#945).

import 'package:flutter_test/flutter_test.dart';

import '../../tool/fork_safety_lint.dart';

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
}
