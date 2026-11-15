// This is a generated file - do not edit.
//
// Generated from fluxer/user/preferences/v1/preferences.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use permissionLayoutModeDescriptor instead')
const PermissionLayoutMode$json = {
  '1': 'PermissionLayoutMode',
  '2': [
    {'1': 'PERMISSION_LAYOUT_MODE_UNSPECIFIED', '2': 0},
    {'1': 'PERMISSION_LAYOUT_MODE_COMFY', '2': 1},
    {'1': 'PERMISSION_LAYOUT_MODE_DENSE', '2': 2},
  ],
};

/// Descriptor for `PermissionLayoutMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List permissionLayoutModeDescriptor = $convert.base64Decode(
    'ChRQZXJtaXNzaW9uTGF5b3V0TW9kZRImCiJQRVJNSVNTSU9OX0xBWU9VVF9NT0RFX1VOU1BFQ0'
    'lGSUVEEAASIAocUEVSTUlTU0lPTl9MQVlPVVRfTU9ERV9DT01GWRABEiAKHFBFUk1JU1NJT05f'
    'TEFZT1VUX01PREVfREVOU0UQAg==');

@$core.Deprecated('Use permissionGridModeDescriptor instead')
const PermissionGridMode$json = {
  '1': 'PermissionGridMode',
  '2': [
    {'1': 'PERMISSION_GRID_MODE_UNSPECIFIED', '2': 0},
    {'1': 'PERMISSION_GRID_MODE_SINGLE', '2': 1},
    {'1': 'PERMISSION_GRID_MODE_GRID', '2': 2},
  ],
};

/// Descriptor for `PermissionGridMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List permissionGridModeDescriptor = $convert.base64Decode(
    'ChJQZXJtaXNzaW9uR3JpZE1vZGUSJAogUEVSTUlTU0lPTl9HUklEX01PREVfVU5TUEVDSUZJRU'
    'QQABIfChtQRVJNSVNTSU9OX0dSSURfTU9ERV9TSU5HTEUQARIdChlQRVJNSVNTSU9OX0dSSURf'
    'TU9ERV9HUklEEAI=');

@$core.Deprecated('Use guildMemberViewModeDescriptor instead')
const GuildMemberViewMode$json = {
  '1': 'GuildMemberViewMode',
  '2': [
    {'1': 'GUILD_MEMBER_VIEW_MODE_UNSPECIFIED', '2': 0},
    {'1': 'GUILD_MEMBER_VIEW_MODE_TABLE', '2': 1},
    {'1': 'GUILD_MEMBER_VIEW_MODE_GRID', '2': 2},
  ],
};

/// Descriptor for `GuildMemberViewMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List guildMemberViewModeDescriptor = $convert.base64Decode(
    'ChNHdWlsZE1lbWJlclZpZXdNb2RlEiYKIkdVSUxEX01FTUJFUl9WSUVXX01PREVfVU5TUEVDSU'
    'ZJRUQQABIgChxHVUlMRF9NRU1CRVJfVklFV19NT0RFX1RBQkxFEAESHwobR1VJTERfTUVNQkVS'
    'X1ZJRVdfTU9ERV9HUklEEAI=');

@$core.Deprecated('Use mfaMethodDescriptor instead')
const MfaMethod$json = {
  '1': 'MfaMethod',
  '2': [
    {'1': 'MFA_METHOD_UNSPECIFIED', '2': 0},
    {'1': 'MFA_METHOD_TOTP', '2': 1},
    {'1': 'MFA_METHOD_WEBAUTHN', '2': 3},
  ],
};

/// Descriptor for `MfaMethod`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List mfaMethodDescriptor = $convert.base64Decode(
    'CglNZmFNZXRob2QSGgoWTUZBX01FVEhPRF9VTlNQRUNJRklFRBAAEhMKD01GQV9NRVRIT0RfVE'
    '9UUBABEhcKE01GQV9NRVRIT0RfV0VCQVVUSE4QAw==');

@$core.Deprecated('Use doubleTapActionDescriptor instead')
const DoubleTapAction$json = {
  '1': 'DoubleTapAction',
  '2': [
    {'1': 'DOUBLE_TAP_ACTION_UNSPECIFIED', '2': 0},
    {'1': 'DOUBLE_TAP_ACTION_REACT', '2': 1},
    {'1': 'DOUBLE_TAP_ACTION_EDIT', '2': 2},
    {'1': 'DOUBLE_TAP_ACTION_NONE', '2': 3},
  ],
};

/// Descriptor for `DoubleTapAction`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List doubleTapActionDescriptor = $convert.base64Decode(
    'Cg9Eb3VibGVUYXBBY3Rpb24SIQodRE9VQkxFX1RBUF9BQ1RJT05fVU5TUEVDSUZJRUQQABIbCh'
    'dET1VCTEVfVEFQX0FDVElPTl9SRUFDVBABEhoKFkRPVUJMRV9UQVBfQUNUSU9OX0VESVQQAhIa'
    'ChZET1VCTEVfVEFQX0FDVElPTl9OT05FEAM=');

@$core.Deprecated('Use swipeActionDescriptor instead')
const SwipeAction$json = {
  '1': 'SwipeAction',
  '2': [
    {'1': 'SWIPE_ACTION_UNSPECIFIED', '2': 0},
    {'1': 'SWIPE_ACTION_CHANNEL_DETAILS', '2': 1},
    {'1': 'SWIPE_ACTION_REPLY', '2': 2},
  ],
};

/// Descriptor for `SwipeAction`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List swipeActionDescriptor = $convert.base64Decode(
    'CgtTd2lwZUFjdGlvbhIcChhTV0lQRV9BQ1RJT05fVU5TUEVDSUZJRUQQABIgChxTV0lQRV9BQ1'
    'RJT05fQ0hBTk5FTF9ERVRBSUxTEAESFgoSU1dJUEVfQUNUSU9OX1JFUExZEAI=');

@$core.Deprecated('Use syncedPreferencesDescriptor instead')
const SyncedPreferences$json = {
  '1': 'SyncedPreferences',
  '2': [
    {
      '1': 'emoji_pins',
      '3': 2200,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.EmojiPinsState',
      '10': 'emojiPins'
    },
    {
      '1': 'accessibility',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.AccessibilitySettings',
      '10': 'accessibility'
    },
    {
      '1': 'accessibility_overrides',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.AccessibilityOverrides',
      '10': 'accessibilityOverrides'
    },
    {
      '1': 'textual_preview',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.TextualPreviewSettings',
      '10': 'textualPreview'
    },
    {
      '1': 'emoji_picker',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.EmojiPickerState',
      '10': 'emojiPicker'
    },
    {
      '1': 'sticker_picker',
      '3': 21,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.StickerPickerState',
      '10': 'stickerPicker'
    },
    {
      '1': 'memes_picker',
      '3': 22,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.MemesPickerState',
      '10': 'memesPicker'
    },
    {
      '1': 'emoji',
      '3': 23,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.EmojiState',
      '10': 'emoji'
    },
    {
      '1': 'emoji_sticker_layout',
      '3': 24,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.EmojiStickerLayoutSettings',
      '10': 'emojiStickerLayout'
    },
    {
      '1': 'favorite_gifs',
      '3': 25,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.FavoriteGifSettings',
      '10': 'favoriteGifs'
    },
    {
      '1': 'favorites',
      '3': 40,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.FavoritesState',
      '10': 'favorites'
    },
    {
      '1': 'recent_mentions',
      '3': 41,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.RecentMentionsSettings',
      '10': 'recentMentions'
    },
    {
      '1': 'sidebar',
      '3': 42,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.SidebarPreferences',
      '10': 'sidebar'
    },
    {
      '1': 'member_list',
      '3': 43,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.MemberListState',
      '10': 'memberList'
    },
    {
      '1': 'unread_channels',
      '3': 44,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.UnreadChannelsState',
      '10': 'unreadChannels'
    },
    {
      '1': 'mention_frecency',
      '3': 45,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.MentionFrecencyState',
      '10': 'mentionFrecency'
    },
    {
      '1': 'nagbars',
      '3': 60,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.NagbarDismissals',
      '10': 'nagbars'
    },
    {
      '1': 'dismissed_upsells',
      '3': 61,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.DismissedUpsells',
      '10': 'dismissedUpsells'
    },
    {
      '1': 'guild_nsfw_agreements',
      '3': 62,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.GuildNsfwAgreements',
      '10': 'guildNsfwAgreements'
    },
    {
      '1': 'whats_new',
      '3': 63,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.WhatsNewState',
      '10': 'whatsNew'
    },
    {
      '1': 'privacy',
      '3': 80,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.PrivacyPreferences',
      '10': 'privacy'
    },
    {
      '1': 'local_spam_overrides',
      '3': 81,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.LocalUserSpamOverrides',
      '10': 'localSpamOverrides'
    },
    {'1': 'sanitize_urls', '3': 82, '4': 1, '5': 8, '10': 'sanitizeUrls'},
    {
      '1': 'sound',
      '3': 100,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.SoundSettings',
      '10': 'sound'
    },
    {
      '1': 'spellcheck',
      '3': 101,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.SpellcheckSettings',
      '10': 'spellcheck'
    },
    {
      '1': 'search_engines',
      '3': 102,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.SearchEngineSettings',
      '10': 'searchEngines'
    },
    {
      '1': 'permission_layout',
      '3': 103,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.PermissionLayoutSettings',
      '10': 'permissionLayout'
    },
    {
      '1': 'guild_member_layout',
      '3': 104,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.GuildMemberLayoutSettings',
      '10': 'guildMemberLayout'
    },
    {
      '1': 'guild_folders',
      '3': 105,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.GuildFolderExpandedState',
      '10': 'guildFolders'
    },
    {
      '1': 'hidden_guild_buttons',
      '3': 106,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.HiddenGuildListButtons',
      '10': 'hiddenGuildButtons'
    },
    {
      '1': 'keyboard_mode_intro',
      '3': 107,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.KeyboardModeIntroState',
      '10': 'keyboardModeIntro'
    },
    {
      '1': 'input_monitoring',
      '3': 108,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.InputMonitoringPromptsState',
      '10': 'inputMonitoring'
    },
    {
      '1': 'voice_prompts',
      '3': 109,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.VoicePromptsState',
      '10': 'voicePrompts'
    },
    {
      '1': 'sudo_prompt',
      '3': 110,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.SudoPromptState',
      '10': 'sudoPrompt'
    },
    {
      '1': 'keybinds',
      '3': 111,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.KeybindSettings',
      '10': 'keybinds'
    },
    {
      '1': 'chat_input',
      '3': 112,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.ChatInputSettings',
      '10': 'chatInput'
    },
    {
      '1': 'double_tap_reaction',
      '3': 114,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.ReactionEmoji',
      '10': 'doubleTapReaction'
    },
    {
      '1': 'channel_frecency',
      '3': 115,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.ChannelFrecencyState',
      '10': 'channelFrecency'
    },
    {
      '1': 'announcement_prompts',
      '3': 116,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.AnnouncementPromptsState',
      '10': 'announcementPrompts'
    },
    {
      '1': 'double_tap_action',
      '3': 117,
      '4': 1,
      '5': 14,
      '6': '.fluxer.user.preferences.v1.DoubleTapAction',
      '10': 'doubleTapAction'
    },
    {
      '1': 'swipe_right_to_left_action',
      '3': 118,
      '4': 1,
      '5': 14,
      '6': '.fluxer.user.preferences.v1.SwipeAction',
      '10': 'swipeRightToLeftAction'
    },
  ],
};

