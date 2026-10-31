import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/guild_commands/presentation/guild_commands_settings.dart';
import 'package:fluxer_app/features/guild_commands/providers/guild_command_editing.dart';
import 'package:fluxer_app/features/guilds/providers/guild_permissions_provider.dart';
import 'package:fluxer_app/features/ui/input/fluxer_input.dart';
import 'package:fluxer_app/material_ui.dart';

import '../../helpers/open_test_database.dart';
import '../../helpers/pump_fluxer_app.dart';
import 'guild_commands_test_support.dart';

const String _guild = 'g';
const String _menu = 'the settings menu';

class _Permissions extends GuildPermissions {
  @override
  Map<String, int> build() {
    super.build();
    return <String, int>{
      _guild: Permission.createCommands.value | Permission.manageCommands.value,
    };
  }
}

/// Releases the tree before the test ends, as the database's stream timers
/// must not outlive it.
void sheetTest(String name, Future<void> Function(WidgetTester) body) {
  testWidgets(name, (WidgetTester tester) async {
    await body(tester);
    await releaseTestWidgetTree(tester);
  });
}

void main() {
  late RecordingAdapter adapter;

  setUp(() {
    adapter = RecordingAdapter((RequestOptions options) {
      if (options.method == 'GET') {
        return <Object?>[
          <String, Object?>{
            ...commandJson('7', _guild, 'hug'),
            'template': '{{ person }} hugs {{ input }}',
          },
        ];
      }
      return <String, Object?>{
        ...commandJson('7', _guild, 'hug'),
        'template': '{{ person }} hugs {{ input }}',
      };
    });
  });

  /// The Commands tab on a page of its own, over the settings menu.
  Future<void> openCommands(
    WidgetTester tester, {
    void Function(WidgetRef ref)? before,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      pumpFluxerApp(
        overrides: [
          fluxerDioProvider.overrideWithValue(
            Dio(BaseOptions(baseUrl: 'https://api.test'))
              ..httpClientAdapter = adapter,
          ),
          guildPermissionsProvider.overrideWith(_Permissions.new),
          fluxerDatabaseProvider.overrideWithValue(openTestDatabase()),
        ],
        child: Consumer(
          builder: (BuildContext context, WidgetRef ref, _) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () {
                    ref.read(currentUserIdProvider.notifier).set('1');
                    before?.call(ref);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const Scaffold(
                          body: GuildCommandsSettings(guildId: _guild),
                        ),
                      ),
                    );
                  },
                  child: const Text(_menu),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text(_menu));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.descendant(
    of: find.ancestor(of: find.text(label), matching: find.byType(FluxerInput)),
    matching: find.byType(EditableText),
  );

  Future<void> openHug(WidgetTester tester) async {
    await tester.tap(find.text('/hug'));
    await tester.pumpAndSettle();
    expect(find.text('Edit /hug'), findsOneWidget);
  }

  sheetTest('back from the editor returns to the command list', (
    WidgetTester tester,
  ) async {
    await openCommands(tester);
    await openHug(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Edit /hug'), findsNothing);
    expect(find.text('/hug'), findsOneWidget);
    expect(find.text(_menu), findsNothing);
  });

  sheetTest('unsaved changes keep the sheet open until reset', (
    WidgetTester tester,
  ) async {
    await openCommands(tester);
    await openHug(tester);
    await tester.enterText(field('Description'), 'A long hug');
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Edit /hug'), findsOneWidget);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Edit /hug'), findsNothing);
    expect(find.text('/hug'), findsOneWidget);
  });

  sheetTest('a form that cannot be saved can still be reset and closed', (
    WidgetTester tester,
  ) async {
    await openCommands(tester);
    await tester.tap(find.text('New command'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Description'), 'Hugs someone');
    await tester.pumpAndSettle();
    expect(find.text('Name'), findsOneWidget);
    expect(find.textContaining('Use lowercase letters'), findsNothing);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Use lowercase letters'), findsWidgets);
    expect(adapter.requests.map((RequestOptions o) => o.method), <String>[
      'GET',
    ]);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Use lowercase letters'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('/hug'), findsOneWidget);
    expect(find.text('Name'), findsNothing);
  });

  sheetTest('an empty message is not saved, and can be reset', (
    WidgetTester tester,
  ) async {
    await openCommands(tester);
    await openHug(tester);
    await tester.enterText(field('Message'), '');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(adapter.requests.map((RequestOptions o) => o.method), <String>[
      'GET',
    ]);
    expect(find.text('Edit /hug'), findsOneWidget);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Edit /hug'), findsNothing);
  });

  sheetTest('saving closes the sheet and lists the commands again', (
    WidgetTester tester,
  ) async {
    await openCommands(tester);
    await openHug(tester);
    await tester.enterText(field('Description'), 'A long hug');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Edit /hug'), findsNothing);
    expect(find.text('/hug'), findsOneWidget);
    expect(
      <String>[
        for (final RequestOptions options in adapter.requests) options.method,
      ],
      <String>['GET', 'PATCH', 'GET'],
    );
  });

  sheetTest("a chip's request opens the sheet on that command", (
    WidgetTester tester,
  ) async {
    await openCommands(
      tester,
      before: (WidgetRef ref) => ref
          .read(guildCommandEditRequestProvider.notifier)
          .request(_guild, '7'),
    );

    expect(find.text('Edit /hug'), findsOneWidget);
    expect(find.byType(FluxerInput), findsWidgets);
  });

  sheetTest("another community's request opens nothing here", (
    WidgetTester tester,
  ) async {
    await openCommands(
      tester,
      before: (WidgetRef ref) => ref
          .read(guildCommandEditRequestProvider.notifier)
          .request('other', '7'),
    );

    expect(find.text('Edit /hug'), findsNothing);
    expect(find.text('/hug'), findsOneWidget);
  });
}
