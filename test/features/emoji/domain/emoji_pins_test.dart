// Fork: the pinned emojis (tyne-chat/tyne#140), kept as the web keeps them.
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/synced_preferences/generated/fluxer/user/preferences/v1/fork_emoji_pins.pb.dart'
    as pins_pb;
import 'package:fluxer_app/features/emoji/domain/emoji_pins.dart';

List<String> _unicodeKeys(int count, {String prefix = 'e'}) => <String>[
  for (int index = 0; index < count; index++) 'unicode:$prefix$index',
];

void main() {
  group('EmojiPins', () {
    test('keeps the account pins and each persona pins apart, in pin '
        'order', () {
      final EmojiPins pins = EmojiPins.empty
          .withPin('unicode:dog')!
          .withPin('unicode:cat', personaId: '1001')!
          .withPin('unicode:fox')!
          .withPin('unicode:cat', personaId: '1002')!;

      expect(pins.account, <String>['unicode:dog', 'unicode:fox']);
      expect(pins.forPersona('1001'), <String>['unicode:cat']);
      expect(pins.isPinnedIn('unicode:cat'), isFalse);
      expect(pins.isPinnedIn('unicode:cat', personaId: '1001'), isTrue);
      expect(pins.effective('1001'), <String>[
        'unicode:dog',
        'unicode:fox',
        'unicode:cat',
      ]);
      expect(pins.effective(null), <String>['unicode:dog', 'unicode:fox']);
    });

    test("treats persona '0' as the account", () {
      final EmojiPins pins = EmojiPins.empty.withPin(
        'unicode:dog',
        personaId: '0',
      )!;
      expect(pins.account, <String>['unicode:dog']);
      expect(pins.personas, isEmpty);
    });

    test('refuses invalid keys and persona ids', () {
      expect(EmojiPins.empty.withPin('dog'), isNull);
      expect(
        EmojiPins.empty.withPin('unicode:dog', personaId: 'persona-a'),
        isNull,
      );
    });

    test('refuses a pin past $kMaxPinnedEmojisPerList in one list', () {
      EmojiPins pins = EmojiPins.empty;
      for (final String key in _unicodeKeys(kMaxPinnedEmojisPerList)) {
        pins = pins.withPin(key)!;
      }
      expect(pins.withPin('unicode:one-too-many'), isNull);
      expect(
        pins.withPin('unicode:one-too-many', personaId: '1001'),
        isNotNull,
      );
    });

    test('refuses a pin that would take the pins past their share of the '
        'synced preferences', () {
      String longKey(int persona, int index) =>
          'custom:${'9' * 19}:$persona${'0' * 14}$index';
      EmojiPins pins = EmojiPins.empty;
      EmojiPins? refusedAt;
      for (int persona = 1000; persona < 1250 && refusedAt == null; persona++) {
        for (int index = 0; index < kMaxPinnedEmojisPerList; index++) {
          final EmojiPins? next = pins.withPin(
            longKey(persona, index),
            personaId: '$persona',
          );
          if (next == null) {
            refusedAt = pins;
            break;
          }
          pins = next;
        }
      }
      expect(refusedAt, isNotNull);
      expect(pins.encodedBytes, lessThanOrEqualTo(kMaxEmojiPinsEncodedBytes));
    });

    test('unpins, and drops a persona whose list empties', () {
      final EmojiPins pins = EmojiPins.empty
          .withPin('unicode:dog')!
          .withPin('unicode:cat', personaId: '1001')!;

      expect(pins.withoutPin('unicode:dog').account, isEmpty);
      expect(
        pins.withoutPin('unicode:cat', personaId: '1001').personas,
        isEmpty,
      );
      expect(identical(pins.withoutPin('unicode:fox'), pins), isTrue);
    });

    test("drops a deleted persona's pins and nobody else's", () {
      final EmojiPins pins = EmojiPins.empty
          .withPin('unicode:cat', personaId: '1001')!
          .withPin('unicode:dog', personaId: '1002')!;

      expect(pins.withoutPersona('1001').personas, <String, List<String>>{
        '1002': <String>['unicode:dog'],
      });
      expect(identical(pins.withoutPersona('1999'), pins), isTrue);
    });

    test('cleans what it reads: bad keys, repeats, bad persona ids, empty '
        'lists, too many', () {
      final EmojiPins pins = EmojiPins.sanitized(
        account: <String>[
          'unicode:cat',
          'cat',
          '',
          'unicode:cat',
          'custom:1:2',
          'unicode:${'x' * 300}',
        ],
        personas: <String, Iterable<String>>{
          '1001': const <String>['unicode:cat'],
          '1002': const <String>['nope'],
          'persona-a': const <String>['unicode:dog'],
          '1003': _unicodeKeys(kMaxPinnedEmojisPerList + 5),
        },
      );

      expect(pins.account, <String>['unicode:cat', 'custom:1:2']);
      expect(pins.personas.keys, unorderedEquals(<String>['1001', '1003']));
      expect(pins.forPersona('1003'), hasLength(kMaxPinnedEmojisPerList));
    });

    test('goes through storage and the synced preferences unchanged', () {
      final EmojiPins pins = EmojiPins.empty
          .withPin('unicode:dog')!
          .withPin('custom:12:34', personaId: '1001')!;

      expect(EmojiPins.fromJson(pins.toJson()), pins);
      expect(EmojiPins.fromProto(pins.toProto()), pins);
      expect(EmojiPins.fromJson('not json'), EmojiPins.empty);
      expect(EmojiPins.fromJson(''), EmojiPins.empty);
    });

    test('writes into the server copy, keeping what it does not know', () {
      final pins_pb.EmojiPinsState server = pins_pb.EmojiPinsState(
        pinnedEmojiIds: <String>['unicode:old'],
      )..unknownFields.mergeVarintField(99, Int64.ONE);
      final pins_pb.EmojiPinsState proto = pins_pb.EmojiPinsState()
        ..mergeFromMessage(server);

      EmojiPins.empty.withPin('unicode:new')!.writeProto(proto);

      expect(proto.pinnedEmojiIds, <String>['unicode:new']);
      expect(proto.unknownFields.hasField(99), isTrue);
    });
  });

  group('rankingWithEmojiPins', () {
    final EmojiPins pins = EmojiPins.empty
        .withPin('unicode:dog')!
        .withPin('unicode:cat', personaId: '1001')!;

    test('puts the account pins, then the persona pins, ahead of the '
        'ranking, each key once', () {
      expect(
        rankingWithEmojiPins(
          <String>['unicode:fox', 'unicode:cat', 'unicode:owl'],
          pins,
          '1001',
          limit: 42,
        ),
        <String>['unicode:dog', 'unicode:cat', 'unicode:fox', 'unicode:owl'],
      );
    });

    test('cuts to the limit, pins first', () {
      expect(
        rankingWithEmojiPins(
          <String>['unicode:fox', 'unicode:owl'],
          pins,
          '1001',
          limit: 3,
        ),
        <String>['unicode:dog', 'unicode:cat', 'unicode:fox'],
      );
    });

    test('gives the same list for the same inputs, and the ranking itself '
        'without pins', () {
      final List<String> ranking = <String>['unicode:fox'];
      final List<String> first = rankingWithEmojiPins(
        ranking,
        pins,
        null,
        limit: 42,
      );
      expect(
        identical(rankingWithEmojiPins(ranking, pins, null, limit: 42), first),
        isTrue,
      );
      expect(
        identical(
          rankingWithEmojiPins(ranking, EmojiPins.empty, null, limit: 42),
          ranking,
        ),
        isTrue,
      );
    });
  });
}
