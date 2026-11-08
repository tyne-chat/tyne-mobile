// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/media/fluxer_media_url.dart';
import 'package:fluxer_app/core/providers/app/account_user_id.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/domain/persona_image_urls.dart';
import 'package:fluxer_app/features/profile/presentation/sheets/edit_persona_sheet.dart';
import 'package:fluxer_app/features/profile/providers/persona_bulk_actions.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/persona_bulk_edit.dart';
import 'package:fluxer_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:fluxer_app/features/settings/providers/persona_settings_launch_provider.dart';
import 'package:fluxer_app/features/shell/providers/user/current_user_private_provider.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/utils/fork_image_upload_limit.dart';
import 'package:fluxer_app/shared/utils/image_utils.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class UserPersonaSettings extends ConsumerStatefulWidget {
  const UserPersonaSettings({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  ConsumerState<UserPersonaSettings> createState() =>
      _UserPersonaSettingsState();
}

class _UserPersonaSettingsState extends ConsumerState<UserPersonaSettings> {
  late final TextEditingController _tagTextController;
  late final TextEditingController _searchController;
  String _searchQuery = '';
  bool _isUploadingTagIcon = false;
  bool _isSaving = false;
  String? _pendingTagIcon;

  // Select mode (tyne-chat/tyne#542). The selection is kept by id across
  // filter and search changes; an id whose persona is gone counts for
  // nothing.
  PersonaVisibilityFilter _filter = PersonaVisibilityFilter.all;
  bool _selecting = false;
  final Set<String> _selected = <String>{};
  bool _bulkBusy = false;

  @override
  void initState() {
    super.initState();
    // Opened from your Personas gallery to pick personas to make public.
    final PersonaSettingsLaunch? launch = ref.read(
      personaSettingsLaunchProvider,
    );
    if (launch != null) {
      _filter = launch.filter;
      _selecting = launch.selecting;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(personaSettingsLaunchProvider.notifier).next = null;
        }
      });
    }
    final initialTag = ref.read(systemDisplayTagProvider);
    _tagTextController = TextEditingController(text: initialTag.text ?? '');
    _pendingTagIcon = initialTag.iconUrl;
    _tagTextController.addListener(_onTagControllerChanged);
    _searchController = TextEditingController();
    _searchController.addListener(() {
      final q = _searchController.text.trim().toLowerCase();
      if (q != _searchQuery) {
        setState(() => _searchQuery = q);
      }
    });
  }

  @override
  void dispose() {
    _tagTextController.removeListener(_onTagControllerChanged);
    _tagTextController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTagControllerChanged() {
    setState(() {});
  }

  bool _computeIsDirty(SystemDisplayTag currentTag) {
    final currentText = currentTag.text ?? '';
    final textDirty = _tagTextController.text.trim() != currentText.trim();
    final iconDirty = _pendingTagIcon != currentTag.iconUrl;
    return textDirty || iconDirty;
  }

  bool get _isDirty => _computeIsDirty(ref.read(systemDisplayTagProvider));

  void _onReset() {
    final currentTag = ref.read(systemDisplayTagProvider);
    _tagTextController.text = currentTag.text ?? '';
    setState(() {
      _pendingTagIcon = currentTag.iconUrl;
    });
  }

  Future<void> _onSave() async {
    setState(() => _isSaving = true);
    try {
      await ref
          .read(systemDisplayTagProvider.notifier)
          .updateDisplayTag(_tagTextController.text.trim(), _pendingTagIcon);
      if (mounted) {
        final l10n = FluxerLocalizations.of(context);
        ref
            .read(toastProvider.notifier)
            .show(
              FluxerToast(
                message: l10n.fork.personaUpdatedToast,
                variant: FluxerToastVariant.success,
              ),
            );
      }
    } on Object catch (err, st) {
      talker.error(
        '[UserPersonaSettings] Failed to save display tag: $err',
        err,
        st,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickTagIcon() async {
    final picked = await ImageUtils.pickImage();
    if (picked == null || !mounted) {
      return;
    }

    if (isImageOverUploadLimit(ref, picked.bytes)) {
      final l10n = FluxerLocalizations.of(context);
      ref
          .read(toastProvider.notifier)
          .show(
            FluxerToast(
              message: imageFileTooLargeMessage(l10n, ref),
              variant: FluxerToastVariant.danger,
            ),
          );
      return;
    }

    setState(() => _isUploadingTagIcon = true);
    try {
      final base64String = base64Encode(picked.bytes);
      final dataUri = 'data:image/png;base64,$base64String';
      final Dio dio = ref.read(fluxerDioProvider);
      final response = await dio.post<dynamic>(
        '/users/@me/personas/avatar',
        data: <String, dynamic>{'avatar': dataUri},
      );
      final dynamic data = response.data;
      final newIconUrl = (data is Map)
          ? (data['avatar_hash'] as String?)
          : null;
      if (newIconUrl != null) {
        if (mounted) {
          setState(() {
            _pendingTagIcon = newIconUrl;
          });
        }
      }
    } on Object catch (err, st) {
      talker.error(
        '[UserPersonaSettings] Tag icon upload failed: $err',
        err,
        st,
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingTagIcon = false);
      }
    }
  }

  void _removeTagIcon() {
    setState(() {
      _pendingTagIcon = null;
    });
  }

  Future<void> _confirmDeletePersona(
    BuildContext context,
    Persona persona,
  ) async {
    final l10n = FluxerLocalizations.of(context);
    final colors = context.colors;

    final bool? confirmed = await FluxerModal.show<bool>(
      context,
      title: l10n.fork.personaDeleteTitle,
      description: l10n.fork.personaDeleteMessage(persona.name),
      centered: true,
      actionsBuilder: (pop) => [
        TextButton(onPressed: () => pop(false), child: Text(l10n.cancel)),
        TextButton(
          onPressed: () => pop(true),
          child: Text(
            l10n.fork.personaDeleteConfirm,
            style: TextStyle(color: colors.textDanger),
          ),
        ),
      ],
      builder: (_, _) => const SizedBox.shrink(),
    );

    if (confirmed != true) {
      return;
    }

    try {
      final Dio dio = ref.read(fluxerDioProvider);
      await dio.delete<dynamic>('/users/@me/personas/${persona.id}');
      ref.read(myPersonasProvider.notifier).removePersona(persona.id);

      final active = ref.read(activePersonaProvider);
      if (active.activePersonaId == persona.id) {
        await ref.read(activePersonaProvider.notifier).unlatch();
      }

      if (mounted) {
        ref
            .read(toastProvider.notifier)
            .show(
              FluxerToast(
                message: l10n.fork.personaDeletedToast,
                variant: FluxerToastVariant.success,
              ),
            );
      }
    } on Object catch (err, st) {
      talker.error(
        '[UserPersonaSettings] Failed to delete persona: $err',
        err,
        st,
      );
    }
  }

  void _startSelecting([String? firstId]) {
    setState(() {
      _selecting = true;
      if (firstId != null) {
        _selected.add(firstId);
      }
    });
  }

  void _stopSelecting() {
    setState(() {
      _selecting = false;
      _selected.clear();
    });
  }

  void _toggleSelected(String id) {
    setState(() {
      if (!_selected.remove(id)) {
        _selected.add(id);
      }
    });
  }

  String _nowMessage(FluxerLocalizations l10n, String visibility, int count) =>
      switch (visibility) {
        'public' => l10n.fork.personaBulkNowPublic(count),
        'private' => l10n.fork.personaBulkNowPrivate(count),
        _ => l10n.fork.personaBulkNowUnlisted(count),
      };

  /// Gives [visibility] to the selected personas, after asking for public
  /// and private; Unlisted applies at once.
  Future<void> _bulkSetVisibility(
    String visibility,
    List<Persona> selected,
  ) async {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final int changing = selected
        .where((Persona p) => p.visibility != visibility)
        .length;
    if (changing == 0) {
      return;
    }
    if (visibility == 'public' || visibility == 'private') {
      final bool isPublic = visibility == 'public';
      final bool confirmed = await confirmPersonaBulkAction(
        context,
        title: isPublic
            ? l10n.fork.personaBulkConfirmPublicTitle(changing)
            : l10n.fork.personaBulkConfirmPrivateTitle(changing),
        body: isPublic
            ? l10n.fork.personaBulkConfirmPublicBody
            : l10n.fork.personaBulkConfirmPrivateBody,
        confirmLabel: isPublic
            ? l10n.fork.personaBulkMakePublic
            : l10n.fork.personaBulkMakePrivate,
      );
      if (!confirmed || !mounted) {
        return;
      }
    }
    final PersonaBulkActions actions = ref.read(personaBulkActionsProvider);
    final Toast toasts = ref.read(toastProvider.notifier);
    final String failed = l10n.fork.personaBulkFailed;
    setState(() => _bulkBusy = true);
    try {
      final PersonaVisibilityChange? change = await actions.setVisibility(
        <String>[for (final Persona p in selected) p.id],
        visibility,
      );
      if (mounted) {
        _stopSelecting();
      }
      if (change != null) {
        toasts.show(
          FluxerToast(
            message: _nowMessage(l10n, visibility, change.count),
            variant: FluxerToastVariant.success,
            action: FluxerToastAction(
              label: l10n.fork.personaUndo,
              onPressed: () =>
                  unawaited(_undoVisibility(actions, toasts, change, failed)),
            ),
          ),
        );
      }
    } on Object catch (err, st) {
      talker.warning(
        '[UserPersonaSettings] Bulk visibility change failed: $err',
        err,
        st,
      );
      toasts.show(
        FluxerToast(message: failed, variant: FluxerToastVariant.danger),
      );
    } finally {
      if (mounted) {
        setState(() => _bulkBusy = false);
      }
    }
  }

  static Future<void> _undoVisibility(
    PersonaBulkActions actions,
    Toast toasts,
    PersonaVisibilityChange change,
    String failed,
  ) async {
    try {
      await actions.undo(change);
    } on Object catch (err, st) {
      talker.warning(
        '[UserPersonaSettings] Undoing a visibility change failed: $err',
        err,
        st,
      );
      toasts.show(
        FluxerToast(message: failed, variant: FluxerToastVariant.danger),
      );
    }
  }

  /// Deletes the selected personas after asking.
  Future<void> _bulkDelete(List<Persona> selected) async {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    if (selected.isEmpty) {
      return;
    }
    final bool confirmed = await confirmPersonaBulkAction(
      context,
      title: l10n.fork.personaBulkConfirmDeleteTitle(selected.length),
      body: l10n.fork.personaBulkConfirmDeleteBody,
      confirmLabel: l10n.fork.personaDeleteConfirm,
      danger: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    final PersonaBulkActions actions = ref.read(personaBulkActionsProvider);
    final Toast toasts = ref.read(toastProvider.notifier);
    setState(() => _bulkBusy = true);
    try {
      final int deleted = await actions.delete(<String>[
        for (final Persona p in selected) p.id,
      ]);
      if (mounted) {
        _stopSelecting();
      }
      if (deleted > 0) {
        toasts.show(
          FluxerToast(
            message: l10n.fork.personaBulkDeleted(deleted),
            variant: FluxerToastVariant.success,
          ),
        );
      }
    } on Object catch (err, st) {
      talker.warning('[UserPersonaSettings] Bulk delete failed: $err', err, st);
      toasts.show(
        FluxerToast(
          message: l10n.fork.personaBulkFailed,
          variant: FluxerToastVariant.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _bulkBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = FluxerLocalizations.of(context);
    final colors = context.colors;
    final layout = context.layout;
    final textStyles = context.textStyles;

    final activeState = ref.watch(activePersonaProvider);
    final systemDisplayTag = ref.watch(systemDisplayTagProvider);
    final personasAsync = ref.watch(myPersonasProvider);
    final currentUser = ref.watch(
      currentUserPrivateReadProvider(watchAccountUserId(ref)),
    );

    ref.listen<SystemDisplayTag>(systemDisplayTagProvider, (prev, next) {
      if (!_isDirty) {
        final newText = next.text ?? '';
        if (_tagTextController.text != newText) {
          _tagTextController.text = newText;
        }
        setState(() {
          _pendingTagIcon = next.iconUrl;
        });
      }
    });

    final List<Persona> personas = ref.watch(sortedPersonasProvider);

    final List<Persona> filteredPersonas = personas.where((p) {
      if (_searchQuery.isEmpty) {
        return true;
      }
      if (p.name.toLowerCase().contains(_searchQuery)) {
        return true;
      }
      if (p.pronouns?.toLowerCase().contains(_searchQuery) ?? false) {
        return true;
      }
      if (p.bio?.toLowerCase().contains(_searchQuery) ?? false) {
        return true;
      }
      return p.personaTags.any(
        (t) =>
            (t.prefix?.toLowerCase().contains(_searchQuery) ?? false) ||
            (t.suffix?.toLowerCase().contains(_searchQuery) ?? false),
      );
    }).toList();

    // Select mode (tyne-chat/tyne#542): the chips count what the search
    // finds, and filter it.
    final Map<PersonaVisibilityFilter, int> filterCounts =
        <PersonaVisibilityFilter, int>{
          for (final PersonaVisibilityFilter f
              in PersonaVisibilityFilter.values)
            f: filteredPersonas.where((p) => f.matches(p.visibility)).length,
        };
    final List<Persona> shownPersonas = filteredPersonas
        .where((p) => _filter.matches(p.visibility))
        .toList();
    final List<Persona> selectedPersonas = personas
        .where((p) => _selected.contains(p.id))
        .toList();
    final bool allShownSelected =
        shownPersonas.isNotEmpty &&
        shownPersonas.every((p) => _selected.contains(p.id));

    final Persona? activePersona = activeState.activePersonaId != null
        ? personas.where((p) => p.id == activeState.activePersonaId).firstOrNull
        : null;

    final String? userAvatar = currentUser?.avatar != null
        ? FluxerMediaUrl.userAvatar(
            userId: currentUser!.id,
            hash: currentUser.avatar,
          )
        : null;

    final String previewName =
        activePersona?.name ??
        currentUser?.globalName ??
        currentUser?.username ??
        l10n.fork.personaPreviewNameFallback;
    final String? rawPreviewAvatar = activePersona?.avatarHash;
    final String? previewAvatar =
        (rawPreviewAvatar != null && rawPreviewAvatar.isNotEmpty)
        ? personaAvatarUrl(
            ownerUserId: currentUser?.id,
            hash: rawPreviewAvatar,
            animated: false,
          )
        : userAvatar;
    final String tagText = _tagTextController.text.trim();
    final String? tagIcon = _pendingTagIcon;
    // The icon is uploaded first and shown by the hash the upload returns.
    final String? resolvedTagIcon = personaTagIconUrl(
      ownerUserId: currentUser?.id,
      icon: tagIcon,
      animated: false,
    );
    final bool isDirty = _computeIsDirty(systemDisplayTag);

    final Widget content = SingleChildScrollView(
      controller: widget.scrollController,
      padding: isDirty
          ? settingsScrollPaddingWithSaveBar(context)
          : settingsScrollPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Active Persona Mode
          FluxerSettingsSection(
            sectionId: 'persona-settings-mode',
            title: l10n.fork.personaSectionTitle,
            description: l10n.fork.personaSettingsDescription,
            isFirst: true,
            children: [
              FluxerRadioGroup<PersonaMode>(
                value: activeState.mode,
                items: [
                  FluxerRadioItem(
                    value: PersonaMode.manual,
                    label: l10n.fork.personaModeManual,
                    description: l10n.fork.personaModeManualDescription,
                  ),
                  FluxerRadioItem(
                    value: PersonaMode.last,
                    label: l10n.fork.personaModeLast,
                    description: l10n.fork.personaModeLastDescription,
                  ),
                ],
                onChanged: (mode) {
                  unawaited(
                    ref.read(activePersonaProvider.notifier).setMode(mode),
                  );
                },
              ),
            ],
          ),

          // Where the selected persona applies
          FluxerSettingsSection(
            sectionId: 'persona-settings-scope',
            title: l10n.fork.personaScopeTitle,
            children: [
              FluxerRadioGroup<PersonaScope>(
                value: activeState.scope,
                items: [
                  FluxerRadioItem(
                    value: PersonaScope.global,
                    label: l10n.fork.personaScopeGlobal,
                    description: l10n.fork.personaScopeGlobalDescription,
                  ),
                  FluxerRadioItem(
                    value: PersonaScope.channel,
                    label: l10n.fork.personaScopeChannel,
                    description: l10n.fork.personaScopeChannelDescription,
                  ),
                ],
                onChanged: (scope) {
                  unawaited(
                    ref.read(activePersonaProvider.notifier).setScope(scope),
                  );
                },
              ),
            ],
          ),

          // Section 2: System Display Tag
          FluxerSettingsSection(
            sectionId: 'persona-settings-display-tag',
            title: l10n.fork.personaDisplayTagSection,
            description: l10n.fork.personaDisplayTagDescription,
            children: [
              FluxerInput(
                controller: _tagTextController,
                label: l10n.fork.personaDisplayTagLabel,
                hint: l10n.fork.personaDisplayTagHint,
                maxLength: 32,
              ),
              // Display Tag Icon
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.fork.personaDisplayTagIconLabel,
                    style: textStyles.label.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: layout.s1_5),
                  Wrap(
                    spacing: layout.s2,
                    runSpacing: layout.s2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Change and Remove show for any icon, so one that cannot
                      // be shown can still be replaced or removed.
                      if (tagIcon != null && tagIcon.isNotEmpty) ...[
                        if (resolvedTagIcon != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(layout.s1),
                            child: Image.network(
                              resolvedTagIcon,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 36,
                                height: 36,
                                color: colors.backgroundSecondary,
                                child: Icon(
                                  PhosphorIconsBold.imageBroken,
                                  size: 18,
                                  color: colors.textPrimaryMuted,
                                ),
                              ),
                            ),
                          ),
                        FluxerButton.secondary(
                          size: FluxerButtonSize.small,
                          fitContent: true,
                          label: l10n.fork.personaChangeTagIcon,
                          icon: PhosphorIconsBold.image,
                          isLoading: _isUploadingTagIcon,
                          onPressed: _isUploadingTagIcon ? null : _pickTagIcon,
                        ),
                        FluxerButton.ghost(
                          size: FluxerButtonSize.small,
                          fitContent: true,
                          label: l10n.fork.personaRemoveTagIcon,
                          icon: PhosphorIconsBold.trash,
                          onPressed: _isUploadingTagIcon
                              ? null
                              : _removeTagIcon,
                        ),
                      ] else ...[
                        FluxerButton.primary(
                          size: FluxerButtonSize.small,
                          fitContent: true,
                          label: l10n.fork.personaUploadTagIcon,
                          icon: PhosphorIconsBold.uploadSimple,
                          isLoading: _isUploadingTagIcon,
                          onPressed: _isUploadingTagIcon ? null : _pickTagIcon,
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              // Chat Preview Card
              Container(
                decoration: BoxDecoration(
                  color: colors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(layout.s2),
                  border: Border.all(color: colors.borderColor),
                ),
                padding: EdgeInsets.all(layout.s3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.fork.personaChatPreviewTitle.toUpperCase(),
                      style: textStyles.smallText.copyWith(
                        color: colors.textPrimaryMuted,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        fontSize: 11,
                      ),
                    ),
                    SizedBox(height: layout.s2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FluxerAvatar.user(
                          userId: currentUser?.id,
                          imageUrl: previewAvatar,
                          fallbackText: previewName,
                          size: 38,
                          showStatus: false,
                        ),
                        SizedBox(width: layout.s3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      previewName,
                                      style: textStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colors.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (tagText.isNotEmpty ||
                                      (resolvedTagIcon != null &&
                                          resolvedTagIcon.isNotEmpty)) ...[
                                    SizedBox(width: layout.s1_5),
                                    FluxerUserTag(
                                      label: tagText.isNotEmpty
                                          ? tagText
                                          : null,
                                      iconUrl: resolvedTagIcon,
                                    ),
                                  ],
                                  SizedBox(width: layout.s2),
                                  Text(
                                    MaterialLocalizations.of(
                                      context,
                                    ).formatTimeOfDay(
                                      const TimeOfDay(hour: 12, minute: 0),
                                    ),
                                    style: textStyles.smallText.copyWith(
                                      color: colors.textPrimaryMuted,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: layout.s1),
                              Text(
                                l10n.fork.personaChatPreviewSampleMessage,
                                style: textStyles.bodySmall.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Section 3: Configured Personas List
          FluxerSettingsSection(
            sectionId: 'persona-settings-list',
            density: FluxerSettingsSectionDensity.compact,
            title: _searchQuery.isNotEmpty
                ? '${l10n.fork.personaListTitle} (${filteredPersonas.length})'
                : '${l10n.fork.personaListTitle} (${personas.length})',
            titleTrailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (personas.isNotEmpty && !_selecting) ...[
                  FluxerButton.ghost(
                    key: const ValueKey<String>('persona-select-mode'),
                    size: FluxerButtonSize.small,
                    fitContent: true,
                    label: l10n.fork.personaBulkSelect,
                    onPressed: _startSelecting,
                  ),
                  SizedBox(width: layout.s1),
                ],
                FluxerButton.primary(
                  size: FluxerButtonSize.small,
                  fitContent: true,
                  label: l10n.fork.personaAddButton,
                  icon: PhosphorIconsBold.plus,
                  onPressed: () => EditPersonaSheet.show(context),
                ),
              ],
            ),
            children: [
              if (personas.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: layout.s1_5),
                  child: FluxerInput(
                    controller: _searchController,
                    hint: l10n.fork.personaSearchPlaceholder,
                    prefixIcon: const Icon(
                      PhosphorIconsBold.magnifyingGlass,
                      size: 16,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? const Icon(PhosphorIconsBold.x, size: 16)
                        : null,
                    onSuffixTap: _searchQuery.isNotEmpty
                        ? () => _searchController.clear()
                        : null,
                  ),
                ),
              if (personas.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: layout.s1_5),
                  child: PersonaVisibilityChips(
                    counts: filterCounts,
                    selected: _filter,
                    onSelected: (filter) => setState(() => _filter = filter),
                  ),
                ),
              if (personasAsync.isLoading && personas.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: FluxerLoadingSpinner(),
                  ),
                )
              else if (personas.isEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(layout.s4),
                  decoration: BoxDecoration(
                    color: colors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(layout.s2),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: Column(
                    children: [
                      PhosphorIcon(
                        PhosphorIconsFill.usersThree,
                        size: 44,
                        color: colors.textPrimaryMuted,
                      ),
                      SizedBox(height: layout.s2),
                      Text(
                        l10n.fork.personaEmptyState,
                        style: textStyles.bodySmall.copyWith(
                          color: colors.textPrimaryMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: layout.s3),
                      FluxerButton.primary(
                        size: FluxerButtonSize.small,
                        fitContent: true,
                        label: l10n.fork.personaAddButton,
                        icon: PhosphorIconsBold.plus,
                        onPressed: () => EditPersonaSheet.show(context),
                      ),
                    ],
                  ),
                )
              else if (filteredPersonas.isEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(layout.s4),
                  decoration: BoxDecoration(
                    color: colors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(layout.s2),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: Column(
                    children: [
                      PhosphorIcon(
                        PhosphorIconsBold.magnifyingGlass,
                        size: 36,
                        color: colors.textPrimaryMuted,
                      ),
                      SizedBox(height: layout.s2),
                      Text(
                        l10n.fork.personaEmptySearch,
                        style: textStyles.bodySmall.copyWith(
                          color: colors.textPrimaryMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else if (shownPersonas.isEmpty)
                Container(
                  key: const ValueKey<String>('persona-filter-empty'),
                  width: double.infinity,
                  padding: EdgeInsets.all(layout.s4),
                  decoration: BoxDecoration(
                    color: colors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(layout.s2),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: Text(
                    l10n.fork.personaFilterEmpty,
                    style: textStyles.bodySmall.copyWith(
                      color: colors.textPrimaryMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...shownPersonas.map(
                  (persona) => _buildPersonaCard(
                    context,
                    persona,
                    userId: currentUser?.id,
                    // With a persona per channel there is no single active
                    // one to show or set from here.
                    canSetActive: activeState.scope == PersonaScope.global,
                    isThisActive:
                        activeState.scope == PersonaScope.global &&
                        activeState.isLatched &&
                        activeState.activePersonaId == persona.id,
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    // While selecting, the bar on top and the actions at the bottom frame
    // the list; the save bar waits until select mode ends.
    final Widget framed = _selecting
        ? Column(
            children: [
              PersonaSelectionBar(
                selectedCount: selectedPersonas.length,
                allShownSelected: allShownSelected,
                canSelectAll: shownPersonas.isNotEmpty,
                onClose: _stopSelecting,
                onSelectAll: () => setState(() {
                  if (allShownSelected) {
                    _selected.removeAll(shownPersonas.map((p) => p.id));
                  } else {
                    _selected.addAll(shownPersonas.map((p) => p.id));
                  }
                }),
              ),
              Expanded(child: content),
              if (selectedPersonas.isNotEmpty)
                PersonaBulkActionBar(
                  canMakePublic: selectedPersonas.any(
                    (p) => p.visibility != 'public',
                  ),
                  canMakeUnlisted: selectedPersonas.any(
                    (p) => p.visibility != 'unlisted',
                  ),
                  canMakePrivate: selectedPersonas.any(
                    (p) => p.visibility != 'private',
                  ),
                  busy: _bulkBusy,
                  onVisibility: (visibility) => unawaited(
                    _bulkSetVisibility(visibility, selectedPersonas),
                  ),
                  onDelete: () => unawaited(_bulkDelete(selectedPersonas)),
                ),
            ],
          )
        : content;

    return FluxerSettingsSheet(
      hasUnsavedChanges: isDirty && !_selecting,
      isSaving: _isSaving,
      onReset: _onReset,
      onSave: _onSave,
      child: framed,
    );
  }

  Widget _buildPersonaCard(
    BuildContext context,
    Persona persona, {
    required bool isThisActive,
    required bool canSetActive,
    String? userId,
  }) {
    final colors = context.colors;
    final layout = context.layout;
    final textStyles = context.textStyles;
    final l10n = FluxerLocalizations.of(context);
    final bool isSelected = _selecting && _selected.contains(persona.id);
    final bool highlighted = isSelected || (!_selecting && isThisActive);

    final Widget card = Container(
      padding: EdgeInsets.all(layout.s3),
      decoration: BoxDecoration(
        color: highlighted
            ? colors.brandPrimary.withValues(alpha: 0.08)
            : colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(layout.s2),
        border: Border.all(
          color: highlighted ? colors.brandPrimary : colors.borderColor,
          width: highlighted ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_selecting) ...[
                FluxerCheckbox(
                  value: isSelected,
                  onChanged: (_) => _toggleSelected(persona.id),
                ),
                SizedBox(width: layout.s2),
              ],
              FluxerAvatar.user(
                userId: userId,
                imageUrl: personaImageHash(persona.avatarHash),
                fallbackText: persona.name,
              ),
              SizedBox(width: layout.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            persona.name,
                            style: textStyles.heading.copyWith(
                              fontSize: 16,
                              color: colors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (persona.pronouns != null &&
                            persona.pronouns!.isNotEmpty) ...[
                          SizedBox(width: layout.s1_5),
                          Text(
                            '(${persona.pronouns})',
                            style: textStyles.bodySmall.copyWith(
                              color: colors.textPrimaryMuted,
                            ),
                          ),
                        ],
                        if (persona.color != null && persona.color != 0) ...[
                          SizedBox(width: layout.s1_5),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Color(persona.color! | 0xFF000000),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                        if (persona.visibility == 'public') ...[
                          SizedBox(width: layout.s1_5),
                          PhosphorIcon(
                            PhosphorIconsBold.globeSimple,
                            size: 14,
                            color: colors.textPrimaryMuted,
                          ),
                        ] else if (persona.visibility == 'private') ...[
                          SizedBox(width: layout.s1_5),
                          PhosphorIcon(
                            PhosphorIconsBold.lockSimple,
                            size: 14,
                            color: colors.textPrimaryMuted,
                          ),
                        ],
                      ],
                    ),
                    if (persona.personaTags.isNotEmpty ||
                        (persona.bio != null && persona.bio!.isNotEmpty)) ...[
                      SizedBox(height: layout.s1),
                      Wrap(
                        spacing: layout.s1_5,
                        runSpacing: layout.s1,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          for (final tag in persona.personaTags)
                            if (tag
                                .displayPattern(l10n.fork.personaTagExampleText)
                                .isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.backgroundModifierSelected,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tag.displayPattern(
                                    l10n.fork.personaTagExampleText,
                                  ),
                                  style: textStyles.smallText.copyWith(
                                    color: colors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          if (persona.bio != null && persona.bio!.isNotEmpty)
                            Text(
                              persona.bio!,
                              style: textStyles.bodySmall.copyWith(
                                color: colors.textPrimaryMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          // Select mode hides the actions: a tap selects instead.
          if (!_selecting) ...[
            SizedBox(height: layout.s2),
            // Actions row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (canSetActive && isThisActive)
                  FluxerButton.secondary(
                    size: FluxerButtonSize.small,
                    fitContent: true,
                    label: l10n.fork.personaActiveBadge,
                    icon: PhosphorIconsFill.lockSimple,
                    onPressed: () =>
                        ref.read(activePersonaProvider.notifier).unlatch(),
                  )
                else if (canSetActive)
                  FluxerButton.secondary(
                    size: FluxerButtonSize.small,
                    fitContent: true,
                    label: l10n.fork.personaMakeActive,
                    icon: PhosphorIconsBold.lockSimpleOpen,
                    onPressed: () => ref
                        .read(activePersonaProvider.notifier)
                        .setActivePersona(persona.id),
                  ),
                if (canSetActive) SizedBox(width: layout.s2),
                FluxerButton.secondary(
                  size: FluxerButtonSize.small,
                  isSquare: true,
                  icon: PhosphorIconsBold.pencilSimple,
                  onPressed: () => EditPersonaSheet.show(
                    context,
                    persona: persona.toPublicPersona(),
                  ),
                ),
                SizedBox(width: layout.s2),
                FluxerButton.dangerSecondary(
                  size: FluxerButtonSize.small,
                  isSquare: true,
                  icon: PhosphorIconsBold.trash,
                  onPressed: () => _confirmDeletePersona(context, persona),
                ),
              ],
            ),
          ],
        ],
      ),
    );
    return Semantics(
      key: ValueKey<String>('persona-card-${persona.id}'),
      selected: _selecting ? isSelected : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _selecting ? () => _toggleSelected(persona.id) : null,
        onLongPress: _selecting ? null : () => _startSelecting(persona.id),
        child: card,
      ),
    );
  }
}
