import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/providers/gateway/gateway_connection_provider.dart';
import 'package:fluxer_app/features/auth/providers/auth_providers.dart';
import 'package:fluxer_app/features/auth/providers/current_auth_session_provider.dart';

Future<void> applyReplacementSession(
  WidgetRef ref, {
  required String token,
  required String authSessionIdHash,
}) => applyReplacementSessionInContainer(
  ref.container,
  token: token,
  authSessionIdHash: authSessionIdHash,
);

// Fork: container-backed session rotation safe after caller sheet/widget
// unmounts (tyne-chat/tyne#946).
Future<void> applyReplacementSessionInContainer(
  ProviderContainer container, {
  required String token,
  required String authSessionIdHash,
}) async {
  container.read(gatewayConnectionProvider).setToken(token);
  container.read(fluxerAuthTokenProvider.notifier).setToken(token);
  container
      .read(currentAuthSessionIdHashProvider.notifier)
      .update(authSessionIdHash);
  await container.read(authRepositoryProvider).persistRotatedToken(token);
}
