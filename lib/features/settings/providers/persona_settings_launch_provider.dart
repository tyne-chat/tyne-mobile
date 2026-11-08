// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: how the Personas settings page should open next time
// (tyne-chat/tyne#542). Your own Personas gallery, when none of your personas
// is public, opens the page with the unlisted ones filtered and select mode
// on, so a few can be made public at once. `UserSettingsModal.show` takes no
// arguments for a section, so the page reads this when it opens and clears
// it.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which personas the settings list shows, by visibility.
enum PersonaVisibilityFilter {
  all,
  public,
  unlisted,
  private;

  /// Whether a persona with [visibility] shows under this filter.
  bool matches(String visibility) => switch (this) {
    PersonaVisibilityFilter.all => true,
    PersonaVisibilityFilter.public => visibility == 'public',
    PersonaVisibilityFilter.unlisted => visibility == 'unlisted',
    PersonaVisibilityFilter.private => visibility == 'private',
  };
}

/// How the Personas settings page opens.
@immutable
class PersonaSettingsLaunch {
  const PersonaSettingsLaunch({
    this.filter = PersonaVisibilityFilter.all,
    this.selecting = false,
  });

  final PersonaVisibilityFilter filter;

  /// Whether it opens in select mode.
  final bool selecting;
}

class PersonaSettingsLaunchNotifier extends Notifier<PersonaSettingsLaunch?> {
  @override
  PersonaSettingsLaunch? build() => null;

  /// How the page opens the next time; null once it has opened.
  PersonaSettingsLaunch? get next => state;
  set next(PersonaSettingsLaunch? launch) => state = launch;
}

final NotifierProvider<PersonaSettingsLaunchNotifier, PersonaSettingsLaunch?>
personaSettingsLaunchProvider =
    NotifierProvider<PersonaSettingsLaunchNotifier, PersonaSettingsLaunch?>(
      PersonaSettingsLaunchNotifier.new,
    );
