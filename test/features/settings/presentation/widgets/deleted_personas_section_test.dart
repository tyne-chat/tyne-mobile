// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: the Personas settings page's Deleted personas section
// (tyne-chat/tyne#610): nothing is asked while it shows, one request on Show,
// Retry after a failure, one request per Restore, and a long list that
// scrolls inside its own box. The request rules themselves are in
// `test/features/profile/providers/deleted_personas_test.dart`.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/deleted_personas_section.dart';
import 'package:fluxer_app/material_ui.dart';

import '../../../../helpers/pump_fluxer_app.dart';

class _Adapter implements HttpClientAdapter {
  int listStatus = 200;
  int count = 2;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final bool restore = options.method == 'POST';
    final int status = restore ? 200 : listStatus;
    final Object body = status != 200
        ? <String, Object?>{'code': 'X', 'message': 'No.'}
        : restore
        ? <String, Object?>{
            'persona': <String, Object?>{'id': 'p0', 'name': 'Persona 0'},
            'dropped_tags': <Object?>[],
            'dropped_signature_emojis': <Object?>[],
          }
        : <Object?>[
            for (int i = 0; i < count; i++)
              <String, Object?>{
                'id': 'p$i',
                'name': 'Persona $i',
                'deleted_at': '2026-11-11T08:00:00.000Z',
                'use_count': 214,
              },
          ];
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeMyPersonas extends MyPersonasNotifier {
  @override
  AsyncValue<List<Persona>> build() => const AsyncValue.data(<Persona>[]);

  @override
  Future<void> reloadSilently() async {}
}

void main() {
  late _Adapter adapter;

  Future<void> pumpSection(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://test.fluxer.invalid'))
      ..httpClientAdapter = adapter;
    await tester.pumpWidget(
      pumpFluxerApp(
        overrides: [
          fluxerDioProvider.overrideWithValue(dio),
          myPersonasProvider.overrideWith(_FakeMyPersonas.new),
        ],
        child: const Scaffold(
          body: SingleChildScrollView(
            child: DeletedPersonasSection(userId: '1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(ValueKey<String>(key)));
    await tester.pumpAndSettle();
  }

  setUp(() => adapter = _Adapter());

  testWidgets('asks for nothing until Show, then lists them', (
    WidgetTester tester,
  ) async {
    await pumpSection(tester);
    expect(adapter.requests, isEmpty);

    await tapKey(tester, 'deleted-personas-show');

    expect(adapter.requests, hasLength(1));
    expect(adapter.requests.single.path, '/users/@me/personas/deleted');
    expect(find.text('Persona 0'), findsOneWidget);
    expect(find.text('Persona 1'), findsOneWidget);
    expect(find.textContaining('Used 214 times'), findsNWidgets(2));
  });

  testWidgets('a failed load shows Retry, which asks once more', (
    WidgetTester tester,
  ) async {
    adapter.listStatus = 500;
    await pumpSection(tester);
    await tapKey(tester, 'deleted-personas-show');

    expect(adapter.requests, hasLength(1));
    expect(
      find.byKey(const ValueKey<String>('deleted-personas-retry')),
      findsOneWidget,
    );

    adapter.listStatus = 200;
    await tapKey(tester, 'deleted-personas-retry');

    expect(adapter.requests, hasLength(2));
    expect(find.text('Persona 0'), findsOneWidget);
  });

  testWidgets('Restore sends one request and takes the row away', (
    WidgetTester tester,
  ) async {
    await pumpSection(tester);
    await tapKey(tester, 'deleted-personas-show');

    await tapKey(tester, 'deleted-persona-restore-p0');

    expect(adapter.requests, hasLength(2));
    expect(adapter.requests.last.method, 'POST');
    expect(
      adapter.requests.last.path,
      '/users/@me/personas/deleted/p0/restore',
    );
    expect(find.text('Persona 0'), findsNothing);
    expect(find.text('Persona 1'), findsOneWidget);
  });

  testWidgets('a long list scrolls inside its own box', (
    WidgetTester tester,
  ) async {
    adapter.count = 40;
    await pumpSection(tester);
    await tapKey(tester, 'deleted-personas-show');

    final Size box = tester.getSize(
      find.byKey(const ValueKey<String>('deleted-personas-list')),
    );
    // The border adds a pixel on each side.
    expect(box.height, lessThanOrEqualTo(kDeletedPersonasListMaxHeight + 2));
    expect(find.text('Persona 39'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Persona 39'),
      200,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey<String>('deleted-personas-list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Persona 39'), findsOneWidget);
  });
}
