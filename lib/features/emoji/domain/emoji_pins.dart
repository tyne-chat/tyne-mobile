import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:fluxer_app/core/synced_preferences/generated/fluxer/user/preferences/v1/fork_emoji_pins.pb.dart'
    as pins_pb;

// Fork: the emojis pinned to the front of the picker's frequently used row and
// the quick reactions (tyne-chat/tyne#140), kept as the web keeps them
// (`fluxer_app/src/features/emoji/state/EmojiPins.ts` in tyne-chat/tyne).

/// The size of the frequently used row (`kMaxFrecentEmojis`), so a list never
/// holds pins the row cannot show. The same cap as the web's.
const int kMaxPinnedEmojisPerList = 42;

/// What all pins may take in the synced preferences, as on the web: below the
/// 64 KiB the web lets one synced field send. Up to 250 personas may each have
/// a list, so a pin that would go past it is refused.
const int kMaxEmojiPinsEncodedBytes = 48000;

const int _kMaxKeyLength = 256;

final RegExp _personaIdPattern = RegExp(r'^\d{1,20}$');

bool isEmojiPinKey(String key) =>
    key.isNotEmpty &&
    key.length <= _kMaxKeyLength &&
    (key.startsWith('unicode:') || key.startsWith('custom:'));

bool isEmojiPinPersonaId(String personaId) =>
    _personaIdPattern.hasMatch(personaId);

/// The persona a pin is for, or null for the account. `'0'` is how the app
/// names the account where it needs a persona id.
String? _personaOrNull(String? personaId) =>
    personaId == null || personaId.isEmpty || personaId == '0'
    ? null
    : personaId;

List<String> sanitizeEmojiPinList(Iterable<String> keys) {
  final List<String> result = <String>[];
  final Set<String> seen = <String>{};
  for (final String key in keys) {
    if (!isEmojiPinKey(key) || !seen.add(key)) {
      continue;
    }
    result.add(key);
    if (result.length >= kMaxPinnedEmojisPerList) {
      break;
    }
  }
  return List<String>.unmodifiable(result);
}

/// The account's pinned emojis and each persona's. They are synced to the
/// account through the fork's `emoji_pins` field of the synced preferences.
/// Keys are the pickers' favourite keys, `unicode:<name>` and
/// `custom:<guild id>:<emoji id>`, in the order they were pinned.
@immutable
class EmojiPins {
  const EmojiPins({
    this.account = const <String>[],
    this.personas = const <String, List<String>>{},
  });

  /// Cleans what came from storage or another client: invalid keys, repeats,
  /// invalid persona ids, empty lists and lists past the cap are dropped.
  factory EmojiPins.sanitized({
    Iterable<String> account = const <String>[],
    Map<String, Iterable<String>> personas = const <String, Iterable<String>>{},
  }) {
    final Map<String, List<String>> cleanPersonas = <String, List<String>>{};
    for (final MapEntry<String, Iterable<String>> entry in personas.entries) {
      if (!isEmojiPinPersonaId(entry.key)) {
        continue;
      }
      final List<String> keys = sanitizeEmojiPinList(entry.value);
      if (keys.isNotEmpty) {
        cleanPersonas[entry.key] = keys;
      }
    }
    return EmojiPins(
      account: sanitizeEmojiPinList(account),
      personas: Map<String, List<String>>.unmodifiable(cleanPersonas),
    );
  }

  factory EmojiPins.fromProto(pins_pb.EmojiPinsState proto) =>
      EmojiPins.sanitized(
        account: proto.pinnedEmojiIds,
        personas: <String, Iterable<String>>{
          for (final MapEntry<String, pins_pb.PersonaEmojiPins> entry
              in proto.personaPins.entries)
            entry.key: entry.value.emojiIds,
        },
      );

  /// Reads what [toJson] wrote; anything unreadable is no pins.
  factory EmojiPins.fromJson(String? json) {
    if (json == null || json.isEmpty) {
      return empty;
    }
    try {
      final Object? decoded = jsonDecode(json);
      if (decoded is! Map<String, Object?>) {
        return empty;
      }
      final Object? account = decoded['account'];
      final Object? personas = decoded['personas'];
      return EmojiPins.sanitized(
        account: account is List<Object?> ? account.whereType<String>() : [],
        personas: <String, Iterable<String>>{
          if (personas is Map<String, Object?>)
            for (final MapEntry<String, Object?> entry in personas.entries)
              if (entry.value case final List<Object?> keys)
                entry.key: keys.whereType<String>(),
        },
      );
    } on FormatException {
      return empty;
    }
  }

  static const EmojiPins empty = EmojiPins();

  /// Pinned whoever the account writes as.
  final List<String> account;

  /// Pinned for one persona, by persona id; a persona without pins has no
  /// entry.
  final Map<String, List<String>> personas;

  bool get isEmpty => account.isEmpty && personas.isEmpty;

  List<String> forPersona(String personaId) =>
      personas[personaId] ?? const <String>[];

  /// The list a pin for [personaId] goes into: the persona's, or the
  /// account's when there is no persona.
  List<String> listFor(String? personaId) {
    final String? persona = _personaOrNull(personaId);
    return persona == null ? account : forPersona(persona);
  }

