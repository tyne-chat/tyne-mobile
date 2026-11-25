// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: whether a message was sent as a persona this account blocked
// (tyne-chat/tyne#921). Kept apart from the provider that loads the list, so
// that upstream's channel stream needs nothing more than this to collapse such
// a message as it collapses a blocked account's.

import 'package:fluxer_app/features/chat/domain/message.dart';

/// The key of one blocked persona: persona ids are unique only within their
/// account, so the account is part of it.
String personaBlockKey(String userId, String personaId) => '$userId:$personaId';

/// Whether [message] was sent as a persona in [blockedPersonaKeys].
bool isMessageFromBlockedPersona(
  Set<String> blockedPersonaKeys,
  Message message,
) {
  final String? personaId = message.personaId;
  if (blockedPersonaKeys.isEmpty || personaId == null || personaId.isEmpty) {
    return false;
  }
  return blockedPersonaKeys.contains(
    personaBlockKey(message.authorId, personaId),
  );
}
