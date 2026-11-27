import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/providers/app/account_user_id.dart';
import 'package:fluxer_app/features/shell/providers/user/current_user_private_provider.dart';
import 'package:fluxer_dart/export.dart';

Future<void> clearUnreadGiftInventoryFlag(WidgetRef ref) =>
    clearUnreadGiftInventoryFlagInContainer(ref.container);

Future<void> dismissPremiumOnboardingFlag(WidgetRef ref) =>
    dismissPremiumOnboardingFlagInContainer(ref.container);

// Fork: container-backed nagbar flag updates safe after self-unmounting
// dismissal (tyne-chat/tyne#946).
Future<void> clearUnreadGiftInventoryFlagInContainer(
  ProviderContainer container,
) async {
  final FluxerClient client = container.read(fluxerClientProvider);
  final String accountUserId = readAccountUserId(container);
  await client.users.updateCurrentUser(
    body: UserUpdateWithVerificationRequest(hasUnreadGiftInventory: false),
  );
  await container
      .read(currentUserPrivateReadProvider(accountUserId).notifier)
      .refresh();
}

Future<void> dismissPremiumOnboardingFlagInContainer(
  ProviderContainer container,
) async {
  final FluxerClient client = container.read(fluxerClientProvider);
  final String accountUserId = readAccountUserId(container);
  await client.users.updateCurrentUser(
    body: UserUpdateWithVerificationRequest(
      hasDismissedPremiumOnboarding: true,
    ),
  );
  await container
      .read(currentUserPrivateReadProvider(accountUserId).notifier)
      .refresh();
}
