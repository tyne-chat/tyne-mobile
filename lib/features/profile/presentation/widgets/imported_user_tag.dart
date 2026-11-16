// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: the "Imported" tag after the name of a placeholder account the Discord
// history import made for someone not on Tyne (tyne-chat/tyne#682), as on the
// web. Long-press (or hover) says what it means.

import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';

class ImportedUserTag extends StatelessWidget {
  const ImportedUserTag({super.key});

  @override
  Widget build(BuildContext context) {
    final ForkLocalizations fork = FluxerLocalizations.of(context).fork;
    return Semantics(
      label: fork.importedUserTooltip,
      excludeSemantics: true,
      child: FluxerTooltip(
        message: fork.importedUserTooltip,
        child: FluxerUserTag(label: fork.importedUserTag),
      ),
    );
  }
}
