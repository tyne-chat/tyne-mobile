import 'dart:async';

import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_dart/export.dart';

typedef GuildCommandPreviewFetch =
    Future<GuildCommandPreviewResponseSchema> Function({
      required String template,
      required String input,
    });

/// Fork: a script's preview, which only the server can fill in. As on the web:
/// at most one request per 500 ms of typing, and a failed one waits for the
/// next edit, keeping the last preview meanwhile.
class GuildCommandScriptPreview extends ChangeNotifier {
  GuildCommandScriptPreview(this._fetch);

  static const Duration _typingDelay = Duration(milliseconds: 500);

  final GuildCommandPreviewFetch _fetch;

  GuildCommandPreviewResponseSchema? _result;
  String? _template;
  String _input = '';
  Timer? _timer;
  int _latest = 0;
  bool _disposed = false;

  /// The last answer, or null when there is none to show.
  GuildCommandPreviewResponseSchema? get result => _result;

  /// Previews [template], or nothing when it is null. The same text again
  /// sends nothing.
  void update({required String? template, required String input}) {
    if (template == _template && input == _input) {
      return;
    }
    _template = template;
    _input = input;
    _latest++;
    _timer?.cancel();
    if (template != null) {
      _timer = Timer(_typingDelay, () => unawaited(_request(_latest)));
    } else if (_result != null) {
      _result = null;
      notifyListeners();
    }
  }

  /// The same preview once more, at once: a script may pick at random.
  void runAgain() {
    _timer?.cancel();
    _latest++;
    if (_template != null) {
      unawaited(_request(_latest));
    }
  }

  Future<void> _request(int request) async {
    try {
      final GuildCommandPreviewResponseSchema result = await _fetch(
        template: _template!,
        input: _input,
      );
      if (request == _latest && !_disposed) {
        _result = result;
        notifyListeners();
      }
    } on Exception {
      // Keeps the last preview until the next edit asks again.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
