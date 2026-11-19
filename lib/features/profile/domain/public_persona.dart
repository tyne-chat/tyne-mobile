import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/domain/persona_mention_setting.dart';
import 'package:fluxer_app/features/profile/domain/persona_name_search.dart';

// Tells copyWith to keep a nullable field, so it can still be set to null.
const Object _keep = Object();

class PublicPersona {
  const PublicPersona({
    required this.id,
    required this.name,
    this.avatarHash,
    this.bannerHash,
    this.displayTagText,
    this.displayTagIcon,
    this.aliases = const <String>[],
    this.pronouns,
    this.color,
    this.avatarColor,
    this.bio,
    this.visibility,
    this.mentionableBy,
    this.autoTagDisabled = false,
    this.personaTags = const [],
    this.signatureEmojis = const [],
  });

  final String id;
  final String name;
  final String? avatarHash;
  final String? bannerHash;
  final String? displayTagText;
  final String? displayTagIcon;

  /// Other names to find the persona by when searching or mentioning; never
  /// shown (tyne-chat/tyne#707).
  final List<String> aliases;
  final String? pronouns;
  final int? color;
  final int? avatarColor;
  final String? bio;
  final String? visibility;

  /// Who gets it in mention suggestions, as stored (tyne-chat/tyne#652); null
  /// follows [visibility]. Only the owner's own personas carry it.
  final String? mentionableBy;
  final bool autoTagDisabled;
  final List<PersonaTag> personaTags;
  final List<SignatureEmoji> signatureEmojis;

  factory PublicPersona.fromJson(Map<String, dynamic> json) {
    final rawTags =
        json['persona_tags'] as List<dynamic>? ??
        json['personaTags'] as List<dynamic>? ??
        const [];
    final tags = rawTags
        .map((t) {
          if (t is Map<String, dynamic>) {
            return PersonaTag.fromJson(t);
          }
          if (t is Map) {
            return PersonaTag.fromJson(Map<String, dynamic>.from(t));
          }
          return null;
        })
        .whereType<PersonaTag>()
        .toList();

    final rawSigs =
        json['signature_emojis'] as List<dynamic>? ??
        json['signatureEmojis'] as List<dynamic>? ??
        const [];
    final sigs = rawSigs
        .map((s) {
          if (s is Map<String, dynamic>) {
            return SignatureEmoji.fromJson(s);
          }
          if (s is Map) {
            return SignatureEmoji.fromJson(Map<String, dynamic>.from(s));
          }
          return null;
        })
        .whereType<SignatureEmoji>()
        .toList();

    return PublicPersona(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatarHash:
          (json['avatar_hash'] as String?) ?? (json['avatar'] as String?),
      bannerHash:
          (json['banner_hash'] as String?) ?? (json['banner'] as String?),
      displayTagText: json['display_tag_text'] as String?,
      displayTagIcon: json['display_tag_icon'] as String?,
      aliases: personaAliasesFromJson(json['aliases']),
      pronouns: json['pronouns'] as String?,
      color: (json['color'] as num?)?.toInt(),
      avatarColor:
          (json['avatar_color'] as num?)?.toInt() ??
          (json['avatarColor'] as num?)?.toInt(),
      bio: json['bio'] as String?,
      visibility: json['visibility'] as String?,
      mentionableBy: personaMentionableByFromJson(json['mentionable_by']),
      autoTagDisabled: json['auto_tag_disabled'] as bool? ?? false,
      personaTags: tags,
      signatureEmojis: sigs,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      if (avatarHash != null) 'avatar_hash': avatarHash,
      if (bannerHash != null) 'banner_hash': bannerHash,
      if (displayTagText != null) 'display_tag_text': displayTagText,
      if (displayTagIcon != null) 'display_tag_icon': displayTagIcon,
      if (aliases.isNotEmpty) 'aliases': aliases,
      if (pronouns != null) 'pronouns': pronouns,
      if (color != null) 'color': color,
      if (avatarColor != null) 'avatar_color': avatarColor,
      if (bio != null) 'bio': bio,
      if (visibility != null) 'visibility': visibility,
      if (mentionableBy != null) 'mentionable_by': mentionableBy,
      'auto_tag_disabled': autoTagDisabled,
      'persona_tags': personaTags.map((t) => t.toJson()).toList(),
      'signature_emojis': signatureEmojis.map((s) => s.toJson()).toList(),
    };
  }

  PublicPersona copyWith({
    String? id,
    String? name,
    String? avatarHash,
    String? bannerHash,
    String? displayTagText,
    String? displayTagIcon,
    List<String>? aliases,
    String? pronouns,
    int? color,
    int? avatarColor,
    String? bio,
    String? visibility,
    Object? mentionableBy = _keep,
    bool? autoTagDisabled,
    List<PersonaTag>? personaTags,
    List<SignatureEmoji>? signatureEmojis,
  }) {
    return PublicPersona(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarHash: avatarHash ?? this.avatarHash,
      bannerHash: bannerHash ?? this.bannerHash,
      displayTagText: displayTagText ?? this.displayTagText,
      displayTagIcon: displayTagIcon ?? this.displayTagIcon,
      aliases: aliases ?? this.aliases,
      pronouns: pronouns ?? this.pronouns,
      color: color ?? this.color,
      avatarColor: avatarColor ?? this.avatarColor,
      bio: bio ?? this.bio,
      visibility: visibility ?? this.visibility,
      mentionableBy: identical(mentionableBy, _keep)
          ? this.mentionableBy
          : mentionableBy as String?,
      autoTagDisabled: autoTagDisabled ?? this.autoTagDisabled,
      personaTags: personaTags ?? this.personaTags,
      signatureEmojis: signatureEmojis ?? this.signatureEmojis,
    );
  }

  Persona toPersona({int useCount = 0, int? lastUsedAtMs}) {
    return Persona(
      id: id,
      name: name,
      avatarHash: avatarHash,
      bannerHash: bannerHash,
      aliases: aliases,
      pronouns: pronouns,
      color: color,
      avatarColor: avatarColor,
      bio: bio,
      visibility: visibility ?? 'unlisted',
      mentionableBy: mentionableBy,
      autoTagDisabled: autoTagDisabled,
      personaTags: personaTags,
      signatureEmojis: signatureEmojis,
      useCount: useCount,
      lastUsedAtMs: lastUsedAtMs,
    );
  }
}
