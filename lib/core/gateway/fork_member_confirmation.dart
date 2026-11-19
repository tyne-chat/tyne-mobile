// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: which cached members this gateway connection has confirmed
// (tyne-chat/tyne#614), as upstream's web app marks members restored from its
// snapshot (`restoredMembers` in fluxer_app's GuildMembers.ts).
//
// A READY in `incremental` or `cache` mode keeps the cached `members` rows, and
// a row whose GUILD_MEMBER_UPDATE was missed while the app was away keeps the
// old nickname, roles and avatar. Upstream never overwrites a cached row, so it
// stayed old until something rewrote it. After such a READY, every cached row
// of the READY's guilds counts as unconfirmed until the server writes it again
// (READY's own members, an event, a chunk, a REST fetch). An unconfirmed row is
// overwritten by a member embedded in an event, and is asked for once more
// through the gateway (never through the per-user REST fallback), at most once
// per connection.
//
// The record lives in memory, keyed by the database it describes, so the code
// that writes members needs no new parameter. Every READY starts it over.

import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_dart/export.dart' show GuildMemberResponse;

class ForkMemberConfirmation {
  ForkMemberConfirmation._();

  static final Expando<ForkMemberConfirmation> _byDatabase =
      Expando<ForkMemberConfirmation>('ForkMemberConfirmation');

  factory ForkMemberConfirmation.of(FluxerDatabase database) =>
      _byDatabase[database] ??= ForkMemberConfirmation._();

  final Set<String> _unverifiedGuilds = <String>{};
  final Map<String, Set<String>> _confirmed = <String, Set<String>>{};
  final Map<String, Set<String>> _requested = <String, Set<String>>{};

  /// Guilds READY listed as unavailable, until their GUILD_CREATE: the gateway
  /// answers no request for one, so none is sent (the request would wait out
  /// its timeout instead).
  final Set<String> _unavailableGuilds = <String>{};
  int _readyCount = 0;

  /// Goes up on every READY, so per-connection state elsewhere (the hydration
  /// service's non-members) can start over with it.
  int get readyCount => _readyCount;

  /// A new connection: nothing is unconfirmed after a `full` READY (the tables
  /// were just rewritten); after an `incremental` or `cache` one, every cached
  /// member of [guildIds] is, unavailable guilds included (their rows are kept
  /// too, and their GUILD_CREATE brings only some members). Those in
  /// [unavailableGuildIds] are asked for only once they are back.
  void startConnection({
    required bool cacheKept,
    required Iterable<String> guildIds,
    Iterable<String> unavailableGuildIds = const <String>[],
  }) {
    _readyCount++;
    _unverifiedGuilds.clear();
    _confirmed.clear();
    _requested.clear();
    _unavailableGuilds.clear();
    if (cacheKept) {
      _unverifiedGuilds.addAll(guildIds);
      _unavailableGuilds.addAll(unavailableGuildIds);
    }
  }

  /// The account changed: nothing is known about the next one's members until
  /// its READY, and per-connection state elsewhere starts over.
  void reset() => startConnection(cacheKept: false, guildIds: const <String>[]);

  /// The server has just written these members.
  void confirm(String guildId, Iterable<String> userIds) {
    if (!_unverifiedGuilds.contains(guildId)) {
      return;
    }
    _confirmed.putIfAbsent(guildId, () => <String>{}).addAll(userIds);
  }

  void confirmMembers(String guildId, Iterable<GuildMemberResponse> members) =>
      confirm(guildId, <String>[
        for (final GuildMemberResponse member in members) member.user.id,
      ]);

  void confirmCompanions(Iterable<MembersCompanion> companions) {
    for (final MembersCompanion companion in companions) {
      confirm(companion.guildId.value, <String>[companion.userId.value]);
    }
  }

  /// Whether a cached row of this member may be out of date. Says nothing about
  /// whether a row exists.
  bool isUnconfirmed(String guildId, String userId) =>
      _unverifiedGuilds.contains(guildId) &&
      !(_confirmed[guildId]?.contains(userId) ?? false);

