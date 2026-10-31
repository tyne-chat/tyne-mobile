import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/channels/providers/channel_providers.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/guild_commands/presentation/guild_command_chip.dart';
import 'package:fluxer_app/features/guild_commands/providers/guild_command_editing.dart';
import 'package:fluxer_app/features/guilds/providers/guild_permissions_provider.dart';
import 'package:fluxer_app/features/settings/domain/guild/guild_settings_tab.dart';
import 'package:fluxer_app/features/ui/toast/toast_provider.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/test_l10n.dart';
import 'guild_commands_test_support.dart';

const String _guild = 'g1';
const String _commandsTab = 'the commands tab';
const Duration _toastGone = Duration(minutes: 1);

class _Permissions extends GuildPermissions {
  _Permissions(this.permissions);

  final int permissions;

  @override
  Map<String, int> build() {
    super.build();
    return <String, int>{_guild: permissions};
  }
}

Message _message({String commandId = '7'}) => Message(
  id: '1',
  channelId: 'c',
  authorId: 'someone',
  authorName: 'Someone',
  content: 'A hug',
  timestamp: DateTime.utc(2026),
  commandId: commandId,
  commandGuildId: _guild,
  commandName: 'hug',
);

void main() {
  late RecordingAdapter adapter;
  late String creator;

  setUp(() {
    creator = 'someone else';
    adapter = RecordingAdapter(
      (RequestOptions options) => <Object?>[
        <String, Object?>{
          ...commandJson('7', _guild, 'hug'),
          'creator_id': creator,
        },
      ],
    );
  });

  Future<ProviderContainer> pumpChip(
    WidgetTester tester, {
    int permissions = 0,
    Message? message,
  }) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final ProviderContainer container = commandsContainer(
      adapter: adapter,
      clock: TestClock(),
      overrides: [
        guildPermissionsProvider.overrideWith(() => _Permissions(permissions)),
        channelByIdProvider(
          'c',
        ).overrideWith((Ref ref) => Stream<Channel?>.value(null)),
      ],
    );
    addTearDown(container.dispose);
    final Widget chip = GuildCommandChip(message: message ?? _message());
    final GoRouter router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(body: Center(child: chip)),
        ),
        GoRoute(
          path: guildSettingsTabPath(_guild, GuildSettingsTab.commands),
          builder: (_, _) => const Scaffold(body: Text(_commandsTab)),
        ),
      ],
    );
    addTearDown(router.dispose);
    final colorTheme = buildDarkColorTheme();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          locale: kTestLocale,
          localizationsDelegates: fluxerLocalizationsDelegates,
          supportedLocales: FluxerLocalizations.supportedLocales,
          theme: buildFluxerTheme(
            colorTheme: colorTheme,
            textTheme: FluxerTextTheme.fromColors(colorTheme),
            layoutTheme: FluxerLayoutTheme.scaled(),
          ),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  List<String> toasts(ProviderContainer container) => <String>[
    for (final ToastEntry entry in container.read(toastProvider))
      entry.toast.message,
  ];

  testWidgets('drawing a chip sends nothing', (WidgetTester tester) async {
    await pumpChip(tester);

    expect(find.text('/hug'), findsOneWidget);
    expect(adapter.requests, isEmpty);
  });

  testWidgets('a tap puts a usable command in the message box', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpChip(tester);

    await tester.tap(find.text('/hug'));
    await tester.pumpAndSettle();

    expect(container.read(pendingGuildCommandInsertProvider), (
      channelId: 'c',
      name: 'hug',
    ));
    expect(toasts(container), isEmpty);
  });

  testWidgets('tapping again shares the one list request', (
    WidgetTester tester,
  ) async {
    await pumpChip(tester);

    await tester.tap(find.text('/hug'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('/hug'));
    await tester.pumpAndSettle();

    expect(adapter.requests, hasLength(1));
  });

  testWidgets('a tap on a deleted command says which command made it', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpChip(
      tester,
      message: _message(commandId: 'gone'),
    );

    await tester.tap(find.text('/hug'));
    await tester.pumpAndSettle();

    expect(container.read(pendingGuildCommandInsertProvider), isNull);
    expect(toasts(container).single, contains('/hug'));
    await tester.pump(_toastGone);
  });

  testWidgets('a failed list is not asked for again straight away', (
    WidgetTester tester,
  ) async {
    adapter.failWith = 500;
    final ProviderContainer container = await pumpChip(tester);

    await tester.tap(find.text('/hug'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('/hug'));
    await tester.pumpAndSettle();

    expect(adapter.requests, hasLength(1));
    expect(container.read(pendingGuildCommandInsertProvider), isNull);
    await tester.pump(_toastGone);
  });

  testWidgets('a long press offers Edit to Manage Commands, and opens it', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpChip(
      tester,
      permissions: Permission.manageCommands.value,
    );

    await tester.longPress(find.text('/hug'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit /hug'));
    await tester.pumpAndSettle();

    expect(find.text(_commandsTab), findsOneWidget);
    expect(container.read(guildCommandEditRequestProvider), (
      guildId: _guild,
      commandId: '7',
    ));
  });

  testWidgets('a long press offers Edit to the creator with Create Commands', (
    WidgetTester tester,
  ) async {
    creator = 'me';
    await pumpChip(tester, permissions: Permission.createCommands.value);

    await tester.longPress(find.text('/hug'));
    await tester.pumpAndSettle();

    expect(find.text('Edit /hug'), findsOneWidget);
  });

  testWidgets('a long press does nothing for anyone else', (
    WidgetTester tester,
  ) async {
    await pumpChip(tester, permissions: Permission.createCommands.value);

    await tester.longPress(find.text('/hug'));
    await tester.pumpAndSettle();

    expect(find.text('Edit /hug'), findsNothing);
  });

  testWidgets('a long press does nothing on a deleted command', (
    WidgetTester tester,
  ) async {
    await pumpChip(
      tester,
      permissions: Permission.manageCommands.value,
      message: _message(commandId: 'gone'),
    );

    await tester.longPress(find.text('/hug'));
    await tester.pumpAndSettle();

    expect(find.text('Edit /hug'), findsNothing);
  });
}
