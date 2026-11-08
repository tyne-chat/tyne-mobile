// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: an account's public personas and display tag, for its profile's
// "Personas (N)" pill, row and gallery (tyne-chat/tyne#189), from
// `GET /users/:id/personas`.
//
// Requests: one per profile opened. Everything that shows the list on screen
// at once (the pill, the row, the gallery) shares that request, and the
// answer is kept a minute after the last of them goes, so going back and
// forth between a profile and its gallery asks nothing more. A failed request
// is not repeated by itself: the row offers Retry, and closing and reopening
// the profile asks again. When the account's personas change
// (`GUILD_PERSONAS_DIRTY`), its list is dropped once the burst of copies of
// that event is over, and fetched again only where it is on screen. Your own
// profile reads your own list (`myPersonasProvider`) and asks nothing.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_app/features/profile/data/persona_refresh.dart'
    show personaRefreshDelayProvider;
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/domain/persona_gallery.dart';
import 'package:fluxer_app/features/profile/domain/public_persona.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';

/// An account's public personas, the most used first, and its display tag.
@immutable
class PublicPersonaList {
  const PublicPersonaList({
    required this.personas,
    this.displayTagText,
    this.displayTagIcon,
  });

  /// Reads the server's answer. Anything that is not a persona is left out.
  factory PublicPersonaList.fromJson(Object? data) {
    if (data is! Map) {
      return const PublicPersonaList(personas: <PublicPersona>[]);
    }
    final Object? rawPersonas = data['personas'];
    final List<PublicPersona> personas = <PublicPersona>[
      if (rawPersonas is List)
        for (final Object? item in rawPersonas)
          if (item is Map)
            PublicPersona.fromJson(Map<String, dynamic>.from(item)),
    ];
    String? text(Object? value) {
      final String? trimmed = value is String ? value.trim() : null;
      return trimmed == null || trimmed.isEmpty ? null : trimmed;
    }

    return PublicPersonaList(
      personas: personas
          .where((PublicPersona p) => p.id.isNotEmpty)
          .toList(growable: false),
      displayTagText: text(data['display_tag_text']),
      displayTagIcon: text(data['display_tag_icon']),
    );
  }

  /// Public personas only, in the server's order: the most used first.
  final List<PublicPersona> personas;
  final String? displayTagText;

  /// The hash of the display tag icon; draw it through `personaTagIconUrl`.
  final String? displayTagIcon;
}

/// How asking for an account's public personas went.
@immutable
sealed class PublicPersonaListResult {
  const PublicPersonaListResult();
}

/// The account's list.
final class PublicPersonaListLoaded extends PublicPersonaListResult {
  const PublicPersonaListLoaded(this.list);

  final PublicPersonaList list;
}

/// The viewer may not see the account's profile: nothing about its personas
/// shows.
final class PublicPersonaListForbidden extends PublicPersonaListResult {
  const PublicPersonaListForbidden();
}

/// The request failed; it is repeated only when someone asks (Retry) or the
/// profile is opened again.
final class PublicPersonaListFailed extends PublicPersonaListResult {
  const PublicPersonaListFailed();
}

/// How long a list stays after nothing shows it any more; tests change it.
final Provider<Duration> publicPersonaListKeepAliveProvider =
    Provider<Duration>((Ref ref) => const Duration(seconds: 60));

/// An account's public personas and display tag, by account id. See the top
/// of this file for when it asks the server.
final FutureProviderFamily<PublicPersonaListResult, String>
publicPersonaListProvider = FutureProvider.autoDispose
    .family<PublicPersonaListResult, String>(
      (Ref ref, String userId) async {
        // What the server shows depends on who asks.
        ref.watch(currentUserIdProvider);
        final Duration keepFor = ref.watch(publicPersonaListKeepAliveProvider);
        if (userId.isEmpty) {
          return const PublicPersonaListFailed();
        }
        final KeepAliveLink link = ref.keepAlive();
        Timer? release;
        ref
          ..onCancel(() {
            release?.cancel();
            release = Timer(keepFor, link.close);
          })
          ..onResume(() {
            release?.cancel();
            release = null;
          })
          ..onDispose(() => release?.cancel());
        try {
          final Dio dio = ref.watch(fluxerDioProvider);
          final Response<dynamic> response = await dio.get<dynamic>(
            '/users/$userId/personas',
          );
          return PublicPersonaListLoaded(
            PublicPersonaList.fromJson(response.data),
          );
        } on DioException catch (err, st) {
          if (err.response?.statusCode == 403) {
            return const PublicPersonaListForbidden();
          }
          talker.warning(
            '[publicPersonaListProvider] Failed to fetch the personas of $userId: $err',
            err,
            st,
          );
        } on Object catch (err, st) {
          talker.warning(
            '[publicPersonaListProvider] Failed to read the personas of $userId: $err',
            err,
            st,
          );
        }
        // A failure is not kept once nothing shows it, so the next profile
        // opened asks again.
        link.close();
        return const PublicPersonaListFailed();
      },
      // Failures are answers here, never errors, so Riverpod has nothing to
      // repeat; and it must not.
      retry: (int retryCount, Object error) => null,
    );