/// Descriptor for `SyncedPreferences`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncedPreferencesDescriptor = $convert.base64Decode(
    'ChFTeW5jZWRQcmVmZXJlbmNlcxJKCgplbW9qaV9waW5zGJgRIAEoCzIqLmZsdXhlci51c2VyLn'
    'ByZWZlcmVuY2VzLnYxLkVtb2ppUGluc1N0YXRlUgllbW9qaVBpbnMSVwoNYWNjZXNzaWJpbGl0'
    'eRgBIAEoCzIxLmZsdXhlci51c2VyLnByZWZlcmVuY2VzLnYxLkFjY2Vzc2liaWxpdHlTZXR0aW'
    '5nc1INYWNjZXNzaWJpbGl0eRJrChdhY2Nlc3NpYmlsaXR5X292ZXJyaWRlcxgCIAEoCzIyLmZs'
    'dXhlci51c2VyLnByZWZlcmVuY2VzLnYxLkFjY2Vzc2liaWxpdHlPdmVycmlkZXNSFmFjY2Vzc2'
    'liaWxpdHlPdmVycmlkZXMSWwoPdGV4dHVhbF9wcmV2aWV3GAMgASgLMjIuZmx1eGVyLnVzZXIu'
    'cHJlZmVyZW5jZXMudjEuVGV4dHVhbFByZXZpZXdTZXR0aW5nc1IOdGV4dHVhbFByZXZpZXcSTw'
    'oMZW1vamlfcGlja2VyGBQgASgLMiwuZmx1eGVyLnVzZXIucHJlZmVyZW5jZXMudjEuRW1vamlQ'
    'aWNrZXJTdGF0ZVILZW1vamlQaWNrZXISVQoOc3RpY2tlcl9waWNrZXIYFSABKAsyLi5mbHV4ZX'
    'IudXNlci5wcmVmZXJlbmNlcy52MS5TdGlja2VyUGlja2VyU3RhdGVSDXN0aWNrZXJQaWNrZXIS'
    'TwoMbWVtZXNfcGlja2VyGBYgASgLMiwuZmx1eGVyLnVzZXIucHJlZmVyZW5jZXMudjEuTWVtZX'
    'NQaWNrZXJTdGF0ZVILbWVtZXNQaWNrZXISPAoFZW1vamkYFyABKAsyJi5mbHV4ZXIudXNlci5w'
    'cmVmZXJlbmNlcy52MS5FbW9qaVN0YXRlUgVlbW9qaRJoChRlbW9qaV9zdGlja2VyX2xheW91dB'
    'gYIAEoCzI2LmZsdXhlci51c2VyLnByZWZlcmVuY2VzLnYxLkVtb2ppU3RpY2tlckxheW91dFNl'
    'dHRpbmdzUhJlbW9qaVN0aWNrZXJMYXlvdXQSVAoNZmF2b3JpdGVfZ2lmcxgZIAEoCzIvLmZsdX'
    'hlci51c2VyLnByZWZlcmVuY2VzLnYxLkZhdm9yaXRlR2lmU2V0dGluZ3NSDGZhdm9yaXRlR2lm'
    'cxJICglmYXZvcml0ZXMYKCABKAsyKi5mbHV4ZXIudXNlci5wcmVmZXJlbmNlcy52MS5GYXZvcm'
    'l0ZXNTdGF0ZVIJZmF2b3JpdGVzElsKD3JlY2VudF9tZW50aW9ucxgpIAEoCzIyLmZsdXhlci51'
    'c2VyLnByZWZlcmVuY2VzLnYxLlJlY2VudE1lbnRpb25zU2V0dGluZ3NSDnJlY2VudE1lbnRpb2'
    '5zEkgKB3NpZGViYXIYKiABKAsyLi5mbHV4ZXIudXNlci5wcmVmZXJlbmNlcy52MS5TaWRlYmFy'
    'UHJlZmVyZW5jZXNSB3NpZGViYXISTAoLbWVtYmVyX2xpc3QYKyABKAsyKy5mbHV4ZXIudXNlci'
    '5wcmVmZXJlbmNlcy52MS5NZW1iZXJMaXN0U3RhdGVSCm1lbWJlckxpc3QSWAoPdW5yZWFkX2No'
    'YW5uZWxzGCwgASgLMi8uZmx1eGVyLnVzZXIucHJlZmVyZW5jZXMudjEuVW5yZWFkQ2hhbm5lbH'
    'NTdGF0ZVIOdW5yZWFkQ2hhbm5lbHMSWwoQbWVudGlvbl9mcmVjZW5jeRgtIAEoCzIwLmZsdXhl'
    'ci51c2VyLnByZWZlcmVuY2VzLnYxLk1lbnRpb25GcmVjZW5jeVN0YXRlUg9tZW50aW9uRnJlY2'
    'VuY3kSRgoHbmFnYmFycxg8IAEoCzIsLmZsdXhlci51c2VyLnByZWZlcmVuY2VzLnYxLk5hZ2Jh'
    'ckRpc21pc3NhbHNSB25hZ2JhcnMSWQoRZGlzbWlzc2VkX3Vwc2VsbHMYPSABKAsyLC5mbHV4ZX'
    'IudXNlci5wcmVmZXJlbmNlcy52MS5EaXNtaXNzZWRVcHNlbGxzUhBkaXNtaXNzZWRVcHNlbGxz'
    'EmMKFWd1aWxkX25zZndfYWdyZWVtZW50cxg+IAEoCzIvLmZsdXhlci51c2VyLnByZWZlcmVuY2'
    'VzLnYxLkd1aWxkTnNmd0FncmVlbWVudHNSE2d1aWxkTnNmd0FncmVlbWVudHMSRgoJd2hhdHNf'
    'bmV3GD8gASgLMikuZmx1eGVyLnVzZXIucHJlZmVyZW5jZXMudjEuV2hhdHNOZXdTdGF0ZVIId2'
    'hhdHNOZXcSSAoHcHJpdmFjeRhQIAEoCzIuLmZsdXhlci51c2VyLnByZWZlcmVuY2VzLnYxLlBy'
    'aXZhY3lQcmVmZXJlbmNlc1IHcHJpdmFjeRJkChRsb2NhbF9zcGFtX292ZXJyaWRlcxhRIAEoCz'
    'IyLmZsdXhlci51c2VyLnByZWZlcmVuY2VzLnYxLkxvY2FsVXNlclNwYW1PdmVycmlkZXNSEmxv'
    'Y2FsU3BhbU92ZXJyaWRlcxIjCg1zYW5pdGl6ZV91cmxzGFIgASgIUgxzYW5pdGl6ZVVybHMSPw'
    'oFc291bmQYZCABKAsyKS5mbHV4ZXIudXNlci5wcmVmZXJlbmNlcy52MS5Tb3VuZFNldHRpbmdz'
    'UgVzb3VuZBJOCgpzcGVsbGNoZWNrGGUgASgLMi4uZmx1eGVyLnVzZXIucHJlZmVyZW5jZXMudj'
    'EuU3BlbGxjaGVja1NldHRpbmdzUgpzcGVsbGNoZWNrElcKDnNlYXJjaF9lbmdpbmVzGGYgASgL'
    'MjAuZmx1eGVyLnVzZXIucHJlZmVyZW5jZXMudjEuU2VhcmNoRW5naW5lU2V0dGluZ3NSDXNlYX'
    'JjaEVuZ2luZXMSYQoRcGVybWlzc2lvbl9sYXlvdXQYZyABKAsyNC5mbHV4ZXIudXNlci5wcmVm'
    'ZXJlbmNlcy52MS5QZXJtaXNzaW9uTGF5b3V0U2V0dGluZ3NSEHBlcm1pc3Npb25MYXlvdXQSZQ'
    'oTZ3VpbGRfbWVtYmVyX2xheW91dBhoIAEoCzI1LmZsdXhlci51c2VyLnByZWZlcmVuY2VzLnYx'
    'Lkd1aWxkTWVtYmVyTGF5b3V0U2V0dGluZ3NSEWd1aWxkTWVtYmVyTGF5b3V0ElkKDWd1aWxkX2'
    'ZvbGRlcnMYaSABKAsyNC5mbHV4ZXIudXNlci5wcmVmZXJlbmNlcy52MS5HdWlsZEZvbGRlckV4'
    'cGFuZGVkU3RhdGVSDGd1aWxkRm9sZGVycxJkChRoaWRkZW5fZ3VpbGRfYnV0dG9ucxhqIAEoCz'
    'IyLmZsdXhlci51c2VyLnByZWZlcmVuY2VzLnYxLkhpZGRlbkd1aWxkTGlzdEJ1dHRvbnNSEmhp'
    'ZGRlbkd1aWxkQnV0dG9ucxJiChNrZXlib2FyZF9tb2RlX2ludHJvGGsgASgLMjIuZmx1eGVyLn'
    'VzZXIucHJlZmVyZW5jZXMudjEuS2V5Ym9hcmRNb2RlSW50cm9TdGF0ZVIRa2V5Ym9hcmRNb2Rl'
    'SW50cm8SYgoQaW5wdXRfbW9uaXRvcmluZxhsIAEoCzI3LmZsdXhlci51c2VyLnByZWZlcmVuY2'
    'VzLnYxLklucHV0TW9uaXRvcmluZ1Byb21wdHNTdGF0ZVIPaW5wdXRNb25pdG9yaW5nElIKDXZv'
    'aWNlX3Byb21wdHMYbSABKAsyLS5mbHV4ZXIudXNlci5wcmVmZXJlbmNlcy52MS5Wb2ljZVByb2'
    '1wdHNTdGF0ZVIMdm9pY2VQcm9tcHRzEkwKC3N1ZG9fcHJvbXB0GG4gASgLMisuZmx1eGVyLnVz'
    'ZXIucHJlZmVyZW5jZXMudjEuU3Vkb1Byb21wdFN0YXRlUgpzdWRvUHJvbXB0EkcKCGtleWJpbm'
    'RzGG8gASgLMisuZmx1eGVyLnVzZXIucHJlZmVyZW5jZXMudjEuS2V5YmluZFNldHRpbmdzUghr'
    'ZXliaW5kcxJMCgpjaGF0X2lucHV0GHAgASgLMi0uZmx1eGVyLnVzZXIucHJlZmVyZW5jZXMudj'
    'EuQ2hhdElucHV0U2V0dGluZ3NSCWNoYXRJbnB1dBJZChNkb3VibGVfdGFwX3JlYWN0aW9uGHIg'
    'ASgLMikuZmx1eGVyLnVzZXIucHJlZmVyZW5jZXMudjEuUmVhY3Rpb25FbW9qaVIRZG91YmxlVG'
    'FwUmVhY3Rpb24SWwoQY2hhbm5lbF9mcmVjZW5jeRhzIAEoCzIwLmZsdXhlci51c2VyLnByZWZl'
    'cmVuY2VzLnYxLkNoYW5uZWxGcmVjZW5jeVN0YXRlUg9jaGFubmVsRnJlY2VuY3kSZwoUYW5ub3'
    'VuY2VtZW50X3Byb21wdHMYdCABKAsyNC5mbHV4ZXIudXNlci5wcmVmZXJlbmNlcy52MS5Bbm5v'
    'dW5jZW1lbnRQcm9tcHRzU3RhdGVSE2Fubm91bmNlbWVudFByb21wdHMSVwoRZG91YmxlX3RhcF'
    '9hY3Rpb24YdSABKA4yKy5mbHV4ZXIudXNlci5wcmVmZXJlbmNlcy52MS5Eb3VibGVUYXBBY3Rp'
    'b25SD2RvdWJsZVRhcEFjdGlvbhJjChpzd2lwZV9yaWdodF90b19sZWZ0X2FjdGlvbhh2IAEoDj'
    'InLmZsdXhlci51c2VyLnByZWZlcmVuY2VzLnYxLlN3aXBlQWN0aW9uUhZzd2lwZVJpZ2h0VG9M'
    'ZWZ0QWN0aW9u');

