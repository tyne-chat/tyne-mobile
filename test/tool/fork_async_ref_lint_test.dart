// Fork: tests for tool/fork_async_ref_lint.dart, the check for unguarded
// WidgetRef and BuildContext reads after `await` in the fork's code
// (tyne-chat/tyne#943).

import 'package:flutter_test/flutter_test.dart';

import '../../tool/fork_async_ref_lint.dart';

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
}