/// Fork: drops an account's list when its personas change, once the copies
/// of the event (one per shared community, all at once) have stopped
/// arriving, so the list is fetched again once, not once per copy.
class PublicPersonaListRefresher {
  PublicPersonaListRefresher({required this.invalidate, required this.delay});

  /// Drops the list of the account with this id.
  final void Function(String userId) invalidate;
  final Duration delay;

  final Set<String> _pending = <String>{};
  Timer? _timer;

  /// The list of [userId] changed.
  void request(String userId) {
    if (userId.isEmpty) {
      return;
    }
    _pending.add(userId);
    _timer ??= Timer(delay, _flush);
  }

  void _flush() {
    _timer = null;
    final List<String> userIds = _pending.toList(growable: false);
    _pending.clear();
    userIds.forEach(invalidate);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _pending.clear();
  }
}

/// Fork: the refresher for [publicPersonaListProvider].
final Provider<PublicPersonaListRefresher> publicPersonaListRefresherProvider =
    Provider<PublicPersonaListRefresher>((Ref ref) {
      final PublicPersonaListRefresher refresher = PublicPersonaListRefresher(
        invalidate: (String userId) =>
            ref.invalidate(publicPersonaListProvider(userId)),
        delay: ref.watch(personaRefreshDelayProvider),
      );
      ref.onDispose(refresher.dispose);
      return refresher;
    });

/// Whose personas a profile's pill, row and gallery show, what the gallery
/// needs to draw a persona that has no avatar of its own (the account's), and
/// the community the profile was opened in, if any.
typedef PersonaGalleryOwner = ({
  String userId,
  bool isSelf,
  String name,
  String? avatarUrl,
  int? avatarColor,
  String? guildId,
});

/// What a profile shows of an account's personas: its display tag, and
/// whether and with which count it shows "Personas (N)".
@immutable
class PersonaGallerySummary {
  const PersonaGallerySummary({
    this.visible = false,
    this.count = 0,
    this.failed = false,
    this.displayTagText,
    this.displayTagIcon,
  });

  /// Whether the pill and the row show: for others when they have a public
  /// persona, on your own profile always.
  final bool visible;

  /// The number of public personas.
  final int count;

  /// The list could not be loaded: the row offers Retry, the pill hides.
  final bool failed;
  final String? displayTagText;

  /// The hash of the display tag icon.
  final String? displayTagIcon;
}

/// What an account's profile shows of its personas. Your own comes from your
/// own list and settings, anyone else's from [publicPersonaListProvider].
final ProviderFamily<PersonaGallerySummary, ({String userId, bool isSelf})>
personaGallerySummaryProvider = Provider.autoDispose
    .family<PersonaGallerySummary, ({String userId, bool isSelf})>((
      Ref ref,
      ({String userId, bool isSelf}) owner,
    ) {
      if (owner.isSelf) {
        final List<Persona> personas =
            ref.watch(myPersonasProvider).asData?.value ?? const <Persona>[];
        final SystemDisplayTag tag = ref.watch(systemDisplayTagProvider);
        return PersonaGallerySummary(
          visible: true,
          count: personas.where(isPublicPersona).length,
          displayTagText: tag.text,
          displayTagIcon: tag.iconUrl,
        );
      }
      final PublicPersonaListResult? result = ref
          .watch(publicPersonaListProvider(owner.userId))
          .value;
      return switch (result) {
        null || PublicPersonaListForbidden() => const PersonaGallerySummary(),
        PublicPersonaListFailed() => const PersonaGallerySummary(failed: true),
        PublicPersonaListLoaded(:final PublicPersonaList list) =>
          PersonaGallerySummary(
            visible: list.personas.isNotEmpty,
            count: list.personas.length,
            displayTagText: list.displayTagText,
            displayTagIcon: list.displayTagIcon,
          ),
      };
    });
