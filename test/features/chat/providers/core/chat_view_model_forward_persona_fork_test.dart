// Fork: tyne-chat/tyne#209. A forward and its comment are sent by the view
// model, not the composer, so it works out their persona itself and keeps it
// through a retry and a restart of the app.
@Tags(['slow'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' hide Message;
import 'package:fluxer_app/core/providers/app/app_ui_lifecycle_provider.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/channels/data/ack_batcher.dart';
import 'package:fluxer_app/features/channels/providers/ack_batcher_provider.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/chat/utils/messages/message_page_sync.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/shared/services/guild_member_hydration_service.dart';
import 'package:fluxer_dart/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/chat_view_model_pagination_test_harness.dart';
import '../../../../helpers/noop_guild_member_hydration_service.dart';
import '../../../../helpers/open_test_database.dart';

const Persona _fox = Persona(id: 'persona_fox', name: 'Fox');
const Persona _bao = Persona(
  id: 'persona_bao',
  name: 'Bao',
  personaTags: <PersonaTag>[PersonaTag(prefix: 'B:')],
);

class _Personas extends MyPersonasNotifier {
  @override
  AsyncValue<List<Persona>> build() =>
      const AsyncValue.data(<Persona>[_fox, _bao]);
}

class _Selection extends ActivePersonaNotifier {
  _Selection(this.selection);

  final ActivePersonaState selection;

  @override
  ActivePersonaState build() => selection;
}

/// Records every message sent, and answers as the server does or with a 400.
class _SendRecorder extends PaginatingAdapter {
  _SendRecorder()
    : super(messagesByChannel: <String, List<Map<String, Object?>>>{});

  final List<({String channelId, Map<String, dynamic> body})> sends =
      <({String channelId, Map<String, dynamic> body})>[];
  bool failSends = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final String? channelId = RegExp(
      r'/channels/([^/]+)/messages$',
    ).firstMatch(options.uri.path)?.group(1);
    if (options.method != 'POST' || channelId == null) {
      return super.fetch(options, requestStream, cancelFuture);
    }
    final List<int> bytes = await requestStream!.expand((b) => b).toList();
    final Map<String, dynamic> body =
        jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    sends.add((channelId: channelId, body: body));
    final Headers jsonHeaders = Headers.fromMap(<String, List<String>>{
      Headers.contentTypeHeader: <String>['application/json'],
    });
    if (failSends) {
      return ResponseBody.fromString(
        jsonEncode(<String, Object?>{'code': 'NOPE', 'message': 'Refused'}),
        400,
        headers: jsonHeaders.map,
      );
    }
    return ResponseBody.fromString(
      jsonEncode(<String, Object?>{
        ...paginationMessageJson(
          id: paginationSnowflakeForIndex(900 + sends.length),
          channelId: channelId,
          authorId: 'me',
        ),
        'nonce': body['nonce'],
      }),
      200,
      headers: jsonHeaders.map,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FluxerDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    db = openTestDatabase();
    for (final String id in <String>['source', 'channel-1', 'channel-2']) {
      await db.channelDao.upsertChannel(
        ChannelsCompanion.insert(id: id, guildId: '', name: id),
      );
    }
  });

  ProviderContainer containerWith(
    _SendRecorder adapter,
    ActivePersonaState selection,
  ) {
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://api.fluxer.app/v1'))
      ..httpClientAdapter = adapter;
    final FluxerClient client = FluxerClient(
      dio,
      baseUrl: 'https://api.fluxer.app/v1',
    );
    final ProviderContainer container = ProviderContainer(
      overrides: [
        fluxerDatabaseProvider.overrideWithValue(db),
        appUiForegroundProvider.overrideWithValue(true),
        fluxerDioProvider.overrideWithValue(dio),
        fluxerClientProvider.overrideWithValue(client),
        currentUserIdProvider.overrideWithValue('me'),
        myPersonasProvider.overrideWith(_Personas.new),
        activePersonaProvider.overrideWith(() => _Selection(selection)),
        ackBatcherProvider.overrideWith((ref) {
          final AckBatcher batcher = AckBatcher(
            client: client,
            batchDelay: Duration.zero,
          );
          ref.onDispose(() {
            unawaited(batcher.dispose());
          });
          return batcher;
        }),
        guildMemberHydrationServiceProvider.overrideWithValue(
          NoopGuildMemberHydrationService(database: db),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<ChatViewModel> open(ProviderContainer container) async {
    final ChatViewModel notifier = container.read(
      chatViewModelProvider.notifier,
    );
    await notifier.switchChannel('channel-1');
    await paginationFlushAsync();
    return notifier;
  }

  Future<void> forward(
    ChatViewModel notifier, {
    List<String> to = const <String>['channel-1'],
    String? comment,
  }) async {
    await notifier.forwardMessage(
      sourceChannelId: 'source',
      sourceMessageId: 'src-1',
      destinationChannelIds: to,
      comment: comment,
    );
    await paginationFlushAsync();
  }

  const ActivePersonaState foxSelected = ActivePersonaState(
    activePersonaId: 'persona_fox',
    isLatched: true,
  );

  test('sends the forward as the selected persona', () async {
    final _SendRecorder adapter = _SendRecorder();
    await forward(await open(containerWith(adapter, foxSelected)));

    expect(adapter.sends, hasLength(1));
    expect(adapter.sends.single.body['persona_id'], 'persona_fox');
    expect(
      (adapter.sends.single.body['message_reference']
          as Map<String, dynamic>)['type'],
      1,
    );
  });

  test('sends as the account with nothing selected', () async {
    final _SendRecorder adapter = _SendRecorder();
    await forward(
      await open(containerWith(adapter, const ActivePersonaState())),
    );

    expect(adapter.sends.single.body.containsKey('persona_id'), isFalse);
  });

  ActivePersonaState perChannel(Map<String, String> selections) =>
      ActivePersonaState(
        scope: PersonaScope.channel,
        channelPersonaIds: selections,
      );

  Map<String, Object?> sentAs(_SendRecorder adapter) => <String, Object?>{
    for (final send in adapter.sends) send.channelId: send.body['persona_id'],
  };

  test("sends every destination as the source channel's selection", () async {
    final _SendRecorder adapter = _SendRecorder();
    await forward(
      await open(
        containerWith(
          adapter,
          perChannel(<String, String>{
            'source': 'persona_fox',
            'channel-2': 'persona_bao',
          }),
        ),
      ),
      to: <String>['channel-1', 'channel-2'],
    );

    expect(sentAs(adapter), <String, Object?>{
      'channel-1': 'persona_fox',
      'channel-2': 'persona_fox',
    });
  });

  test("falls back to each destination's selection", () async {
    final _SendRecorder adapter = _SendRecorder();
    await forward(
      await open(
        containerWith(
          adapter,
          perChannel(<String, String>{'channel-2': 'persona_bao'}),
        ),
      ),
      to: <String>['channel-1', 'channel-2'],
    );

    expect(sentAs(adapter), <String, Object?>{
      'channel-1': null,
      'channel-2': 'persona_bao',
    });
  });

  test('sends the forward and its comment as the persona the comment '
      'names, without the tag', () async {
    final _SendRecorder adapter = _SendRecorder();
    await forward(
      await open(containerWith(adapter, foxSelected)),
      comment: 'B: look at this',
    );

    expect(adapter.sends, hasLength(2));
    expect(adapter.sends[0].body['persona_id'], 'persona_bao');
    expect(adapter.sends[1].body['persona_id'], 'persona_bao');
    expect(adapter.sends[1].body['content'], 'look at this');
  });

  test('sends no comment when the comment was only a tag', () async {
    final _SendRecorder adapter = _SendRecorder();
    await forward(
      await open(containerWith(adapter, const ActivePersonaState())),
      comment: 'B:',
    );

    expect(adapter.sends, hasLength(1));
    expect(adapter.sends.single.body['persona_id'], 'persona_bao');
  });

  test('shows a failed forward as the persona and retries as it', () async {
    final _SendRecorder adapter = _SendRecorder()..failSends = true;
    final ProviderContainer container = containerWith(adapter, foxSelected);
    final ChatViewModel notifier = await open(container);
    await forward(notifier);

    final Message failed = container
        .read(chatViewModelProvider)
        .messages
        .singleWhere(isLocalSendPlaceholder);
    expect(failed.personaId, 'persona_fox');
    expect(failed.personaName, 'Fox');

    adapter.failSends = false;
    await notifier.retryMessageSend(failed.id);
    await paginationFlushAsync();

    expect(adapter.sends, hasLength(2));
    expect(adapter.sends.last.body['persona_id'], 'persona_fox');
    expect(adapter.sends.last.body['message_reference'], isNotNull);
  });

  test('keeps the persona of a failed forward across a restart', () async {
    final _SendRecorder adapter = _SendRecorder()..failSends = true;
    final ProviderContainer before = containerWith(adapter, foxSelected);
    await forward(await open(before));
    before.dispose();

    adapter.failSends = false;
    final ProviderContainer after = containerWith(adapter, foxSelected);
    final ChatViewModel notifier = await open(after);
    final Message restored = after
        .read(chatViewModelProvider)
        .messages
        .singleWhere(isLocalSendPlaceholder);
    expect(restored.personaId, 'persona_fox');
    expect(restored.personaName, 'Fox');

    await notifier.retryMessageSend(restored.id);
    await paginationFlushAsync();

    expect(adapter.sends.last.body['persona_id'], 'persona_fox');
    expect(adapter.sends.last.body['message_reference'], isNotNull);
  });
}
