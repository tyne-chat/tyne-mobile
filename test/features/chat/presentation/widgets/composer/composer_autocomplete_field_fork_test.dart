// Fork: mentioning a persona from the composer. Typing `@` and a name offers
// the personas the channel knows (asked from `GET /channels/:id/persona-mentions`
// through ChannelPersonaMentionCache, plus the personas of the messages on
// screen), and picking one puts `<@owner:persona>` in the message. The
// requests are counted: the lookup runs on every keystroke of a mention. Also
// the server commands the fork adds to the `/` list.
// Kept out of upstream's composer_autocomplete_field_test.dart so that file
// stays as upstream has it.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/providers/gateway/gateway_connection_provider.dart';
import 'package:fluxer_app/features/chat/data/channel_persona_mention_cache.dart';
import 'package:fluxer_app/features/chat/domain/composer_slash_command.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/composer/composer_autocomplete_field.dart';
import 'package:fluxer_app/features/chat/providers/channel/channel_message_permissions_provider.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/guild_commands/providers/guild_commands_providers.dart';
import 'package:fluxer_app/features/ui/badge/fluxer_user_tag.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_dart/export.dart';
import 'package:fluxer_dart/gateway.dart';

import '../../../../../helpers/composer_channel_textarea_harness.dart';
import '../../../../../helpers/open_test_database.dart';

/// The DM's other member in the harness (Alice).
const String _alice = '2000000000000000001';
const String _bob = '2000000000000000002';

/// `GET /channels/:id/persona-mentions`: answers with [personas] and records
/// the query of every request.
class _MentionApi implements HttpClientAdapter {
  _MentionApi(this.personas);

  final List<Map<String, Object?>> personas;
  final List<String> queries = <String>[];
  int status = 200;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (!options.uri.path.endsWith(
      '/channels/$kComposerHarnessChannelA/persona-mentions',
    )) {
      return ResponseBody.fromString('Not found', 404);
    }
    queries.add(options.uri.queryParameters['q'] ?? '');
    return ResponseBody.fromString(
      jsonEncode(
        status == 200
            ? personas
            : <String, Object?>{'code': 'RATE_LIMITED', 'message': 'Slow'},
      ),
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// A gateway that never connects; member search only needs one to exist.
class _QuietGatewayConnection extends GatewayConnection {
  _QuietGatewayConnection() : super(token: 'test', dio: Dio());

  @override
  Future<void> connect() async {}

  @override
  Future<void> suspend() async {}
}

/// One community command, already loaded.
class _CommunityCommands extends GuildCommandsNotifier {
  int listLoads = 0;

  @override
  Future<void> loadForList() async {
    listLoads++;
  }

  @override
  List<ComposerSlashCommand> composerCommands(
    List<ComposerSlashCommand> builtIns, {
    required String? channelGuildId,
    required int channelPermissionBits,
  }) => <ComposerSlashCommand>[
    ...builtIns,
    const ComposerActionSlashCommand(
      name: '/roll',
      description: 'Roll dice · Dice Club',
    ),
  ];
}

const Map<String, Object?> _fox = <String, Object?>{
  'id': 'persona_fox',
  'name': 'Fox',
  'owner_user_id': _alice,
  'owner_username': 'alice',
  'owner_discriminator': '0',
  'display_tag_text': 'sys',
  'color': 0x336699,
  'use_count': 3,
};

void main() {
  late db.FluxerDatabase database;
  late _MentionApi api;
  late _QuietGatewayConnection gateway;

  setUp(() {
    gateway = _QuietGatewayConnection();
    addTearDown(gateway.dispose);
    ChannelPersonaMentionCache.instance.clear();
    addTearDown(ChannelPersonaMentionCache.instance.clear);
    database = openTestDatabase();
    api = _MentionApi(<Map<String, Object?>>[_fox]);
  });

  Future<ProviderContainer> pumpComposer(
    WidgetTester tester, {
    List<Message> messages = const <Message>[],
    _CommunityCommands? commands,
    bool inCommunity = false,
  }) async {
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.fluxer.invalid'))
      ..httpClientAdapter = api;
    if (inCommunity) {
      await tester.runAsync(
        () => database.channelDao.upsertChannel(
          db.ChannelsCompanion.insert(
            id: kComposerHarnessChannelA,
            guildId: 'g1',
            name: 'general',
          ),
        ),
      );
    }
    final ProviderContainer container =
        await pumpComposerChannelTextareaHarness(
          tester,
          database: database,
          guildChannelPermissions: inCommunity
              ? ChannelMessagePermissions.all
              : null,
          extraOverrides: [
            fluxerDioProvider.overrideWithValue(dio),
            fluxerClientProvider.overrideWithValue(
              FluxerClient(dio, baseUrl: 'https://test.fluxer.invalid'),
            ),
            gatewayConnectionProvider.overrideWithValue(gateway),
            if (commands != null)
              guildCommandsProvider.overrideWith(() => commands),
          ],
        );
    final MutableChatViewModel chat = readMutableChatViewModel(container);
    chat.state = chat.state.copyWith(
      write: (messages: messages, origin: MessagesOrigin.windowSwap),
    );
    await tester.pump();
    return container;
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(channelComposerField(), text);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 150));
  }

