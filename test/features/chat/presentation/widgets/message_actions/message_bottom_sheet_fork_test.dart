// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/domain/chat_fullscreen_video_launch_context.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/message_actions/message_bottom_sheet.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../helpers/pump_fluxer_app.dart';

const Persona _alpha = Persona(id: 'p_alpha', name: 'Alpha Alter');
const Persona _beta = Persona(id: 'p_beta', name: 'Beta Alter');

class _FakeChat extends ChatViewModel {
  @override
  ChatViewState build() => ChatViewState.empty.copyWith(channelId: 'c1');
}

class _FakePersonas extends MyPersonasNotifier {
  @override
  AsyncValue<List<Persona>> build() =>
      const AsyncData(<Persona>[_alpha, _beta]);

  @override
  Future<void> reloadSilently() async {}
}

/// The composer has Alpha selected for every channel.
class _AlphaSelected extends ActivePersonaNotifier {
  @override
  ActivePersonaState build() =>
      const ActivePersonaState(activePersonaId: 'p_alpha', isLatched: true);
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

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  /// Opens "Change persona" for a message sent as [personaId] (null: as the
  /// account).
  Future<void> openChangePersona(WidgetTester tester, String? personaId) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    late WidgetRef capturedRef;
    late BuildContext capturedContext;
    await tester.pumpWidget(
      pumpFluxerApp(
        overrides: [
          chatViewModelProvider.overrideWith(_FakeChat.new),
          myPersonasProvider.overrideWith(_FakePersonas.new),
          activePersonaProvider.overrideWith(_AlphaSelected.new),
          userSettingsViewModelProvider.overrideWith(_FakeUserSettings.new),
        ],
        child: Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? child) {
            capturedRef = ref;
            capturedContext = context;
            return const SizedBox();
          },
        ),
      ),
    );

    await dispatchMessageAction(
      ref: capturedRef,
      context: capturedContext,
      message: Message(
        id: 'm1',
        channelId: 'c1',
        authorId: '1',
        authorName: 'tester',
        content: 'hello',
        timestamp: DateTime(2026, 11, 21, 12),
        personaId: personaId,
      ),
      action: MessageAction.changePersona,
      callbacks: const MessageActionCallbacks(),
    );
    await tester.pumpAndSettle();
  }

  Finder checkIn(Finder row) =>
      find.descendant(of: row, matching: find.byIcon(PhosphorIconsBold.check));

  Finder accountRow() => find
      .ancestor(
        of: find.text('Root Account (Default)'),
        matching: find.byType(GestureDetector),
      )
      .first;

  // tyne-chat/tyne#420: a message sent as the account showed the composer's
  // selected persona as the message's.
  testWidgets("Change persona on the account's message marks the account", (
    tester,
  ) async {
    await openChangePersona(tester, null);

    expect(find.text('Change Persona'), findsOneWidget);
    expect(find.byIcon(PhosphorIconsBold.check), findsOneWidget);
    expect(checkIn(accountRow()), findsOneWidget);
  });

  testWidgets("Change persona on a persona's message marks that persona", (
    tester,
  ) async {
    await openChangePersona(tester, 'p_beta');

    expect(find.byIcon(PhosphorIconsBold.check), findsOneWidget);
    expect(checkIn(accountRow()), findsNothing);
  });
}