@$core.Deprecated('Use spellcheckSettingsDescriptor instead')
const SpellcheckSettings$json = {
  '1': 'SpellcheckSettings',
  '2': [
    {
      '1': 'enabled',
      '3': 1,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'enabled',
      '17': true
    },
    {'1': 'languages', '3': 2, '4': 3, '5': 9, '10': 'languages'},
    {
      '1': 'personal_dictionary',
      '3': 3,
      '4': 3,
      '5': 9,
      '10': 'personalDictionary'
    },
    {
      '1': 'auto_detect',
      '3': 4,
      '4': 1,
      '5': 8,
      '9': 1,
      '10': 'autoDetect',
      '17': true
    },
    {'1': 'engine', '3': 5, '4': 1, '5': 9, '9': 2, '10': 'engine', '17': true},
  ],
  '8': [
    {'1': '_enabled'},
    {'1': '_auto_detect'},
    {'1': '_engine'},
  ],
};

/// Descriptor for `SpellcheckSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List spellcheckSettingsDescriptor = $convert.base64Decode(
    'ChJTcGVsbGNoZWNrU2V0dGluZ3MSHQoHZW5hYmxlZBgBIAEoCEgAUgdlbmFibGVkiAEBEhwKCW'
    'xhbmd1YWdlcxgCIAMoCVIJbGFuZ3VhZ2VzEi8KE3BlcnNvbmFsX2RpY3Rpb25hcnkYAyADKAlS'
    'EnBlcnNvbmFsRGljdGlvbmFyeRIkCgthdXRvX2RldGVjdBgEIAEoCEgBUgphdXRvRGV0ZWN0iA'
    'EBEhsKBmVuZ2luZRgFIAEoCUgCUgZlbmdpbmWIAQFCCgoIX2VuYWJsZWRCDgoMX2F1dG9fZGV0'
    'ZWN0QgkKB19lbmdpbmU=');

@$core.Deprecated('Use searchEngineSettingsDescriptor instead')
const SearchEngineSettings$json = {
  '1': 'SearchEngineSettings',
  '2': [
    {
      '1': 'text_search_engine_id',
      '3': 1,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'textSearchEngineId',
      '17': true
    },
    {
      '1': 'reverse_image_search_engine_id',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'reverseImageSearchEngineId',
      '17': true
    },
    {
      '1': 'translation_provider_id',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'translationProviderId',
      '17': true
    },
  ],
  '8': [
    {'1': '_text_search_engine_id'},
    {'1': '_reverse_image_search_engine_id'},
    {'1': '_translation_provider_id'},
  ],
};

