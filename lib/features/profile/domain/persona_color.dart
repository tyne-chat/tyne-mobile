// SPDX-License-Identifier: AGPL-3.0-or-later

/// Fork: the one rule for the colour a persona is drawn in (mentions, typing,
/// the profile), the same as the web app's `personaColor`
/// (tyne-chat/tyne#254): the accent colour its owner picked, else the colour
/// taken from its own avatar. A persona without an avatar of its own shows the
/// account's, so its stored avatar colour says nothing then. Null when neither
/// applies: each place keeps its usual colour. 0 means no colour. The settings
/// list shows the accent setting itself and does not use this.
int? resolvePersonaColor({
  required int? color,
  required int? avatarColor,
  required String? avatarHash,
}) {
  if (color != null && color != 0) {
    return color;
  }
  final bool hasOwnAvatar = avatarHash != null && avatarHash.isNotEmpty;
  if (hasOwnAvatar && avatarColor != null && avatarColor != 0) {
    return avatarColor;
  }
  return null;
}
