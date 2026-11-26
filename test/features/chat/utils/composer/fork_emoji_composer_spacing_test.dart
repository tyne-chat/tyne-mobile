// Fork: "Add a space after emoji" (tyne-chat/tyne#650). Tests emoji insertion
// from both the picker (`ComposerMentionController.insertEmoji`) and the `:`
// autocomplete (`ComposerAutocompleteField`) with the setting on and off.
// Root ProviderScope built by a helper; the lint only exempts a
// ProviderScope written inline in pumpWidget.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/route_state_providers.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/composer/composer_autocomplete_field.dart';
import 'package:fluxer_app/features/chat/providers/channel/channel_message_permissions_provider.dart';
import 'package:fluxer_app/features/chat/providers/pickers/emoji_picker_provider.dart';
import 'package:fluxer_app/features/chat/services/composer_mention_controller.dart';
import 'package:fluxer_app/features/dm/domain/dm_conversation.dart';
import 'package:fluxer_app/features/dm/providers/dm_view_model.dart';
import 'package:fluxer_app/features/friends/domain/friend.dart';
import 'package:fluxer_app/features/guilds/domain/guild.dart';
import 'package:fluxer_app/features/guilds/providers/guild_list_view_model.dart';
import 'package:fluxer_app/features/settings/providers/preferences/space_after_emoji_preference.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/utils/emoji/emoji_registry.dart';

import '../../../../helpers/open_test_database.dart';
import '../../../../helpers/test_l10n.dart';

const String _kChannelId = 'general';
const String _kGuildId = 'guild_1';

class _FakeGuilds extends GuildListViewModel {
  _FakeGuilds(this._guilds);

  final List<Guild> _guilds;

  @override
  GuildListViewState build() => GuildListViewState(guilds: _guilds);
}

class _FixedSpaceAfterEmoji extends SpaceAfterEmojiPreference {
  _FixedSpaceAfterEmoji(this._initial);

  final bool _initial;

  @override
  bool build() => _initial;
}

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

Future<ComposerMentionController> _pumpMentionController(
  WidgetTester tester, {
  required bool spaceAfterEmoji,
}) async {
  ComposerMentionController? controller;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        spaceAfterEmojiPreferenceProvider.overrideWith(
          () => _FixedSpaceAfterEmoji(spaceAfterEmoji),
        ),
      ],
      child: _app(
        Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? _) {
            controller ??= ComposerMentionController(ref: ref);
            return TextField(controller: controller);
          },
        ),
      ),
    ),
  );
  await tester.pump();
  addTearDown(() => controller?.dispose());
  return controller!;
}

Future<({TextEditingController controller, FocusNode focusNode})>
_pumpAutocomplete(
  WidgetTester tester, {
  required bool spaceAfterEmoji,
  required List<GuildEmojiEntry> customEmojis,
  bool plainController = false,
  int? maxActualLength,
}) async {
  final db = openTestDatabase();
  final emojis = StreamController<List<GuildEmojiEntry>>.broadcast();
  addTearDown(emojis.close);
  TextEditingController? controller;
  final focusNode = FocusNode();
  addTearDown(focusNode.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        fluxerDatabaseProvider.overrideWithValue(db),
        activeGuildIdProvider.overrideWith((ref) => _kGuildId),
        guildListViewModelProvider.overrideWith(
          () => _FakeGuilds(const <Guild>[
            Guild(id: _kGuildId, name: 'Guild One', ownerId: 'owner'),
          ]),
        ),
        allGuildEmojisForPickerProvider.overrideWith((ref) => emojis.stream),
        channelMessagePermissionsProvider(_kChannelId).overrideWith(
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
        spaceAfterEmojiPreferenceProvider.overrideWith(
          () => _FixedSpaceAfterEmoji(spaceAfterEmoji),
        ),
      ],
      child: _app(
        Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? _) {
            controller ??= plainController
                ? TextEditingController()
                : ComposerMentionController(ref: ref);
            return ComposerAutocompleteField(
              controller: controller!,
              focusNode: focusNode,
              channelId: _kChannelId,
              maxActualLength: maxActualLength,
              child: TextField(controller: controller, focusNode: focusNode),
            );
          },
        ),
      ),
    ),
  );
  addTearDown(() => controller?.dispose());
  emojis.add(customEmojis);
  await tester.pump();
  return (controller: controller!, focusNode: focusNode);
}

