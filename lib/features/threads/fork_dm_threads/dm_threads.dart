// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: threads in DMs and group DMs (tyne-chat/tyne#699).
//
// A DM thread is a thread channel (type 11) whose parent is a DM or group DM.
// It is stored where the app keeps every other thread: a row in `channels`
// and the account's `thread_members` row. Both tables type the guild id as
// non-null, so a DM thread stores the empty string there
// ([forkDmThreadGuildKey]), as the server stores `0`. The empty string is
// what upstream's code already reads as "no community": navigation goes to
// the DM routes, community read states and settings skip the row, and no
// community list ever shows it. Keeping DM threads in the same tables lets
// the thread screen, the composer gate, the thread menu and the read states
// work on them unchanged; the fork adds the few places that need to know the
// parent is a DM. No schema change is needed.

import 'package:flutter/foundation.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/core/router/route_names.dart';
import 'package:fluxer_app/features/channels/data/read_state_utils.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';

/// The guild id a DM thread is stored under in `channels` and
/// `thread_members`.
const String forkDmThreadGuildKey = '';

/// What a member of a DM may do in its threads, as permission bits for
/// upstream's thread rules. Moderation (lock, delete, removing members) comes
/// only with being the group's owner (`ThreadActor.isOwner`).
final int forkDmThreadMemberPermissions =
    Permission.viewChannel.value |
    Permission.sendMessages.value |
    Permission.sendMessagesInThreads.value |
    Permission.readMessageHistory.value |
    Permission.addReactions.value |
    Permission.embedLinks.value |
    Permission.attachFiles.value |
    Permission.useExternalEmojis.value |
    Permission.useExternalStickers.value |
    Permission.pinMessages.value;

/// Whether a stored channel row is a thread in a DM.
bool forkIsDmThreadRow(db.Channel row) =>
    row.guildId == forkDmThreadGuildKey && isThreadChannelType(row.type);

/// Whether [channel] is a thread in a DM.
bool forkIsDmThread(Channel? channel) =>
    channel != null &&
    channel.guildId == forkDmThreadGuildKey &&
    channel.isThread;

/// Whether [channel] is a DM or group DM standing in as a thread parent
/// ([forkDmThreadParentChannel]).
bool forkIsDmThreadParent(Channel? channel) =>
    channel != null &&
    channel.guildId == forkDmThreadGuildKey &&
    (channel.type == ChannelType.dm || channel.type == ChannelType.groupDm);

/// A DM as the thread parent upstream's thread sheets take. DMs live in
/// `dm_channels`, not `channels`, so the browser and the create sheet get
/// this stand-in: the DM's id, no community, and its type.
Channel forkDmThreadParentChannel({
  required String dmId,
  required bool isGroup,
  required String name,
}) => Channel(
  id: dmId,
  guildId: forkDmThreadGuildKey,
  name: name,
  type: isGroup ? ChannelType.groupDm : ChannelType.dm,
);

// Which DM each known DM thread belongs to, in memory. Back, the DM list's
// mark and the DM header ask it before anything reads the database, so
// screens without DM threads (and upstream's tests) never open a query for
// them. READY fills it from the stored threads, the thread events keep it up
// to date. Thread ids are unique across accounts, so it is not per account;
// READY of another account replaces it.
final ValueNotifier<Map<String, String>> _dmThreadParents =
    ValueNotifier<Map<String, String>>(const <String, String>{});

/// Changes whenever the index of known DM threads changes.
Listenable get forkDmThreadIndexChanges => _dmThreadParents;

/// The DM [threadId] belongs to, if it is a known DM thread.
String? forkDmThreadParentOf(String threadId) =>
    _dmThreadParents.value[threadId];

/// Whether a thread is known in the DM [dmId].
bool forkDmHasKnownThreads(String dmId) =>
    _dmThreadParents.value.containsValue(dmId);

/// Replaces the index with [threads] (thread id to DM id).
void forkReplaceDmThreadIndex(Map<String, String> threads) {
  if (mapEquals(threads, _dmThreadParents.value)) {
    return;
  }
  _dmThreadParents.value = Map<String, String>.unmodifiable(threads);
}

/// Records that [threadId] is a thread in the DM [dmId].
void forkNoteDmThread(String threadId, String dmId) {
  if (_dmThreadParents.value[threadId] == dmId) {
    return;
  }
  _dmThreadParents.value = Map<String, String>.unmodifiable(<String, String>{
    ..._dmThreadParents.value,
    threadId: dmId,
  });
}

/// Forgets [threadId] (deleted).
void forkForgetDmThread(String threadId) {
  if (!_dmThreadParents.value.containsKey(threadId)) {
    return;
  }
  _dmThreadParents.value = Map<String, String>.unmodifiable(
    <String, String>{..._dmThreadParents.value}..remove(threadId),
  );
}

/// Empties the index (tests).
@visibleForTesting
void forkResetDmThreadIndex() =>
    _dmThreadParents.value = const <String, String>{};

/// Where Back leaves a DM thread for: its DM, whichever way the thread was
/// opened. Null for anything else.
String? forkDmThreadLeavePath(String channelId) {
  final String? parentId = forkDmThreadParentOf(channelId);
  return parentId == null ? null : RoutePaths.dmChannel(parentId);
}

/// The thread browser's line under its title: `#channel`, or a DM's name.
String forkThreadBrowserParentLabel(Channel parent) =>
    forkIsDmThreadParent(parent) ? parent.name : '#${parent.name}';

/// A DM's threads whose names hold [query], newest first. Community
/// threads are searched by the server; a DM's are the ones on the device.
Future<List<String>> forkSearchDmThreadIds(
  db.FluxerDatabase database, {
  required String parentId,
  required String query,
  required bool archived,
}) async {
  final String needle = query.trim().toLowerCase();
  final List<db.Channel> rows = await database.threadDao.getThreadsForParent(
    parentId,
  );
  rows.sort((db.Channel a, db.Channel b) => compareSnowflakeIds(b.id, a.id));
  return <String>[
    for (final db.Channel row in rows)
      if ((row.threadArchived ?? false) == archived &&
          row.name.toLowerCase().contains(needle))
        row.id,
  ];
}

// READY's per-account switch: whether an account may start threads in DMs.
// Existing DM threads show whatever it says. The gateway handler is plain
// Dart, so READY writes the switch here and `forkDmThreadsEnabledProvider`
// reads it.
final ValueNotifier<Map<String, bool>> _dmThreadsSwitch =
    ValueNotifier<Map<String, bool>>(const <String, bool>{});

/// Changes whenever a READY sets an account's switch.
Listenable get forkDmThreadsSwitchChanges => _dmThreadsSwitch;

/// The switch READY last gave [userId]; off until then.
bool forkDmThreadsEnabledFor(String? userId) =>
    userId != null && (_dmThreadsSwitch.value[userId] ?? false);

/// Records READY's switch for [userId].
void forkSetDmThreadsEnabled(String userId, {required bool enabled}) {
  if (_dmThreadsSwitch.value[userId] == enabled) {
    return;
  }
  _dmThreadsSwitch.value = <String, bool>{
    ..._dmThreadsSwitch.value,
    userId: enabled,
  };
}

/// Forgets every account's switch (tests).
@visibleForTesting
void forkResetDmThreadsEnabled() =>
    _dmThreadsSwitch.value = const <String, bool>{};
