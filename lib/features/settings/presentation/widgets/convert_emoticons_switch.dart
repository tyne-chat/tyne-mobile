import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/features/settings/providers/preferences/convert_emoticons_preference.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';

/// Fork: the switch for the web's "Turn text smileys into emoji", in the
/// Input section of Messages & media (tyne-chat/tyne#260).
class ConvertEmoticonsSwitch extends ConsumerWidget {
  const ConvertEmoticonsSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FluxerSettingsSwitchItem(
      label: FluxerLocalizations.of(context).fork.convertEmoticonsLabel,
      value: ref.watch(convertEmoticonsPreferenceProvider),
      onChanged: (bool value) => ref
          .read(convertEmoticonsPreferenceProvider.notifier)
          .setConvertEmoticons(value: value),
    );
  }
}
