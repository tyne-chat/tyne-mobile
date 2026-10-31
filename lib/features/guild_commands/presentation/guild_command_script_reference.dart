import 'dart:async';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/ui/accordion/fluxer_accordion.dart';
import 'package:fluxer_app/features/ui/tappable/fluxer_gesture_detector.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/external_links/external_url_launcher.dart';

/// Fork: a short reference under the script editor, as on the web, with a link
/// to the whole language. The code stays in English: it is the language itself.
class GuildCommandScriptReference extends StatelessWidget {
  const GuildCommandScriptReference({super.key});

  static final Uri _guide = Uri.parse(
    'https://github.com/tyne-chat/tyne/blob/tyne/docs/server-command-scripts.md',
  );

  Widget _code(BuildContext context, String code) {
    return Text(
      code,
      style: context.textStyles.codeText.copyWith(
        color: context.colors.textSecondary,
      ),
    );
  }

  Widget _variable(BuildContext context, String code, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _code(context, code),
          Text(
            label,
            style: context.textStyles.bodySmall.copyWith(
              color: context.colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _example(BuildContext context, String label, String code) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: context.textStyles.bodySmall.copyWith(
              color: context.colors.textTertiary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.colors.backgroundPrimary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: _code(context, code),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    return FluxerAccordion(
      title: l10n.fork.guildCommandReferenceTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _variable(
            context,
            '{{ person }}',
            l10n.fork.guildCommandReferencePerson,
          ),
          _variable(
            context,
            '{{ person.name }}',
            l10n.fork.guildCommandReferencePersonName,
          ),
          _variable(context, '{{ input }}', l10n.fork.guildCommandInsertInput),
          _variable(
            context,
            '{{ target }}',
            l10n.fork.guildCommandReferenceTarget,
          ),
          _variable(
            context,
            '{{ target.name }}',
            l10n.fork.guildCommandReferenceTargetName,
          ),
          _variable(
            context,
            '{{ channel }}',
            l10n.fork.guildCommandReferenceChannel,
          ),
          _variable(
            context,
            '{{ community.name }}',
            l10n.fork.guildCommandReferenceCommunity,
          ),
          _example(
            context,
            l10n.fork.guildCommandExampleRandom,
            '{% random %}\nFirst option\n{% or %}\nSecond option\n{% endrandom %}',
          ),
          _example(
            context,
            l10n.fork.guildCommandExampleDepends,
            '{% if target %}\n{{ person }} hugs {{ target }}\n{% else %}\n{{ person }} hugs the air\n{% endif %}',
          ),
          _example(
            context,
            l10n.fork.guildCommandExampleOneWord,
            '{{ "warm" | one_of: "gentle", "big" }}',
          ),
          _example(
            context,
            l10n.fork.guildCommandExampleWordForNumber,
            '{{ 3 | plural: "time", "times" }}',
          ),
          _example(
            context,
            l10n.fork.guildCommandExampleOrdinal,
            '{{ 3 | ordinal }}',
          ),
          const SizedBox(height: 12),
          FluxerGestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => unawaited(openExternalUrl(_guide)),
            child: Text(
              l10n.fork.guildCommandFullGuide,
              style: context.textStyles.bodySmall.copyWith(
                color: context.colors.textLink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
