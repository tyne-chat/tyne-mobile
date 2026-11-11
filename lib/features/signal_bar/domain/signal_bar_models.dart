import 'package:flutter/foundation.dart';

/// One toggleable signal on the instance-wide signal bar.
@immutable
class SignalBarSignal {
  const SignalBarSignal({
    required this.id,
    required this.emojiName,
    required this.animated,
    this.emojiId,
    this.label,
    this.everywhere = false,
  });

  factory SignalBarSignal.fromJson(Map<String, dynamic> json) {
    return SignalBarSignal(
      id: json['id'] as String,
      emojiId: json['emoji_id'] as String?,
      emojiName: json['emoji_name'] as String,
      animated: json['animated'] as bool? ?? false,
      label: json['label'] as String?,
      everywhere: json['everywhere'] as bool? ?? false,
    );
  }

  final String id;
  final String? emojiId;
  final String emojiName;
  final bool animated;
  final String? label;

  /// Whether the managers let people set this signal in every chat at once.
  final bool everywhere;

  String get displayLabel =>
      (label != null && label!.isNotEmpty) ? label! : emojiName;
}

/// The bar as configured by the home community's managers.
@immutable
class SignalBarConfig {
  const SignalBarConfig({
    required this.version,
    required this.signals,
    this.guildId,
    this.canManage = false,
  });

  factory SignalBarConfig.fromJson(Map<String, dynamic> json) {
    return SignalBarConfig(
      version: (json['version'] as num?)?.toInt() ?? 0,
      signals: <SignalBarSignal>[
        for (final Object? item
            in json['signals'] as List<dynamic>? ?? const [])
          SignalBarSignal.fromJson(item! as Map<String, dynamic>),
      ],
      guildId: json['guild_id'] as String?,
      canManage: json['can_manage'] as bool? ?? false,
    );
  }

  static const SignalBarConfig empty = SignalBarConfig(
    version: -1,
    signals: <SignalBarSignal>[],
  );

  final int version;
  final List<SignalBarSignal> signals;
  final String? guildId;
  final bool canManage;
}

/// One account currently giving a signal in a channel. An account holds at
/// most one entry per signal; [personaId] is whoever it is signalling as now.
@immutable
class SignalEntry {
  const SignalEntry({
    required this.signalId,
    required this.userId,
    required this.username,
    this.globalName,
    this.userAvatar,
    this.personaId,
    this.personaName,
    this.personaAvatar,
    this.activatedAt = 0,
  });

  factory SignalEntry.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> user = json['user'] as Map<String, dynamic>;
    final Map<String, dynamic>? subprofile =
        json['subprofile'] as Map<String, dynamic>?;
    return SignalEntry(
      signalId: json['signal_id'] as String,
      userId: user['id'] as String,
      username: user['username'] as String? ?? '',
      globalName: user['global_name'] as String?,
      userAvatar: user['avatar'] as String?,
      personaId: json['persona_id'] as String?,
      personaName: subprofile?['name'] as String?,
      personaAvatar: subprofile?['avatar'] as String?,
      activatedAt: (json['activated_at'] as num?)?.toInt() ?? 0,
    );
  }

  final String signalId;
  final String userId;
  final String username;
  final String? globalName;
  final String? userAvatar;
  final String? personaId;
  final String? personaName;
  final String? personaAvatar;

  /// When the signal was lit, in Unix milliseconds.
  final int activatedAt;

  String get displayName {
    if (personaName != null && personaName!.isNotEmpty) {
      return personaName!;
    }
    if (globalName != null && globalName!.isNotEmpty) {
      return globalName!;
    }
    return username;
  }

  SignalEntry withPersona({
    required String? personaId,
    required String? personaName,
    required String? personaAvatar,
  }) {
    return SignalEntry(
      signalId: signalId,
      userId: userId,
      username: username,
      globalName: globalName,
      userAvatar: userAvatar,
      personaId: personaId,
      personaName: personaName,
      personaAvatar: personaAvatar,
      activatedAt: activatedAt,
    );
  }
}

