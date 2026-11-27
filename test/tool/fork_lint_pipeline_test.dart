// Fork: tests for the unified mobile 4-stage compiler-pipeline linter
// (`tool/fork_lint.dart` and `tool/fork_lint/*`, tyne-chat/tyne#953).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/fork_lint/engine.dart';
import '../../tool/fork_lint/ir.dart';
import '../../tool/fork_lint_reviewed.dart';

void main() {
  test(
    'parses once and dispatches string, async-ref, and safety over shared IR',
    () {
      const String source = '''
class _BrokenState extends ConsumerState<BrokenWidget> {
  Future<void> save() async {
    await Future<void>.delayed(Duration.zero);
    Text('Unsaved changes');
    ref.read(otherProvider);
  }

  @override
  void dispose() {
    ref.read(coordProvider).cleanup();
    super.dispose();
  }
}
''';

      final List<String> parsedFiles = <String>[];
      final DartPipelineResult result = lintDartFileWithPipeline(
        'lib/broken.dart',
        source,
        null,
        onParse: parsedFiles.add,
      );

      expect(parsedFiles, <String>['lib/broken.dart']);
      expect(result.parseCount, 1);
      expect(result.ir, isNotNull);
      expect(result.problemsByLinter['string'], <String>[
        'lib/broken.dart:4:10: Text(): "Unsaved changes"',
      ]);
      expect(result.problemsByLinter['async-ref'], <String>[
        'lib/broken.dart:5:5: unguarded WidgetRef `ref` after `await`',
      ]);
      expect(result.problemsByLinter['safety'], <String>[
        'lib/broken.dart:10:5: [dispose-ref] `ref` read inside `State.dispose()` (cache the provider/notifier in a field in `initState` instead)',
      ]);
    },
  );

  test(
    'shares ClassIR, ControlFlowIR, and logOnlyPrivateNamedParams in DartFileIR',
    () {
      const String source = '''
class _PanelState extends ConsumerState<PanelWidget> {
  void _logOnly({required String detail}) {
    debugPrint(detail);
  }

  Future<void> work() async {
    _logOnly(detail: 'Internal trace detail');
    if (!mounted) {
      return;
    }
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }
    debugPrint(context.toString());
  }
}
''';

      final DartPipelineResult result = lintDartFileWithPipeline(
        'lib/panel.dart',
        source,
        null,
      );
      final DartFileIR ir = result.ir!;
      expect(ir.classesByNode.length, 1);
      final ClassIR cls = ir.classesByNode.values.single;
      expect(cls.name, '_PanelState');
      expect(cls.isConsumerStateClass, isTrue);
      expect(ir.logOnlyPrivateNamedParams, contains('_logOnly:detail'));
      expect(result.problems, isEmpty);
    },
  );

  test('evaluates multi-linter reviewed catalog stats and stale entries', () {
    final ReviewedLintCatalog catalog =
        ReviewedLintCatalog.fromEntries(<ReviewedLintEntry>[
          const ReviewedLintEntry(
            linter: 'safety',
            rule: 'dispose-ref',
            file: 'lib/sample.dart',
            enclosing: '_SampleState.dispose',
            reason: 'reviewed fixture',
          ),
          const ReviewedLintEntry(
            linter: 'async-ref',
            rule: 'async-ref',
            file: 'lib/sample.dart',
            enclosing: '_SampleState.missing',
            target: 'ref',
            reason: 'deliberately stale fixture',
          ),
        ]);

    const String source = '''
class _SampleState extends ConsumerState<SampleWidget> {
  @override
  void dispose() {
    ref.read(coordProvider).cleanup();
    super.dispose();
  }
}
''';

    lintDartFileWithPipeline(
      'lib/sample.dart',
      source,
      null,
      reviewed: catalog,
    );

    final ReviewedMultiSummary summary = evaluateReviewedForLinters(
      catalog,
      <String>['safety', 'async-ref'],
    );
    expect(summary.totalSuppressed, 1);
    expect(summary.byLinter['safety']?.suppressed, 1);
    expect(summary.byLinter['safety']?.staleEntries, isEmpty);
    expect(summary.allStaleEntries, hasLength(1));
    expect(summary.allStaleEntries.first.linter, 'async-ref');
    expect(reviewedCatalogExists(), isTrue);
  });

  test('produces violations and staleReviewed in one --audit-json pass', () {
    final Directory tempDir = Directory.systemTemp.createTempSync(
      'fork-lint-mobile-audit-',
    );
    try {
      final File catalogFile = File('${tempDir.path}/reviewed.json')
        ..writeAsStringSync(
          jsonEncode(<String, Object?>{
            'version': 1,
            'entries': <Map<String, Object?>>[
              <String, Object?>{
                'linter': 'async-ref',
                'rule': 'async-ref',
                'file': 'lib/nonexistent.dart',
                'enclosing': 'Missing.fn',
                'target': 'ref',
                'reason': 'stale fixture for audit-json test',
              },
            ],
          }),
        );

      final ProcessResult res = Process.runSync('dart', <String>[
        'tool/fork_lint.dart',
        '--linter',
        'safety,async-ref',
        '--reviewed',
        catalogFile.path,
        '--audit-json',
        'lib/features/settings/providers/preferences/time_format_providers.dart',
      ]);
      expect(res.exitCode, 0, reason: '${res.stderr}');
      final Map<String, Object?> decoded =
          jsonDecode(res.stdout as String) as Map<String, Object?>;
      final Map<String, Object?> linters =
          decoded['linters']! as Map<String, Object?>;
      final Map<String, Object?> safety =
          linters['safety']! as Map<String, Object?>;
      final Map<String, Object?> asyncRef =
          linters['async-ref']! as Map<String, Object?>;
      expect(safety['violations']! as List<Object?>, isNotEmpty);
      expect(asyncRef['violations']! as List<Object?>, isEmpty);
      final List<Object?> stale = asyncRef['staleReviewed']! as List<Object?>;
      expect(stale, hasLength(1));
      expect(stale.first! as String, contains('Stale reviewed entry:'));
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });
}
