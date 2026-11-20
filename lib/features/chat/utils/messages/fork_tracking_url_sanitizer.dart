// Fork: a port of the web app's tracking URL sanitizer (TrackingUrlSanitizer.ts in tyne, derived
// from tidy-url, MIT License, Copyright (c) 2021 DrKain), so a link sent from the phone loses the
// same tracking parameters, redirect wrappers and AMP wrappers as one sent from the web or desktop
// app (tyne-chat/tyne#844). The rules are generated from the web's TrackingUrlRules.ts
// (generated/fork_tracking_url_rules.dart). Upstream's own list in url_sanitization_utils.dart
// still runs after this, so nothing it removed before is kept now.
//
// The functions follow the web's one for one, under the same names, so a change upstream makes
// there can be carried over line by line. Where JavaScript's URL class would re-encode the whole
// link, this keeps the parts it does not change as they were written.

import 'dart:convert';

import 'package:fluxer_app/features/chat/utils/messages/fork_tracking_url_rule.dart';
import 'package:fluxer_app/features/chat/utils/messages/generated/fork_tracking_url_rules.dart';

const int _maxRewriteDepth = 2;
final RegExp _absoluteHttpUrlPattern = RegExp(
  r'^https?:\/\/',
  caseSensitive: false,
);
final RegExp _youtubeHostPattern = RegExp(
  r'(?:^|\.)(?:youtube\.com|youtu\.be|youtube-nocookie\.com)$',
  caseSensitive: false,
);
const List<String> _youtubeTrackingParams = ['si', 'is', 'pp'];
final RegExp _emptyParamValue = RegExp(r'=(?=&|$)');
final RegExp _twoHexDigits = RegExp(r'^[0-9a-fA-F]{2}$');
final RegExp _hexPattern = RegExp(r'^[\da-f]+$', caseSensitive: false);
final RegExp _base64Pattern = RegExp(r'^[A-Za-z0-9+/]*$');
final RegExp _redditMailPattern = RegExp(
  r'https:\/\/click\.redditmail\.com\/CL0\/(.*?)\/',
  caseSensitive: false,
);

/// Removes tracking from one absolute link, as the web app's `sanitizeTrackingURL` does. Returns
/// [value] unchanged when nothing is removed or the result would be longer.
String forkSanitizeTrackingUrl(String value) =>
    _sanitizeTrackingUrlAtDepth(value, 0);

final Expando<RegExp> _compiled = Expando<RegExp>('ForkJsRegExp');

RegExp _regExp(ForkJsRegExp pattern) => _compiled[pattern] ??= RegExp(
  pattern.source,
  caseSensitive: !pattern.flags.contains('i'),
  multiLine: pattern.flags.contains('m'),
);

bool _matches(ForkJsRegExp pattern, String value) =>
    _regExp(pattern).hasMatch(value);

/// JavaScript's `string.replace(regex, with)`: every match with the `g` flag, else the first.
String _replacePattern(
  String value,
  ForkJsRegExp pattern,
  String replacement,
) => pattern.global
    ? value.replaceAll(_regExp(pattern), replacement)
    : value.replaceFirst(_regExp(pattern), replacement);

/// The parts of an absolute http(s) link that the web reads through JavaScript's URL class.
/// Unchanged parts keep their original text.
class _Url {
  _Url._(
    this._origin,
    this.hostname,
    this.pathname,
    this._pairs,
    this._hadQuery,
    this._hash,
  );

  final String _origin;
  final String hostname;
  String pathname;
  final List<String> _pairs;
  final bool _hadQuery;

  /// The fragment with its `#`; `#` alone for an empty fragment, '' for none.
  String _hash;

