// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: persona groups on the Personas settings page (tyne-chat/tyne#829):
// sections that fold and stay folded, search across folded groups, a new
// group, a group's menu, and the select mode's Groups sheet, which sends one
// request for all its changes.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/domain/persona_group.dart';
import 'package:fluxer_app/features/profile/domain/persona_settings.dart';
import 'package:fluxer_app/features/profile/providers/persona_group_folds_provider.dart';
import 'package:fluxer_app/features/profile/providers/persona_groups_provider.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/user_persona_settings.dart';
import 'package:fluxer_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:fluxer_app/features/shell/providers/user/current_user_private_provider.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_dart/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/pump_fluxer_app.dart';
import '../../../../helpers/test_account_user_id.dart';
import '../../../../helpers/test_l10n.dart';

class _Adapter implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(<String, Object?>{}),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeUserSettings extends UserSettingsViewModel {
  @override
  UserSettingsViewState build() => const UserSettingsViewState(
    userId: '1',
    username: 'tester',
    displayName: 'Root User',
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

class _FixedCurrentUserPrivate extends CurrentUserPrivateRead {
  @override
  UserPrivateResponse? build(String accountUserId) => null;
}

class _FakeMyPersonas extends MyPersonasNotifier {
  _FakeMyPersonas(this._personas);

  final List<Persona> _personas;

  @override
  AsyncValue<List<Persona>> build() => AsyncData(_personas);

  @override
  Future<void> reloadSilently() async {}
}

class _FakePersonaSettings extends PersonaSettingsNotifier {
  @override
  AsyncValue<PersonaSettings> build() => const AsyncData(PersonaSettings());

  @override
  Future<void> reloadSilently() async {}
}

class _FakeDisplayTag extends SystemDisplayTagNotifier {
  @override
  SystemDisplayTag build() => const SystemDisplayTag();
}

/// The groups as given, with no load; changes go through the real requests.
class _FakeGroups extends PersonaGroupsNotifier {
  _FakeGroups(this._groups);

  final List<PersonaGroup> _groups;

  @override
  List<PersonaGroup> build() => _groups;
}

const Persona _wren = Persona(id: 'w', name: 'Wren', visibility: 'public');
const Persona _marlowe = Persona(
  id: 'm',
  name: 'Marlowe',
  visibility: 'public',
);
const Persona _lyra = Persona(id: 'l', name: 'Lyra');
const Persona _sable = Persona(id: 's', name: 'Sable', visibility: 'public');

const PersonaGroup _core = PersonaGroup(
  id: 'g1',
  name: 'Core',
  personaIds: <String>['w', 'm'],
);
const PersonaGroup _visitors = PersonaGroup(
  id: 'g2',
  name: 'Visitors',
  personaIds: <String>['l', 'm', 'deleted'],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Adapter adapter;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    adapter = _Adapter();
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    List<PersonaGroup> groups = const <PersonaGroup>[_core, _visitors],
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
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
          currentUserPrivateReadProvider(
            kTestAccountUserId,
          ).overrideWith(_FixedCurrentUserPrivate.new),
          myPersonasProvider.overrideWith(
            () => _FakeMyPersonas(<Persona>[_wren, _marlowe, _lyra, _sable]),
          ),
          personaSettingsProvider.overrideWith(_FakePersonaSettings.new),
          systemDisplayTagProvider.overrideWith(_FakeDisplayTag.new),
          personaGroupsProvider.overrideWith(() => _FakeGroups(groups)),
        ],
        child: const Scaffold(body: UserPersonaSettings()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder section(String key) =>
      find.byKey(ValueKey<String>('persona-group-section-$key'));

  Finder nameIn(String key, String name) =>
      find.descendant(of: section(key), matching: find.text(name));

  testWidgets('without groups the list stays flat', (
    WidgetTester tester,
  ) async {
    await pumpPage(tester, groups: const <PersonaGroup>[]);
    expect(
      find.byKey(const ValueKey<String>('persona-group-section-g1')),
      findsNothing,
    );
    expect(find.text(testL10n.fork.personaGroupNone), findsNothing);
    expect(find.text('Lyra'), findsOneWidget);
  });

  testWidgets('a section per group, a persona in two groups in both, then '
      '"Not in a group"; a fold hides its cards and stays', (
    WidgetTester tester,
  ) async {
    await pumpPage(tester);

    expect(nameIn('g1', 'Marlowe'), findsOneWidget);
    expect(nameIn('g1', 'Wren'), findsOneWidget);
    expect(nameIn('g2', 'Marlowe'), findsOneWidget);
    expect(nameIn('g2', 'Lyra'), findsOneWidget);
    expect(nameIn('none', 'Sable'), findsOneWidget);
    expect(
      tester.getTopLeft(section('g1')).dy,
      lessThan(tester.getTopLeft(section('none')).dy),
    );

    await tester.tap(nameIn('g2', 'Visitors'));
    await tester.pumpAndSettle();
    expect(nameIn('g2', 'Lyra'), findsNothing);
    expect(nameIn('g2', 'Visitors'), findsOneWidget);
    expect(nameIn('g1', 'Marlowe'), findsOneWidget);

    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(UserPersonaSettings)),
    );
    expect(container.read(personaGroupFoldsProvider), <String>{'g2'});

    // A search shows its matches in one list, folded groups included.
    await tester.enterText(find.byType(TextField).last, 'lyr');
    await tester.pumpAndSettle();
    expect(section('g2'), findsNothing);
    expect(find.text('Lyra'), findsOneWidget);

    expect(adapter.requests, isEmpty);
  });

