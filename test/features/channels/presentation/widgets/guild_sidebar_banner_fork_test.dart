import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/channels/presentation/widgets/guild_sidebar/guild_sidebar.dart'
    show GuildSidebarHeaderBody;
import 'package:fluxer_app/features/guilds/domain/guild.dart';
import 'package:fluxer_app/material_ui.dart';

import '../../../../helpers/pump_fluxer_app.dart';

// tyne-chat/tyne#622: the sidebar header draws its banner with an Image, which
// stops animating while TickerMode is off (the sidebar drawer's hidden layer).
// Upstream's DecorationImage kept an animated banner running off screen.
void main() {
  testWidgets('the banner is an Image, not a DecorationImage', (
    WidgetTester tester,
  ) async {
    const Guild guild = Guild(
      id: '1523148232476065792',
      name: 'Test Guild',
      banner: 'a_0a139172',
    );
    await tester.pumpWidget(
      pumpFluxerApp(
        child: const SizedBox(
          width: 300,
          height: 200,
          child: GuildSidebarHeaderBody(
            guild: guild,
            outageUnavailable: false,
            onTap: null,
            collapseRatio: 0,
            height: 170,
          ),
        ),
      ),
    );

    final Iterable<Image> banners = tester.widgetList<Image>(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is Image && widget.image is CachedNetworkImageProvider,
      ),
    );
    expect(banners, hasLength(1));
    final Image banner = banners.single;
    expect((banner.image as CachedNetworkImageProvider).url, guild.bannerUrl);
    expect(banner.fit, BoxFit.cover);
    expect(banner.alignment, Alignment.topCenter);
    expect(banner.excludeFromSemantics, isTrue);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).image != null,
      ),
      findsNothing,
    );
  });
}
