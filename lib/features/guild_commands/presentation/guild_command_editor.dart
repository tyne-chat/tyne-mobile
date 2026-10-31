import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/api/api_exception.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/composer/composer_autocomplete_field.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/messages/message_markdown.dart';
import 'package:fluxer_app/features/chat/services/composer_autocomplete_trigger.dart';
import 'package:fluxer_app/features/guild_commands/data/guild_commands_repository.dart';
import 'package:fluxer_app/features/guild_commands/providers/guild_command_editing.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:fluxer_app/features/ui/bottom_sheet/fluxer_bottom_sheet.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button.dart';
import 'package:fluxer_app/features/ui/input/emoji_text_editing_controller.dart';
import 'package:fluxer_app/features/ui/input/fluxer_input.dart';
import 'package:fluxer_app/features/ui/modal/fluxer_modal.dart';
import 'package:fluxer_app/features/ui/radio_group/fluxer_radio_group.dart';
import 'package:fluxer_app/features/ui/settings/fluxer_settings_sheet.dart';
import 'package:fluxer_app/features/ui/tappable/fluxer_gesture_detector.dart';
import 'package:fluxer_app/features/ui/toast/fluxer_toast.dart';
import 'package:fluxer_app/features/ui/toast/toast_provider.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_dart/export.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const int _maxTemplateLength = 4000;
const int _maxTextLength = 100;
const String _newTemplate = '# **{{ person }} {{ input }}**';

final RegExp _namePattern = RegExp(r'^[a-z0-9_-]{1,32}$');

