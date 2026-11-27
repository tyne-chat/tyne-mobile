// Fork: tyne-chat/tyne#946 — regression tests for Group C async WidgetRef
// disposal hazards across dispatchMessageAction (speak / translate),
// showMoveChannelToCategorySheet, and ChannelFollowSheet.

import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/channels/data/channel_repository.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/channels/domain/channel_move_operation.dart';
import 'package:fluxer_app/features/channels/presentation/sheets/channel_follow_sheet.dart';
import 'package:fluxer_app/features/channels/presentation/sheets/move_channel_to_category_sheet.dart';
import 'package:fluxer_app/features/channels/providers/channel_providers.dart';
import 'package:fluxer_app/features/chat/data/message_translation_service.dart';
import 'package:fluxer_app/features/chat/data/message_translation_source.dart';
import 'package:fluxer_app/features/chat/domain/chat_fullscreen_video_launch_context.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/domain/message_translation.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/message_actions/message_bottom_sheet.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/chat/providers/messages/message_translation_provider.dart';
import 'package:fluxer_app/features/guilds/domain/guild.dart';
import 'package:fluxer_app/features/guilds/providers/guild_list_view_model.dart';
import 'package:fluxer_app/features/profile/providers/user_settings_status_provider.dart';
import 'package:fluxer_app/features/voice/tts/fluxer_tts_provider.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/utils/fluxer_haptics.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../helpers/core_test_provider_overrides.dart';
import '../../../../../helpers/open_test_database.dart';
import '../../../../../helpers/test_l10n.dart';

Widget _appShell({
  required ProviderContainer container,
  required Widget child,
}) {
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
      home: child,
    ),
  );
}

class _SlowTtsService extends FluxerTtsService {
  final Completer<bool> supportCompleter = Completer<bool>();
  final List<String> spokenMessageIds = <String>[];

  @override
  FluxerTtsSpeakingState build() => const FluxerTtsSpeakingState();

  @override
  Future<bool> isSupported() => supportCompleter.future;

  @override
  Future<void> speakMessage({
    required Message message,
    required double rate,
    String? locale,
  }) async {
    spokenMessageIds.add(message.id);
  }
}

class _SlowTranslationService extends MessageTranslationService {
  _SlowTranslationService(db.FluxerDatabase database)
    : super(
        messageDao: database.messageDao,
        sources: const <MessageTranslationSource>[],
      );

  final Completer<Message> translateCompleter = Completer<Message>();

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<Message> translateMessage({
    required Message message,
    required String targetLanguage,
  }) => translateCompleter.future;
}

class _RecordingChatViewModel extends ChatViewModel {
  final List<(String messageId, MessageTranslation? translation)>
  appliedTranslations = <(String, MessageTranslation?)>[];

  @override
  ChatViewState build() => ChatViewState.empty.copyWith(channelId: 'c1');

  @override
  void applyMessageTranslation({
    required String messageId,
    required MessageTranslation? translation,
  }) {
    appliedTranslations.add((messageId, translation));
  }
}

class _RecordingMoveChannelRepository extends Fake
    implements ChannelRepository {
  final List<(String guildId, ChannelMoveOperation operation)> moved =
      <(String, ChannelMoveOperation)>[];

  @override
  Future<void> moveChannel({
    required String guildId,
    required ChannelMoveOperation operation,
    List<Channel>? rollbackChannels,
  }) async {
    moved.add((guildId, operation));
  }
}

class _FixedGuildListViewModel extends GuildListViewModel {
  @override
  GuildListViewState build() => const GuildListViewState(
    guilds: <Guild>[Guild(id: 'g1', name: 'Alpha')],
  );
}

class _StreamChannelRepository extends Fake implements ChannelRepository {
  _StreamChannelRepository(this.stream);

  final Stream<List<Channel>> stream;

