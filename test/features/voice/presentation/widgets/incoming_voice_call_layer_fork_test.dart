// Fork: tyne-chat/tyne#946 — regression tests for executeDeclineIncomingVoiceCall
// reading unmounted ref after await leaveVoice (skipping stop-ringing API call),
// and navigateToChannelContent reading unmounted ref after await loadGuildChannelById.
import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/daos/channel_dao.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/gateway/providers/gateway_event_providers.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/channels/utils/navigation/navigate_to_channel_content.dart';
import 'package:fluxer_app/features/threads/data/threads_repository.dart';
import 'package:fluxer_app/features/voice/providers/voice_session_provider.dart';
import 'package:fluxer_app/features/voice/providers/voice_session_state.dart';
import 'package:fluxer_app/features/voice/utils/callkit/incoming_call_actions.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_dart/export.dart' hide ChannelType;

import '../../../../helpers/core_test_provider_overrides.dart';
import '../../../../helpers/open_test_database.dart';
import '../../../../helpers/test_l10n.dart';

const String _callChannelId = 'call-dm-1';

class _SlowLeavingVoiceSession extends VoiceSession {
  final Completer<void> leaveCompleter = Completer<void>();

  @override
  VoiceSessionState build() =>
      const VoiceSessionState(channelId: _callChannelId, isConnected: true);

  @override
  Future<void> leaveVoice({bool endCall = false}) => leaveCompleter.future;
}

class _RecordingAdapter implements HttpClientAdapter {
  final List<String> paths = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add('${options.method} ${options.path}');
    return ResponseBody.fromString('', 204);
  }

  @override
  void close({bool force = false}) {}
}

class _StubThreadsRepository extends Fake implements ThreadsRepository {
  @override
  Future<Channel?> loadCachedThread({
    required String guildId,
    required String threadId,
  }) async => null;
}

class _SlowChannelDao extends ChannelDao {
  _SlowChannelDao(super.attachedDatabase);

  final Completer<db.Channel?> lookupCompleter = Completer<db.Channel?>();

  @override
  Future<db.Channel?> getChannelById(String id) => lookupCompleter.future;
}

class _SlowChannelDatabase extends db.FluxerDatabase {
  _SlowChannelDatabase() : super.forTesting(NativeDatabase.memory());

  late final _SlowChannelDao slowChannels = _SlowChannelDao(this);

  @override
  ChannelDao get channelDao => slowChannels;
}

void main() {
  testWidgets(
    'executeDeclineIncomingVoiceCall still stops server ringing without StateError if caller unmounts during leaveVoice',
    (WidgetTester tester) async {
      final db = openTestDatabase();
      final _SlowLeavingVoiceSession voice = _SlowLeavingVoiceSession();
      final _RecordingAdapter adapter = _RecordingAdapter();
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://api.fluxer.app/v1'))
        ..httpClientAdapter = adapter;
      final ValueNotifier<bool> mountCaller = ValueNotifier<bool>(true);
      addTearDown(mountCaller.dispose);
      final colorTheme = buildDarkColorTheme();

      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: db,
          extra: [
            currentUserIdProvider.overrideWithValue('user-1'),
            voiceSessionProvider.overrideWith(() => voice),
            fluxerClientProvider.overrideWithValue(FluxerClient(dio)),
          ],
        ),
      );
      addTearDown(container.dispose);

      container
          .read(activeCallsProvider('user-1').notifier)
          .createCall(
            _callChannelId,
            messageId: 'm-ring',
            ringing: const <String>['user-1'],
          );

      Object? declineError;
      bool declineDone = false;

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
                    builder: (BuildContext context, WidgetRef ref, _) {
                      return ElevatedButton(
                        onPressed: () {
                          unawaited(
                            executeDeclineIncomingVoiceCall(
                              ref,
                              context,
                              _callChannelId,
                            ).then(
                              (_) {
                                declineDone = true;
                              },
                              onError: (Object e) {
                                declineError = e;
                                declineDone = true;
                              },
                            ),
                          );
                        },
                        child: const Text('Decline'),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Decline'));
      await tester.pump();

      // Unmount caller while `leaveVoice` is still awaiting.
      mountCaller.value = false;
      await tester.pump();

      voice.leaveCompleter.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(declineError, isNull);
      expect(declineDone, isTrue);
      expect(
        adapter.paths,
        contains('POST /channels/$_callChannelId/call/stop-ringing'),
      );
    },
  );

  testWidgets(
    'navigateToChannelContent aborts cleanly without StateError when caller unmounts while resolving an uncached guild channel',
    (WidgetTester tester) async {
      final _SlowChannelDatabase slowDb = _SlowChannelDatabase();
      addTearDown(() async {
        await releaseTestWidgetTree(tester);
        await slowDb.close();
      });
      final ValueNotifier<bool> mountCaller = ValueNotifier<bool>(true);
      addTearDown(mountCaller.dispose);
      final colorTheme = buildDarkColorTheme();

      Object? navError;
      bool navDone = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: coreTestProviderOverrides(
            database: slowDb,
            extra: [
              threadsRepositoryProvider.overrideWithValue(
                _StubThreadsRepository(),
              ),
            ],
          ),
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
                    builder: (BuildContext context, WidgetRef ref, _) {
                      return ElevatedButton(
                        onPressed: () {
                          unawaited(
                            navigateToChannelContent(
                              context: context,
                              ref: ref,
                              guildId: 'g1',
                              channelId: 'uncached-thread-1',
                            ).then(
                              (_) {
                                navDone = true;
                              },
                              onError: (Object e) {
                                navError = e;
                                navDone = true;
                              },
                            ),
                          );
                        },
                        child: const Text('Navigate'),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pump();

      // Unmount caller cleanly while `loadGuildChannelById` is awaiting SQLite.
      mountCaller.value = false;
      await tester.pump();

      // Complete the lookup with `null` so `navigateToChannelContent` resumes.
      slowDb.slowChannels.lookupCompleter.complete(null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(navError, isNull);
      expect(navDone, isTrue);
    },
  );
}
