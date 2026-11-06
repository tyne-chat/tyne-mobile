// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as cache;
import 'package:fluxer_app/core/providers/app/app_ui_lifecycle_provider.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/channels/data/ack_batcher.dart';
import 'package:fluxer_app/features/channels/providers/ack_batcher_provider.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/chat/providers/messages/typing_sender.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/shared/services/guild_member_hydration_service.dart';
import 'package:fluxer_dart/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/chat_view_model_pagination_test_harness.dart';
import '../../../../helpers/noop_guild_member_hydration_service.dart';
import '../../../../helpers/open_test_database.dart';

// Fork: what the chat view model does with personas outside sending: a persona
// or the account's display tag edited elsewhere reaches the messages already on
// screen, the reply and edit in progress, and the cache, and typing as a
// persona names it once the persona's tag is complete.

class _FakeMyPersonasNotifier extends MyPersonasNotifier {
  _FakeMyPersonasNotifier(this._personas);

  final List<Persona> _personas;

  @override
  AsyncValue<List<Persona>> build() => AsyncData(_personas);
}

class _RecordingTypingSender extends TypingSender {
  final List<({String channelId, String? personaId})> sent = [];
  final List<Map<String, dynamic>?> payloads = [];

  @override
  Future<void> notifyUserTyping(
    String channelId, {
    Map<String, dynamic>? personaData,
  }) async {
    sent.add((channelId: channelId, personaId: personaData?['id'] as String?));
    payloads.add(personaData);
  }
}

const Persona _alice = Persona(
  id: 'persona_a',
  name: 'Alice',
  personaTags: [PersonaTag(prefix: 'a:', suffix: '')],
);

