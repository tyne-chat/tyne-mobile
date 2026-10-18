// Fork: tests of tool/fork_string_lint.dart, the check for hard-coded
// user-facing strings in the fork's code (tyne-chat/tyne#184).

import 'package:flutter_test/flutter_test.dart';

import '../../tool/fork_string_lint.dart';

List<String> _lint(String source, [Set<int>? lines]) =>
    lintSource('lib/example.dart', source, lines);

void main() {
  test('reports literals where people read them', () {
    final List<String> problems = _lint(r'''
void f(BuildContext context, Ref ref, int n) {
  Text('Alice');
  ref.read(toastProvider.notifier).show(const FluxerToast(message: 'Active persona cleared'));
  FluxerButton.secondary(label: 'Add Tag Pair ($n/5)');
  state = state.copyWith(errorMessage: 'Failed to change message persona');
  throw Exception(userFacingErrorMessage(e, 'Failed to change persona'));
  final String tooltipText = 'Account: @name';
  Semantics(label: busy ? 'Saving now' : label);
}
''');
    expect(problems, <String>[
      'lib/example.dart:2:8: Text(): "Alice"',
      'lib/example.dart:3:68: argument message: "Active persona cleared"',
      'lib/example.dart:4:33: argument label: "Add Tag Pair (/5)"',
      'lib/example.dart:5:40: argument errorMessage: "Failed to change message persona"',
      'lib/example.dart:6:45: userFacingErrorMessage(): "Failed to change persona"',
      'lib/example.dart:7:30: variable tooltipText: "Account: @name"',
      'lib/example.dart:8:27: argument label: "Saving now"',
    ]);
  });

  test('leaves strings nobody reads alone', () {
    expect(
      _lint('''
void f() {
  debugPrint('[ChatViewModel] Failed to change message persona');
  _logger.warning('Failed to load personas');
  throw StateError('Persona list is not loaded');
  const ValueKey<String>('Persona row');
  final String debugLabel = 'Persona list';
  if (mode == 'Manual mode') {}
  FluxerButton.secondary(label: 'persona-row');
}

@FluxerWidgetPreview(name: 'Example')
Widget examplePreview() => const Text('Invite friends');
'''),
      isEmpty,
    );
  });

  test('skips a literal marked i18n-ignore, with a reason', () {
    expect(
      _lint('''
void f() {
  // i18n-ignore: a process name, not text in the app
  Text('Example GIF preview');
  Text('Network error'); // i18n-ignore: shown to developers only
  // i18n-ignore:
  Text('Active persona cleared');
}
'''),
      <String>['lib/example.dart:6:8: Text(): "Active persona cleared"'],
    );
  });

  test(
    'lets an i18n-ignore comment above a wrapped declaration cover its literal',
    () {
      expect(
        _lint('''
// i18n-ignore: a process name, not text in the app
const String playerTitle =
    'Example GIF preview';
const String otherTitle =
    'Example GIF preview';
'''),
        <String>[
          'lib/example.dart:5:5: variable otherTitle: "Example GIF preview"',
        ],
      );
    },
  );

  test('checks only the lines it is given', () {
    expect(
      _lint(
        '''
void f() {
  Text('Failed to set active persona');
  Text('Failed to clear active persona');
}
''',
        <int>{3},
      ),
      <String>[
        'lib/example.dart:3:8: Text(): "Failed to clear active persona"',
      ],
    );
  });

  test('skips generated files', () {
    expect(
      _lint('''
// GENERATED CODE - DO NOT MODIFY BY HAND
void f() => Text('Failed to save persona');
'''),
      isEmpty,
    );
  });
}
