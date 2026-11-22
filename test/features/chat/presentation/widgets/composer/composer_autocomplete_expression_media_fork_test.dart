// Fork: stickers and saved media in the `:` expression autocomplete, under the
// settings "Show stickers" and "Show saved media in expression autocomplete"
// (tyne-chat/tyne#777). They are listed after the emojis only while the
// composer holds nothing but the `:query` (or a persona tag the send uses up),
// and a pick goes out through the composer's existing sticker and saved media
// handlers. Kept out of upstream's composer tests.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/route_state_providers.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/chat/domain/favorite_meme.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/composer/channel_textarea.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/composer/composer_autocomplete_field.dart';
import 'package:fluxer_app/features/chat/providers/channel/channel_message_permissions_provider.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/chat/providers/pickers/emoji_picker_provider.dart';
import 'package:fluxer_app/features/chat/providers/pickers/favorite_media_provider.dart';
import 'package:fluxer_app/features/chat/providers/pickers/sticker_picker_provider.dart';
import 'package:fluxer_app/features/dm/domain/dm_conversation.dart';
import 'package:fluxer_app/features/dm/providers/dm_view_model.dart';
import 'package:fluxer_app/features/friends/domain/friend.dart';
import 'package:fluxer_app/features/guilds/domain/guild.dart';
import 'package:fluxer_app/features/guilds/providers/guild_list_view_model.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/features/settings/providers/preferences/chat_preferences_provider.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/utils/emoji/emoji_registry.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../helpers/composer_channel_textarea_harness.dart';
import '../../../../../helpers/open_test_database.dart';
import '../../../../../helpers/test_l10n.dart';

const String _channelId = 'general';
const String _guildId = 'guild_1';

const Persona _alpha = Persona(
  id: 'p_alpha',
  name: 'Alpha',
  personaTags: [PersonaTag(prefix: 'a:', suffix: '')],
);

const StickerEntry _waveSticker = StickerEntry(
  id: 's_wave',
  guildId: _guildId,
  name: 'wavey',
  description: '',
  tags: <String>[],
  animated: false,
);

const FavoriteMeme _waveMeme = FavoriteMeme(
  id: 'm_wave',
  userId: 'u1',
  name: 'wave goodbye',
  altText: null,
  tags: <String>[],
  attachmentId: 'a1',
  filename: 'bye.png',
  contentType: 'image/png',
  contentHash: null,
  size: 1,
  width: 1,
  height: 1,
  duration: null,
  isGifv: false,
  url: 'https://media.invalid/bye.png',
  klipySlug: null,
  tenorSlugId: null,
);

class _FakeGuilds extends GuildListViewModel {
  @override
  GuildListViewState build() => const GuildListViewState(
    guilds: <Guild>[Guild(id: _guildId, name: 'Guild One', ownerId: 'o')],
  );
}

class _Prefs extends ChatPreferences {
  _Prefs(this._state);
  final ChatPreferencesState _state;

  @override
  ChatPreferencesState build() => _state;
}

class _OwnPersonas extends MyPersonasNotifier {
  @override
  AsyncValue<List<Persona>> build() => const AsyncValue.data(<Persona>[_alpha]);

  @override
  Future<void> reloadSilently() async {}
}

class _NoSelection extends ActivePersonaNotifier {
  @override
  ActivePersonaState build() => const ActivePersonaState();
}

/// The composer's chat, recording the sticker and saved media sends.
class _RecordingChat extends MutableChatViewModel {
  final List<({String id, Map<String, dynamic>? persona})> stickers = [];
  final List<({String id, Map<String, dynamic>? persona})> memes = [];

  @override
  Future<void> sendStickerMessage(
    StickerEntry sticker, {
    Map<String, dynamic>? personaData,
  }) async {
    stickers.add((id: sticker.id, persona: personaData));
  }

  @override
  Future<void> sendFavoriteMemeMessage(
    FavoriteMeme meme, {
    Map<String, dynamic>? personaData,
  }) async {
    memes.add((id: meme.id, persona: personaData));
  }
}

