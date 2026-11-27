// Fork: tyne-chat/tyne#946 — regression tests for Group B (chat/composer/drawer)
// post-await WidgetRef/BuildContext disposal hazards across
// ChannelDetailsDrawerOverlay, showFavoriteGifFirstTimePrompt,
// ChannelHeaderSearchField, UploadDropOverlay, and ComposerAutocompleteField.

import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/providers/gateway/gateway_connection_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/chat/data/channel_search_history_repository.dart';
import 'package:fluxer_app/features/chat/data/channel_search_query_parser.dart';
import 'package:fluxer_app/features/chat/data/message_search_repository.dart';
import 'package:fluxer_app/features/chat/domain/channel_search_chip_filters.dart';
import 'package:fluxer_app/features/chat/domain/cloud_composer_attachments.dart';
import 'package:fluxer_app/features/chat/presentation/sheets/favorite_gif_first_time_prompt_sheet.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/channel/channel_details_drawer_overlay.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/channel/header/channel_header_search_field.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/composer/upload_drop_overlay.dart';
import 'package:fluxer_app/features/chat/providers/channel/channel_details_drawer_provider.dart';
import 'package:fluxer_app/features/chat/providers/channel/channel_details_providers.dart';
import 'package:fluxer_app/features/chat/providers/channel/channel_message_permissions_provider.dart';
import 'package:fluxer_app/features/chat/providers/pickers/emoji_picker_provider.dart';
import 'package:fluxer_app/features/chat/providers/pickers/favorite_gifs_provider.dart';
import 'package:fluxer_app/features/chat/providers/upload/cloud_upload_controller.dart';
import 'package:fluxer_app/features/chat/utils/attachments/file_upload_validator.dart';
import 'package:fluxer_app/features/chat/utils/composer/composer_upload_file.dart';
import 'package:fluxer_app/features/guild_commands/providers/guild_commands_providers.dart';
import 'package:fluxer_app/features/settings/providers/preferences/advanced_preferences_provider.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/utils/emoji/emoji_registry.dart';
import 'package:fluxer_dart/export.dart' hide ChannelType;
import 'package:fluxer_dart/gateway.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../helpers/composer_channel_textarea_harness.dart';
import '../../../../../helpers/core_test_provider_overrides.dart';
import '../../../../../helpers/open_test_database.dart';
import '../../../../../helpers/test_account_user_id.dart';
import '../../../../../helpers/test_l10n.dart';

