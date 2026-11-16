// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: placeholder accounts the Discord history import made for people not on
// Tyne (public user flag IMPORTED, tyne-chat/tyne#682). Nobody is behind them,
// so the app offers no message, call or friend actions for them; the server
// refuses those too.

/// The server's `UserFlags.IMPORTED`: the top bit of the public flags, where
/// the fork takes its flag bits.
const int kForkUserFlagImported = 1 << 30;

/// Whether [userFlags] (a user's public flags) mark an imported placeholder.
bool isImportedPlaceholder(int? userFlags) =>
    userFlags != null && (userFlags & kForkUserFlagImported) != 0;
