// This is a generated file - do not edit.
//
// Generated from fluxer/user/preferences/v1/fork_emoji_pins.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Emojis pinned to the front of the picker's frequently used section and the quick reactions.
/// Every list holds emoji keys as the pickers write them (`unicode:<unique name>`,
/// `custom:<guild id>:<emoji id>`), in the order they were pinned.
class EmojiPinsState extends $pb.GeneratedMessage {
  factory EmojiPinsState({
    $core.Iterable<$core.String>? pinnedEmojiIds,
    $core.Iterable<$core.MapEntry<$core.String, PersonaEmojiPins>>? personaPins,
  }) {
    final result = EmojiPinsState._();
    if (pinnedEmojiIds != null) result.pinnedEmojiIds.addAll(pinnedEmojiIds);
    if (personaPins != null) result.personaPins.addEntries(personaPins);
    return result;
  }

  EmojiPinsState._();

  factory EmojiPinsState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EmojiPinsState()..mergeFromBuffer(data, registry);
  factory EmojiPinsState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EmojiPinsState()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EmojiPinsState',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fluxer.user.preferences.v1'),
      createEmptyInstance: EmojiPinsState.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'pinnedEmojiIds')
    ..m<$core.String, PersonaEmojiPins>(2, _omitFieldNames ? '' : 'personaPins',
        entryClassName: 'EmojiPinsState.PersonaPinsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: PersonaEmojiPins.$_createMessage,
        valueDefaultOrMaker: PersonaEmojiPins.getDefault,
        packageName: const $pb.PackageName('fluxer.user.preferences.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EmojiPinsState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EmojiPinsState copyWith(void Function(EmojiPinsState) updates) =>
      super.copyWith((message) => updates(message as EmojiPinsState))
          as EmojiPinsState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use EmojiPinsState() / EmojiPinsState.new instead')
  static EmojiPinsState create() => EmojiPinsState._();
  static $pb.GeneratedMessage $_createMessage() => EmojiPinsState._();
  @$core.override
  EmojiPinsState createEmptyInstance() => EmojiPinsState._();
  @$core.pragma('dart2js:noInline')
  static EmojiPinsState getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EmojiPinsState>(
          EmojiPinsState.$_createMessage);
  static EmojiPinsState? _defaultInstance;

  /// Pinned whoever the account writes as.
  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get pinnedEmojiIds => $_getList(0);

  /// Pinned for one persona only, by persona id; shown after the account's pins.
  @$pb.TagNumber(2)
  $pb.PbMap<$core.String, PersonaEmojiPins> get personaPins => $_getMap(1);
}

class PersonaEmojiPins extends $pb.GeneratedMessage {
  factory PersonaEmojiPins({
    $core.Iterable<$core.String>? emojiIds,
  }) {
    final result = PersonaEmojiPins._();
    if (emojiIds != null) result.emojiIds.addAll(emojiIds);
    return result;
  }

  PersonaEmojiPins._();

  factory PersonaEmojiPins.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PersonaEmojiPins()..mergeFromBuffer(data, registry);
  factory PersonaEmojiPins.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PersonaEmojiPins()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PersonaEmojiPins',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'fluxer.user.preferences.v1'),
      createEmptyInstance: PersonaEmojiPins.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'emojiIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PersonaEmojiPins clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PersonaEmojiPins copyWith(void Function(PersonaEmojiPins) updates) =>
      super.copyWith((message) => updates(message as PersonaEmojiPins))
          as PersonaEmojiPins;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PersonaEmojiPins() / PersonaEmojiPins.new instead')
  static PersonaEmojiPins create() => PersonaEmojiPins._();
  static $pb.GeneratedMessage $_createMessage() => PersonaEmojiPins._();
  @$core.override
  PersonaEmojiPins createEmptyInstance() => PersonaEmojiPins._();
  @$core.pragma('dart2js:noInline')
  static PersonaEmojiPins getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PersonaEmojiPins>(
          PersonaEmojiPins.$_createMessage);
  static PersonaEmojiPins? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get emojiIds => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
