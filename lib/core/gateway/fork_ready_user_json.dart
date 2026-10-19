// Fork: the signed-in user as READY's guild parser needs it
// (tyne-chat/tyne#193).
//
// READY sends each guild's members with the user reduced to its id, and the
// parser fills the user back in from a list of user maps. The handler adds the
// signed-in user to that list from `event.user.toJson()`, after the server's
// own copy, so it wins. But the SDK's generated `toJson()` (json_serializable
// without `explicit_to_json`) leaves enum fields as Dart values for
// `jsonEncode` to convert later: `mention_flags` stays a
// `MentionReplyPreferences`. `UserPartialResponse.fromJson` then fails on
// `v as num`, `GuildCreateData` skips the member without a word, and the user's
// own member is missing from every guild after READY. Channel permissions stay
// unknown until something else brings it: no reactions and no Pin in the
// long-press menu for minutes. Only accounts with a reply mention preference
// set are affected; the server leaves `mention_flags` out when it is 0.
//
// The line is upstream's (3d3b332b6, "mobile polish, sync, upload and
// reliability fixes") and upstream still has the bug. When upstream fixes it,
// take theirs and delete this file.

import 'dart:convert';

import 'package:fluxer_dart/export.dart';

extension ForkUserPrivateResponseWireJson on UserPrivateResponse {
  /// The user as plain JSON values, as the server sends it: a round trip
  /// through `jsonEncode`, which converts enums and nested models.
  Map<String, dynamic> wireJson() =>
      jsonDecode(jsonEncode(this)) as Map<String, dynamic>;
}
