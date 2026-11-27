// Fork: tyne-chat/tyne#946 — regression tests for self-unmounting nagbars
// (GiftInventoryNagbar, PremiumOnboardingNagbar, GuildMembershipCtaNagbar)
// and nagbar_user_updates.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/providers/instance/well_known_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/guilds/data/guild_repository.dart';
import 'package:fluxer_app/features/guilds/providers/guild_providers.dart';
import 'package:fluxer_app/features/shell/presentation/widgets/nagbars/gift_inventory_nagbar.dart';
import 'package:fluxer_app/features/shell/presentation/widgets/nagbars/guild_membership_cta_nagbar.dart';
import 'package:fluxer_app/features/shell/presentation/widgets/nagbars/premium_onboarding_nagbar.dart';
import 'package:fluxer_app/features/shell/providers/nagbar/guild_membership_cta_visibility_provider.dart';
import 'package:fluxer_app/features/shell/providers/nagbar/nagbar_providers.dart';
import 'package:fluxer_app/features/shell/providers/user/current_user_private_provider.dart';
import 'package:fluxer_app/features/ui/nagbar/fluxer_nagbar_button.dart';
import 'package:fluxer_app/features/ui/nagbar/fluxer_nagbar_content.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_dart/export.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../helpers/core_test_provider_overrides.dart';
import '../../../../../helpers/fake_well_known.dart';
import '../../../../../helpers/open_test_database.dart';
import '../../../../../helpers/test_account_user_id.dart';
import '../../../../../helpers/test_l10n.dart';

final UserPrivateResponse _privateProfile = UserPrivateResponse.fromJson(
  <String, Object?>{'id': kTestAccountUserId, 'username': 'neo'},
);

final InviteResponseSchema _hqInvite = InviteResponseSchema.fromJson(
  <String, Object?>{
    'code': kFluxerHqInviteCode,
    'temporary': false,
    'type': 0,
    'guild': <String, Object?>{'id': 'hq-g1', 'name': 'Fluxer HQ'},
    'channel': <String, Object?>{'id': 'hq-c1', 'type': 0, 'name': 'general'},
    'member_count': 10,
    'presence_count': 4,
  },
);

class _SlowNagbarUsersApi implements UsersApi {
  final Completer<UserUpdateResponse> updateCompleter =
      Completer<UserUpdateResponse>();
  final List<UserUpdateWithVerificationRequest?> updateBodies =
      <UserUpdateWithVerificationRequest?>[];
  int getCurrentUserCalls = 0;

  @override
  Future<UserUpdateResponse> updateCurrentUser({
    UserUpdateWithVerificationRequest? body,
  }) {
    updateBodies.add(body);
    return updateCompleter.future;
  }

