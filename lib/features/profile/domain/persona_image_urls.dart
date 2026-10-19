// Fork: the one place where a persona's images, and an account's display tag
// icon, become image addresses.
//
// Each is the hash of an image the server stores under the owning account
// (`avatars/<user id>/`, `banners/<user id>/`), served through the media proxy
// like the account's own avatar. The server accepts and sends only hashes
// (tyne-chat/tyne `fluxer_api/src/api/persona/AGENTS.md`); any other value
// still gives no address here, so a link is never loaded, whatever a cache or
// another server holds. A link would make the app load a picture from wherever
// it points and tell that server who is reading.

import 'package:fluxer_app/core/constants/media_proxy_sizes.dart';
import 'package:fluxer_app/core/media/fluxer_media_url.dart';

/// A persona image hash as the server issues it: the first 8 hex characters of
/// the image's MD5, prefixed with `a_` when animated (`PERSONA_ASSET_HASH_PATTERN`
/// in the server repository's `PersonaApiSchemas.ts`).
final RegExp _personaImageHash = RegExp(r'^(a_)?[0-9a-f]{8}$');

/// Whether [value] is a persona image hash.
bool isPersonaImageHash(String? value) =>
    value != null && _personaImageHash.hasMatch(value);

/// [value], trimmed, when it is a persona image hash, otherwise null: for a
/// widget that builds the address from a hash itself, such as `FluxerAvatar`,
/// which loads an http(s), data: or blob: value as it is.
String? personaImageHash(String? value) {
  final String? hash = value?.trim();
  return isPersonaImageHash(hash) ? hash : null;
}

String? _validHash(String? ownerUserId, String? value) {
  if (ownerUserId == null || ownerUserId.isEmpty) {
    return null;
  }
  return personaImageHash(value);
}

/// The address of a persona's avatar, or null for none (the account's avatar
/// shows instead) and for anything that is not a hash.
String? personaAvatarUrl({
  required String? ownerUserId,
  required String? hash,
  int size = MediaProxySizes.avatarDefault,
  bool animated = true,
}) {
  final String? valid = _validHash(ownerUserId, hash);
  if (valid == null) {
    return null;
  }
  return FluxerMediaUrl.userAvatar(
    userId: ownerUserId!,
    hash: valid,
    size: size,
    animated: animated,
  );
}

/// The address of a persona's banner, or null.
String? personaBannerUrl({
  required String? ownerUserId,
  required String? hash,
  bool animated = true,
}) {
  final String? valid = _validHash(ownerUserId, hash);
  if (valid == null) {
    return null;
  }
  return FluxerMediaUrl.userBanner(
    userId: ownerUserId!,
    hash: valid,
    animated: animated,
  );
}

/// The address of an account's display tag icon, or null. The icon is stored
/// like an avatar.
String? personaTagIconUrl({
  required String? ownerUserId,
  required String? icon,
  bool animated = true,
}) =>
    personaAvatarUrl(ownerUserId: ownerUserId, hash: icon, animated: animated);
