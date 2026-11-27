// Fork: tyne-chat/tyne#946 — regression tests for [unmounted-listener] widgets
// whose initState schedules WidgetsBinding.instance.addPostFrameCallback and
// reads `ref` without checking `if (!mounted)` when a two-pass responsive
// layout mounts and unmounts the widget within the same frame.
import 'package:dio/dio.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/channels/presentation/channel_settings/widgets/channel_add_override_popout.dart';
import 'package:fluxer_app/features/chat/data/channel_pins_repository.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/channel/header/channel_header_search_field.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/channel/header/channel_pins_content.dart';
import 'package:fluxer_app/features/chat/providers/channel/channel_details_providers.dart';
import 'package:fluxer_app/features/members/presentation/widgets/guild_members_tab_content.dart';
import 'package:fluxer_app/features/members/providers/member_list_subscription_provider.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_dart/export.dart';

import '../../../../helpers/core_test_provider_overrides.dart';
import '../../../../helpers/open_test_database.dart';
import '../../../../helpers/test_l10n.dart';

/// Simulates a responsive container (like an overflow toolbar or adaptive split
/// pane) that measures its child at wide width (`900px`) and then lays it out
/// at narrow width (`300px`) within the same frame. Any widget inside a child
/// `LayoutBuilder` gated on `constraints.maxWidth >= 600` mounts in pass 1
/// (running `initState`) and unmounts in pass 2 *before* `WidgetsBinding`
/// flushes post-frame callbacks at the end of the frame.
class _TwoPassResponsiveBox extends SingleChildRenderObjectWidget {
  const _TwoPassResponsiveBox({required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTwoPassResponsiveBox();
}

class _RenderTwoPassResponsiveBox extends RenderProxyBox {
  @override
  void performLayout() {
    final RenderBox? c = child;
    if (c == null) {
      size = constraints.smallest;
      return;
    }
    c
      ..layout(
        const BoxConstraints(maxWidth: 900, maxHeight: 600),
        parentUsesSize: true,
      )
      ..layout(
        const BoxConstraints(maxWidth: 300, maxHeight: 600),
        parentUsesSize: true,
      );
    size = constraints.constrain(c.size);
  }
}

class _EmptyPins extends ChannelPins {
  @override
  Future<ChannelPinsState> build(String channelId) async {
    return const ChannelPinsState(
      items: <PinnedMessageEntry>[],
      hasMore: false,
    );
  }
}

Future<void> _pumpSameFrameMountAndUnmount(
  WidgetTester tester,
  Widget Function() buildTarget,
) async {
  final db = openTestDatabase();
  final colorTheme = buildDarkColorTheme();

  await tester.pumpWidget(
    ProviderScope(
      overrides: coreTestProviderOverrides(
        database: db,
        extra: [
          fluxerClientProvider.overrideWithValue(
            FluxerClient(
              Dio(BaseOptions(baseUrl: 'https://api.fluxer.app/v1')),
            ),
          ),
          channelPinsProvider('c1').overrideWith(_EmptyPins.new),
          memberListDetailsSubscriptionProvider(
            'g1',
            'c1',
            true,
          ).overrideWithValue(null),
          memberListDetailsSubscriptionProvider(
            'g1',
            'c1',
            false,
          ).overrideWithValue(null),
        ],
      ),
      child: MaterialApp(
        locale: kTestLocale,
        localizationsDelegates: fluxerLocalizationsDelegates,
        supportedLocales: FluxerLocalizations.supportedLocales,
        theme: buildFluxerTheme(
          colorTheme: colorTheme,
          textTheme: FluxerTextTheme.fromColors(colorTheme),
          layoutTheme: FluxerLayoutTheme.scaled(),
        ),
        home: Scaffold(
          body: _TwoPassResponsiveBox(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                if (constraints.maxWidth >= 600) {
                  return buildTarget();
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'ChannelPinsContent post-frame callback does not throw StateError on same-frame unmount',
    (WidgetTester tester) async {
      await _pumpSameFrameMountAndUnmount(
        tester,
        () =>
            ChannelPinsContent(channelId: 'c1', guildId: 'g1', onClose: () {}),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ChannelHeaderSearchField post-frame callback does not throw StateError on same-frame unmount',
    (WidgetTester tester) async {
      await _pumpSameFrameMountAndUnmount(
        tester,
        () => const ChannelHeaderSearchField(channelId: 'c1', guildId: 'g1'),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ChannelAddOverridePickerContent post-frame callback does not throw StateError on same-frame unmount',
    (WidgetTester tester) async {
      await _pumpSameFrameMountAndUnmount(
        tester,
        () => ChannelAddOverridePickerContent(
          guildId: 'g1',
          rolesById: const {},
          existingOverwriteIds: const <String>{},
          onSelect: (_, _, _) {},
          onClose: () {},
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'GuildMembersTabContent post-frame callback does not throw StateError on same-frame unmount',
    (WidgetTester tester) async {
      final ScrollController scrollController = ScrollController();
      addTearDown(scrollController.dispose);
      await _pumpSameFrameMountAndUnmount(
        tester,
        () => GuildMembersTabContent(
          guildId: 'g1',
          channelId: 'c1',
          scrollController: scrollController,
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