/// Descriptor for `SearchEngineSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchEngineSettingsDescriptor = $convert.base64Decode(
    'ChRTZWFyY2hFbmdpbmVTZXR0aW5ncxI2ChV0ZXh0X3NlYXJjaF9lbmdpbmVfaWQYASABKAlIAF'
    'ISdGV4dFNlYXJjaEVuZ2luZUlkiAEBEkcKHnJldmVyc2VfaW1hZ2Vfc2VhcmNoX2VuZ2luZV9p'
    'ZBgCIAEoCUgBUhpyZXZlcnNlSW1hZ2VTZWFyY2hFbmdpbmVJZIgBARI7Chd0cmFuc2xhdGlvbl'
    '9wcm92aWRlcl9pZBgDIAEoCUgCUhV0cmFuc2xhdGlvblByb3ZpZGVySWSIAQFCGAoWX3RleHRf'
    'c2VhcmNoX2VuZ2luZV9pZEIhCh9fcmV2ZXJzZV9pbWFnZV9zZWFyY2hfZW5naW5lX2lkQhoKGF'
    '90cmFuc2xhdGlvbl9wcm92aWRlcl9pZA==');

@$core.Deprecated('Use privacyPreferencesDescriptor instead')
const PrivacyPreferences$json = {
  '1': 'PrivacyPreferences',
  '2': [
    {
      '1': 'disable_stream_previews',
      '3': 1,
      '4': 1,
      '5': 8,
      '10': 'disableStreamPreviews'
    },
    {
      '1': 'show_active_now',
      '3': 2,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'showActiveNow',
      '17': true
    },
    {
      '1': 'preupload_message_attachments',
      '3': 3,
      '4': 1,
      '5': 8,
      '9': 1,
      '10': 'preuploadMessageAttachments',
      '17': true
    },
  ],
  '8': [
    {'1': '_show_active_now'},
    {'1': '_preupload_message_attachments'},
  ],
};

/// Descriptor for `PrivacyPreferences`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List privacyPreferencesDescriptor = $convert.base64Decode(
    'ChJQcml2YWN5UHJlZmVyZW5jZXMSNgoXZGlzYWJsZV9zdHJlYW1fcHJldmlld3MYASABKAhSFW'
    'Rpc2FibGVTdHJlYW1QcmV2aWV3cxIrCg9zaG93X2FjdGl2ZV9ub3cYAiABKAhIAFINc2hvd0Fj'
    'dGl2ZU5vd4gBARJHCh1wcmV1cGxvYWRfbWVzc2FnZV9hdHRhY2htZW50cxgDIAEoCEgBUhtwcm'
    'V1cGxvYWRNZXNzYWdlQXR0YWNobWVudHOIAQFCEgoQX3Nob3dfYWN0aXZlX25vd0IgCh5fcHJl'
    'dXBsb2FkX21lc3NhZ2VfYXR0YWNobWVudHM=');

@$core.Deprecated('Use localUserSpamOverridesDescriptor instead')
const LocalUserSpamOverrides$json = {
  '1': 'LocalUserSpamOverrides',
  '2': [
    {'1': 'spammer_user_ids', '3': 1, '4': 3, '5': 9, '10': 'spammerUserIds'},
    {
      '1': 'not_spammer_user_ids',
      '3': 2,
      '4': 3,
      '5': 9,
      '10': 'notSpammerUserIds'
    },
  ],
};

/// Descriptor for `LocalUserSpamOverrides`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List localUserSpamOverridesDescriptor = $convert.base64Decode(
    'ChZMb2NhbFVzZXJTcGFtT3ZlcnJpZGVzEigKEHNwYW1tZXJfdXNlcl9pZHMYASADKAlSDnNwYW'
    '1tZXJVc2VySWRzEi8KFG5vdF9zcGFtbWVyX3VzZXJfaWRzGAIgAygJUhFub3RTcGFtbWVyVXNl'
    'cklkcw==');

@$core.Deprecated('Use textualPreviewSettingsDescriptor instead')
const TextualPreviewSettings$json = {
  '1': 'TextualPreviewSettings',
  '2': [
    {'1': 'wrap_text', '3': 1, '4': 1, '5': 8, '10': 'wrapText'},
  ],
};

/// Descriptor for `TextualPreviewSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List textualPreviewSettingsDescriptor =
    $convert.base64Decode(
        'ChZUZXh0dWFsUHJldmlld1NldHRpbmdzEhsKCXdyYXBfdGV4dBgBIAEoCFIId3JhcFRleHQ=');

@$core.Deprecated('Use sidebarPreferencesDescriptor instead')
const SidebarPreferences$json = {
  '1': 'SidebarPreferences',
  '2': [
    {
      '1': 'inline_dms_collapsed',
      '3': 1,
      '4': 1,
      '5': 8,
      '10': 'inlineDmsCollapsed'
    },
    {
      '1': 'show_collapsed_unread_dms_badge',
      '3': 2,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'showCollapsedUnreadDmsBadge',
      '17': true
    },
    {
      '1': 'show_incoming_friend_request_badge',
      '3': 3,
      '4': 1,
      '5': 8,
      '9': 1,
      '10': 'showIncomingFriendRequestBadge',
      '17': true
    },
  ],
  '8': [
    {'1': '_show_collapsed_unread_dms_badge'},
    {'1': '_show_incoming_friend_request_badge'},
  ],
};

/// Descriptor for `SidebarPreferences`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sidebarPreferencesDescriptor = $convert.base64Decode(
    'ChJTaWRlYmFyUHJlZmVyZW5jZXMSMAoUaW5saW5lX2Rtc19jb2xsYXBzZWQYASABKAhSEmlubG'
    'luZURtc0NvbGxhcHNlZBJJCh9zaG93X2NvbGxhcHNlZF91bnJlYWRfZG1zX2JhZGdlGAIgASgI'
    'SABSG3Nob3dDb2xsYXBzZWRVbnJlYWREbXNCYWRnZYgBARJPCiJzaG93X2luY29taW5nX2ZyaW'
    'VuZF9yZXF1ZXN0X2JhZGdlGAMgASgISAFSHnNob3dJbmNvbWluZ0ZyaWVuZFJlcXVlc3RCYWRn'
    'ZYgBAUIiCiBfc2hvd19jb2xsYXBzZWRfdW5yZWFkX2Rtc19iYWRnZUIlCiNfc2hvd19pbmNvbW'
    'luZ19mcmllbmRfcmVxdWVzdF9iYWRnZQ==');

@$core.Deprecated('Use memberListStateDescriptor instead')
const MemberListState$json = {
  '1': 'MemberListState',
  '2': [
    {
      '1': 'members_open',
      '3': 1,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'membersOpen',
      '17': true
    },
  ],
  '8': [
    {'1': '_members_open'},
  ],
};

/// Descriptor for `MemberListState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List memberListStateDescriptor = $convert.base64Decode(
    'Cg9NZW1iZXJMaXN0U3RhdGUSJgoMbWVtYmVyc19vcGVuGAEgASgISABSC21lbWJlcnNPcGVuiA'
    'EBQg8KDV9tZW1iZXJzX29wZW4=');

@$core.Deprecated('Use unreadChannelsStateDescriptor instead')
const UnreadChannelsState$json = {
  '1': 'UnreadChannelsState',
  '2': [
    {
      '1': 'collapsed_channel_ids',
      '3': 1,
      '4': 3,
      '5': 9,
      '10': 'collapsedChannelIds'
    },
  ],
};

/// Descriptor for `UnreadChannelsState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List unreadChannelsStateDescriptor = $convert.base64Decode(
    'ChNVbnJlYWRDaGFubmVsc1N0YXRlEjIKFWNvbGxhcHNlZF9jaGFubmVsX2lkcxgBIAMoCVITY2'
    '9sbGFwc2VkQ2hhbm5lbElkcw==');

@$core.Deprecated('Use recentMentionsSettingsDescriptor instead')
const RecentMentionsSettings$json = {
  '1': 'RecentMentionsSettings',
  '2': [
    {
      '1': 'include_everyone',
      '3': 1,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'includeEveryone',
      '17': true
    },
    {
      '1': 'include_roles',
      '3': 2,
      '4': 1,
      '5': 8,
      '9': 1,
      '10': 'includeRoles',
      '17': true
    },
    {
      '1': 'include_guilds',
      '3': 3,
      '4': 1,
      '5': 8,
      '9': 2,
      '10': 'includeGuilds',
      '17': true
    },
  ],
  '8': [
    {'1': '_include_everyone'},
    {'1': '_include_roles'},
    {'1': '_include_guilds'},
  ],
};

