// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: asks for a persona group's name (tyne-chat/tyne#829), to make a group
// or rename one. The name is trimmed; the button is off while it is empty.

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/profile/domain/persona_group.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';

/// The name typed, or null when cancelled.
Future<String?> showPersonaGroupNameDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initialName = '',
}) {
  return FluxerModal.show<String>(
    context,
    title: title,
    centered: true,
    useRootNavigator: true,
    builder: (BuildContext dialogContext, VoidCallback close) =>
        _PersonaGroupNameForm(
          initialName: initialName,
          confirmLabel: confirmLabel,
        ),
    actionsBuilder: (void Function([String?]) pop) => const <Widget>[],
  );
}

class _PersonaGroupNameForm extends StatefulWidget {
  const _PersonaGroupNameForm({
    required this.initialName,
    required this.confirmLabel,
  });

  final String initialName;
  final String confirmLabel;

  @override
  State<_PersonaGroupNameForm> createState() => _PersonaGroupNameFormState();
}

class _PersonaGroupNameFormState extends State<_PersonaGroupNameForm> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName,
  )..addListener(_onChanged);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  String get _name => _controller.text.trim();

  void _submit() {
    if (_name.isNotEmpty) {
      Navigator.of(context).pop(_name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final layout = context.layout;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FluxerInput(
          key: const ValueKey<String>('persona-group-name-input'),
          controller: _controller,
          label: l10n.fork.personaGroupNameLabel,
          autofocus: true,
          maxLength: kPersonaGroupNameMaxLength,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        SizedBox(height: layout.s4),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            FluxerButton.secondary(
              fitContent: true,
              label: l10n.cancel,
              onPressed: () => Navigator.of(context).pop(),
            ),
            SizedBox(width: layout.s2),
            FluxerButton.primary(
              key: const ValueKey<String>('persona-group-name-confirm'),
              fitContent: true,
              label: widget.confirmLabel,
              onPressed: _name.isEmpty ? null : _submit,
            ),
          ],
        ),
      ],
    );
  }
}