  ComposerAutocompleteFieldState field(WidgetTester tester) =>
      tester.state<ComposerAutocompleteFieldState>(
        find.byType(ComposerAutocompleteField),
      );

  Future<void> finish(WidgetTester tester) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 400));
    await releaseTestWidgetTree(tester);
  }

  testWidgets('typing @ and a name offers the persona, with one request', (
    WidgetTester tester,
  ) async {
    await pumpComposer(tester);

    await type(tester, '@');
    await type(tester, '@F');
    await type(tester, '@Fo');

    expect(field(tester).hasOpenMenu, isTrue);
    expect(find.text('Fox'), findsOneWidget);
    expect(find.text('alice'), findsOneWidget);
    expect(
      tester.widget<FluxerUserTag>(find.byType(FluxerUserTag)).label,
      'sys',
    );
    expect(api.queries, <String>['']);
    await finish(tester);
  });

  testWidgets('picking the persona puts its mention in the message', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpComposer(tester);

    await type(tester, 'hi @');
    await type(tester, 'hi @Fo');
    await tester.tap(find.text('Fox'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      container.read(chatViewModelProvider).messageText,
      startsWith('hi <@$_alice:persona_fox>'),
    );
    expect(field(tester).hasOpenMenu, isFalse);
    final List<db.KnownPersona> known = (await tester.runAsync(
      () => database.select(database.knownPersonas).get(),
    ))!;
    expect(known.single.id, 'persona_fox');
    expect(known.single.userId, _alice);
    await finish(tester);
  });

  testWidgets('a persona from the messages on screen is offered without '
      'asking the server for it', (WidgetTester tester) async {
    await pumpComposer(
      tester,
      messages: <Message>[
        Message(
          id: '1000000000000000300',
          channelId: kComposerHarnessChannelA,
          authorId: _bob,
          authorName: 'bob',
          content: 'hoot',
          timestamp: DateTime.now(),
          personaId: 'persona_owl',
          personaName: 'Owl',
          personaTag: 'BIRD',
        ),
      ],
    );

    await type(tester, '@');
    await type(tester, '@Ow');

    expect(find.text('Owl'), findsOneWidget);
    expect(find.text('bob'), findsOneWidget);
    expect(find.text('Fox'), findsNothing);
    expect(api.queries, <String>['']);
    await finish(tester);
  });

  testWidgets("a community's command joins the built-ins in the / list", (
    WidgetTester tester,
  ) async {
    final _CommunityCommands commands = _CommunityCommands();
    await pumpComposer(tester, commands: commands);

    await type(tester, '/ro');

    expect(find.text('/roll'), findsOneWidget);
    expect(find.text('Roll dice · Dice Club'), findsOneWidget);
    expect(commands.listLoads, greaterThan(0));
    await finish(tester);
  });

  testWidgets('in a community channel, picking a persona puts its mention in '
      'the message', (WidgetTester tester) async {
    final ProviderContainer container = await pumpComposer(
      tester,
      inCommunity: true,
    );

    await type(tester, '@');
    await type(tester, '@Fo');
    await tester.tap(find.text('Fox'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      container.read(chatViewModelProvider).messageText,
      startsWith('<@$_alice:persona_fox>'),
    );
    expect(api.queries, contains(''));
    // Ends the mention before the composer goes: upstream's field reads a
    // provider in dispose while a community mention is open (reported). The
    // member search it started gives up after its own timeout.
    await type(tester, '');
    await tester.pump(const Duration(seconds: 2));
    await finish(tester);
  });
}