  static _Url? parse(String value) {
    final Uri? uri = Uri.tryParse(value);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return null;
    }
    final int authorityStart = value.indexOf('//');
    if (authorityStart == -1) {
      return null;
    }
    int pathStart = value.length;
    for (final String c in const ['/', '?', '#']) {
      final int index = value.indexOf(c, authorityStart + 2);
      if (index != -1 && index < pathStart) {
        pathStart = index;
      }
    }
    final int hashStart = value.indexOf('#', pathStart);
    final String beforeHash = hashStart == -1
        ? value
        : value.substring(0, hashStart);
    final int queryStart = beforeHash.indexOf('?', pathStart);
    final String path = queryStart == -1
        ? beforeHash.substring(pathStart)
        : beforeHash.substring(pathStart, queryStart);
    final String query = queryStart == -1
        ? ''
        : beforeHash.substring(queryStart + 1);
    return _Url._(
      value.substring(0, pathStart),
      uri.host.toLowerCase(),
      path.isEmpty ? '/' : path,
      query.isEmpty ? <String>[] : query.split('&'),
      queryStart != -1,
      hashStart == -1 ? '' : value.substring(hashStart),
    );
  }

  /// JavaScript's `url.hash`: '' for an empty fragment.
  String get hash => _hash == '#' ? '' : _hash;

  set hash(String value) => _hash = value;

  bool _queryChanged = false;

  Iterable<(String, String)> get searchParams sync* {
    for (final String pair in _pairs) {
      if (pair.isEmpty) {
        continue;
      }
      final int eq = pair.indexOf('=');
      yield eq == -1
          ? (_formDecode(pair), '')
          : (
              _formDecode(pair.substring(0, eq)),
              _formDecode(pair.substring(eq + 1)),
            );
    }
  }

  String? get(String name) {
    for (final (String key, String value) in searchParams) {
      if (key == name) {
        return value;
      }
    }
    return null;
  }

  bool has(String name) => get(name) != null;

  void delete(String name) {
    _pairs.removeWhere((pair) {
      final int eq = pair.indexOf('=');
      return pair.isNotEmpty &&
          _formDecode(eq == -1 ? pair : pair.substring(0, eq)) == name;
    });
    _queryChanged = true;
  }

  @override
  String toString() {
    final List<String> pairs = _queryChanged
        ? _pairs.where((p) => p.isNotEmpty).toList()
        : _pairs;
    final String search = pairs.isEmpty
        ? (_hadQuery && !_queryChanged ? '?' : '')
        : '?${pairs.join('&')}';
    return '$_origin$pathname$search$_hash';
  }
}

/// How URLSearchParams reads a name or value: `+` is a space, bad escapes stay as they are.
String _formDecode(String value) {
  final String text = value.replaceAll('+', ' ');
  if (!text.contains('%')) {
    return text;
  }
  final List<int> bytes = [];
  for (int i = 0; i < text.length; i++) {
    final int unit = text.codeUnitAt(i);
    if (unit == 0x25 && i + 2 < text.length) {
      final String hex = text.substring(i + 1, i + 3);
      if (_twoHexDigits.hasMatch(hex)) {
        bytes.add(int.parse(hex, radix: 16));
        i += 2;
        continue;
      }
    }
    final int end = (unit >= 0xD800 && unit <= 0xDBFF && i + 1 < text.length)
        ? i + 2
        : i + 1;
    bytes.addAll(utf8.encode(text.substring(i, end)));
    i = end - 1;
  }
  return utf8.decode(bytes, allowMalformed: true);
}

const String _uriReserved = r';/?:@&=+$,#';