  testWidgets('a chip hides the groups it leaves empty', (
    WidgetTester tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('persona-filter-unlisted')),
    );
    await tester.pumpAndSettle();
    expect(section('g1'), findsNothing);
    expect(nameIn('g2', 'Lyra'), findsOneWidget);
    expect(section('none'), findsNothing);
  });

  testWidgets('New group asks for a name and sends one request', (
    WidgetTester tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.byKey(const ValueKey<String>('persona-group-new')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey<String>('persona-group-name-input')),
        matching: find.byType(TextField),
      ),
      '  Travellers ',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('persona-group-name-confirm')),
    );
    await tester.pumpAndSettle();

    expect(adapter.requests, hasLength(1));
    expect(adapter.requests.single.method, 'POST');
    expect(adapter.requests.single.path, '/users/@me/personas/groups');
    expect(adapter.requests.single.data, <String, Object?>{
      'name': 'Travellers',
    });
  });

  testWidgets('"Select the personas in it" selects the live ones and '
      'unfolds the group', (WidgetTester tester) async {
    await pumpPage(tester);
    await tester.tap(nameIn('g2', 'Visitors'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.bySemanticsLabel(testL10n.fork.personaGroupOptions('Visitors')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(testL10n.fork.personaGroupSelectMembers));
    await tester.pumpAndSettle();

    // Lyra and Marlowe; the deleted persona is not counted.
    expect(
      find.text(testL10n.fork.personaBulkSelectedCount(2)),
      findsOneWidget,
    );
    expect(nameIn('g2', 'Lyra'), findsOneWidget);
    expect(adapter.requests, isEmpty);
  });

  testWidgets('the Groups sheet sends every change in one request, then '
      'select mode ends', (WidgetTester tester) async {
    await pumpPage(tester);
    await tester.longPress(nameIn('none', 'Sable'));
    await tester.pumpAndSettle();
    await tester.tap(nameIn('g1', 'Wren'));
    await tester.pumpAndSettle();
    expect(
      find.text(testL10n.fork.personaBulkSelectedCount(2)),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('persona-bulk-groups')));
    await tester.pumpAndSettle();
    // The sheet is open; its title is "Groups" (the count is in the bar).
    expect(
      find.byKey(const ValueKey<String>('persona-groups-sheet-done')),
      findsOneWidget,
    );
    // Core holds Wren but not Sable: its dash reads as "mixed" to a screen
    // reader, not as "not checked".
    final SemanticsHandle semantics = tester.ensureSemantics();
    expect(
      tester.getSemantics(
        find.byKey(const ValueKey<String>('persona-groups-sheet-g1')),
      ),
      isSemantics(hasCheckedState: true, isCheckStateMixed: true),
    );
    semantics.dispose();

    // Core has Wren, not Sable: a tap puts both in. Visitors has neither:
    // tapped twice it is back as it was and sends nothing.
    await tester.tap(
      find.byKey(const ValueKey<String>('persona-groups-sheet-g1')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('persona-groups-sheet-g2')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('persona-groups-sheet-g2')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('persona-groups-sheet-done')),
    );
    await tester.pumpAndSettle();

    expect(adapter.requests, hasLength(1));
    expect(adapter.requests.single.method, 'PATCH');
    expect(adapter.requests.single.path, '/users/@me/personas/groups/members');
    expect(adapter.requests.single.data, <String, Object?>{
      'changes': <Object?>[
        <String, Object?>{
          'group_id': 'g1',
          'add': <String>['s'],
        },
      ],
    });
    expect(
      find.byKey(const ValueKey<String>('persona-bulk-actions')),
      findsNothing,
    );
  });
}
