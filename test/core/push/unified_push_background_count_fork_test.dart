import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/push/unified_push/fork_unified_push_background_count.dart';

void main() {
  final Future<void> Function(int handled) original =
      forkReportUnifiedPushHandled;
  late List<int> reported;

  setUp(() {
    reported = <int>[];
    forkReportUnifiedPushHandled = (int handled) async {
      reported.add(handled);
    };
    resetForkUnifiedPushHandledCount();
  });

  tearDown(() {
    forkReportUnifiedPushHandled = original;
    resetForkUnifiedPushHandledCount();
  });

  test(
    'the background isolate reports a running count after each push',
    () async {
      await forkNoteUnifiedPushMessageHandled(backgroundMode: true);
      await forkNoteUnifiedPushMessageHandled(backgroundMode: true);
      await forkNoteUnifiedPushMessageHandled(backgroundMode: true);

      expect(reported, <int>[1, 2, 3]);
      expect(forkUnifiedPushHandledCount, 3);
    },
  );

  test('the main app counts but reports nothing', () async {
    await forkNoteUnifiedPushMessageHandled(backgroundMode: false);

    expect(reported, isEmpty);
    expect(forkUnifiedPushHandledCount, 1);
  });
}