/// Descriptor for `RecentMentionsSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recentMentionsSettingsDescriptor = $convert.base64Decode(
    'ChZSZWNlbnRNZW50aW9uc1NldHRpbmdzEi4KEGluY2x1ZGVfZXZlcnlvbmUYASABKAhIAFIPaW'
    '5jbHVkZUV2ZXJ5b25liAEBEigKDWluY2x1ZGVfcm9sZXMYAiABKAhIAVIMaW5jbHVkZVJvbGVz'
    'iAEBEioKDmluY2x1ZGVfZ3VpbGRzGAMgASgISAJSDWluY2x1ZGVHdWlsZHOIAQFCEwoRX2luY2'
    'x1ZGVfZXZlcnlvbmVCEAoOX2luY2x1ZGVfcm9sZXNCEQoPX2luY2x1ZGVfZ3VpbGRz');

@$core.Deprecated('Use mentionFrecencyStateDescriptor instead')
const MentionFrecencyState$json = {
  '1': 'MentionFrecencyState',
  '2': [
    {
      '1': 'scopes',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.MentionFrecencyState.Scope',
      '10': 'scopes'
    },
  ],
  '3': [MentionFrecencyState_Entry$json, MentionFrecencyState_Scope$json],
};

@$core.Deprecated('Use mentionFrecencyStateDescriptor instead')
const MentionFrecencyState_Entry$json = {
  '1': 'Entry',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'count', '3': 2, '4': 1, '5': 13, '10': 'count'},
    {'1': 'last_at_ms', '3': 3, '4': 1, '5': 3, '10': 'lastAtMs'},
  ],
};

@$core.Deprecated('Use mentionFrecencyStateDescriptor instead')
const MentionFrecencyState_Scope$json = {
  '1': 'Scope',
  '2': [
    {'1': 'guild_id', '3': 1, '4': 1, '5': 9, '10': 'guildId'},
    {
      '1': 'entries',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.MentionFrecencyState.Entry',
      '10': 'entries'
    },
  ],
};

/// Descriptor for `MentionFrecencyState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mentionFrecencyStateDescriptor = $convert.base64Decode(
    'ChRNZW50aW9uRnJlY2VuY3lTdGF0ZRJOCgZzY29wZXMYASADKAsyNi5mbHV4ZXIudXNlci5wcm'
    'VmZXJlbmNlcy52MS5NZW50aW9uRnJlY2VuY3lTdGF0ZS5TY29wZVIGc2NvcGVzGlQKBUVudHJ5'
    'EhcKB3VzZXJfaWQYASABKAlSBnVzZXJJZBIUCgVjb3VudBgCIAEoDVIFY291bnQSHAoKbGFzdF'
    '9hdF9tcxgDIAEoA1IIbGFzdEF0TXMadAoFU2NvcGUSGQoIZ3VpbGRfaWQYASABKAlSB2d1aWxk'
    'SWQSUAoHZW50cmllcxgCIAMoCzI2LmZsdXhlci51c2VyLnByZWZlcmVuY2VzLnYxLk1lbnRpb2'
    '5GcmVjZW5jeVN0YXRlLkVudHJ5UgdlbnRyaWVz');

@$core.Deprecated('Use favoritesStateDescriptor instead')
const FavoritesState$json = {
  '1': 'FavoritesState',
  '2': [
    {
      '1': 'channels',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.FavoriteChannel',
      '10': 'channels'
    },
    {
      '1': 'categories',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.FavoriteCategory',
      '10': 'categories'
    },
    {
      '1': 'collapsed_category_ids',
      '3': 3,
      '4': 3,
      '5': 9,
      '10': 'collapsedCategoryIds'
    },
    {
      '1': 'hide_muted_channels',
      '3': 4,
      '4': 1,
      '5': 8,
      '10': 'hideMutedChannels'
    },
    {'1': 'muted', '3': 5, '4': 1, '5': 8, '10': 'muted'},
  ],
};

/// Descriptor for `FavoritesState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List favoritesStateDescriptor = $convert.base64Decode(
    'Cg5GYXZvcml0ZXNTdGF0ZRJHCghjaGFubmVscxgBIAMoCzIrLmZsdXhlci51c2VyLnByZWZlcm'
    'VuY2VzLnYxLkZhdm9yaXRlQ2hhbm5lbFIIY2hhbm5lbHMSTAoKY2F0ZWdvcmllcxgCIAMoCzIs'
    'LmZsdXhlci51c2VyLnByZWZlcmVuY2VzLnYxLkZhdm9yaXRlQ2F0ZWdvcnlSCmNhdGVnb3JpZX'
    'MSNAoWY29sbGFwc2VkX2NhdGVnb3J5X2lkcxgDIAMoCVIUY29sbGFwc2VkQ2F0ZWdvcnlJZHMS'
    'LgoTaGlkZV9tdXRlZF9jaGFubmVscxgEIAEoCFIRaGlkZU11dGVkQ2hhbm5lbHMSFAoFbXV0ZW'
    'QYBSABKAhSBW11dGVk');

@$core.Deprecated('Use favoriteChannelDescriptor instead')
const FavoriteChannel$json = {
  '1': 'FavoriteChannel',
  '2': [
    {'1': 'channel_id', '3': 1, '4': 1, '5': 9, '10': 'channelId'},
    {'1': 'guild_id', '3': 2, '4': 1, '5': 9, '10': 'guildId'},
    {
      '1': 'parent_id',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'parentId',
      '17': true
    },
    {'1': 'position', '3': 4, '4': 1, '5': 5, '10': 'position'},
    {
      '1': 'nickname',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'nickname',
      '17': true
    },
  ],
  '8': [
    {'1': '_parent_id'},
    {'1': '_nickname'},
  ],
};

/// Descriptor for `FavoriteChannel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List favoriteChannelDescriptor = $convert.base64Decode(
    'Cg9GYXZvcml0ZUNoYW5uZWwSHQoKY2hhbm5lbF9pZBgBIAEoCVIJY2hhbm5lbElkEhkKCGd1aW'
    'xkX2lkGAIgASgJUgdndWlsZElkEiAKCXBhcmVudF9pZBgDIAEoCUgAUghwYXJlbnRJZIgBARIa'
    'Cghwb3NpdGlvbhgEIAEoBVIIcG9zaXRpb24SHwoIbmlja25hbWUYBSABKAlIAVIIbmlja25hbW'
    'WIAQFCDAoKX3BhcmVudF9pZEILCglfbmlja25hbWU=');

@$core.Deprecated('Use favoriteCategoryDescriptor instead')
const FavoriteCategory$json = {
  '1': 'FavoriteCategory',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'position', '3': 3, '4': 1, '5': 5, '10': 'position'},
  ],
};

/// Descriptor for `FavoriteCategory`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List favoriteCategoryDescriptor = $convert.base64Decode(
    'ChBGYXZvcml0ZUNhdGVnb3J5Eg4KAmlkGAEgASgJUgJpZBISCgRuYW1lGAIgASgJUgRuYW1lEh'
    'oKCHBvc2l0aW9uGAMgASgFUghwb3NpdGlvbg==');

@$core.Deprecated('Use nagbarDismissalsDescriptor instead')
const NagbarDismissals$json = {
  '1': 'NagbarDismissals',
  '2': [
    {'1': 'ios_install', '3': 1, '4': 1, '5': 8, '10': 'iosInstall'},
    {'1': 'pwa_install', '3': 2, '4': 1, '5': 8, '10': 'pwaInstall'},
    {
      '1': 'push_notification',
      '3': 3,
      '4': 1,
      '5': 8,
      '10': 'pushNotification'
    },
    {
      '1': 'desktop_notification',
      '3': 4,
      '4': 1,
      '5': 8,
      '10': 'desktopNotification'
    },
    {
      '1': 'premium_grace_period',
      '3': 5,
      '4': 1,
      '5': 8,
      '10': 'premiumGracePeriod'
    },
    {'1': 'premium_expired', '3': 6, '4': 1, '5': 8, '10': 'premiumExpired'},
    {
      '1': 'premium_onboarding',
      '3': 7,
      '4': 1,
      '5': 8,
      '10': 'premiumOnboarding'
    },
    {
      '1': 'premium_trial_expiring',
      '3': 8,
      '4': 1,
      '5': 8,
      '10': 'premiumTrialExpiring'
    },
    {'1': 'gift_inventory', '3': 9, '4': 1, '5': 8, '10': 'giftInventory'},
    {'1': 'desktop_download', '3': 10, '4': 1, '5': 8, '10': 'desktopDownload'},
    {
      '1': 'guild_membership_cta',
      '3': 11,
      '4': 1,
      '5': 8,
      '10': 'guildMembershipCta'
    },
    {'1': 'visionary_mfa', '3': 12, '4': 1, '5': 8, '10': 'visionaryMfa'},
    {
      '1': 'legacy_phone_unlink',
      '3': 14,
      '4': 1,
      '5': 8,
      '10': 'legacyPhoneUnlink'
    },
    {
      '1': 'pending_bulk_deletion',
      '3': 15,
      '4': 3,
      '5': 11,
      '6':
          '.fluxer.user.preferences.v1.NagbarDismissals.PendingBulkDeletionEntry',
      '10': 'pendingBulkDeletion'
    },
    {
      '1': 'invites_disabled',
      '3': 16,
      '4': 3,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.NagbarDismissals.InvitesDisabledEntry',
      '10': 'invitesDisabled'
    },
    {
      '1': 'guild_mfa_requirement',
      '3': 17,
      '4': 3,
      '5': 11,
      '6':
          '.fluxer.user.preferences.v1.NagbarDismissals.GuildMfaRequirementEntry',
      '10': 'guildMfaRequirement'
    },
  ],
  '3': [
    NagbarDismissals_PendingBulkDeletionEntry$json,
    NagbarDismissals_InvitesDisabledEntry$json,
    NagbarDismissals_GuildMfaRequirementEntry$json
  ],
};

