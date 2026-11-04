import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';

/// An account without personas, for upstream's widget tests that reach the
/// fork's persona code.
///
/// Upstream's test helpers sign an account in with a test database. A request
/// from a widget test then reads that account's settings from it on the way out
/// (`AcceptLanguageInterceptor`), and that stream leaves a timer behind when the
/// tree goes, which fails the test. With no personas the fork's code asks the
/// server for none, as upstream's code never does.
class ForkNoPersonas extends MyPersonasNotifier {
  @override
  AsyncValue<List<Persona>> build() => const AsyncData(<Persona>[]);

  @override
  Future<void> reloadSilently() async {}
}
