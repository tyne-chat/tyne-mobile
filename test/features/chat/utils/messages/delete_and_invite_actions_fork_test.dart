// Fork: tyne-chat/tyne#946 — regression tests for bulk deleting own messages
// (`confirmAndDeleteMyMessagesInChannel`), invite creation/DM send
// (`createGuildInviteLink` / `sendInviteLinkMessage`), and iOS gift claim
// (`redeemGiftCode`) when the caller unmounts mid-flight.
import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/permissions/channel_permission_cache_provider.dart';
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/chat/data/message_repository.dart';
import 'package:fluxer_app/features/chat/domain/api_attachment_metadata.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_providers.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/chat/utils/messages/delete_my_messages_in_channel_action.dart';
import 'package:fluxer_app/features/dm/data/dm_repository.dart';
import 'package:fluxer_app/features/dm/providers/dm_providers.dart';
import 'package:fluxer_app/features/gifts/providers/gift_embed_provider.dart';
import 'package:fluxer_app/features/gifts/services/gift_redeem_service.dart';
import 'package:fluxer_app/features/guilds/utils/invites/invite_people_actions.dart';
import 'package:fluxer_app/features/ui/toast/toast_provider.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_dart/export.dart' hide ChannelType;

import '../../../../helpers/core_test_provider_overrides.dart';
import '../../../../helpers/open_test_database.dart';
import '../../../../helpers/test_account_user_id.dart';
import '../../../../helpers/test_l10n.dart';

class _SlowChannelsApi implements ChannelsApi {
  final Completer<void> deleteCompleter = Completer<void>();

