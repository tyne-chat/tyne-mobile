// Fork: tests the fork adds, kept out of upstream's accessibility_synced_field_test.dart so that file stays as
// upstream has it.
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/synced_preferences/fields/accessibility_synced_field.dart';
import 'package:fluxer_app/core/synced_preferences/generated/fluxer/user/preferences/v1/accessibility.pb.dart'
    as accessibility_pb;
import 'package:fluxer_app/features/settings/providers/preferences/appearance_preferences_provider.dart';

import 'accessibility_synced_field_test.dart' hide main;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AccessibilitySyncedField', () {
    test(
      'ignores desktop fontSize and messageGroupSpacing when mobile layout fields are omitted',
      () {
        final proto = accessibility_pb.AccessibilitySettings(
          fontSize: 24,
          messageGroupSpacing: 0,
          compactMessageGroupSpacing: 0,
        );
        final restored = AccessibilitySyncedField.fromProto(proto);
        expect(restored.chatFontSize, 16);
        expect(restored.messageGroupSpacing, 16);
        expect(restored.compactMessageGroupSpacing, 0);
        expect(restored.hasMobileFontSizeInProto, isFalse);
        expect(restored.hasMobileMessageGroupSpacingInProto, isFalse);
      },
    );

    test(
      'push keeps desktop fontSize and messageGroupSpacing from the wire and writes the mobile fields',
      () {
        final local = AccessibilitySyncedField.fromProto(
          accessibility_pb.AccessibilitySettings(),
        );
        final pushed = AccessibilitySyncedField.toProtoForPush(
          local: local,
          wireBase: accessibility_pb.AccessibilitySettings(
            fontSize: 24,
            messageGroupSpacing: 0,
          ),
        );
        expect(pushed.fontSize, 24);
        expect(pushed.messageGroupSpacing, 0);
        expect(pushed.mobileFontSize, 16);
        expect(pushed.mobileMessageGroupSpacing, 16);
      },
    );

    test(
      'mergeForMigration keeps local font size and spacing when remote omits mobile fields',
      () {
        final field = forkUpstream.splashZoomField();
        const local = AccessibilityLocalState(
          hideKeyboardHints: false,
          channelTypingIndicatorMode: ChannelTypingIndicatorMode.avatars,
          showSelectedChannelTypingIndicator: false,
          showFadedUnreadOnMutedChannels: false,
          dmMessagePreviewMode: DmMessagePreviewMode.all,
          showFavorites: true,
          messageGroupSpacing: 18,
          compactMessageGroupSpacing: 2,
          saturationFactor: 1,
          customThemeCss: null,
          chatFontSize: 18,
          hasMobileFontSizeInProto: true,
          hasMobileMessageGroupSpacingInProto: true,
          advanced: forkDefaultAdvancedAccessibility,
        );
        final remote = AccessibilitySyncedField.fromProto(
          accessibility_pb.AccessibilitySettings(
            fontSize: 24,
            messageGroupSpacing: 0,
          ),
        );
        final merged = field.mergeForMigration(local: local, remote: remote);
        expect(merged.chatFontSize, 18);
        expect(merged.messageGroupSpacing, 18);
      },
    );

    test('defaults spaceAfterEmoji to true when omitted from proto', () {
      final restored = AccessibilitySyncedField.fromProto(
        accessibility_pb.AccessibilitySettings(fontSize: 14),
      );
      expect(restored.spaceAfterEmoji, isTrue);
      expect(restored.hasSpaceAfterEmojiInProto, isFalse);
    });

    test('roundtrips spaceAfterEmoji false and true', () {
      final field = forkUpstream.splashZoomField();
      for (final bool enabled in <bool>[false, true]) {
        final local = AccessibilityLocalState(
          spaceAfterEmoji: enabled,
          hideKeyboardHints: false,
          channelTypingIndicatorMode: ChannelTypingIndicatorMode.avatars,
          showSelectedChannelTypingIndicator: false,
          showFadedUnreadOnMutedChannels: false,
          dmMessagePreviewMode: DmMessagePreviewMode.all,
          showFavorites: true,
          messageGroupSpacing: 16,
          compactMessageGroupSpacing: 0,
          saturationFactor: 1,
          customThemeCss: null,
          advanced: forkDefaultAdvancedAccessibility,
        );
        final proto = AccessibilitySyncedField.toProto(local);
        expect(proto.hasSpaceAfterEmoji(), isTrue);
        expect(proto.spaceAfterEmoji, enabled);
        final restored = AccessibilitySyncedField.fromProto(proto);
        expect(restored.spaceAfterEmoji, enabled);
        expect(restored.hasSpaceAfterEmojiInProto, isTrue);
        expect(field.verifyRoundtrip(local), isTrue);
      }
    });

    test(
      'toProtoForPush writes spaceAfterEmoji while preserving desktop fields',
      () {
        const local = AccessibilityLocalState(
          spaceAfterEmoji: false,
          hideKeyboardHints: false,
          channelTypingIndicatorMode: ChannelTypingIndicatorMode.avatars,
          showSelectedChannelTypingIndicator: false,
          showFadedUnreadOnMutedChannels: false,
          dmMessagePreviewMode: DmMessagePreviewMode.all,
          showFavorites: true,
          messageGroupSpacing: 16,
          compactMessageGroupSpacing: 0,
          saturationFactor: 1,
          customThemeCss: null,
          advanced: forkDefaultAdvancedAccessibility,
        );
        final pushed = AccessibilitySyncedField.toProtoForPush(
          local: local,
          wireBase: accessibility_pb.AccessibilitySettings(
            fontSize: 24,
            showMessageSendButton: true,
          ),
        );
        expect(pushed.hasSpaceAfterEmoji(), isTrue);
        expect(pushed.spaceAfterEmoji, isFalse);
        expect(pushed.fontSize, 24);
        expect(pushed.showMessageSendButton, isTrue);
      },
    );

    test(
      'mergeForMigration keeps local spaceAfterEmoji when remote omits it and takes remote when present',
      () {
        final field = forkUpstream.splashZoomField();
        const localOff = AccessibilityLocalState(
          spaceAfterEmoji: false,
          hasSpaceAfterEmojiInProto: true,
          hideKeyboardHints: false,
          channelTypingIndicatorMode: ChannelTypingIndicatorMode.avatars,
          showSelectedChannelTypingIndicator: false,
          showFadedUnreadOnMutedChannels: false,
          dmMessagePreviewMode: DmMessagePreviewMode.all,
          showFavorites: true,
          messageGroupSpacing: 16,
          compactMessageGroupSpacing: 0,
          saturationFactor: 1,
          customThemeCss: null,
          advanced: forkDefaultAdvancedAccessibility,
        );
        final remoteOmitted = AccessibilitySyncedField.fromProto(
          accessibility_pb.AccessibilitySettings(fontSize: 14),
        );
        final mergedOmitted = field.mergeForMigration(
          local: localOff,
          remote: remoteOmitted,
        );
        expect(mergedOmitted.spaceAfterEmoji, isFalse);
        expect(mergedOmitted.hasSpaceAfterEmojiInProto, isTrue);

        final remoteOn = AccessibilitySyncedField.fromProto(
          accessibility_pb.AccessibilitySettings(spaceAfterEmoji: true),
        );
        final mergedOn = field.mergeForMigration(
          local: localOff,
          remote: remoteOn,
        );
        expect(mergedOn.spaceAfterEmoji, isTrue);
        expect(mergedOn.hasSpaceAfterEmojiInProto, isTrue);
      },
    );

    test('statesEqual detects spaceAfterEmoji changes', () {
      final field = forkUpstream.splashZoomField();
      const base = AccessibilityLocalState(
        hideKeyboardHints: false,
        channelTypingIndicatorMode: ChannelTypingIndicatorMode.avatars,
        showSelectedChannelTypingIndicator: false,
        showFadedUnreadOnMutedChannels: false,
        dmMessagePreviewMode: DmMessagePreviewMode.all,
        showFavorites: true,
        messageGroupSpacing: 16,
        compactMessageGroupSpacing: 0,
        saturationFactor: 1,
        customThemeCss: null,
        advanced: forkDefaultAdvancedAccessibility,
      );
      const sameValueWithFlag = AccessibilityLocalState(
        hasSpaceAfterEmojiInProto: true,
        hideKeyboardHints: false,
        channelTypingIndicatorMode: ChannelTypingIndicatorMode.avatars,
        showSelectedChannelTypingIndicator: false,
        showFadedUnreadOnMutedChannels: false,
        dmMessagePreviewMode: DmMessagePreviewMode.all,
        showFavorites: true,
        messageGroupSpacing: 16,
        compactMessageGroupSpacing: 0,
        saturationFactor: 1,
        customThemeCss: null,
        advanced: forkDefaultAdvancedAccessibility,
      );
      const turnedOff = AccessibilityLocalState(
        spaceAfterEmoji: false,
        hasSpaceAfterEmojiInProto: true,
        hideKeyboardHints: false,
        channelTypingIndicatorMode: ChannelTypingIndicatorMode.avatars,
        showSelectedChannelTypingIndicator: false,
        showFadedUnreadOnMutedChannels: false,
        dmMessagePreviewMode: DmMessagePreviewMode.all,
        showFavorites: true,
        messageGroupSpacing: 16,
        compactMessageGroupSpacing: 0,
        saturationFactor: 1,
        customThemeCss: null,
        advanced: forkDefaultAdvancedAccessibility,
      );
      expect(field.statesEqual(base, sameValueWithFlag), isTrue);
      expect(field.statesEqual(base, turnedOff), isFalse);
    });
  });
}
