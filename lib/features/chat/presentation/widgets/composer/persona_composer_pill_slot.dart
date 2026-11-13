// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/providers/app/account_user_id.dart';
import 'package:fluxer_app/features/chat/domain/cloud_composer_attachments.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/composer/persona_composer_pill.dart';
import 'package:fluxer_app/features/chat/providers/upload/cloud_upload_controller.dart';
import 'package:fluxer_app/material_ui.dart';

/// Fork: the persona pill's place in the phone composer's row
/// (tyne-chat/tyne#623).
///
/// The composer around it rebuilds on every frame of the keyboard animation.
/// This slot listens to the text itself and hands back the same pill while the
/// text and attachments it shows are unchanged, so Flutter skips the pill and
/// its persona preview on those frames. It also keeps the pill's providers
/// out of the composer's own dependencies.
class PersonaComposerPillSlot extends ConsumerStatefulWidget {
  const PersonaComposerPillSlot({
    required this.controller,
    required this.wireText,
    required this.channelId,
    super.key,
  });

  /// The composer's text, listened to for changes.
  final Listenable controller;

  /// The text as it would be sent, which the pill previews personas from.
  final String Function() wireText;
  final String channelId;

  @override
  ConsumerState<PersonaComposerPillSlot> createState() =>
      _PersonaComposerPillSlotState();
}

class _PersonaComposerPillSlotState
    extends ConsumerState<PersonaComposerPillSlot> {
  Widget? _pill;
  Object? _pillInputs;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(PersonaComposerPillSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!watchPersonaPillVisible(ref)) {
      return const SizedBox.shrink();
    }
    final bool hasAttachments = ref.watch(
      cloudUploadControllerProvider(
        watchAccountUserId(ref),
        widget.channelId,
      ).select((CloudComposerAttachments a) => a.items.isNotEmpty),
    );
    final String text = widget.wireText();
    final Object inputs = (text, hasAttachments, widget.channelId);
    final Widget? previous = _pill;
    if (previous != null && inputs == _pillInputs) {
      return previous;
    }
    _pillInputs = inputs;
    return _pill = Padding(
      padding: const EdgeInsets.only(bottom: 2, right: 6),
      child: PersonaComposerPill(
        text: text,
        hasAttachments: hasAttachments,
        channelId: widget.channelId,
      ),
    );
  }
}
