// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: how the "Personas (N)" gallery lays its personas out, remembered on
// this device for every account and profile (tyne-chat/tyne#189).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/features/profile/domain/persona_gallery.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersonaGalleryViewNotifier extends Notifier<PersonaGalleryView> {
  /// Holds the view's name, never its position.
  static const String prefKey = 'persona_gallery_view';

  bool _chosen = false;

  @override
  PersonaGalleryView build() {
    _chosen = false;
    unawaited(_restore());
    return PersonaGalleryView.gallery;
  }

  Future<void> _restore() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? saved = prefs.getString(prefKey);
      if (!ref.mounted || _chosen || saved == null) {
        return;
      }
      for (final PersonaGalleryView view in PersonaGalleryView.values) {
        if (view.name == saved) {
          state = view;
          return;
        }
      }
    } on Object catch (_) {
      // The default stays.
    }
  }

  /// Shows the gallery as [view] from now on, on this device.
  Future<void> choose(PersonaGalleryView view) async {
    _chosen = true;
    state = view;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefKey, view.name);
    } on Object catch (_) {
      // Kept for this session only.
    }
  }
}

final NotifierProvider<PersonaGalleryViewNotifier, PersonaGalleryView>
personaGalleryViewProvider =
    NotifierProvider<PersonaGalleryViewNotifier, PersonaGalleryView>(
      PersonaGalleryViewNotifier.new,
    );
