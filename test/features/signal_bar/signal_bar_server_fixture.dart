// A stand-in for the API's signal bar routes, behind the real
// SignalBarRepository, that records every request it is sent, the way
// test/core/permissions/channel_effective_permissions_fork_test.dart records
// them: the server signs a session out over a burst of requests
// (tyne-chat/tyne#114), so the signal bar's tests count them.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fluxer_app/features/signal_bar/data/signal_bar_repository.dart';

/// The account the tests act as.
const String kSignalTestMe = 'me';

const Map<String, Object?> _bar = <String, Object?>{
  'version': 3,
  'signals': <Object?>[
    <String, Object?>{'id': 'reading', 'emoji_name': '📖', 'animated': false},
    <String, Object?>{'id': 'done', 'emoji_name': '✅', 'animated': false},
  ],
};

/// A lit signal as the server sends it.
Map<String, Object?> signalEntryJson(
  String signalId,
  String userId, {
  String? personaId,
}) => <String, Object?>{
  'signal_id': signalId,
  'user': <String, Object?>{'id': userId, 'username': 'user$userId'},
  'persona_id': personaId,
  'subprofile': personaId == null
      ? null
      : <String, Object?>{'id': personaId, 'name': 'Persona $personaId'},
  'activated_at': 1,
};

/// Holds the bar, each chat's switch and lit signals, and answers the routes
/// the app calls as the API does, but sends no gateway events: a test hands
/// those to the notifier itself, or leaves them out to stand for a missed one.
class SignalBarTestServer implements HttpClientAdapter {
  /// Every request, as `METHOD /path`.
  final List<String> requests = <String>[];

  /// Lit signals per chat.
  final Map<String, List<Map<String, Object?>>> lit =
      <String, List<Map<String, Object?>>>{};

  /// Each chat's switch; a chat missing here is on.
  final Map<String, bool> enabled = <String, bool>{};

  /// Whether channel reads, or writes, answer 500.
  bool failReads = false;
  bool failWrites = false;

  /// The real repository, talking to this server.
  SignalBarRepository repository() => SignalBarRepository(
    Dio(BaseOptions(baseUrl: 'https://api.example.invalid'))
      ..httpClientAdapter = this,
  );

  /// The `GET /channels/<id>/signals` requests sent.
  List<String> get channelGets => <String>[
    for (final String request in requests)
      if (request.startsWith('GET /channels/')) request,
  ];

  /// The PUT and DELETE requests sent.
  List<String> get writes => <String>[
    for (final String request in requests)
      if (request.startsWith('PUT') || request.startsWith('DELETE')) request,
  ];

  /// The account's signal [signalId] in [channelId] goes off on the server,
  /// as a sweep or another of its sessions would.
  void dropMine(String channelId, String signalId) {
    lit[channelId]?.removeWhere(
      (Map<String, Object?> entry) =>
          entry['signal_id'] == signalId &&
          (entry['user']! as Map<String, Object?>)['id'] == kSignalTestMe,
    );
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final String method = options.method;
    final String path = options.path;
    requests.add('$method $path');
    final List<String> parts = path.split('/');
    if (method == 'GET' && path == '/instance/signal-bar') {
      return _json(_bar);
    }
    if (method == 'GET' && path == '/users/@me/signals') {
      return _json(<String, Object?>{
        'chats': <Object?>[],
        'restore_available': false,
      });
    }
    if (parts.length < 4 || parts[1] != 'channels') {
      return _json(<String, Object?>{}, status: 404);
    }
    final String channelId = parts[2];
    if (method == 'GET') {
      if (failReads) {
        return _json(<String, Object?>{}, status: 500);
      }
      final bool on = enabled[channelId] ?? true;
      return _json(<String, Object?>{
        'enabled': on,
        'bar_version': 3,
        'entries': on ? lit[channelId] ?? <Object?>[] : <Object?>[],
      });
    }
    if (failWrites) {
      return _json(<String, Object?>{}, status: 500);
    }
    final Map<String, Object?> body =
        (options.data as Map<String, dynamic>?) ?? const <String, Object?>{};
    if (method == 'PUT' && parts[3] == 'signal-bar') {
      final bool on = body['enabled']! as bool;
      enabled[channelId] = on;
      if (!on) {
        lit.remove(channelId);
      }
    } else if (method == 'PUT' && parts.length == 6) {
      dropMine(channelId, parts[4]);
      (lit[channelId] ??= <Map<String, Object?>>[]).add(
        signalEntryJson(
          parts[4],
          kSignalTestMe,
          personaId: body['persona_id'] as String?,
        ),
      );
    } else if (method == 'DELETE' && parts.length == 6) {
      dropMine(channelId, parts[4]);
    }
    return ResponseBody.fromString('', 204);
  }

  ResponseBody _json(Object? body, {int status = 200}) =>
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}
