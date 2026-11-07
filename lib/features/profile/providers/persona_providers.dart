// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_app/features/chat/data/channel_persona_mention_cache.dart';
import 'package:fluxer_app/features/emoji/providers/emoji_pins_provider.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/domain/persona_settings.dart';
import 'package:fluxer_app/features/profile/providers/persona_first_load.dart';
import 'package:fluxer_dart/models/persona_channel_state_update_request_schema.dart';
import 'package:native_natural_sort/native_natural_sort.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PersonaMode {
  manual,
  last;

  static PersonaMode fromString(String? value) {
    return switch (value) {
      'last' => PersonaMode.last,
      _ => PersonaMode.manual,
    };
  }

  String toPrefString() => name;
}

/// Where the selected persona applies: one for every channel, or one
/// remembered per channel.
enum PersonaScope {
  global,
  channel;

  static PersonaScope fromString(String? value) {
    return value == 'channel' ? PersonaScope.channel : PersonaScope.global;
  }

  String toWire() => name;
}

class ActivePersonaState {
  const ActivePersonaState({
    this.mode = PersonaMode.manual,
    this.activePersonaId,
    this.isLatched = false,
    this.frecencyUsage = const {},
    this.scope = PersonaScope.global,
    this.channelPersonaIds = const <String, String>{},
  });

  final PersonaMode mode;
  final String? activePersonaId;
  final bool isLatched;
  final Map<String, ({int count, int lastUsedAtMs})> frecencyUsage;
  final PersonaScope scope;

  /// With [PersonaScope.channel]: the persona selected in each channel. A
  /// channel that is not here is used as the account itself.
  final Map<String, String> channelPersonaIds;

  /// The persona selected for a channel: what an untagged message there is
  /// sent as, and what its composer shows. Everything that acts in a channel
  /// asks this, never [activePersonaId], which is only the selection for
  /// every channel and says nothing about one channel when selections are
  /// kept per channel. Without a channel there is nothing per channel to look
  /// up: the answer is the selection for every channel, or nobody when
  /// selections are per channel.
  String? latchedIdFor(String? channelId) {
    if (scope == PersonaScope.channel) {
      if (channelId == null || channelId.isEmpty) {
        return null;
      }
      return channelPersonaIds[channelId];
    }
    return isLatched ? activePersonaId : null;
  }

  ActivePersonaState copyWith({
    PersonaMode? mode,
    String? Function()? activePersonaId,
    bool? isLatched,
    Map<String, ({int count, int lastUsedAtMs})>? frecencyUsage,
    PersonaScope? scope,
    Map<String, String>? channelPersonaIds,
  }) {
    return ActivePersonaState(
      mode: mode ?? this.mode,
      activePersonaId: activePersonaId != null
          ? activePersonaId()
          : this.activePersonaId,
      isLatched: isLatched ?? this.isLatched,
      frecencyUsage: frecencyUsage ?? this.frecencyUsage,
      scope: scope ?? this.scope,
      channelPersonaIds: channelPersonaIds ?? this.channelPersonaIds,
    );
  }
}

// -----------------------------------------------------------------------------
// MyPersonasNotifier & Provider
// -----------------------------------------------------------------------------

class MyPersonasNotifier extends Notifier<AsyncValue<List<Persona>>> {
  /// Whether the account had personas when the list last loaded on this
  /// device, so a send can tell a late list from an account without personas
  /// (tyne-chat/tyne#30). Like the selection, the key does not name the
  /// account, and [reset] clears it.
  static const _kPrefHadPersonas = 'persona_list_had_personas';

  /// The tags of the account's personas (those whose tags are matched), kept
  /// with [_kPrefHadPersonas] so a send can tell a tagged message while the
  /// list has not loaded.
  static const _kPrefTags = 'persona_list_tags';

  final FirstLoadGate _gate = FirstLoadGate();
  bool _hadPersonas = false;

  /// Whether the account had personas when the list last loaded on this
  /// device: from the device until the list loads, then from the list. A send
  /// asks it without waiting, so a send from an account without personas
  /// goes out at once, as before.
  bool get hadPersonas => _hadPersonas;

  List<PersonaTag> _tags = const <PersonaTag>[];

  /// The tags of the account's personas when the list last loaded on this
  /// device, as [hadPersonas] is kept.
  List<PersonaTag> get knownTags => _tags;

