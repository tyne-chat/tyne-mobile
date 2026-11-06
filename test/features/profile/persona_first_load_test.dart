// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: the first load a send waits for (tyne-chat/tyne#30). Sends repeated
// while the server refuses must not turn into a burst of requests, so each
// case counts the loads it starts.
import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/profile/providers/persona_first_load.dart';

void main() {
  late DateTime now;
  late FirstLoadGate gate;
  late int loads;

  setUp(() {
    now = DateTime(2026, 11, 6, 12);
    gate = FirstLoadGate(now: () => now);
    loads = 0;
  });

  Future<bool> Function() answering({required bool ok}) => () async {
    loads++;
    return ok;
  };

  test('a wait joins the load in flight instead of starting another', () async {
    final Completer<bool> answer = Completer<bool>();
    unawaited(
      gate.run(() {
        loads++;
        return answer.future;
      }),
    );

    final Future<bool> first = gate.wait(
      answering(ok: true),
      timeout: const Duration(seconds: 5),
    );
    final Future<bool> second = gate.wait(
      answering(ok: true),
      timeout: const Duration(seconds: 5),
    );
    answer.complete(true);

    expect(await first, isTrue);
    expect(await second, isTrue);
    expect(loads, 1);
  });

  test('a wait with nothing in flight starts one load', () async {
    expect(
      await gate.wait(answering(ok: true), timeout: const Duration(seconds: 5)),
      isTrue,
    );
    expect(loads, 1);
  });

  test(
    'after a failure, waits ask again only once the cooldown is over',
    () async {
      expect(
        await gate.wait(
          answering(ok: false),
          timeout: const Duration(seconds: 5),
        ),
        isFalse,
      );
      for (int i = 0; i < 20; i++) {
        expect(
          await gate.wait(
            answering(ok: true),
            timeout: const Duration(seconds: 5),
          ),
          isFalse,
        );
      }
      expect(loads, 1);

      now = now.add(const Duration(seconds: 10));
      expect(
        await gate.wait(
          answering(ok: true),
          timeout: const Duration(seconds: 5),
        ),
        isTrue,
      );
      expect(loads, 2);
    },
  );

  test('a load that throws counts as a failure', () async {
    expect(
      await gate.wait(() {
        loads++;
        return Future<bool>.error(StateError('offline'));
      }, timeout: const Duration(seconds: 5)),
      isFalse,
    );
    expect(
      await gate.wait(answering(ok: true), timeout: const Duration(seconds: 5)),
      isFalse,
    );
    expect(loads, 1);
  });

  test('a wait gives up after its timeout, and the load goes on', () {
    fakeAsync((FakeAsync async) {
      final Completer<bool> answer = Completer<bool>();
      bool? result;
      unawaited(
        gate
            .wait(() => answer.future, timeout: const Duration(seconds: 5))
            .then((bool ok) => result = ok),
      );

      async.elapse(const Duration(seconds: 4));
      expect(result, isNull);
      async.elapse(const Duration(seconds: 1));
      expect(result, isFalse);

      bool? later;
      unawaited(
        gate
            .wait(answering(ok: true), timeout: const Duration(seconds: 5))
            .then((bool ok) => later = ok),
      );
      answer.complete(true);
      async.flushMicrotasks();
      expect(later, isTrue);
      expect(loads, 0);
    });
  });

  test(
    'a reset forgets the failure and ignores loads started before it',
    () async {
      final Completer<bool> stale = Completer<bool>();
      unawaited(gate.run(() => stale.future));
      gate.reset();
      stale.complete(false);
      await pumpEventQueue();

      expect(
        await gate.wait(
          answering(ok: true),
          timeout: const Duration(seconds: 5),
        ),
        isTrue,
      );
      expect(loads, 1);
    },
  );
}
