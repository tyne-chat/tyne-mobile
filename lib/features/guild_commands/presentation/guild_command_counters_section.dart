import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button.dart';
import 'package:fluxer_app/features/ui/checkbox/fluxer_checkbox.dart';
import 'package:fluxer_app/features/ui/input/fluxer_input.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_dart/export.dart';

const int _maxCounters = 5;

final RegExp _counterName = RegExp(r'^[a-z][a-z0-9_]{0,31}$');

/// The server's list: a counter is read as a variable, so it cannot be one.
const Set<String> _reservedCounterNames = <String>{
  'person',
  'input',
  'target',
  'channel',
  'community',
  'true',
  'false',
  'nil',
  'null',
  'blank',
  'empty',
};

/// Fork: one counter as it is being edited. It saves with the command.
class GuildCommandCounterDraft {
  GuildCommandCounterDraft({
    this.id,
    String name = '',
    Set<GuildCommandCounterPart>? per,
    this.identity = GuildCommandCounterIdentity.persona,
  }) : name = TextEditingController(text: name),
       per = per ?? <GuildCommandCounterPart>{};

  factory GuildCommandCounterDraft.of(GuildCommandCounterSchema counter) =>
      GuildCommandCounterDraft(
        id: counter.id,
        name: counter.name,
        per: counter.per.toSet(),
        identity: counter.identity,
      );

  /// Null until it is saved.
  final String? id;
  final TextEditingController name;
  final Set<GuildCommandCounterPart> per;
  GuildCommandCounterIdentity identity;

  String get signature {
    final List<String> parts = <String>[
      for (final GuildCommandCounterPart part in per) part.name,
    ]..sort();
    return '$id|${name.text}|${parts.join(',')}|${identity.name}';
  }

  GuildCommandCounterInputSchema toInput() => GuildCommandCounterInputSchema(
    id: id == null
        ? const JsonNullable<SnowflakeStringType>.undefined()
        : JsonNullable<SnowflakeStringType>.of(id),
    name: name.text,
    per: per.toList(),
    identity: identity,
  );
}

/// Whether [counter]'s name works, among [counters].
bool isGuildCommandCounterNameValid(
  List<GuildCommandCounterDraft> counters,
  GuildCommandCounterDraft counter,
) {
  final String name = counter.name.text;
  return _counterName.hasMatch(name) &&
      !_reservedCounterNames.contains(name) &&
      counters.where((GuildCommandCounterDraft c) {
            return c.name.text == name;
          }).length ==
          1;
}

/// Fork: a command's counters in its editor. Only Reset counts acts at once.
class GuildCommandCountersSection extends StatelessWidget {
  const GuildCommandCountersSection({
    required this.counters,
    required this.editable,
    required this.takesInput,
    required this.personLabel,
    required this.onChanged,
    required this.onReset,
    super.key,
  });

  final List<GuildCommandCounterDraft> counters;
  final bool editable;
  final bool takesInput;

  /// "Person running it", which the editor's insert button also says.
  final String personLabel;
  final VoidCallback onChanged;
  final ValueChanged<GuildCommandCounterDraft> onReset;

  void _togglePart(
    GuildCommandCounterDraft counter,
    GuildCommandCounterPart part, {
    required bool on,
  }) {
    if (on) {
      counter.per.add(part);
    } else {
      counter.per.remove(part);
    }
    onChanged();
  }

  Widget _part(
    GuildCommandCounterDraft counter,
    GuildCommandCounterPart part,
    String label, {
    bool enabled = true,
  }) {
    return FluxerCheckbox(
      value: counter.per.contains(part),
      label: label,
      enabled: editable && enabled,
      onChanged: (bool? on) => _togglePart(counter, part, on: on ?? false),
    );
  }

  Widget _counter(BuildContext context, GuildCommandCounterDraft counter) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final String name = counter.name.text;
    final String variable = '{{ ${name.isEmpty ? 'name' : name} }}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.backgroundPrimary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FluxerInput(
            controller: counter.name,
            label: l10n.fork.guildCommandName,
            enabled: editable,
            autocorrect: false,
            errorText:
                name.isNotEmpty &&
                    !isGuildCommandCounterNameValid(counters, counter)
                ? l10n.fork.guildCommandCounterNameInvalid
                : null,
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.fork.guildCommandCounterSeparately,
            style: context.textStyles.bodySmall.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          _part(counter, GuildCommandCounterPart.person, personLabel),
          _part(
            counter,
            GuildCommandCounterPart.target,
            l10n.fork.guildCommandCounterPersonMentioned,
            enabled: takesInput,
          ),
          _part(
            counter,
            GuildCommandCounterPart.channel,
            l10n.fork.guildCommandCounterChannel,
          ),
          FluxerCheckbox(
            value: counter.identity == GuildCommandCounterIdentity.persona,
            label: l10n.fork.guildCommandCounterPersonas,
            enabled: editable,
            onChanged: (bool? on) {
              counter.identity = on ?? false
                  ? GuildCommandCounterIdentity.persona
                  : GuildCommandCounterIdentity.account;
              onChanged();
            },
          ),
          const SizedBox(height: 4),
          Text(
            l10n.fork.guildCommandCounterHowToUse(variable),
            style: context.textStyles.bodySmall.copyWith(
              color: context.colors.textTertiary,
            ),
          ),
          if (editable) ...<Widget>[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                if (counter.id != null)
                  FluxerButton.secondary(
                    label: l10n.fork.guildCommandCounterReset,
                    fitContent: true,
                    onPressed: () => onReset(counter),
                  ),
                FluxerButton.dangerPrimary(
                  label: l10n.fork.guildCommandCounterRemove,
                  fitContent: true,
                  onPressed: () {
                    counters.remove(counter);
                    onChanged();
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final GuildCommandCounterDraft counter in counters)
          _counter(context, counter),
        if (editable && counters.length < _maxCounters)
          FluxerButton.secondary(
            label: l10n.fork.guildCommandCounterAdd,
            fitContent: true,
            onPressed: () {
              counters.add(GuildCommandCounterDraft());
              onChanged();
            },
          ),
      ],
    );
  }
}