/// The persona an account is acting as right now, as resolved by the composer.
@immutable
class SignalPersona {
  const SignalPersona({required this.id, required this.name, this.avatar});

  final String id;
  final String name;
  final String? avatar;
}

/// Applies a CHANNEL_SIGNAL_UPDATE payload to a channel's entries. Removed
/// entries are dropped; added entries replace the same account's entry on the
/// same signal in place, or are appended.
List<SignalEntry> applySignalUpdate(
  List<SignalEntry> current, {
  required List<SignalEntry> added,
  required List<({String signalId, String userId})> removed,
}) {
  final List<SignalEntry> next = <SignalEntry>[
    for (final SignalEntry entry in current)
      if (!removed.any(
        (r) => r.signalId == entry.signalId && r.userId == entry.userId,
      ))
        entry,
  ];
  for (final SignalEntry entry in added) {
    final int index = next.indexWhere(
      (e) => e.signalId == entry.signalId && e.userId == entry.userId,
    );
    if (index == -1) {
      next.add(entry);
    } else {
      next[index] = entry;
    }
  }
  return next;
}

/// One of the account's own signals in a chat, as the signals-everywhere
/// routes describe it.
@immutable
class UserSignalRef {
  const UserSignalRef({required this.signalId, this.personaId});

  factory UserSignalRef.fromJson(Map<String, dynamic> json) {
    return UserSignalRef(
      signalId: json['signal_id'] as String,
      personaId: json['persona_id'] as String?,
    );
  }

  final String signalId;
  final String? personaId;

  @override
  bool operator ==(Object other) =>
      other is UserSignalRef &&
      other.signalId == signalId &&
      other.personaId == personaId;

  @override
  int get hashCode => Object.hash(signalId, personaId);
}

List<UserSignalRef> _parseRefs(Object? value) => <UserSignalRef>[
  for (final Object? item in value as List<dynamic>? ?? const [])
    UserSignalRef.fromJson(item! as Map<String, dynamic>),
];

/// The account's signals in one chat. [updatedAt] is when the newest of them
/// was lit, in Unix milliseconds; the list is newest first by it.
@immutable
class UserSignalChat {
  const UserSignalChat({
    required this.channelId,
    required this.signals,
    required this.updatedAt,
  });

  factory UserSignalChat.fromJson(Map<String, dynamic> json) {
    return UserSignalChat(
      channelId: json['channel_id'] as String,
      signals: _parseRefs(json['signals']),
      updatedAt: (json['updated_at'] as num?)?.toInt() ?? 0,
    );
  }

  final String channelId;
  final List<UserSignalRef> signals;
  final int updatedAt;
}

/// `GET /users/@me/signals`: every chat where the account has a signal on, and
/// whether Restore has something to put back.
@immutable
class UserSignalsSummary {
  const UserSignalsSummary({
    required this.chats,
    required this.restoreAvailable,
  });

  factory UserSignalsSummary.fromJson(Map<String, dynamic> json) {
    return UserSignalsSummary(
      chats: <UserSignalChat>[
        for (final Object? item in json['chats'] as List<dynamic>? ?? const [])
          UserSignalChat.fromJson(item! as Map<String, dynamic>),
      ],
      restoreAvailable: json['restore_available'] as bool? ?? false,
    );
  }

  final List<UserSignalChat> chats;
  final bool restoreAvailable;

  /// The chats newest first.
  List<UserSignalChat> get newestFirst => <UserSignalChat>[...chats]
    ..sort((UserSignalChat a, UserSignalChat b) => b.updatedAt - a.updatedAt);