  @override
  AsyncValue<List<Persona>> build() {
    _gate.reset();
    _hadPersonas = false;
    _tags = const <PersonaTag>[];
    unawaited(_readHadPersonas());
    unawaited(_gate.run(_loadPersonas));
    return const AsyncValue.loading();
  }

  /// Whether the list loaded, and how it went is in [state].
  Future<bool> _loadPersonas() async {
    try {
      final Dio dio = ref.read(fluxerDioProvider);
      final Response<dynamic> response = await dio.get<dynamic>(
        '/users/@me/personas',
      );
      final dynamic data = response.data;
      final List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map && data['personas'] is List) {
        list = data['personas'] as List<dynamic>;
      } else {
        list = const [];
      }

      final personas = list
          .map((item) {
            if (item is Map<String, dynamic>) {
              return Persona.fromJson(item);
            }
            if (item is Map) {
              return Persona.fromJson(Map<String, dynamic>.from(item));
            }
            return null;
          })
          .whereType<Persona>()
          .where((p) => !p.isDeleted)
          .toList();

      if (!ref.mounted) {
        return false;
      }
      state = AsyncValue.data(personas);
      _hadPersonas = personas.isNotEmpty;
      _tags = <PersonaTag>[
        for (final Persona p in personas)
          if (!p.autoTagDisabled) ...p.personaTags,
      ];
      unawaited(_rememberHadPersonas(personas.isNotEmpty, _tags));
      return true;
    } on Object catch (err, st) {
      talker.warning(
        '[MyPersonasNotifier] Failed to load personas: $err',
        err,
        st,
      );
      if (!ref.mounted) {
        return false;
      }
      // A reload that fails keeps the list already loaded. Readers take
      // `asData`, which is null for an error even when it carries the old
      // list, so an error here would empty the list for all of them, and an
      // untagged message would go out as the account (tyne-chat/tyne#499).
      if (state.asData == null) {
        state = AsyncValue.error(err, st);
      }
      return false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _gate.run(_loadPersonas);
  }

  Future<void> reloadSilently() async {
    await _gate.run(_loadPersonas);
  }

  /// The list, waiting up to [timeout] for it when it has not loaded yet: a
  /// send must not go out as the account only because the list is late
  /// (tyne-chat/tyne#30). Null if it still has not loaded.
  Future<List<Persona>?> whenLoaded({
    Duration timeout = kPersonaSendWait,
  }) async {
    final List<Persona>? loaded = state.asData?.value;
    if (loaded != null) {
      return loaded;
    }
    await _gate.wait(_loadPersonas, timeout: timeout);
    if (!ref.mounted) {
      return null;
    }
    return state.asData?.value;
  }

  Future<void> _readHadPersonas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool stored = prefs.getBool(_kPrefHadPersonas) ?? false;
      final List<PersonaTag> tags = <PersonaTag>[];
      try {
        for (final Object? item
            in jsonDecode(prefs.getString(_kPrefTags) ?? '[]') as List) {
          if (item is Map<String, dynamic>) {
            tags.add(PersonaTag.fromJson(item));
          }
        }
      } on Object catch (_) {}
      // The list, once it has loaded, knows better than the device.
      if (ref.mounted && state.asData == null) {
        _hadPersonas = stored;
        _tags = tags;
      }
    } on Object catch (_) {}
  }

  Future<void> _rememberHadPersonas(bool had, List<PersonaTag> tags) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPrefHadPersonas, had);
      await prefs.setString(
        _kPrefTags,
        jsonEncode(<Object?>[for (final PersonaTag t in tags) t.toJson()]),
      );
    } on Object catch (_) {}
  }

  void upsertPersona(Persona persona) {
    if (persona.isDeleted) {
      removePersona(persona.id);
      return;
    }
    state.whenData((current) {
      final idx = current.indexWhere((p) => p.id == persona.id);
      if (idx >= 0) {
        final updated = List<Persona>.from(current);
        updated[idx] = persona;
        state = AsyncValue.data(updated);
      } else {
        state = AsyncValue.data([...current, persona]);
      }
    });
  }

  void removePersona(String id) {
    state.whenData((current) {
      state = AsyncValue.data(current.where((p) => p.id != id).toList());
    });
    // Fork: a deleted persona's pinned emojis go too (tyne-chat/tyne#140).
    unawaited(_forgetPinnedEmojis(id));
  }

  Future<void> _forgetPinnedEmojis(String id) async {
    try {
      await ref.read(emojiPinsProvider.notifier).forgetPersona(id);
    } on Object catch (e, st) {
      talker.error("Failed to drop a deleted persona's pins", e, st);
    }
  }

  void reset() {
    state = const AsyncValue.data([]);
    _gate.reset();
    _hadPersonas = false;
    _tags = const <PersonaTag>[];
    unawaited(_forgetHadPersonas());
  }

  Future<void> _forgetHadPersonas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kPrefHadPersonas);
      await prefs.remove(_kPrefTags);
    } on Object catch (_) {}
  }
}

