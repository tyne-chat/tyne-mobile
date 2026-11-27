// This is a generated file - do not edit.
//
// Generated from fluxer/user/preferences/v1/accessibility.proto.

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

@$core.Deprecated('Use channelTypingIndicatorModeDescriptor instead')
const ChannelTypingIndicatorMode$json = {
  '1': 'ChannelTypingIndicatorMode',
  '2': [
    {'1': 'CHANNEL_TYPING_INDICATOR_MODE_UNSPECIFIED', '2': 0},
    {'1': 'CHANNEL_TYPING_INDICATOR_MODE_AVATARS', '2': 1},
    {'1': 'CHANNEL_TYPING_INDICATOR_MODE_INDICATOR_ONLY', '2': 2},
    {'1': 'CHANNEL_TYPING_INDICATOR_MODE_HIDDEN', '2': 3},
  ],
};

/// Descriptor for `ChannelTypingIndicatorMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List channelTypingIndicatorModeDescriptor = $convert.base64Decode(
    'ChpDaGFubmVsVHlwaW5nSW5kaWNhdG9yTW9kZRItCilDSEFOTkVMX1RZUElOR19JTkRJQ0FUT1'
    'JfTU9ERV9VTlNQRUNJRklFRBAAEikKJUNIQU5ORUxfVFlQSU5HX0lORElDQVRPUl9NT0RFX0FW'
    'QVRBUlMQARIwCixDSEFOTkVMX1RZUElOR19JTkRJQ0FUT1JfTU9ERV9JTkRJQ0FUT1JfT05MWR'
    'ACEigKJENIQU5ORUxfVFlQSU5HX0lORElDQVRPUl9NT0RFX0hJRERFThAD');

@$core.Deprecated('Use dmMessagePreviewModeDescriptor instead')
const DmMessagePreviewMode$json = {
  '1': 'DmMessagePreviewMode',
  '2': [
    {'1': 'DM_MESSAGE_PREVIEW_MODE_UNSPECIFIED', '2': 0},
    {'1': 'DM_MESSAGE_PREVIEW_MODE_ALL', '2': 1},
    {'1': 'DM_MESSAGE_PREVIEW_MODE_UNREAD_ONLY', '2': 2},
    {'1': 'DM_MESSAGE_PREVIEW_MODE_NONE', '2': 3},
  ],
};

/// Descriptor for `DmMessagePreviewMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List dmMessagePreviewModeDescriptor = $convert.base64Decode(
    'ChREbU1lc3NhZ2VQcmV2aWV3TW9kZRInCiNETV9NRVNTQUdFX1BSRVZJRVdfTU9ERV9VTlNQRU'
    'NJRklFRBAAEh8KG0RNX01FU1NBR0VfUFJFVklFV19NT0RFX0FMTBABEicKI0RNX01FU1NBR0Vf'
    'UFJFVklFV19NT0RFX1VOUkVBRF9PTkxZEAISIAocRE1fTUVTU0FHRV9QUkVWSUVXX01PREVfTk'
    '9ORRAD');

@$core.Deprecated('Use hdrDisplayModeDescriptor instead')
const HdrDisplayMode$json = {
  '1': 'HdrDisplayMode',
  '2': [
    {'1': 'HDR_DISPLAY_MODE_UNSPECIFIED', '2': 0},
    {'1': 'HDR_DISPLAY_MODE_FULL', '2': 1},
    {'1': 'HDR_DISPLAY_MODE_STANDARD', '2': 2},
  ],
};

/// Descriptor for `HdrDisplayMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List hdrDisplayModeDescriptor = $convert.base64Decode(
    'Cg5IZHJEaXNwbGF5TW9kZRIgChxIRFJfRElTUExBWV9NT0RFX1VOU1BFQ0lGSUVEEAASGQoVSE'
    'RSX0RJU1BMQVlfTU9ERV9GVUxMEAESHQoZSERSX0RJU1BMQVlfTU9ERV9TVEFOREFSRBAC');

