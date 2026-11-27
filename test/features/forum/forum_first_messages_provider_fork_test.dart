// Fork: tyne-chat/tyne#946 — regression tests for ForumFirstMessages keeping
// stale `_requested` IDs and a cancelled non-null `_flushTimer` across
// kept-alive provider rebuilds/invalidations.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/core/permissions/thread_permissions.dart';
import 'package:fluxer_app/core/providers/app/account_user_id.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/forum/data/forum_repository.dart';
import 'package:fluxer_app/features/forum/domain/forum_channel.dart';
import 'package:fluxer_app/features/forum/providers/forum_first_messages_provider.dart';
import 'package:fluxer_app/features/threads/providers/thread_ui_providers.dart';

import '../../helpers/open_test_database.dart';

class _RecordingForumRepository implements ForumRepository {
  final List<List<String>> requestedBatches = <List<String>>[];

  @override
  Future<Map<String, Message?>> fetchPostData({
    required String guildId,
    required String forumId,
    required List<String> postIds,
  }) async {
    requestedBatches.add(List<String>.of(postIds));
    return <String, Message?>{
      for (final String id in postIds)
        id: Message(
          id: id,
          channelId: id,
          authorId: 'u1',
          authorName: 'Alice',
          content: 'starter $id',
          timestamp: DateTime.utc(2026, 11, 26),
        ),
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProviderContainer _makeContainer(
  db.FluxerDatabase database,
  _RecordingForumRepository repository,
) {
  return ProviderContainer(
    overrides: <Override>[
      fluxerDatabaseProvider.overrideWithValue(database),
      forumRepositoryProvider.overrideWithValue(repository),
      parentThreadActorProvider('g1', 'f1').overrideWithValue(
        ThreadActor(
          permissions:
              Permission.viewChannel.value |
              Permission.readMessageHistory.value,
        ),
      ),
    ],
  );
}

void main() {
  test(
    'invalidating forumFirstMessagesProvider clears _requested so wiped posts can be fetched again',
    () async {
      final db.FluxerDatabase database = openTestDatabase();
      final _RecordingForumRepository repository = _RecordingForumRepository();
      final ProviderContainer container = _makeContainer(database, repository);
      addTearDown(container.dispose);

      final String uid = readAccountUserId(container);
      final ProviderSubscription<Map<String, Message?>> sub = container.listen(
        forumFirstMessagesProvider(uid),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      container
          .read(forumFirstMessagesProvider(uid).notifier)
          .request(guildId: 'g1', forumId: 'f1', postIds: const <String>['p1']);
      await Future<void>.delayed(
        forumPostDataDebounce + const Duration(milliseconds: 30),
      );
      expect(container.read(forumFirstMessagesProvider(uid))['p1'], isNotNull);
      expect(repository.requestedBatches, <List<String>>[
        <String>['p1'],
      ]);

      // Rebuild the kept-alive provider (wiping state back to `{}`).
      container
        ..invalidate(forumFirstMessagesProvider(uid))
        ..read(forumFirstMessagesProvider(uid));
      expect(container.read(forumFirstMessagesProvider(uid)), isEmpty);

      // Requesting `'p1'` again must re-fetch it rather than being permanently
      // blocked by stale `_requested`.
      container
          .read(forumFirstMessagesProvider(uid).notifier)
          .request(guildId: 'g1', forumId: 'f1', postIds: const <String>['p1']);
      await Future<void>.delayed(
        forumPostDataDebounce + const Duration(milliseconds: 30),
      );

      expect(repository.requestedBatches, <List<String>>[
        <String>['p1'],
        <String>['p1'],
      ]);
      expect(container.read(forumFirstMessagesProvider(uid))['p1'], isNotNull);
    },
  );

  test(
    'invalidating forumFirstMessagesProvider while _flushTimer is pending clears _flushTimer so future requests still flush',
    () async {
      final db.FluxerDatabase database = openTestDatabase();
      final _RecordingForumRepository repository = _RecordingForumRepository();
      final ProviderContainer container = _makeContainer(database, repository);
      addTearDown(container.dispose);

      final String uid = readAccountUserId(container);
      final ProviderSubscription<Map<String, Message?>> sub = container.listen(
        forumFirstMessagesProvider(uid),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      // Arm `_flushTimer` debounce and immediately invalidate BEFORE it fires!
      container
          .read(forumFirstMessagesProvider(uid).notifier)
          .request(guildId: 'g1', forumId: 'f1', postIds: const <String>['p1']);
      container
        ..invalidate(forumFirstMessagesProvider(uid))
        ..read(forumFirstMessagesProvider(uid));

      // Now request a brand-new post `'p2'`. `_flushTimer` must not remain stuck
      // on the cancelled timer from the previous build!
      container
          .read(forumFirstMessagesProvider(uid).notifier)
          .request(guildId: 'g1', forumId: 'f1', postIds: const <String>['p2']);
      await Future<void>.delayed(
        forumPostDataDebounce + const Duration(milliseconds: 30),
      );

      expect(repository.requestedBatches, <List<String>>[
        <String>['p2'],
      ]);
      expect(container.read(forumFirstMessagesProvider(uid))['p2'], isNotNull);
    },
  );
}