  @override
  Future<void> bulkDeleteMyMessagesInChannel({
    required String channelId,
    SudoVerificationSchema? body,
  }) => deleteCompleter.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SlowCreateInvitesApi implements InvitesApi {
  final Completer<InviteMetadataResponseSchema> createCompleter =
      Completer<InviteMetadataResponseSchema>();

  @override
  Future<InviteMetadataResponseSchema> createChannelInvite({
    required String channelId,
    ChannelInviteCreateRequest? body,
  }) => createCompleter.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SlowGiftsApi implements GiftsApi {
  final Completer<GiftCodeResponse> getGiftCompleter =
      Completer<GiftCodeResponse>();

  @override
  Future<GiftCodeResponse> getGiftCode({required String code}) =>
      getGiftCompleter.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CompositeTestClient extends FluxerClient {
  _CompositeTestClient({
    this.channelsOverride,
    this.invitesOverride,
    this.giftsOverride,
  }) : super(Dio());

  final ChannelsApi? channelsOverride;
  final InvitesApi? invitesOverride;
  final GiftsApi? giftsOverride;

  @override
  ChannelsApi get channels => channelsOverride ?? super.channels;

  @override
  InvitesApi get invites => invitesOverride ?? super.invites;

  @override
  GiftsApi get gifts => giftsOverride ?? super.gifts;
}

class _RecordingChatViewModel extends ChatViewModel {
  _RecordingChatViewModel({required this.channelId, required this.onReload});

  final String channelId;
  final VoidCallback onReload;

  @override
  ChatViewState build() => ChatViewState.empty.copyWith(channelId: channelId);

  @override
  Future<void> reloadCurrentChannel() async {
    onReload();
  }
}

class _FullInvitePermissionCache extends ChannelPermissionCache {
  @override
  ChannelPermissionCaches build(
    String accountUserId,
  ) => ChannelPermissionCaches(
    effective: <String, int>{
      'c1': Permission.viewChannel.value | Permission.createInstantInvite.value,
    },
  );
}

class _SlowDmRepository extends Fake implements DmRepository {
  final Completer<String> dmCompleter = Completer<String>();

  @override
  Future<String> ensureDmChannel(String recipientId) => dmCompleter.future;
}

class _RecordingMessageRepository extends MessageRepository {
  _RecordingMessageRepository(db.FluxerDatabase database)
    : super(FluxerClient(Dio()), Dio(), database, kTestAccountUserId);

  final List<(String channelId, String content)> sent =
      <(String channelId, String content)>[];

  @override
  Future<Message> sendMessage({
    required String channelId,
    required String content,
    String? replyToId,
    bool replyMention = true,
    String? clientNonce,
    List<String> stickerIds = const <String>[],
    String? favoriteMemeId,
    List<ApiAttachmentMetadata>? attachmentMetadata,
    List<XFile>? attachmentFiles,
    int? messageFlags,
    bool tts = false,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    Map<String, dynamic>? personaData,
  }) async {
    sent.add((channelId, content));
    return Message(
      id: 'm1',
      channelId: channelId,
      authorId: kTestAccountUserId,
      authorName: 'Me',
      content: content,
      timestamp: DateTime.utc(2026, 11, 26),
    );
  }
}

class _RecordingGiftEmbed extends GiftEmbed {
  _RecordingGiftEmbed(this.onRedeem);

  final VoidCallback onRedeem;

  @override
  Future<GiftEmbedState> build(String code) async => GiftEmbedLoaded(
    const GiftCodeResponse(
      code: 'CODE1',
      durationType: GiftCodeDurationTypeSchema.months,
      durationQuantity: 1,
      redeemed: false,
    ),
  );

  @override
  Future<GiftCodeResponse> redeem() async {
    onRedeem();
    return const GiftCodeResponse(
      code: 'CODE1',
      durationType: GiftCodeDurationTypeSchema.months,
      durationQuantity: 1,
      redeemed: true,
    );
  }
}

Widget _wrapApp(ProviderContainer container, Widget body) {
  final colorTheme = buildDarkColorTheme();
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      navigatorKey: rootNavigatorKey,
      locale: kTestLocale,
      localizationsDelegates: fluxerLocalizationsDelegates,
      supportedLocales: FluxerLocalizations.supportedLocales,
      theme: buildFluxerTheme(
        colorTheme: colorTheme,
        textTheme: FluxerTextTheme.fromColors(colorTheme),
        layoutTheme: FluxerLayoutTheme.scaled(),
      ),
      home: Scaffold(body: body),
    ),
  );
}

void main() {
  testWidgets(
    'confirmAndDeleteMyMessagesInChannel reloads channel and shows success toast instead of false error toast when caller unmounts mid-delete',
    (WidgetTester tester) async {
      final db.FluxerDatabase database = openTestDatabase();
      final _SlowChannelsApi channelsApi = _SlowChannelsApi();
      int reloadCount = 0;
      final ValueNotifier<bool> mountCaller = ValueNotifier<bool>(true);
      addTearDown(mountCaller.dispose);

      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: database,
          extra: [
            fluxerClientProvider.overrideWithValue(
              _CompositeTestClient(channelsOverride: channelsApi),
            ),
            chatViewModelProvider.overrideWith(
              () => _RecordingChatViewModel(
                channelId: 'c1',
                onReload: () => reloadCount++,
              ),
            ),
          ],
        ),
      );
      addTearDown(container.dispose);

      Object? actionErr;
      await tester.pumpWidget(
        _wrapApp(
          container,
          ValueListenableBuilder<bool>(
            valueListenable: mountCaller,
            builder: (_, bool mounted, _) => mounted
                ? Consumer(
                    builder: (BuildContext context, WidgetRef ref, _) =>
                        ElevatedButton(
                          onPressed: () {
                            unawaited(
                              confirmAndDeleteMyMessagesInChannel(
                                context,
                                ref,
                                channelId: 'c1',
                                isPrivateConversation: false,
                              ).catchError((Object e) {
                                actionErr = e;
                              }),
                            );
                          },
                          child: const Text('Delete Mine'),
                        ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      );

      await tester.tap(find.text('Delete Mine'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text(testL10n.channelMenuDeleteMyMessagesConfirm));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Switch away / unmount caller while bulkDeleteMyMessagesInChannel awaits.
      mountCaller.value = false;
      await tester.pump();

      channelsApi.deleteCompleter.complete();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(actionErr, isNull);
      expect(reloadCount, 1);
      expect(
        container.read(toastProvider).single.toast.message,
        testL10n.channelMenuDeletedYourMessages,
      );
    },
  );

  testWidgets(
    'createGuildInviteLink and sendInviteLinkMessage succeed without StateError when caller unmounts mid-request',
    (WidgetTester tester) async {
      final db.FluxerDatabase database = openTestDatabase();
      await database.guildDao.upsertServer(
        db.ServersCompanion.insert(
          id: 'g1',
          name: 'Guild 1',
          ownerId: const Value<String?>(kTestAccountUserId),
        ),
      );
      await database.channelDao.upsertChannels(<db.ChannelsCompanion>[
        db.ChannelsCompanion.insert(id: 'c1', guildId: 'g1', name: 'general'),
      ]);

      final _SlowCreateInvitesApi invitesApi = _SlowCreateInvitesApi();
      final _SlowDmRepository dmRepo = _SlowDmRepository();
      final _RecordingMessageRepository msgRepo = _RecordingMessageRepository(
        database,
      );
      final ValueNotifier<bool> mountCaller = ValueNotifier<bool>(true);
      addTearDown(mountCaller.dispose);

      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: database,
          extra: [
            fluxerClientProvider.overrideWithValue(
              _CompositeTestClient(invitesOverride: invitesApi),
            ),
            channelPermissionCacheProvider(
              kTestAccountUserId,
            ).overrideWith(_FullInvitePermissionCache.new),
            dmRepositoryProvider.overrideWithValue(dmRepo),
            messageRepositoryProvider.overrideWithValue(msgRepo),
          ],
        ),
      );
      addTearDown(container.dispose);

      Object? inviteErr;
      ({String url, String channelName, bool useVanityUrl})? inviteResult;
      Object? sendErr;
      bool sendDone = false;

      await tester.pumpWidget(
        _wrapApp(
          container,
          ValueListenableBuilder<bool>(
            valueListenable: mountCaller,
            builder: (_, bool mounted, _) => mounted
                ? Consumer(
                    builder: (_, WidgetRef ref, _) => ElevatedButton(
                      onPressed: () {
                        unawaited(
                          createGuildInviteLink(
                            ref: ref,
                            guildId: 'g1',
                            channelId: 'c1',
                          ).then(
                            (res) => inviteResult = res,
                            onError: (Object e) => inviteErr = e,
                          ),
                        );
                        unawaited(
                          sendInviteLinkMessage(
                            ref: ref,
                            channelId: null,
                            recipientId: 'u2',
                            url: 'https://invite.example/abc',
                          ).then(
                            (_) => sendDone = true,
                            onError: (Object e) => sendErr = e,
                          ),
                        );
                      },
                      child: const Text('Create & Send'),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      );

      await tester.tap(find.text('Create & Send'));
      await tester.pump();
      await tester.pump();

      mountCaller.value = false;
      await tester.pump();

      invitesApi.createCompleter.complete(
        InviteMetadataResponseSchema.fromJson(<String, Object?>{
          'code': 'freshcode',
          'temporary': false,
          'type': 0,
          'guild': <String, Object?>{'id': 'g1', 'name': 'Guild 1'},
          'channel': <String, Object?>{
            'id': 'c1',
            'type': 0,
            'name': 'general',
          },
          'member_count': 1,
          'presence_count': 1,
        }),
      );
      dmRepo.dmCompleter.complete('dm-u2');
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(inviteErr, isNull);
      expect(inviteResult?.url, endsWith('/freshcode'));
      expect(sendErr, isNull);
      expect(sendDone, isTrue);
      expect(msgRepo.sent, <(String, String)>[
        ('dm-u2', 'https://invite.example/abc'),
      ]);
    },
  );

  testWidgets(
    'redeemGiftCode on iOS completes redemption without StateError when caller unmounts while getGiftCode awaits',
    (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        final db.FluxerDatabase database = openTestDatabase();
        final _SlowGiftsApi giftsApi = _SlowGiftsApi();
        final ValueNotifier<bool> mountCaller = ValueNotifier<bool>(true);
        addTearDown(mountCaller.dispose);
        int redeemCalls = 0;

        final ProviderContainer container = ProviderContainer(
          overrides: coreTestProviderOverrides(
            database: database,
            extra: [
              fluxerClientProvider.overrideWithValue(
                _CompositeTestClient(giftsOverride: giftsApi),
              ),
              giftEmbedProvider(
                'CODE1',
              ).overrideWith(() => _RecordingGiftEmbed(() => redeemCalls++)),
            ],
          ),
        );
        addTearDown(container.dispose);

        Object? redeemErr;
        bool? redeemOk;

        await tester.pumpWidget(
          _wrapApp(
            container,
            ValueListenableBuilder<bool>(
              valueListenable: mountCaller,
              builder: (_, bool mounted, _) => mounted
                  ? Consumer(
                      builder: (BuildContext context, WidgetRef ref, _) =>
                          ElevatedButton(
                            onPressed: () {
                              unawaited(
                                redeemGiftCode(
                                  context: context,
                                  ref: ref,
                                  code: 'CODE1',
                                ).then(
                                  (bool ok) => redeemOk = ok,
                                  onError: (Object e) => redeemErr = e,
                                ),
                              );
                            },
                            child: const Text('Redeem Gift'),
                          ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        );

        await tester.tap(find.text('Redeem Gift'));
        await tester.pump();

        mountCaller.value = false;
        await tester.pump();

        giftsApi.getGiftCompleter.complete(
          const GiftCodeResponse(
            code: 'CODE1',
            durationType: GiftCodeDurationTypeSchema.months,
            durationQuantity: 1,
            redeemed: false,
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(redeemErr, isNull);
        expect(redeemOk, isTrue);
        expect(redeemCalls, 1);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
