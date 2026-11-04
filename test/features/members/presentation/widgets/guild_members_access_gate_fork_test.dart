import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/core/providers/app/account_user_id.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/guilds/providers/guild_permissions_provider.dart';
import 'package:fluxer_app/features/members/presentation/widgets/guild_members_access_gate.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/material_ui.dart';

import '../../../../helpers/test_account_user_id.dart';

const String _guild = 'g';
const String _denied = 'You do not have permission to view this settings tab.';
final int _manage = Permission.manageGuild.value;

/// The real provider, with a value in place of working one out from the database.
class _Permissions extends GuildPermissions {
  void give(String guildId, int value) {
    state = <String, int>{...state, guildId: value};
  }

  @override
  Future<void> refreshPermissions(String guildId) async {}
}

void main() {
  testWidgets('the Members page stays through READY (tyne-chat/tyne#275)', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        guildPermissionsProvider(
          kTestAccountUserId,
        ).overrideWith(_Permissions.new),
      ],
    );
    addTearDown(container.dispose);
    final _Permissions permissions =
        container.read(
                guildPermissionsProvider(readAccountUserId(container)).notifier,
              )
              as _Permissions
          ..give(_guild, _manage);

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
          home: const Scaffold(
            body: GuildMembersAccessGate(
              guildId: _guild,
              child: Text('members'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('members'), findsOneWidget);

    permissions.clearAll();
    await tester.pump();

    expect(find.text(_denied), findsNothing);
    expect(find.text('members'), findsOneWidget);
  });
}