Map<String, Object?> _messageAs(String id, {String? personaId, String? name}) {
  final Map<String, Object?> json = paginationMessageJson(
    id: id,
    channelId: 'channel-1',
    authorId: 'other',
  );
  if (personaId != null) {
    json['subprofile'] = <String, Object?>{'id': personaId, 'name': name};
  }
  return json;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late cache.FluxerDatabase db;
  late ProviderContainer container;
  late ChatViewModel viewModel;
  late _RecordingTypingSender typing;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = openTestDatabase();
    final adapter = PaginatingAdapter(
      messagesByChannel: {
        'channel-1': [
          _messageAs(
            paginationSnowflakeForIndex(1),
            personaId: 'persona_a',
            name: 'Alice',
          ),
          _messageAs(paginationSnowflakeForIndex(2)),
          _messageAs(
            paginationSnowflakeForIndex(3),
            personaId: 'persona_b',
            name: 'Bob',
          ),
        ],
      },
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://api.fluxer.app/v1'))
      ..httpClientAdapter = adapter;
    final client = FluxerClient(dio, baseUrl: 'https://api.fluxer.app/v1');
    typing = _RecordingTypingSender();
    container = ProviderContainer(
      overrides: [
        fluxerDatabaseProvider.overrideWithValue(db),
        appUiForegroundProvider.overrideWithValue(true),
        fluxerDioProvider.overrideWithValue(dio),
        fluxerClientProvider.overrideWithValue(client),
        currentUserIdProvider.overrideWithValue('me'),
        myPersonasProvider.overrideWith(
          () => _FakeMyPersonasNotifier(const [_alice]),
        ),
        typingSenderProvider.overrideWith(() => typing),
        ackBatcherProvider.overrideWith((ref) {
          final batcher = AckBatcher(client: client, batchDelay: Duration.zero);
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

    viewModel = container.read(chatViewModelProvider.notifier);
    await viewModel.switchChannel('channel-1');
    await paginationFlushAsync();
  });

  List<Message> shown() => container.read(chatViewModelProvider).messages;

  Message shownAs(String personaId) =>
      shown().singleWhere((Message m) => m.personaId == personaId);

  Future<void> startReplyTo(Message message) async {
    viewModel.startReply(message);
    await paginationFlushAsync();
    expect(container.read(chatViewModelProvider).replyingTo?.id, message.id);
  }

  Future<List<cache.Message>> cachedOnceRenamed(
    bool Function(List<cache.Message> rows) done,
  ) async {
    final Stopwatch waited = Stopwatch()..start();
    List<cache.Message> rows;
    do {
      await pumpEventQueue();
      rows = await db.select(db.messages).get();
      if (waited.elapsed > const Duration(seconds: 10)) {
        fail('Timed out waiting for the cached messages to change');
      }
    } while (!done(rows));
    return rows;
  }

  group('a persona edited elsewhere', () {
    test('reaches its messages on screen and leaves the others alone', () {
      expect(
        shown().where((m) => m.personaId == 'persona_a').single.personaName,
        'Alice',
      );

      viewModel.onPersonaUpdated(
        personaId: 'persona_a',
        name: 'Alicia',
        avatar: 'avatar-hash',
        tag: 'SYS',
        tagIcon: null,
      );

      final Message updated = shown().singleWhere(
        (m) => m.personaId == 'persona_a',
      );
      expect(updated.personaName, 'Alicia');
      expect(updated.personaAvatar, 'avatar-hash');
      expect(updated.personaTag, 'SYS');
      expect(
        shown().singleWhere((m) => m.personaId == 'persona_b').personaName,
        'Bob',
      );
    });

    test('reaches its messages in the cache', () async {
      viewModel.onPersonaUpdated(
        personaId: 'persona_a',
        name: 'Alicia',
        avatar: null,
        tag: null,
        tagIcon: null,
      );

      final Stopwatch waited = Stopwatch()..start();
      List<cache.Message> cached;
      do {
        await pumpEventQueue();
        cached = await (db.select(
          db.messages,
        )..where((m) => m.personaId.equals('persona_a'))).get();
        if (waited.elapsed > const Duration(seconds: 10)) {
          fail('Timed out waiting for the cached message to be renamed');
        }
      } while (cached.isEmpty || cached.any((m) => m.personaName != 'Alicia'));
      expect(cached, hasLength(1));
    });

    test('reaches the reply and the edit in progress', () async {
      await startReplyTo(shownAs('persona_a'));

      viewModel.onPersonaUpdated(
        personaId: 'persona_a',
        name: 'Alicia',
        avatar: null,
        tag: null,
        tagIcon: null,
      );
      expect(
        container.read(chatViewModelProvider).replyingTo?.personaName,
        'Alicia',
      );

      viewModel
        ..startEdit(shownAs('persona_b'))
        ..onPersonaUpdated(
          personaId: 'persona_b',
          name: 'Bobby',
          avatar: null,
          tag: null,
          tagIcon: null,
        );
      expect(
        container.read(chatViewModelProvider).editingMessage?.personaName,
        'Bobby',
      );
    });

    test('changes nothing for an empty persona id', () {
      final List<Message> before = shown();

      viewModel.onPersonaUpdated(
        personaId: '',
        name: 'Nobody',
        avatar: null,
        tag: null,
        tagIcon: null,
      );

      expect(identical(shown(), before), isTrue);
    });
  });

  group("the account's display tag edited elsewhere", () {
    test(
      "reaches that account's persona messages on screen, and only them",
      () {
        viewModel.onAuthorDisplayTagUpdated(
          authorId: 'other',
          tag: 'SYS',
          tagIcon: 'icon-hash',
        );

        expect(shownAs('persona_a').personaTag, 'SYS');
        expect(shownAs('persona_a').personaTagIcon, 'icon-hash');
        expect(shownAs('persona_b').personaTag, 'SYS');
        expect(
          shown().singleWhere((Message m) => m.personaId == null).personaTag,
          isNull,
          reason: "the account's own messages show no display tag",
        );
      },
    );

    test('reaches the reply and the edit in progress', () async {
      await startReplyTo(shownAs('persona_a'));
      viewModel.onAuthorDisplayTagUpdated(
        authorId: 'other',
        tag: 'SYS',
        tagIcon: null,
      );
      expect(
        container.read(chatViewModelProvider).replyingTo?.personaTag,
        'SYS',
      );

      viewModel
        ..startEdit(shownAs('persona_b'))
        ..onAuthorDisplayTagUpdated(
          authorId: 'other',
          tag: 'NEW',
          tagIcon: null,
        );
      expect(
        container.read(chatViewModelProvider).editingMessage?.personaTag,
        'NEW',
      );
    });

    test("reaches that account's persona messages in the cache", () async {
      viewModel.onAuthorDisplayTagUpdated(
        authorId: 'other',
        tag: 'SYS',
        tagIcon: null,
      );

      final List<cache.Message> rows = await cachedOnceRenamed(
        (List<cache.Message> rows) => rows
            .where((cache.Message m) => m.personaId != null)
            .every((cache.Message m) => m.personaTag == 'SYS'),
      );
      expect(
        rows.where((cache.Message m) => m.personaTag == 'SYS'),
        hasLength(2),
      );
    });

    test('changes nothing for another account or an empty id', () {
      final List<Message> before = shown();

      viewModel
        ..onAuthorDisplayTagUpdated(authorId: 'me', tag: 'SYS', tagIcon: null)
        ..onAuthorDisplayTagUpdated(authorId: '', tag: 'SYS', tagIcon: null);

      expect(identical(shown(), before), isTrue);
    });
  });

  group('typing as a persona', () {
    test('says nothing while the text could still become a persona tag', () {
      viewModel.updateMessageText('a');

      expect(typing.sent, isEmpty);
    });

    test('names the persona once its tag is complete', () {
      viewModel.updateMessageText('a:hello');

      expect(typing.sent, [(channelId: 'channel-1', personaId: 'persona_a')]);
    });

    test("sends the account's display tag along with the persona", () {
      container
          .read(systemDisplayTagProvider.notifier)
          .syncFromSettings(text: '  SYS  ', iconUrl: ' icon-hash ');

      viewModel.updateMessageText('a:hello');

      expect(typing.payloads.single, containsPair('display_tag_text', 'SYS'));
      expect(
        typing.payloads.single,
        containsPair('display_tag_icon', 'icon-hash'),
      );
    });

    test('names no persona for text without a tag', () {
      viewModel.updateMessageText('hello');

      expect(typing.sent, [(channelId: 'channel-1', personaId: null)]);
    });
  });
}
