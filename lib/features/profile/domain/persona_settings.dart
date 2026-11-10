// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/foundation.dart';

@immutable
class PersonaSettings {
  const PersonaSettings({
    this.userId = '',
    this.activePersonaMode = 'manual',
    this.activePersonaScope = 'global',
    this.activePersonaId,
    this.isLatched = false,
    this.displayTagText = '',
    this.displayTagIcon,
    this.multiPersonaReactions = true,
  });

  final String userId;
  final String activePersonaMode;

  /// `global`: one selected persona for every channel. `channel`: each channel
  /// remembers its own.
  final String activePersonaScope;
  final String? activePersonaId;
  final bool isLatched;
  final String displayTagText;
  final String? displayTagIcon;

  /// "React as several personas at once" (tyne-chat/tyne#86). Off: one
  /// reaction per emoji for the whole account.
  final bool multiPersonaReactions;

  factory PersonaSettings.fromJson(Map<String, dynamic> json) {
    return PersonaSettings(
      userId: (json['user_id'] as String?) ?? '',
      activePersonaMode: (json['active_persona_mode'] as String?) ?? 'manual',
      activePersonaScope: (json['active_persona_scope'] as String?) == 'channel'
          ? 'channel'
          : 'global',
      activePersonaId: json['active_persona_id'] as String?,
      isLatched: (json['is_latched'] as bool?) ?? false,
      displayTagText: (json['display_tag_text'] as String?) ?? '',
      displayTagIcon: json['display_tag_icon'] as String?,
      multiPersonaReactions: (json['multi_persona_reactions'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'user_id': userId,
      'active_persona_mode': activePersonaMode,
      'active_persona_scope': activePersonaScope,
      if (activePersonaId != null) 'active_persona_id': activePersonaId,
      'is_latched': isLatched,
      'display_tag_text': displayTagText,
      if (displayTagIcon != null) 'display_tag_icon': displayTagIcon,
      'multi_persona_reactions': multiPersonaReactions,
    };
  }

  PersonaSettings copyWith({
    String? userId,
    String? activePersonaMode,
    String? activePersonaScope,
    String? Function()? activePersonaId,
    bool? isLatched,
    String? displayTagText,
    String? Function()? displayTagIcon,
    bool? multiPersonaReactions,
  }) {
    return PersonaSettings(
      userId: userId ?? this.userId,
      activePersonaMode: activePersonaMode ?? this.activePersonaMode,
      activePersonaScope: activePersonaScope ?? this.activePersonaScope,
      activePersonaId: activePersonaId != null
          ? activePersonaId()
          : this.activePersonaId,
      isLatched: isLatched ?? this.isLatched,
      displayTagText: displayTagText ?? this.displayTagText,
      displayTagIcon: displayTagIcon != null
          ? displayTagIcon()
          : this.displayTagIcon,
      multiPersonaReactions:
          multiPersonaReactions ?? this.multiPersonaReactions,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonaSettings &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          activePersonaMode == other.activePersonaMode &&
          activePersonaScope == other.activePersonaScope &&
          activePersonaId == other.activePersonaId &&
          isLatched == other.isLatched &&
          displayTagText == other.displayTagText &&
          displayTagIcon == other.displayTagIcon &&
          multiPersonaReactions == other.multiPersonaReactions;

  @override
  int get hashCode => Object.hash(
    userId,
    activePersonaMode,
    activePersonaScope,
    activePersonaId,
    isLatched,
    displayTagText,
    displayTagIcon,
    multiPersonaReactions,
  );
}
