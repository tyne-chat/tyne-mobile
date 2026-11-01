import 'package:fluxer_app/core/instance/well_known_compat.dart';
import 'package:fluxer_app/core/observability/fluxer_observability.dart';

// Fork: a discovery document the app cannot parse has to reach Measure. Its
// callers fall back quietly (a saved copy, a stored push key), so v1.2.13 and
// v1.2.14 failed on every one of production's documents for 27 hours and nothing
// said so (tyne-chat/tyne#454, #458). The fallbacks stay as they are.

/// What is sent: the model and the field that failed. Never the original error,
/// because `CheckedFromJsonException` holds the whole document in `map`. Only
/// these two names are taken from its text, so a value in it cannot leave too.
class ForkDiscoveryParseFailure implements Exception {
  ForkDiscoveryParseFailure.from(Object error) : summary = _summarize(error);

  final String summary;

  static final RegExp _model = RegExp('Could not create `([^`]+)`');
  static final RegExp _field = RegExp('There is a problem with "([^"]+)"');

  static String _summarize(Object error) {
    final String text = error.toString();
    final String model = _model.firstMatch(text)?.group(1) ?? 'unknown model';
    final String field = _field.firstMatch(text)?.group(1) ?? 'unknown field';
    return '${error.runtimeType}: $model.$field';
  }

  @override
  String toString() => 'Could not parse the discovery document: $summary';
}

/// Reports the first failure of an app run: a refresh can repeat all day.
class ForkDiscoveryFailureReport {
  ForkDiscoveryFailureReport(this._record);

  final void Function(ForkDiscoveryParseFailure, StackTrace) _record;
  bool _reported = false;

  void report(Object error, StackTrace stackTrace) {
    if (_reported) {
      return;
    }
    _reported = true;
    _record(ForkDiscoveryParseFailure.from(error), stackTrace);
  }
}

void installForkDiscoveryFailureReport() {
  forkOnWellKnownParseFailure = ForkDiscoveryFailureReport((
    ForkDiscoveryParseFailure failure,
    StackTrace stackTrace,
  ) {
    FluxerObservability.instance.recordError(
      failure,
      source: 'instance_discovery',
      stackTrace: stackTrace,
    );
  }).report;
}
