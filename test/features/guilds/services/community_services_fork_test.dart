// Fork: tyne-chat/tyne#946 — regression tests for createCommunity and
// joinCommunityViaInvite when the caller modal/widget unmounts while the
// backend create/accept request is in flight.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
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
import 'package:fluxer_app/features/channels/data/channel_repository.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/channels/providers/channel_list_view_model.dart';
import 'package:fluxer_app/features/channels/providers/channel_providers.dart';
import 'package:fluxer_app/features/guilds/data/guild_repository.dart';
import 'package:fluxer_app/features/guilds/domain/guild.dart';
import 'package:fluxer_app/features/guilds/providers/guild_providers.dart';
import 'package:fluxer_app/features/guilds/services/create_community_service.dart';
import 'package:fluxer_app/features/guilds/services/join_community_service.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_dart/export.dart' hide ChannelType;
import 'package:go_router/go_router.dart';

import '../../../helpers/core_test_provider_overrides.dart';
import '../../../helpers/fake_well_known.dart';
import '../../../helpers/open_test_database.dart';
import '../../../helpers/test_l10n.dart';

const String _createdGuildId = 'new-g1';
const String _inviteCode = 'guildcode';
const String _invitedGuildId = 'inv-g1';
const String _invitedChannelId = 'inv-c1';

final InviteResponseSchema _guildInvite = InviteResponseSchema.fromJson(
  <String, dynamic>{
    'code': _inviteCode,
    'temporary': false,
    'type': 0,
    'guild': <String, dynamic>{'id': _invitedGuildId, 'name': 'Invited Server'},
    'channel': <String, dynamic>{
      'id': _invitedChannelId,
      'type': 0,
      'name': 'general',
    },
    'member_count': 5,
    'presence_count': 3,
  },
);

class _SlowCreateGuildRepository extends GuildRepository {
  _SlowCreateGuildRepository(this._database)
    : super(FluxerClient(Dio()), _database);

  final db.FluxerDatabase _database;
  final Completer<GuildResponse> createCompleter = Completer<GuildResponse>();

  @override
  Future<GuildResponse> createGuild({
    required String name,
    String? iconDataUri,
    TemplateSerializedGuild? template,
  }) async {
    final GuildResponse response = await createCompleter.future;
    await _database.guildDao.upsertServer(
      db.ServersCompanion.insert(
        id: response.id,
        name: response.name,
        ownerId: Value(response.ownerId),
      ),
    );
    return response;
  }
}

class _RecordingChannelRepository extends ChannelRepository {
  _RecordingChannelRepository(db.FluxerDatabase database)
    : super(FluxerClient(Dio()), Dio(), database);

  final List<String> fetchedGuildIds = <String>[];

  @override
  Future<List<ChannelCategory>> getChannels(String guildId) async {
    fetchedGuildIds.add(guildId);
    return const <ChannelCategory>[];
  }
}

class _RecordingChannelListViewModel extends ChannelListViewModel {
  final List<String> loadedGuildIds = <String>[];

  @override
  void loadChannels(String guildId, {Guild? guild}) {
    loadedGuildIds.add(guildId);
  }
}

class _SlowInvitesApi implements InvitesApi {
  final Completer<InviteResponseSchema> acceptCompleter =
      Completer<InviteResponseSchema>();
  final List<String> acceptedCodes = <String>[];

  @override
  Future<InviteResponseSchema> getInvite({required String inviteCode}) async =>
      _guildInvite;

