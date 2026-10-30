import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/guild_commands/providers/guild_commands_providers.dart';
import 'package:fluxer_dart/export.dart';

/// Records every request and answers from [respond], or fails with [failWith].
class RecordingAdapter implements HttpClientAdapter {
  RecordingAdapter(this.respond);

  final Object? Function(RequestOptions options) respond;
  final List<RequestOptions> requests = <RequestOptions>[];
  int? failWith;
  Map<String, Object?> failBody = const <String, Object?>{};

  /// Lets a test hold a request back.
  Future<void> Function(RequestOptions options)? beforeResponse;

  List<String> get paths => <String>[
    for (final RequestOptions options in requests) options.path,
  ];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    await beforeResponse?.call(options);
    final int? status = failWith;
    return ResponseBody.fromString(
      jsonEncode(status != null ? failBody : respond(options)),
      status ?? 200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> commandJson(String id, String guildId, String name) =>
    <String, Object?>{
      'id': id,
      'guild_id': guildId,
      'name': name,
      'description': 'Does $name',
      'kind': 'basic',
      'input_mode': 'optional',
      'input_type': 'text',
      'input_hint': null,
      'creator_id': '1',
      'created_at': '2026-10-30T00:00:00.000Z',
      'updated_at': '2026-10-30T00:00:00.000Z',
    };

/// The tests' clock, moved by hand.
class TestClock {
  DateTime now = DateTime.utc(2026, 10, 30);

  void advance(Duration by) => now = now.add(by);
}

const List<({String id, String name})> _defaultSidebar =
    <({String id, String name})>[
      (id: 'g1', name: 'Temple'),
      (id: 'g2', name: 'Garden'),
    ];

ProviderContainer commandsContainer({
  required RecordingAdapter adapter,
  required TestClock clock,
  List<({String id, String name})> Function()? sidebar,
  List<Override> overrides = const <Override>[],
}) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'https://tyne.test'))
    ..httpClientAdapter = adapter;
  return ProviderContainer(
    overrides: <Override>[
      fluxerClientProvider.overrideWithValue(
        FluxerClient(dio, baseUrl: 'https://tyne.test'),
      ),
      currentUserIdProvider.overrideWithValue('me'),
      guildCommandsSidebarProvider.overrideWith(
        (Ref ref) => sidebar?.call() ?? _defaultSidebar,
      ),
      guildCommandsClockProvider.overrideWithValue(() => clock.now),
      ...overrides,
    ],
  );
}
