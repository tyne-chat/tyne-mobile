// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: the persona editor's Groups field (tyne-chat/tyne#829): chips for the
// persona's groups, changes held until Save, then sent in one request after
// the persona's own; nothing sent when the groups did not change.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/domain/persona_group.dart';
import 'package:fluxer_app/features/profile/domain/public_persona.dart';
import 'package:fluxer_app/features/profile/presentation/sheets/edit_persona_sheet.dart';
import 'package:fluxer_app/features/profile/providers/persona_groups_provider.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:fluxer_app/features/ui/settings/fluxer_save_bar.dart';
import 'package:fluxer_app/features/ui/toast/toast_provider.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';

import '../../../../helpers/pump_fluxer_app.dart';
import '../../../../helpers/test_l10n.dart';

class _FakeUserSettings extends UserSettingsViewModel {
  @override
  UserSettingsViewState build() => const UserSettingsViewState(
    userId: '1',
    username: 'tester',
    displayName: 'Tester',
    discriminator: '0001',
    avatar: null,
    avatarColor: null,
    memberSince: null,
    status: 'online',
    messageDisplayCompact: false,
    developerMode: false,
    trustedDomains: <String>[],
  );
}

class _FakeMyPersonas extends MyPersonasNotifier {
  @override
  AsyncValue<List<Persona>> build() => const AsyncData(<Persona>[]);

  @override
  Future<void> reloadSilently() async {}
}

class _FakeDisplayTag extends SystemDisplayTagNotifier {
  @override
  SystemDisplayTag build() => const SystemDisplayTag();
}

class _FakeGroups extends PersonaGroupsNotifier {
  @override
  List<PersonaGroup> build() => const <PersonaGroup>[
    PersonaGroup(id: 'g1', name: 'Core', personaIds: <String>['p1']),
    PersonaGroup(id: 'g2', name: 'Visitors'),
  ];
}

class _Adapter implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];

  /// Answers the groups request with a 500.
  bool failGroups = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final Object body = options.path == '/users/@me/personas/p1'
        ? <String, Object?>{'id': 'p1', 'name': 'Lyra'}
        : <Object?>[];
    final bool fail =
        failGroups && options.path == '/users/@me/personas/groups/members';
    return ResponseBody.fromString(
      jsonEncode(fail ? <String, Object?>{'code': 'GENERAL_ERROR'} : body),
      fail ? 500 : 200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const PublicPersona _lyra = PublicPersona(id: 'p1', name: 'Lyra');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Adapter adapter;

  setUp(() => adapter = _Adapter());

  Future<void> openEditor(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
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
          userSettingsViewModelProvider.overrideWith(_FakeUserSettings.new),
          myPersonasProvider.overrideWith(_FakeMyPersonas.new),
          systemDisplayTagProvider.overrideWith(_FakeDisplayTag.new),
          personaGroupsProvider.overrideWith(_FakeGroups.new),
        ],
        child: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const ValueKey<String>('open'),
                onPressed: () => EditPersonaSheet.show(context, persona: _lyra),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey<String>('open')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('persona-group-add')),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets("shows the persona's groups; with only groups changed, Save "
      'sends one request for them and not the persona', (
    WidgetTester tester,
  ) async {
    await openEditor(tester);
    expect(
      find.byKey(const ValueKey<String>('persona-group-chip-g1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('persona-group-chip-g2')),
      findsNothing,
    );

    await tester.tap(
      find.bySemanticsLabel(testL10n.fork.personaGroupRemoveFrom('Core')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('persona-group-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Visitors').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('persona-group-chip-g1')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('persona-group-chip-g2')),
      findsOneWidget,
    );
    // Nothing is sent before Save.
    expect(adapter.requests, isEmpty);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      <String>[
        for (final RequestOptions r in adapter.requests)
          '${r.method} ${r.path}',
      ],
      <String>['PATCH /users/@me/personas/groups/members'],
    );
    expect(adapter.requests.last.data, <String, Object?>{
      'changes': <Object?>[
        <String, Object?>{
          'group_id': 'g1',
          'remove': <String>['p1'],
        },
        <String, Object?>{
          'group_id': 'g2',
          'add': <String>['p1'],
        },
      ],
    });
  });

  testWidgets('taking a group out and putting it back changes nothing', (
    WidgetTester tester,
  ) async {
    await openEditor(tester);
    await tester.tap(
      find.bySemanticsLabel(testL10n.fork.personaGroupRemoveFrom('Core')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('persona-group-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Core').last);
    await tester.pumpAndSettle();

    // No unsaved change: the save bar stays down.
    expect(
      tester.widget<FluxerSaveBar>(find.byType(FluxerSaveBar)).visible,
      isFalse,
    );
    expect(adapter.requests, isEmpty);
  });

  testWidgets(
    'a persona field and a group: the persona first, then the groups',
    (WidgetTester tester) async {
      await openEditor(tester);
      // The editor opens scrolled to the groups; since the mention setting
      // (tyne-chat/tyne#652) the name field is then out of the built list.
      final Finder name = find.widgetWithText(TextField, 'Lyra');
      await tester.scrollUntilVisible(
        name,
        -300,
        scrollable: find
            .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.enterText(name.first, 'Lyra B');
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('persona-group-add')),
      );
      await tester.tap(find.byKey(const ValueKey<String>('persona-group-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Visitors').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        <String>[
          for (final RequestOptions r in adapter.requests)
            '${r.method} ${r.path}',
        ],
        <String>[
          'PATCH /users/@me/personas/p1',
          'PATCH /users/@me/personas/groups/members',
        ],
      );
    },
  );

  testWidgets('with only groups changed, a failed save keeps the editor open '
      'and says nothing was updated', (WidgetTester tester) async {
    adapter.failGroups = true;
    await openEditor(tester);
    await tester.tap(find.byKey(const ValueKey<String>('persona-group-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Visitors').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(adapter.requests, hasLength(1));
    final List<String> toasts = <String>[
      for (final ToastEntry e in ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).first),
      ).read(toastProvider))
        e.toast.message,
    ];
    expect(toasts, <String>[testL10n.fork.personaGroupFailed]);
    // Still open, with the change unsaved, so Save can try again.
    expect(
      find.byKey(const ValueKey<String>('persona-group-chip-g2')),
      findsOneWidget,
    );
    expect(
      tester.widget<FluxerSaveBar>(find.byType(FluxerSaveBar)).visible,
      isTrue,
    );
  });
}
