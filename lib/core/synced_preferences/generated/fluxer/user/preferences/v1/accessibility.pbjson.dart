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
      '1': 'saturation_factor',
      '3': 1,
      '4': 1,
      '5': 1,
      '9': 8,
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
      '9': 9,
      '10': 'enableTextSelection',
      '17': true
    },
    {
      '1': 'show_message_send_button',
      '3': 4,
      '4': 1,
      '5': 8,
      '9': 10,
      '10': 'showMessageSendButton',
      '17': true
    },
    {
      '1': 'show_textarea_focus_ring',
      '3': 5,
      '4': 1,
      '5': 8,
      '9': 11,
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
      '9': 12,
      '10': 'escapeExitsKeyboardMode',
      '17': true
    },
    {
      '1': 'sync_reduced_motion_with_system',
      '3': 8,
      '4': 1,
      '5': 8,
      '9': 13,
      '10': 'syncReducedMotionWithSystem',
      '17': true
    },
    {
      '1': 'reduced_motion_override',
      '3': 9,
      '4': 1,
      '5': 8,
      '9': 14,
      '10': 'reducedMotionOverride',
      '17': true
    },
    {
      '1': 'message_group_spacing',
      '3': 10,
      '4': 1,
      '5': 1,
      '9': 15,
      '10': 'messageGroupSpacing',
      '17': true
    },
    {
      '1': 'message_gutter',
      '3': 11,
      '4': 1,
      '5': 1,
      '9': 16,
      '10': 'messageGutter',
      '17': true
    },
    {
      '1': 'font_size',
      '3': 12,
      '4': 1,
      '5': 1,
      '9': 17,
      '10': 'fontSize',
      '17': true
    },
    {
      '1': 'show_user_avatars_in_compact_mode',
      '3': 13,
      '4': 1,
      '5': 8,
      '9': 18,
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
      '9': 19,
      '10': 'mobileStickerAnimationValue',
      '17': true
    },
    {
      '1': 'mobile_gif_autoplay_value',
      '3': 18,
      '4': 1,
      '5': 8,
      '9': 20,
      '10': 'mobileGifAutoplayValue',
      '17': true
    },
    {
      '1': 'mobile_animate_emoji_value',
      '3': 19,
      '4': 1,
      '5': 8,
      '9': 21,
      '10': 'mobileAnimateEmojiValue',
      '17': true
    },
    {
      '1': 'auto_send_klipy_gifs',
      '3': 20,
      '4': 1,
      '5': 8,
      '9': 22,
      '10': 'autoSendKlipyGifs',
      '17': true
    },
    {
      '1': 'show_gif_button',
      '3': 21,
      '4': 1,
      '5': 8,
      '9': 23,
      '10': 'showGifButton',
      '17': true
    },
    {
      '1': 'show_memes_button',
      '3': 22,
      '4': 1,
      '5': 8,
      '9': 24,
      '10': 'showMemesButton',
      '17': true
    },
    {
      '1': 'show_stickers_button',
      '3': 23,
      '4': 1,
      '5': 8,
      '9': 25,
      '10': 'showStickersButton',
      '17': true
    },
    {
      '1': 'show_emoji_button',
      '3': 24,
      '4': 1,
      '5': 8,
      '9': 26,
      '10': 'showEmojiButton',
      '17': true
    },
    {
      '1': 'show_media_favorite_button',
      '3': 25,
      '4': 1,
      '5': 8,
      '9': 27,
      '10': 'showMediaFavoriteButton',
      '17': true
    },
    {
      '1': 'show_media_download_button',
      '3': 26,
      '4': 1,
      '5': 8,
      '9': 28,
      '10': 'showMediaDownloadButton',
      '17': true
    },
    {
      '1': 'show_media_delete_button',
      '3': 27,
      '4': 1,
      '5': 8,
      '9': 29,
      '10': 'showMediaDeleteButton',
      '17': true
    },
    {
      '1': 'show_suppress_embeds_button',
      '3': 28,
      '4': 1,
      '5': 8,
      '9': 30,
      '10': 'showSuppressEmbedsButton',
      '17': true
    },
    {
      '1': 'show_gif_indicator',
      '3': 29,
      '4': 1,
      '5': 8,
      '9': 31,
      '10': 'showGifIndicator',
      '17': true
    },
    {
      '1': 'show_attachment_expiry_indicator',
      '3': 30,
      '4': 1,
      '5': 8,
      '9': 32,
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
      '9': 33,
      '10': 'showSelectedChannelTypingIndicator',
      '17': true
    },
    {
      '1': 'show_message_action_bar',
      '3': 34,
      '4': 1,
      '5': 8,
      '9': 34,
      '10': 'showMessageActionBar',
      '17': true
    },
    {
      '1': 'show_message_action_bar_quick_reactions',
      '3': 35,
      '4': 1,
      '5': 8,
      '9': 35,
      '10': 'showMessageActionBarQuickReactions',
      '17': true
    },
    {
      '1': 'show_message_action_bar_shift_expand',
      '3': 36,
      '4': 1,
      '5': 8,
      '9': 36,
      '10': 'showMessageActionBarShiftExpand',
      '17': true
    },
    {
      '1': 'show_message_action_bar_only_more_button',
      '3': 37,
      '4': 1,
      '5': 8,
      '9': 37,
      '10': 'showMessageActionBarOnlyMoreButton',
      '17': true
    },
    {
      '1': 'show_default_emojis_in_autocomplete',
      '3': 38,
      '4': 1,
      '5': 8,
      '9': 38,
      '10': 'showDefaultEmojisInAutocomplete',
      '17': true
    },
    {
      '1': 'show_custom_emojis_in_autocomplete',
      '3': 39,
      '4': 1,
      '5': 8,
      '9': 39,
      '10': 'showCustomEmojisInAutocomplete',
      '17': true
    },
    {
      '1': 'show_stickers_in_autocomplete',
      '3': 40,
      '4': 1,
      '5': 8,
      '9': 40,
      '10': 'showStickersInAutocomplete',
      '17': true
    },
    {
      '1': 'show_memes_in_autocomplete',
      '3': 41,
      '4': 1,
      '5': 8,
      '9': 41,
      '10': 'showMemesInAutocomplete',
      '17': true
    },
    {
      '1': 'voice_channel_join_requires_double_click',
      '3': 44,
      '4': 1,
      '5': 8,
      '9': 42,
      '10': 'voiceChannelJoinRequiresDoubleClick',
      '17': true
    },
    {
      '1': 'custom_theme_css',
      '3': 45,
      '4': 1,
      '5': 9,
      '9': 43,
      '10': 'customThemeCss',
      '17': true
    },
    {
      '1': 'show_favorites',
      '3': 46,
      '4': 1,
      '5': 8,
      '9': 44,
      '10': 'showFavorites',
      '17': true
    },
    {
      '1': 'zoom_level',
      '3': 47,
      '4': 1,
      '5': 1,
      '9': 45,
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
      '9': 46,
      '10': 'enableTtsCommand',
      '17': true
    },
    {
      '1': 'tts_rate',
      '3': 50,
      '4': 1,
      '5': 1,
      '9': 47,
      '10': 'ttsRate',
      '17': true
    },
    {
      '1': 'show_faded_unread_on_muted_channels',
      '3': 51,
      '4': 1,
      '5': 8,
      '9': 48,
      '10': 'showFadedUnreadOnMutedChannels',
      '17': true
    },
    {
      '1': 'show_context_menu_shortcuts',
      '3': 52,
      '4': 1,
      '5': 8,
      '9': 49,
      '10': 'showContextMenuShortcuts',
      '17': true
    },
    {
      '1': 'confirm_before_starting_calls',
      '3': 53,
      '4': 1,
      '5': 8,
      '9': 50,
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
      '9': 51,
      '10': 'preserveEditDraft',
      '17': true
    },
    {
      '1': 'stay_interactive_when_unfocused',
      '3': 56,
      '4': 1,
      '5': 8,
      '9': 52,
      '10': 'stayInteractiveWhenUnfocused',
      '17': true
    },
    {
      '1': 'confirm_before_joining_voice_channels',
      '3': 57,
      '4': 1,
      '5': 8,
      '9': 53,
      '10': 'confirmBeforeJoiningVoiceChannels',
      '17': true
    },
    {
      '1': 'screen_reader_announce_new_messages',
      '3': 58,
      '4': 1,
      '5': 8,
      '9': 54,
      '10': 'screenReaderAnnounceNewMessages',
      '17': true
    },
    {
      '1': 'first_click_pass_through_when_unfocused',
      '3': 59,
      '4': 1,
      '5': 8,
      '9': 55,
      '10': 'firstClickPassThroughWhenUnfocused',
      '17': true
    },
    {
      '1': 'compact_message_group_spacing',
      '3': 60,
      '4': 1,
      '5': 1,
      '9': 56,
      '10': 'compactMessageGroupSpacing',
      '17': true
    },
    {
      '1': 'scroll_to_bottom_on_message_send',
      '3': 61,
      '4': 1,
      '5': 8,
      '9': 57,
      '10': 'scrollToBottomOnMessageSend',
      '17': true
    },
    {
      '1': 'dim_strikethrough_text',
      '3': 62,
      '4': 1,
      '5': 8,
      '9': 58,
      '10': 'dimStrikethroughText',
      '17': true
    },
    {
      '1': 'sequential_file_send',
      '3': 63,
      '4': 1,
      '5': 8,
      '9': 59,
      '10': 'sequentialFileSend',
      '17': true
    },
    {
      '1': 'mobile_splash_zoom_animation',
      '3': 64,
      '4': 1,
      '5': 8,
      '9': 60,
      '10': 'mobileSplashZoomAnimation',
      '17': true
    },
    {
      '1': 'message_double_click_actions',
      '3': 66,
      '4': 1,
      '5': 8,
      '9': 61,
      '10': 'messageDoubleClickActions',
      '17': true
    },
    {
      '1': 'announce_call_joins_and_leaves',
      '3': 67,
      '4': 1,
      '5': 8,
      '9': 62,
      '10': 'announceCallJoinsAndLeaves',
      '17': true
    },
    {
      '1': 'animate_gif_picker',
      '3': 68,
      '4': 1,
      '5': 8,
      '9': 63,
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
    'UmVwbGllc4gBARIwChFzYXR1cmF0aW9uX2ZhY3RvchgBIAEoAUgIUhBzYXR1cmF0aW9uRmFjdG'
    '9yiAEBEjQKFmFsd2F5c191bmRlcmxpbmVfbGlua3MYAiABKAhSFGFsd2F5c1VuZGVybGluZUxp'
    'bmtzEjcKFWVuYWJsZV90ZXh0X3NlbGVjdGlvbhgDIAEoCEgJUhNlbmFibGVUZXh0U2VsZWN0aW'
    '9uiAEBEjwKGHNob3dfbWVzc2FnZV9zZW5kX2J1dHRvbhgEIAEoCEgKUhVzaG93TWVzc2FnZVNl'
    'bmRCdXR0b26IAQESPAoYc2hvd190ZXh0YXJlYV9mb2N1c19yaW5nGAUgASgISAtSFXNob3dUZX'
    'h0YXJlYUZvY3VzUmluZ4gBARIuChNoaWRlX2tleWJvYXJkX2hpbnRzGAYgASgIUhFoaWRlS2V5'
    'Ym9hcmRIaW50cxJAChplc2NhcGVfZXhpdHNfa2V5Ym9hcmRfbW9kZRgHIAEoCEgMUhdlc2NhcG'
    'VFeGl0c0tleWJvYXJkTW9kZYgBARJJCh9zeW5jX3JlZHVjZWRfbW90aW9uX3dpdGhfc3lzdGVt'
    'GAggASgISA1SG3N5bmNSZWR1Y2VkTW90aW9uV2l0aFN5c3RlbYgBARI7ChdyZWR1Y2VkX21vdG'
    'lvbl9vdmVycmlkZRgJIAEoCEgOUhVyZWR1Y2VkTW90aW9uT3ZlcnJpZGWIAQESNwoVbWVzc2Fn'
    'ZV9ncm91cF9zcGFjaW5nGAogASgBSA9SE21lc3NhZ2VHcm91cFNwYWNpbmeIAQESKgoObWVzc2'
    'FnZV9ndXR0ZXIYCyABKAFIEFINbWVzc2FnZUd1dHRlcogBARIgCglmb250X3NpemUYDCABKAFI'
    'EVIIZm9udFNpemWIAQESTAohc2hvd191c2VyX2F2YXRhcnNfaW5fY29tcGFjdF9tb2RlGA0gAS'
    'gISBJSHHNob3dVc2VyQXZhdGFyc0luQ29tcGFjdE1vZGWIAQESTQojbW9iaWxlX3N0aWNrZXJf'
    'YW5pbWF0aW9uX292ZXJyaWRkZW4YDiABKAhSIG1vYmlsZVN0aWNrZXJBbmltYXRpb25PdmVycm'
    'lkZGVuEkMKHm1vYmlsZV9naWZfYXV0b3BsYXlfb3ZlcnJpZGRlbhgPIAEoCFIbbW9iaWxlR2lm'
    'QXV0b3BsYXlPdmVycmlkZGVuEkUKH21vYmlsZV9hbmltYXRlX2Vtb2ppX292ZXJyaWRkZW4YEC'
    'ABKAhSHG1vYmlsZUFuaW1hdGVFbW9qaU92ZXJyaWRkZW4SSAoebW9iaWxlX3N0aWNrZXJfYW5p'
    'bWF0aW9uX3ZhbHVlGBEgASgFSBNSG21vYmlsZVN0aWNrZXJBbmltYXRpb25WYWx1ZYgBARI+Ch'
    'ltb2JpbGVfZ2lmX2F1dG9wbGF5X3ZhbHVlGBIgASgISBRSFm1vYmlsZUdpZkF1dG9wbGF5VmFs'
    'dWWIAQESQAoabW9iaWxlX2FuaW1hdGVfZW1vamlfdmFsdWUYEyABKAhIFVIXbW9iaWxlQW5pbW'
    'F0ZUVtb2ppVmFsdWWIAQESNAoUYXV0b19zZW5kX2tsaXB5X2dpZnMYFCABKAhIFlIRYXV0b1Nl'
    'bmRLbGlweUdpZnOIAQESKwoPc2hvd19naWZfYnV0dG9uGBUgASgISBdSDXNob3dHaWZCdXR0b2'
    '6IAQESLwoRc2hvd19tZW1lc19idXR0b24YFiABKAhIGFIPc2hvd01lbWVzQnV0dG9uiAEBEjUK'
    'FHNob3dfc3RpY2tlcnNfYnV0dG9uGBcgASgISBlSEnNob3dTdGlja2Vyc0J1dHRvbogBARIvCh'
    'FzaG93X2Vtb2ppX2J1dHRvbhgYIAEoCEgaUg9zaG93RW1vamlCdXR0b26IAQESQAoac2hvd19t'
    'ZWRpYV9mYXZvcml0ZV9idXR0b24YGSABKAhIG1IXc2hvd01lZGlhRmF2b3JpdGVCdXR0b26IAQ'
    'ESQAoac2hvd19tZWRpYV9kb3dubG9hZF9idXR0b24YGiABKAhIHFIXc2hvd01lZGlhRG93bmxv'
    'YWRCdXR0b26IAQESPAoYc2hvd19tZWRpYV9kZWxldGVfYnV0dG9uGBsgASgISB1SFXNob3dNZW'
    'RpYURlbGV0ZUJ1dHRvbogBARJCChtzaG93X3N1cHByZXNzX2VtYmVkc19idXR0b24YHCABKAhI'
    'HlIYc2hvd1N1cHByZXNzRW1iZWRzQnV0dG9uiAEBEjEKEnNob3dfZ2lmX2luZGljYXRvchgdIA'
    'EoCEgfUhBzaG93R2lmSW5kaWNhdG9yiAEBEkwKIHNob3dfYXR0YWNobWVudF9leHBpcnlfaW5k'
    'aWNhdG9yGB4gASgISCBSHXNob3dBdHRhY2htZW50RXhwaXJ5SW5kaWNhdG9yiAEBEnkKHWNoYW'
    '5uZWxfdHlwaW5nX2luZGljYXRvcl9tb2RlGCAgASgOMjYuZmx1eGVyLnVzZXIucHJlZmVyZW5j'
    'ZXMudjEuQ2hhbm5lbFR5cGluZ0luZGljYXRvck1vZGVSGmNoYW5uZWxUeXBpbmdJbmRpY2F0b3'
    'JNb2RlElcKJnNob3dfc2VsZWN0ZWRfY2hhbm5lbF90eXBpbmdfaW5kaWNhdG9yGCEgASgISCFS'
    'InNob3dTZWxlY3RlZENoYW5uZWxUeXBpbmdJbmRpY2F0b3KIAQESOgoXc2hvd19tZXNzYWdlX2'
    'FjdGlvbl9iYXIYIiABKAhIIlIUc2hvd01lc3NhZ2VBY3Rpb25CYXKIAQESWAonc2hvd19tZXNz'
    'YWdlX2FjdGlvbl9iYXJfcXVpY2tfcmVhY3Rpb25zGCMgASgISCNSInNob3dNZXNzYWdlQWN0aW'
    '9uQmFyUXVpY2tSZWFjdGlvbnOIAQESUgokc2hvd19tZXNzYWdlX2FjdGlvbl9iYXJfc2hpZnRf'
    'ZXhwYW5kGCQgASgISCRSH3Nob3dNZXNzYWdlQWN0aW9uQmFyU2hpZnRFeHBhbmSIAQESWQooc2'
    'hvd19tZXNzYWdlX2FjdGlvbl9iYXJfb25seV9tb3JlX2J1dHRvbhglIAEoCEglUiJzaG93TWVz'
    'c2FnZUFjdGlvbkJhck9ubHlNb3JlQnV0dG9uiAEBElEKI3Nob3dfZGVmYXVsdF9lbW9qaXNfaW'
    '5fYXV0b2NvbXBsZXRlGCYgASgISCZSH3Nob3dEZWZhdWx0RW1vamlzSW5BdXRvY29tcGxldGWI'
    'AQESTwoic2hvd19jdXN0b21fZW1vamlzX2luX2F1dG9jb21wbGV0ZRgnIAEoCEgnUh5zaG93Q3'
    'VzdG9tRW1vamlzSW5BdXRvY29tcGxldGWIAQESRgodc2hvd19zdGlja2Vyc19pbl9hdXRvY29t'
    'cGxldGUYKCABKAhIKFIac2hvd1N0aWNrZXJzSW5BdXRvY29tcGxldGWIAQESQAoac2hvd19tZW'
    '1lc19pbl9hdXRvY29tcGxldGUYKSABKAhIKVIXc2hvd01lbWVzSW5BdXRvY29tcGxldGWIAQES'
    'Wgoodm9pY2VfY2hhbm5lbF9qb2luX3JlcXVpcmVzX2RvdWJsZV9jbGljaxgsIAEoCEgqUiN2b2'
    'ljZUNoYW5uZWxKb2luUmVxdWlyZXNEb3VibGVDbGlja4gBARItChBjdXN0b21fdGhlbWVfY3Nz'
    'GC0gASgJSCtSDmN1c3RvbVRoZW1lQ3NziAEBEioKDnNob3dfZmF2b3JpdGVzGC4gASgISCxSDX'
    'Nob3dGYXZvcml0ZXOIAQESIgoKem9vbV9sZXZlbBgvIAEoAUgtUgl6b29tTGV2ZWyIAQESZwoX'
    'ZG1fbWVzc2FnZV9wcmV2aWV3X21vZGUYMCABKA4yMC5mbHV4ZXIudXNlci5wcmVmZXJlbmNlcy'
    '52MS5EbU1lc3NhZ2VQcmV2aWV3TW9kZVIUZG1NZXNzYWdlUHJldmlld01vZGUSMQoSZW5hYmxl'
    'X3R0c19jb21tYW5kGDEgASgISC5SEGVuYWJsZVR0c0NvbW1hbmSIAQESHgoIdHRzX3JhdGUYMi'
    'ABKAFIL1IHdHRzUmF0ZYgBARJQCiNzaG93X2ZhZGVkX3VucmVhZF9vbl9tdXRlZF9jaGFubmVs'
    'cxgzIAEoCEgwUh5zaG93RmFkZWRVbnJlYWRPbk11dGVkQ2hhbm5lbHOIAQESQgobc2hvd19jb2'
    '50ZXh0X21lbnVfc2hvcnRjdXRzGDQgASgISDFSGHNob3dDb250ZXh0TWVudVNob3J0Y3V0c4gB'
    'ARJGCh1jb25maXJtX2JlZm9yZV9zdGFydGluZ19jYWxscxg1IAEoCEgyUhpjb25maXJtQmVmb3'
    'JlU3RhcnRpbmdDYWxsc4gBARJUChBoZHJfZGlzcGxheV9tb2RlGDYgASgOMiouZmx1eGVyLnVz'
    'ZXIucHJlZmVyZW5jZXMudjEuSGRyRGlzcGxheU1vZGVSDmhkckRpc3BsYXlNb2RlEjMKE3ByZX'
    'NlcnZlX2VkaXRfZHJhZnQYNyABKAhIM1IRcHJlc2VydmVFZGl0RHJhZnSIAQESSgofc3RheV9p'
    'bnRlcmFjdGl2ZV93aGVuX3VuZm9jdXNlZBg4IAEoCEg0UhxzdGF5SW50ZXJhY3RpdmVXaGVuVW'
    '5mb2N1c2VkiAEBElUKJWNvbmZpcm1fYmVmb3JlX2pvaW5pbmdfdm9pY2VfY2hhbm5lbHMYOSAB'
    'KAhINVIhY29uZmlybUJlZm9yZUpvaW5pbmdWb2ljZUNoYW5uZWxziAEBElEKI3NjcmVlbl9yZW'
    'FkZXJfYW5ub3VuY2VfbmV3X21lc3NhZ2VzGDogASgISDZSH3NjcmVlblJlYWRlckFubm91bmNl'
    'TmV3TWVzc2FnZXOIAQESWAonZmlyc3RfY2xpY2tfcGFzc190aHJvdWdoX3doZW5fdW5mb2N1c2'
    'VkGDsgASgISDdSImZpcnN0Q2xpY2tQYXNzVGhyb3VnaFdoZW5VbmZvY3VzZWSIAQESRgodY29t'
    'cGFjdF9tZXNzYWdlX2dyb3VwX3NwYWNpbmcYPCABKAFIOFIaY29tcGFjdE1lc3NhZ2VHcm91cF'
    'NwYWNpbmeIAQESSgogc2Nyb2xsX3RvX2JvdHRvbV9vbl9tZXNzYWdlX3NlbmQYPSABKAhIOVIb'
    'c2Nyb2xsVG9Cb3R0b21Pbk1lc3NhZ2VTZW5kiAEBEjkKFmRpbV9zdHJpa2V0aHJvdWdoX3RleH'
    'QYPiABKAhIOlIUZGltU3RyaWtldGhyb3VnaFRleHSIAQESNQoUc2VxdWVudGlhbF9maWxlX3Nl'
    'bmQYPyABKAhIO1ISc2VxdWVudGlhbEZpbGVTZW5kiAEBEkQKHG1vYmlsZV9zcGxhc2hfem9vbV'
    '9hbmltYXRpb24YQCABKAhIPFIZbW9iaWxlU3BsYXNoWm9vbUFuaW1hdGlvbogBARJEChxtZXNz'
    'YWdlX2RvdWJsZV9jbGlja19hY3Rpb25zGEIgASgISD1SGW1lc3NhZ2VEb3VibGVDbGlja0FjdG'
    'lvbnOIAQESRwoeYW5ub3VuY2VfY2FsbF9qb2luc19hbmRfbGVhdmVzGEMgASgISD5SGmFubm91'
    'bmNlQ2FsbEpvaW5zQW5kTGVhdmVziAEBEjEKEmFuaW1hdGVfZ2lmX3BpY2tlchhEIAEoCEg/Uh'
    'BhbmltYXRlR2lmUGlja2VyiAEBQhcKFV9zaG93X3BlcnNvbmFzX2J1dHRvbkImCiRfc2hvd19t'
    'ZXNzYWdlX2FjdGlvbl9iYXJfY29weV9idXR0b25CGgoYX3Nob3dfYWx0X3RleHRfb25faW1hZ2'
    'VzQhMKEV9tb2JpbGVfZm9udF9zaXplQh8KHV9tb2JpbGVfbWVzc2FnZV9ncm91cF9zcGFjaW5n'
    'QicKJV9tb2JpbGVfY29tcGFjdF9tZXNzYWdlX2dyb3VwX3NwYWNpbmdCHQobX21lc3NhZ2VfZG'
    '91YmxlX2NsaWNrX2VkaXRzQh8KHV9tZXNzYWdlX2RvdWJsZV9jbGlja19yZXBsaWVzQhQKEl9z'
    'YXR1cmF0aW9uX2ZhY3RvckIYChZfZW5hYmxlX3RleHRfc2VsZWN0aW9uQhsKGV9zaG93X21lc3'
    'NhZ2Vfc2VuZF9idXR0b25CGwoZX3Nob3dfdGV4dGFyZWFfZm9jdXNfcmluZ0IdChtfZXNjYXBl'
    'X2V4aXRzX2tleWJvYXJkX21vZGVCIgogX3N5bmNfcmVkdWNlZF9tb3Rpb25fd2l0aF9zeXN0ZW'
    '1CGgoYX3JlZHVjZWRfbW90aW9uX292ZXJyaWRlQhgKFl9tZXNzYWdlX2dyb3VwX3NwYWNpbmdC'
    'EQoPX21lc3NhZ2VfZ3V0dGVyQgwKCl9mb250X3NpemVCJAoiX3Nob3dfdXNlcl9hdmF0YXJzX2'
    'luX2NvbXBhY3RfbW9kZUIhCh9fbW9iaWxlX3N0aWNrZXJfYW5pbWF0aW9uX3ZhbHVlQhwKGl9t'
    'b2JpbGVfZ2lmX2F1dG9wbGF5X3ZhbHVlQh0KG19tb2JpbGVfYW5pbWF0ZV9lbW9qaV92YWx1ZU'
    'IXChVfYXV0b19zZW5kX2tsaXB5X2dpZnNCEgoQX3Nob3dfZ2lmX2J1dHRvbkIUChJfc2hvd19t'
    'ZW1lc19idXR0b25CFwoVX3Nob3dfc3RpY2tlcnNfYnV0dG9uQhQKEl9zaG93X2Vtb2ppX2J1dH'
    'RvbkIdChtfc2hvd19tZWRpYV9mYXZvcml0ZV9idXR0b25CHQobX3Nob3dfbWVkaWFfZG93bmxv'
    'YWRfYnV0dG9uQhsKGV9zaG93X21lZGlhX2RlbGV0ZV9idXR0b25CHgocX3Nob3dfc3VwcHJlc3'
    'NfZW1iZWRzX2J1dHRvbkIVChNfc2hvd19naWZfaW5kaWNhdG9yQiMKIV9zaG93X2F0dGFjaG1l'
    'bnRfZXhwaXJ5X2luZGljYXRvckIpCidfc2hvd19zZWxlY3RlZF9jaGFubmVsX3R5cGluZ19pbm'
    'RpY2F0b3JCGgoYX3Nob3dfbWVzc2FnZV9hY3Rpb25fYmFyQioKKF9zaG93X21lc3NhZ2VfYWN0'
    'aW9uX2Jhcl9xdWlja19yZWFjdGlvbnNCJwolX3Nob3dfbWVzc2FnZV9hY3Rpb25fYmFyX3NoaW'
    'Z0X2V4cGFuZEIrCilfc2hvd19tZXNzYWdlX2FjdGlvbl9iYXJfb25seV9tb3JlX2J1dHRvbkIm'
    'CiRfc2hvd19kZWZhdWx0X2Vtb2ppc19pbl9hdXRvY29tcGxldGVCJQojX3Nob3dfY3VzdG9tX2'
    'Vtb2ppc19pbl9hdXRvY29tcGxldGVCIAoeX3Nob3dfc3RpY2tlcnNfaW5fYXV0b2NvbXBsZXRl'
    'Qh0KG19zaG93X21lbWVzX2luX2F1dG9jb21wbGV0ZUIrCilfdm9pY2VfY2hhbm5lbF9qb2luX3'
    'JlcXVpcmVzX2RvdWJsZV9jbGlja0ITChFfY3VzdG9tX3RoZW1lX2Nzc0IRCg9fc2hvd19mYXZv'
    'cml0ZXNCDQoLX3pvb21fbGV2ZWxCFQoTX2VuYWJsZV90dHNfY29tbWFuZEILCglfdHRzX3JhdG'
    'VCJgokX3Nob3dfZmFkZWRfdW5yZWFkX29uX211dGVkX2NoYW5uZWxzQh4KHF9zaG93X2NvbnRl'
    'eHRfbWVudV9zaG9ydGN1dHNCIAoeX2NvbmZpcm1fYmVmb3JlX3N0YXJ0aW5nX2NhbGxzQhYKFF'
    '9wcmVzZXJ2ZV9lZGl0X2RyYWZ0QiIKIF9zdGF5X2ludGVyYWN0aXZlX3doZW5fdW5mb2N1c2Vk'
    'QigKJl9jb25maXJtX2JlZm9yZV9qb2luaW5nX3ZvaWNlX2NoYW5uZWxzQiYKJF9zY3JlZW5fcm'
    'VhZGVyX2Fubm91bmNlX25ld19tZXNzYWdlc0IqCihfZmlyc3RfY2xpY2tfcGFzc190aHJvdWdo'
    'X3doZW5fdW5mb2N1c2VkQiAKHl9jb21wYWN0X21lc3NhZ2VfZ3JvdXBfc3BhY2luZ0IjCiFfc2'
    'Nyb2xsX3RvX2JvdHRvbV9vbl9tZXNzYWdlX3NlbmRCGQoXX2RpbV9zdHJpa2V0aHJvdWdoX3Rl'
    'eHRCFwoVX3NlcXVlbnRpYWxfZmlsZV9zZW5kQh8KHV9tb2JpbGVfc3BsYXNoX3pvb21fYW5pbW'
    'F0aW9uQh8KHV9tZXNzYWdlX2RvdWJsZV9jbGlja19hY3Rpb25zQiEKH19hbm5vdW5jZV9jYWxs'
    'X2pvaW5zX2FuZF9sZWF2ZXNCFQoTX2FuaW1hdGVfZ2lmX3BpY2tlckoECB8QIEoECCoQK0oECC'
    'sQLEoECEEQQlIidXNlX2Jyb3dzZXJfbG9jYWxlX2Zvcl90aW1lX2Zvcm1hdFIfYXR0YWNobWVu'
    'dF9tZWRpYV9kaW1lbnNpb25fc2l6ZVIaZW1iZWRfbWVkaWFfZGltZW5zaW9uX3NpemVSHGRvdW'
    'JsZV9jbGlja19tZXNzYWdlX2FjdGlvbnM=');

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
