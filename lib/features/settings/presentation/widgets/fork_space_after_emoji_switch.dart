import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/features/settings/providers/preferences/space_after_emoji_preference.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';

/// Fork: the switch for "Add a space after emoji", in the Chat section of
/// Advanced settings (tyne-chat/tyne#650). Synced with the web app's setting
/// of the same name (`AccessibilitySettings.space_after_emoji`, field 2229).
class ForkSpaceAfterEmojiSwitch extends ConsumerWidget {
  const ForkSpaceAfterEmojiSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ForkLocalizations l10n = FluxerLocalizations.of(context).fork;
    return FluxerSettingsSwitchItem(
      label: l10n.advancedSettingSpaceAfterEmojiLabel,
      description: l10n.advancedSettingSpaceAfterEmojiDescription,
      value: ref.watch(spaceAfterEmojiPreferenceProvider),
      onChanged: (bool value) => ref
          .read(spaceAfterEmojiPreferenceProvider.notifier)
          .setSpaceAfterEmoji(value: value),
    );
  }
}