/// Fork: a command's name, with its slash right before it, as it is typed.
/// A prefix icon has a 48 by 48 box of its own unless the theme says otherwise,
/// which would leave the slash in that box's corner, away from the name.
class GuildCommandNameField extends StatelessWidget {
  const GuildCommandNameField({
    required this.controller,
    required this.label,
    required this.enabled,
    required this.onChanged,
    this.errorText,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final InputDecorationThemeData inputTheme = theme.inputDecorationTheme;
    // Flutter keeps 4 between a field's padding and its text. A prefix icon
    // ignores the padding, so this starts it where other fields start their text.
    final double padding = (inputTheme.contentPadding ?? EdgeInsets.zero)
        .resolve(Directionality.of(context))
        .left;
    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: inputTheme.copyWith(
          prefixIconConstraints: const BoxConstraints(),
        ),
      ),
      child: FluxerInput(
        controller: controller,
        label: label,
        enabled: enabled,
        errorText: errorText,
        prefixIcon: Padding(
          padding: EdgeInsetsDirectional.only(start: padding + 4),
          child: Text(
            '/', // i18n-ignore: the slash before a command.
            style: context.textStyles.inputText,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

/// Fork: the editor as a sheet over the command list, as the persona editor is.
class GuildCommandEditorSheet {
  GuildCommandEditorSheet._();

  static Future<void> show(
    BuildContext context, {
    required String guildId,
    required GuildCommandResponseSchema? command,
    required Set<String> taken,
    required bool editable,
  }) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final ValueNotifier<bool> canDismiss = ValueNotifier<bool>(true);
    return FluxerBottomSheet.showScrollable<void>(
      context,
      title: command == null
          ? l10n.fork.guildCommandsNew
          : l10n.fork.guildCommandEdit(command.name),
      useRootNavigator: true,
      minChildSize: 0.6,
      canDismissNotifier: canDismiss,
      builder: (_, ScrollController scrollController, VoidCallback close) {
        return GuildCommandEditor(
          guildId: guildId,
          command: command,
          taken: taken,
          editable: editable,
          scrollController: scrollController,
          canDismissNotifier: canDismiss,
          onClose: close,
        );
      },
    );
  }
}

/// Fork: creates or edits one command. A script opens read-only: it is written
/// in the web or desktop editor, which fills it in as it is typed.
class GuildCommandEditor extends ConsumerStatefulWidget {
  const GuildCommandEditor({
    required this.guildId,
    required this.command,
    required this.taken,
    required this.editable,
    required this.scrollController,
    required this.canDismissNotifier,
    required this.onClose,
    super.key,
  });

  final String guildId;

  /// Null for a new command.
  final GuildCommandResponseSchema? command;

  /// The other commands' names.
  final Set<String> taken;
  final bool editable;
  final ScrollController scrollController;

  /// False while there are unsaved changes, so a drag does not lose them.
  final ValueNotifier<bool> canDismissNotifier;
  final VoidCallback onClose;

  @override
  ConsumerState<GuildCommandEditor> createState() => _GuildCommandEditorState();
}

class _GuildCommandEditorState extends ConsumerState<GuildCommandEditor> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _hint;
  late final TextEditingController _sample;
  late final EmojiTextEditingController _template;
  final FocusNode _templateFocus = FocusNode();
  late GuildCommandInputMode _inputMode;
  bool _saving = false;

  /// Save was pressed with no name: only then is that worth pointing out.
  bool _triedSaving = false;

  GuildCommandResponseSchema? get _command => widget.command;

  bool get _isScript => _command?.kind == GuildCommandKind.script;

  bool get _canChange => widget.editable && !_isScript;

  String get _storedTemplate => _command?.template ?? _newTemplate;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: _command?.name ?? '');
    _description = TextEditingController(text: _command?.description ?? '');
    _hint = TextEditingController(text: _command?.inputHint ?? '');
    _sample = TextEditingController();
    _template = EmojiTextEditingController()..loadWithTokens(_storedTemplate);
    _inputMode = _command?.inputMode ?? GuildCommandInputMode.valueRequired;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _hint.dispose();
    _sample.dispose();
    _template.dispose();
    _templateFocus.dispose();
    super.dispose();
  }

  bool get _dirty {
    final GuildCommandResponseSchema? command = _command;
    if (command == null) {
      return _name.text.isNotEmpty ||
          _description.text.isNotEmpty ||
          _hint.text.isNotEmpty ||
          _template.actualText != _newTemplate ||
          _inputMode != GuildCommandInputMode.valueRequired;
    }
    return _name.text != command.name ||
        _description.text != command.description ||
        _hint.text != (command.inputHint ?? '') ||
        _template.actualText != (command.template ?? '') ||
        _inputMode != command.inputMode;
  }

  String? _nameError(FluxerLocalizations l10n) {
    final String name = _name.text;
    if (name.isEmpty) {
      return _triedSaving ? l10n.fork.guildCommandNameInvalid : null;
    }
    if (!_namePattern.hasMatch(name)) {
      return l10n.fork.guildCommandNameInvalid;
    }
    return widget.taken.contains(name) ? l10n.fork.guildCommandNameTaken : null;
  }

  /// Why this cannot be saved, if it cannot. Save stays on the bar regardless,
  /// beside the Reset that is the way out of a sheet with unsaved changes.
  String? _saveProblem(FluxerLocalizations l10n) {
    if (_name.text.isEmpty) {
      return l10n.fork.guildCommandNameInvalid;
    }
    return _nameError(l10n) ??
        (_template.actualText.trim().isEmpty
            ? l10n.fork.guildCommandEmptyMessage
            : null);
  }

  void _reset() {
    setState(() {
      _triedSaving = false;
      _name.text = _command?.name ?? '';
      _description.text = _command?.description ?? '';
      _hint.text = _command?.inputHint ?? '';
      _template.loadWithTokens(_storedTemplate);
      _inputMode = _command?.inputMode ?? GuildCommandInputMode.valueRequired;
    });
  }

  void _insert(String text) {
    final TextSelection selection = _template.selection;
    final int start = selection.isValid
        ? selection.start
        : _template.text.length;
    final int end = selection.isValid ? selection.end : start;
    _template.value = TextEditingValue(
      text: _template.text.replaceRange(start, end, text),
      selection: TextSelection.collapsed(offset: start + text.length),
    );
    _templateFocus.requestFocus();
    setState(() {});
  }

  void _toast(
    String message, {
    FluxerToastVariant variant = FluxerToastVariant.info,
  }) {
    ref
        .read(toastProvider.notifier)
        .show(FluxerToast(message: message, variant: variant));
  }

  Future<void> _save() async {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final String? problem = _saveProblem(l10n);
    if (problem != null) {
      setState(() => _triedSaving = true);
      _toast(problem, variant: FluxerToastVariant.danger);
      return;
    }
    final GuildCommandResponseSchema? command = _command;
    final GuildCommandsRepository repository = ref.read(
      guildCommandsRepositoryProvider,
    );
    final String hint = _inputMode == GuildCommandInputMode.none
        ? ''
        : _hint.text;
    setState(() => _saving = true);
    try {
      if (command == null) {
        await repository.create(
          guildId: widget.guildId,
          name: _name.text,
          description: _description.text,
          template: _template.actualText,
          inputMode: _inputMode,
          hint: hint,
        );
      } else {
        await repository.update(
          guildId: widget.guildId,
          commandId: command.id,
          name: _name.text,
          description: _description.text,
          template: _template.actualText,
          inputMode: _inputMode,
          hint: hint,
        );
      }
      if (!mounted) {
        return;
      }
      _toast(l10n.fork.guildCommandsSaved);
      ref.invalidate(guildCommandsSettingsProvider(widget.guildId));
      widget.onClose();
    } on Exception catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        _toast(
          l10n.fork.guildCommandSaveFailed(
            _name.text,
            ApiException.from(error).message ?? '',
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(GuildCommandResponseSchema command) async {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    await FluxerConfirmModal.show(
      context,
      title: l10n.fork.guildCommandDeleteTitle(command.name),
      description: l10n.fork.guildCommandDeleteBody,
      confirmLabel: l10n.fork.guildCommandDelete,
      isDanger: true,
      onConfirm: () => unawaited(_delete(command)),
    );
  }

  Future<void> _delete(GuildCommandResponseSchema command) async {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    try {
      await ref
          .read(guildCommandsRepositoryProvider)
          .delete(guildId: widget.guildId, commandId: command.id);
      if (mounted) {
        ref.invalidate(guildCommandsSettingsProvider(widget.guildId));
        widget.onClose();
      }
    } on Exception catch (error) {
      if (mounted) {
        _toast(
          l10n.fork.guildCommandSaveFailed(
            command.name,
            ApiException.from(error).message ?? '',
          ),
        );
      }
    }
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: context.textStyles.bodySmall.copyWith(
          color: context.colors.textTertiary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _insertButton(BuildContext context, String label, String text) {
    return FluxerGestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _insert(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: context.colors.textLink),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: context.textStyles.bodySmall.copyWith(
            color: context.colors.textLink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _templateField(FluxerLocalizations l10n) {
    if (!_canChange) {
      return FluxerInput.multiline(
        controller: _template,
        label: l10n.fork.guildCommandMessage,
        readOnly: true,
        maxLines: 10,
      );
    }
    return TextFieldTapRegion(
      child: ComposerAutocompleteField(
        controller: _template,
        focusNode: _templateFocus,
        allowedTriggers: const <ComposerAutocompleteTriggerKind>{
          ComposerAutocompleteTriggerKind.emoji,
        },
        maxActualLength: _maxTemplateLength,
        onApplied: () => setState(() {}),
        child: FluxerInput.multiline(
          controller: _template,
          focusNode: _templateFocus,
          label: l10n.fork.guildCommandMessage,
          maxLines: 8,
          showCounter: true,
          counterLength: () => _template.actualTextLength,
          counterMax: _maxTemplateLength,
          onChanged: (_) => setState(() {}),
        ),
      ),
    );
  }

  Widget _preview(BuildContext context) {
    final String content = fillBasicGuildCommandTemplate(
      _template.actualText,
      person: '<@${ref.read(currentUserIdProvider) ?? ''}>',
      input: _inputMode == GuildCommandInputMode.none ? '' : _sample.text,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.backgroundPrimary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: MessageMarkdown(data: content, guildId: widget.guildId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final GuildCommandResponseSchema? command = _command;
    final bool hasUnsavedChanges = _canChange && _dirty;
    if (widget.canDismissNotifier.value == hasUnsavedChanges) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.canDismissNotifier.value = !hasUnsavedChanges;
      });
    }
    final Widget content = ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        kSettingsScrollBottomPadding + kSettingsSaveBarScrollExtra,
      ),
      children: <Widget>[
        _sectionLabel(context, l10n.fork.guildCommandSectionCommand),
        GuildCommandNameField(
          controller: _name,
          label: l10n.fork.guildCommandName,
          enabled: _canChange,
          errorText: _nameError(l10n),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        FluxerInput(
          controller: _description,
          label: l10n.fork.guildCommandDescription,
          enabled: _canChange,
          maxLength: _maxTextLength,
          onChanged: (_) => setState(() {}),
        ),
        _sectionLabel(context, l10n.fork.guildCommandSectionInput),
        FluxerRadioGroup<GuildCommandInputMode>(
          value: _inputMode,
          items: <FluxerRadioItem<GuildCommandInputMode>>[
            FluxerRadioItem<GuildCommandInputMode>(
              value: GuildCommandInputMode.none,
              label: l10n.fork.guildCommandInputNone,
              enabled: _canChange,
            ),
            FluxerRadioItem<GuildCommandInputMode>(
              value: GuildCommandInputMode.optional,
              label: l10n.fork.guildCommandInputOptional,
              enabled: _canChange,
            ),
            FluxerRadioItem<GuildCommandInputMode>(
              value: GuildCommandInputMode.valueRequired,
              label: l10n.fork.guildCommandInputRequired,
              enabled: _canChange,
            ),
          ],
          onChanged: (GuildCommandInputMode mode) {
            if (_canChange) {
              setState(() => _inputMode = mode);
            }
          },
        ),
        if (_inputMode != GuildCommandInputMode.none) ...<Widget>[
          const SizedBox(height: 12),
          FluxerInput(
            controller: _hint,
            label: l10n.fork.guildCommandHint,
            enabled: _canChange,
            maxLength: _maxTextLength,
            onChanged: (_) => setState(() {}),
          ),
        ],
        _sectionLabel(context, l10n.fork.guildCommandMessage),
        if (_isScript) ...<Widget>[
          Text(
            l10n.fork.guildCommandScriptReadOnly,
            style: TextStyle(color: context.colors.textTertiary),
          ),
          const SizedBox(height: 8),
        ] else if (_canChange) ...<Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(
                l10n.fork.guildCommandInsert,
                style: TextStyle(color: context.colors.textTertiary),
              ),
              _insertButton(
                context,
                l10n.fork.guildCommandInsertPerson,
                '{{ person }}',
              ),
              _insertButton(
                context,
                l10n.fork.guildCommandInsertInput,
                '{{ input }}',
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        _templateField(l10n),
        if (!_isScript) ...<Widget>[
          _sectionLabel(context, l10n.fork.guildCommandPreview),
          if (_inputMode != GuildCommandInputMode.none) ...<Widget>[
            FluxerInput(
              controller: _sample,
              label: l10n.fork.guildCommandSampleInput,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
          ],
          _preview(context),
        ],
        if (command != null && widget.editable) ...<Widget>[
          const SizedBox(height: 24),
          FluxerButton.dangerPrimary(
            label: l10n.fork.guildCommandDeleteCommand,
            icon: PhosphorIconsFill.trash,
            onPressed: _saving
                ? null
                : () => unawaited(_confirmDelete(command)),
          ),
        ],
      ],
    );
    return FluxerSettingsSheet(
      hasUnsavedChanges: hasUnsavedChanges,
      isSaving: _saving,
      onReset: _reset,
      onSave: () => unawaited(_save()),
      child: content,
    );
  }
}