/// JavaScript's `decodeURIComponent` (no [reserved]) or `decodeURI` (with the reserved set):
/// throws a [FormatException] where JavaScript throws a URIError.
String _jsDecode(String value, [String reserved = '']) {
  final StringBuffer out = StringBuffer();
  int i = 0;
  int hexByte(int at) {
    if (at + 3 > value.length || value.codeUnitAt(at) != 0x25) {
      throw const FormatException('URI malformed');
    }
    final String hex = value.substring(at + 1, at + 3);
    if (!_twoHexDigits.hasMatch(hex)) {
      throw const FormatException('URI malformed');
    }
    return int.parse(hex, radix: 16);
  }

  while (i < value.length) {
    if (value.codeUnitAt(i) != 0x25) {
      out.write(value[i]);
      i++;
      continue;
    }
    final int start = i;
    final int first = hexByte(i);
    i += 3;
    if (first < 0x80) {
      final String char = String.fromCharCode(first);
      out.write(reserved.contains(char) ? value.substring(start, i) : char);
      continue;
    }
    final int count;
    int codePoint;
    if (first & 0xE0 == 0xC0) {
      count = 1;
      codePoint = first & 0x1F;
    } else if (first & 0xF0 == 0xE0) {
      count = 2;
      codePoint = first & 0x0F;
    } else if (first & 0xF8 == 0xF0) {
      count = 3;
      codePoint = first & 0x07;
    } else {
      throw const FormatException('URI malformed');
    }
    for (int n = 0; n < count; n++) {
      final int next = hexByte(i);
      if (next & 0xC0 != 0x80) {
        throw const FormatException('URI malformed');
      }
      codePoint = (codePoint << 6) | (next & 0x3F);
      i += 3;
    }
    const List<int> minimum = [0, 0x80, 0x800, 0x10000];
    if (codePoint < minimum[count] ||
        codePoint > 0x10FFFF ||
        (codePoint >= 0xD800 && codePoint <= 0xDFFF)) {
      throw const FormatException('URI malformed');
    }
    out.writeCharCode(codePoint);
  }
  return out.toString();
}

_Url? _parseHttpUrl(String value) => _Url.parse(value);

bool _hostMatchesRule(List<String> hosts, String hostname) =>
    hosts.any((host) => hostname == host || hostname.endsWith('.$host'));

List<ForkTrackingUrlRule> _findRules(_Url parsedUrl) {
  final String hostname = parsedUrl.hostname;
  final String href = parsedUrl.toString();
  return forkTrackingUrlRules.where((rule) {
    if (rule.matchUrl) {
      return _matches(rule.match, href);
    }
    final List<String>? hosts = rule.hosts;
    if (hosts != null) {
      return _hostMatchesRule(hosts, hostname);
    }
    return _matches(rule.match, hostname);
  }).toList();
}

String? _findParamCaseInsensitive(_Url url, String target) {
  final String normalizedTarget = target.toLowerCase();
  for (final (String key, String value) in url.searchParams) {
    if (key.toLowerCase() == normalizedTarget) {
      return value;
    }
  }
  return null;
}

bool _removeTrackingParams(_Url parsedUrl, List<ForkTrackingUrlRule> rules) {
  final Set<String> allowed = {for (final rule in rules) ...rule.allowParams};
  final Set<String> removable = {
    for (final rule in rules) ...rule.removeParams,
  };
  if (_youtubeHostPattern.hasMatch(parsedUrl.hostname)) {
    removable.addAll(_youtubeTrackingParams);
  }
  bool changed = false;
  for (final String param in removable) {
    if (allowed.contains(param) || !parsedUrl.has(param)) {
      continue;
    }
    parsedUrl.delete(param);
    changed = true;
  }
  return changed;
}

bool _removeTrackingPathParts(_Url parsedUrl, List<ForkTrackingUrlRule> rules) {
  String pathname = parsedUrl.pathname;
  for (final ForkTrackingUrlRule rule in rules) {
    for (final ForkJsRegExp pattern in rule.removeFromPath) {
      pathname = _replacePattern(pathname, pattern, '');
    }
  }
  if (pathname == parsedUrl.pathname) {
    return false;
  }
  parsedUrl.pathname = pathname.isEmpty ? '/' : pathname;
  return true;
}

/// JavaScript's `atob`, falling back to [value] where it throws.
String _decodeBase64(String value) {
  String input = value.replaceAll(RegExp(r'[\t\n\f\r ]'), '');
  if (input.length % 4 == 0) {
    input = input.replaceFirst(RegExp(r'==?$'), '');
  }
  if (input.length % 4 == 1 || !_base64Pattern.hasMatch(input)) {
    return value;
  }
  try {
    return String.fromCharCodes(base64.decode(base64.normalize(input)));
  } on FormatException {
    return value;
  }
}