final myPersonasProvider =
    NotifierProvider<MyPersonasNotifier, AsyncValue<List<Persona>>>(
      MyPersonasNotifier.new,
    );

// -----------------------------------------------------------------------------
// ActivePersonaNotifier & Provider
// -----------------------------------------------------------------------------

class ActivePersonaNotifier extends Notifier<ActivePersonaState> {
  static const _kPrefMode = 'persona_active_mode';
  static const _kPrefId = 'persona_active_id';
  static const _kPrefLatched = 'persona_is_latched';
  static const _kPrefFrecency = 'persona_frecency_map';

  @override
  ActivePersonaState build() {
    _channelStatesGate.reset();
    _channelStatesLoaded = false;
    unawaited(_initFromPrefs());
    return const ActivePersonaState();
  }

  final FirstLoadGate _channelStatesGate = FirstLoadGate();
  bool _channelStatesLoaded = false;

  /// Whether the per-channel selections have loaded since the account signed
  /// in (tyne-chat/tyne#30).
  bool get channelStatesLoaded => _channelStatesLoaded;

  Future<void> _initFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString(_kPrefMode);
      final idStr = prefs.getString(_kPrefId);
      final latched = prefs.getBool(_kPrefLatched) ?? false;
      final frecencyStr = prefs.getString(_kPrefFrecency);

      final Map<String, ({int count, int lastUsedAtMs})> frecency = {};
      if (frecencyStr != null && frecencyStr.isNotEmpty) {
        try {
          final decoded = jsonDecode(frecencyStr) as Map<String, dynamic>;
          for (final entry in decoded.entries) {
            final val = entry.value as Map<String, dynamic>;
            frecency[entry.key] = (
              count: (val['count'] as num?)?.toInt() ?? 0,
              lastUsedAtMs: (val['last_used'] as num?)?.toInt() ?? 0,
            );
          }
        } on Object catch (_) {}
      }

