// Fork: the shape of the web app's tracking URL rules (TrackingUrlRules.ts in tyne), which
// tool/gen_fork_tracking_url_rules.dart turns into generated/fork_tracking_url_rules.dart
// (tyne-chat/tyne#844). Field names follow the web's; see fork_tracking_url_sanitizer.dart for
// what each does.

/// A JavaScript regular expression: its source and flags (`g`, `i`, `m`).
class ForkJsRegExp {
  const ForkJsRegExp(this.source, [this.flags = '']);

  final String source;
  final String flags;

  bool get global => flags.contains('g');
}

class ForkTrackingUrlAmpRule {
  const ForkTrackingUrlAmpRule({
    this.regex,
    this.replaceText,
    this.replacePattern,
    this.replaceWith,
    this.sliceTrailing,
  });

  final ForkJsRegExp? regex;

  /// `replace.text` when the web gives a string, [replacePattern] when it gives a regex.
  final String? replaceText;
  final ForkJsRegExp? replacePattern;
  final String? replaceWith;
  final String? sliceTrailing;
}

class ForkTrackingUrlDecodeRule {
  const ForkTrackingUrlDecodeRule({
    this.param,
    this.jsonKey,
    this.encoding,
    this.targetPath = false,
    this.handler,
  });

  final String? param;
  final String? jsonKey;

  /// The web's `TrackingURLEncoding` value, such as `base64`.
  final String? encoding;
  final bool targetPath;

  /// The web's `TrackingURLHandler` value, such as `patchbot.io`.
  final String? handler;
}

class ForkTrackingUrlRule {
  const ForkTrackingUrlRule({
    required this.name,
    required this.match,
    this.matchUrl = false,
    this.hosts,
    this.removeParams = const [],
    this.removeFromPath = const [],
    this.exclude = const [],
    this.redirectParam,
    this.amp,
    this.decode,
    this.allowParams = const [],
    this.removeEmptyParamValues = false,
  });

  final String name;
  final ForkJsRegExp match;
  final bool matchUrl;
  final List<String>? hosts;
  final List<String> removeParams;
  final List<ForkJsRegExp> removeFromPath;
  final List<ForkJsRegExp> exclude;
  final String? redirectParam;
  final ForkTrackingUrlAmpRule? amp;
  final ForkTrackingUrlDecodeRule? decode;
  final List<String> allowParams;
  final bool removeEmptyParamValues;
}