@$core.Deprecated('Use accessibilitySettingsDescriptor instead')
const AccessibilitySettings$json = {
  '1': 'AccessibilitySettings',
  '2': [
    {
      '1': 'show_personas_button',
      '3': 2221,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'showPersonasButton',
      '17': true
    },
    {
      '1': 'show_message_action_bar_copy_button',
      '3': 2222,
      '4': 1,
      '5': 8,
      '9': 1,
      '10': 'showMessageActionBarCopyButton',
      '17': true
    },
    {
      '1': 'show_alt_text_on_images',
      '3': 2223,
      '4': 1,
      '5': 8,
      '9': 2,
      '10': 'showAltTextOnImages',
      '17': true
    },
    {
      '1': 'mobile_font_size',
      '3': 2224,
      '4': 1,
      '5': 1,
      '9': 3,
      '10': 'mobileFontSize',
      '17': true
    },
    {
      '1': 'mobile_message_group_spacing',
      '3': 2225,
      '4': 1,
      '5': 1,
      '9': 4,
      '10': 'mobileMessageGroupSpacing',
      '17': true
    },
    {
      '1': 'mobile_compact_message_group_spacing',
      '3': 2226,
      '4': 1,
      '5': 1,
      '9': 5,
      '10': 'mobileCompactMessageGroupSpacing',
      '17': true
    },
    {
      '1': 'message_double_click_edits',
      '3': 2227,
      '4': 1,
      '5': 8,
      '9': 6,
      '10': 'messageDoubleClickEdits',
      '17': true
    },
    {
      '1': 'message_double_click_replies',
      '3': 2228,
      '4': 1,
      '5': 8,
      '9': 7,
      '10': 'messageDoubleClickReplies',
      '17': true
    },
    {
      '1': 'space_after_emoji',
      '3': 2229,
      '4': 1,
      '5': 8,
      '9': 8,
      '10': 'spaceAfterEmoji',
      '17': true
    },
    {
      '1': 'saturation_factor',
      '3': 1,
      '4': 1,
      '5': 1,
      '9': 9,
      '10': 'saturationFactor',
      '17': true
    },
    {
      '1': 'always_underline_links',
      '3': 2,
      '4': 1,
      '5': 8,
      '10': 'alwaysUnderlineLinks'
    },
    {
      '1': 'enable_text_selection',
      '3': 3,
      '4': 1,
      '5': 8,
      '9': 10,
      '10': 'enableTextSelection',
      '17': true
    },
    {
      '1': 'show_message_send_button',
      '3': 4,
      '4': 1,
      '5': 8,
      '9': 11,
      '10': 'showMessageSendButton',
      '17': true
    },
    {
      '1': 'show_textarea_focus_ring',
      '3': 5,
      '4': 1,
      '5': 8,
      '9': 12,
      '10': 'showTextareaFocusRing',
      '17': true
    },
    {
      '1': 'hide_keyboard_hints',
      '3': 6,
      '4': 1,
      '5': 8,
      '10': 'hideKeyboardHints'
    },
    {
      '1': 'escape_exits_keyboard_mode',
      '3': 7,
      '4': 1,
      '5': 8,
      '9': 13,
      '10': 'escapeExitsKeyboardMode',
      '17': true
    },
    {
      '1': 'sync_reduced_motion_with_system',
      '3': 8,
      '4': 1,
      '5': 8,
      '9': 14,
      '10': 'syncReducedMotionWithSystem',
      '17': true
    },
    {
      '1': 'reduced_motion_override',
      '3': 9,
      '4': 1,
      '5': 8,
      '9': 15,
      '10': 'reducedMotionOverride',
      '17': true
    },
    {
      '1': 'message_group_spacing',
      '3': 10,
      '4': 1,
      '5': 1,
      '9': 16,
      '10': 'messageGroupSpacing',
      '17': true
    },
    {
      '1': 'message_gutter',
      '3': 11,
      '4': 1,
      '5': 1,
      '9': 17,
      '10': 'messageGutter',
      '17': true
    },
    {
      '1': 'font_size',
      '3': 12,
      '4': 1,
      '5': 1,
      '9': 18,
      '10': 'fontSize',
      '17': true
    },
    {
      '1': 'show_user_avatars_in_compact_mode',
      '3': 13,
      '4': 1,
      '5': 8,
      '9': 19,
      '10': 'showUserAvatarsInCompactMode',
      '17': true
    },
    {
      '1': 'mobile_sticker_animation_overridden',
      '3': 14,
      '4': 1,
      '5': 8,
      '10': 'mobileStickerAnimationOverridden'
    },
    {
      '1': 'mobile_gif_autoplay_overridden',
      '3': 15,
      '4': 1,
      '5': 8,
      '10': 'mobileGifAutoplayOverridden'
    },
    {
      '1': 'mobile_animate_emoji_overridden',
      '3': 16,
      '4': 1,
      '5': 8,
      '10': 'mobileAnimateEmojiOverridden'
    },
    {
      '1': 'mobile_sticker_animation_value',
      '3': 17,
      '4': 1,
      '5': 5,
      '9': 20,
      '10': 'mobileStickerAnimationValue',
      '17': true
    },
    {
      '1': 'mobile_gif_autoplay_value',
      '3': 18,
      '4': 1,
      '5': 8,
      '9': 21,
      '10': 'mobileGifAutoplayValue',
      '17': true
    },
    {
      '1': 'mobile_animate_emoji_value',
      '3': 19,
      '4': 1,
      '5': 8,
      '9': 22,
      '10': 'mobileAnimateEmojiValue',
      '17': true
    },
    {
      '1': 'auto_send_klipy_gifs',
      '3': 20,
      '4': 1,
      '5': 8,
      '9': 23,
      '10': 'autoSendKlipyGifs',
      '17': true
    },
    {
      '1': 'show_gif_button',
      '3': 21,
      '4': 1,
      '5': 8,
      '9': 24,
      '10': 'showGifButton',
      '17': true
    },
    {
      '1': 'show_memes_button',
      '3': 22,
      '4': 1,
      '5': 8,
      '9': 25,
      '10': 'showMemesButton',
      '17': true
    },
    {
      '1': 'show_stickers_button',
      '3': 23,
      '4': 1,
      '5': 8,
      '9': 26,
      '10': 'showStickersButton',
      '17': true
    },
    {
      '1': 'show_emoji_button',
      '3': 24,
      '4': 1,
      '5': 8,
      '9': 27,
      '10': 'showEmojiButton',
      '17': true
    },
    {
      '1': 'show_media_favorite_button',
      '3': 25,
      '4': 1,
      '5': 8,
      '9': 28,
      '10': 'showMediaFavoriteButton',
      '17': true
    },
    {
      '1': 'show_media_download_button',
      '3': 26,
      '4': 1,
      '5': 8,
      '9': 29,
      '10': 'showMediaDownloadButton',
      '17': true
    },
    {
      '1': 'show_media_delete_button',
      '3': 27,
      '4': 1,
      '5': 8,
      '9': 30,
      '10': 'showMediaDeleteButton',
      '17': true
    },
    {
      '1': 'show_suppress_embeds_button',
      '3': 28,
      '4': 1,
      '5': 8,
      '9': 31,
      '10': 'showSuppressEmbedsButton',
      '17': true
    },
    {
      '1': 'show_gif_indicator',
      '3': 29,
      '4': 1,
      '5': 8,
      '9': 32,
      '10': 'showGifIndicator',
      '17': true
    },
    {
      '1': 'show_attachment_expiry_indicator',
      '3': 30,
      '4': 1,
      '5': 8,
      '9': 33,
      '10': 'showAttachmentExpiryIndicator',
      '17': true
    },
    {
      '1': 'channel_typing_indicator_mode',
      '3': 32,
      '4': 1,
      '5': 14,
      '6': '.fluxer.user.preferences.v1.ChannelTypingIndicatorMode',
      '10': 'channelTypingIndicatorMode'
    },
    {
      '1': 'show_selected_channel_typing_indicator',
      '3': 33,
      '4': 1,
      '5': 8,
      '9': 34,
      '10': 'showSelectedChannelTypingIndicator',
      '17': true
    },
    {
      '1': 'show_message_action_bar',
      '3': 34,
      '4': 1,
      '5': 8,
      '9': 35,
      '10': 'showMessageActionBar',
      '17': true
    },
    {
      '1': 'show_message_action_bar_quick_reactions',
      '3': 35,
      '4': 1,
      '5': 8,
      '9': 36,
      '10': 'showMessageActionBarQuickReactions',
      '17': true
    },
    {
      '1': 'show_message_action_bar_shift_expand',
      '3': 36,
      '4': 1,
      '5': 8,
      '9': 37,
      '10': 'showMessageActionBarShiftExpand',
      '17': true
    },
    {
      '1': 'show_message_action_bar_only_more_button',
      '3': 37,
      '4': 1,
      '5': 8,
      '9': 38,
      '10': 'showMessageActionBarOnlyMoreButton',
      '17': true
    },
    {
      '1': 'show_default_emojis_in_autocomplete',
      '3': 38,
      '4': 1,
      '5': 8,
      '9': 39,
      '10': 'showDefaultEmojisInAutocomplete',
      '17': true
    },
    {
      '1': 'show_custom_emojis_in_autocomplete',
      '3': 39,
      '4': 1,
      '5': 8,
      '9': 40,
      '10': 'showCustomEmojisInAutocomplete',
      '17': true
    },
    {
      '1': 'show_stickers_in_autocomplete',
      '3': 40,
      '4': 1,
      '5': 8,
      '9': 41,
      '10': 'showStickersInAutocomplete',
      '17': true
    },
    {
      '1': 'show_memes_in_autocomplete',
      '3': 41,
      '4': 1,
      '5': 8,
      '9': 42,
      '10': 'showMemesInAutocomplete',
      '17': true
    },
    {
      '1': 'voice_channel_join_requires_double_click',
      '3': 44,
      '4': 1,
      '5': 8,
      '9': 43,
      '10': 'voiceChannelJoinRequiresDoubleClick',
      '17': true
    },
    {
      '1': 'custom_theme_css',
      '3': 45,
      '4': 1,
      '5': 9,
      '9': 44,
      '10': 'customThemeCss',
      '17': true
    },
    {
      '1': 'show_favorites',
      '3': 46,
      '4': 1,
      '5': 8,
      '9': 45,
      '10': 'showFavorites',
      '17': true
    },
    {
      '1': 'zoom_level',
      '3': 47,
      '4': 1,
      '5': 1,
      '9': 46,
      '10': 'zoomLevel',
      '17': true
    },
    {
      '1': 'dm_message_preview_mode',
      '3': 48,
      '4': 1,
      '5': 14,
      '6': '.fluxer.user.preferences.v1.DmMessagePreviewMode',
      '10': 'dmMessagePreviewMode'
    },
    {
      '1': 'enable_tts_command',
      '3': 49,
      '4': 1,
      '5': 8,
      '9': 47,
      '10': 'enableTtsCommand',
      '17': true
    },
    {
      '1': 'tts_rate',
      '3': 50,
      '4': 1,
      '5': 1,
      '9': 48,
      '10': 'ttsRate',
      '17': true
    },
    {
      '1': 'show_faded_unread_on_muted_channels',
      '3': 51,
      '4': 1,
      '5': 8,
      '9': 49,
      '10': 'showFadedUnreadOnMutedChannels',
      '17': true
    },
    {
      '1': 'show_context_menu_shortcuts',
      '3': 52,
      '4': 1,
      '5': 8,
      '9': 50,
      '10': 'showContextMenuShortcuts',
      '17': true
    },
    {
      '1': 'confirm_before_starting_calls',
      '3': 53,
      '4': 1,
      '5': 8,
      '9': 51,
      '10': 'confirmBeforeStartingCalls',
      '17': true
    },
    {
      '1': 'hdr_display_mode',
      '3': 54,
      '4': 1,
      '5': 14,
      '6': '.fluxer.user.preferences.v1.HdrDisplayMode',
      '10': 'hdrDisplayMode'
    },
    {
      '1': 'preserve_edit_draft',
      '3': 55,
      '4': 1,
      '5': 8,
      '9': 52,
      '10': 'preserveEditDraft',
      '17': true
    },
    {
      '1': 'stay_interactive_when_unfocused',
      '3': 56,
      '4': 1,
      '5': 8,
      '9': 53,
      '10': 'stayInteractiveWhenUnfocused',
      '17': true
    },
    {
      '1': 'confirm_before_joining_voice_channels',
      '3': 57,
      '4': 1,
      '5': 8,
      '9': 54,
      '10': 'confirmBeforeJoiningVoiceChannels',
      '17': true
    },
    {
      '1': 'screen_reader_announce_new_messages',
      '3': 58,
      '4': 1,
      '5': 8,
      '9': 55,
      '10': 'screenReaderAnnounceNewMessages',
      '17': true
    },
    {
      '1': 'first_click_pass_through_when_unfocused',
      '3': 59,
      '4': 1,
      '5': 8,
      '9': 56,
      '10': 'firstClickPassThroughWhenUnfocused',
      '17': true
    },
    {
      '1': 'compact_message_group_spacing',
      '3': 60,
      '4': 1,
      '5': 1,
      '9': 57,
      '10': 'compactMessageGroupSpacing',
      '17': true
    },
    {
      '1': 'scroll_to_bottom_on_message_send',
      '3': 61,
      '4': 1,
      '5': 8,
      '9': 58,
      '10': 'scrollToBottomOnMessageSend',
      '17': true
    },
    {
      '1': 'dim_strikethrough_text',
      '3': 62,
      '4': 1,
      '5': 8,
      '9': 59,
      '10': 'dimStrikethroughText',
      '17': true
    },
    {
      '1': 'sequential_file_send',
      '3': 63,
      '4': 1,
      '5': 8,
      '9': 60,
      '10': 'sequentialFileSend',
      '17': true
    },
    {
      '1': 'mobile_splash_zoom_animation',
      '3': 64,
      '4': 1,
      '5': 8,
      '9': 61,
      '10': 'mobileSplashZoomAnimation',
      '17': true
    },
    {
      '1': 'message_double_click_actions',
      '3': 66,
      '4': 1,
      '5': 8,
      '9': 62,
      '10': 'messageDoubleClickActions',
      '17': true
    },
    {
      '1': 'announce_call_joins_and_leaves',
      '3': 67,
      '4': 1,
      '5': 8,
      '9': 63,
      '10': 'announceCallJoinsAndLeaves',
      '17': true
    },
    {
      '1': 'animate_gif_picker',
      '3': 68,
      '4': 1,
      '5': 8,
      '9': 64,
      '10': 'animateGifPicker',
      '17': true
    },
  ],
  '8': [
    {'1': '_show_personas_button'},
    {'1': '_show_message_action_bar_copy_button'},
    {'1': '_show_alt_text_on_images'},
    {'1': '_mobile_font_size'},
    {'1': '_mobile_message_group_spacing'},
    {'1': '_mobile_compact_message_group_spacing'},
    {'1': '_message_double_click_edits'},
    {'1': '_message_double_click_replies'},
    {'1': '_space_after_emoji'},
    {'1': '_saturation_factor'},
    {'1': '_enable_text_selection'},
    {'1': '_show_message_send_button'},
    {'1': '_show_textarea_focus_ring'},
    {'1': '_escape_exits_keyboard_mode'},
    {'1': '_sync_reduced_motion_with_system'},
    {'1': '_reduced_motion_override'},
    {'1': '_message_group_spacing'},
    {'1': '_message_gutter'},
    {'1': '_font_size'},
    {'1': '_show_user_avatars_in_compact_mode'},
    {'1': '_mobile_sticker_animation_value'},
    {'1': '_mobile_gif_autoplay_value'},
    {'1': '_mobile_animate_emoji_value'},
    {'1': '_auto_send_klipy_gifs'},
    {'1': '_show_gif_button'},
    {'1': '_show_memes_button'},
    {'1': '_show_stickers_button'},
    {'1': '_show_emoji_button'},
    {'1': '_show_media_favorite_button'},
    {'1': '_show_media_download_button'},
    {'1': '_show_media_delete_button'},
    {'1': '_show_suppress_embeds_button'},
    {'1': '_show_gif_indicator'},
    {'1': '_show_attachment_expiry_indicator'},
    {'1': '_show_selected_channel_typing_indicator'},
    {'1': '_show_message_action_bar'},
    {'1': '_show_message_action_bar_quick_reactions'},
    {'1': '_show_message_action_bar_shift_expand'},
    {'1': '_show_message_action_bar_only_more_button'},
    {'1': '_show_default_emojis_in_autocomplete'},
    {'1': '_show_custom_emojis_in_autocomplete'},
    {'1': '_show_stickers_in_autocomplete'},
    {'1': '_show_memes_in_autocomplete'},
    {'1': '_voice_channel_join_requires_double_click'},
    {'1': '_custom_theme_css'},
    {'1': '_show_favorites'},
    {'1': '_zoom_level'},
    {'1': '_enable_tts_command'},
    {'1': '_tts_rate'},
    {'1': '_show_faded_unread_on_muted_channels'},
    {'1': '_show_context_menu_shortcuts'},
    {'1': '_confirm_before_starting_calls'},
    {'1': '_preserve_edit_draft'},
    {'1': '_stay_interactive_when_unfocused'},
    {'1': '_confirm_before_joining_voice_channels'},
    {'1': '_screen_reader_announce_new_messages'},
    {'1': '_first_click_pass_through_when_unfocused'},
    {'1': '_compact_message_group_spacing'},
    {'1': '_scroll_to_bottom_on_message_send'},
    {'1': '_dim_strikethrough_text'},
    {'1': '_sequential_file_send'},
    {'1': '_mobile_splash_zoom_animation'},
    {'1': '_message_double_click_actions'},
    {'1': '_announce_call_joins_and_leaves'},
    {'1': '_animate_gif_picker'},
  ],
  '9': [
    {'1': 31, '2': 32},
    {'1': 42, '2': 43},
    {'1': 43, '2': 44},
    {'1': 65, '2': 66},
  ],
  '10': [
    'use_browser_locale_for_time_format',
    'attachment_media_dimension_size',
    'embed_media_dimension_size',
    'double_click_message_actions'
  ],
};

