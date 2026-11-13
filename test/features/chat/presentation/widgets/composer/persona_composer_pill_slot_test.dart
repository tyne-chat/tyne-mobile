// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/composer/persona_composer_pill.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/composer/persona_composer_pill_slot.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/domain/persona_settings.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:fluxer_app/material_ui.dart';

import '../../../../../helpers/pump_fluxer_app.dart';

// tyne-chat/tyne#623: the composer rebuilds on every frame of the keyboard
// animation. The pill's slot hands back the same pill while its text and
// attachments are unchanged, so Flutter skips the pill on those frames.

class _UserSettings extends UserSettingsViewModel {
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

class _MyPersonas extends MyPersonasNotifier {
  @override
  AsyncValue<List<Persona>> build() => const AsyncData(<Persona>[
    Persona(
      id: 'p_alpha',
      name: 'Alpha Alter',
      personaTags: [PersonaTag(prefix: 'a:', suffix: '')],
    ),
  ]);

  @override
  Future<void> reloadSilently() async {}
}

class _ActivePersona extends ActivePersonaNotifier {
  @override
  ActivePersonaState build() => const ActivePersonaState();
}

class _PersonaSettings extends PersonaSettingsNotifier {
  @override
  AsyncValue<PersonaSettings> build() => const AsyncData(PersonaSettings());

  @override
  Future<void> reloadSilently() async {}
}

void main() {
  testWidgets('a parent rebuild with the same text hands back the same pill', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: 'hello',
    );
    addTearDown(controller.dispose);
    late StateSetter rebuildParent;
    await tester.pumpWidget(
      pumpFluxerApp(
        overrides: [
          userSettingsViewModelProvider.overrideWith(_UserSettings.new),
          myPersonasProvider.overrideWith(_MyPersonas.new),
          activePersonaProvider.overrideWith(_ActivePersona.new),
          personaSettingsProvider.overrideWith(_PersonaSettings.new),
        ],
        child: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              rebuildParent = setState;
              return PersonaComposerPillSlot(
                controller: controller,
                wireText: () => controller.text,
                channelId: 'c1',
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    final PersonaComposerPill first = tester.widget(
      find.byType(PersonaComposerPill),
    );
    expect(first.text, 'hello');

    rebuildParent(() {});
    await tester.pump();
    expect(
      identical(tester.widget(find.byType(PersonaComposerPill)), first),
      isTrue,
    );

    // The text changes: a new pill, without the parent rebuilding.
    controller.text = 'a: hi';
    await tester.pump();
    final PersonaComposerPill second = tester.widget(
      find.byType(PersonaComposerPill),
    );
    expect(second.text, 'a: hi');
  });
}