      // The scope and the per-channel selections come from the server only.
      // Keep whatever has arrived from there while the preferences were read.
      state = state.copyWith(
        mode: PersonaMode.fromString(modeStr),
        activePersonaId: () => idStr != null && idStr.isNotEmpty ? idStr : null,
        isLatched: latched,
        frecencyUsage: frecency,
      );
    } on Object catch (e) {
      talker.warning('[ActivePersonaNotifier] Error reading prefs: $e');
    }
  }

  void syncFromSettings({
    required PersonaMode mode,
    required String? activeId,
    required bool isLatched,
    PersonaScope? scope,
  }) {
    state = state.copyWith(
      mode: mode,
      activePersonaId: () => activeId,
      isLatched: isLatched,
      scope: scope,
    );
  }

  Future<void> setScope(PersonaScope scope) async {
    if (state.scope == scope) {
      return;
    }
    final PersonaScope previous = state.scope;
    state = state.copyWith(scope: scope);
    try {
      await ref
          .read(personaSettingsProvider.notifier)
          .updateSettings(activePersonaScope: scope.toWire());
    } on Exception catch (err) {
      talker.warning('[ActivePersonaNotifier] Failed to save the scope: $err');
      state = state.copyWith(scope: previous);
    }
  }

  /// Replaces the per-channel selections with what the server holds.
  Future<void> loadChannelStates() async {
    await _channelStatesGate.run(_loadChannelStates);
  }

  Future<bool> _loadChannelStates() async {
    try {
      final response = await ref
          .read(fluxerClientProvider)
          .personas
          .listMyPersonaChannelStates();
      if (!ref.mounted) {
        return false;
      }
      state = state.copyWith(
        channelPersonaIds: <String, String>{
          for (final entry in response.states)
            if (entry.personaId != null) entry.channelId: entry.personaId!,
        },
      );
      _channelStatesLoaded = true;
      return true;
    } on Exception catch (err) {
      talker.warning(
        '[ActivePersonaNotifier] Failed to load channel personas: $err',
      );
      return false;
    }
  }

  /// Whether the per-channel selections have loaded once, waiting up to
  /// [timeout] when they have not: until then a channel without one reads as
  /// the account (tyne-chat/tyne#30).
  Future<bool> whenChannelStatesLoaded({
    Duration timeout = kPersonaSendWait,
  }) async {
    if (_channelStatesLoaded) {
      return true;
    }
    await _channelStatesGate.wait(_loadChannelStates, timeout: timeout);
    return ref.mounted && _channelStatesLoaded;
  }

  /// Another session of this account selected a persona in a channel, or the
  /// server cleared one.
  void applyChannelState(String channelId, String? personaId) {
    if (channelId.isEmpty) {
      return;
    }
    final Map<String, String> next = Map<String, String>.of(
      state.channelPersonaIds,
    );
    if (personaId == null || personaId.isEmpty) {
      next.remove(channelId);
    } else {
      next[channelId] = personaId;
    }
    state = state.copyWith(channelPersonaIds: next);
  }

  /// A thread or post that was just created starts as whoever opened it, when
  /// personas are kept per channel: they have just spoken there.
  void startChannelAs(String channelId, String? personaId) {
    if (state.scope == PersonaScope.channel &&
        channelId.isNotEmpty &&
        personaId != null &&
        personaId.isNotEmpty) {
      unawaited(_selectInChannel(channelId, personaId));
    }
  }

  Future<void> _selectInChannel(String channelId, String? personaId) async {
    applyChannelState(channelId, personaId);
    try {
      await ref
          .read(fluxerClientProvider)
          .personas
          .setMyPersonaChannelState(
            channelId: channelId,
            body: PersonaChannelStateUpdateRequestSchema(personaId: personaId),
          );
    } on Exception catch (err) {
      talker.warning(
        '[ActivePersonaNotifier] Failed to save the channel persona: $err',
      );
      // Ask the server what holds now, instead of putting back a value that
      // may itself be stale.
      await loadChannelStates();
    }
  }

  Future<void> setMode(PersonaMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefMode, mode.toPrefString());

    final currentId = state.activePersonaId;
    final latched = currentId != null && currentId.isNotEmpty;
    await prefs.setBool(_kPrefLatched, latched);
    state = state.copyWith(mode: mode, isLatched: latched);

    try {
      unawaited(
        ref
            .read(personaSettingsProvider.notifier)
            .updateSettings(activePersonaMode: mode.toPrefString()),
      );
    } on Object catch (_) {}
  }

  /// Selects a persona. With the per-channel scope and a [channelId], the
  /// selection is that channel's alone and the one for every channel is left
  /// as it is.
  Future<void> setActivePersona(
    String? id, {
    bool latch = true,
    PersonaMode? mode,
    String? channelId,
  }) async {
    if (state.scope == PersonaScope.channel &&
        channelId != null &&
        channelId.isNotEmpty) {
      await _selectInChannel(
        channelId,
        id != null && id.isNotEmpty && latch ? id : null,
      );
      return;
    }
    final effectiveMode = mode ?? state.mode;
    state = state.copyWith(
      mode: effectiveMode,
      activePersonaId: () => id != null && id.isNotEmpty ? id : null,
      isLatched: id != null && id.isNotEmpty && latch,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefMode, effectiveMode.toPrefString());
    if (id != null && id.isNotEmpty) {
      await prefs.setString(_kPrefId, id);
      await prefs.setBool(_kPrefLatched, latch);
    } else {
      await prefs.remove(_kPrefId);
      await prefs.setBool(_kPrefLatched, false);
    }

    try {
      unawaited(
        ref
            .read(personaSettingsProvider.notifier)
            .updateSettings(
              activePersonaId: () => id != null && id.isNotEmpty ? id : null,
              isLatched: id != null && id.isNotEmpty && latch,
              activePersonaMode: effectiveMode.toPrefString(),
            ),
      );
    } on Object catch (_) {}
  }

  Future<void> unlatch({bool preserveMode = false, String? channelId}) async {
    if (state.scope == PersonaScope.channel &&
        channelId != null &&
        channelId.isNotEmpty) {
      await _selectInChannel(channelId, null);
      return;
    }
    final newMode = state.mode;
    state = state.copyWith(
      mode: newMode,
      activePersonaId: () => null,
      isLatched: false,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefLatched, false);
    await prefs.remove(_kPrefId);

    try {
      unawaited(
        ref
            .read(personaSettingsProvider.notifier)
            .updateSettings(
              isLatched: false,
              activePersonaId: () => null,
              activePersonaMode: newMode.toPrefString(),
            ),
      );
    } on Object catch (_) {}
  }

  Future<void> recordUsage(String personaId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = state.frecencyUsage[personaId];
    final count = (existing?.count ?? 0) + 1;

    final updated = Map<String, ({int count, int lastUsedAtMs})>.from(
      state.frecencyUsage,
    );
    updated[personaId] = (count: count, lastUsedAtMs: now);

    state = state.copyWith(frecencyUsage: updated);

    try {
      final prefs = await SharedPreferences.getInstance();
      final serializable = <String, dynamic>{};
      for (final entry in updated.entries) {
        serializable[entry.key] = {
          'count': entry.value.count,
          'last_used': entry.value.lastUsedAtMs,
        };
      }
      await prefs.setString(_kPrefFrecency, jsonEncode(serializable));
    } on Object catch (_) {}
  }

  Future<void> reset() async {
    state = const ActivePersonaState();
    _channelStatesGate.reset();
    _channelStatesLoaded = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kPrefMode);
      await prefs.remove(_kPrefId);
      await prefs.remove(_kPrefLatched);
      await prefs.remove(_kPrefFrecency);
    } on Object catch (_) {}
  }
}