String? _decodeUriComponentSafely(String value) {
  try {
    return _jsDecode(value);
  } on FormatException {
    return null;
  }
}

String _decodeHex(String value) {
  if (value.length.isOdd || !_hexPattern.hasMatch(value)) {
    return value;
  }
  final StringBuffer result = StringBuffer();
  for (int index = 0; index < value.length; index += 2) {
    result.writeCharCode(
      int.parse(value.substring(index, index + 2), radix: 16),
    );
  }
  return result.toString();
}

String _decodeValue(String value, String? encoding) {
  try {
    switch (encoding ?? 'base64') {
      case 'base64':
        return _decodeBase64(value);
      case 'url':
        return _jsDecode(value, _uriReserved);
      case 'urlComponent':
        return _jsDecode(value);
      case 'hex':
        return _decodeHex(value);
      default:
        return value;
    }
  } on FormatException {
    return value;
  }
}

String? _decodeJsonTarget(String decoded, String key) {
  try {
    final Object? value = jsonDecode(decoded);
    if (value is! Map<String, Object?>) {
      return null;
    }
    final Object? target = value[key];
    return target is String ? target : null;
  } on FormatException {
    return null;
  }
}

class _DecodeContext {
  const _DecodeContext(this.originalUrl, this.decoded, this.lastPath, this.url);

  final String originalUrl;
  final String decoded;
  final String lastPath;
  final _Url url;
}

String? _decodePatchbotTarget(_DecodeContext context) {
  final List<String> parts = context.decoded.replaceAll('%3D', '=').split('|');
  if (parts.length < 3 || parts[2].isEmpty) {
    return null;
  }
  return _decodeUriComponentSafely(parts[2]);
}

String? _decodeProofpointUrlDefenseTarget(_DecodeContext context) {
  final String? target = context.url.get('u');
  if (target == null || target.isEmpty) {
    return null;
  }
  return _jsDecode(
    target.replaceAll('-', '%'),
  ).replaceAll('_', '/').replaceAll('%2F', '/');
}

String? _decodeRedditMailTarget(_DecodeContext context) {
  final Match? match = _redditMailPattern.firstMatch(context.originalUrl);
  final String? target = match?.group(1);
  if (target == null || target.isEmpty) {
    return null;
  }
  return _decodeUriComponentSafely(target);
}

String? _decodeRedirectingAtTarget(_DecodeContext context) {
  final List<String> parts = context.originalUrl.split('?id');
  final String host = parts[0];
  if (host != 'https://go.redirectingat.com/') {
    return context.originalUrl;
  }
  if (parts.length < 2 || parts[1].isEmpty) {
    return context.originalUrl;
  }
  return _Url.parse('$host?id=${_jsDecode(parts[1])}')?.get('url');
}

String? _decodeTwitchEmailTarget(_DecodeContext context) {
  final Object? data = jsonDecode(context.decoded);
  if (data is! Map<String, Object?>) {
    return null;
  }
  final Object? channel = data['channel'];
  if (data['name'] == 'twitch_favorite_up' && channel is String) {
    return 'https://www.twitch.tv/$channel';
  }
  return null;
}

String? _decodeHandlerTarget(String handler, _DecodeContext context) {
  try {
    switch (handler) {
      case 'patchbot.io':
        return _decodePatchbotTarget(context);
      case 'urldefense.proofpoint.com':
        return _decodeProofpointUrlDefenseTarget(context);
      case 'stardockentertainment.info':
        return _decodeBase64(
          context.lastPath,
        ).replaceFirst('watch>v=', 'watch?v=');
      case 'steam.gs':
        return context.originalUrl.split('%3Eutm_')[0];
      case '0yxjo.mjt.lu' || 'deals.dominos.co.nz':
        return _decodeBase64(context.lastPath);
      case 'click.redditmail.com':
        return _decodeRedditMailTarget(context);
      case 'redirectingat.com':
        return _decodeRedirectingAtTarget(context);
      case 'twitch.tv-email':
        return _decodeTwitchEmailTarget(context);
      default:
        return null;
    }
  } on FormatException {
    return null;
  }
}

