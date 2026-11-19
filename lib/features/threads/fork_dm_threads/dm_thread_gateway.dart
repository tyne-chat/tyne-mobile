// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: what the gateway handler does with threads in DMs
// (tyne-chat/tyne#699). Storage is described in dm_threads.dart.

import 'package:drift/drift.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/gateway/gateway_event_handler.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_app/features/channels/data/read_state_utils.dart';
import 'package:fluxer_app/features/channels/data/unread_settings_resolver.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart'
    show isThreadChannelType;
import 'package:fluxer_app/features/threads/domain/thread_channel.dart';
import 'package:fluxer_app/features/threads/fork_dm_threads/dm_threads.dart';
import 'package:fluxer_app/shared/utils/sdk_converters.dart';
import 'package:fluxer_dart/export.dart' hide ChannelType;
import 'package:fluxer_dart/gateway.dart';
import 'package:fluxer_dart/gateway_client/event_parser.dart';
import 'package:fluxer_dart/gateway_client/fork_parse_skips.dart';

/// The envelope every event about a DM thread arrives in:
/// `{"t": "FORK_DM_THREAD_EVENT", "d": {"t": <event>, "d": <payload>}}`.
/// Older apps drop the unknown name.
const String forkDmThreadEventName = 'FORK_DM_THREAD_EVENT';

/// Inner events whose upstream parser requires a `guild_id`: a DM thread's
/// payload has none, so the DM thread key is filled in before parsing, and
/// upstream's handlers store the thread under it.
const Set<String> _guildKeyedEvents = <String>{
  'THREAD_CREATE',
  'THREAD_UPDATE',
  'THREAD_DELETE',
  'THREAD_MEMBER_UPDATE',
  'THREAD_MEMBERS_UPDATE',
};

/// Inner events that read like their community versions without a guild id.
const Set<String> _channelEvents = <String>{
  'MESSAGE_CREATE',
  'MESSAGE_UPDATE',
  'MESSAGE_DELETE',
  'MESSAGE_DELETE_BULK',
  'MESSAGE_ACK',
  'TYPING_START',
  'CHANNEL_PINS_UPDATE',
  'CHANNEL_PINS_ACK',
};

/// The upstream event a DM thread envelope carries, parsed so that
/// upstream's handlers can take it, or null for anything else.
GatewayEvent? forkUnwrapDmThreadEvent(Map<String, dynamic> envelope) {
  final Object? name = envelope['t'];
  final Object? payload = envelope['d'];
  if (name is! String || payload is! Map<String, dynamic>) {
    return null;
  }
  final bool guildKeyed = _guildKeyedEvents.contains(name);
  if (!guildKeyed &&
      !_channelEvents.contains(name) &&
      !name.startsWith('MESSAGE_REACTION_')) {
    return null;
  }
  final GatewayEvent event = const EventParser().parse(
    name,
    guildKeyed
        ? <String, dynamic>{...payload, 'guild_id': forkDmThreadGuildKey}
        : payload,
  );
  if (event is UnknownGatewayEvent) {
    talker.warning(
      '[Gateway] Fork: DM thread $name not read: ${event.parseError}',
    );
    return null;
  }
  return event;
}

/// Hands a DM thread envelope's event to upstream's handler.
Future<void> forkHandleDmThreadEvent(
  GatewayEventHandler handler,
  Map<String, dynamic> envelope,
) async {
  final GatewayEvent? event = forkUnwrapDmThreadEvent(envelope);
  if (event == null) {
    return;
  }
  await handler.handle(event);
  final ChannelResponse? thread = event is ThreadCreateEvent
      ? event.channel
      : event is ThreadUpdateEvent
      ? event.channel
      : null;
  final String? parentId = thread?.parentId;
  if (thread != null && parentId != null) {
    forkNoteDmThread(thread.id, parentId);
  } else if (event is ThreadDeleteEvent) {
    forkForgetDmThread(event.id);
  }
}