  @override
  Future<UserPrivateResponse> getCurrentUser() async {
    getCurrentUserCalls++;
    return _privateProfile;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SlowNagbarInvitesApi implements InvitesApi {
  final Completer<InviteResponseSchema> acceptCompleter =
      Completer<InviteResponseSchema>();

  @override
  Future<InviteResponseSchema> getInvite({required String inviteCode}) async =>
      _hqInvite;

  @override
  Future<InviteResponseSchema> acceptInvite({required String inviteCode}) =>
      acceptCompleter.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NagbarTestClient extends FluxerClient {
  _NagbarTestClient({this.usersOverride, this.invitesOverride}) : super(Dio());

  final UsersApi? usersOverride;
  final InvitesApi? invitesOverride;

  @override
  UsersApi get users => usersOverride ?? super.users;

  @override
  InvitesApi get invites => invitesOverride ?? super.invites;
}

Widget _wrapNagbar(ProviderContainer container, Widget child) {
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
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets(
    'GiftInventoryNagbar dismissing itself clears server flag and refreshes private user without StateError after unmounting',
    (WidgetTester tester) async {
      final db.FluxerDatabase database = openTestDatabase();
      final _SlowNagbarUsersApi usersApi = _SlowNagbarUsersApi();
      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: database,
          extra: [
            fluxerClientProvider.overrideWithValue(
              _NagbarTestClient(usersOverride: usersApi),
            ),
          ],
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrapNagbar(
          container,
          Consumer(
            builder: (_, WidgetRef ref, _) =>
                ref.watch(nagbarDismissalsProvider).giftInventoryDismissed
                ? const SizedBox.shrink()
                : const GiftInventoryNagbar(),
          ),
        ),
      );

      final FluxerNagbarContent content = tester.widget<FluxerNagbarContent>(
        find.byType(FluxerNagbarContent),
      );
      content.onDismiss!.call();
      await tester.pump();

      // Dismissing synchronously updates nagbarDismissalsProvider and unmounts
      // GiftInventoryNagbar before updateCurrentUser completes!
      expect(find.byType(GiftInventoryNagbar), findsNothing);
      expect(usersApi.updateBodies.single?.hasUnreadGiftInventory, isFalse);

      usersApi.updateCompleter.complete(
        UserUpdateResponse.fromJson(<String, Object?>{
          'id': kTestAccountUserId,
          'username': 'neo',
        }),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(tester.takeException(), isNull);
      expect(usersApi.getCurrentUserCalls, 1);
      expect(
        container.read(currentUserPrivateReadProvider(kTestAccountUserId))?.id,
        kTestAccountUserId,
      );
    },
  );

  testWidgets(
    'PremiumOnboardingNagbar dismissing itself persists server flag and refreshes private user without StateError after unmounting',
    (WidgetTester tester) async {
      final db.FluxerDatabase database = openTestDatabase();
      final _SlowNagbarUsersApi usersApi = _SlowNagbarUsersApi();
      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: database,
          extra: [
            fluxerClientProvider.overrideWithValue(
              _NagbarTestClient(usersOverride: usersApi),
            ),
          ],
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrapNagbar(
          container,
          Consumer(
            builder: (_, WidgetRef ref, _) =>
                ref.watch(nagbarDismissalsProvider).premiumOnboardingDismissed
                ? const SizedBox.shrink()
                : const PremiumOnboardingNagbar(),
          ),
        ),
      );

      final FluxerNagbarContent content = tester.widget<FluxerNagbarContent>(
        find.byType(FluxerNagbarContent),
      );
      content.onDismiss!.call();
      await tester.pump();

      expect(find.byType(PremiumOnboardingNagbar), findsNothing);
      expect(
        usersApi.updateBodies.single?.hasDismissedPremiumOnboarding,
        isTrue,
      );

      usersApi.updateCompleter.complete(
        UserUpdateResponse.fromJson(<String, Object?>{
          'id': kTestAccountUserId,
          'username': 'neo',
        }),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(tester.takeException(), isNull);
      expect(usersApi.getCurrentUserCalls, 1);
      expect(
        container.read(currentUserPrivateReadProvider(kTestAccountUserId))?.id,
        kTestAccountUserId,
      );
    },
  );

  testWidgets(
    'GuildMembershipCtaNagbar records dismissal without StateError when unmounted while joinCommunityViaInvite is in flight',
    (WidgetTester tester) async {
      final db.FluxerDatabase database = openTestDatabase();
      final _SlowNagbarInvitesApi invitesApi = _SlowNagbarInvitesApi();
      final _NagbarTestClient client = _NagbarTestClient(
        invitesOverride: invitesApi,
      );
      final GoRouter router = GoRouter(
        initialLocation: '/',
        routes: <RouteBase>[
          GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink()),
          GoRoute(
            path: '/channels/:guildId',
            builder: (_, _) => const SizedBox.shrink(),
            routes: <RouteBase>[
              GoRoute(
                path: ':channelId',
                builder: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      final ValueNotifier<bool> mountNagbar = ValueNotifier<bool>(true);
      addTearDown(mountNagbar.dispose);

      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: database,
          extra: [
            wellKnownProvider.overrideWith(FakeWellKnown.new),
            fluxerClientProvider.overrideWithValue(client),
            guildRepositoryProvider.overrideWithValue(
              GuildRepository(client, database),
            ),
            fluxerRouterProvider.overrideWithValue(router),
          ],
        ),
      );
      addTearDown(container.dispose);

      final colorTheme = buildDarkColorTheme();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            locale: kTestLocale,
            localizationsDelegates: fluxerLocalizationsDelegates,
            supportedLocales: FluxerLocalizations.supportedLocales,
            theme: buildFluxerTheme(
              colorTheme: colorTheme,
              textTheme: FluxerTextTheme.fromColors(colorTheme),
              layoutTheme: FluxerLayoutTheme.scaled(),
            ),
            builder: (_, Widget? child) => Scaffold(
              body: Column(
                children: <Widget>[
                  Expanded(child: child ?? const SizedBox.shrink()),
                  ValueListenableBuilder<bool>(
                    valueListenable: mountNagbar,
                    builder: (_, bool mounted, _) => mounted
                        ? const GuildMembershipCtaNagbar()
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final FluxerNagbarButton joinBtn = tester.widget<FluxerNagbarButton>(
        find.byType(FluxerNagbarButton),
      );
      joinBtn.onPressed?.call();
      await tester.pump();
      await tester.pump();

      mountNagbar.value = false;
      await tester.pump();

      invitesApi.acceptCompleter.complete(_hqInvite);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(tester.takeException(), isNull);
      expect(
        container.read(nagbarDismissalsProvider).guildMembershipCtaDismissed,
        isTrue,
      );
    },
  );
}