/// Descriptor for `AccessibilitySettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List accessibilitySettingsDescriptor = $convert.base64Decode(
    'ChVBY2Nlc3NpYmlsaXR5U2V0dGluZ3MSNgoUc2hvd19wZXJzb25hc19idXR0b24YrREgASgISA'
    'BSEnNob3dQZXJzb25hc0J1dHRvbogBARJRCiNzaG93X21lc3NhZ2VfYWN0aW9uX2Jhcl9jb3B5'
    'X2J1dHRvbhiuESABKAhIAVIec2hvd01lc3NhZ2VBY3Rpb25CYXJDb3B5QnV0dG9uiAEBEjoKF3'
    'Nob3dfYWx0X3RleHRfb25faW1hZ2VzGK8RIAEoCEgCUhNzaG93QWx0VGV4dE9uSW1hZ2VziAEB'
    'Ei4KEG1vYmlsZV9mb250X3NpemUYsBEgASgBSANSDm1vYmlsZUZvbnRTaXpliAEBEkUKHG1vYm'
    'lsZV9tZXNzYWdlX2dyb3VwX3NwYWNpbmcYsREgASgBSARSGW1vYmlsZU1lc3NhZ2VHcm91cFNw'
    'YWNpbmeIAQESVAokbW9iaWxlX2NvbXBhY3RfbWVzc2FnZV9ncm91cF9zcGFjaW5nGLIRIAEoAU'
    'gFUiBtb2JpbGVDb21wYWN0TWVzc2FnZUdyb3VwU3BhY2luZ4gBARJBChptZXNzYWdlX2RvdWJs'
    'ZV9jbGlja19lZGl0cxizESABKAhIBlIXbWVzc2FnZURvdWJsZUNsaWNrRWRpdHOIAQESRQocbW'
    'Vzc2FnZV9kb3VibGVfY2xpY2tfcmVwbGllcxi0ESABKAhIB1IZbWVzc2FnZURvdWJsZUNsaWNr'
    'UmVwbGllc4gBARIwChFzcGFjZV9hZnRlcl9lbW9qaRi1ESABKAhICFIPc3BhY2VBZnRlckVtb2'
    'ppiAEBEjAKEXNhdHVyYXRpb25fZmFjdG9yGAEgASgBSAlSEHNhdHVyYXRpb25GYWN0b3KIAQES'
    'NAoWYWx3YXlzX3VuZGVybGluZV9saW5rcxgCIAEoCFIUYWx3YXlzVW5kZXJsaW5lTGlua3MSNw'
    'oVZW5hYmxlX3RleHRfc2VsZWN0aW9uGAMgASgISApSE2VuYWJsZVRleHRTZWxlY3Rpb26IAQES'
    'PAoYc2hvd19tZXNzYWdlX3NlbmRfYnV0dG9uGAQgASgISAtSFXNob3dNZXNzYWdlU2VuZEJ1dH'
    'RvbogBARI8ChhzaG93X3RleHRhcmVhX2ZvY3VzX3JpbmcYBSABKAhIDFIVc2hvd1RleHRhcmVh'
    'Rm9jdXNSaW5niAEBEi4KE2hpZGVfa2V5Ym9hcmRfaGludHMYBiABKAhSEWhpZGVLZXlib2FyZE'
    'hpbnRzEkAKGmVzY2FwZV9leGl0c19rZXlib2FyZF9tb2RlGAcgASgISA1SF2VzY2FwZUV4aXRz'
    'S2V5Ym9hcmRNb2RliAEBEkkKH3N5bmNfcmVkdWNlZF9tb3Rpb25fd2l0aF9zeXN0ZW0YCCABKA'
    'hIDlIbc3luY1JlZHVjZWRNb3Rpb25XaXRoU3lzdGVtiAEBEjsKF3JlZHVjZWRfbW90aW9uX292'
    'ZXJyaWRlGAkgASgISA9SFXJlZHVjZWRNb3Rpb25PdmVycmlkZYgBARI3ChVtZXNzYWdlX2dyb3'
    'VwX3NwYWNpbmcYCiABKAFIEFITbWVzc2FnZUdyb3VwU3BhY2luZ4gBARIqCg5tZXNzYWdlX2d1'
    'dHRlchgLIAEoAUgRUg1tZXNzYWdlR3V0dGVyiAEBEiAKCWZvbnRfc2l6ZRgMIAEoAUgSUghmb2'
    '50U2l6ZYgBARJMCiFzaG93X3VzZXJfYXZhdGFyc19pbl9jb21wYWN0X21vZGUYDSABKAhIE1Ic'
    'c2hvd1VzZXJBdmF0YXJzSW5Db21wYWN0TW9kZYgBARJNCiNtb2JpbGVfc3RpY2tlcl9hbmltYX'
    'Rpb25fb3ZlcnJpZGRlbhgOIAEoCFIgbW9iaWxlU3RpY2tlckFuaW1hdGlvbk92ZXJyaWRkZW4S'
    'QwoebW9iaWxlX2dpZl9hdXRvcGxheV9vdmVycmlkZGVuGA8gASgIUhttb2JpbGVHaWZBdXRvcG'
    'xheU92ZXJyaWRkZW4SRQofbW9iaWxlX2FuaW1hdGVfZW1vamlfb3ZlcnJpZGRlbhgQIAEoCFIc'
    'bW9iaWxlQW5pbWF0ZUVtb2ppT3ZlcnJpZGRlbhJICh5tb2JpbGVfc3RpY2tlcl9hbmltYXRpb2'
    '5fdmFsdWUYESABKAVIFFIbbW9iaWxlU3RpY2tlckFuaW1hdGlvblZhbHVliAEBEj4KGW1vYmls'
    'ZV9naWZfYXV0b3BsYXlfdmFsdWUYEiABKAhIFVIWbW9iaWxlR2lmQXV0b3BsYXlWYWx1ZYgBAR'
    'JAChptb2JpbGVfYW5pbWF0ZV9lbW9qaV92YWx1ZRgTIAEoCEgWUhdtb2JpbGVBbmltYXRlRW1v'
    'amlWYWx1ZYgBARI0ChRhdXRvX3NlbmRfa2xpcHlfZ2lmcxgUIAEoCEgXUhFhdXRvU2VuZEtsaX'
    'B5R2lmc4gBARIrCg9zaG93X2dpZl9idXR0b24YFSABKAhIGFINc2hvd0dpZkJ1dHRvbogBARIv'
    'ChFzaG93X21lbWVzX2J1dHRvbhgWIAEoCEgZUg9zaG93TWVtZXNCdXR0b26IAQESNQoUc2hvd1'
    '9zdGlja2Vyc19idXR0b24YFyABKAhIGlISc2hvd1N0aWNrZXJzQnV0dG9uiAEBEi8KEXNob3df'
    'ZW1vamlfYnV0dG9uGBggASgISBtSD3Nob3dFbW9qaUJ1dHRvbogBARJAChpzaG93X21lZGlhX2'
    'Zhdm9yaXRlX2J1dHRvbhgZIAEoCEgcUhdzaG93TWVkaWFGYXZvcml0ZUJ1dHRvbogBARJAChpz'
    'aG93X21lZGlhX2Rvd25sb2FkX2J1dHRvbhgaIAEoCEgdUhdzaG93TWVkaWFEb3dubG9hZEJ1dH'
    'RvbogBARI8ChhzaG93X21lZGlhX2RlbGV0ZV9idXR0b24YGyABKAhIHlIVc2hvd01lZGlhRGVs'
    'ZXRlQnV0dG9uiAEBEkIKG3Nob3dfc3VwcHJlc3NfZW1iZWRzX2J1dHRvbhgcIAEoCEgfUhhzaG'
    '93U3VwcHJlc3NFbWJlZHNCdXR0b26IAQESMQoSc2hvd19naWZfaW5kaWNhdG9yGB0gASgISCBS'
    'EHNob3dHaWZJbmRpY2F0b3KIAQESTAogc2hvd19hdHRhY2htZW50X2V4cGlyeV9pbmRpY2F0b3'
    'IYHiABKAhIIVIdc2hvd0F0dGFjaG1lbnRFeHBpcnlJbmRpY2F0b3KIAQESeQodY2hhbm5lbF90'
    'eXBpbmdfaW5kaWNhdG9yX21vZGUYICABKA4yNi5mbHV4ZXIudXNlci5wcmVmZXJlbmNlcy52MS'
    '5DaGFubmVsVHlwaW5nSW5kaWNhdG9yTW9kZVIaY2hhbm5lbFR5cGluZ0luZGljYXRvck1vZGUS'
    'Vwomc2hvd19zZWxlY3RlZF9jaGFubmVsX3R5cGluZ19pbmRpY2F0b3IYISABKAhIIlIic2hvd1'
    'NlbGVjdGVkQ2hhbm5lbFR5cGluZ0luZGljYXRvcogBARI6ChdzaG93X21lc3NhZ2VfYWN0aW9u'
    'X2JhchgiIAEoCEgjUhRzaG93TWVzc2FnZUFjdGlvbkJhcogBARJYCidzaG93X21lc3NhZ2VfYW'
    'N0aW9uX2Jhcl9xdWlja19yZWFjdGlvbnMYIyABKAhIJFIic2hvd01lc3NhZ2VBY3Rpb25CYXJR'
    'dWlja1JlYWN0aW9uc4gBARJSCiRzaG93X21lc3NhZ2VfYWN0aW9uX2Jhcl9zaGlmdF9leHBhbm'
    'QYJCABKAhIJVIfc2hvd01lc3NhZ2VBY3Rpb25CYXJTaGlmdEV4cGFuZIgBARJZCihzaG93X21l'
    'c3NhZ2VfYWN0aW9uX2Jhcl9vbmx5X21vcmVfYnV0dG9uGCUgASgISCZSInNob3dNZXNzYWdlQW'
    'N0aW9uQmFyT25seU1vcmVCdXR0b26IAQESUQojc2hvd19kZWZhdWx0X2Vtb2ppc19pbl9hdXRv'
    'Y29tcGxldGUYJiABKAhIJ1Ifc2hvd0RlZmF1bHRFbW9qaXNJbkF1dG9jb21wbGV0ZYgBARJPCi'
    'JzaG93X2N1c3RvbV9lbW9qaXNfaW5fYXV0b2NvbXBsZXRlGCcgASgISChSHnNob3dDdXN0b21F'
    'bW9qaXNJbkF1dG9jb21wbGV0ZYgBARJGCh1zaG93X3N0aWNrZXJzX2luX2F1dG9jb21wbGV0ZR'
    'goIAEoCEgpUhpzaG93U3RpY2tlcnNJbkF1dG9jb21wbGV0ZYgBARJAChpzaG93X21lbWVzX2lu'
    'X2F1dG9jb21wbGV0ZRgpIAEoCEgqUhdzaG93TWVtZXNJbkF1dG9jb21wbGV0ZYgBARJaCih2b2'
    'ljZV9jaGFubmVsX2pvaW5fcmVxdWlyZXNfZG91YmxlX2NsaWNrGCwgASgISCtSI3ZvaWNlQ2hh'
    'bm5lbEpvaW5SZXF1aXJlc0RvdWJsZUNsaWNriAEBEi0KEGN1c3RvbV90aGVtZV9jc3MYLSABKA'
    'lILFIOY3VzdG9tVGhlbWVDc3OIAQESKgoOc2hvd19mYXZvcml0ZXMYLiABKAhILVINc2hvd0Zh'
    'dm9yaXRlc4gBARIiCgp6b29tX2xldmVsGC8gASgBSC5SCXpvb21MZXZlbIgBARJnChdkbV9tZX'
    'NzYWdlX3ByZXZpZXdfbW9kZRgwIAEoDjIwLmZsdXhlci51c2VyLnByZWZlcmVuY2VzLnYxLkRt'
    'TWVzc2FnZVByZXZpZXdNb2RlUhRkbU1lc3NhZ2VQcmV2aWV3TW9kZRIxChJlbmFibGVfdHRzX2'
    'NvbW1hbmQYMSABKAhIL1IQZW5hYmxlVHRzQ29tbWFuZIgBARIeCgh0dHNfcmF0ZRgyIAEoAUgw'
    'Ugd0dHNSYXRliAEBElAKI3Nob3dfZmFkZWRfdW5yZWFkX29uX211dGVkX2NoYW5uZWxzGDMgAS'
    'gISDFSHnNob3dGYWRlZFVucmVhZE9uTXV0ZWRDaGFubmVsc4gBARJCChtzaG93X2NvbnRleHRf'
    'bWVudV9zaG9ydGN1dHMYNCABKAhIMlIYc2hvd0NvbnRleHRNZW51U2hvcnRjdXRziAEBEkYKHW'
    'NvbmZpcm1fYmVmb3JlX3N0YXJ0aW5nX2NhbGxzGDUgASgISDNSGmNvbmZpcm1CZWZvcmVTdGFy'
    'dGluZ0NhbGxziAEBElQKEGhkcl9kaXNwbGF5X21vZGUYNiABKA4yKi5mbHV4ZXIudXNlci5wcm'
    'VmZXJlbmNlcy52MS5IZHJEaXNwbGF5TW9kZVIOaGRyRGlzcGxheU1vZGUSMwoTcHJlc2VydmVf'
    'ZWRpdF9kcmFmdBg3IAEoCEg0UhFwcmVzZXJ2ZUVkaXREcmFmdIgBARJKCh9zdGF5X2ludGVyYW'
    'N0aXZlX3doZW5fdW5mb2N1c2VkGDggASgISDVSHHN0YXlJbnRlcmFjdGl2ZVdoZW5VbmZvY3Vz'
    'ZWSIAQESVQolY29uZmlybV9iZWZvcmVfam9pbmluZ192b2ljZV9jaGFubmVscxg5IAEoCEg2Ui'
    'Fjb25maXJtQmVmb3JlSm9pbmluZ1ZvaWNlQ2hhbm5lbHOIAQESUQojc2NyZWVuX3JlYWRlcl9h'
    'bm5vdW5jZV9uZXdfbWVzc2FnZXMYOiABKAhIN1Ifc2NyZWVuUmVhZGVyQW5ub3VuY2VOZXdNZX'
    'NzYWdlc4gBARJYCidmaXJzdF9jbGlja19wYXNzX3Rocm91Z2hfd2hlbl91bmZvY3VzZWQYOyAB'
    'KAhIOFIiZmlyc3RDbGlja1Bhc3NUaHJvdWdoV2hlblVuZm9jdXNlZIgBARJGCh1jb21wYWN0X2'
    '1lc3NhZ2VfZ3JvdXBfc3BhY2luZxg8IAEoAUg5Uhpjb21wYWN0TWVzc2FnZUdyb3VwU3BhY2lu'
    'Z4gBARJKCiBzY3JvbGxfdG9fYm90dG9tX29uX21lc3NhZ2Vfc2VuZBg9IAEoCEg6UhtzY3JvbG'
    'xUb0JvdHRvbU9uTWVzc2FnZVNlbmSIAQESOQoWZGltX3N0cmlrZXRocm91Z2hfdGV4dBg+IAEo'
    'CEg7UhRkaW1TdHJpa2V0aHJvdWdoVGV4dIgBARI1ChRzZXF1ZW50aWFsX2ZpbGVfc2VuZBg/IA'
    'EoCEg8UhJzZXF1ZW50aWFsRmlsZVNlbmSIAQESRAocbW9iaWxlX3NwbGFzaF96b29tX2FuaW1h'
    'dGlvbhhAIAEoCEg9Uhltb2JpbGVTcGxhc2hab29tQW5pbWF0aW9uiAEBEkQKHG1lc3NhZ2VfZG'
    '91YmxlX2NsaWNrX2FjdGlvbnMYQiABKAhIPlIZbWVzc2FnZURvdWJsZUNsaWNrQWN0aW9uc4gB'
    'ARJHCh5hbm5vdW5jZV9jYWxsX2pvaW5zX2FuZF9sZWF2ZXMYQyABKAhIP1IaYW5ub3VuY2VDYW'
    'xsSm9pbnNBbmRMZWF2ZXOIAQESMQoSYW5pbWF0ZV9naWZfcGlja2VyGEQgASgISEBSEGFuaW1h'
    'dGVHaWZQaWNrZXKIAQFCFwoVX3Nob3dfcGVyc29uYXNfYnV0dG9uQiYKJF9zaG93X21lc3NhZ2'
    'VfYWN0aW9uX2Jhcl9jb3B5X2J1dHRvbkIaChhfc2hvd19hbHRfdGV4dF9vbl9pbWFnZXNCEwoR'
    'X21vYmlsZV9mb250X3NpemVCHwodX21vYmlsZV9tZXNzYWdlX2dyb3VwX3NwYWNpbmdCJwolX2'
    '1vYmlsZV9jb21wYWN0X21lc3NhZ2VfZ3JvdXBfc3BhY2luZ0IdChtfbWVzc2FnZV9kb3VibGVf'
    'Y2xpY2tfZWRpdHNCHwodX21lc3NhZ2VfZG91YmxlX2NsaWNrX3JlcGxpZXNCFAoSX3NwYWNlX2'
    'FmdGVyX2Vtb2ppQhQKEl9zYXR1cmF0aW9uX2ZhY3RvckIYChZfZW5hYmxlX3RleHRfc2VsZWN0'
    'aW9uQhsKGV9zaG93X21lc3NhZ2Vfc2VuZF9idXR0b25CGwoZX3Nob3dfdGV4dGFyZWFfZm9jdX'
    'NfcmluZ0IdChtfZXNjYXBlX2V4aXRzX2tleWJvYXJkX21vZGVCIgogX3N5bmNfcmVkdWNlZF9t'
    'b3Rpb25fd2l0aF9zeXN0ZW1CGgoYX3JlZHVjZWRfbW90aW9uX292ZXJyaWRlQhgKFl9tZXNzYW'
    'dlX2dyb3VwX3NwYWNpbmdCEQoPX21lc3NhZ2VfZ3V0dGVyQgwKCl9mb250X3NpemVCJAoiX3No'
    'b3dfdXNlcl9hdmF0YXJzX2luX2NvbXBhY3RfbW9kZUIhCh9fbW9iaWxlX3N0aWNrZXJfYW5pbW'
    'F0aW9uX3ZhbHVlQhwKGl9tb2JpbGVfZ2lmX2F1dG9wbGF5X3ZhbHVlQh0KG19tb2JpbGVfYW5p'
    'bWF0ZV9lbW9qaV92YWx1ZUIXChVfYXV0b19zZW5kX2tsaXB5X2dpZnNCEgoQX3Nob3dfZ2lmX2'
    'J1dHRvbkIUChJfc2hvd19tZW1lc19idXR0b25CFwoVX3Nob3dfc3RpY2tlcnNfYnV0dG9uQhQK'
    'El9zaG93X2Vtb2ppX2J1dHRvbkIdChtfc2hvd19tZWRpYV9mYXZvcml0ZV9idXR0b25CHQobX3'
    'Nob3dfbWVkaWFfZG93bmxvYWRfYnV0dG9uQhsKGV9zaG93X21lZGlhX2RlbGV0ZV9idXR0b25C'
    'HgocX3Nob3dfc3VwcHJlc3NfZW1iZWRzX2J1dHRvbkIVChNfc2hvd19naWZfaW5kaWNhdG9yQi'
    'MKIV9zaG93X2F0dGFjaG1lbnRfZXhwaXJ5X2luZGljYXRvckIpCidfc2hvd19zZWxlY3RlZF9j'
    'aGFubmVsX3R5cGluZ19pbmRpY2F0b3JCGgoYX3Nob3dfbWVzc2FnZV9hY3Rpb25fYmFyQioKKF'
    '9zaG93X21lc3NhZ2VfYWN0aW9uX2Jhcl9xdWlja19yZWFjdGlvbnNCJwolX3Nob3dfbWVzc2Fn'
    'ZV9hY3Rpb25fYmFyX3NoaWZ0X2V4cGFuZEIrCilfc2hvd19tZXNzYWdlX2FjdGlvbl9iYXJfb2'
    '5seV9tb3JlX2J1dHRvbkImCiRfc2hvd19kZWZhdWx0X2Vtb2ppc19pbl9hdXRvY29tcGxldGVC'
    'JQojX3Nob3dfY3VzdG9tX2Vtb2ppc19pbl9hdXRvY29tcGxldGVCIAoeX3Nob3dfc3RpY2tlcn'
    'NfaW5fYXV0b2NvbXBsZXRlQh0KG19zaG93X21lbWVzX2luX2F1dG9jb21wbGV0ZUIrCilfdm9p'
    'Y2VfY2hhbm5lbF9qb2luX3JlcXVpcmVzX2RvdWJsZV9jbGlja0ITChFfY3VzdG9tX3RoZW1lX2'
    'Nzc0IRCg9fc2hvd19mYXZvcml0ZXNCDQoLX3pvb21fbGV2ZWxCFQoTX2VuYWJsZV90dHNfY29t'
    'bWFuZEILCglfdHRzX3JhdGVCJgokX3Nob3dfZmFkZWRfdW5yZWFkX29uX211dGVkX2NoYW5uZW'
    'xzQh4KHF9zaG93X2NvbnRleHRfbWVudV9zaG9ydGN1dHNCIAoeX2NvbmZpcm1fYmVmb3JlX3N0'
    'YXJ0aW5nX2NhbGxzQhYKFF9wcmVzZXJ2ZV9lZGl0X2RyYWZ0QiIKIF9zdGF5X2ludGVyYWN0aX'
    'ZlX3doZW5fdW5mb2N1c2VkQigKJl9jb25maXJtX2JlZm9yZV9qb2luaW5nX3ZvaWNlX2NoYW5u'
    'ZWxzQiYKJF9zY3JlZW5fcmVhZGVyX2Fubm91bmNlX25ld19tZXNzYWdlc0IqCihfZmlyc3RfY2'
    'xpY2tfcGFzc190aHJvdWdoX3doZW5fdW5mb2N1c2VkQiAKHl9jb21wYWN0X21lc3NhZ2VfZ3Jv'
    'dXBfc3BhY2luZ0IjCiFfc2Nyb2xsX3RvX2JvdHRvbV9vbl9tZXNzYWdlX3NlbmRCGQoXX2RpbV'
    '9zdHJpa2V0aHJvdWdoX3RleHRCFwoVX3NlcXVlbnRpYWxfZmlsZV9zZW5kQh8KHV9tb2JpbGVf'
    'c3BsYXNoX3pvb21fYW5pbWF0aW9uQh8KHV9tZXNzYWdlX2RvdWJsZV9jbGlja19hY3Rpb25zQi'
    'EKH19hbm5vdW5jZV9jYWxsX2pvaW5zX2FuZF9sZWF2ZXNCFQoTX2FuaW1hdGVfZ2lmX3BpY2tl'
    'ckoECB8QIEoECCoQK0oECCsQLEoECEEQQlIidXNlX2Jyb3dzZXJfbG9jYWxlX2Zvcl90aW1lX2'
    'Zvcm1hdFIfYXR0YWNobWVudF9tZWRpYV9kaW1lbnNpb25fc2l6ZVIaZW1iZWRfbWVkaWFfZGlt'
    'ZW5zaW9uX3NpemVSHGRvdWJsZV9jbGlja19tZXNzYWdlX2FjdGlvbnM=');