final activePersonaProvider =
    NotifierProvider<ActivePersonaNotifier, ActivePersonaState>(
      ActivePersonaNotifier.new,
    );

// -----------------------------------------------------------------------------
// Helper Providers
// -----------------------------------------------------------------------------

/// The persona selected for [channelId], as [ActivePersonaState.latchedIdFor]
/// has it, or null for the account itself. A selection whose persona no
/// longer exists counts as the account.
Persona? latchedPersonaFor(
  ActivePersonaState active,
  List<Persona> personas,
  String? channelId,
) {
  final String? id = active.latchedIdFor(channelId);
  if (id == null) {
    return null;
  }
  for (final Persona persona in personas) {
    if (persona.id == id) {
      return persona;
    }
  }
  return null;
}

final _leadingDecoration = RegExp(r'^[^\p{Alphabetic}\p{N}]+', unicode: true);

/// The name as it is filed in sorted lists: without leading symbols or emoji,
/// so "✨Alice" sits with the A's.
String personaSortName(String name) {
  final trimmed = name.trim();
  final stripped = trimmed.replaceFirst(_leadingDecoration, '');
  return stripped.isEmpty ? trimmed : stripped;
}

int comparePersonasByName(Persona a, Persona b) {
  final byName = personaSortName(
    a.name,
  ).toLowerCase().compareTo(personaSortName(b.name).toLowerCase());
  return byName != 0 ? byName : a.id.compareTo(b.id);
}

/// Returns the ids of [personas] ordered by name the way the device's language
/// sorts text.
typedef PersonaNameCollator =
    Future<List<String>> Function(List<Persona> personas);

Future<List<String>> _collatePersonaNamesOnDevice(
  List<Persona> personas,
) async {
  final sorter = NativeSort();
  await sorter.config(const SortOptions());
  final sorted = await sorter.sort([
    for (final p in personas)
      SortItem(id: p.id, value: personaSortName(p.name)),
  ]);
  return [for (final item in sorted) item.id];
}

final personaNameCollatorProvider = Provider<PersonaNameCollator>(
  (ref) => _collatePersonaNamesOnDevice,
);

