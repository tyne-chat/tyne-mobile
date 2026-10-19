// Fork: tests of the fork-owned fork_gateway_parse_skip_log.dart
// (tyne-chat/tyne#193).
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/gateway/fork_gateway_parse_skip_log.dart';
import 'package:fluxer_app/core/gateway/gateway_event_handler.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_dart/gateway.dart';
import 'package:fluxer_dart/gateway_client/fork_parse_skips.dart';
import 'package:talker/talker.dart' show TalkerData;

import '../../helpers/open_test_database.dart';

/// A guild whose second member does not parse (its join date is not a date).
Map<String, dynamic> _guildWithOneBadMember() => <String, dynamic>{
  'id': 'g1',
  'properties': <String, dynamic>{
    'id': 'g1',
    'name': 'Guild g1',
    'owner_id': '100',
  },
  'members': <Map<String, Object?>>[
    for (final (String id, String joinedAt) in <(String, String)>[
      ('1', '2026-01-01'),
      ('2', 'not a date'),
    ])
      <String, Object?>{
        'user': <String, Object?>{
          'id': id,
          'username': 'user-$id',
          'discriminator': '0001',
        },
        'roles': <String>[],
        'joined_at': joinedAt,
      },
  ],
};

/// Runs in the background isolate: parses the guild and returns its members.
int _memberCountOnIsolate(Map<String, dynamic> raw) =>
    GuildCreateData.fromJson(raw).members.length;

void main() {
  tearDown(() => ForkGatewayParseSkips.onSkipped = null);

  group('ForkGatewayParseSkipLog', () {
    test('logs a kind of skip once, then at the 10th and 100th time', () {
      final List<String> lines = <String>[];
      final ForkGatewayParseSkipLog skipLog = ForkGatewayParseSkipLog(
        log: lines.add,
      );

      for (var i = 0; i < 150; i++) {
        skipLog.record('GuildMemberResponse', const FormatException('bad'));
      }

      const String reason = 'that did not parse: FormatException: bad';
      expect(lines, <String>[
        'skipped a GuildMemberResponse $reason',
        'skipped 10 of GuildMemberResponse $reason',
        'skipped 100 of GuildMemberResponse $reason',
      ]);
    });

    test('counts each kind and reason apart, on one line each', () {
      final List<String> lines = <String>[];
      ForkGatewayParseSkipLog(log: lines.add)
        ..record('GuildMemberResponse', 'first\nsecond line')
        ..record('GuildRoleResponse', 'first\nsecond line')
        ..record('GuildMemberResponse', 'another reason');

      expect(lines, <String>[
        'skipped a GuildMemberResponse that did not parse: first second line',
        'skipped a GuildRoleResponse that did not parse: first second line',
        'skipped a GuildMemberResponse that did not parse: another reason',
      ]);
    });

    test(
      'shortens long reasons and stops taking new kinds after the limit',
      () {
        final List<String> lines = <String>[];
        final ForkGatewayParseSkipLog skipLog = ForkGatewayParseSkipLog(
          log: lines.add,
          maxKinds: 2,
        )..record('A', 'x' * 400);

        expect(lines.single, hasLength(lessThan(360)));
        expect(lines.single, endsWith('…'));

        skipLog
          ..record('B', 'reason')
          ..record('C', 'reason')
          ..record('D', 'reason')
          ..record('A', 'x' * 400);

        expect(lines, hasLength(3));
        expect(
          lines.last,
          'more than 2 kinds of skipped items; not logging new ones',
        );
      },
    );
  });

  test('forkLogGatewayParseSkips writes skips to App logs', () {
    talker.cleanHistory();
    forkLogGatewayParseSkips();

    ForkGatewayParseSkips.report('GuildRoleResponse', 'bad role');

    expect(
      <String?>[for (final TalkerData entry in talker.history) entry.message],
      contains(
        '[Gateway] Fork: skipped a GuildRoleResponse that did not parse: '
        'bad role',
      ),
    );
  });

  test(
    'forkComputeLoggingSkips forwards what the background isolate skipped',
    () async {
      final List<(String, Object)> skips = <(String, Object)>[];
      void handler(String skipped, Object error) => skips.add((skipped, error));
      ForkGatewayParseSkips.onSkipped = handler;

      final int members = await forkComputeLoggingSkips(
        _memberCountOnIsolate,
        _guildWithOneBadMember(),
      );

      expect(members, 1);
      expect(skips.map(((String, Object) s) => s.$1), <String>[
        'GuildMemberResponse',
      ]);
      expect('${skips.single.$2}', contains('joined_at'));
      expect(ForkGatewayParseSkips.onSkipped, same(handler));
    },
  );

  test('a presence user the handler cannot parse is reported', () async {
    final List<String> skipped = <String>[];
    ForkGatewayParseSkips.onSkipped = (String what, Object error) =>
        skipped.add(what);
    final FluxerDatabase database = openTestDatabase();
    final GatewayEventHandler handler = GatewayEventHandler(database: database);

    await handler.handle(
      const PresenceUpdateBulkEvent(
        presences: <Map<String, dynamic>>[
          <String, dynamic>{
            'user': <String, dynamic>{
              'id': '2',
              'username': 'user-2',
              'flags': 'not a number',
            },
            'status': 'online',
          },
        ],
      ),
    );

    // The handler writes presences without awaiting; this read queues
    // behind that write, so it is done before the database closes.
    await database.userDao.getUserById('2');

    expect(skipped, <String>['presence UserPartialResponse']);
  });
}