/// Whether a message just created in [channel] counts towards its unread
/// count. Every message in a DM thread does for the members who follow it,
/// have not muted it and have not turned its messages down to mentions or
/// nothing, as every DM message does (the server's
/// `dmThreadNotifiedMemberIds` counts them the same way); the message itself
/// is not marked as a mention.
Future<bool> forkDmThreadMessageCounts(
  db.FluxerDatabase database,
  db.Channel? channel,
) async {
  if (channel == null || !forkIsDmThreadRow(channel)) {
    return false;
  }
  return _followedForEveryMessage(database, channel.id);
}

/// Whether every message in the DM thread [threadId] counts for the account,
/// as every DM message does: it follows the thread, has not muted it, and has
/// not turned its messages down to mentions or nothing. False for any other
/// channel. Read when a message arrives and when unread counts are worked out
/// again after a delete.
Future<bool> forkDmThreadCountsEveryMessage(
  db.FluxerDatabase database,
  String threadId,
) async {
  if (forkDmThreadParentOf(threadId) == null) {
    return false;
  }
  return _followedForEveryMessage(database, threadId);
}

Future<bool> _followedForEveryMessage(
  db.FluxerDatabase database,
  String threadId,
) async {
  final db.ThreadMember? member = await database.threadDao.getMember(threadId);
  if (member == null || isThreadMemberMuted(member, DateTime.now())) {
    return false;
  }
  final ThreadNotificationSetting setting = threadNotificationSettingOf(
    member.flags,
  );
  return setting != ThreadNotificationSetting.onlyMentions &&
      setting != ThreadNotificationSetting.none;
}

/// Whether the DM the DM thread [channelId] belongs to is muted, so that a
/// message in the thread neither sounds nor shows a banner, as in its DM.
/// False for any other channel (tyne-chat/tyne#699).
Future<bool> forkDmThreadParentMuted(
  db.FluxerDatabase database,
  String channelId,
  DateTime now,
) async {
  final String? dmId = forkDmThreadParentOf(channelId);
  if (dmId == null) {
    return false;
  }
  final db.UserGuildSettingsTableData? row = await database.userGuildSettingsDao
      .getByGuildId('@me');
  final UserGuildSettingsResponse? settings = row == null
      ? null
      : decodeUserGuildSettings(row.data);
  return isChannelOverrideMuted(settings?.channelOverrides?[dmId], now: now);
}

/// Deletes the stored threads of the DMs [dmIds], which are gone (closed
/// while the app was away), and forgets them. Returns their ids.
Future<List<String>> forkDeleteDmThreadsOf(
  db.FluxerDatabase database,
  Iterable<String> dmIds,
) async {
  final List<String> removed = <String>[];
  for (final String dmId in dmIds) {
    for (final String threadId
        in await database.threadDao.deleteThreadsForParent(dmId)) {
      forkForgetDmThread(threadId);
      removed.add(threadId);
    }
  }
  return removed;
}

/// The account left the group DM [dmId]: its threads go with it, and a
/// thread on screen is left as a deleted channel is.
Future<void> forkLeaveDmThreads(
  GatewayEventHandler handler,
  String dmId,
) async {
  for (final String threadId in await forkDeleteDmThreadsOf(
    handler.database,
    <String>[dmId],
  )) {
    handler.readStateWriteBatcher?.discard(threadId);
    handler.onChannelDelete?.call(threadId);
  }
}

