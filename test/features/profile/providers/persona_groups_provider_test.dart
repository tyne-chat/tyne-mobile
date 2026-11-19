// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: requests for the account's persona groups (tyne-chat/tyne#829): one
// load, shared, whoever reads the groups and however often they rebuild; a
// failed load asked again only at the next READY, never per read; the event
// replacing the list without a request; one request per change and none for
// a change that changes nothing. Also the folds, kept per account on the
// device and never sent.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/profile/domain/persona_group.dart';
import 'package:fluxer_app/features/profile/providers/persona_group_folds_provider.dart';
import 'package:fluxer_app/features/profile/providers/persona_groups_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fork_support/wait_until.dart';

typedef _Request = ({String method, String path, Object? data});

class _Adapter implements HttpClientAdapter {
  int status = 200;

  /// Holds every answer until completed, when set.
  Completer<void>? gate;
  Object listBody = <Object?>[
    <String, Object?>{
      'id': 'g1',
      'name': 'Core',
      'persona_ids': <Object?>['w'],
    },
  ];
  final List<_Request> requests = <_Request>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add((
      method: options.method,
      path: options.path,
      data: options.data,
    ));
    await gate?.future;
    final Object body = status != 200
        ? <String, Object?>{'code': 'X', 'message': 'Refused here.'}
        : switch (options.method) {
            'POST' => <String, Object?>{
              'id': 'g9',
              'name': 'Visitors',
              'persona_ids': <Object?>['l'],
            },
            'DELETE' => '',
            _ => listBody,
          };
    return ResponseBody.fromString(
      body is String ? body : jsonEncode(body),
      status == 200 && options.method == 'DELETE' ? 204 : status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// What READY and the gateway handler call, from a [Ref].
final Provider<void Function()> _readyProvider = Provider<void Function()>(
  (Ref ref) =>
      () => reloadPersonaGroupsIfLoaded(ref),
);
final Provider<void Function(Object?)> _eventProvider =
    Provider<void Function(Object?)>(
      (Ref ref) =>
          (Object? data) => applyPersonaGroupsEvent(ref, data),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Adapter adapter;
  late ProviderContainer container;

  ProviderContainer makeContainer({String userId = 'u1'}) {
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
      ..httpClientAdapter = adapter;
    final ProviderContainer c = ProviderContainer(
      overrides: [
        fluxerDioProvider.overrideWithValue(dio),
        currentUserIdProvider.overrideWithValue(userId),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    adapter = _Adapter();
    container = makeContainer();
  });

  List<String> paths() => <String>[
    for (final _Request r in adapter.requests) '${r.method} ${r.path}',
  ];

  /// A container whose signed-in account can change, as the app's can.
  ProviderContainer switchableContainer() {
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
      ..httpClientAdapter = adapter;
    final ProviderContainer c = ProviderContainer(
      overrides: [fluxerDioProvider.overrideWithValue(dio)],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('accounts', () {
    test('signed out: nothing is asked', () async {
      final ProviderContainer c = switchableContainer();
      final ProviderSubscription<List<PersonaGroup>> sub = c.listen(
        personaGroupsProvider,
        (_, _) {},
      );
      addTearDown(sub.close);
      await Future<void>.delayed(Duration.zero);
      expect(adapter.requests, isEmpty);
      expect(c.read(personaGroupsProvider), isEmpty);
    });

    test('a change made for the previous account does not land on the next '
        'one, whichever way the account changed', () async {
      final ProviderContainer c = switchableContainer();
      c.read(currentUserIdProvider.notifier).set('u1');
      final ProviderSubscription<List<PersonaGroup>> sub = c.listen(
        personaGroupsProvider,
        (_, _) {},
      );
      addTearDown(sub.close);
      await waitUntil(
        () => c.read(personaGroupsProvider).isNotEmpty,
        "u1's groups to load",
      );

      // u1 makes a group; before the answer, the account becomes u2 (Add
      // Account, say, which does not reset the personas), whose list is empty.
      adapter.gate = Completer<void>();
      final Future<PersonaGroup?> made = c
          .read(personaGroupsProvider.notifier)
          .create('Visitors');
      await waitUntil(() => adapter.requests.length == 2, 'the create');
      c.read(currentUserIdProvider.notifier).set('u2');
      expect(c.read(personaGroupsProvider), isEmpty);
      await waitUntil(() => adapter.requests.length == 3, "u2's load");
      adapter.listBody = <Object?>[];
      adapter.gate!.complete();
      // The create's answer is handled once it returns; u2's load is the one
      // in flight, which reloadSilently shares.
      await made;
      await c.read(personaGroupsProvider.notifier).reloadSilently();
      expect(c.read(personaGroupsProvider), isEmpty);
    });
  });

  group('loading', () {
    test('nothing is asked until something reads the groups', () {
      container.read(_readyProvider)();
      container.read(_eventProvider)(<String, Object?>{'groups': <Object?>[]});
      expect(adapter.requests, isEmpty);
      expect(container.read(personaGroupsProvider.exists), isFalse);
    });

    test('one request, shared by every reader and every reload while it runs, '
        'and none for rebuilds', () async {
      adapter.gate = Completer<void>();
      final ProviderSubscription<List<PersonaGroup>> a = container.listen(
        personaGroupsProvider,
        (_, _) {},
      );
      addTearDown(a.close);
      final ProviderSubscription<List<PersonaGroup>> b = container.listen(
        personaGroupsProvider,
        (_, _) {},
      );
      addTearDown(b.close);
      final PersonaGroupsNotifier notifier = container.read(
        personaGroupsProvider.notifier,
      );
      final Future<void> load = notifier.reloadSilently();
      unawaited(notifier.reloadSilently());
      container.read(personaGroupsProvider);
      adapter.gate!.complete();
      await load;

      expect(paths(), <String>['GET /users/@me/personas/groups']);
      expect(container.read(personaGroupsProvider), const <PersonaGroup>[
        PersonaGroup(id: 'g1', name: 'Core', personaIds: <String>['w']),
      ]);

      for (int i = 0; i < 20; i++) {
        container.read(personaGroupsProvider);
      }
      expect(adapter.requests, hasLength(1));
    });

    test('a failed load leaves no groups and is not asked again by reading; '
        'READY asks once more', () async {
      adapter.status = 500;
      final ProviderSubscription<List<PersonaGroup>> sub = container.listen(
        personaGroupsProvider,
        (_, _) {},
      );
      addTearDown(sub.close);
      await container.read(personaGroupsProvider.notifier).reloadSilently();
      expect(container.read(personaGroupsProvider), isEmpty);

      for (int i = 0; i < 20; i++) {
        container.read(personaGroupsProvider);
      }
      expect(adapter.requests, hasLength(1));

      adapter.status = 200;
      container.read(_readyProvider)();
      // The load READY started, shared.
      await container.read(personaGroupsProvider.notifier).reloadSilently();
      expect(adapter.requests, hasLength(2));
      expect(container.read(personaGroupsProvider), hasLength(1));
    });

    test('the event replaces the list without a request, and a load still on '
        'its way does not undo it', () async {
      adapter.gate = Completer<void>();
      final ProviderSubscription<List<PersonaGroup>> sub = container.listen(
        personaGroupsProvider,
        (_, _) {},
      );
      addTearDown(sub.close);
      final Future<void> load = container
          .read(personaGroupsProvider.notifier)
          .reloadSilently();
      container.read(_eventProvider)(<String, Object?>{
        'groups': <Object?>[
          <String, Object?>{
            'id': 'g2',
            'name': 'Visitors',
            'persona_ids': <Object?>['l'],
          },
        ],
      });
      adapter.gate!.complete();
      await load;

      expect(adapter.requests, hasLength(1));
      expect(container.read(personaGroupsProvider), const <PersonaGroup>[
        PersonaGroup(id: 'g2', name: 'Visitors', personaIds: <String>['l']),
      ]);
    });
  });

  group('changes', () {
    late PersonaGroupsNotifier notifier;

    setUp(() async {
      final ProviderSubscription<List<PersonaGroup>> sub = container.listen(
        personaGroupsProvider,
        (_, _) {},
      );
      addTearDown(sub.close);
      notifier = container.read(personaGroupsProvider.notifier);
      await notifier.reloadSilently();
      adapter.requests.clear();
    });

    test('nothing to change sends nothing', () async {
      await notifier.changeMembers(const <PersonaGroupMemberChange>[]);
      await notifier.changeMembers(const <PersonaGroupMemberChange>[
        PersonaGroupMemberChange(groupId: 'g1'),
      ]);
      expect(adapter.requests, isEmpty);
    });

    test('any number of memberships go in one request', () async {
      await notifier.changeMembers(const <PersonaGroupMemberChange>[
        PersonaGroupMemberChange(groupId: 'g1', add: <String>['a', 'b']),
        PersonaGroupMemberChange(groupId: 'g2', remove: <String>['c']),
      ]);
      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.single.method, 'PATCH');
      expect(
        adapter.requests.single.path,
        '/users/@me/personas/groups/members',
      );
      expect(adapter.requests.single.data, <String, Object?>{
        'changes': <Object?>[
          <String, Object?>{
            'group_id': 'g1',
            'add': <String>['a', 'b'],
          },
          <String, Object?>{
            'group_id': 'g2',
            'remove': <String>['c'],
          },
        ],
      });
    });

    test('make, rename and delete: one request each, shown at once', () async {
      final PersonaGroup? made = await notifier.create(
        'Visitors',
        personaIds: <String>['l'],
      );
      expect(made?.id, 'g9');
      await notifier.rename('g1', 'Inner');
      await notifier.delete('g9');

      expect(paths(), <String>[
        'POST /users/@me/personas/groups',
        'PATCH /users/@me/personas/groups/g1',
        'DELETE /users/@me/personas/groups/g9',
      ]);
      expect(adapter.requests.first.data, <String, Object?>{
        'name': 'Visitors',
        'persona_ids': <String>['l'],
      });
      expect(container.read(personaGroupsProvider), const <PersonaGroup>[
        PersonaGroup(id: 'g1', name: 'Inner', personaIds: <String>['w']),
      ]);
    });

    test('a refused change throws and changes nothing here', () async {
      adapter.status = 500;
      await expectLater(notifier.rename('g1', 'Inner'), throwsA(anything));
      expect(container.read(personaGroupsProvider).single.name, 'Core');
      expect(adapter.requests, hasLength(1));
    });
  });

  group('folds', () {
    test('are kept on the device per account, and sent nowhere', () async {
      container.read(personaGroupFoldsProvider.notifier)
        ..toggle('g1')
        ..toggle(kUngroupedPersonaSectionKey);
      expect(container.read(personaGroupFoldsProvider), <String>{
        'g1',
        kUngroupedPersonaSectionKey,
      });
      container.read(personaGroupFoldsProvider.notifier).unfold('g1');

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String expected = jsonEncode(<String>[kUngroupedPersonaSectionKey]);
      await waitUntil(
        () =>
            prefs.getString('${PersonaGroupFoldsNotifier.prefKeyPrefix}u1') ==
            expected,
        'the folds to be stored',
      );

      final ProviderContainer again = makeContainer();
      final ProviderSubscription<Set<String>> restored = again.listen(
        personaGroupFoldsProvider,
        (_, _) {},
      );
      addTearDown(restored.close);
      await waitUntil(
        () => again.read(personaGroupFoldsProvider).isNotEmpty,
        'the folds to be restored',
      );
      expect(again.read(personaGroupFoldsProvider), <String>{
        kUngroupedPersonaSectionKey,
      });

      // Nothing is stored for another account, so its list stays empty.
      expect(
        prefs.getString('${PersonaGroupFoldsNotifier.prefKeyPrefix}u2'),
        isNull,
      );
      final ProviderContainer other = makeContainer(userId: 'u2');
      expect(other.read(personaGroupFoldsProvider), isEmpty);

      expect(adapter.requests, isEmpty);
    });
  });
}