/// Position of each persona id in the device's name order, or null when the
/// device could not sort them.
final _personaNameOrderProvider = FutureProvider<Map<String, int>?>((
  ref,
) async {
  final personas = ref.watch(myPersonasProvider).asData?.value ?? const [];
  if (personas.length < 2) {
    return null;
  }
  try {
    final ids = await ref.watch(personaNameCollatorProvider)(personas);
    return {for (final (index, id) in ids.indexed) id: index};
  } on Object catch (err, st) {
    talker.warning(
      '[sortedPersonasProvider] Device sort failed, using plain order: $err',
      err,
      st,
    );
    return null;
  }
});

/// Personas by name, for the lists people browse. [myPersonasProvider] keeps
/// the order they were loaded in.
///
/// The order comes from the device's own collator, so it follows the device
/// language like the web client follows the browser's. That answer arrives
/// asynchronously; until it covers every persona this uses
/// [comparePersonasByName].
final sortedPersonasProvider = Provider<List<Persona>>((ref) {
  final personas = ref.watch(myPersonasProvider).asData?.value ?? const [];
  final order = ref.watch(_personaNameOrderProvider).value;
  final sorted = List<Persona>.from(personas);
  if (order == null || personas.any((p) => !order.containsKey(p.id))) {
    return sorted..sort(comparePersonasByName);
  }
  return sorted..sort((a, b) => order[a.id]!.compareTo(order[b.id]!));
});

final rankedPersonasProvider = Provider<List<Persona>>((ref) {
  final personas = ref.watch(myPersonasProvider).asData?.value ?? const [];
  if (personas.isEmpty) {
    return const [];
  }

  final activeState = ref.watch(activePersonaProvider);
  final DateTime now = DateTime.now();

  double calculateFrecency(Persona p) {
    final local = activeState.frecencyUsage[p.id];
    final lastUsed = local?.lastUsedAtMs ?? p.lastUsedAtMs;
    final count = (local?.count ?? 0) + p.useCount;
    return calculatePersonaFrecencyScore(
      useCount: count,
      lastUsedAtMs: lastUsed,
      now: now,
    );
  }

  return List<Persona>.from(personas)..sort((a, b) {
    final scoreA = calculateFrecency(a);
    final scoreB = calculateFrecency(b);
    if ((scoreB - scoreA).abs() > 0.001) {
      return scoreB.compareTo(scoreA);
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
});

// -----------------------------------------------------------------------------
// SystemDisplayTagNotifier & Provider
// -----------------------------------------------------------------------------

class SystemDisplayTag {
  const SystemDisplayTag({this.text, this.iconUrl});

  final String? text;
  final String? iconUrl;

  bool get isEmpty =>
      (text == null || text!.isEmpty) && (iconUrl == null || iconUrl!.isEmpty);
  bool get isNotEmpty => !isEmpty;
}

class SystemDisplayTagNotifier extends Notifier<SystemDisplayTag> {
  static const _kPrefTagText = 'system_display_tag_text';
  static const _kPrefTagIcon = 'system_display_tag_icon';

  @override
  SystemDisplayTag build() {
    unawaited(_initFromPrefs());
    return const SystemDisplayTag();
  }

  Future<void> _initFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedText = prefs.getString(_kPrefTagText);
      final cachedIcon = prefs.getString(_kPrefTagIcon);
      if ((cachedText != null || cachedIcon != null) && state.isEmpty) {
        state = SystemDisplayTag(text: cachedText, iconUrl: cachedIcon);
      }
    } on Object catch (_) {}
  }

  Future<void> _saveToPrefs(String? text, String? icon) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (text != null) {
        await prefs.setString(_kPrefTagText, text);
      } else {
        await prefs.remove(_kPrefTagText);
      }
      if (icon != null) {
        await prefs.setString(_kPrefTagIcon, icon);
      } else {
        await prefs.remove(_kPrefTagIcon);
      }
    } on Object catch (_) {}
  }

  void syncFromSettings({required String? text, required String? iconUrl}) {
    state = SystemDisplayTag(text: text, iconUrl: iconUrl);
    unawaited(_saveToPrefs(text, iconUrl));
  }

  Future<void> updateDisplayTag(String? text, String? iconUrl) async {
    state = SystemDisplayTag(text: text, iconUrl: iconUrl);
    await _saveToPrefs(text, iconUrl);
    await ref
        .read(personaSettingsProvider.notifier)
        .updateSettings(
          displayTagText: text ?? '',
          displayTagIcon: () => iconUrl,
        );
  }

  Future<void> reset() async {
    state = const SystemDisplayTag();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kPrefTagText);
      await prefs.remove(_kPrefTagIcon);
    } on Object catch (_) {}
  }
}

