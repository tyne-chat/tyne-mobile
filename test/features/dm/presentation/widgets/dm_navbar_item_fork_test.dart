// Fork: tests the fork adds, kept out of upstream's dm_navbar_item_test.dart so that file stays as
// upstream has it.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' show DmChannel;
import 'package:fluxer_app/features/dm/presentation/widgets/dm_navbar_item.dart';
import 'package:fluxer_app/features/dm/providers/dm_mute_provider.dart';
import 'package:fluxer_app/features/dm/providers/unread_dm_provider.dart';
import 'package:fluxer_app/features/guilds/presentation/widgets/guild_navbar.dart'
    show GuildNavbarPill;
import 'package:fluxer_app/features/settings/providers/preferences/appearance_preferences_provider.dart';
import 'package:fluxer_app/features/ui/badge/fluxer_badge.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/utils/navigation_item_semantics.dart';

import '../../../../helpers/open_test_database.dart';
import 'dm_navbar_item_test.dart' hide main;

const String _channelId = '1000000000000000001';
const String _recipientId = '1000000000000000002';
const String _displayName = 'Alpha';

void main() {
  setUp(() {
    forkUpstreamDatabase = openTestDatabase();
  });

  // tyne-chat/tyne#284: muting a DM changes only its row in the DM list. Its rail item looks the
  // same, so a count on the back button always has a visible source.
  for (final bool isMuted in const [false, true]) {
    for (final bool showFaded in const [false, true]) {
      final String state =
          '${isMuted ? 'muted' : 'unmuted'}, faded setting '
          '${showFaded ? 'on' : 'off'}';

      group('DmNavbarItem ($state)', () {
        testWidgets('shows the mention count at full strength', (tester) async {
          await _pumpRailItem(
            tester,
            isMuted: isMuted,
            showFaded: showFaded,
            mentionCount: 30,
          );

          _expectSemanticLabel(
            tester,
            mentionCount: 30,
            hasUnread: false,
            isMuted: isMuted,
          );
          expect(find.byType(FluxerBadge), findsOneWidget);
          expect(find.text('30'), findsOneWidget);
          expect(
            tester
                .widgetList<Opacity>(
                  find.ancestor(
                    of: find.byType(FluxerBadge),
                    matching: find.byType(Opacity),
                  ),
                )
                .map((Opacity widget) => widget.opacity),
            everyElement(1.0),
          );
          _expectFullUnreadPill(tester);

          await releaseTestWidgetTree(tester);
        });

        testWidgets('shows a full unread pill without mentions', (
          tester,
        ) async {
          await _pumpRailItem(
            tester,
            isMuted: isMuted,
            showFaded: showFaded,
            mentionCount: 0,
          );

          _expectSemanticLabel(
            tester,
            mentionCount: 0,
            hasUnread: true,
            isMuted: isMuted,
          );
          expect(find.byType(FluxerBadge), findsNothing);
          _expectFullUnreadPill(tester);

          await releaseTestWidgetTree(tester);
        });
      });
    }
  }
}

Future<void> _pumpRailItem(
  WidgetTester tester, {
  required bool isMuted,
  required bool showFaded,
  required int mentionCount,
}) async {
  final router = forkUpstream.buildRouter(
    home: ProviderScope(
      overrides: [
        mutedDmChannelIdsProvider.overrideWith(
          (ref) => Stream.value(isMuted ? {_channelId} : const <String>{}),
        ),
        appearancePreferencesProvider.overrideWith(
          () => _FakeAppearancePreferences(showFaded: showFaded),
        ),
      ],
      child: const DmNavbarItem(
        channelId: _channelId,
        recipientId: _recipientId,
        displayName: _displayName,
        type: 1,
      ),
    ),
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    forkUpstream.buildTestApp(
      router: router,
      unreadState: UnreadDmState(
        channels: [
          DmChannel(
            id: _channelId,
            type: 1,
            recipientId: _recipientId,
            recipientCount: 1,
            recipientIds: '["$_recipientId"]',
            nicksJson: '{}',
            lastMessage: '',
            lastMessageTime: DateTime.fromMillisecondsSinceEpoch(0),
            unreadCount: mentionCount,
          ),
        ],
        unreadChannelIds: const {_channelId},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// Also what shows a muted case really was muted: nothing else on the item differs.
void _expectSemanticLabel(
  WidgetTester tester, {
  required int mentionCount,
  required bool hasUnread,
  required bool isMuted,
}) {
  final String expected = navigationItemSemanticLabel(
    l10n: FluxerLocalizations.of(tester.element(find.byType(DmNavbarItem))),
    name: _displayName,
    hasUnread: hasUnread,
    mentionCount: mentionCount,
    isMuted: isMuted,
  );
  expect(
    find.byWidgetPredicate(
      (Widget widget) =>
          widget is Semantics && widget.properties.label == expected,
    ),
    findsOneWidget,
  );
}

void _expectFullUnreadPill(WidgetTester tester) {
  final GuildNavbarPill pill = tester.widget<GuildNavbarPill>(
    find.byType(GuildNavbarPill),
  );
  expect(pill.height, GuildNavbarPill.unreadHeight);
  expect(pill.faded, isFalse);
}

class _FakeAppearancePreferences extends AppearancePreferences {
  _FakeAppearancePreferences({required this.showFaded});

  final bool showFaded;

  @override
  AppearancePreferencesState build() => AppearancePreferencesState(
    dmMessagePreviewMode: defaultDmMessagePreviewMode(),
    showFadedUnreadOnMutedChannels: showFaded,
  );
}