String? _resolveRedirect(_Url parsedUrl, List<ForkTrackingUrlRule> rules) {
  for (final ForkTrackingUrlRule rule in rules) {
    final String? redirectParam = rule.redirectParam;
    if (redirectParam == null || redirectParam.isEmpty) {
      continue;
    }
    final String? target = _findParamCaseInsensitive(parsedUrl, redirectParam);
    if (target != null && target.isNotEmpty && _parseHttpUrl(target) != null) {
      return target;
    }
    final String? decoded = target != null && target.isNotEmpty
        ? _decodeUriComponentSafely(target)
        : null;
    if (decoded != null &&
        decoded.isNotEmpty &&
        _parseHttpUrl(decoded) != null) {
      return decoded;
    }
  }
  return null;
}

String? _resolveEncodedDecodeTarget(
  _Url parsedUrl,
  ForkTrackingUrlRule rule,
  String lastPath,
) {
  final ForkTrackingUrlDecodeRule? decode = rule.decode;
  if (decode == null) {
    return null;
  }
  if (decode.targetPath) {
    return lastPath;
  }
  final String? param = decode.param;
  return param == null ? null : parsedUrl.get(param);
}

String? _resolveDecodedUrl(_Url parsedUrl, List<ForkTrackingUrlRule> rules) {
  final String lastPath = parsedUrl.pathname.split('/').last;
  for (final ForkTrackingUrlRule rule in rules) {
    final ForkTrackingUrlDecodeRule? decode = rule.decode;
    if (decode == null) {
      continue;
    }
    final String? encoded = _resolveEncodedDecodeTarget(
      parsedUrl,
      rule,
      lastPath,
    );
    if (encoded == null) {
      continue;
    }
    final String decoded = _decodeValue(encoded, decode.encoding);
    final String? handler = decode.handler;
    final String? jsonKey = decode.jsonKey;
    final String? target;
    if (handler != null) {
      target = _decodeHandlerTarget(
        handler,
        _DecodeContext(parsedUrl.toString(), decoded, lastPath, parsedUrl),
      );
    } else if (jsonKey != null) {
      target = _decodeJsonTarget(decoded, jsonKey);
    } else {
      target = decoded;
    }
    if (target != null && target.isNotEmpty && _parseHttpUrl(target) != null) {
      return target;
    }
  }
  return null;
}

String _resolveAmpCandidateUrl(String decoded) =>
    _absoluteHttpUrlPattern.hasMatch(decoded) ? decoded : 'https://$decoded';

String? _resolveAmpRegexTarget(ForkJsRegExp regex, String value) {
  final Match? match = _regExp(regex).firstMatch(value);
  final String? target = match?.group(1);
  if (target == null || target.isEmpty) {
    return null;
  }
  final String? decoded = _decodeUriComponentSafely(target);
  if (decoded == null || decoded.isEmpty) {
    return null;
  }
  final String candidate = _resolveAmpCandidateUrl(decoded);
  return _parseHttpUrl(candidate) == null ? null : candidate;
}

(String, bool) _applyAmpRewrite(String value, ForkTrackingUrlAmpRule amp) {
  String result = value;
  bool resolvedTarget = false;
  final String replacement = amp.replaceWith ?? '';
  final String? replaceText = amp.replaceText;
  final ForkJsRegExp? replacePattern = amp.replacePattern;
  if (replaceText != null) {
    result = result.replaceFirst(replaceText, replacement);
  } else if (replacePattern != null) {
    result = _replacePattern(result, replacePattern, replacement);
  }
  final ForkJsRegExp? regex = amp.regex;
  if (regex != null) {
    final String? target = _resolveAmpRegexTarget(regex, result);
    if (target != null) {
      result = target;
      resolvedTarget = true;
    }
  }
  final String? sliceTrailing = amp.sliceTrailing;
  if (sliceTrailing != null &&
      sliceTrailing.isNotEmpty &&
      result.endsWith(sliceTrailing)) {
    result = result.substring(0, result.length - sliceTrailing.length);
  }
  if (result.endsWith('%3Famp')) {
    result = result.substring(0, result.length - 6);
  }
  if (result.endsWith('amp/')) {
    result = result.substring(0, result.length - 4);
  }
  return (result, resolvedTarget);
}

