// Fork: tyne-chat/tyne#882. A send that moves the persona selection must not
// wait for the selection's save: a second tap on Send while it is on its way
// would send the same text again.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_dart/fluxer_client.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../helpers/composer_channel_textarea_harness.dart';
import '../../../../../helpers/open_test_database.dart';

const String _channel = kComposerHarnessChannelA;

/// Holds every selection's save until the test lets them through, and fails
/// them when asked to. Every other request gets an empty object.
class _Api implements HttpClientAdapter {
  final List<String> calls = <String>[];
  final Completer<void> _putsAnswered = Completer<void>();
  bool failPut = false;

  int get putCount => calls.where((String c) => c.startsWith('PUT ')).length;

  int get channelStateReads => calls
      .where((String c) => c == 'GET /users/@me/personas/channel-states')
      .length;

  /// Lets the saves through, also those that have not reached the server yet.
  void answerPuts() {
    if (!_putsAnswered.isCompleted) {
      _putsAnswered.complete();
    }
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final String path = options.uri.path;
    final Object? data = options.data;
    calls.add(
      '${options.method} $path${data == null ? '' : ' ${data is String ? data : jsonEncode(data)}'}',
    );
    ResponseBody json(Object? body, [int status = 200]) =>
        ResponseBody.fromString(
          jsonEncode(body),
          status,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
    if (path.contains('/personas/channel-states/') && options.method == 'PUT') {
      await _putsAnswered.future;
      if (failPut) {
        return json(<String, Object?>{'code': 'NOPE', 'message': 'no'}, 500);
      }
      return json(<String, Object?>{
        'channel_id': path.split('/').last,
        'persona_id': null,
      });
    }
    if (path.endsWith('/personas/channel-states')) {
      return json(<String, Object?>{'states': <Object?>[]});
    }
    return json(<String, Object?>{});
  }

  @override
  void close({bool force = false}) {}
}

class _Personas extends MyPersonasNotifier {
  @override
  AsyncValue<List<Persona>> build() => const AsyncValue.data(<Persona>[
    Persona(
      id: 'ash',
      name: 'Ash',
      personaTags: <PersonaTag>[PersonaTag(prefix: 'a:')],
    ),
    Persona(
      id: 'birch',
      name: 'Birch',
      personaTags: <PersonaTag>[PersonaTag(prefix: 'b:')],
    ),
  ]);
}

/// Personas kept per channel, with the channels' selections already loaded.
class _Active extends ActivePersonaNotifier {
  _Active(this._initial);
  final ActivePersonaState _initial;

  @override
  ActivePersonaState build() => _initial;

  @override
  bool get channelStatesLoaded => true;
}

ActivePersonaState _perChannel(PersonaMode mode, {String? selected}) =>
    ActivePersonaState(
      mode: mode,
      scope: PersonaScope.channel,
      channelPersonaIds: selected == null
          ? const <String, String>{}
          : <String, String>{_channel: selected},
    );

Future<(ProviderContainer, _Api)> _pump(
  WidgetTester tester,
  ActivePersonaState initial,
) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final _Api api = _Api();
  final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.fluxer.invalid'))
    ..httpClientAdapter = api;
  final ProviderContainer container = await pumpComposerChannelTextareaHarness(
    tester,
    extraOverrides: <Override>[
      fluxerDioProvider.overrideWithValue(dio),
      fluxerClientProvider.overrideWithValue(
        FluxerClient(dio, baseUrl: 'https://test.fluxer.invalid'),
      ),
      myPersonasProvider.overrideWith(_Personas.new),
      activePersonaProvider.overrideWith(() => _Active(initial)),
    ],
  );
  return (container, api);
}

/// Types [text], taps Send twice in quick succession while the selection's
/// save is still on its way, then lets the save answer.
Future<void> _doubleTap(WidgetTester tester, _Api api, String text) async {
  await tester.enterText(channelComposerField(), text);
  await tester.pump();
  final Finder send = find.byKey(
    const ValueKey<String>('mobile-composer-send'),
  );
  await tester.tap(send);
  await tester.pump();
  // Once the composer is cleared the send button gives way, and the second
  // tap has nothing to send. Before the fix it was still there.
  if (send.evaluate().isNotEmpty) {
    await tester.tap(send);
    await tester.pump();
  }
  api.answerPuts();
  for (int i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

Future<void> _finish(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 400));
  await releaseTestWidgetTree(tester);
}

String? _selected(ProviderContainer container) =>
    container.read(activePersonaProvider).latchedIdFor(_channel);

void main() {
  testWidgets(
    'Last Used: a tag that switches from the account sends once and saves once',
    (WidgetTester tester) async {
      final (ProviderContainer container, _Api api) = await _pump(
        tester,
        _perChannel(PersonaMode.last),
      );

      await _doubleTap(tester, api, 'a:hello');

      expect(readMutableChatViewModel(container).sentTexts, <String?>['hello']);
      expect(api.calls.where((String c) => c.startsWith('PUT ')), <String>[
        'PUT /users/@me/personas/channel-states/$_channel {"persona_id":"ash"}',
      ]);
      expect(_selected(container), 'ash');
      await _finish(tester);
    },
  );

  testWidgets(
    'Last Used: a tag that switches from another persona sends once',
    (WidgetTester tester) async {
      final (ProviderContainer container, _Api api) = await _pump(
        tester,
        _perChannel(PersonaMode.last, selected: 'birch'),
      );

      await _doubleTap(tester, api, 'a:hello');

      expect(readMutableChatViewModel(container).sentTexts, <String?>['hello']);
      expect(api.putCount, 1);
      expect(_selected(container), 'ash');
      await _finish(tester);
    },
  );

  testWidgets(r'Last Used: "\" before the text sends once, as the account', (
    WidgetTester tester,
  ) async {
    final (ProviderContainer container, _Api api) = await _pump(
      tester,
      _perChannel(PersonaMode.last, selected: 'birch'),
    );

    await _doubleTap(tester, api, r'\hello');

    expect(readMutableChatViewModel(container).sentTexts, <String?>['hello']);
    expect(api.putCount, 1);
    expect(_selected(container), isNull);
    await _finish(tester);
  });

  testWidgets(r'Manual: "\\" before the text sends once and deselects', (
    WidgetTester tester,
  ) async {
    final (ProviderContainer container, _Api api) = await _pump(
      tester,
      _perChannel(PersonaMode.manual, selected: 'birch'),
    );

    await _doubleTap(tester, api, r'\\hello');

    expect(readMutableChatViewModel(container).sentTexts, <String?>['hello']);
    expect(api.putCount, 1);
    expect(_selected(container), isNull);
    await _finish(tester);
  });

  testWidgets(r'"\\" alone deselects and sends nothing', (
    WidgetTester tester,
  ) async {
    final (ProviderContainer container, _Api api) = await _pump(
      tester,
      _perChannel(PersonaMode.manual, selected: 'birch'),
    );

    await _doubleTap(tester, api, r'\\');

    expect(readMutableChatViewModel(container).sentTexts, isEmpty);
    expect(api.putCount, 1);
    expect(_selected(container), isNull);
    await _finish(tester);
  });

  testWidgets(
    'a failed save still sends once and reads the selections back once',
    (WidgetTester tester) async {
      final (ProviderContainer container, _Api api) = await _pump(
        tester,
        _perChannel(PersonaMode.last),
      );
      api.failPut = true;

      await _doubleTap(tester, api, 'a:hello');

      expect(readMutableChatViewModel(container).sentTexts, <String?>['hello']);
      expect(api.putCount, 1);
      expect(api.channelStateReads, 1);
      await _finish(tester);
    },
  );
}
