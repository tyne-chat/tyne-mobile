import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/utils/messages/fork_tracking_url_rule.dart';
import 'package:fluxer_app/features/chat/utils/messages/generated/fork_tracking_url_rules.dart';

// Fork: package imports cannot reach tool/, so the parser comes in by path.
import '../../../../../tool/fork_tracking_url_rules/ts_rules_parser.dart';

// Fork: the generated rule list must match the web app's TrackingUrlRules.ts in the `fluxer`
// submodule (tyne-chat/tyne#844). When this fails after the submodule moved, run
// `dart run tool/gen_fork_tracking_url_rules.dart`.
void main() {
  final File source = File(forkTrackingUrlRulesSourcePath);

  test(
    'generated tracking URL rules match the web app',
    () {
      final List<Map<String, Object>> expected = parseTrackingUrlRules(
        source.readAsStringSync(),
      );
      expect(
        forkTrackingUrlRules.map(_describe).toList(),
        expected.map(_normalize).toList(),
      );
    },
    skip: source.existsSync()
        ? false
        : 'the fluxer submodule is not checked out',
  );
}

String _regex(ForkJsRegExp r) => '/${r.source}/${r.flags}';

Map<String, Object> _describe(ForkTrackingUrlRule rule) {
  final ForkTrackingUrlAmpRule? amp = rule.amp;
  final ForkTrackingUrlDecodeRule? decode = rule.decode;
  final ForkJsRegExp? ampRegex = amp?.regex;
  final ForkJsRegExp? replacePattern = amp?.replacePattern;
  final String? replaceText = amp?.replaceText;
  final String? replaceWith = amp?.replaceWith;
  final String? sliceTrailing = amp?.sliceTrailing;
  final List<String>? hosts = rule.hosts;
  final String? redirectParam = rule.redirectParam;
  return {
    'name': rule.name,
    'match': _regex(rule.match),
    if (rule.matchUrl) 'matchURL': true,
    'hosts': ?hosts,
    if (rule.removeParams.isNotEmpty) 'removeParams': rule.removeParams,
    if (rule.removeFromPath.isNotEmpty)
      'removeFromPath': rule.removeFromPath.map(_regex).toList(),
    if (rule.exclude.isNotEmpty) 'exclude': rule.exclude.map(_regex).toList(),
    'redirectParam': ?redirectParam,
    if (amp != null)
      'AMP': {
        if (ampRegex != null) 'regex': _regex(ampRegex),
        if (replaceText != null || replacePattern != null)
          'replace': {
            'text': replaceText ?? _regex(replacePattern!),
            'with': ?replaceWith,
          },
        'sliceTrailing': ?sliceTrailing,
      },
    if (decode != null)
      'decode': {
        'param': ?decode.param,
        'jsonKey': ?decode.jsonKey,
        'encoding': ?decode.encoding,
        if (decode.targetPath) 'targetPath': true,
        'handler': ?decode.handler,
      },
    if (rule.allowParams.isNotEmpty) 'allowParams': rule.allowParams,
    if (rule.removeEmptyParamValues) 'removeEmptyParamValues': true,
  };
}

/// The parsed rule in [_describe]'s shape: regexes as text.
Object _normalize(Object value) {
  if (value is TsRegExp) {
    return value.toString();
  }
  if (value is List<Object>) {
    return value.map(_normalize).toList();
  }
  if (value is Map<String, Object>) {
    return value.map((key, item) => MapEntry(key, _normalize(item)));
  }
  return value;
}