@$core.Deprecated('Use accessibilityOverridesDescriptor instead')
const AccessibilityOverrides$json = {
  '1': 'AccessibilityOverrides',
  '2': [
    {
      '1': 'gif_autoplay_dirty',
      '3': 1,
      '4': 1,
      '5': 8,
      '10': 'gifAutoplayDirty'
    },
    {
      '1': 'animate_emoji_dirty',
      '3': 2,
      '4': 1,
      '5': 8,
      '10': 'animateEmojiDirty'
    },
    {
      '1': 'animate_stickers_dirty',
      '3': 3,
      '4': 1,
      '5': 8,
      '10': 'animateStickersDirty'
    },
  ],
};

/// Descriptor for `AccessibilityOverrides`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List accessibilityOverridesDescriptor = $convert.base64Decode(
    'ChZBY2Nlc3NpYmlsaXR5T3ZlcnJpZGVzEiwKEmdpZl9hdXRvcGxheV9kaXJ0eRgBIAEoCFIQZ2'
    'lmQXV0b3BsYXlEaXJ0eRIuChNhbmltYXRlX2Vtb2ppX2RpcnR5GAIgASgIUhFhbmltYXRlRW1v'
    'amlEaXJ0eRI0ChZhbmltYXRlX3N0aWNrZXJzX2RpcnR5GAMgASgIUhRhbmltYXRlU3RpY2tlcn'
    'NEaXJ0eQ==');
