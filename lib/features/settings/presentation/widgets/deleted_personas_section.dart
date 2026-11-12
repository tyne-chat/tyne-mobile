// SPDX-License-Identifier: AGPL-3.0-or-later

// Fork: Deleted personas, the last section of the Personas settings page
// (tyne-chat/tyne#610), as in the web app: the list is asked for when the
// person taps Show, a failure waits for Retry, and Restore brings a persona
// back at once, one at a time. A long list scrolls inside its own box. The
// requests are in `deleted_personas.dart`.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/domain/persona_image_urls.dart';
import 'package:fluxer_app/features/profile/providers/deleted_personas.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:intl/intl.dart';

/// The height above which the list scrolls inside its box: about five rows.
const double kDeletedPersonasListMaxHeight = 360;

class DeletedPersonasSection extends ConsumerWidget {
  const DeletedPersonasSection({required this.userId, super.key});

  /// The account's id, for the personas' avatars.
  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;
    final DeletedPersonasState state = ref.watch(deletedPersonasProvider);
    final DeletedPersonasNotifier notifier = ref.read(
      deletedPersonasProvider.notifier,
    );
    final TextStyle statusStyle = textStyles.bodySmall.copyWith(
      color: colors.textSecondary,
    );

    final Widget body = switch (state.status) {
      DeletedPersonasStatus.closed => Align(
        alignment: AlignmentDirectional.centerStart,
        child: FluxerButton.secondary(
          key: const ValueKey<String>('deleted-personas-show'),
          size: FluxerButtonSize.small,
          fitContent: true,
          label: l10n.fork.deletedPersonasShow,
          onPressed: () => unawaited(notifier.load()),
        ),
      ),
      DeletedPersonasStatus.loading => Row(
        children: <Widget>[
          FluxerLoadingSpinner(
            size: FluxerLoadingSpinnerSize.small,
            color: colors.textSecondary,
          ),
          SizedBox(width: layout.s2),
          Text(l10n.uiLoading, style: statusStyle),
        ],
      ),
      DeletedPersonasStatus.failed => Row(
        children: <Widget>[
          Expanded(
            child: Text(
              l10n.fork.deletedPersonasLoadFailed,
              style: statusStyle,
            ),
          ),
          SizedBox(width: layout.s2),
          FluxerButton.secondary(
            key: const ValueKey<String>('deleted-personas-retry'),
            size: FluxerButtonSize.small,
            fitContent: true,
            label: l10n.retry,
            onPressed: () => unawaited(notifier.load()),
          ),
        ],
      ),
      DeletedPersonasStatus.ready when state.personas.isEmpty => Text(
        l10n.fork.deletedPersonasEmpty,
        style: statusStyle,
      ),
      DeletedPersonasStatus.ready => _DeletedPersonasList(
        personas: state.personas,
        restoringId: state.restoringId,
        userId: userId,
        onRestore: (Persona persona) =>
            unawaited(_restore(context, ref, persona)),
      ),
    };

    return FluxerSettingsSection(
      sectionId: 'persona-settings-deleted',
      linkable: false,
      title: l10n.fork.deletedPersonasTitle,
      description: l10n.fork.deletedPersonasDescription,
      children: <Widget>[body],
    );
  }

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    Persona persona,
  ) async {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final Toast toasts = ref.read(toastProvider.notifier);
    final DeletedPersonasNotifier notifier = ref.read(
      deletedPersonasProvider.notifier,
    );
    try {
      final PersonaRestoreResult? result = await notifier.restore(persona.id);
      if (result == null) {
        return;
      }
      final List<String> lost = <String>[
        for (final PersonaTag tag in result.droppedTags)
          tag.displayPattern(l10n.fork.personaTagExampleText),
        ...result.droppedSignatureEmojis,
      ];
      final String back = l10n.fork.personaRestored(result.name);
      toasts.show(
        FluxerToast(
          message: lost.isEmpty
              ? back
              : '$back ${l10n.fork.personaRestoredWithout(lost.join(', '))}',
          variant: FluxerToastVariant.success,
        ),
      );
    } on Object catch (err, st) {
      talker.warning('[DeletedPersonasSection] Restore failed: $err', err, st);
      toasts.show(
        FluxerToast(
          message: _serverMessage(err) ?? l10n.fork.personaRestoreFailed,
          variant: FluxerToastVariant.danger,
        ),
      );
    }
  }

  /// The server's own explanation of a refusal (such as the persona limit).
  static String? _serverMessage(Object err) {
    if (err is! DioException) {
      return null;
    }
    final Object? data = err.response?.data;
    final Object? message = data is Map ? data['message'] : null;
    return message is String && message.trim().isNotEmpty ? message : null;
  }
}

