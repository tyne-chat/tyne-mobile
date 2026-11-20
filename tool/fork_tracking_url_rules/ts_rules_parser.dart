// Fork: reads the web app's tracking URL rules (TrackingUrlRules.ts in tyne, via the `fluxer`
// submodule) into plain Dart values, for gen_fork_tracking_url_rules.dart and the test that keeps
// the generated list in step with it (tyne-chat/tyne#844).
//
// The rule list is a literal: objects, arrays, strings, regular expressions, booleans and
// references to the two enum objects declared at the top of the file. Anything else makes the
// parser fail, so a new kind of value upstream adds is noticed instead of being dropped.

/// Path of the web app's rules, relative to the tyne-mobile checkout.
const String forkTrackingUrlRulesSourcePath =
    'fluxer/fluxer_app/src/features/messaging/utils/TrackingUrlRules.ts';

/// A JavaScript regular expression literal.
class TsRegExp {
  const TsRegExp(this.source, this.flags);

  final String source;
  final String flags;

  @override
  String toString() => '/$source/$flags';
}

class _Ref {
  const _Ref(this.object, this.member);

  final String object;
  final String member;
}

/// The rules of `TRACKING_URL_RULES`, each a map of the rule's keys to strings, booleans,
/// [TsRegExp]s, lists and maps, with enum references replaced by their values.
List<Map<String, Object>> parseTrackingUrlRules(String source) {
  final Map<String, Map<String, Object>> enums = {
    for (final String name in const [
      'TrackingURLEncoding',
      'TrackingURLHandler',
    ])
      name: _parseEnum(source, name),
  };
  const String marker = '= defineTrackingURLRules(';
  final int start = source.indexOf(marker);
  if (start == -1) {
    throw const FormatException(
      'TRACKING_URL_RULES = defineTrackingURLRules([...]) not found',
    );
  }
  final _Parser parser = _Parser(source, start + marker.length);
  final Object rules = parser.value();
  if (rules is! List<Object>) {
    throw const FormatException('defineTrackingURLRules is not given an array');
  }
  return [
    for (final Object rule in rules)
      if (rule is Map<String, Object>)
        _resolve(rule, enums) as Map<String, Object>
      else
        throw FormatException('A rule is not an object: $rule'),
  ];
}

Map<String, Object> _parseEnum(String source, String name) {
  final String marker = 'export const $name = Object.freeze(';
  final int start = source.indexOf(marker);
  if (start == -1) {
    throw FormatException('$name not found');
  }
  final Object value = _Parser(source, start + marker.length).value();
  if (value is! Map<String, Object>) {
    throw FormatException('$name is not an object');
  }
  return value;
}

Object _resolve(Object value, Map<String, Map<String, Object>> enums) {
  if (value is _Ref) {
    final Object? resolved = enums[value.object]?[value.member];
    if (resolved == null) {
      throw FormatException(
        'Unknown reference ${value.object}.${value.member}',
      );
    }
    return resolved;
  }
  if (value is List<Object>) {
    return [for (final Object item in value) _resolve(item, enums)];
  }
  if (value is Map<String, Object>) {
    return {
      for (final MapEntry<String, Object> entry in value.entries)
        entry.key: _resolve(entry.value, enums),
    };
  }
  return value;
}

class _Parser {
  _Parser(this._s, this._i);

  final String _s;
  int _i;

  Never _fail(String message) {
    final int line = '\n'.allMatches(_s.substring(0, _i)).length + 1;
    throw FormatException('$message (line $line)');
  }

