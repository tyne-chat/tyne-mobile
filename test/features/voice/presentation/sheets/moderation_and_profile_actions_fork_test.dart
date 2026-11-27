// Fork: tyne-chat/tyne#946 — regression tests for Group B moderation, member
// role, menu resolution, and blocked-DM async WidgetRef/mounted hazards.

import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/dm/data/dm_repository.dart';
import 'package:fluxer_app/features/dm/providers/dm_providers.dart';
import 'package:fluxer_app/features/friends/data/friend_repository.dart';
import 'package:fluxer_app/features/friends/domain/friend.dart';
import 'package:fluxer_app/features/friends/providers/friend_providers.dart';
import 'package:fluxer_app/features/members/data/guild_member_role_repository.dart';
import 'package:fluxer_app/features/members/providers/guild_member_role_repository_provider.dart';
import 'package:fluxer_app/features/members/utils/guild_member_menu_state.dart';
import 'package:fluxer_app/features/members/utils/member_role_actions.dart';
import 'package:fluxer_app/features/profile/presentation/menus/guild_member_moderation_menu_items.dart';
import 'package:fluxer_app/features/profile/presentation/sheets/user_profile_actions_sheet.dart';
import 'package:fluxer_app/features/profile/presentation/widgets/user_profile_view.dart';
import 'package:fluxer_app/features/profile/providers/public_persona_list_provider.dart';
import 'package:fluxer_app/features/profile/providers/user_note_view_model.dart';
import 'package:fluxer_app/features/profile/providers/user_presence_provider.dart';
import 'package:fluxer_app/features/profile/providers/user_relationship_provider.dart';
import 'package:fluxer_app/features/profile/utils/profile_menu_capabilities.dart';
import 'package:fluxer_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:fluxer_app/features/ui/toast/fluxer_toast_overlay.dart';
import 'package:fluxer_app/features/ui/toast/toast_provider.dart';
import 'package:fluxer_app/features/voice/presentation/sheets/voice_participant_guild_moderation_entries.dart';
import 'package:fluxer_app/features/voice/presentation/sheets/voice_participant_menu_data.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/providers/user_profile.dart';
import 'package:fluxer_app/shared/utils/fluxer_haptics.dart';
import 'package:fluxer_dart/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/core_test_provider_overrides.dart';
import '../../../../helpers/open_test_database.dart';
import '../../../../helpers/test_account_user_id.dart';
import '../../../../helpers/test_l10n.dart';

const String _guildId = 'g1';
const String _targetUserId = 'u2';
const String _roleId = 'r1';

const ProfileMenuCapabilities _kickCapable = ProfileMenuCapabilities(
  canChangeNickname: false,
  canTransfer: false,
  showTimeout: false,
  showRemoveTimeout: false,
  canKick: true,
  canBan: false,
  showManageRoles: false,
  showCommunityMute: false,
  showCommunityDeafen: false,
  showDisconnectFromVoice: false,
);

const UserPartialResponse _targetUser = UserPartialResponse(
  id: _targetUserId,
  username: 'bob',
  discriminator: '0002',
  globalName: 'Bob',
  avatar: null,
  avatarColor: null,
  flags: 0,
);

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
      home: FluxerToastOverlay(child: child),
    ),
  );
}

class _RecordingFriendRepository extends Fake implements FriendRepository {
  final List<String> blockedUserIds = <String>[];
  int watchCalls = 0;

  @override
  Stream<List<Friend>> watchRelationships() {
    watchCalls++;
    return Stream<List<Friend>>.value(const <Friend>[
      Friend(
        id: _targetUserId,
        username: 'bob',
        friendStatus: FriendStatus.blocked,
      ),
    ]);
  }

  @override
  Future<void> blockUser(String userId) async {
    blockedUserIds.add(userId);
  }
}

class _RecordingGuildsApi implements GuildsApi {
  final List<(String guildId, String userId)> kickedMembers =
      <(String, String)>[];

  @override
  Future<void> removeGuildMember({
    required String guildId,
    required String userId,
    String? reason,
  }) async {
    kickedMembers.add((guildId, userId));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'Unexpected GuildsApi call: ${invocation.memberName}',
  );
}