  /// Unconfirmed, in a guild that is available, and not asked for yet in this
  /// connection.
  bool needsRequest(String guildId, String userId) =>
      isUnconfirmed(guildId, userId) &&
      !_unavailableGuilds.contains(guildId) &&
      !(_requested[guildId]?.contains(userId) ?? false);

  /// The members of [userIds] to ask the gateway for now, each marked as asked
  /// so no other caller asks again in this connection. Call it only right before
  /// sending the request.
  List<String> claimRequests(String guildId, Iterable<String> userIds) {
    final List<String> claimed = <String>[
      for (final String userId in userIds)
        if (needsRequest(guildId, userId)) userId,
    ];
    if (claimed.isNotEmpty) {
      _requested.putIfAbsent(guildId, () => <String>{}).addAll(claimed);
    }
    return claimed;
  }

  /// The guild came back (its GUILD_CREATE has been stored): its members may
  /// be asked for now. Only a guild READY listed as unavailable changes; a
  /// GUILD_CREATE or GUILD_SYNC of an available one, which arrives whenever
  /// the guild is opened, gives nobody a second request.
  void guildAvailable(String guildId) => _unavailableGuilds.remove(guildId);

  /// The guild's member rows were removed (GUILD_DELETE): nothing about them
  /// is left to confirm.
  void forgetGuild(String guildId) {
    _unverifiedGuilds.remove(guildId);
    _unavailableGuilds.remove(guildId);
    _confirmed.remove(guildId);
    _requested.remove(guildId);
  }

  /// The member's row was removed.
  void forget(String guildId, String userId) {
    _confirmed[guildId]?.remove(userId);
    _requested[guildId]?.remove(userId);
  }
}

/// [ForkMemberConfirmation.startConnection] for a READY.
void forkStartMemberConfirmation(
  FluxerDatabase database, {
  required bool fullWipe,
  required List<Map<String, dynamic>> rawGuilds,
}) => ForkMemberConfirmation.of(database).startConnection(
  cacheKept: !fullWipe,
  guildIds: <String>[
    for (final Map<String, dynamic> rawGuild in rawGuilds)
      if (rawGuild['id'] case final String id) id,
  ],
  unavailableGuildIds: <String>[
    for (final Map<String, dynamic> rawGuild in rawGuilds)
      if (rawGuild['unavailable'] == true)
        if (rawGuild['id'] case final String id) id,
  ],
);

/// A GUILD_CREATE (or GUILD_SYNC) has been stored: the [members] it carried
/// are confirmed, and when it is still the guild's latest availability
/// ([current]), the guild is available to ask for again.
void forkGuildCreateStored(
  FluxerDatabase database,
  String guildId,
  Iterable<GuildMemberResponse> members, {
  required bool current,
}) {
  final ForkMemberConfirmation confirmation = ForkMemberConfirmation.of(
    database,
  )..confirmMembers(guildId, members);
  if (current) {
    confirmation.guildAvailable(guildId);
  }
}

/// Whether an embedded member may overwrite the cached row: only when this
/// connection has not confirmed it.
bool forkCachedMemberUnconfirmed(
  FluxerDatabase database,
  String guildId,
  String userId,
) => ForkMemberConfirmation.of(database).isUnconfirmed(guildId, userId);

/// After the gateway was asked for [claimed] (cached but unconfirmed members):
/// those it reported as not in the guild left while the app was away, so their
/// stale row goes, as the web app removes a restored member the reply left out.
Future<void> forkRemoveMembersWhoLeft(
  FluxerDatabase database,
  String guildId,
  List<String> claimed, {
  required bool Function(String userId) isNonMember,
}) async {
  final ForkMemberConfirmation confirmation = ForkMemberConfirmation.of(
    database,
  );
  for (final String userId in claimed) {
    if (isNonMember(userId)) {
      await database.memberDao.deleteMember(userId, guildId);
      confirmation.forget(guildId, userId);
    }
  }
}