  @override
  Future<InviteResponseSchema> acceptInvite({required String inviteCode}) {
    acceptedCodes.add(inviteCode);
    return acceptCompleter.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _InviteTestClient extends FluxerClient {
  _InviteTestClient(this._invites) : super(Dio());

  final InvitesApi _invites;

  @override
  InvitesApi get invites => _invites;
}

GoRouter _makeTestRouter(List<String> visitedPaths) {
  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink()),
      GoRoute(
        path: '/channels/:guildId',
        builder: (_, GoRouterState state) {
          visitedPaths.add(state.uri.toString());
          return const SizedBox.shrink();
        },
        routes: <RouteBase>[
          GoRoute(
            path: ':channelId',
            builder: (_, GoRouterState state) {
              visitedPaths.add(state.uri.toString());
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    ],
  );
}

void main() {
  testWidgets(
    'createCommunity finishes channel fetch, loadChannels, and navigation without falsely throwing CreateCommunityException when caller modal unmounts during createGuild',
    (WidgetTester tester) async {
      final db.FluxerDatabase database = openTestDatabase();
      final _SlowCreateGuildRepository guildRepo = _SlowCreateGuildRepository(
        database,
      );
      final _RecordingChannelRepository channelRepo =
          _RecordingChannelRepository(database);
      final _RecordingChannelListViewModel channelListVm =
          _RecordingChannelListViewModel();
      final List<String> visitedPaths = <String>[];
      final GoRouter router = _makeTestRouter(visitedPaths);
      addTearDown(router.dispose);

      final ValueNotifier<bool> mountCaller = ValueNotifier<bool>(true);
      addTearDown(mountCaller.dispose);

      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: database,
          extra: [
            guildRepositoryProvider.overrideWithValue(guildRepo),
            channelRepositoryProvider.overrideWithValue(channelRepo),
            channelListViewModelProvider.overrideWith(() => channelListVm),
            fluxerRouterProvider.overrideWithValue(router),
          ],
        ),
      );
      addTearDown(container.dispose);

      Object? caughtError;
      bool completed = false;
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
            builder: (BuildContext context, Widget? child) => Scaffold(
              body: Column(
                children: <Widget>[
                  Expanded(child: child ?? const SizedBox.shrink()),
                  ValueListenableBuilder<bool>(
                    valueListenable: mountCaller,
                    builder: (_, bool mounted, _) {
                      if (!mounted) {
                        return const SizedBox.shrink();
                      }
                      return Consumer(
                        builder: (BuildContext ctx, WidgetRef ref, _) =>
                            ElevatedButton(
                              onPressed: () {
                                unawaited(
                                  createCommunity(
                                    context: ctx,
                                    ref: ref,
                                    name: 'New Server',
                                    l10n: testL10n,
                                  ).then(
                                    (_) => completed = true,
                                    onError: (Object e) => caughtError = e,
                                  ),
                                );
                              },
                              child: const Text('Create Server'),
                            ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Create Server'));
      await tester.pump();

      // Dismiss/unmount the caller while `createGuild` is in flight.
      mountCaller.value = false;
      await tester.pump();

      guildRepo.createCompleter.complete(
        GuildResponse.fromJson(<String, Object?>{
          'id': _createdGuildId,
          'name': 'New Server',
          'owner_id': 'user-1',
        }),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(tester.takeException(), isNull);
      expect(caughtError, isNull);
      expect(completed, isTrue);
      expect(channelRepo.fetchedGuildIds, <String>[_createdGuildId]);
      expect(channelListVm.loadedGuildIds, <String>[_createdGuildId]);
      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/channels/$_createdGuildId',
      );
    },
  );

  testWidgets(
    'joinCommunityViaInvite stages joined guild and navigates without StateError when caller unmounts while acceptInvite is in flight',
    (WidgetTester tester) async {
      final db.FluxerDatabase database = openTestDatabase();
      final _SlowInvitesApi invitesApi = _SlowInvitesApi();
      final _InviteTestClient client = _InviteTestClient(invitesApi);
      final _RecordingChannelListViewModel channelListVm =
          _RecordingChannelListViewModel();
      final List<String> visitedPaths = <String>[];
      final GoRouter router = _makeTestRouter(visitedPaths);
      addTearDown(router.dispose);

      final ValueNotifier<bool> mountCaller = ValueNotifier<bool>(true);
      addTearDown(mountCaller.dispose);

      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: database,
          extra: [
            wellKnownProvider.overrideWith(FakeWellKnown.new),
            fluxerClientProvider.overrideWithValue(client),
            guildRepositoryProvider.overrideWithValue(
              GuildRepository(client, database),
            ),
            channelListViewModelProvider.overrideWith(() => channelListVm),
            fluxerRouterProvider.overrideWithValue(router),
          ],
        ),
      );
      addTearDown(container.dispose);

      Object? caughtError;
      bool completed = false;
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
            builder: (BuildContext context, Widget? child) => Scaffold(
              body: Column(
                children: <Widget>[
                  Expanded(child: child ?? const SizedBox.shrink()),
                  ValueListenableBuilder<bool>(
                    valueListenable: mountCaller,
                    builder: (_, bool mounted, _) {
                      if (!mounted) {
                        return const SizedBox.shrink();
                      }
                      return Consumer(
                        builder: (BuildContext ctx, WidgetRef ref, _) =>
                            ElevatedButton(
                              onPressed: () {
                                unawaited(
                                  joinCommunityViaInvite(
                                    ref: ref,
                                    rawInput: _inviteCode,
                                    l10n: testL10n,
                                  ).then(
                                    (_) => completed = true,
                                    onError: (Object e) => caughtError = e,
                                  ),
                                );
                              },
                              child: const Text('Join Invite'),
                            ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Join Invite'));
      await tester.pump();
      await tester.pump();
      expect(invitesApi.acceptedCodes, <String>[_inviteCode]);

      // Unmount the caller while `acceptInvite` is in flight.
      mountCaller.value = false;
      await tester.pump();

      invitesApi.acceptCompleter.complete(_guildInvite);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(tester.takeException(), isNull);
      expect(caughtError, isNull);
      expect(completed, isTrue);
      expect(
        (await database.guildDao.getServerById(_invitedGuildId))?.name,
        'Invited Server',
      );
      expect(channelListVm.loadedGuildIds, <String>[_invitedGuildId]);
      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/channels/$_invitedGuildId/$_invitedChannelId',
      );
    },
  );
}