class _RecordingModerationClient implements FluxerClient {
  _RecordingModerationClient(this._guilds);

  final _RecordingGuildsApi _guilds;

  @override
  GuildsApi get guilds => _guilds;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'Unexpected FluxerClient call: ${invocation.memberName}',
  );
}

class _SlowMemberRoleRepository extends Fake
    implements GuildMemberRoleRepository {
  final Completer<void> removeCompleter = Completer<void>();
  int removeCalls = 0;

  @override
  Future<void> removeMemberRole({
    required String guildId,
    required String userId,
    required String roleId,
  }) async {
    removeCalls++;
    await removeCompleter.future;
  }
}

class _FixedSettings extends UserSettingsViewModel {
  @override
  UserSettingsViewState build() => const UserSettingsViewState(
    userId: kTestAccountUserId,
    username: 'alice',
    displayName: 'Alice',
    discriminator: '0001',
    avatar: null,
    avatarColor: null,
    memberSince: null,
    status: 'online',
    messageDisplayCompact: false,
    developerMode: false,
    trustedDomains: <String>[],
  );
}

class _NullUserNote extends UserNoteViewModel {
  @override
  Stream<String?> build({required String userId}) =>
      Stream<String?>.value(null);
}

class _RecordingDmRepository extends Fake implements DmRepository {
  int ensureDmCalls = 0;