(String, bool) _removeAmpWrappers(
  String value,
  List<ForkTrackingUrlRule> rules,
) {
  String result = value;
  bool resolvedTarget = false;
  for (final ForkTrackingUrlRule rule in rules) {
    final ForkTrackingUrlAmpRule? amp = rule.amp;
    if (amp == null) {
      continue;
    }
    final (String rewritten, bool resolved) = _applyAmpRewrite(result, amp);
    result = rewritten;
    if (resolved) {
      resolvedTarget = true;
    }
  }
  return (result, resolvedTarget);
}

String _preserveSourceHash(String target, _Url source) {
  final bool hasEmptyHash =
      source.hash.isEmpty && source.toString().endsWith('#');
  if (source.hash.isEmpty && !hasEmptyHash) {
    return target;
  }
  final _Url? parsed = _parseHttpUrl(target);
  if (parsed == null) {
    return target;
  }
  if (source.hash.isNotEmpty) {
    parsed.hash = source.hash;
  }
  final String result = parsed.toString();
  if (hasEmptyHash && parsed.hash.isEmpty && !result.endsWith('#')) {
    return '$result#';
  }
  return result;
}

bool _isExcludedByRules(List<ForkTrackingUrlRule> rules, _Url sourceUrl) {
  final String target = sourceUrl.toString();
  return rules.any(
    (rule) => rule.exclude.any((pattern) => _matches(pattern, target)),
  );
}

String _sanitizeTrackingUrlAtDepth(String value, int depth) {
  final _Url? sourceUrl = _parseHttpUrl(value);
  if (sourceUrl == null) {
    return value;
  }
  final List<ForkTrackingUrlRule> rules = _findRules(sourceUrl);
  if (_isExcludedByRules(rules, sourceUrl)) {
    return value;
  }
  final String? redirect = _resolveRedirect(sourceUrl, rules);
  if (redirect != null && redirect.isNotEmpty && depth < _maxRewriteDepth) {
    final String sanitized = _sanitizeTrackingUrlAtDepth(
      _preserveSourceHash(redirect, sourceUrl),
      depth + 1,
    );
    return sanitized.length <= value.length ? sanitized : value;
  }
  bool changed = _removeTrackingParams(sourceUrl, rules);
  changed = _removeTrackingPathParts(sourceUrl, rules) || changed;
  final (String rewritten, bool resolvedTarget) = _removeAmpWrappers(
    sourceUrl.toString(),
    rules,
  );
  String result = rewritten;
  changed = result != sourceUrl.toString() || changed;
  if (resolvedTarget && depth < _maxRewriteDepth) {
    final String sanitizedAmpTarget = _sanitizeTrackingUrlAtDepth(
      _preserveSourceHash(result, sourceUrl),
      depth + 1,
    );
    changed = sanitizedAmpTarget != result || changed;
    result = sanitizedAmpTarget;
  }
  final _Url? ampUrl = _parseHttpUrl(result);
  if (ampUrl == null) {
    return value;
  }
  final String? decoded = _resolveDecodedUrl(ampUrl, rules);
  if (decoded != null && decoded.isNotEmpty && depth < _maxRewriteDepth) {
    result = _sanitizeTrackingUrlAtDepth(
      _preserveSourceHash(decoded, sourceUrl),
      depth + 1,
    );
    changed = true;
  }
  if (rules.any((rule) => rule.removeEmptyParamValues)) {
    final String withoutEmptyValues = result.replaceAll(_emptyParamValue, '');
    changed = withoutEmptyValues != result || changed;
    result = withoutEmptyValues;
  }
  if (!changed || result.length > value.length) {
    return value;
  }
  return result;
}
