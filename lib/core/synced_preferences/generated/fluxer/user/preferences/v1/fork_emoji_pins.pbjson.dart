// This is a generated file - do not edit.
//
// Generated from fluxer/user/preferences/v1/fork_emoji_pins.proto.

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

@$core.Deprecated('Use emojiPinsStateDescriptor instead')
const EmojiPinsState$json = {
  '1': 'EmojiPinsState',
  '2': [
    {'1': 'pinned_emoji_ids', '3': 1, '4': 3, '5': 9, '10': 'pinnedEmojiIds'},
    {
      '1': 'persona_pins',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.EmojiPinsState.PersonaPinsEntry',
      '10': 'personaPins'
    },
  ],
  '3': [EmojiPinsState_PersonaPinsEntry$json],
};

@$core.Deprecated('Use emojiPinsStateDescriptor instead')
const EmojiPinsState_PersonaPinsEntry$json = {
  '1': 'PersonaPinsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.fluxer.user.preferences.v1.PersonaEmojiPins',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

/// Descriptor for `EmojiPinsState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List emojiPinsStateDescriptor = $convert.base64Decode(
    'Cg5FbW9qaVBpbnNTdGF0ZRIoChBwaW5uZWRfZW1vamlfaWRzGAEgAygJUg5waW5uZWRFbW9qaU'
    'lkcxJeCgxwZXJzb25hX3BpbnMYAiADKAsyOy5mbHV4ZXIudXNlci5wcmVmZXJlbmNlcy52MS5F'
    'bW9qaVBpbnNTdGF0ZS5QZXJzb25hUGluc0VudHJ5UgtwZXJzb25hUGlucxpsChBQZXJzb25hUG'
    'luc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EkIKBXZhbHVlGAIgASgLMiwuZmx1eGVyLnVzZXIu'
    'cHJlZmVyZW5jZXMudjEuUGVyc29uYUVtb2ppUGluc1IFdmFsdWU6AjgB');

@$core.Deprecated('Use personaEmojiPinsDescriptor instead')
const PersonaEmojiPins$json = {
  '1': 'PersonaEmojiPins',
  '2': [
    {'1': 'emoji_ids', '3': 1, '4': 3, '5': 9, '10': 'emojiIds'},
  ],
};

/// Descriptor for `PersonaEmojiPins`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List personaEmojiPinsDescriptor = $convert.base64Decode(
    'ChBQZXJzb25hRW1vamlQaW5zEhsKCWVtb2ppX2lkcxgBIAMoCVIIZW1vamlJZHM=');
