// Fork: tyne-chat/tyne#946 — regression test for PushNotificationsCoordinator
// cancelling _messageSubscription in ref.onDispose while leaving
// _bootstrapScheduled == true on the kept-alive instance, permanently dropping
// push messages after a provider rebuild/invalidation.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/providers/app/app_ui_lifecycle_provider.dart';
import 'package:fluxer_app/core/providers/push_provider.dart';
import 'package:fluxer_app/core/push/apns/apple_push_notification_tap_binding.dart';
import 'package:fluxer_app/core/push/fcm/fcm_notification_tap_binding.dart';
import 'package:fluxer_app/core/push/push_message.dart';
import 'package:fluxer_app/core/push/push_notifications_coordinator.dart';
import 'package:fluxer_app/core/push/push_service.dart';
import 'package:fluxer_app/core/push/tray/registry.dart';
import 'package:fluxer_app/core/push/tray/registry_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/dm/domain/dm_conversation.dart';
import 'package:fluxer_app/features/dm/providers/dm_view_model.dart';
import 'package:fluxer_app/features/friends/domain/friend.dart';

import '../../helpers/core_test_provider_overrides.dart';
import '../../helpers/open_test_database.dart';

class _EmptyDmViewModel extends DmViewModel {
  @override
  DmViewState build() => const DmViewState(
    conversations: <DmConversation>[],
    friendsList: <Friend>[],
    activeTab: FriendsTab.online,
    searchQuery: '',
  );
}

class _FakePushService implements PushService {
  final StreamController<PushMessage> controller =
      StreamController<PushMessage>.broadcast();
  int initializeCalls = 0;

  @override
  Future<void> initialize() async {
    initializeCalls++;
  }

  @override
  Future<String?> getToken() async => 'fake-token';

  @override
  Stream<PushMessage> watchMessages() => controller.stream;

  Future<void> dispose() => controller.close();
}

void main() {
  testWidgets(
    'invalidating pushNotificationsCoordinatorProvider re-subscribes to pushService.watchMessages()',
    (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final db = openTestDatabase();
      final _FakePushService pushService = _FakePushService();
      addTearDown(pushService.dispose);
      final PushTrayRegistry trayRegistry = PushTrayRegistry();

      final ProviderContainer container = ProviderContainer(
        overrides: coreTestProviderOverrides(
          database: db,
          extra: [
            currentUserIdProvider.overrideWithValue('user-1'),
            appUiForegroundProvider.overrideWithValue(true),
            dmViewModelProvider.overrideWith(_EmptyDmViewModel.new),
            pushServiceProvider.overrideWithValue(pushService),
            pushTrayRegistryProvider.overrideWithValue(trayRegistry),
            applePushNotificationTapBindingProvider.overrideWithValue(null),
            fcmNotificationTapBindingProvider.overrideWithValue(null),
          ],
        ),
      );
      addTearDown(container.dispose);

      final ProviderSubscription<bool> sub = container.listen(
        pushNotificationsCoordinatorProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      // Flush the initial post-frame bootstrap.
      tester.binding.scheduleFrame();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(pushService.initializeCalls, 1);

      pushService.controller.add(
        const PushMessage(
          id: 'p1',
          title: 'Alice',
          body: 'hi',
          payload: <String, String>{
            'channel_id': 'c1',
            'message_id': '100',
            'recipient_id': 'user-1',
          },
        ),
      );
      await tester.pump();
      expect(
        trayRegistry.drain().map((e) => (e.key, e.value)).toList(),
        <(String, String)>[('c1', '100')],
      );

      // Rebuild the kept-alive coordinator via invalidate (while sub is still
      // listening, matching ShellRouteListeners).
      container
        ..invalidate(pushNotificationsCoordinatorProvider)
        ..read(pushNotificationsCoordinatorProvider);
      tester.binding.scheduleFrame();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Emit a second push message — it must still be received rather than
      // silently dropped by a cancelled _messageSubscription!
      pushService.controller.add(
        const PushMessage(
          id: 'p2',
          title: 'Alice',
          body: 'still working?',
          payload: <String, String>{
            'channel_id': 'c1',
            'message_id': '200',
            'recipient_id': 'user-1',
          },
        ),
      );
      await tester.pump();
      expect(
        trayRegistry.drain().map((e) => (e.key, e.value)).toList(),
        <(String, String)>[('c1', '200')],
      );
    },
  );
}
