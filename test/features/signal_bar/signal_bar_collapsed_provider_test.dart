import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/signal_bar/providers/signal_bar_collapsed_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyOfA = 'signal_bar_collapsed_v1_a';

/// One run of the app, signed in as [account]. A new one is a restart.
ProviderContainer _run([String? account]) {
  final ProviderContainer container = ProviderContainer();
  addTearDown(container.dispose);
  if (account != null) {
    container.read(currentUserIdProvider.notifier).set(account);
  }
  return container;
}

/// The value once the stored one is in, as the strip first reads it.
Future<bool> _settled(ProviderContainer container) async {
  container.read(signalBarCollapsedProvider);
  await pumpEventQueue();
  return container.read(signalBarCollapsedProvider);
}

Future<void> _press(ProviderContainer container) async {
  container.read(signalBarCollapsedProvider.notifier).toggle();
  await pumpEventQueue();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('starts expanded when nothing is stored', () async {
    expect(await _settled(_run('a')), isFalse);
  });

  test('stays collapsed across app restarts', () async {
    final ProviderContainer first = _run('a');
    await _settled(first);
    await _press(first);

    expect(await _settled(_run('a')), isTrue);
  });

  test('stays open across app restarts once reopened', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{_keyOfA: true});
    final ProviderContainer first = _run('a');
    await _settled(first);
    await _press(first);
    expect(first.read(signalBarCollapsedProvider), isFalse);

    expect(await _settled(_run('a')), isFalse);
  });

  test('is kept per account, and follows an account switch', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{_keyOfA: true});
    final ProviderContainer container = _run('a');
    expect(await _settled(container), isTrue);

    container.read(currentUserIdProvider.notifier).set('b');
    expect(container.read(signalBarCollapsedProvider), isFalse);
    expect(await _settled(container), isFalse);

    container.read(currentUserIdProvider.notifier).set('a');
    expect(await _settled(container), isTrue);
  });

  test('a value still being read does not land on the next account', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{_keyOfA: true});
    final ProviderContainer container = _run('a')
      ..read(signalBarCollapsedProvider);
    container.read(currentUserIdProvider.notifier).set('b');

    expect(await _settled(container), isFalse);
  });

  test('a press while the value is being read wins, and is stored', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{_keyOfA: false});
    // Already open, as in the running app: only then does the read land first.
    await SharedPreferences.getInstance();
    final ProviderContainer container = _run('a')
      ..read(signalBarCollapsedProvider);
    await _press(container);

    expect(await _settled(container), isTrue);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(_keyOfA), isTrue);
  });

  test('stores nothing when signed out, but still toggles', () async {
    final ProviderContainer container = _run();
    await _press(container);

    expect(container.read(signalBarCollapsedProvider), isTrue);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isEmpty);
  });
}