  void _skipSpace() {
    while (_i < _s.length) {
      final String c = _s[_i];
      if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
        _i++;
      } else if (_s.startsWith('//', _i)) {
        final int end = _s.indexOf('\n', _i);
        _i = end == -1 ? _s.length : end;
      } else if (_s.startsWith('/*', _i)) {
        final int end = _s.indexOf('*/', _i);
        if (end == -1) {
          _fail('Unterminated comment');
        }
        _i = end + 2;
      } else {
        return;
      }
    }
  }

  void _expect(String token) {
    _skipSpace();
    if (!_s.startsWith(token, _i)) {
      _fail('Expected "$token"');
    }
    _i += token.length;
  }

  bool _take(String token) {
    _skipSpace();
    if (_s.startsWith(token, _i)) {
      _i += token.length;
      return true;
    }
    return false;
  }

  Object value() {
    _skipSpace();
    if (_i >= _s.length) {
      _fail('Unexpected end of file');
    }
    final String c = _s[_i];
    if (c == '{') {
      return _object();
    }
    if (c == '[') {
      return _array();
    }
    if (c == "'" || c == '"') {
      return _string();
    }
    if (c == '/') {
      return _regExp();
    }
    final String word = _identifier();
    if (word == 'true') {
      return true;
    }
    if (word == 'false') {
      return false;
    }
    if (_take('.')) {
      return _Ref(word, _identifier());
    }
    _fail('Unsupported value "$word"');
  }

  Map<String, Object> _object() {
    _expect('{');
    final Map<String, Object> result = {};
    while (!_take('}')) {
      _skipSpace();
      final String key = _s[_i] == "'" || _s[_i] == '"'
          ? _string()
          : _identifier();
      _expect(':');
      if (result.containsKey(key)) {
        _fail('Duplicate key "$key"');
      }
      result[key] = value();
      if (!_take(',')) {
        _expect('}');
        break;
      }
    }
    _take('as const');
    return result;
  }

  List<Object> _array() {
    _expect('[');
    final List<Object> result = [];
    while (!_take(']')) {
      result.add(value());
      if (!_take(',')) {
        _expect(']');
        break;
      }
    }
    return result;
  }

  String _identifier() {
    _skipSpace();
    final Match? match = RegExp(
      r'[A-Za-z_$][A-Za-z0-9_$]*',
    ).matchAsPrefix(_s, _i);
    if (match == null) {
      _fail('Expected a name');
    }
    _i = match.end;
    return match[0]!;
  }

  String _string() {
    final String quote = _s[_i++];
    final StringBuffer out = StringBuffer();
    while (true) {
      if (_i >= _s.length) {
        _fail('Unterminated string');
      }
      final String c = _s[_i++];
      if (c == quote) {
        return out.toString();
      }
      if (c == '\n') {
        _fail('Line break in a string');
      }
      if (c != r'\') {
        out.write(c);
        continue;
      }
      final String e = _s[_i++];
      switch (e) {
        case 'n':
          out.write('\n');
        case 't':
          out.write('\t');
        case 'r':
          out.write('\r');
        case 'u':
          out.writeCharCode(int.parse(_s.substring(_i, _i + 4), radix: 16));
          _i += 4;
        case "'" || '"' || r'\' || '/':
          out.write(e);
        default:
          _fail('Unsupported escape "\\$e"');
      }
    }
  }

  TsRegExp _regExp() {
    _i++;
    final int start = _i;
    bool inClass = false;
    while (true) {
      if (_i >= _s.length || _s[_i] == '\n') {
        _fail('Unterminated regular expression');
      }
      final String c = _s[_i];
      if (c == r'\') {
        _i += 2;
        continue;
      }
      if (c == '[') {
        inClass = true;
      } else if (c == ']') {
        inClass = false;
      } else if (c == '/' && !inClass) {
        break;
      }
      _i++;
    }
    final String source = _s.substring(start, _i);
    _i++;
    final Match flags = RegExp('[a-z]*').matchAsPrefix(_s, _i)!;
    _i = flags.end;
    for (final String flag in flags[0]!.split('')) {
      if (!'gim'.contains(flag)) {
        _fail('Unsupported regular expression flag "$flag"');
      }
    }
    return TsRegExp(source, flags[0]!);
  }
}