  @override
  Future<String> ensureDmChannel(String recipientId) async {
    ensureDmCalls++;
    return 'dm-1';
  }
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
    'UserProfileActionsSheet.show and appendGuildMemberModerationMenuItems succeed when caller unmounts during confirm modal',
    (WidgetTester tester) async {
      final db.FluxerDatabase database = openTestDatabase();
      final _RecordingFriendRepository friendRepo =
          _RecordingFriendRepository();
      final _RecordingGuildsApi guildsApi = _RecordingGuildsApi();
      final ValueNotifier<bool> mountCaller = ValueNotifier<bool>(true);
      addTearDown(mountCaller.dispose);

      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: database,
          extra: <Override>[
            userSettingsViewModelProvider.overrideWith(_FixedSettings.new),
            friendRepositoryProvider.overrideWithValue(friendRepo),
            fluxerClientProvider.overrideWithValue(
              _RecordingModerationClient(guildsApi),
            ),
          ],
        ),
      );
      addTearDown(container.dispose);

      // Keep friendsListProvider active so invalidation increments watchCalls.
      container.listen(friendsListProvider, (_, _) {});
      await tester.pump();
      final int baselineWatches = friendRepo.watchCalls;

      late BuildContext rootCtx;
      final List<Widget> builtModerationItems = <Widget>[];

      await tester.pumpWidget(
        _appShell(
          container: container,
          child: Builder(
            builder: (BuildContext outerCtx) {
              rootCtx = outerCtx;
              return Scaffold(
                body: ValueListenableBuilder<bool>(
                  valueListenable: mountCaller,
                  builder: (_, bool mounted, _) {
                    if (!mounted) {
                      return Column(children: builtModerationItems);
                    }
                    return Consumer(
                      builder: (BuildContext ctx, WidgetRef ref, _) {
                        return Column(
                          children: <Widget>[
                            ElevatedButton(
                              onPressed: () => UserProfileActionsSheet.show(
                                rootCtx,
                                ref,
                                relationship: null,
                                user: _targetUser,
                                isCurrentUser: false,
                                position: Offset.zero,
                                displayName: 'Bob',
                              ),
                              child: const Text('OpenProfileMenu'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                builtModerationItems.clear();
                                appendGuildMemberModerationMenuItems(
                                  items: builtModerationItems,
                                  context: rootCtx,
                                  ref: ref,
                                  close: () {},
                                  l10n: testL10n,
                                  guildId: _guildId,
                                  userId: _targetUserId,
                                  username: 'bob',
                                  capabilities: _kickCapable,
                                  currentNick: null,
                                );
                              },
                              child: const Text('BuildModItems'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      );

      // 1. Open UserProfileActionsSheet, tap Block User, unmount caller, confirm.
      await tester.tap(find.text('OpenProfileMenu'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(testL10n.userProfileBlockUser));
      await tester.pumpAndSettle();

      mountCaller.value = false;
      await tester.pump();

      await tester.tap(find.text(testL10n.userProfileBlockUser).last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(friendRepo.blockedUserIds, <String>[_targetUserId]);
      expect(friendRepo.watchCalls, greaterThan(baselineWatches));

      // 2. Remount caller, build moderation menu items, unmount caller mid-confirm, confirm Kick.
      mountCaller.value = true;
      await tester.pump();
      await tester.tap(find.text('BuildModItems'));
      await tester.pump();

      mountCaller.value = false;
      await tester.pump();

      await tester.tap(find.text(testL10n.userProfileKick));
      await tester.pumpAndSettle();

      await tester.tap(find.text(testL10n.userProfileKick).last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(guildsApi.kickedMembers, <(String, String)>[
        (_guildId, _targetUserId),
      ]);
      expect(
        container.read(toastProvider).last.toast.message,
        testL10n.userProfileKickSuccess('bob'),
      );
    },
  );

  testWidgets(
    'buildVoiceParticipantGuildModerationEntries, toggleMemberRole, and resolveGuildMemberMenuStateForUser survive caller unmount',
    (WidgetTester tester) async {
      final db.FluxerDatabase database = openTestDatabase();
      await database.guildDao.upsertServer(
        db.ServersCompanion.insert(
          id: _guildId,
          name: 'Guild',
          ownerId: const Value(kTestAccountUserId),
        ),
      );
      await database.roleDao.upsertRoles(<db.RolesCompanion>[
        db.RolesCompanion.insert(
          id: _guildId,
          guildId: _guildId,
          name: '@everyone',
          permissions: Value(Permission.viewChannel.value.toString()),
        ),
      ]);
      await database.userDao.upsertUser(
        db.UsersCompanion.insert(
          id: _targetUserId,
          username: 'bob',
          discriminator: const Value('0002'),
        ),
      );
      await database.memberDao.upsertMember(
        db.MembersCompanion.insert(
          guildId: _guildId,
          userId: _targetUserId,
          roleIdsJson: const Value('[]'),
        ),
      );

      final _RecordingGuildsApi guildsApi = _RecordingGuildsApi();
      final _SlowMemberRoleRepository roleRepo = _SlowMemberRoleRepository();
      final ValueNotifier<bool> mountCaller = ValueNotifier<bool>(true);
      addTearDown(mountCaller.dispose);

      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: database,
          extra: <Override>[
            userSettingsViewModelProvider.overrideWith(_FixedSettings.new),
            fluxerClientProvider.overrideWithValue(
              _RecordingModerationClient(guildsApi),
            ),
            guildMemberRoleRepositoryProvider.overrideWithValue(roleRepo),
          ],
        ),
      );
      addTearDown(container.dispose);

      late BuildContext rootCtx;
      late WidgetRef callerRef;

      await tester.pumpWidget(
        _appShell(
          container: container,
          child: Builder(
            builder: (BuildContext outerCtx) {
              rootCtx = outerCtx;
              return Scaffold(
                body: ValueListenableBuilder<bool>(
                  valueListenable: mountCaller,
                  builder: (_, bool mounted, _) => mounted
                      ? Consumer(
                          builder: (_, WidgetRef ref, _) {
                            callerRef = ref;
                            return const SizedBox.shrink();
                          },
                        )
                      : const SizedBox.shrink(),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();

      // 1. Voice participant moderation Kick entry unmounts caller before confirm.
      final List<VoiceParticipantMenuEntry> entries =
          buildVoiceParticipantGuildModerationEntries(
            context: rootCtx,
            ref: callerRef,
            l10n: testL10n,
            guildId: _guildId,
            userId: _targetUserId,
            username: 'bob',
            capabilities: _kickCapable,
            currentNick: null,
            close: () {},
          );
      final VoiceParticipantMenuActionEntry kickEntry =
          entries.single as VoiceParticipantMenuActionEntry;
      kickEntry.onPressed();
      await tester.pumpAndSettle();

      mountCaller.value = false;
      await tester.pump();

      await tester.tap(find.text(testL10n.userProfileKick).last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(guildsApi.kickedMembers, <(String, String)>[
        (_guildId, _targetUserId),
      ]);

      // 2. Remount caller -> invoke toggleMemberRole -> unmount mid-request.
      mountCaller.value = true;
      await tester.pump();

      Object? toggleError;
      bool? toggleResult;
      unawaited(
        toggleMemberRole(
          callerRef,
          guildId: _guildId,
          userId: _targetUserId,
          roleId: _roleId,
          hasRole: true,
        ).then(
          (bool value) => toggleResult = value,
          onError: (Object e) => toggleError = e,
        ),
      );
      await tester.pump();

      mountCaller.value = false;
      await tester.pump();

      roleRepo.removeCompleter.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(toggleError, isNull);
      expect(toggleResult, isTrue);
      expect(roleRepo.removeCalls, 1);

      // 3. Remount caller -> invoke resolveGuildMemberMenuStateForUser -> unmount immediately.
      mountCaller.value = true;
      await tester.pump();

      Object? resolveError;
      GuildMemberMenuState? resolvedState;
      unawaited(
        resolveGuildMemberMenuStateForUser(
          ref: callerRef,
          guildId: _guildId,
          userId: _targetUserId,
        ).then(
          (GuildMemberMenuState? value) => resolvedState = value,
          onError: (Object e) => resolveError = e,
        ),
      );
      mountCaller.value = false;
      await tester.pumpAndSettle();

      expect(resolveError, isNull);
      expect(resolvedState, isNotNull);
    },
  );

  testWidgets(
    'UserProfileView blocked-DM confirmation aborts cleanly when unmounted before confirmation resolves',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final db.FluxerDatabase database = openTestDatabase();
      final _RecordingDmRepository dmRepo = _RecordingDmRepository();
      final ScrollController scrollController = ScrollController();
      addTearDown(scrollController.dispose);
      final ValueNotifier<bool> mountProfile = ValueNotifier<bool>(true);
      addTearDown(mountProfile.dispose);

      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: database,
          extra: <Override>[
            userSettingsViewModelProvider.overrideWith(_FixedSettings.new),
            dmRepositoryProvider.overrideWithValue(dmRepo),
            publicPersonaListProvider(
              _targetUserId,
            ).overrideWith((Ref ref) => const PublicPersonaListForbidden()),
            userRowProvider(_targetUserId).overrideWith(
              (Ref ref) => Stream<db.User?>.value(
                const db.User(
                  id: _targetUserId,
                  username: 'bob',
                  discriminator: '0002',
                  globalName: 'Bob',
                  bot: false,
                  system: false,
                  status: 'offline',
                  mobile: false,
                  hiddenProfileBadgesJson: '[]',
                ),
              ),
            ),
            userPresenceProvider(_targetUserId).overrideWithBuild(
              (_, _) => const UserPresence(status: 'offline'),
            ),
            userNoteViewModelProvider(
              userId: _targetUserId,
            ).overrideWith(_NullUserNote.new),
            userProfileProvider(userId: _targetUserId).overrideWith(
              (Ref ref) => Future<UserProfileFullResponse?>.value(
                const UserProfileFullResponse(
                  user: _targetUser,
                  userProfile: UserProfileFullResponseUserProfile(
                    bio: null,
                    pronouns: null,
                    banner: null,
                    accentColor: null,
                  ),
                  timezoneOffset: null,
                ),
              ),
            ),
            userRelationshipProvider(userId: _targetUserId).overrideWith(
              (Ref ref) => Stream<Friend?>.value(
                const Friend(
                  id: _targetUserId,
                  username: 'bob',
                  friendStatus: FriendStatus.blocked,
                ),
              ),
            ),
          ],
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _appShell(
          container: container,
          child: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: mountProfile,
              builder: (_, bool mounted, _) => mounted
                  ? UserProfileView(
                      userId: _targetUserId,
                      autoFocusNote: false,
                      scrollController: scrollController,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(testL10n.userProfileOpenDm));
      await tester.pumpAndSettle();

      mountProfile.value = false;
      await tester.pump();

      final int talkerLogsBeforeConfirm = talker.history.length;
      await tester.tap(find.text(testL10n.userProfileOpenDm).last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(dmRepo.ensureDmCalls, 0);
      expect(talker.history.skip(talkerLogsBeforeConfirm), isEmpty);
    },
  );
}
