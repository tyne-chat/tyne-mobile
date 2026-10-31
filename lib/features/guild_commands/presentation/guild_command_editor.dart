import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/api/api_exception.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/channels/providers/channel_providers.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/composer/composer_autocomplete_field.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/messages/message_markdown.dart';
import 'package:fluxer_app/features/chat/services/composer_autocomplete_trigger.dart';
import 'package:fluxer_app/features/guild_commands/data/guild_commands_repository.dart';
import 'package:fluxer_app/features/guild_commands/presentation/guild_command_counters_section.dart';
import 'package:fluxer_app/features/guild_commands/presentation/guild_command_script_reference.dart';
import 'package:fluxer_app/features/guild_commands/presentation/guild_command_template_issue.dart';
import 'package:fluxer_app/features/guild_commands/providers/guild_command_editing.dart';
import 'package:fluxer_app/features/guild_commands/providers/guild_command_script_preview.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:fluxer_app/features/ui/bottom_sheet/fluxer_bottom_sheet.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button_size.dart';
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
import 'package:fluxer_dart/export.dart' hide ChannelType;
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

/// Fork: creates or edits one command, in the basic editor or the script
/// editor. The server fills a script in, so its preview is a request.
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

  /// Which editor is open. The text decides what the command is: a script
  /// stays in this editor until it is plain text again.
  late bool _scriptEditor;
  late final GuildCommandScriptPreview _scriptPreview;
  late List<GuildCommandCounterDraft> _counters;

  List<GuildCommandCounterDraft> _storedCounters() =>
      <GuildCommandCounterDraft>[
        for (final GuildCommandCounterSchema counter
            in _command?.counters ?? const <GuildCommandCounterSchema>[])
          GuildCommandCounterDraft.of(counter),
      ];

  String _signature(List<GuildCommandCounterDraft> counters) => counters
      .map((GuildCommandCounterDraft counter) => counter.signature)
      .join(';');

  List<String> get _counterNames => <String>[
    for (final GuildCommandCounterDraft counter in _counters)
      if (counter.name.text.isNotEmpty) counter.name.text,
  ];

  GuildCommandResponseSchema? get _command => widget.command;

  bool get _isScript => isGuildCommandScript(_template.actualText);

  bool get _canChange => widget.editable;

  String get _previewInput =>
      _inputMode == GuildCommandInputMode.none ? '' : _sample.text;

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
    _scriptEditor = _command?.kind == GuildCommandKind.script;
    _counters = _storedCounters();
    _scriptPreview = GuildCommandScriptPreview(({
      required String template,
      required String input,
      required List<String> counterNames,
      required int run,
    }) {
      return ref
          .read(guildCommandsRepositoryProvider)
          .preview(
            guildId: widget.guildId,
            template: template,
            input: input,
            channelId: _previewChannelId(),
            counterNames: counterNames,
            run: run,
          );
    });
    _template.addListener(_updatePreview);
    _sample.addListener(_updatePreview);
    _updatePreview();
  }

  /// A text channel of the community, so `{{ channel }}` has one to fill in.
  String? _previewChannelId() {
    return ref
        .read(allChannelsProvider)
        .value
        ?.where(
          (Channel channel) =>
              channel.guildId == widget.guildId &&
              channel.type == ChannelType.guildText,
        )
        .firstOrNull
        ?.id;
  }

  void _updatePreview() {
    _scriptPreview.update(
      template: _isScript ? _template.actualText : null,
      input: _previewInput,
      counterNames: _counterNames,
    );
  }

  @override
  void dispose() {
    _template.removeListener(_updatePreview);
    _sample.removeListener(_updatePreview);
    _scriptPreview.dispose();
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
          _inputMode != GuildCommandInputMode.valueRequired ||
          _counters.isNotEmpty;
    }
    return _name.text != command.name ||
        _description.text != command.description ||
        _hint.text != (command.inputHint ?? '') ||
        _template.actualText != (command.template ?? '') ||
        _inputMode != command.inputMode ||
        _signature(_counters) != _signature(_storedCounters());
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
    if (_counters.any(
      (GuildCommandCounterDraft counter) =>
          !isGuildCommandCounterNameValid(_counters, counter),
    )) {
      return l10n.fork.guildCommandCounterNameInvalid;
    }
    return _nameError(l10n) ??
        (_template.actualText.trim().isEmpty
            ? l10n.fork.guildCommandEmptyMessage
            : null);
  }

  void _reset() {
    setState(() {
      _triedSaving = false;
      _scriptEditor = _command?.kind == GuildCommandKind.script;
      _counters = _storedCounters();
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
          counters: <GuildCommandCounterInputSchema>[
            for (final GuildCommandCounterDraft counter in _counters)
              counter.toInput(),
          ],
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
          counters: <GuildCommandCounterInputSchema>[
            for (final GuildCommandCounterDraft counter in _counters)
              counter.toInput(),
          ],
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
        final GuildCommandTemplateIssueSchema? issue =
            guildCommandTemplateIssueOf(error);
        _toast(
          issue != null
              ? describeGuildCommandTemplateIssue(l10n, issue)
              : l10n.fork.guildCommandSaveFailed(
                  _name.text,
                  ApiException.from(error).message ?? '',
                ),
        );
      }
    }
  }

  Future<void> _confirmReset(GuildCommandCounterDraft counter) async {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    await FluxerConfirmModal.show(
      context,
      title: l10n.fork.guildCommandCounterReset,
      description: l10n.fork.guildCommandCounterResetConfirm(counter.name.text),
      confirmLabel: l10n.fork.guildCommandCounterReset,
      isDanger: true,
      onConfirm: () => unawaited(_resetCounts(counter)),
    );
  }

  Future<void> _resetCounts(GuildCommandCounterDraft counter) async {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    try {
      await ref
          .read(guildCommandsRepositoryProvider)
          .resetCounter(
            guildId: widget.guildId,
            commandId: _command!.id,
            counterId: counter.id!,
          );
    } on Exception catch (error) {
      if (mounted) {
        _toast(
          ApiException.from(error).message ??
              l10n.fork.guildCommandCounterReset,
          variant: FluxerToastVariant.danger,
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

  Widget _templateField(BuildContext context, FluxerLocalizations l10n) {
    final String label = _scriptEditor
        ? l10n.fork.guildCommandScript
        : l10n.fork.guildCommandMessage;
    final TextStyle? style = _scriptEditor ? context.textStyles.codeText : null;
    if (!_canChange) {
      return FluxerInput.multiline(
        controller: _template,
        label: label,
        readOnly: true,
        style: style,
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
          label: label,
          style: style,
          maxLines: _scriptEditor ? 14 : 8,
          // A keyboard's corrections would rewrite the language's words.
          autocorrect: !_scriptEditor,
          enableSuggestions: !_scriptEditor,
          showCounter: true,
          counterLength: () => _template.actualTextLength,
          counterMax: _maxTemplateLength,
          onChanged: (_) => setState(() {}),
        ),
      ),
    );
  }

  Widget _editorSwitch(BuildContext context, FluxerLocalizations l10n) {
    return FluxerGestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _scriptEditor = !_scriptEditor),
      child: Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(
          _scriptEditor
              ? l10n.fork.guildCommandUseBasicEditor
              : l10n.fork.guildCommandUseScriptEditor,
          style: context.textStyles.bodySmall.copyWith(
            color: context.colors.textLink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _previewBox(BuildContext context, String content) {
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

  Widget _scriptPreviewView(BuildContext context, FluxerLocalizations l10n) {
    return ListenableBuilder(
      listenable: _scriptPreview,
      builder: (BuildContext context, _) {
        final GuildCommandPreviewResponseSchema? result = _scriptPreview.result;
        final GuildCommandTemplateIssueSchema? issue = result?.issue;
        final String? content = result?.content;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (issue != null)
              Text(
                describeGuildCommandTemplateIssue(l10n, issue),
                style: context.textStyles.bodySmall.copyWith(
                  color: context.colors.statusDanger,
                ),
              )
            else if (content != null && content.isEmpty)
              Text(
                l10n.fork.guildCommandEmptyMessage,
                style: context.textStyles.bodySmall.copyWith(
                  color: context.colors.statusDanger,
                ),
              )
            else if (content != null)
              _previewBox(context, content),
            if (guildCommandPicksAtRandom(_template.actualText) ||
                _counters.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              FluxerButton.secondary(
                label: l10n.fork.guildCommandRunAgain,
                size: FluxerButtonSize.small,
                fitContent: true,
                onPressed: _scriptPreview.runAgain,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _preview(BuildContext context, FluxerLocalizations l10n) {
    if (_isScript) {
      return _scriptPreviewView(context, l10n);
    }
    return _previewBox(
      context,
      fillBasicGuildCommandTemplate(
        _template.actualText,
        person: '<@${ref.read(currentUserIdProvider) ?? ''}>',
        input: _previewInput,
      ),
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
              _updatePreview();
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _sectionLabel(context, l10n.fork.guildCommandMessage),
            if (_canChange && (!_scriptEditor || !_isScript))
              _editorSwitch(context, l10n),
          ],
        ),
        if (_canChange && !_scriptEditor) ...<Widget>[
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
        _templateField(context, l10n),
        if (_scriptEditor) ...<Widget>[
          const SizedBox(height: 12),
          const GuildCommandScriptReference(),
        ],
        _sectionLabel(context, l10n.fork.guildCommandCounters),
        GuildCommandCountersSection(
          counters: _counters,
          editable: _canChange,
          takesInput: _inputMode != GuildCommandInputMode.none,
          personLabel: l10n.fork.guildCommandInsertPerson,
          onChanged: () {
            setState(() {});
            _updatePreview();
          },
          onReset: (GuildCommandCounterDraft counter) =>
              unawaited(_confirmReset(counter)),
        ),
        _sectionLabel(context, l10n.fork.guildCommandPreview),
        if (_inputMode != GuildCommandInputMode.none) ...<Widget>[
          FluxerInput(
            controller: _sample,
            label: l10n.fork.guildCommandSampleInput,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
        ],
        _preview(context, l10n),
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