/// READY's `fork_dm_threads`: the active DM threads the account follows,
/// their read states, and whether it may start new ones. Runs inside READY's
/// transaction, after upstream's read states and before cached messages are
/// trimmed to known channels. A server without the field changes nothing.
Future<void> forkApplyReadyDmThreads(
  GatewayEventHandler handler,
  ReadyEvent event,
) async {
  final Map<String, dynamic>? raw = event.forkDmThreads;
  forkSetDmThreadsEnabled(event.user.id, enabled: raw?['enabled'] == true);
  final db.FluxerDatabase database = handler.database;
  if (raw == null) {
    await _indexStoredDmThreads(database);
    return;
  }
  final List<db.ChannelsCompanion> threads = <db.ChannelsCompanion>[];
  final List<db.ThreadMembersCompanion> joined = <db.ThreadMembersCompanion>[];
  final Set<String> listed = <String>{};
  for (final Map<String, dynamic> item in _maps(raw['threads'])) {
    final ChannelResponse thread;
    try {
      thread = ChannelResponse.fromJson(item);
    } on Object catch (error) {
      ForkGatewayParseSkips.report('READY DM thread', error);
      continue;
    }
    if (!isThreadChannelType(thread.type.json ?? -1)) {
      continue;
    }
    threads.add(channelFromSdk(thread, forkDmThreadGuildKey));
    listed.add(thread.id);
    final ThreadMemberResponse? member = thread.member;
    if (member != null) {
      joined.add(
        threadMemberFromSdk(
          member,
          threadId: thread.id,
          guildId: forkDmThreadGuildKey,
        ),
      );
    }
  }
  await database.channelDao.upsertChannelsMerged(threads);
  final List<String> stale = await database.threadDao.reconcileJoined(
    forkDmThreadGuildKey,
    joined,
    listedIds: listed,
  );
  for (final String threadId in stale) {
    handler.readStateWriteBatcher?.discard(threadId);
    handler.messageMentionContextCache?.invalidateChannel(threadId);
  }
  final List<GatewayReadState> readStates = <GatewayReadState>[];
  for (final Map<String, dynamic> item in _maps(raw['read_states'])) {
    try {
      readStates.add(GatewayReadState.fromJson(item));
    } on Object catch (error) {
      ForkGatewayParseSkips.report('READY DM thread read state', error);
    }
  }
  await _applyReadStates(handler, readStates);
  await _indexStoredDmThreads(database);
}

/// Fills the in-memory index of DM threads from the stored ones.
Future<void> _indexStoredDmThreads(db.FluxerDatabase database) async {
  forkReplaceDmThreadIndex(<String, String>{
    for (final db.Channel row in await database.threadDao.getThreadsForGuild(
      forkDmThreadGuildKey,
    ))
      if (row.parentId case final String parentId) row.id: parentId,
  });
}

Iterable<Map<String, dynamic>> _maps(Object? list) =>
    list is List<dynamic> ? list.whereType<Map<String, dynamic>>() : const [];

/// The DM threads' read states, kept as upstream's READY keeps the others:
/// a read state marked unread by hand stays so until the server moves past
/// it, and an ack still being sent wins over an older one.
Future<void> _applyReadStates(
  GatewayEventHandler handler,
  List<GatewayReadState> states,
) async {
  if (states.isEmpty) {
    return;
  }
  final db.FluxerDatabase database = handler.database;
  final Map<String, db.ReadState> existing = <String, db.ReadState>{
    for (final db.ReadState row in await database.readStateDao.getReadStatesFor(
      <String>[for (final GatewayReadState state in states) state.id],
    ))
      row.channelId: row,
  };
  final List<db.ReadStatesCompanion> rows = <db.ReadStatesCompanion>[];
  for (final GatewayReadState state in states) {
    final db.ReadState? prior = existing[state.id];
    final bool keepManual =
        (prior?.manual ?? false) &&
        compareSnowflakeIds(state.lastMessageId, prior?.lastMessageId) <= 0;
    final String? sticky = keepManual ? prior?.stickyUnreadMessageId : null;
    final String? outstandingAck = keepManual
        ? null
        : handler.ackBatcher?.outstandingAck(state.id);
    final bool localAckAhead =
        compareSnowflakeIds(outstandingAck, state.lastMessageId) > 0;
    final String? lastMessageId = localAckAhead
        ? outstandingAck
        : state.lastMessageId;
    final int mentionCount = localAckAhead ? 0 : state.mentionCount;
    rows.add(
      db.ReadStatesCompanion(
        channelId: Value(state.id),
        lastMessageId: Value(lastMessageId),
        mentionCount: Value(mentionCount),
        lastPinTimestamp: Value(state.lastPinTimestamp),
        manual: Value(keepManual),
        stickyUnreadMessageId: Value(sticky),
        version: Value(state.version),
        flags: Value(state.flags),
      ),
    );
    handler.readStateWriteBatcher?.adoptPersisted(
      channelId: state.id,
      lastMessageId: lastMessageId,
      mentionCount: mentionCount,
      manual: keepManual,
      stickyUnreadMessageId: sticky,
      lastPinTimestamp: state.lastPinTimestamp,
      version: state.version,
      flags: state.flags,
    );
  }
  await database.readStateDao.upsertReadStates(rows);
}
