import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/guilds/domain/guild.dart';
import 'package:fluxer_app/features/guilds/providers/guild_permissions_provider.dart';
import 'package:fluxer_app/features/guilds/providers/guild_providers.dart';
import 'package:fluxer_app/features/guilds/providers/guild_sync_provider.dart';
import 'package:fluxer_app/features/settings/domain/guild/guild_settings_tab.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/guild/guild_settings_access_gate.dart';
import 'package:fluxer_app/features/settings/providers/guild/guild_settings_tab_providers.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/material_ui.dart';

const String _guild = 'g';
const String _denied = 'You do not have permission to view this settings tab.';
final int _manage = Permission.manageCommands.value;

/// The real provider, with a value in place of working one out from the database.
class _Permissions extends GuildPermissions {
  void give(String guildId, int value) {
    state = <String, int>{...state, guildId: value};
  }
}

class _NoSync extends GuildSync {
  @override
  void syncIfNeeded(String guildId, {bool force = false}) {}
}

/// Stands in for an editor: `starts` goes up each time it is built from scratch.
class _Editor extends StatefulWidget {
  const _Editor(this.onStart);

  final VoidCallback onStart;

  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  @override
  void initState() {
    super.initState();
    widget.onStart();
  }

  @override
  Widget build(BuildContext context) => const Text('editor');
}

ProviderContainer _container() {
  final ProviderContainer container = ProviderContainer(
    overrides: [guildPermissionsProvider.overrideWith(_Permissions.new)],
  );
  addTearDown(container.dispose);
  return container;
}

_Permissions _permissions(ProviderContainer container) =>
    container.read(guildPermissionsProvider.notifier) as _Permissions;

void main() {
  group('guildSettingsPermissions', () {
    int read(ProviderContainer container) =>
        container.read(guildSettingsPermissionsProvider(_guild));

    test('is 0 for a guild never worked out', () {
      expect(read(_container()), 0);
    });

    test('keeps the last value while READY refills it', () {
      final ProviderContainer container = _container();
      _permissions(container).give(_guild, _manage);
      _permissions(container).clearAll();
      expect(read(container), _manage);
    });

    test('keeps it through a second READY before the refill', () {
      final ProviderContainer container = _container();
      _permissions(container).give(_guild, _manage);
      _permissions(container).clearAll();
      _permissions(container).clearAll();
      expect(read(container), _manage);
    });

    test('takes the refilled value at once, even when it is less', () {
      final ProviderContainer container = _container();
      _permissions(container).give(_guild, _manage);
      _permissions(container).clearAll();
      _permissions(container).give(_guild, 0);
      expect(read(container), 0);
    });

    test('forgets a guild that is left', () {
      final ProviderContainer container = _container();
      _permissions(container).give(_guild, _manage);
      _permissions(container).clearAll();
      _permissions(container).evict(_guild);
      expect(read(container), 0);
    });

    test('forgets everything on an account switch', () {
      final ProviderContainer container = _container();
      container.read(currentUserIdProvider.notifier).set('a');
      _permissions(container).give(_guild, _manage);
      _permissions(container).clearAll();
      container.read(currentUserIdProvider.notifier).set('b');
      expect(read(container), 0);
    });
  });

  group('GuildSettingsAccessGate', () {
    Future<int Function()> pumpGate(
      WidgetTester tester,
      ProviderContainer container,
    ) async {
      int starts = 0;
      final colorTheme = buildDarkColorTheme();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildFluxerTheme(
              colorTheme: colorTheme,
              textTheme: FluxerTextTheme.fromColors(colorTheme),
              layoutTheme: FluxerLayoutTheme.scaled(),
            ),
            localizationsDelegates: FluxerLocalizations.localizationsDelegates,
            supportedLocales: FluxerLocalizations.supportedLocales,
            home: Scaffold(
              body: GuildSettingsAccessGate(
                guildId: _guild,
                tab: GuildSettingsTab.commands,
                child: _Editor(() => starts++),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return () => starts;
    }

    ProviderContainer gateContainer() {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          guildPermissionsProvider.overrideWith(_Permissions.new),
          guildSyncProvider.overrideWith(_NoSync.new),
          guildByIdProvider(
            _guild,
          ).overrideWith((Ref ref) => Future<Guild?>.value()),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    testWidgets('keeps an open tab, state and all, through READY', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = gateContainer();
      _permissions(container).give(_guild, _manage);
      final int Function() starts = await pumpGate(tester, container);
      expect(find.text('editor'), findsOneWidget);

      _permissions(container).clearAll();
      await tester.pump();
      expect(find.text(_denied), findsNothing);
      expect(find.text('editor'), findsOneWidget);

      _permissions(container).give(_guild, _manage);
      await tester.pump();
      expect(find.text('editor'), findsOneWidget);
      expect(starts(), 1);
    });

    testWidgets('closes the tab when READY shows the permission is gone', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = gateContainer();
      _permissions(container).give(_guild, _manage);
      await pumpGate(tester, container);

      _permissions(container).clearAll();
      await tester.pump();
      _permissions(container).give(_guild, 0);
      await tester.pump();

      expect(find.text(_denied), findsOneWidget);
      expect(find.text('editor'), findsNothing);
    });

    testWidgets('refuses a tab it knows nothing about, as before', (
      WidgetTester tester,
    ) async {
      await pumpGate(tester, gateContainer());
      expect(find.text(_denied), findsOneWidget);
    });
  });
}