  @override
  Stream<List<Channel>> watchChannels(String guildId) => stream;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FluxerHaptics.enabled = false;
  });

  tearDown(() {
    FluxerHaptics.enabled = true;
  });

  testWidgets(
    'dispatchMessageAction speak and translate complete cleanly when caller ref unmounts mid-flight',
    (WidgetTester tester) async {
      final db.FluxerDatabase database = openTestDatabase();
      final _SlowTtsService ttsService = _SlowTtsService();
      final _SlowTranslationService translationService =
          _SlowTranslationService(database);
      final _RecordingChatViewModel chatVm = _RecordingChatViewModel();

      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: database,
          extra: <Override>[
            userSettingsStatusProvider.overrideWithValue(null),
            fluxerTtsServiceProvider.overrideWith(() => ttsService),
            messageTranslationAvailableProvider.overrideWith(
              (Ref ref) => Future<bool>.value(true),
            ),
            messageTranslationServiceProvider.overrideWithValue(
              translationService,
            ),
            chatViewModelProvider.overrideWith(() => chatVm),
          ],
        ),
      );
      addTearDown(container.dispose);

      final ValueNotifier<bool> mountCaller = ValueNotifier<bool>(true);
      addTearDown(mountCaller.dispose);
      final Message sampleMessage = Message(
        id: 'm1',
        channelId: 'c1',
        authorId: 'u2',
        authorName: 'bob',
        content: 'bonjour',
        timestamp: DateTime(2026, 5, 6, 12),
      );

      await tester.pumpWidget(
        _appShell(
          container: container,
          child: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: mountCaller,
              builder: (_, bool mounted, _) {
                if (!mounted) {
                  return const SizedBox.shrink();
                }
                return Consumer(
                  builder: (BuildContext ctx, WidgetRef ref, _) => Column(
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: () => unawaited(
                          dispatchMessageAction(
                            ref: ref,
                            context: ctx,
                            message: sampleMessage,
                            action: MessageAction.speak,
                            callbacks: const MessageActionCallbacks(),
                          ),
                        ),
                        child: const Text('Speak'),
                      ),
                      ElevatedButton(
                        onPressed: () => unawaited(
                          dispatchMessageAction(
                            ref: ref,
                            context: ctx,
                            message: sampleMessage,
                            action: MessageAction.translate,
                            callbacks: const MessageActionCallbacks(),
                          ),
                        ),
                        child: const Text('Translate'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      // 1. MessageAction.speak: unmount caller before tts.isSupported() completes.
      await tester.tap(find.text('Speak'));
      await tester.pump();
      mountCaller.value = false;
      await tester.pump();

      ttsService.supportCompleter.complete(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(ttsService.spokenMessageIds, <String>['m1']);

      // 2. MessageAction.translate: remount caller, dispatch, unmount mid-translate.
      mountCaller.value = true;
      await tester.pump();

      await tester.tap(find.text('Translate'));
      await tester.pump();
      await tester.pump();
      mountCaller.value = false;
      await tester.pump();

      const MessageTranslation translated = MessageTranslation(
        sourceContent: 'bonjour',
        sourceLanguageCode: 'fr',
        targetLanguageCode: 'en',
        translatedContent: 'hello',
      );
      translationService.translateCompleter.complete(
        sampleMessage.copyWith(translation: translated),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(chatVm.appliedTranslations, <(String, MessageTranslation?)>[
        ('m1', translated),
      ]);
      expect(container.read(translatingMessageIdsProvider), isEmpty);
    },
  );

  testWidgets(
    'showMoveChannelToCategorySheet moves channel cleanly when launching ref unmounts while sheet is open',
    (WidgetTester tester) async {
      final db.FluxerDatabase database = openTestDatabase();
      await database.channelDao.upsertChannels(<db.ChannelsCompanion>[
        db.ChannelsCompanion.insert(
          id: 'cat1',
          guildId: 'g1',
          name: 'Category One',
          type: Value(ChannelType.guildCategory.wireValue),
        ),
        db.ChannelsCompanion.insert(
          id: 'c1',
          guildId: 'g1',
          name: 'general',
          type: Value(ChannelType.guildText.wireValue),
          position: const Value(1),
        ),
      ]);

      final _RecordingMoveChannelRepository channelRepo =
          _RecordingMoveChannelRepository();
      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: database,
          extra: <Override>[
            channelRepositoryProvider.overrideWithValue(channelRepo),
          ],
        ),
      );
      addTearDown(container.dispose);

      final ValueNotifier<bool> mountLauncher = ValueNotifier<bool>(true);
      addTearDown(mountLauncher.dispose);
      late BuildContext rootCtx;

      await tester.pumpWidget(
        _appShell(
          container: container,
          child: Builder(
            builder: (BuildContext outerCtx) {
              rootCtx = outerCtx;
              return Scaffold(
                body: ValueListenableBuilder<bool>(
                  valueListenable: mountLauncher,
                  builder: (_, bool mounted, _) {
                    if (!mounted) {
                      return const SizedBox.shrink();
                    }
                    return Consumer(
                      builder: (_, WidgetRef ref, _) => ElevatedButton(
                        onPressed: () => unawaited(
                          showMoveChannelToCategorySheet(
                            rootCtx,
                            ref,
                            guildId: 'g1',
                            channelId: 'c1',
                          ),
                        ),
                        child: const Text('MoveChannel'),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('MoveChannel'));
      await tester.pumpAndSettle();
      expect(find.text('Category One'), findsOneWidget);

      mountLauncher.value = false;
      await tester.pump();

      await tester.tap(find.text('Category One'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(channelRepo.moved, hasLength(1));
      expect(channelRepo.moved.single.$1, 'g1');
      expect(channelRepo.moved.single.$2.newParentId, 'cat1');
    },
  );

  testWidgets(
    'ChannelFollowSheet completes watchChannels future without StateError when dismissed while loading',
    (WidgetTester tester) async {
      final db.FluxerDatabase database = openTestDatabase();
      final StreamController<List<Channel>> channelsController =
          StreamController<List<Channel>>.broadcast();
      addTearDown(channelsController.close);
      final _StreamChannelRepository channelRepo = _StreamChannelRepository(
        channelsController.stream,
      );

      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: database,
          extra: <Override>[
            guildListViewModelProvider.overrideWith(
              _FixedGuildListViewModel.new,
            ),
            channelRepositoryProvider.overrideWithValue(channelRepo),
          ],
        ),
      );
      addTearDown(container.dispose);

      const Channel sourceChannel = Channel(
        id: 'ann-1',
        guildId: 'g1',
        name: 'announcements',
        type: ChannelType.guildAnnouncement,
      );

      await tester.pumpWidget(
        _appShell(
          container: container,
          child: Builder(
            builder: (BuildContext context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => unawaited(
                  ChannelFollowSheet.show(context, channel: sourceChannel),
                ),
                child: const Text('OpenFollow'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OpenFollow'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      Navigator.of(rootNavigatorKey.currentContext!).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      channelsController.add(const <Channel>[
        Channel(id: 'txt-1', guildId: 'g1', name: 'updates'),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
    },
  );
}