List<Override> _mediaOverrides({
  bool showStickers = true,
  bool showMemes = true,
}) => <Override>[
  allGuildStickersForPickerProvider.overrideWith(
    (ref) => Stream<List<StickerEntry>>.value(<StickerEntry>[_waveSticker]),
  ),
  frecentStickersProvider.overrideWith(
    (ref) => Future<List<StickerEntry>>.value(const <StickerEntry>[]),
  ),
  favoriteMemesProvider.overrideWith(
    (ref) => Stream<List<FavoriteMeme>>.value(<FavoriteMeme>[_waveMeme]),
  ),
  chatPreferencesProvider.overrideWith(
    () => _Prefs(
      ChatPreferencesState(
        showStickersInExpressionAutocomplete: showStickers,
        showMemesInExpressionAutocomplete: showMemes,
      ),
    ),
  ),
  myPersonasProvider.overrideWith(_OwnPersonas.new),
  activePersonaProvider.overrideWith(_NoSelection.new),
  contextualGuildIdProvider.overrideWithValue(_guildId),
];

Widget _app(Widget child) {
  final colorTheme = buildDarkColorTheme();
  return MaterialApp(
    locale: kTestLocale,
    localizationsDelegates: fluxerLocalizationsDelegates,
    supportedLocales: FluxerLocalizations.supportedLocales,
    theme: buildFluxerTheme(
      colorTheme: colorTheme,
      textTheme: FluxerTextTheme.fromColors(colorTheme),
      layoutTheme: FluxerLayoutTheme.scaled(),
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  setUpAll(() async {
    await EmojiRegistry.preload();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('the `:` list on its own', () {
    late TextEditingController text;
    late List<StickerEntry> pickedStickers;
    late List<FavoriteMeme> pickedMemes;
    late List<String> textAtPick;

    Future<void> pump(
      WidgetTester tester, {
      bool showStickers = true,
      bool showMemes = true,
    }) async {
      final db.FluxerDatabase database = openTestDatabase();
      text = TextEditingController();
      addTearDown(text.dispose);
      final FocusNode focus = FocusNode();
      addTearDown(focus.dispose);
      pickedStickers = <StickerEntry>[];
      pickedMemes = <FavoriteMeme>[];
      textAtPick = <String>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fluxerDatabaseProvider.overrideWithValue(database),
            activeGuildIdProvider.overrideWith((ref) => _guildId),
            guildListViewModelProvider.overrideWith(_FakeGuilds.new),
            allGuildEmojisForPickerProvider.overrideWith(
              (ref) => Stream<List<GuildEmojiEntry>>.value(<GuildEmojiEntry>[
                GuildEmojiEntry(
                  id: 'e1',
                  name: 'wavecat',
                  animated: false,
                  guildId: _guildId,
                ),
              ]),
            ),
            channelMessagePermissionsProvider(_channelId).overrideWith(
              (ref) => Future<ChannelMessagePermissions>.value(
                ChannelMessagePermissions.all,
              ),
            ),
            dmViewModelProvider.overrideWithValue(
              const DmViewState(
                conversations: <DmConversation>[],
                friendsList: <Friend>[],
                activeTab: FriendsTab.online,
                searchQuery: '',
              ),
            ),
            ..._mediaOverrides(
              showStickers: showStickers,
              showMemes: showMemes,
            ),
          ],
          child: _app(
            ComposerAutocompleteField(
              controller: text,
              focusNode: focus,
              channelId: _channelId,
              onSelectSticker: (StickerEntry s) {
                textAtPick.add(text.text);
                pickedStickers.add(s);
              },
              onSelectMeme: (FavoriteMeme m) {
                textAtPick.add(text.text);
                pickedMemes.add(m);
              },
              child: TextField(controller: text, focusNode: focus),
            ),
          ),
        ),
      );
    }

    Future<void> type(WidgetTester tester, String value) async {
      text.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
    }

    testWidgets('with both settings on, stickers and saved media follow '
        'the emojis', (tester) async {
      await pump(tester);
      await type(tester, ':wave');

      expect(find.text(':wavecat:'), findsWidgets);
      expect(find.text('wavey'), findsOneWidget);
      expect(find.text('wave goodbye'), findsOneWidget);
      final double emojiY = tester.getTopLeft(find.text(':wavecat:').first).dy;
      final double stickerY = tester.getTopLeft(find.text('wavey')).dy;
      final double memeY = tester.getTopLeft(find.text('wave goodbye')).dy;
      expect(emojiY, lessThan(stickerY));
      expect(stickerY, lessThan(memeY));
    });

    testWidgets('each setting turns its own kind off; emojis stay', (
      tester,
    ) async {
      await pump(tester, showStickers: false);
      await type(tester, ':wave');
      expect(find.text(':wavecat:'), findsWidgets);
      expect(find.text('wavey'), findsNothing);
      expect(find.text('wave goodbye'), findsOneWidget);
    });

    testWidgets('saved media off', (tester) async {
      await pump(tester, showMemes: false);
      await type(tester, ':wave');
      expect(find.text(':wavecat:'), findsWidgets);
      expect(find.text('wavey'), findsOneWidget);
      expect(find.text('wave goodbye'), findsNothing);
    });

    testWidgets('with other text in the composer, only emojis are offered', (
      tester,
    ) async {
      await pump(tester);
      await type(tester, 'hello :wave');
      expect(find.text(':wavecat:'), findsWidgets);
      expect(find.text('wavey'), findsNothing);
      expect(find.text('wave goodbye'), findsNothing);
    });

    testWidgets('a persona tag alone still offers them', (tester) async {
      await pump(tester);
      await type(tester, 'a: :wave');
      expect(find.text('wavey'), findsOneWidget);
      expect(find.text('wave goodbye'), findsOneWidget);
    });

    testWidgets('picking a sticker hands it over with the query taken out', (
      tester,
    ) async {
      await pump(tester);
      await type(tester, 'a: :wave');
      await tester.tap(find.text('wavey'));
      await tester.pump();
      expect(pickedStickers.map((StickerEntry s) => s.id), <String>['s_wave']);
      expect(textAtPick, <String>['a: ']);
    });

    testWidgets('picking saved media hands it over with the query taken out', (
      tester,
    ) async {
      await pump(tester);
      await type(tester, ':wave');
      await tester.tap(find.text('wave goodbye'));
      await tester.pump();
      expect(pickedMemes.map((FavoriteMeme m) => m.id), <String>['m_wave']);
      expect(textAtPick, <String>['']);
    });

    testWidgets('a pick after other text was typed sends nothing', (
      tester,
    ) async {
      await pump(tester);
      await type(tester, ':wave');
      expect(find.text('wavey'), findsOneWidget);
      // Text added before the list catches up.
      text.value = const TextEditingValue(
        text: 'hi :wave',
        selection: TextSelection.collapsed(offset: 8),
      );
      await tester.tap(find.text('wavey'), warnIfMissed: false);
      await tester.pump();
      expect(pickedStickers, isEmpty);
      expect(text.text, 'hi :wave');
    });
  });

  group('in the channel composer', () {
    late _RecordingChat chat;

    Future<ProviderContainer> pumpComposer(WidgetTester tester) async {
      chat = _RecordingChat();
      final ProviderContainer container =
          await pumpComposerChannelTextareaHarness(
            tester,
            extraOverrides: _mediaOverrides(),
            // The harness already overrides these two; here the chat records
            // the sends and the stickers' community is known.
            home: ProviderScope(
              overrides: [
                chatViewModelProvider.overrideWith(() => chat),
                guildListViewModelProvider.overrideWith(_FakeGuilds.new),
              ],
              child: const Scaffold(body: ChannelTextarea()),
            ),
          );
      return container;
    }

    Future<void> type(WidgetTester tester, String value) async {
      await tester.enterText(channelComposerField(), value);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 150));
    }

    testWidgets('a sticker picked from `:` goes out through the sticker send '
        'and empties the composer', (tester) async {
      await pumpComposer(tester);
      await type(tester, ':wave');
      expect(find.text('wavey'), findsOneWidget);

      await tester.tap(find.text('wavey'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(chat.stickers.map((s) => s.id), <String>['s_wave']);
      expect(chat.stickers.single.persona, isNull);
      expect(chat.sentTexts, isEmpty);
      final EditableText field = tester.widget<EditableText>(
        find.byType(EditableText).first,
      );
      expect(field.controller.text, isEmpty);
      expect(chat.state.messageText, isEmpty);
    });

    testWidgets('a persona tag before the query sends it as that persona', (
      tester,
    ) async {
      await pumpComposer(tester);
      await type(tester, 'a: :wave');
      await tester.tap(find.text('wave goodbye'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(chat.memes.map((m) => m.id), <String>['m_wave']);
      expect(chat.memes.single.persona?['id'], _alpha.id);
    });
  });
}
