// Fork: tests for tool/fork_async_ref_lint.dart, the check for unguarded
// WidgetRef and BuildContext reads after `await` in the fork's code
// (tyne-chat/tyne#943).

import 'package:flutter_test/flutter_test.dart';

import '../../tool/fork_async_ref_lint.dart';
import '../../tool/fork_lint_reviewed.dart';

List<String> _lint(String source, [Set<int>? lines]) =>
    lintAsyncRefSource('lib/example.dart', source, lines);

void main() {
  test('flags unguarded WidgetRef and BuildContext reads after await', () {
    final List<String> problems = _lint('''
Future<List<String>> withEmojiPins(WidgetRef ref, String channelId) async {
  final pins = await ref.read(emojiPinsProvider.future);
  return rankingWithEmojiPins(ref.read(otherProvider), channelId);
}

Future<void> openSheet(BuildContext context) async {
  await handOffFluxerSheet(context);
  Navigator.of(context).pop();
}

class _RowState extends ConsumerState<RowWidget> {
  Future<void> toggle() async {
    await Future<void>.delayed(Duration.zero);
    ref.read(chatViewModelProvider.notifier).ping();
    ScaffoldMessenger.of(context);
  }
}
''');
    expect(problems, <String>[
      'lib/example.dart:3:31: unguarded WidgetRef `ref` after `await`',
      'lib/example.dart:8:16: unguarded BuildContext `context` after `await`',
      'lib/example.dart:14:5: unguarded WidgetRef `ref` after `await`',
      'lib/example.dart:15:26: unguarded BuildContext `context` after `await`',
    ]);
  });

  test('accepts mounted, context.mounted, and ref.context.mounted guards', () {
    expect(
      _lint('''
Future<List<String>> withEmojiPins(WidgetRef ref, String channelId) async {
  final pins = await ref.read(emojiPinsProvider.future);
  if (pins.isEmpty || !ref.context.mounted) {
    return const <String>[];
  }
  return rankingWithEmojiPins(ref.read(otherProvider), channelId);
}

Future<void> openSheet(BuildContext context) async {
  await handOffFluxerSheet(context);
  if (context.mounted) {
    Navigator.of(context).pop();
  }
}

class _RowState extends ConsumerState<RowWidget> {
  Future<void> toggle() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }
    ref.read(chatViewModelProvider.notifier).ping();
    ScaffoldMessenger.of(context);
  }
}
'''),
      isEmpty,
    );
  });

  test('invalidates earlier mounted guard after a subsequent await', () {
    final List<String> problems = _lint('''
class _RowState extends ConsumerState<RowWidget> {
  Future<void> twoSteps() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }
    ref.read(firstProvider);
    await Future<void>.delayed(Duration.zero);
    ref.read(secondProvider);
  }
}
''');
    expect(problems, <String>[
      'lib/example.dart:9:5: unguarded WidgetRef `ref` after `await`',
    ]);
  });

  test('ignores Riverpod Notifier Ref (not a WidgetRef) and sync closures', () {
    expect(
      _lint(r'''
class MyNotifier extends _$MyNotifier {
  Future<void> refreshData(Ref helperRef) async {
    await Future<void>.delayed(Duration.zero);
    ref.read(otherProvider);
    helperRef.read(otherProvider);
  }
}

class _RowState extends ConsumerState<RowWidget> {
  void syncHandler() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(firstProvider);
    });
  }
}
'''),
      isEmpty,
    );
  });

  test('respects async-ref-ignore with a non-empty reason and line filter', () {
    expect(
      _lint(
        '''
Future<void> f(BuildContext a, BuildContext b) async {
  await Future<void>.delayed(Duration.zero);
  // async-ref-ignore: root navigator context stays mounted for app lifetime
  Navigator.of(a);
  // async-ref-ignore:
  Navigator.of(b);
}
''',
        <int>{4, 6},
      ),
      <String>[
        'lib/example.dart:6:16: unguarded BuildContext `b` after `await`',
      ],
    );
  });

  test(
    'handles switch cases, conditional-await joins, and State context params',
    () {
      expect(
        _lint('''
Future<void> helper(BuildContext context, WidgetRef ref, int kind) async {
  switch (kind) {
    case 1:
      await handOffFluxerSheet(context);
      if (!context.mounted) return;
      ref.read(firstProvider);
    case 2:
      ref.read(secondProvider);
  }
}

class _SettingsState extends ConsumerState<SettingsWidget> {
  Future<void> deleteItem(BuildContext context, bool needsConfirm) async {
    if (needsConfirm) {
      if (!await confirm(context) || !mounted) {
        return;
      }
    }
    ref.read(firstProvider);
  }
}
'''),
        isEmpty,
      );
    },
  );

  test(
    'suppresses reviewed upstream findings across line shifts while keeping unreviewed siblings',
    () {
      final ReviewedLintCatalog catalog =
          ReviewedLintCatalog.fromEntries(<ReviewedLintEntry>[
            const ReviewedLintEntry(
              linter: 'async-ref',
              file: 'lib/example.dart',
              enclosing: 'safeFlow',
              target: 'ctx',
              reason: 'known-safe external lifetime',
            ),
          ]);
      const String source = '''
Future<void> safeFlow(BuildContext? ctx) async {
  await Future<void>.delayed(Duration.zero);
  if (ctx != null) {
    Navigator.of(ctx).pop();
  }
}

Future<void> unreviewedSibling(WidgetRef ref) async {
  await Future<void>.delayed(Duration.zero);
  ref.read(someProvider);
}
''';
      final List<String> problems = lintAsyncRefSource(
        'lib/example.dart',
        source,
        null,
        reviewed: catalog,
      );
      expect(problems, <String>[
        'lib/example.dart:10:3: unguarded WidgetRef `ref` after `await`',
      ]);
      expect(catalog.unmatchedEntries('async-ref'), isEmpty);

      // Simulate an upstream rebase shifting line numbers downward.
      final ReviewedLintCatalog shiftedCatalog =
          ReviewedLintCatalog.fromEntries(catalog.entries);
      final List<String> shiftedProblems = lintAsyncRefSource(
        'lib/example.dart',
        '\n\n\n$source',
        null,
        reviewed: shiftedCatalog,
      );
      expect(shiftedProblems, <String>[
        'lib/example.dart:13:3: unguarded WidgetRef `ref` after `await`',
      ]);
      expect(shiftedCatalog.unmatchedEntries('async-ref'), isEmpty);
    },
  );

  test(
    'allows null checks, = reassignments that clear old guards, De Morgan exits, || chains, and dead exit code (tyne-chat/tyne#950)',
    () {
      expect(
        _lint('''
Future<void> safePatterns(
  BuildContext? context,
  WidgetRef ref,
  bool flag,
) async {
  await Future<void>.delayed(Duration.zero);
  if (context == null || !context.mounted) {
    return;
  }
  if (identical(context, null)) {
    return;
  }
  await handOffFluxerSheet(
    context != null && context.mounted ? context : null,
  );
  final BuildContext? other = context != null && context.mounted
      ? context
      : null;
  if (other == null || !other.mounted) {
    return;
  }
  Navigator.of(other).pop();
}

Future<void> deMorganAndReassignment(
  BuildContext? context,
  BuildContext? Function() nextRoot,
) async {
  await Future<void>.delayed(Duration.zero);
  if (context != null && !context.mounted) {
    return;
  }
  BuildContext? ctx = context;
  if (ctx == null || !ctx.mounted) {
    await Future<void>.delayed(Duration.zero);
    ctx = nextRoot();
  }
  if (ctx == null || !ctx.mounted) {
    return;
  }
  Navigator.of(ctx).pop();
}

class _GateState extends ConsumerState<GateWidget> {
  Future<void> check(bool ready, String userId) async {
    final res = await fetchResult();
    if (!mounted || ready || ref.read(userIdProvider) != userId || ref.read(extraProvider) != null) {
      return;
    }
    return;
    ref.read(deadProvider);
  }
}

Future<void> switchDeadCode(BuildContext context, int kind) async {
  switch (kind) {
    case 1:
      await handOffFluxerSheet(context);
      return;
      Navigator.of(context).pop();
  }
}
'''),
        isEmpty,
      );

      final List<String> unsoundCases = _lint('''
Future<void> reassignedWithoutRecheck(
  BuildContext? ctx,
  BuildContext? Function() nextRoot,
) async {
  await Future<void>.delayed(Duration.zero);
  if (ctx == null || !ctx.mounted) {
    return;
  }
  ctx = nextRoot();
  Navigator.of(ctx!).pop();
}

Future<void> compoundAssignmentStillReads(BuildContext? ctx) async {
  await Future<void>.delayed(Duration.zero);
  ctx ??= fallbackContext();
}
''');
      expect(unsoundCases, <String>[
        'lib/example.dart:10:16: unguarded BuildContext `ctx` after `await`',
        'lib/example.dart:15:3: unguarded BuildContext `ctx` after `await`',
      ]);
    },
  );

  test('validates reviewed catalog schema and loads checked-in catalog', () {
    expect(
      () => ReviewedLintCatalog.fromJsonString(
        '{"version":1,"entries":[{"linter":"async-ref","file":"lib/a.dart","enclosing":"fn","target":"ctx","reason":"   "}]}',
      ),
      throwsFormatException,
    );
    expect(
      () => ReviewedLintCatalog.fromJsonString(
        '{"version":1,"entries":[{"linter":"async-ref","file":"lib/a.dart","reason":"missing selector"}]}',
      ),
      throwsFormatException,
    );
    expect(
      () => ReviewedLintCatalog.fromJsonString(
        '{"version":1,"entries":[{"linter":"async-ref","file":"lib/a.dart","enclosing":"fn","enclosingMethod":"typo","reason":"bad key"}]}',
      ),
      throwsFormatException,
    );

    final ReviewedLintCatalog checkedIn = ReviewedLintCatalog.load();
    expect(checkedIn.entries, isNotEmpty);
  });
}
