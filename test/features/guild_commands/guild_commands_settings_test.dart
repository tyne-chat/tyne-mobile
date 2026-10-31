import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/composer/composer_autocomplete_field.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/messages/message_markdown.dart';
import 'package:fluxer_app/features/chat/services/composer_autocomplete_trigger.dart';
import 'package:fluxer_app/features/chat/services/composer_mention_controller.dart';
import 'package:fluxer_app/features/guild_commands/presentation/guild_commands_settings.dart';
import 'package:fluxer_app/features/guild_commands/providers/guild_command_editing.dart';
import 'package:fluxer_app/features/guilds/providers/guild_permissions_provider.dart';
import 'package:fluxer_app/features/ui/input/fluxer_input.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_dart/export.dart';

import '../../helpers/open_test_database.dart';
import '../../helpers/pump_fluxer_app.dart';
import 'guild_commands_test_support.dart';

const String _guild = 'g';
const String _menu = 'the settings menu';
const String _plain = '{{ person }} hugs {{ input }}';
const String _script = '{% if target %}{{ target }}{% endif %}';

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
  late String template;
  late Map<String, Object?> previewAnswer;

  Map<String, Object?> hug() => <String, Object?>{
    ...commandJson('7', _guild, 'hug'),
    'template': template,
    'kind': template == _plain ? 'basic' : 'script',
  };

  setUp(() {
    template = _plain;
    previewAnswer = <String, Object?>{'content': 'filled in', 'issue': null};
    adapter = RecordingAdapter((RequestOptions options) {
      if (options.path.endsWith('/preview')) {
        return previewAnswer;
      }
      return options.method == 'GET' ? <Object?>[hug()] : hug();
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

  Future<void> openScript(WidgetTester tester) async {
    template = _script;
    await openCommands(tester);
    await tester.tap(find.text('/hug'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  /// The server's answer, in the preview. It is rich text, which find.text
  /// does not see.
  Finder filledIn() => find.byWidgetPredicate(
    (Widget widget) => widget is MessageMarkdown && widget.data == 'filled in',
  );

  List<RequestOptions> previews() => <RequestOptions>[
    for (final RequestOptions options in adapter.requests)
      if (options.path.endsWith('/preview')) options,
  ];

  sheetTest('a script opens in the script editor, filled in by the server', (
    WidgetTester tester,
  ) async {
    await openScript(tester);

    expect(find.text('Script'), findsOneWidget);
    expect(find.text('Script reference'), findsOneWidget);
    expect(filledIn(), findsOneWidget);
    expect(find.text('Use the basic editor'), findsNothing);
    expect(previews(), hasLength(1));
    expect(previews().single.data, containsPair('template', _script));
  });

  sheetTest('typing in a script sends one preview for the burst', (
    WidgetTester tester,
  ) async {
    await openScript(tester);

    for (final String text in <String>['{{ a', '{{ ab', '{{ abc }}']) {
      await tester.enterText(field('Script'), text);
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(previews(), hasLength(2));
    expect(previews().last.data, containsPair('template', '{{ abc }}'));
  });

  sheetTest('a basic command can move to the script editor and back', (
    WidgetTester tester,
  ) async {
    await openCommands(tester);
    await openHug(tester);
    expect(find.text('Insert:'), findsOneWidget);

    await tester.ensureVisible(find.text('Use the script editor'));
    await tester.tap(find.text('Use the script editor'));
    await tester.pumpAndSettle();
    expect(find.text('Insert:'), findsNothing);
    expect(previews(), isEmpty);

    await tester.tap(find.text('Use the basic editor'));
    await tester.pumpAndSettle();
    expect(find.text('Insert:'), findsOneWidget);
  });

  sheetTest('a script cannot go back to the basic editor', (
    WidgetTester tester,
  ) async {
    await openCommands(tester);
    await openHug(tester);
    await tester.ensureVisible(find.text('Use the script editor'));
    await tester.tap(find.text('Use the script editor'));
    await tester.pumpAndSettle();

    await tester.enterText(field('Script'), '{% if target %}x{% endif %}');
    await tester.pumpAndSettle();

    expect(find.text('Use the basic editor'), findsNothing);
  });

  sheetTest('a problem in a script shows with its position', (
    WidgetTester tester,
  ) async {
    previewAnswer = <String, Object?>{
      'content': null,
      'issue': <String, Object?>{
        'code': 'unknown_tag',
        'line': 2,
        'column': 3,
        'name': 'for',
      },
    };
    await openScript(tester);

    expect(
      find.text("Line 2, column 3: There's no tag called for."),
      findsOneWidget,
    );
    expect(filledIn(), findsNothing);
  });

  sheetTest('a script that prints nothing says so', (
    WidgetTester tester,
  ) async {
    previewAnswer = <String, Object?>{'content': '', 'issue': null};
    await openScript(tester);

    expect(
      find.text('This would post nothing, so the command would fail.'),
      findsOneWidget,
    );
  });

  sheetTest('Run again appears for random scripts and asks at once', (
    WidgetTester tester,
  ) async {
    await openScript(tester);
    expect(find.text('Run again'), findsNothing);

    await tester.enterText(
      field('Script'),
      '{% random %}a{% or %}b{% endrandom %}',
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    final int before = previews().length;

    await tester.ensureVisible(find.text('Run again'));
    await tester.tap(find.text('Run again'));
    await tester.pumpAndSettle();

    expect(previews(), hasLength(before + 1));
  });

  sheetTest('a changed script is saved', (WidgetTester tester) async {
    await openScript(tester);
    await tester.enterText(field('Script'), '{{ person.name }}!');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final RequestOptions saved = adapter.requests.firstWhere(
      (RequestOptions o) => o.method == 'PATCH',
    );
    expect(saved.data, containsPair('template', '{{ person.name }}!'));
    expect(find.text('Edit /hug'), findsNothing);
  });

  sheetTest('Reset returns a changed script to the script editor', (
    WidgetTester tester,
  ) async {
    await openScript(tester);
    await tester.enterText(field('Script'), 'plain text');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Use the basic editor'));
    await tester.tap(find.text('Use the basic editor'));
    await tester.pumpAndSettle();
    expect(find.text('Insert:'), findsOneWidget);

    await tester.ensureVisible(find.text('Reset'));
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(find.text('Insert:'), findsNothing);
    expect(find.text('Script reference'), findsOneWidget);
  });

  sheetTest('a counter is added and saved with the command', (
    WidgetTester tester,
  ) async {
    await openCommands(tester);
    await openHug(tester);
    await tester.ensureVisible(find.text('Add counter'));
    await tester.tap(find.text('Add counter'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Name').last, 'hugs');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Person mentioned'));
    await tester.tap(find.text('Person mentioned'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final RequestOptions saved = adapter.requests.firstWhere(
      (RequestOptions o) => o.method == 'PATCH',
    );
    final GuildCommandCounterInputSchema counter =
        ((saved.data as Map<String, Object?>)['counters']! as List<Object?>)
                .single!
            as GuildCommandCounterInputSchema;
    expect(counter.name, 'hugs');
    expect(counter.per, <GuildCommandCounterPart>[
      GuildCommandCounterPart.target,
    ]);
  });

  sheetTest('a bad counter name is not saved, and Reset clears it', (
    WidgetTester tester,
  ) async {
    await openCommands(tester);
    await openHug(tester);
    await tester.ensureVisible(find.text('Add counter'));
    await tester.tap(find.text('Add counter'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Name').last, 'person');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      adapter.requests.where((RequestOptions o) => o.method == 'PATCH'),
      isEmpty,
    );

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(find.text('Remove counter'), findsNothing);
  });

  sheetTest('a mention picked in the sample reaches the preview by id', (
    WidgetTester tester,
  ) async {
    await openScript(tester);
    final FluxerInput sample = tester.widget<FluxerInput>(
      find.ancestor(
        of: find.text('Sample input'),
        matching: find.byType(FluxerInput),
      ),
    );

    (sample.controller! as ComposerMentionController)
        .insertUserMentionPlaceholder(
          matchStart: 0,
          matchEnd: 0,
          userId: '222',
          personaId: '9',
          displayName: 'Yami',
        );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // The message box leaves a space after a mention, ready for the next word.
    expect(previews().last.data, containsPair('input', '<@222:9> '));
  });

  sheetTest('the sample suggests people and emoji, nothing else', (
    WidgetTester tester,
  ) async {
    await openScript(tester);

    final ComposerAutocompleteField field = tester
        .widget<ComposerAutocompleteField>(
          find.ancestor(
            of: find.text('Sample input'),
            matching: find.byType(ComposerAutocompleteField),
          ),
        );

    expect(field.allowedTriggers, <ComposerAutocompleteTriggerKind>{
      ComposerAutocompleteTriggerKind.mention,
      ComposerAutocompleteTriggerKind.emoji,
    });
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
