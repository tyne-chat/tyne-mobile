// Fork: tyne-chat/tyne#946 — regression tests for ForumPostComposerSheet
// dismissed mid-create, updateForumPost caller unmount, and
// toggleForumDefaultReaction caller unmount.
import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/core/permissions/thread_permissions.dart';
import 'package:fluxer_app/core/providers/app/account_user_id.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/forum/data/forum_repository.dart';
import 'package:fluxer_app/features/forum/presentation/forum_post_actions.dart';
import 'package:fluxer_app/features/forum/presentation/sheets/forum_post_composer_sheet.dart';
import 'package:fluxer_app/features/forum/presentation/widgets/forum_post_card.dart';
import 'package:fluxer_app/features/forum/providers/forum_first_messages_provider.dart';
import 'package:fluxer_app/features/threads/providers/thread_ui_providers.dart';
import 'package:fluxer_app/features/ui/toast/toast_provider.dart';
import 'package:fluxer_app/material_ui.dart';

import '../../../helpers/core_test_provider_overrides.dart';
import '../../../helpers/open_test_database.dart';
import '../../../helpers/test_l10n.dart';

const String _guildId = 'g1';
const String _forumId = 'f1';
const String _postId = 'post-101';

final Channel _forum = Channel(
  id: _forumId,
  guildId: _guildId,
  name: 'questions',
  type: ChannelType.guildForum,
  rateLimitPerUser: 30,
  defaultReactionEmojiJson: jsonEncode(<String, Object?>{
    'emoji_id': null,
    'emoji_name': '❤️',
  }),
);

const Channel _post = Channel(
  id: _postId,
  guildId: _guildId,
  parentId: _forumId,
  name: 'How to test?',
  type: ChannelType.publicThread,
);

class _SlowForumRepository extends Fake implements ForumRepository {
  final Completer<({String postId, Message? firstMessage})> createCompleter =
      Completer<({String postId, Message? firstMessage})>();
  final Completer<Channel> updateCompleter = Completer<Channel>();
  final Completer<void> reactCompleter = Completer<void>();

  @override
  Future<({String postId, Message? firstMessage})> createPost({
    required String guildId,
    required String forumId,
    required ForumPostDraft draft,
  }) => createCompleter.future;

  @override
  Future<Channel> updatePost({
    required String guildId,
    required String postId,
    required Map<String, Object?> patch,
  }) => updateCompleter.future;

  @override
  Future<void> reactToPost({
    required String guildId,
    required String postId,
    required String emoji,
    required bool add,
  }) => reactCompleter.future;
}

void main() {
  testWidgets(
    'dismissing ForumPostComposerSheet while createPost awaits still caches firstMessage and starts cooldown without StateError',
    (WidgetTester tester) async {
      final db.FluxerDatabase database = openTestDatabase();
      final _SlowForumRepository repo = _SlowForumRepository();
      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: database,
          extra: [
            forumRepositoryProvider.overrideWithValue(repo),
            parentThreadActorProvider(_guildId, _forumId).overrideWithValue(
              ThreadActor(
                permissions:
                    Permission.viewChannel.value |
                    Permission.sendMessages.value |
                    Permission.createPublicThreads.value,
              ),
            ),
          ],
        ),
      );
      addTearDown(container.dispose);

      final colorTheme = buildDarkColorTheme();
      await tester.pumpWidget(
        UncontrolledProviderScope(
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
            home: Scaffold(
              body: Consumer(
                builder: (BuildContext context, WidgetRef ref, _) => Center(
                  child: ElevatedButton(
                    onPressed: () =>
                        showForumPostComposerSheet(context, ref, forum: _forum),
                    child: const Text('New Post'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('New Post'));
      await tester.pumpAndSettle();

      final Finder fields = find.byType(EditableText);
      await tester.enterText(fields.at(0), 'How to test?');
      await tester.enterText(fields.at(1), 'Details inside');
      await tester.pump();

      await tester.ensureVisible(find.text(testL10n.forumPostSubmit));
      await tester.pumpAndSettle();
      await tester.tap(find.text(testL10n.forumPostSubmit));
      await tester.pump();

      // Dismiss the sheet while `createPost` is in flight.
      Navigator.of(tester.element(find.byType(EditableText).first)).pop();
      await tester.pumpAndSettle();

      final Message starter = Message(
        id: _postId,
        channelId: _postId,
        authorId: '42',
        authorName: 'Alice',
        content: 'Details inside',
        timestamp: DateTime.utc(2026, 11, 26, 12),
      );
      repo.createCompleter.complete((postId: _postId, firstMessage: starter));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      final String uid = readAccountUserId(container);
      expect(
        container.read(forumFirstMessagesProvider(uid))[_postId]?.content,
        'Details inside',
      );
      expect(
        container
            .read(threadCreateCooldownsProvider.notifier)
            .remainingSeconds(_forumId),
        greaterThan(0),
      );
    },
  );

  testWidgets(
    'updateForumPost and toggleForumDefaultReaction show toasts without StateError when caller unmounts mid-request',
    (WidgetTester tester) async {
      final db.FluxerDatabase database = openTestDatabase();
      final _SlowForumRepository repo = _SlowForumRepository();
      final ValueNotifier<bool> mountCaller = ValueNotifier<bool>(true);
      addTearDown(mountCaller.dispose);
      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: database,
          extra: [forumRepositoryProvider.overrideWithValue(repo)],
        ),
      );
      addTearDown(container.dispose);

      Object? updateErr;
      bool? updateResult;
      Object? reactErr;

      final colorTheme = buildDarkColorTheme();
      await tester.pumpWidget(
        UncontrolledProviderScope(
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
            home: Scaffold(
              body: ValueListenableBuilder<bool>(
                valueListenable: mountCaller,
                builder: (_, bool mounted, _) {
                  if (!mounted) {
                    return const SizedBox.shrink();
                  }
                  return Consumer(
                    builder: (BuildContext context, WidgetRef ref, _) => Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            unawaited(
                              updateForumPost(
                                context,
                                ref,
                                _post,
                                const <String, Object?>{'flags': 2},
                                successMessage: 'Post pinned',
                              ).then(
                                (bool ok) => updateResult = ok,
                                onError: (Object e) => updateErr = e,
                              ),
                            );
                            unawaited(
                              toggleForumDefaultReaction(
                                context,
                                ref,
                                _forum,
                                ForumPostCardData(
                                  forum: _forum,
                                  post: _post,
                                  firstMessageLoaded: true,
                                  firstMessage: Message(
                                    id: _postId,
                                    channelId: _postId,
                                    authorId: '42',
                                    authorName: 'Alice',
                                    content: 'hello',
                                    timestamp: DateTime.utc(2026, 11, 26),
                                  ),
                                ),
                              ).catchError((Object e) {
                                reactErr = e;
                              }),
                            );
                          },
                          child: const Text('Run Actions'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Run Actions'));
      await tester.pump();

      mountCaller.value = false;
      await tester.pump();

      repo.updateCompleter.complete(_post);
      await tester.pump();
      expect(updateErr, isNull);
      expect(updateResult, isTrue);
      expect(container.read(toastProvider).last.toast.message, 'Post pinned');

      repo.reactCompleter.completeError(Exception('rate limited'));
      await tester.pump();
      expect(reactErr, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
