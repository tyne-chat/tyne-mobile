// Fork: tyne-chat/tyne#946 — regression tests for unsaveMessageBookmark
// (which optimistically removes and unmounts its own bookmark row before
// unsaveMessage completes), toggleSavedMessageBookmark, and runThreadAction.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart'
    show FluxerDatabase;
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/bookmarks/data/saved_messages_repository.dart';
import 'package:fluxer_app/features/bookmarks/domain/saved_messages.dart';
import 'package:fluxer_app/features/bookmarks/providers/saved_messages_provider.dart';
import 'package:fluxer_app/features/bookmarks/utils/saved_message_actions.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/threads/data/threads_repository.dart';
import 'package:fluxer_app/features/threads/utils/thread_actions.dart';
import 'package:fluxer_app/features/ui/toast/toast_provider.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_dart/export.dart';

import '../../../helpers/core_test_provider_overrides.dart';
import '../../../helpers/open_test_database.dart';
import '../../../helpers/test_l10n.dart';

class _SlowSavedMessagesRepository extends SavedMessagesRepository {
  _SlowSavedMessagesRepository(FluxerDatabase db)
    : super(database: db, client: FluxerClient(Dio()), currentUserId: 'user-1');

  final Completer<void> saveCompleter = Completer<void>();
  final Completer<void> unsaveCompleter = Completer<void>();

  @override
  Future<void> saveMessage({
    required String channelId,
    required String messageId,
  }) => saveCompleter.future;

  @override
  Future<void> unsaveMessage(String messageId) => unsaveCompleter.future;
}

class _SeededSavedMessages extends SavedMessagesNotifier {
  @override
  SavedMessagesState build() {
    return SavedMessagesState(
      fetched: true,
      hasMore: false,
      messages: <Message>[
        Message(
          id: 'msg-1',
          channelId: 'c1',
          authorId: 'u1',
          authorName: 'Alice',
          content: 'saved',
          timestamp: DateTime.utc(2026, 11, 26),
        ),
      ],
    );
  }
}

void main() {
  testWidgets(
    'unsaveMessageBookmark shows removed toast without StateError when optimistic removal unmounts the bookmark item row',
    (WidgetTester tester) async {
      final FluxerDatabase db = openTestDatabase();
      final _SlowSavedMessagesRepository repo = _SlowSavedMessagesRepository(
        db,
      );
      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: db,
          extra: [
            savedMessagesRepositoryProvider.overrideWithValue(repo),
            savedMessagesProvider.overrideWith(_SeededSavedMessages.new),
          ],
        ),
      );
      addTearDown(container.dispose);

      Object? actionError;
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
                builder: (BuildContext context, WidgetRef ref, _) {
                  final messages = ref.watch(savedMessagesProvider).messages;
                  return Column(
                    children: [
                      for (final msg in messages)
                        Consumer(
                          key: ValueKey<String>(msg.id),
                          builder: (_, WidgetRef rowRef, _) => ElevatedButton(
                            onPressed: () {
                              unawaited(
                                unsaveMessageBookmark(
                                  ref: rowRef,
                                  l10n: testL10n,
                                  messageId: msg.id,
                                ).catchError((Object e) {
                                  actionError = e;
                                }),
                              );
                            },
                            child: Text('Unsave ${msg.id}'),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Tapping Unsave calls `handleMessageDelete('msg-1')` synchronously,
      // removing and unmounting the row's `Consumer` (`rowRef`) on the next pump!
      await tester.tap(find.text('Unsave msg-1'));
      await tester.pump();
      expect(find.text('Unsave msg-1'), findsNothing);

      repo.unsaveCompleter.complete();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(actionError, isNull);
      expect(
        container.read(toastProvider).single.toast.message,
        testL10n.savedMessagesRemovedToast,
      );
    },
  );

  testWidgets(
    'toggleSavedMessageBookmark and runThreadAction succeed without StateError when caller unmounts mid-request',
    (WidgetTester tester) async {
      final FluxerDatabase db = openTestDatabase();
      final _SlowSavedMessagesRepository repo = _SlowSavedMessagesRepository(
        db,
      );
      final Completer<void> threadCompleter = Completer<void>();
      final ValueNotifier<bool> mountCaller = ValueNotifier<bool>(true);
      addTearDown(mountCaller.dispose);

      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: db,
          extra: [
            savedMessagesRepositoryProvider.overrideWithValue(repo),
            threadsRepositoryProvider.overrideWithValue(
              ThreadsRepository(FluxerClient(Dio()), db),
            ),
          ],
        ),
      );
      addTearDown(container.dispose);

      Object? saveErr;
      Object? threadErr;
      bool? threadOk;
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
                    builder: (BuildContext context, WidgetRef ref, _) =>
                        ElevatedButton(
                          onPressed: () {
                            unawaited(
                              toggleSavedMessageBookmark(
                                ref: ref,
                                l10n: testL10n,
                                channelId: 'c1',
                                messageId: 'msg-2',
                              ).catchError((Object e) {
                                saveErr = e;
                              }),
                            );
                            unawaited(
                              runThreadAction(
                                context,
                                ref,
                                (_) => threadCompleter.future,
                                successMessage: 'Thread archived',
                              ).then(
                                (bool ok) => threadOk = ok,
                                onError: (Object e) => threadErr = e,
                              ),
                            );
                          },
                          child: const Text('Trigger'),
                        ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pump();

      mountCaller.value = false;
      await tester.pump();

      repo.saveCompleter.complete();
      await tester.pump();
      expect(saveErr, isNull);
      expect(
        container.read(toastProvider).last.toast.message,
        testL10n.savedMessagesAddedToast,
      );

      threadCompleter.complete();
      await tester.pump();
      expect(threadErr, isNull);
      expect(threadOk, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
