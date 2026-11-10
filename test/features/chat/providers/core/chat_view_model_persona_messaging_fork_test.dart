// Fork: what the chat view model sends for personas, and what the messages on
// screen end up as: stickers and voice messages sent as a persona, a failed
// send retried as the persona it was first sent as, edits and the replace
// command that move a message to another persona or back to the account,
// "Change persona", and reactions as a persona, with "React as several personas
// at once" on and off (tyne-chat/tyne#86; the requests are counted). Only the
// persona's id goes on the wire (`persona_id`); the server builds the
// `subprofile`.
@Tags(['slow'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' hide Message;
import 'package:fluxer_app/core/providers/app/app_ui_lifecycle_provider.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/channels/data/ack_batcher.dart';
import 'package:fluxer_app/features/channels/providers/ack_batcher_provider.dart';
import 'package:fluxer_app/features/chat/data/persona_emoji_usage_store.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/chat/providers/pickers/sticker_picker_provider.dart';
import 'package:fluxer_app/features/chat/providers/upload/attachment_upload_client_provider.dart';
import 'package:fluxer_app/features/chat/providers/upload/user_upload_limits_provider.dart';
import 'package:fluxer_app/features/chat/utils/attachments/voice_message_constants.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/providers/multi_persona_reactions_provider.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/l10n/app_locale_provider.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/shared/services/guild_member_hydration_service.dart';
import 'package:fluxer_app/shared/utils/emoji/emoji_registry.dart';
import 'package:fluxer_dart/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../fork_support/wait_until.dart';
import '../../../../helpers/chat_view_model_pagination_test_harness.dart';
import '../../../../helpers/fake_attachment_upload_client.dart';
import '../../../../helpers/noop_guild_member_hydration_service.dart';
import '../../../../helpers/open_test_database.dart';

const String _channelId = 'channel-1';
final String _ownId = paginationSnowflakeForIndex(1);
final String _ownAsFoxId = paginationSnowflakeForIndex(2);
final String _othersId = paginationSnowflakeForIndex(3);

const Persona _fox = Persona(
  id: 'persona_fox',
  name: 'Fox',
  avatarHash: 'fox-avatar',
);
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

/// One request the test server received.
typedef _Request = ({String method, String path, Map<String, dynamic>? body});

/// The channel's messages and the routes the persona paths use. Records each
/// send, edit and reaction, and answers as the server does: a message sent or
/// moved to a persona comes back with that persona's `subprofile`.
class _Server extends PaginatingAdapter {
  _Server({required List<Map<String, Object?>> messages})
    : _byId = <String, Map<String, Object?>>{
        for (final Map<String, Object?> m in messages) m['id']! as String: m,
      },
      super(
        messagesByChannel: <String, List<Map<String, Object?>>>{
          _channelId: messages,
        },
      );

  final Map<String, Map<String, Object?>> _byId;
  final List<_Request> requests = <_Request>[];
  bool failSends = false;
  bool failEdits = false;

  /// Reaction removals are refused from this one on (0 is the first).
  int? refuseReactionRemovalsFrom;
  int _reactionRemovals = 0;

  /// The most reaction requests that were ever waiting for an answer at once.
  int mostReactionRequestsAtOnce = 0;
  int _reactionRequestsOpen = 0;

  List<_Request> where(String method, [Pattern? path]) => requests
      .where(
        (_Request r) =>
            r.method == method && (path == null || r.path.contains(path)),
      )
      .toList(growable: false);

  static const Map<String, List<String>> _json = <String, List<String>>{
    Headers.contentTypeHeader: <String>['application/json'],
  };

  ResponseBody _refused() => ResponseBody.fromString(
    jsonEncode(<String, Object?>{'code': 'NOPE', 'message': 'Refused'}),
    400,
    headers: _json,
  );

  static Map<String, Object?>? _subprofile(Object? personaId) =>
      personaId is String && personaId.isNotEmpty
      ? <String, Object?>{
          'id': personaId,
          'name': personaId == _bao.id ? _bao.name : _fox.name,
        }
      : null;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final String path =
        '${Uri.decodeFull(options.uri.path)}'
        '${options.uri.hasQuery ? '?${options.uri.query}' : ''}';
    if (options.method == 'GET') {
      return super.fetch(options, requestStream, cancelFuture);
    }
    final Map<String, dynamic>? body = await _readBody(options, requestStream);
    requests.add((method: options.method, path: path, body: body));

    if (path.contains('/reactions/')) {
      _reactionRequestsOpen++;
      mostReactionRequestsAtOnce = math.max(
        mostReactionRequestsAtOnce,
        _reactionRequestsOpen,
      );
      // Answered a turn of the event loop later, so requests sent together
      // are seen together.
      await Future<void>.delayed(Duration.zero);
      _reactionRequestsOpen--;
      if (options.method == 'DELETE') {
        final int? refuseFrom = refuseReactionRemovalsFrom;
        if (refuseFrom != null && _reactionRemovals++ >= refuseFrom) {
          return _refused();
        }
      }
      return ResponseBody.fromString('', 204);
    }
    if (options.method == 'POST' && path.endsWith('/messages')) {
      if (failSends) {
        return _refused();
      }
      return ResponseBody.fromString(
        jsonEncode(<String, Object?>{
          ...paginationMessageJson(
            id: paginationSnowflakeForIndex(900 + requests.length),
            channelId: _channelId,
            authorId: 'me',
          ),
          'content': body?['content'] ?? '',
          'nonce': body?['nonce'],
          'subprofile': ?_subprofile(body?['persona_id']),
        }),
        200,
        headers: _json,
      );
    }
    if (options.method == 'PATCH') {
      if (failEdits) {
        return _refused();
      }
      final String messageId = path.split('/').last;
      final Map<String, Object?> current = Map<String, Object?>.of(
        _byId[messageId]!,
      );
      if (body != null && body.containsKey('content')) {
        current['content'] = body['content'];
      }
      if (body != null && body.containsKey('persona_id')) {
        current.remove('subprofile');
        final Map<String, Object?>? subprofile = _subprofile(
          body['persona_id'],
        );
        if (subprofile != null) {
          current['subprofile'] = subprofile;
        }
      }
      current['edited_timestamp'] = DateTime.utc(2026, 11).toIso8601String();
      _byId[messageId] = current;
      return ResponseBody.fromString(jsonEncode(current), 200, headers: _json);
    }
    return ResponseBody.fromString('Not found', 404);
  }

  static Future<Map<String, dynamic>?> _readBody(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
  ) async {
    final Object? data = options.data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (data is FormData) {
      // The SDK's multipart edit sends each field as a part of its own.
      final Map<String, dynamic> fields = <String, dynamic>{
        for (final MapEntry<String, String> f in data.fields) f.key: f.value,
      };
      final Object? json = fields.remove('payload_json');
      return json is String
          ? <String, dynamic>{
              ...fields,
              ...jsonDecode(json) as Map<String, dynamic>,
            }
          : fields;
    }
    if (requestStream == null) {
      return null;
    }
    final List<int> bytes = await requestStream.expand((b) => b).toList();
    if (bytes.isEmpty) {
      return null;
    }
    final Object? decoded = jsonDecode(utf8.decode(bytes));
    return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
  }
}

Map<String, Object?> _message(
  String id, {
  required String authorId,
  required String content,
  String? personaId,
  List<Map<String, Object?>>? reactions,
}) => <String, Object?>{
  ...paginationMessageJson(id: id, channelId: _channelId, authorId: authorId),
  'content': content,
  'subprofile': ?_Server._subprofile(personaId),
  'reactions': ?reactions,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FluxerDatabase db;
  late Directory tempDir;
  late _Server server;

  setUpAll(EmojiRegistry.preload);

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    db = openTestDatabase();
    await db.channelDao.upsertChannel(
      ChannelsCompanion.insert(id: _channelId, guildId: '', name: 'dm'),
    );
    tempDir = await Directory.systemTemp.createTemp('persona_messaging_fork');
    addTearDown(() => tempDir.delete(recursive: true));
    server = _Server(
      messages: <Map<String, Object?>>[
        _message(_ownId, authorId: 'me', content: 'hello world'),
        _message(
          _ownAsFoxId,
          authorId: 'me',
          content: 'fox here',
          personaId: _fox.id,
        ),
        _message(
          _othersId,
          authorId: 'other',
          content: 'hi',
          reactions: <Map<String, Object?>>[
            <String, Object?>{
              'emoji': <String, Object?>{'id': null, 'name': '🎉'},
              'count': 2,
              'me': true,
              'me_root': true,
              'persona_reactions': <Map<String, Object?>>[
                <String, Object?>{
                  'persona_id': _fox.id,
                  'count': 1,
                  'me': true,
                },
              ],
            },
            <String, Object?>{
              'emoji': <String, Object?>{'id': null, 'name': '👍'},
              'count': 1,
              'me': false,
            },
          ],
        ),
      ],
    );
  });

  Future<(ProviderContainer, ChatViewModel)> open({
    ActivePersonaState selection = const ActivePersonaState(),
  }) async {
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://api.fluxer.app/v1'))
      ..httpClientAdapter = server;
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
        attachmentUploadClientProvider.overrideWithValue(
          FakeAttachmentUploadClient(apiDio: Dio(), uploadDio: Dio()),
        ),
        maxAttachmentFileBytesProvider.overrideWithValue(1024 * 1024),
        instanceRuntimeConfigProvider.overrideWithValue(
          testInstanceRuntimeConfig(presignedAttachmentUploads: true),
        ),
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
    // Disposed before the database closes (openTestDatabase's tear-down).
    addTearDown(container.dispose);
    final ChatViewModel notifier = container.read(
      chatViewModelProvider.notifier,
    );
    await notifier.switchChannel(_channelId);
    await paginationFlushAsync();
    return (container, notifier);
  }

  Message shown(ProviderContainer container, String id) => container
      .read(chatViewModelProvider)
      .messages
      .singleWhere((Message m) => m.id == id);

  /// Whether every send has been answered, so nothing is left in flight when
  /// the test ends.
  bool sentAll(ProviderContainer container) =>
      server.where('POST', '/messages').isNotEmpty &&
      container
          .read(chatViewModelProvider)
          .messages
          .every(
            (Message m) => m.deliveryState != MessageDeliveryState.sending,
          );

  int usesOf(ProviderContainer container, String personaId) =>
      container.read(activePersonaProvider).frecencyUsage[personaId]?.count ??
      0;

  const ActivePersonaState foxSelected = ActivePersonaState(
    activePersonaId: 'persona_fox',
    isLatched: true,
  );

  group('sending as a persona', () {
    test('a sticker goes out as the persona it is sent as', () async {
      final (_, ChatViewModel chat) = await open();

      await chat.sendStickerMessage(
        const StickerEntry(
          id: 'sticker-1',
          guildId: 'g1',
          name: 'wave',
          description: '',
          tags: <String>[],
          animated: false,
        ),
        personaData: _fox.toSubprofilePayload(),
      );
      await paginationFlushAsync();

      final List<_Request> sends = server.where('POST', '/messages');
      expect(sends, hasLength(1));
      expect(sends.single.body?['persona_id'], _fox.id);
      expect(sends.single.body?['sticker_ids'], <String>['sticker-1']);
      expect(sends.single.body?.containsKey('subprofile'), isFalse);
    });

    test(
      'a voice message goes out as the persona selected for the channel',
      () async {
        final (ProviderContainer container, ChatViewModel chat) = await open(
          selection: foxSelected,
        );
        final File recording = File('${tempDir.path}/voice.wav')
          ..writeAsBytesSync(List<int>.filled(64, 1));

        await chat.sendVoiceMessage(
          filePath: recording.path,
          duration: 3,
          waveform: 'AAAA',
        );
        final Message pending = container
            .read(chatViewModelProvider)
            .messages
            .last;
        expect(pending.personaId, _fox.id);
        expect(pending.personaName, _fox.name);
        await waitUntil(
          () => sentAll(container),
          'the voice message to be sent',
        );

        final Map<String, dynamic>? body = server
            .where('POST', '/messages')
            .single
            .body;
        expect(body?['persona_id'], _fox.id);
        expect(body?['flags'], kMessageFlagVoiceMessage);
        expect(usesOf(container, _fox.id), 1);
      },
    );

    test(
      'a voice message with nothing selected goes out as the account',
      () async {
        final (ProviderContainer container, ChatViewModel chat) = await open();
        final File recording = File('${tempDir.path}/voice.wav')
          ..writeAsBytesSync(List<int>.filled(64, 1));

        await chat.sendVoiceMessage(
          filePath: recording.path,
          duration: 3,
          waveform: 'AAAA',
        );
        await waitUntil(
          () => sentAll(container),
          'the voice message to be sent',
        );

        expect(
          server
              .where('POST', '/messages')
              .single
              .body
              ?.containsKey('persona_id'),
          isFalse,
        );
      },
    );

    test('a failed send retried goes out as the persona it was sent as, '
        'with its tag on the pending row', () async {
      final (ProviderContainer container, ChatViewModel chat) = await open();
      server.failSends = true;

      await chat.sendMessage(
        text: 'hi there',
        personaData: <String, dynamic>{
          'id': _fox.id,
          'name': _fox.name,
          'avatar': 'fox-avatar',
          'display_tag_text': 'SYS',
          'display_tag_icon': 'tag-icon',
          'color': 0x112233,
        },
      );
      await paginationFlushAsync();
      final Message failed = container
          .read(chatViewModelProvider)
          .messages
          .lastWhere((Message m) => m.hasFailed);
      expect(failed.personaId, _fox.id);
      expect(failed.personaTag, 'SYS');

      server.failSends = false;
      await chat.retryMessageSend(failed.id);
      await paginationFlushAsync();

      final List<_Request> sends = server.where('POST', '/messages');
      expect(sends, hasLength(2));
      expect(sends.last.body?['persona_id'], _fox.id);
      expect(sends.last.body?['content'], 'hi there');
      expect(
        container
            .read(chatViewModelProvider)
            .messages
            .where((Message m) => m.hasFailed),
        isEmpty,
      );
      expect(usesOf(container, _fox.id), 1);
    });

    test('a failed send as the account is retried as the account', () async {
      final (ProviderContainer container, ChatViewModel chat) = await open();
      server.failSends = true;
      await chat.sendMessage(text: 'plain');
      await paginationFlushAsync();
      server.failSends = false;

      final Message failed = container
          .read(chatViewModelProvider)
          .messages
          .lastWhere((Message m) => m.hasFailed);
      await chat.retryMessageSend(failed.id);
      await paginationFlushAsync();

      expect(
        server.where('POST', '/messages').last.body?.containsKey('persona_id'),
        isFalse,
      );
    });
  });

  group('editing', () {
    test(
      'a persona tag added in an edit moves the message to that persona',
      () async {
        final (ProviderContainer container, ChatViewModel chat) = await open();
        chat.startEdit(shown(container, _ownId));

        await chat.saveEditedMessage(text: 'B: hello world, edited');
        await paginationFlushAsync();

        final List<_Request> edits = server.where('PATCH');
        expect(edits, hasLength(1));
        expect(edits.single.body, <String, dynamic>{
          'content': 'hello world, edited',
          'persona_id': _bao.id,
        });
        expect(shown(container, _ownId).personaId, _bao.id);
        expect(shown(container, _ownId).content, 'hello world, edited');
        expect(usesOf(container, _bao.id), 1);
      },
    );

    test(
      "a backslash in an edit moves a persona's message to the account",
      () async {
        final (ProviderContainer container, ChatViewModel chat) = await open();
        chat.startEdit(shown(container, _ownAsFoxId));

        await chat.saveEditedMessage(text: r'\ fox here');
        await paginationFlushAsync();

        expect(server.where('PATCH').single.body, <String, dynamic>{
          'content': 'fox here',
          'persona_id': null,
        });
        expect(shown(container, _ownAsFoxId).personaId, isNull);
      },
    );

    test('an edit without a tag keeps the persona and names none', () async {
      final (ProviderContainer container, ChatViewModel chat) = await open();
      chat.startEdit(shown(container, _ownAsFoxId));

      await chat.saveEditedMessage(text: 'fox, edited');
      await paginationFlushAsync();

      final Map<String, dynamic>? body = server.where('PATCH').single.body;
      expect(body?['content'], 'fox, edited');
      expect(body?.containsKey('persona_id'), isFalse);
      expect(shown(container, _ownAsFoxId).personaId, _fox.id);
    });
  });

  group("changing a message's persona", () {
    test('sends only the new persona and shows the message as it', () async {
      final (ProviderContainer container, ChatViewModel chat) = await open();

      await chat.changeMessagePersona(
        message: shown(container, _ownId),
        persona: _fox,
      );

      expect(server.where('PATCH').single.body, <String, dynamic>{
        'persona_id': _fox.id,
      });
      expect(shown(container, _ownId).personaId, _fox.id);
      expect(container.read(chatViewModelProvider).errorMessage, isNull);
      expect(usesOf(container, _fox.id), 1);
    });

    test('to nobody moves the message to the account', () async {
      final (ProviderContainer container, ChatViewModel chat) = await open();

      await chat.changeMessagePersona(
        message: shown(container, _ownAsFoxId),
        persona: null,
      );

      expect(server.where('PATCH').single.body, <String, dynamic>{
        'persona_id': null,
      });
      expect(shown(container, _ownAsFoxId).personaId, isNull);
    });

    test('a refused change says so and leaves the message as it was', () async {
      final (ProviderContainer container, ChatViewModel chat) = await open();
      server.failEdits = true;

      await chat.changeMessagePersona(
        message: shown(container, _ownId),
        persona: _bao,
      );

      expect(
        container.read(chatViewModelProvider).errorMessage,
        container
            .read(appLocalizationsProvider)
            .fork
            .personaChangeMessageFailed,
      );
      expect(shown(container, _ownId).personaId, isNull);
      expect(usesOf(container, _bao.id), 0);
    });
  });

  group('the replace command', () {
    test('a replacement that starts with a tag moves the last own message to '
        'that persona', () async {
      final (ProviderContainer container, ChatViewModel chat) = await open();

      await chat.applyComposerReplace(
        source: 'fox',
        replacement: 'B:fox',
        global: false,
      );
      await paginationFlushAsync();

      expect(server.where('PATCH').single.path, endsWith('/$_ownAsFoxId'));
      expect(server.where('PATCH').single.body, <String, dynamic>{
        'content': 'fox here',
        'persona_id': _bao.id,
      });
      expect(shown(container, _ownAsFoxId).personaId, _bao.id);
      expect(usesOf(container, _bao.id), 1);
    });

    test('a replacement that starts with a backslash moves the message to '
        'the account', () async {
      final (ProviderContainer container, ChatViewModel chat) = await open();

      await chat.applyComposerReplace(
        source: 'fox',
        replacement: r'\fox',
        global: false,
      );
      await paginationFlushAsync();

      expect(server.where('PATCH').single.body, <String, dynamic>{
        'content': 'fox here',
        'persona_id': null,
      });
      expect(shown(container, _ownAsFoxId).personaId, isNull);
    });

    test(
      'a plain replacement changes the text and keeps the persona',
      () async {
        final (ProviderContainer container, ChatViewModel chat) = await open();

        await chat.applyComposerReplace(
          source: 'here',
          replacement: 'there',
          global: false,
        );
        await paginationFlushAsync();

        final Map<String, dynamic>? body = server.where('PATCH').single.body;
        expect(body?['content'], 'fox there');
        expect(body?.containsKey('persona_id'), isFalse);
        expect(shown(container, _ownAsFoxId).personaId, _fox.id);
      },
    );
  });

  group('reacting as a persona', () {
    Reaction reactionOn(
      ProviderContainer container,
      String messageId,
      String emoji,
    ) => shown(
      container,
      messageId,
    ).reactions.singleWhere((Reaction r) => r.emoji == emoji);

    test(
      'a new reaction is sent with the persona and counted for it',
      () async {
        final (ProviderContainer container, ChatViewModel chat) = await open();

        await chat.toggleReaction(_othersId, '🔥', personaId: _fox.id);
        await paginationFlushAsync();

        final Reaction fire = reactionOn(container, _othersId, '🔥');
        expect(fire.count, 1);
        expect(fire.personaReactions, <String>[_fox.id]);
        expect(fire.meRoot, isFalse);
        final List<_Request> puts = server.where('PUT', '/reactions/🔥/@me');
        expect(puts, hasLength(1));
        expect(puts.single.body, <String, dynamic>{'persona_id': _fox.id});
        expect(
          await PersonaEmojiUsageStore.getRankedKeys(_fox.id),
          hasLength(1),
        );
      },
    );

    test(
      'a reaction already there gains the persona and keeps the others',
      () async {
        final (ProviderContainer container, ChatViewModel chat) = await open();

        await chat.toggleReaction(_othersId, '👍', personaId: _bao.id);
        await paginationFlushAsync();

        final Reaction thumbs = reactionOn(container, _othersId, '👍');
        expect(thumbs.count, 2);
        expect(thumbs.personaReactions, <String>[_bao.id]);
        expect(thumbs.meRoot, isFalse);
        expect(thumbs.hasReacted, isTrue);
      },
    );

    test("removing a persona's reaction leaves the account's", () async {
      final (ProviderContainer container, ChatViewModel chat) = await open();

      await chat.toggleReaction(_othersId, '🎉', personaId: _fox.id);
      await paginationFlushAsync();

      final Reaction party = reactionOn(container, _othersId, '🎉');
      expect(party.count, 1);
      expect(party.personaReactions, isEmpty);
      expect(party.meRoot, isTrue);
      expect(party.hasReacted, isTrue);
      final List<_Request> deletes = server.where(
        'DELETE',
        '/reactions/🎉/@me',
      );
      expect(deletes, hasLength(1));
      expect(
        Uri.parse(deletes.single.path).queryParameters['persona_id'],
        _fox.id,
      );
      expect(await PersonaEmojiUsageStore.getRankedKeys(_fox.id), isEmpty);
    });

    test('a custom emoji is counted for the persona by its id', () async {
      final (_, ChatViewModel chat) = await open();

      await chat.toggleReaction(
        _othersId,
        'blob',
        emojiId: 'emoji-1',
        personaId: _fox.id,
      );
      await paginationFlushAsync();

      expect(await PersonaEmojiUsageStore.getRankedKeys(_fox.id), <String>[
        'custom::emoji-1',
      ]);
    });

    test('with no persona named, the channel selection reacts', () async {
      final (ProviderContainer container, ChatViewModel chat) = await open(
        selection: foxSelected,
      );

      await chat.toggleReaction(_othersId, '🔥');
      await paginationFlushAsync();

      expect(reactionOn(container, _othersId, '🔥').personaReactions, <String>[
        _fox.id,
      ]);
      expect(server.where('PUT', '/reactions/').single.body, <String, dynamic>{
        'persona_id': _fox.id,
      });
    });
  });

  // tyne-chat/tyne#86. With the setting off the account has one reaction per
  // emoji. Taking several off is one request per identity: counted here, with
  // the requests failing too, because a burst of requests signs the user out
  // (tyne-chat/tyne#114).
  group('with "React as several personas at once" off', () {
    Reaction? reactionOn(
      ProviderContainer container,
      String messageId,
      String emoji,
    ) => shown(
      container,
      messageId,
    ).reactions.where((Reaction r) => r.emoji == emoji).firstOrNull;

    List<String?> removedAs() => <String?>[
      for (final _Request r in server.where('DELETE', '/reactions/'))
        Uri.parse(r.path).queryParameters['persona_id'],
    ];

    Future<(ProviderContainer, ChatViewModel)> openWithSettingOff({
      ActivePersonaState selection = const ActivePersonaState(),
    }) async {
      final (ProviderContainer container, ChatViewModel chat) = await open(
        selection: selection,
      );
      container
          .read(multiPersonaReactionsProvider.notifier)
          .syncFromSettings(enabled: false);
      return (container, chat);
    }

    test('a tap on an emoji the account reacted with takes every own reaction '
        'off, one request each', () async {
      final (ProviderContainer container, ChatViewModel chat) =
          await openWithSettingOff();

      await chat.toggleReaction(_othersId, '🎉');
      await paginationFlushAsync();

      expect(reactionOn(container, _othersId, '🎉'), isNull);
      expect(removedAs(), <String?>['0', _fox.id]);
      expect(server.where('PUT'), isEmpty);
      expect(server.requests, hasLength(2));
    });

    test('it does so whichever persona is selected', () async {
      final (ProviderContainer container, ChatViewModel chat) =
          await openWithSettingOff(selection: foxSelected);

      await chat.toggleReaction(_othersId, '🎉');
      await paginationFlushAsync();

      expect(reactionOn(container, _othersId, '🎉'), isNull);
      expect(removedAs(), <String?>['0', _fox.id]);
      expect(server.requests, hasLength(2));
    });

    // 40 personas and the account reacted, next to four other people.
    final List<String> manyIds = <String>[
      for (int i = 0; i < 40; i++) 'persona_$i',
    ];
    _Server serverWithManyOwnReactions() => _Server(
      messages: <Map<String, Object?>>[
        _message(
          _othersId,
          authorId: 'other',
          content: 'hi',
          reactions: <Map<String, Object?>>[
            <String, Object?>{
              'emoji': <String, Object?>{'id': null, 'name': '🎉'},
              'count': 45,
              'me': true,
              'me_root': true,
              'persona_reactions': <Map<String, Object?>>[
                for (final String id in manyIds)
                  <String, Object?>{'persona_id': id, 'count': 1, 'me': true},
              ],
            },
          ],
        ),
      ],
    );

    test('a large system sends one removal per identity, one after the '
        'other', () async {
      server = serverWithManyOwnReactions();
      final (ProviderContainer container, ChatViewModel chat) =
          await openWithSettingOff();

      await chat.toggleReaction(_othersId, '🎉');
      await paginationFlushAsync();

      final Reaction? party = reactionOn(container, _othersId, '🎉');
      expect(party?.count, 4);
      expect(party?.hasReacted, isFalse);
      expect(removedAs(), <String?>['0', ...manyIds]);
      expect(server.requests, hasLength(41));
      expect(server.mostReactionRequestsAtOnce, 1);
    });

    test('a removal the server refuses is the last request: the reactions '
        'not removed stay', () async {
      server = serverWithManyOwnReactions()..refuseReactionRemovalsFrom = 3;
      final (ProviderContainer container, ChatViewModel chat) =
          await openWithSettingOff();

      await chat.toggleReaction(_othersId, '🎉');
      await paginationFlushAsync();

      final Reaction? party = reactionOn(container, _othersId, '🎉');
      expect(party?.count, 42);
      expect(party?.meRoot, isFalse);
      expect(party?.personaReactions, manyIds.sublist(2));
      expect(removedAs(), <String?>['0', ...manyIds.take(3)]);
      expect(server.requests, hasLength(4));
    });

    test("a refused removal of the persona's reaction keeps it and takes the "
        "account's off", () async {
      server.refuseReactionRemovalsFrom = 1;
      final (ProviderContainer container, ChatViewModel chat) =
          await openWithSettingOff();

      await chat.toggleReaction(_othersId, '🎉');
      await paginationFlushAsync();

      final Reaction? party = reactionOn(container, _othersId, '🎉');
      expect(party?.count, 1);
      expect(party?.meRoot, isFalse);
      expect(party?.personaReactions, <String>[_fox.id]);
      expect(removedAs(), <String?>['0', _fox.id]);
      expect(server.requests, hasLength(2));
    });

    test('when the first removal is refused nothing changes and nothing more '
        'is sent', () async {
      server.refuseReactionRemovalsFrom = 0;
      final (ProviderContainer container, ChatViewModel chat) =
          await openWithSettingOff();

      await chat.toggleReaction(_othersId, '🎉');
      await paginationFlushAsync();

      final Reaction? party = reactionOn(container, _othersId, '🎉');
      expect(party?.count, 2);
      expect(party?.meRoot, isTrue);
      expect(party?.personaReactions, <String>[_fox.id]);
      expect(server.requests, hasLength(1));
    });

    test('a tap on an emoji the account has not reacted with adds one '
        'reaction as the current identity', () async {
      final (ProviderContainer container, ChatViewModel chat) =
          await openWithSettingOff(selection: foxSelected);

      await chat.toggleReaction(_othersId, '👍');
      await paginationFlushAsync();

      expect(reactionOn(container, _othersId, '👍')?.personaReactions, <String>[
        _fox.id,
      ]);
      expect(server.requests, hasLength(1));
      expect(
        server.where('PUT', '/reactions/👍/@me').single.body,
        <String, dynamic>{'persona_id': _fox.id},
      );
    });

    test('React as… moves the reaction to the chosen persona: the own ones '
        'come off, then one is added', () async {
      final (ProviderContainer container, ChatViewModel chat) =
          await openWithSettingOff();

      await chat.reactAsOnly(_othersId, '🎉', personaId: _bao.id);
      await paginationFlushAsync();

      final Reaction? party = reactionOn(container, _othersId, '🎉');
      expect(party?.count, 1);
      expect(party?.meRoot, isFalse);
      expect(party?.personaReactions, <String>[_bao.id]);
      expect(
        <String>[for (final _Request r in server.requests) r.method],
        <String>['DELETE', 'DELETE', 'PUT'],
      );
      expect(removedAs(), <String?>['0', _fox.id]);
      expect(server.where('PUT').single.body, <String, dynamic>{
        'persona_id': _bao.id,
      });
      expect(server.mostReactionRequestsAtOnce, 1);
    });

    test('React as… does not add when an own reaction could not be '
        'removed', () async {
      server.refuseReactionRemovalsFrom = 1;
      final (ProviderContainer container, ChatViewModel chat) =
          await openWithSettingOff();

      await chat.reactAsOnly(_othersId, '🎉', personaId: _bao.id);
      await paginationFlushAsync();

      expect(reactionOn(container, _othersId, '🎉')?.personaReactions, <String>[
        _fox.id,
      ]);
      expect(server.where('PUT'), isEmpty);
      expect(server.requests, hasLength(2));
    });

    test(
      'React as… the identity that reacted takes its reaction off',
      () async {
        final (ProviderContainer container, ChatViewModel chat) =
            await openWithSettingOff();

        await chat.reactAsOnly(_othersId, '🎉', personaId: null);
        await paginationFlushAsync();

        final Reaction? party = reactionOn(container, _othersId, '🎉');
        expect(party?.count, 1);
        expect(party?.meRoot, isFalse);
        expect(party?.personaReactions, <String>[_fox.id]);
        expect(removedAs(), <String?>['0']);
        expect(server.requests, hasLength(1));
      },
    );

    test('React as… on an emoji the account has not reacted with adds one '
        'reaction', () async {
      final (ProviderContainer container, ChatViewModel chat) =
          await openWithSettingOff(selection: foxSelected);

      await chat.reactAsOnly(_othersId, '👍', personaId: null);
      await paginationFlushAsync();

      final Reaction? thumbs = reactionOn(container, _othersId, '👍');
      expect(thumbs?.count, 2);
      expect(thumbs?.meRoot, isTrue);
      expect(thumbs?.personaReactions, isEmpty);
      expect(server.requests, hasLength(1));
      // The SDK sends an empty object when there is no persona: the account.
      expect(server.where('PUT').single.body, <String, dynamic>{});
    });

    test('with the setting on, a tap takes off only the current '
        "identity's reaction", () async {
      final (ProviderContainer container, ChatViewModel chat) = await open();

      await chat.toggleReaction(_othersId, '🎉');
      await paginationFlushAsync();

      final Reaction? party = reactionOn(container, _othersId, '🎉');
      expect(party?.count, 1);
      expect(party?.meRoot, isFalse);
      expect(party?.personaReactions, <String>[_fox.id]);
      expect(removedAs(), <String?>['0']);
      expect(server.requests, hasLength(1));
    });
  });
}