final systemDisplayTagProvider =
    NotifierProvider<SystemDisplayTagNotifier, SystemDisplayTag>(
      SystemDisplayTagNotifier.new,
    );

// -----------------------------------------------------------------------------
// PersonaSettingsNotifier & Provider
// -----------------------------------------------------------------------------

class PersonaSettingsNotifier extends Notifier<AsyncValue<PersonaSettings>> {
  @override
  AsyncValue<PersonaSettings> build() {
    unawaited(_loadSettings());
    return const AsyncValue.loading();
  }

  Future<void> _loadSettings() async {
    try {
      final Dio dio = ref.read(fluxerDioProvider);
      final Response<dynamic> response = await dio.get<dynamic>(
        '/users/@me/personas/settings',
      );
      final dynamic data = response.data;
      if (!ref.mounted) {
        return;
      }
      if (data is Map<String, dynamic>) {
        final settings = PersonaSettings.fromJson(data);
        state = AsyncValue.data(settings);
        _syncToLegacyProviders(settings);
      } else if (data is Map) {
        final settings = PersonaSettings.fromJson(
          Map<String, dynamic>.from(data),
        );
        state = AsyncValue.data(settings);
        _syncToLegacyProviders(settings);
      }
      // The per-channel selections travel with the settings.
      unawaited(ref.read(activePersonaProvider.notifier).loadChannelStates());
    } on Object catch (err, st) {
      talker.warning(
        '[PersonaSettingsNotifier] Failed to load persona settings: $err',
        err,
        st,
      );
      if (!ref.mounted) {
        return;
      }
      state = AsyncValue.error(err, st);
    }
  }

  Future<void> reloadSilently() async {
    await _loadSettings();
  }

  void updateFromGateway(Map<String, dynamic> data) {
    final settings = PersonaSettings.fromJson(data);
    state = AsyncValue.data(settings);
    _syncToLegacyProviders(settings);
  }

  void _syncToLegacyProviders(PersonaSettings settings) {
    ref
        .read(activePersonaProvider.notifier)
        .syncFromSettings(
          mode: PersonaMode.fromString(settings.activePersonaMode),
          activeId: settings.activePersonaId,
          isLatched: settings.isLatched,
          scope: PersonaScope.fromString(settings.activePersonaScope),
        );
    ref
        .read(systemDisplayTagProvider.notifier)
        .syncFromSettings(
          text: settings.displayTagText,
          iconUrl: settings.displayTagIcon,
        );
  }

  Future<void> updateSettings({
    String? activePersonaMode,
    String? activePersonaScope,
    String? Function()? activePersonaId,
    bool? isLatched,
    String? displayTagText,
    String? Function()? displayTagIcon,
  }) async {
    final current = state.asData?.value ?? const PersonaSettings();
    final updated = current.copyWith(
      activePersonaMode: activePersonaMode,
      activePersonaScope: activePersonaScope,
      activePersonaId: activePersonaId,
      isLatched: isLatched,
      displayTagText: displayTagText,
      displayTagIcon: displayTagIcon,
    );
    state = AsyncValue.data(updated);
    _syncToLegacyProviders(updated);

    try {
      final Dio dio = ref.read(fluxerDioProvider);
      final body = <String, dynamic>{
        'active_persona_mode': ?activePersonaMode,
        'active_persona_scope': ?activePersonaScope,
        if (activePersonaId != null) 'active_persona_id': activePersonaId(),
        'is_latched': ?isLatched,
        'display_tag_text': ?displayTagText,
        if (displayTagIcon != null) 'display_tag_icon': displayTagIcon(),
      };
      await dio.patch<dynamic>('/users/@me/personas/settings', data: body);
    } catch (err, st) {
      talker.error(
        '[PersonaSettingsNotifier] Failed to update settings: $err',
        err,
        st,
      );
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadSettings();
  }

  void reset() {
    state = const AsyncValue.data(PersonaSettings());
  }
}

final personaSettingsProvider =
    NotifierProvider<PersonaSettingsNotifier, AsyncValue<PersonaSettings>>(
      PersonaSettingsNotifier.new,
    );
