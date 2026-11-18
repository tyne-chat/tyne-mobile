// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: who a forward goes out as when the Forward sheet's "Forward as" was
// used (tyne-chat/tyne#817).

import 'package:fluxer_app/features/profile/domain/persona.dart';

/// A persona, or the account ([persona] null).
class ForwardAs {
  const ForwardAs.persona(Persona this.persona);
  const ForwardAs.account() : persona = null;

  final Persona? persona;
}