Widget _shell({required ProviderContainer container, required Widget child}) {
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

class _SuspendingAdvancedPreferences extends AdvancedPreferences {
  _SuspendingAdvancedPreferences(this.saveCompleter);

  final Completer<void> saveCompleter;

  @override
  AdvancedPreferencesState build() => const AdvancedPreferencesState();

  @override
  Future<void> setSaveGifFavoritesAsSavedMedia({required bool value}) async {
    state = state.copyWith(saveGifFavoritesAsSavedMedia: value);
    await saveCompleter.future;
  }
}

class _RecordingFavoriteGifs extends FavoriteGifs {
  @override
  FavoriteGifsState build() => const FavoriteGifsState();

  @override
  void markFirstTimePromptSeen() {
    state = FavoriteGifsState(
      entries: state.entries,
      seenFirstTimePrompt: true,
    );
  }
}

class _SuspendingChannelSearch extends ChannelSearch {
  _SuspendingChannelSearch(this.completer);

  final Completer<void> completer;

  @override
  ChannelSearchState build(String channelId, String? guildId) =>
      ChannelSearchState(
        query: MessageSearchQuery(channelId: channelId, guildId: guildId),
      );

  @override
  Future<void> search({
    MessageSearchQuery? query,
    String? rawQuery,
    String? text,
    ChannelSearchParseHints? hints,
    ChannelSearchParseContext? context,
    MessageSearchScopeFilter? scope,
    MessageSearchSortFilter? sort,
    String? authorId,
    Set<MessageSearchContentFilter>? contentTypes,
    ChannelSearchChipFilters chipFilters = const ChannelSearchChipFilters(),
  }) async {
    await completer.future;
  }
}

class _SuspendingCloudUploadController extends CloudUploadController {
  _SuspendingCloudUploadController(this.completer);

  final Completer<FileUploadValidationResult> completer;

  @override
  CloudComposerAttachments build(String accountUserId, String channelId) =>
      CloudComposerAttachments.empty;

  @override
  Future<FileUploadValidationResult> addFiles(List<ComposerUploadFile> files) =>
      completer.future;
}

class _QuietGatewayConnection extends GatewayConnection {
  _QuietGatewayConnection() : super(token: 'test', dio: Dio());

  @override
  Future<void> connect() async {}

  @override
  Future<void> suspend() async {}
}

class _InertGuildCommands extends GuildCommandsNotifier {
  @override
  Future<void> loadForList() async {}
}

void main() {
  testWidgets(
    'ChannelDetailsDrawerOverlay _moveToClosed and showFavoriteGifFirstTimePrompt survive unmount',
    (WidgetTester tester) async {
      final db.FluxerDatabase mockDb = openTestDatabase();
      final Completer<void> saveCompleter = Completer<void>();
      final _QuietGatewayConnection gateway = _QuietGatewayConnection();
      addTearDown(gateway.dispose);
      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: mockDb,
          extra: <Override>[
            gatewayConnectionProvider.overrideWithValue(gateway),
            advancedPreferencesProvider.overrideWith(
              () => _SuspendingAdvancedPreferences(saveCompleter),
            ),
            favoriteGifsProvider.overrideWith(_RecordingFavoriteGifs.new),
          ],
        ),
      );
      addTearDown(container.dispose);

      final ValueNotifier<bool> mountOverlay = ValueNotifier<bool>(true);
      addTearDown(mountOverlay.dispose);
      late BuildContext hostContext;
      int confirmCalls = 0;

      await tester.pumpWidget(
        _shell(
          container: container,
          child: Builder(
            builder: (BuildContext ctx) {
              hostContext = ctx;
              return Scaffold(
                body: Stack(
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: () => unawaited(
                        showFavoriteGifFirstTimePrompt(
                          context: hostContext,
                          onConfirm: () async {
                            confirmCalls += 1;
                          },
                        ),
                      ),
                      child: const Text('GifPrompt'),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: mountOverlay,
                      builder: (_, bool mounted, _) {
                        if (!mounted) {
                          return const SizedBox.shrink();
                        }
                        return const ChannelDetailsDrawerOverlay(
                          channelId: 'ch-drawer-1',
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();

      // 1. Open then close drawer, then unmount overlay mid-close animation.
      unawaited(
        container
            .read(channelDetailsDrawerProvider.notifier)
            .open(
              channel: const Channel(
                id: 'ch-drawer-1',
                guildId: 'g-1',
                name: 'general',
              ),
              dm: null,
            ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      container.read(channelDetailsDrawerProvider.notifier).close();
      await tester.pump();

      mountOverlay.value = false;
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(container.read(channelDetailsDrawerRevealProvider), 0);

      // 2. Favorite GIF prompt unmounts before save resolves.
      await tester.tap(find.text('GifPrompt'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(testL10n.gifFavoriteFirstTimeUseUrlOnly));
      await tester.pump();

      // Dismiss the sheet immediately so ConsumerWidget unmounts before await finishes.
      Navigator.of(rootNavigatorKey.currentContext!).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      saveCompleter.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(container.read(favoriteGifsProvider).seenFirstTimePrompt, isTrue);
      expect(confirmCalls, 1);
    },
  );

  testWidgets(
    'ChannelHeaderSearchField _submitSearch and UploadDropOverlay onDragDone handle unmount cleanly',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final Completer<void> searchCompleter = Completer<void>();
      final Completer<FileUploadValidationResult> uploadCompleter =
          Completer<FileUploadValidationResult>();
      final db.FluxerDatabase mockDb = openTestDatabase();
      final ChannelSearchHistoryRepository historyRepo =
          ChannelSearchHistoryRepository(await SharedPreferences.getInstance());

      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: mockDb,
          extra: <Override>[
            channelSearchProvider(
              'ch-search-1',
              null,
            ).overrideWith(() => _SuspendingChannelSearch(searchCompleter)),
            channelSearchHistoryRepositoryProvider.overrideWith(
              (Ref ref) => historyRepo,
            ),
            cloudUploadControllerProvider(
              kTestAccountUserId,
              'ch-search-1',
            ).overrideWith(
              () => _SuspendingCloudUploadController(uploadCompleter),
            ),
          ],
        ),
      );
      addTearDown(container.dispose);

      // Ensure FutureProvider is resolved before submit.
      await container.read(channelSearchHistoryRepositoryProvider.future);

      final ValueNotifier<bool> mountSearch = ValueNotifier<bool>(true);
      addTearDown(mountSearch.dispose);
      final ValueNotifier<bool> mountDrop = ValueNotifier<bool>(true);
      addTearDown(mountDrop.dispose);

      await tester.pumpWidget(
        _shell(
          container: container,
          child: Scaffold(
            body: Column(
              children: <Widget>[
                ValueListenableBuilder<bool>(
                  valueListenable: mountSearch,
                  builder: (_, bool mounted, _) {
                    if (!mounted) {
                      return const SizedBox.shrink();
                    }
                    return const ChannelHeaderSearchField(
                      channelId: 'ch-search-1',
                      guildId: null,
                    );
                  },
                ),
                Expanded(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: mountDrop,
                    builder: (_, bool mounted, _) {
                      if (!mounted) {
                        return const SizedBox.shrink();
                      }
                      return const UploadDropOverlay(
                        channelId: 'ch-search-1',
                        child: SizedBox.expand(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      // 1. ChannelHeaderSearchField submit -> unmount before search() completes.
      await tester.enterText(find.byType(EditableText).first, 'hello');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      mountSearch.value = false;
      await tester.pump();

      searchCompleter.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(
        historyRepo.readForContext(
          channelSearchContextKey(channelId: 'ch-search-1'),
        ),
        hasLength(1),
      );

      // 2. UploadDropOverlay drop -> unmount before addFiles() resolves.
      final DropTarget dropTarget = tester.widget<DropTarget>(
        find.byType(DropTarget),
      );
      dropTarget.onDragDone!(
        DropDoneDetails(
          files: <DropItem>[
            DropItemFile.fromData(
              Uint8List.fromList(<int>[1, 2, 3]),
              name: 'a.txt',
            ),
          ],
          localPosition: Offset.zero,
          globalPosition: Offset.zero,
        ),
      );
      await tester.pump();

      mountDrop.value = false;
      await tester.pump();

      uploadCompleter.complete(const FileUploadValidationResult.success());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ComposerAutocompleteField _syncEmoji aborts cleanly if unmounted before emoji load resolves',
    (WidgetTester tester) async {
      final db.FluxerDatabase mockDb = openTestDatabase();
      final Completer<List<GuildEmojiEntry>> emojiCompleter =
          Completer<List<GuildEmojiEntry>>();
      final _QuietGatewayConnection gateway = _QuietGatewayConnection();
      addTearDown(gateway.dispose);
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.fluxer.invalid'));
      await tester.runAsync(EmojiRegistry.ensureLoaded);

      final ProviderContainer container =
          await pumpComposerChannelTextareaHarness(
            tester,
            database: mockDb,
            guildChannelPermissions: ChannelMessagePermissions.all,
            extraOverrides: <Override>[
              fluxerDioProvider.overrideWithValue(dio),
              fluxerClientProvider.overrideWithValue(
                FluxerClient(dio, baseUrl: 'https://test.fluxer.invalid'),
              ),
              gatewayConnectionProvider.overrideWithValue(gateway),
              guildCommandsProvider.overrideWith(_InertGuildCommands.new),
              allGuildEmojisForPickerProvider.overrideWith(
                (Ref ref) => Stream<List<GuildEmojiEntry>>.fromFuture(
                  emojiCompleter.future,
                ),
              ),
            ],
          );
      final ProviderSubscription<AsyncValue<List<GuildEmojiEntry>>> emojiSub =
          container.listen(allGuildEmojisForPickerProvider, (_, _) {});
      addTearDown(emojiSub.close);

      await tester.tap(channelComposerField());
      await tester.pump();
      await tester.enterText(channelComposerField(), ':sm');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Dispose composer while _syncEmoji awaits allGuildEmojisForPickerProvider.future.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      emojiCompleter.complete(const <GuildEmojiEntry>[]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
    },
  );
}
