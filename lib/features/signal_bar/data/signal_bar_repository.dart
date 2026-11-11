import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/features/signal_bar/domain/signal_bar_models.dart';

/// REST access to the signal bar, through the shared authenticated [Dio]. The
/// generated SDK has these routes too; this folder parses by hand, as it
/// always has.
class SignalBarRepository {
  const SignalBarRepository(this._dio);

  final Dio _dio;

  Future<SignalBarConfig> fetchBar() async {
    final Response<Map<String, dynamic>> response = await _dio
        .get<Map<String, dynamic>>('/instance/signal-bar');
    return SignalBarConfig.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<({bool enabled, int barVersion, List<SignalEntry> entries})>
  fetchChannel(String channelId) async {
    final Response<Map<String, dynamic>> response = await _dio
        .get<Map<String, dynamic>>('/channels/$channelId/signals');
    final Map<String, dynamic> data =
        response.data ?? const <String, dynamic>{};
    return (
      enabled: data['enabled'] as bool? ?? false,
      barVersion: (data['bar_version'] as num?)?.toInt() ?? 0,
      entries: <SignalEntry>[
        for (final Object? item
            in data['entries'] as List<dynamic>? ?? const [])
          SignalEntry.fromJson(item! as Map<String, dynamic>),
      ],
    );
  }

  Future<void> activate(
    String channelId,
    String signalId, {
    String? personaId,
  }) async {
    await _dio.put<void>(
      '/channels/$channelId/signals/$signalId/@me',
      data: <String, dynamic>{'persona_id': ?personaId},
    );
  }

  Future<void> deactivate(String channelId, String signalId) async {
    await _dio.delete<void>('/channels/$channelId/signals/$signalId/@me');
  }

  Future<void> removeUser(
    String channelId,
    String signalId,
    String userId,
  ) async {
    await _dio.delete<void>(
      '/channels/$channelId/signals/$signalId/users/$userId',
    );
  }

  Future<void> reset(String channelId, String signalId) async {
    await _dio.delete<void>('/channels/$channelId/signals/$signalId');
  }

  /// Every chat where the account has a signal on.
  Future<UserSignalsSummary> fetchMySignals() async {
    final Response<Map<String, dynamic>> response = await _dio
        .get<Map<String, dynamic>>('/users/@me/signals');
    return UserSignalsSummary.fromJson(
      response.data ?? const <String, dynamic>{},
    );
  }

  /// Sets [signalId] in every chat where the account has a signal on, and in
  /// [channelId] as [personaId]; with [signalId] null, turns every signal off.
  Future<UserSignalsSummary> setEverywhere({
    required String? signalId,
    String? channelId,
    String? personaId,
  }) async {
    final Response<Map<String, dynamic>> response = await _dio
        .put<Map<String, dynamic>>(
          '/users/@me/signals',
          data: <String, dynamic>{
            'signal_id': signalId,
            'channel_id': ?channelId,
            'persona_id': ?personaId,
          },
        );
    return UserSignalsSummary.fromJson(
      response.data ?? const <String, dynamic>{},
    );
  }

  Future<UserSignalsRestorePreview> fetchRestorePreview() async {
    final Response<Map<String, dynamic>> response = await _dio
        .get<Map<String, dynamic>>('/users/@me/signals/restore');
    return UserSignalsRestorePreview.fromJson(
      response.data ?? const <String, dynamic>{},
    );
  }

  Future<UserSignalsSummary> restore() async {
    final Response<Map<String, dynamic>> response = await _dio
        .post<Map<String, dynamic>>('/users/@me/signals/restore');
    return UserSignalsSummary.fromJson(
      response.data ?? const <String, dynamic>{},
    );
  }
}

final Provider<SignalBarRepository> signalBarRepositoryProvider =
    Provider<SignalBarRepository>((Ref ref) {
      return SignalBarRepository(ref.watch(fluxerDioProvider));
    });
