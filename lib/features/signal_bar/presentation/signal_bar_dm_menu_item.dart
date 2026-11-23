import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/features/dm/domain/dm_channel_types.dart';
import 'package:fluxer_app/features/dm/domain/dm_conversation.dart';
import 'package:fluxer_app/features/signal_bar/domain/signal_bar_models.dart';
import 'package:fluxer_app/features/signal_bar/providers/signal_bar_providers.dart';
import 'package:fluxer_app/features/ui/bottom_sheet/fluxer_bottom_sheet.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// The signal bar's switch for [dm], to spread into a DM menu's group: one
/// item while the instance has a bar and [dm] is a DM or group DM with a
/// composer (not personal notes or the system DM), none otherwise, so the
/// group draws no empty row. As on the web, anyone in a DM or group DM may
/// switch it (tyne-chat/tyne#265, #743).
///
/// Reads the bar once, when the menu builds. [showIcon] gives the row a
/// switch icon, for menus whose rows all have one. [close] closes the menu;
/// without it the menu's route is popped.
List<Widget> signalBarDmMenuItems(
  WidgetRef ref,
  DmConversation? dm, {
  bool showIcon = false,
  VoidCallback? close,
}) {
  if (dm == null ||
      dm.isPersonalNotes ||
      isSystemDmConversation(dm) ||
      ref.read(signalBarConfigProvider).signals.isEmpty) {
    return const <Widget>[];
  }
  return <Widget>[
    SignalBarDmMenuItem(channelId: dm.id, showIcon: showIcon, close: close),
  ];
}

/// "Turn on signal bar" or "Turn off signal bar" in a DM's menu. Asks for
/// the chat as entering it would (`ChannelSignalsNotifier.shouldLoad`), so the
/// label follows the server; until the answer, a chat not loaded counts as
/// off, as everywhere else. A tap closes the menu and sends the switch.
class SignalBarDmMenuItem extends ConsumerStatefulWidget {
  const SignalBarDmMenuItem({
    required this.channelId,
    this.showIcon = false,
    this.close,
    super.key,
  });

  final String channelId;
  final bool showIcon;
  final VoidCallback? close;

  @override
  ConsumerState<SignalBarDmMenuItem> createState() =>
      _SignalBarDmMenuItemState();
}

class _SignalBarDmMenuItemState extends ConsumerState<SignalBarDmMenuItem> {
  late final ChannelSignalsNotifier _signals;

  @override
  void initState() {
    super.initState();
    _signals = ref.read(channelSignalsProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _signals.shouldLoad(widget.channelId, entering: true)) {
        unawaited(_signals.loadChannel(widget.channelId));
      }
    });
  }

  void _switch({required bool enabled}) {
    final VoidCallback? close = widget.close;
    if (close != null) {
      close();
    } else {
      Navigator.of(context).pop();
    }
    unawaited(_signals.setDmEnabled(widget.channelId, enabled: !enabled));
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = ref.watch(
      channelSignalsProvider.select(
        (Map<String, List<SignalEntry>> channels) =>
            _signals.isEnabledIn(channels, widget.channelId),
      ),
    );
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    return FluxerBottomSheetMenuItem(
      key: ValueKey<String>('signal-bar-dm-switch-${widget.channelId}'),
      label: enabled
          ? l10n.fork.signalBarDmTurnOff
          : l10n.fork.signalBarDmTurnOn,
      icon: widget.showIcon
          ? (enabled
                ? PhosphorIconsBold.toggleRight
                : PhosphorIconsBold.toggleLeft)
          : null,
      onTap: () => _switch(enabled: enabled),
    );
  }
}