  bool isPinnedIn(String key, {String? personaId}) =>
      listFor(personaId).contains(key);

  /// The account's pins, then the persona's, each key once.
  List<String> effective(String? personaId) {
    final String? persona = _personaOrNull(personaId);
    if (persona == null || forPersona(persona).isEmpty) {
      return account;
    }
    return <String>{...account, ...forPersona(persona)}.toList();
  }

  /// With [key] pinned in [personaId]'s list (the account's without one), or
  /// null when that is refused: an invalid key or persona id, a full list, or
  /// pins that would no longer fit the synced preferences.
  EmojiPins? withPin(String key, {String? personaId}) {
    final String? persona = _personaOrNull(personaId);
    if (!isEmojiPinKey(key) ||
        (persona != null && !isEmojiPinPersonaId(persona))) {
      return null;
    }
    final List<String> current = listFor(persona);
    if (current.contains(key)) {
      return this;
    }
    if (current.length >= kMaxPinnedEmojisPerList) {
      return null;
    }
    final List<String> next = List<String>.unmodifiable(<String>[
      ...current,
      key,
    ]);
    final EmojiPins result = persona == null
        ? EmojiPins(account: next, personas: personas)
        : EmojiPins(
            account: account,
            personas: Map<String, List<String>>.unmodifiable(
              <String, List<String>>{...personas, persona: next},
            ),
          );
    return result.encodedBytes > kMaxEmojiPinsEncodedBytes ? null : result;
  }

  EmojiPins withoutPin(String key, {String? personaId}) {
    final String? persona = _personaOrNull(personaId);
    if (!isPinnedIn(key, personaId: persona)) {
      return this;
    }
    final List<String> rest = List<String>.unmodifiable(
      listFor(persona).where((String pin) => pin != key),
    );
    if (persona == null) {
      return EmojiPins(account: rest, personas: personas);
    }
    return _withPersonaList(persona, rest);
  }

  /// Without a deleted persona's pins.
  EmojiPins withoutPersona(String personaId) => personas.containsKey(personaId)
      ? _withPersonaList(personaId, const <String>[])
      : this;

  EmojiPins _withPersonaList(String personaId, List<String> keys) {
    final Map<String, List<String>> next = <String, List<String>>{...personas}
      ..remove(personaId);
    if (keys.isNotEmpty) {
      next[personaId] = keys;
    }
    return EmojiPins(
      account: account,
      personas: Map<String, List<String>>.unmodifiable(next),
    );
  }

  /// Fills [proto], which may be the server's copy, with these pins.
  void writeProto(pins_pb.EmojiPinsState proto) {
    proto.pinnedEmojiIds
      ..clear()
      ..addAll(account);
    proto.personaPins
      ..clear()
      ..addAll(<String, pins_pb.PersonaEmojiPins>{
        for (final MapEntry<String, List<String>> entry in personas.entries)
          entry.key: pins_pb.PersonaEmojiPins(emojiIds: entry.value),
      });
  }

  pins_pb.EmojiPinsState toProto() {
    final pins_pb.EmojiPinsState proto = pins_pb.EmojiPinsState();
    writeProto(proto);
    return proto;
  }

  int get encodedBytes => toProto().writeToBuffer().length;

  String toJson() =>
      jsonEncode(<String, Object>{'account': account, 'personas': personas});

  @override
  bool operator ==(Object other) =>
      other is EmojiPins &&
      listEquals(account, other.account) &&
      other.personas.length == personas.length &&
      personas.entries.every(
        (MapEntry<String, List<String>> entry) =>
            listEquals(entry.value, other.personas[entry.key]),
      );

  @override
  int get hashCode => Object.hash(
    Object.hashAll(account),
    Object.hashAllUnordered(
      personas.entries.map(
        (MapEntry<String, List<String>> entry) =>
            Object.hash(entry.key, Object.hashAll(entry.value)),
      ),
    ),
  );
}

List<String>? _lastRanking;
EmojiPins? _lastPins;
String? _lastPersonaId;
int? _lastLimit;
List<String>? _lastResult;

/// [ranking] with [pins] in front: the account's, then [personaId]'s, each key
/// once, cut to [limit]. The same inputs give the same list object, so the
/// picker's caches, which compare by identity, keep working.
List<String> rankingWithEmojiPins(
  List<String> ranking,
  EmojiPins pins,
  String? personaId, {
  required int limit,
}) {
  if (pins.isEmpty) {
    return ranking;
  }
  final List<String>? last = _lastResult;
  if (last != null &&
      identical(_lastRanking, ranking) &&
      _lastPins == pins &&
      _lastPersonaId == personaId &&
      _lastLimit == limit) {
    return last;
  }
  final List<String> result = List<String>.unmodifiable(
    <String>{...pins.effective(personaId), ...ranking}.take(limit),
  );
  _lastRanking = ranking;
  _lastPins = pins;
  _lastPersonaId = personaId;
  _lastLimit = limit;
  _lastResult = result;
  return result;
}