@$core.Deprecated('Use nagbarDismissalsDescriptor instead')
const NagbarDismissals_PendingBulkDeletionEntry$json = {
  '1': 'PendingBulkDeletionEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 8, '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use nagbarDismissalsDescriptor instead')
const NagbarDismissals_InvitesDisabledEntry$json = {
  '1': 'InvitesDisabledEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 8, '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use nagbarDismissalsDescriptor instead')
const NagbarDismissals_GuildMfaRequirementEntry$json = {
  '1': 'GuildMfaRequirementEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 8, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `NagbarDismissals`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nagbarDismissalsDescriptor = $convert.base64Decode(
    'ChBOYWdiYXJEaXNtaXNzYWxzEh8KC2lvc19pbnN0YWxsGAEgASgIUgppb3NJbnN0YWxsEh8KC3'
    'B3YV9pbnN0YWxsGAIgASgIUgpwd2FJbnN0YWxsEisKEXB1c2hfbm90aWZpY2F0aW9uGAMgASgI'
    'UhBwdXNoTm90aWZpY2F0aW9uEjEKFGRlc2t0b3Bfbm90aWZpY2F0aW9uGAQgASgIUhNkZXNrdG'
    '9wTm90aWZpY2F0aW9uEjAKFHByZW1pdW1fZ3JhY2VfcGVyaW9kGAUgASgIUhJwcmVtaXVtR3Jh'
    'Y2VQZXJpb2QSJwoPcHJlbWl1bV9leHBpcmVkGAYgASgIUg5wcmVtaXVtRXhwaXJlZBItChJwcm'
    'VtaXVtX29uYm9hcmRpbmcYByABKAhSEXByZW1pdW1PbmJvYXJkaW5nEjQKFnByZW1pdW1fdHJp'
    'YWxfZXhwaXJpbmcYCCABKAhSFHByZW1pdW1UcmlhbEV4cGlyaW5nEiUKDmdpZnRfaW52ZW50b3'
    'J5GAkgASgIUg1naWZ0SW52ZW50b3J5EikKEGRlc2t0b3BfZG93bmxvYWQYCiABKAhSD2Rlc2t0'
    'b3BEb3dubG9hZBIwChRndWlsZF9tZW1iZXJzaGlwX2N0YRgLIAEoCFISZ3VpbGRNZW1iZXJzaG'
    'lwQ3RhEiMKDXZpc2lvbmFyeV9tZmEYDCABKAhSDHZpc2lvbmFyeU1mYRIuChNsZWdhY3lfcGhv'
    'bmVfdW5saW5rGA4gASgIUhFsZWdhY3lQaG9uZVVubGluaxJ5ChVwZW5kaW5nX2J1bGtfZGVsZX'
    'Rpb24YDyADKAsyRS5mbHV4ZXIudXNlci5wcmVmZXJlbmNlcy52MS5OYWdiYXJEaXNtaXNzYWxz'
    'LlBlbmRpbmdCdWxrRGVsZXRpb25FbnRyeVITcGVuZGluZ0J1bGtEZWxldGlvbhJsChBpbnZpdG'
    'VzX2Rpc2FibGVkGBAgAygLMkEuZmx1eGVyLnVzZXIucHJlZmVyZW5jZXMudjEuTmFnYmFyRGlz'
    'bWlzc2Fscy5JbnZpdGVzRGlzYWJsZWRFbnRyeVIPaW52aXRlc0Rpc2FibGVkEnkKFWd1aWxkX2'
    '1mYV9yZXF1aXJlbWVudBgRIAMoCzJFLmZsdXhlci51c2VyLnByZWZlcmVuY2VzLnYxLk5hZ2Jh'
    'ckRpc21pc3NhbHMuR3VpbGRNZmFSZXF1aXJlbWVudEVudHJ5UhNndWlsZE1mYVJlcXVpcmVtZW'
    '50GkYKGFBlbmRpbmdCdWxrRGVsZXRpb25FbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1'
    'ZRgCIAEoCFIFdmFsdWU6AjgBGkIKFEludml0ZXNEaXNhYmxlZEVudHJ5EhAKA2tleRgBIAEoCV'
    'IDa2V5EhQKBXZhbHVlGAIgASgIUgV2YWx1ZToCOAEaRgoYR3VpbGRNZmFSZXF1aXJlbWVudEVu'
    'dHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgIUgV2YWx1ZToCOAE=');

@$core.Deprecated('Use dismissedUpsellsDescriptor instead')
const DismissedUpsells$json = {
  '1': 'DismissedUpsells',
  '2': [
    {'1': 'picker_premium', '3': 1, '4': 1, '5': 8, '10': 'pickerPremium'},
  ],
};

/// Descriptor for `DismissedUpsells`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dismissedUpsellsDescriptor = $convert.base64Decode(
    'ChBEaXNtaXNzZWRVcHNlbGxzEiUKDnBpY2tlcl9wcmVtaXVtGAEgASgIUg1waWNrZXJQcmVtaX'
    'Vt');

@$core.Deprecated('Use guildNsfwAgreementsDescriptor instead')
const GuildNsfwAgreements$json = {
  '1': 'GuildNsfwAgreements',
  '2': [
    {
      '1': 'agreed_channel_ids',
      '3': 1,
      '4': 3,
      '5': 9,
      '10': 'agreedChannelIds'
    },
    {'1': 'agreed_guild_ids', '3': 2, '4': 3, '5': 9, '10': 'agreedGuildIds'},
    {
      '1': 'agreed_category_ids',
      '3': 3,
      '4': 3,
      '5': 9,
      '10': 'agreedCategoryIds'
    },
  ],
};

/// Descriptor for `GuildNsfwAgreements`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List guildNsfwAgreementsDescriptor = $convert.base64Decode(
    'ChNHdWlsZE5zZndBZ3JlZW1lbnRzEiwKEmFncmVlZF9jaGFubmVsX2lkcxgBIAMoCVIQYWdyZW'
    'VkQ2hhbm5lbElkcxIoChBhZ3JlZWRfZ3VpbGRfaWRzGAIgAygJUg5hZ3JlZWRHdWlsZElkcxIu'
    'ChNhZ3JlZWRfY2F0ZWdvcnlfaWRzGAMgAygJUhFhZ3JlZWRDYXRlZ29yeUlkcw==');

@$core.Deprecated('Use whatsNewStateDescriptor instead')
const WhatsNewState$json = {
  '1': 'WhatsNewState',
  '2': [
    {
      '1': 'last_dismissed_entry_id',
      '3': 1,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'lastDismissedEntryId',
      '17': true
    },
  ],
  '8': [
    {'1': '_last_dismissed_entry_id'},
  ],
};

/// Descriptor for `WhatsNewState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List whatsNewStateDescriptor = $convert.base64Decode(
    'Cg1XaGF0c05ld1N0YXRlEjoKF2xhc3RfZGlzbWlzc2VkX2VudHJ5X2lkGAEgASgJSABSFGxhc3'
    'REaXNtaXNzZWRFbnRyeUlkiAEBQhoKGF9sYXN0X2Rpc21pc3NlZF9lbnRyeV9pZA==');

@$core.Deprecated('Use permissionLayoutSettingsDescriptor instead')
const PermissionLayoutSettings$json = {
  '1': 'PermissionLayoutSettings',
  '2': [
    {
      '1': 'layout',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.fluxer.user.preferences.v1.PermissionLayoutMode',
      '10': 'layout'
    },
    {
      '1': 'grid',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.fluxer.user.preferences.v1.PermissionGridMode',
      '10': 'grid'
    },
  ],
};