class _DeletedPersonasList extends StatefulWidget {
  const _DeletedPersonasList({
    required this.personas,
    required this.restoringId,
    required this.userId,
    required this.onRestore,
  });

  final List<Persona> personas;
  final String? restoringId;
  final String? userId;
  final void Function(Persona persona) onRestore;

  @override
  State<_DeletedPersonasList> createState() => _DeletedPersonasListState();
}

class _DeletedPersonasListState extends State<_DeletedPersonasList> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;
    return Container(
      key: const ValueKey<String>('deleted-personas-list'),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(layout.s2),
        border: Border.all(color: colors.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: kDeletedPersonasListMaxHeight,
        ),
        child: Scrollbar(
          controller: _scroll,
          child: ListView.separated(
            controller: _scroll,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: widget.personas.length,
            separatorBuilder: (BuildContext context, int index) => Divider(
              height: 1,
              thickness: 1,
              indent: layout.s3 + 40 + layout.s3,
              color: colors.borderColor,
            ),
            itemBuilder: (BuildContext context, int index) {
              final Persona persona = widget.personas[index];
              return _DeletedPersonaRow(
                persona: persona,
                userId: widget.userId,
                restoring: widget.restoringId == persona.id,
                onRestore: widget.restoringId == null
                    ? () => widget.onRestore(persona)
                    : null,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DeletedPersonaRow extends StatelessWidget {
  const _DeletedPersonaRow({
    required this.persona,
    required this.userId,
    required this.restoring,
    required this.onRestore,
  });

  final Persona persona;
  final String? userId;
  final bool restoring;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;
    final DateTime? deletedAt = persona.deletedAt;
    final String tags = persona.personaTags
        .map(
          (PersonaTag t) => t.displayPattern(l10n.fork.personaTagExampleText),
        )
        .where((String t) => t.isNotEmpty)
        .join(' ');
    final String meta = <String>[
      if (deletedAt != null)
        l10n.fork.deletedPersonaDeletedAt(
          DateFormat.yMMMd(l10n.localeName).format(deletedAt.toLocal()),
        ),
      if (tags.isNotEmpty) tags,
      l10n.fork.deletedPersonaUseCount(persona.useCount),
    ].join(' · ');

    return Padding(
      padding: EdgeInsets.all(layout.s3),
      child: Row(
        children: <Widget>[
          FluxerAvatar.user(
            userId: userId,
            imageUrl: personaImageHash(persona.avatarHash),
            fallbackText: persona.name,
            showStatus: false,
          ),
          SizedBox(width: layout.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  persona.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyles.heading.copyWith(
                    fontSize: 16,
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: layout.s1 / 2),
                Text(
                  meta,
                  style: textStyles.bodySmall.copyWith(
                    color: colors.textPrimaryMuted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: layout.s2),
          FluxerButton.secondary(
            key: ValueKey<String>('deleted-persona-restore-${persona.id}'),
            size: FluxerButtonSize.compact,
            fitContent: true,
            isLoading: restoring,
            label: l10n.fork.deletedPersonaRestore,
            semanticLabel: l10n.fork.deletedPersonaRestoreLabel(persona.name),
            onPressed: onRestore,
          ),
        ],
      ),
    );
  }
}