void main() {
  setUpAll(() async {
    await EmojiRegistry.preload();
  });

  group('picker insertions (ComposerMentionController.insertEmoji)', () {
    testWidgets('adds upstream spacing while spaceAfterEmoji is on', (
      WidgetTester tester,
    ) async {
      final controller = await _pumpMentionController(
        tester,
        spaceAfterEmoji: true,
      );

      controller
        ..insertEmoji('left', '<:left:1>')
        ..insertEmoji('right', '<:right:2>');

      expect(controller.toWireText(), '<:left:1> <:right:2> ');
    });

    testWidgets(
      'inserts adjacent emojis without leading or trailing space when off',
      (WidgetTester tester) async {
        final controller = await _pumpMentionController(
          tester,
          spaceAfterEmoji: false,
        );

        controller
          ..insertEmoji('left', '<:left:1>')
          ..insertEmoji('right', '<:right:2>');

        expect(controller.toWireText(), '<:left:1><:right:2>');
      },
    );

    testWidgets('inserts between existing emojis without spaces when off', (
      WidgetTester tester,
    ) async {
      final controller = await _pumpMentionController(
        tester,
        spaceAfterEmoji: false,
      );

      controller
        ..insertEmoji('a', '<:a:1>')
        ..insertEmoji('c', '<:c:3>');
      expect(controller.text.length, 2);

      controller
        ..selection = const TextSelection.collapsed(offset: 1)
        ..insertEmoji('b', '<:b:2>');

      expect(controller.toWireText(), '<:a:1><:b:2><:c:3>');
      expect(controller.selection, const TextSelection.collapsed(offset: 2));
    });

    testWidgets(
      'preserves existing space and replaces selected text when off',
      (WidgetTester tester) async {
        final controller = await _pumpMentionController(
          tester,
          spaceAfterEmoji: false,
        );

        controller
          ..value = const TextEditingValue(
            text: 'hi ',
            selection: TextSelection.collapsed(offset: 3),
          )
          ..insertEmoji('fire', '🔥');
        expect(controller.toWireText(), 'hi :fire:');

        controller
          ..value = const TextEditingValue(
            text: 'ab',
            selection: TextSelection(baseOffset: 0, extentOffset: 2),
          )
          ..insertEmoji('left', '<:left:1>');
        expect(controller.toWireText(), '<:left:1>');
      },
    );

    testWidgets('respects maxActualLength when off', (
      WidgetTester tester,
    ) async {
      final controller = await _pumpMentionController(
        tester,
        spaceAfterEmoji: false,
      );

      controller
        ..insertEmoji('left', '<:left:1>', maxActualLength: 10)
        ..insertEmoji('right', '<:right:2>', maxActualLength: 10);

      expect(controller.toWireText(), '<:left:1>');
    });

    testWidgets('leaves mention spacing untouched when off', (
      WidgetTester tester,
    ) async {
      final controller = await _pumpMentionController(
        tester,
        spaceAfterEmoji: false,
      );

      controller.insertUserMentionPlaceholder(
        matchStart: 0,
        matchEnd: 0,
        userId: '123',
        displayName: 'Fox',
      );

      expect(controller.toWireText(), '<@123> ');
    });
  });

  group('colon autocomplete (ComposerAutocompleteField)', () {
    final List<GuildEmojiEntry> halves = <GuildEmojiEntry>[
      GuildEmojiEntry(
        id: '1',
        name: 'catleft',
        animated: false,
        guildId: _kGuildId,
      ),
      GuildEmojiEntry(
        id: '2',
        name: 'catright',
        animated: false,
        guildId: _kGuildId,
      ),
    ];

    Future<void> typeAndWait(
      WidgetTester tester,
      TextEditingController controller,
      String text, {
      int? offset,
    }) async {
      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: offset ?? text.length),
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
    }

    testWidgets('adds trailing space while spaceAfterEmoji is on', (
      WidgetTester tester,
    ) async {
      final harness = await _pumpAutocomplete(
        tester,
        spaceAfterEmoji: true,
        customEmojis: halves,
      );
      final controller = harness.controller as ComposerMentionController;

      await typeAndWait(tester, controller, ':catl');
      expect(find.text(':catleft:'), findsOneWidget);
      await tester.tap(find.text(':catleft:'));
      await tester.pump();

      expect(controller.toWireText(), '<:catleft:1> ');
    });

    testWidgets(
      'inserts touching custom emojis back-to-back via colon search when off',
      (WidgetTester tester) async {
        final harness = await _pumpAutocomplete(
          tester,
          spaceAfterEmoji: false,
          customEmojis: halves,
        );
        final controller = harness.controller as ComposerMentionController;

        await typeAndWait(tester, controller, ':catl');
        expect(find.text(':catleft:'), findsOneWidget);
        await tester.tap(find.text(':catleft:'));
        await tester.pump();

        expect(controller.toWireText(), '<:catleft:1>');
        expect(controller.selection, const TextSelection.collapsed(offset: 1));

        // Typing `:` straight after the first emoji token triggers search again
        // and inserts the second half touching the first.
        await typeAndWait(tester, controller, '${controller.text}:catr');
        expect(find.text(':catright:'), findsOneWidget);
        await tester.tap(find.text(':catright:'));
        await tester.pump();

        expect(controller.toWireText(), '<:catleft:1><:catright:2>');
      },
    );

    testWidgets(
      'inserts unicode emoji before an existing emoji with no trailing space when off',
      (WidgetTester tester) async {
        final harness = await _pumpAutocomplete(
          tester,
          spaceAfterEmoji: false,
          customEmojis: halves,
        );
        final controller = (harness.controller as ComposerMentionController)
          ..insertEmoji('catright', '<:catright:2>');
        final String rightSentinel = controller.text;
        await typeAndWait(tester, controller, ':fire$rightSentinel', offset: 5);
        expect(find.text(':fire:'), findsOneWidget);
        await tester.tap(find.text(':fire:'));
        await tester.pump();

        expect(controller.toWireText(), ':fire:<:catright:2>');
      },
    );

    testWidgets(
      'omits trailing space on plain TextEditingController when off',
      (WidgetTester tester) async {
        final harness = await _pumpAutocomplete(
          tester,
          spaceAfterEmoji: false,
          customEmojis: halves,
          plainController: true,
        );
        final controller = harness.controller;

        await typeAndWait(tester, controller, ':catl');
        expect(find.text(':catleft:'), findsOneWidget);
        await tester.tap(find.text(':catleft:'));
        await tester.pump();

        expect(controller.text, '<:catleft:1>');
        expect(
          controller.selection,
          const TextSelection.collapsed(offset: '<:catleft:1>'.length),
        );
      },
    );
  });
}