  /// Applies a CHANNEL_SIGNAL_UPDATE to the account's own signals in it.
  UserSignalsSummary withChannelUpdate(
    String channelId, {
    required String userId,
    required List<SignalEntry> added,
    required List<({String signalId, String userId})> removed,
  }) {
    final List<String> removedIds = <String>[
      for (final r in removed)
        if (r.userId == userId) r.signalId,
    ];
    final List<SignalEntry> mine = <SignalEntry>[
      for (final SignalEntry entry in added)
        if (entry.userId == userId) entry,
    ];
    if (removedIds.isEmpty && mine.isEmpty) {
      return this;
    }
    final UserSignalChat? current = chats
        .where((UserSignalChat chat) => chat.channelId == channelId)
        .firstOrNull;
    final List<UserSignalRef> refs = <UserSignalRef>[
      for (final UserSignalRef ref in current?.signals ?? const [])
        if (!removedIds.contains(ref.signalId)) ref,
    ];
    int updatedAt = current?.updatedAt ?? 0;
    for (final SignalEntry entry in mine) {
      final UserSignalRef ref = UserSignalRef(
        signalId: entry.signalId,
        personaId: entry.personaId,
      );
      final int index = refs.indexWhere(
        (UserSignalRef existing) => existing.signalId == entry.signalId,
      );
      if (index == -1) {
        refs.add(ref);
      } else {
        refs[index] = ref;
      }
      if (entry.activatedAt > updatedAt) {
        updatedAt = entry.activatedAt;
      }
    }
    return UserSignalsSummary(
      chats: <UserSignalChat>[
        for (final UserSignalChat chat in chats)
          if (chat.channelId != channelId) chat,
        if (refs.isNotEmpty)
          UserSignalChat(
            channelId: channelId,
            signals: refs,
            updatedAt: updatedAt,
          ),
      ],
      restoreAvailable: restoreAvailable,
    );
  }
}

/// What the last change everywhere was, which Restore undoes.
enum UserSignalsRestoreKind { set, off, restore }

/// One chat in the restore preview: what is on [now], what it gets back
/// ([after]), and whether the account may still light signals there.
@immutable
class UserSignalsRestoreChat {
  const UserSignalsRestoreChat({
    required this.channelId,
    required this.available,
    required this.now,
    required this.after,
  });

  factory UserSignalsRestoreChat.fromJson(Map<String, dynamic> json) {
    return UserSignalsRestoreChat(
      channelId: json['channel_id'] as String,
      available: json['available'] as bool? ?? false,
      now: _parseRefs(json['now']),
      after: _parseRefs(json['after']),
    );
  }

  final String channelId;
  final bool available;
  final List<UserSignalRef> now;
  final List<UserSignalRef> after;

  /// Whether Restore changes this chat at all.
  bool get changes =>
      now.length != after.length ||
      now.any((UserSignalRef ref) => !after.contains(ref));
}

/// `GET /users/@me/signals/restore`.
@immutable
class UserSignalsRestorePreview {
  const UserSignalsRestorePreview({
    required this.available,
    required this.chats,
    this.createdAt,
    this.kind,
    this.signalId,
  });

  factory UserSignalsRestorePreview.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? action =
        json['action'] as Map<String, dynamic>?;
    return UserSignalsRestorePreview(
      available: json['available'] as bool? ?? false,
      createdAt: (json['created_at'] as num?)?.toInt(),
      kind: switch (action?['kind']) {
        'set' => UserSignalsRestoreKind.set,
        'off' => UserSignalsRestoreKind.off,
        'restore' => UserSignalsRestoreKind.restore,
        _ => null,
      },
      signalId: action?['signal_id'] as String?,
      chats: <UserSignalsRestoreChat>[
        for (final Object? item in json['chats'] as List<dynamic>? ?? const [])
          UserSignalsRestoreChat.fromJson(item! as Map<String, dynamic>),
      ],
    );
  }

  final bool available;
  final int? createdAt;
  final UserSignalsRestoreKind? kind;
  final String? signalId;
  final List<UserSignalsRestoreChat> chats;
}