/// Descriptor for `PermissionLayoutSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List permissionLayoutSettingsDescriptor = $convert.base64Decode(
    'ChhQZXJtaXNzaW9uTGF5b3V0U2V0dGluZ3MSSAoGbGF5b3V0GAEgASgOMjAuZmx1eGVyLnVzZX'
    'IucHJlZmVyZW5jZXMudjEuUGVybWlzc2lvbkxheW91dE1vZGVSBmxheW91dBJCCgRncmlkGAIg'
    'ASgOMi4uZmx1eGVyLnVzZXIucHJlZmVyZW5jZXMudjEuUGVybWlzc2lvbkdyaWRNb2RlUgRncm'
    'lk');

@$core.Deprecated('Use guildMemberLayoutSettingsDescriptor instead')
const GuildMemberLayoutSettings$json = {
  '1': 'GuildMemberLayoutSettings',
  '2': [
    {
      '1': 'mode',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.fluxer.user.preferences.v1.GuildMemberViewMode',
      '10': 'mode'
    },
  ],
};

/// Descriptor for `GuildMemberLayoutSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List guildMemberLayoutSettingsDescriptor =
    $convert.base64Decode(
        'ChlHdWlsZE1lbWJlckxheW91dFNldHRpbmdzEkMKBG1vZGUYASABKA4yLy5mbHV4ZXIudXNlci'
        '5wcmVmZXJlbmNlcy52MS5HdWlsZE1lbWJlclZpZXdNb2RlUgRtb2Rl');

@$core.Deprecated('Use guildFolderExpandedStateDescriptor instead')
const GuildFolderExpandedState$json = {
  '1': 'GuildFolderExpandedState',
  '2': [
    {
      '1': 'expanded_folder_ids',
      '3': 1,
      '4': 3,
      '5': 6,
      '10': 'expandedFolderIds'
    },
  ],
};

/// Descriptor for `GuildFolderExpandedState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List guildFolderExpandedStateDescriptor =
    $convert.base64Decode(
        'ChhHdWlsZEZvbGRlckV4cGFuZGVkU3RhdGUSLgoTZXhwYW5kZWRfZm9sZGVyX2lkcxgBIAMoBl'
        'IRZXhwYW5kZWRGb2xkZXJJZHM=');

@$core.Deprecated('Use hiddenGuildListButtonsDescriptor instead')
const HiddenGuildListButtons$json = {
  '1': 'HiddenGuildListButtons',
  '2': [
    {'1': 'download_button', '3': 1, '4': 1, '5': 8, '10': 'downloadButton'},
    {'1': 'help_button', '3': 2, '4': 1, '5': 8, '10': 'helpButton'},
  ],
};

/// Descriptor for `HiddenGuildListButtons`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hiddenGuildListButtonsDescriptor =
    $convert.base64Decode(
        'ChZIaWRkZW5HdWlsZExpc3RCdXR0b25zEicKD2Rvd25sb2FkX2J1dHRvbhgBIAEoCFIOZG93bm'
        'xvYWRCdXR0b24SHwoLaGVscF9idXR0b24YAiABKAhSCmhlbHBCdXR0b24=');

@$core.Deprecated('Use keyboardModeIntroStateDescriptor instead')
const KeyboardModeIntroState$json = {
  '1': 'KeyboardModeIntroState',
  '2': [
    {'1': 'seen', '3': 1, '4': 1, '5': 8, '10': 'seen'},
  ],
};

/// Descriptor for `KeyboardModeIntroState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keyboardModeIntroStateDescriptor =
    $convert.base64Decode(
        'ChZLZXlib2FyZE1vZGVJbnRyb1N0YXRlEhIKBHNlZW4YASABKAhSBHNlZW4=');

@$core.Deprecated('Use inputMonitoringPromptsStateDescriptor instead')
const InputMonitoringPromptsState$json = {
  '1': 'InputMonitoringPromptsState',
  '2': [
    {'1': 'seen_cta', '3': 1, '4': 1, '5': 8, '10': 'seenCta'},
  ],
};

/// Descriptor for `InputMonitoringPromptsState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inputMonitoringPromptsStateDescriptor =
    $convert.base64Decode(
        'ChtJbnB1dE1vbml0b3JpbmdQcm9tcHRzU3RhdGUSGQoIc2Vlbl9jdGEYASABKAhSB3NlZW5DdG'
        'E=');

@$core.Deprecated('Use voicePromptsStateDescriptor instead')
const VoicePromptsState$json = {
  '1': 'VoicePromptsState',
  '2': [
    {
      '1': 'skip_hide_own_camera_confirm',
      '3': 1,
      '4': 1,
      '5': 8,
      '10': 'skipHideOwnCameraConfirm'
    },
    {
      '1': 'skip_hide_own_screenshare_confirm',
      '3': 2,
      '4': 1,
      '5': 8,
      '10': 'skipHideOwnScreenshareConfirm'
    },
    {
      '1': 'skip_p2p_join_confirm',
      '3': 3,
      '4': 1,
      '5': 8,
      '10': 'skipP2pJoinConfirm'
    },
  ],
};

/// Descriptor for `VoicePromptsState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List voicePromptsStateDescriptor = $convert.base64Decode(
    'ChFWb2ljZVByb21wdHNTdGF0ZRI+Chxza2lwX2hpZGVfb3duX2NhbWVyYV9jb25maXJtGAEgAS'
    'gIUhhza2lwSGlkZU93bkNhbWVyYUNvbmZpcm0SSAohc2tpcF9oaWRlX293bl9zY3JlZW5zaGFy'
    'ZV9jb25maXJtGAIgASgIUh1za2lwSGlkZU93blNjcmVlbnNoYXJlQ29uZmlybRIxChVza2lwX3'
    'AycF9qb2luX2NvbmZpcm0YAyABKAhSEnNraXBQMnBKb2luQ29uZmlybQ==');

@$core.Deprecated('Use announcementPromptsStateDescriptor instead')
const AnnouncementPromptsState$json = {
  '1': 'AnnouncementPromptsState',
  '2': [
    {
      '1': 'hide_publish_nudge',
      '3': 1,
      '4': 1,
      '5': 8,
      '10': 'hidePublishNudge'
    },
  ],
};

/// Descriptor for `AnnouncementPromptsState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List announcementPromptsStateDescriptor =
    $convert.base64Decode(
        'ChhBbm5vdW5jZW1lbnRQcm9tcHRzU3RhdGUSLAoSaGlkZV9wdWJsaXNoX251ZGdlGAEgASgIUh'
        'BoaWRlUHVibGlzaE51ZGdl');

@$core.Deprecated('Use sudoPromptStateDescriptor instead')
const SudoPromptState$json = {
  '1': 'SudoPromptState',
  '2': [
    {
      '1': 'last_used_mfa_method',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.fluxer.user.preferences.v1.MfaMethod',
      '9': 0,
      '10': 'lastUsedMfaMethod',
      '17': true
    },
  ],
  '8': [
    {'1': '_last_used_mfa_method'},
  ],
};

/// Descriptor for `SudoPromptState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sudoPromptStateDescriptor = $convert.base64Decode(
    'Cg9TdWRvUHJvbXB0U3RhdGUSWwoUbGFzdF91c2VkX21mYV9tZXRob2QYASABKA4yJS5mbHV4ZX'
    'IudXNlci5wcmVmZXJlbmNlcy52MS5NZmFNZXRob2RIAFIRbGFzdFVzZWRNZmFNZXRob2SIAQFC'
    'FwoVX2xhc3RfdXNlZF9tZmFfbWV0aG9k');

@$core.Deprecated('Use keybindSettingsDescriptor instead')
const KeybindSettings$json = {
  '1': 'KeybindSettings',
  '2': [
    {
      '1': 'custom_keybinds',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.CustomKeybind',
      '10': 'customKeybinds'
    },
    {'1': 'transmit_mode', '3': 2, '4': 1, '5': 9, '10': 'transmitMode'},
    {
      '1': 'push_to_talk_release_delay_ms',
      '3': 3,
      '4': 1,
      '5': 13,
      '9': 0,
      '10': 'pushToTalkReleaseDelayMs',
      '17': true
    },
  ],
  '8': [
    {'1': '_push_to_talk_release_delay_ms'},
  ],
};

/// Descriptor for `KeybindSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keybindSettingsDescriptor = $convert.base64Decode(
    'Cg9LZXliaW5kU2V0dGluZ3MSUgoPY3VzdG9tX2tleWJpbmRzGAEgAygLMikuZmx1eGVyLnVzZX'
    'IucHJlZmVyZW5jZXMudjEuQ3VzdG9tS2V5YmluZFIOY3VzdG9tS2V5YmluZHMSIwoNdHJhbnNt'
    'aXRfbW9kZRgCIAEoCVIMdHJhbnNtaXRNb2RlEkQKHXB1c2hfdG9fdGFsa19yZWxlYXNlX2RlbG'
    'F5X21zGAMgASgNSABSGHB1c2hUb1RhbGtSZWxlYXNlRGVsYXlNc4gBAUIgCh5fcHVzaF90b190'
    'YWxrX3JlbGVhc2VfZGVsYXlfbXM=');

