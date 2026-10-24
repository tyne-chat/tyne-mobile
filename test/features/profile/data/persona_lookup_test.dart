import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/profile/data/persona_lookup.dart';
import 'package:fluxer_dart/export.dart';

// Fork: persona lookups made close together share one request, and a failed
// lookup is not repeated until a cooldown has passed (tyne-tools#7).

PersonaLookupItemSchema _item(String userId, String personaId) =>
    PersonaLookupItemSchema(id: personaId, userId: userId, name: 'Fox');

void main() {
  late List<List<PersonaLookupPair>> sent;
  late Future<List<PersonaLookupItemSchema>> Function(List<PersonaLookupPair>)
  answer;
  late DateTime now;
  late PersonaLookupBatcher batcher;

  setUp(() {
    sent = <List<PersonaLookupPair>>[];
    answer = (List<PersonaLookupPair> pairs) async => <PersonaLookupItemSchema>[
      for (final PersonaLookupPair pair in pairs)
        _item(pair.userId, pair.personaId),
    ];
    now = DateTime(2026, 10, 23);
    batcher = PersonaLookupBatcher(
      (List<PersonaLookupPair> pairs) {
        sent.add(pairs);
        return answer(pairs);
      },
      delay: Duration.zero,
      now: () => now,
    );
  });

  test('sends lookups made close together as one request, the same persona '
      'once', () async {
    final List<PersonaLookupItemSchema?> found =
        await Future.wait(<Future<PersonaLookupItemSchema?>>[
          batcher.lookup((userId: 'u1', personaId: 'p1')),
          batcher.lookup((userId: 'u1', personaId: 'p1')),
          batcher.lookup((userId: 'u2', personaId: 'p2')),
        ]);

    expect(sent, hasLength(1));
    expect(sent.single, <PersonaLookupPair>[
      (userId: 'u1', personaId: 'p1'),
      (userId: 'u2', personaId: 'p2'),
    ]);
    expect(found.map((PersonaLookupItemSchema? i) => i?.id), <String>[
      'p1',
      'p1',
      'p2',
    ]);
  });

  test('does not ask again for a persona it was told does not exist, unless '
      'forced', () async {
    answer = (_) async => <PersonaLookupItemSchema>[];
    expect(await batcher.lookup((userId: 'u1', personaId: 'gone')), isNull);
    expect(await batcher.lookup((userId: 'u1', personaId: 'gone')), isNull);
    expect(sent, hasLength(1));

    await batcher.lookup((userId: 'u1', personaId: 'gone'), force: true);
    expect(sent, hasLength(2));
  });

  test('does not ask again inside the cooldown after a failure, even when '
      'forced, and asks after it', () async {
    answer = (_) async => throw Exception('429');
    expect(await batcher.lookup((userId: 'u1', personaId: 'p1')), isNull);
    answer = (List<PersonaLookupPair> pairs) async => <PersonaLookupItemSchema>[
      _item('u1', 'p1'),
    ];
    expect(
      await batcher.lookup((userId: 'u1', personaId: 'p1'), force: true),
      isNull,
    );
    expect(sent, hasLength(1));

    now = now.add(const Duration(minutes: 1, seconds: 1));
    expect((await batcher.lookup((userId: 'u1', personaId: 'p1')))?.id, 'p1');
    expect(sent, hasLength(2));
  });

  test('splits more than 100 personas over several requests', () async {
    await Future.wait(<Future<PersonaLookupItemSchema?>>[
      for (int i = 0; i < 150; i++)
        batcher.lookup((userId: 'u1', personaId: 'p$i')),
    ]);

    expect(sent.map((List<PersonaLookupPair> pairs) => pairs.length), <int>[
      100,
      50,
    ]);
  });

  test('drops what is pending when reset', () async {
    final Future<PersonaLookupItemSchema?> pending = batcher.lookup((
      userId: 'u1',
      personaId: 'p1',
    ));
    batcher.reset();

    expect(await pending, isNull);
    expect(sent, isEmpty);
  });
}