@$core.Deprecated('Use customKeybindDescriptor instead')
const CustomKeybind$json = {
  '1': 'CustomKeybind',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'action', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'action', '17': true},
    {
      '1': 'combo',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.KeybindCombo',
      '10': 'combo'
    },
    {'1': 'enabled', '3': 4, '4': 1, '5': 8, '10': 'enabled'},
  ],
  '8': [
    {'1': '_action'},
  ],
};

/// Descriptor for `CustomKeybind`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List customKeybindDescriptor = $convert.base64Decode(
    'Cg1DdXN0b21LZXliaW5kEg4KAmlkGAEgASgJUgJpZBIbCgZhY3Rpb24YAiABKAlIAFIGYWN0aW'
    '9uiAEBEj4KBWNvbWJvGAMgASgLMiguZmx1eGVyLnVzZXIucHJlZmVyZW5jZXMudjEuS2V5Ymlu'
    'ZENvbWJvUgVjb21ibxIYCgdlbmFibGVkGAQgASgIUgdlbmFibGVkQgkKB19hY3Rpb24=');

@$core.Deprecated('Use keybindComboDescriptor instead')
const KeybindCombo$json = {
  '1': 'KeybindCombo',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'code', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'code', '17': true},
    {'1': 'ctrl_or_meta', '3': 3, '4': 1, '5': 8, '10': 'ctrlOrMeta'},
    {'1': 'ctrl', '3': 4, '4': 1, '5': 8, '10': 'ctrl'},
    {'1': 'alt', '3': 5, '4': 1, '5': 8, '10': 'alt'},
    {'1': 'shift', '3': 6, '4': 1, '5': 8, '10': 'shift'},
    {'1': 'meta', '3': 7, '4': 1, '5': 8, '10': 'meta'},
    {'1': 'global', '3': 8, '4': 1, '5': 8, '9': 1, '10': 'global', '17': true},
    {
      '1': 'enabled',
      '3': 9,
      '4': 1,
      '5': 8,
      '9': 2,
      '10': 'enabled',
      '17': true
    },
    {'1': 'modifier_only', '3': 10, '4': 1, '5': 8, '10': 'modifierOnly'},
    {'1': 'both_sides', '3': 11, '4': 1, '5': 8, '10': 'bothSides'},
    {
      '1': 'mouse_button',
      '3': 12,
      '4': 1,
      '5': 13,
      '9': 3,
      '10': 'mouseButton',
      '17': true
    },
    {
      '1': 'gamepad_button',
      '3': 13,
      '4': 1,
      '5': 13,
      '9': 4,
      '10': 'gamepadButton',
      '17': true
    },
  ],
  '8': [
    {'1': '_code'},
    {'1': '_global'},
    {'1': '_enabled'},
    {'1': '_mouse_button'},
    {'1': '_gamepad_button'},
  ],
};

/// Descriptor for `KeybindCombo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keybindComboDescriptor = $convert.base64Decode(
    'CgxLZXliaW5kQ29tYm8SEAoDa2V5GAEgASgJUgNrZXkSFwoEY29kZRgCIAEoCUgAUgRjb2RliA'
    'EBEiAKDGN0cmxfb3JfbWV0YRgDIAEoCFIKY3RybE9yTWV0YRISCgRjdHJsGAQgASgIUgRjdHJs'
    'EhAKA2FsdBgFIAEoCFIDYWx0EhQKBXNoaWZ0GAYgASgIUgVzaGlmdBISCgRtZXRhGAcgASgIUg'
    'RtZXRhEhsKBmdsb2JhbBgIIAEoCEgBUgZnbG9iYWyIAQESHQoHZW5hYmxlZBgJIAEoCEgCUgdl'
    'bmFibGVkiAEBEiMKDW1vZGlmaWVyX29ubHkYCiABKAhSDG1vZGlmaWVyT25seRIdCgpib3RoX3'
    'NpZGVzGAsgASgIUglib3RoU2lkZXMSJgoMbW91c2VfYnV0dG9uGAwgASgNSANSC21vdXNlQnV0'
    'dG9uiAEBEioKDmdhbWVwYWRfYnV0dG9uGA0gASgNSARSDWdhbWVwYWRCdXR0b26IAQFCBwoFX2'
    'NvZGVCCQoHX2dsb2JhbEIKCghfZW5hYmxlZEIPCg1fbW91c2VfYnV0dG9uQhEKD19nYW1lcGFk'
    'X2J1dHRvbg==');

@$core.Deprecated('Use channelFrecencyEntryDescriptor instead')
const ChannelFrecencyEntry$json = {
  '1': 'ChannelFrecencyEntry',
  '2': [
    {'1': 'total_uses', '3': 1, '4': 1, '5': 13, '10': 'totalUses'},
    {'1': 'recent_uses_ms', '3': 2, '4': 3, '5': 3, '10': 'recentUsesMs'},
  ],
};

/// Descriptor for `ChannelFrecencyEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List channelFrecencyEntryDescriptor = $convert.base64Decode(
    'ChRDaGFubmVsRnJlY2VuY3lFbnRyeRIdCgp0b3RhbF91c2VzGAEgASgNUgl0b3RhbFVzZXMSJA'
    'oOcmVjZW50X3VzZXNfbXMYAiADKANSDHJlY2VudFVzZXNNcw==');

@$core.Deprecated('Use channelFrecencyStateDescriptor instead')
const ChannelFrecencyState$json = {
  '1': 'ChannelFrecencyState',
  '2': [
    {
      '1': 'usage',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.ChannelFrecencyState.UsageEntry',
      '10': 'usage'
    },
  ],
  '3': [ChannelFrecencyState_UsageEntry$json],
};

@$core.Deprecated('Use channelFrecencyStateDescriptor instead')
const ChannelFrecencyState_UsageEntry$json = {
  '1': 'UsageEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.ChannelFrecencyEntry',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

/// Descriptor for `ChannelFrecencyState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List channelFrecencyStateDescriptor = $convert.base64Decode(
    'ChRDaGFubmVsRnJlY2VuY3lTdGF0ZRJRCgV1c2FnZRgBIAMoCzI7LmZsdXhlci51c2VyLnByZW'
    'ZlcmVuY2VzLnYxLkNoYW5uZWxGcmVjZW5jeVN0YXRlLlVzYWdlRW50cnlSBXVzYWdlGmoKClVz'
    'YWdlRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSRgoFdmFsdWUYAiABKAsyMC5mbHV4ZXIudXNlci'
    '5wcmVmZXJlbmNlcy52MS5DaGFubmVsRnJlY2VuY3lFbnRyeVIFdmFsdWU6AjgB');

@$core.Deprecated('Use chatInputSettingsDescriptor instead')
const ChatInputSettings$json = {
  '1': 'ChatInputSettings',
  '2': [
    {
      '1': 'convert_emoticons',
      '3': 1,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'convertEmoticons',
      '17': true
    },
    {
      '1': 'save_camera_captures_to_device',
      '3': 2,
      '4': 1,
      '5': 8,
      '9': 1,
      '10': 'saveCameraCapturesToDevice',
      '17': true
    },
  ],
  '8': [
    {'1': '_convert_emoticons'},
    {'1': '_save_camera_captures_to_device'},
  ],
};

/// Descriptor for `ChatInputSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatInputSettingsDescriptor = $convert.base64Decode(
    'ChFDaGF0SW5wdXRTZXR0aW5ncxIwChFjb252ZXJ0X2Vtb3RpY29ucxgBIAEoCEgAUhBjb252ZX'
    'J0RW1vdGljb25ziAEBEkcKHnNhdmVfY2FtZXJhX2NhcHR1cmVzX3RvX2RldmljZRgCIAEoCEgB'
    'UhpzYXZlQ2FtZXJhQ2FwdHVyZXNUb0RldmljZYgBAUIUChJfY29udmVydF9lbW90aWNvbnNCIQ'
    'ofX3NhdmVfY2FtZXJhX2NhcHR1cmVzX3RvX2RldmljZQ==');

@$core.Deprecated('Use reactionEmojiDescriptor instead')
const ReactionEmoji$json = {
  '1': 'ReactionEmoji',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'id', '17': true},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
  ],
  '8': [
    {'1': '_id'},
  ],
};

/// Descriptor for `ReactionEmoji`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reactionEmojiDescriptor = $convert.base64Decode(
    'Cg1SZWFjdGlvbkVtb2ppEhMKAmlkGAEgASgJSABSAmlkiAEBEhIKBG5hbWUYAiABKAlSBG5hbW'
    'VCBQoDX2lk');
