// Fork: "Alert for every message" in the notification settings
// (tyne-chat/tyne#468). Android only: the policy it turns off decides how
// Android conversation notifications alert.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fluxer_app/core/push/notification/fork_alert_every_message.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';

class ForkNotificationAlertEveryMessageSwitch extends StatefulWidget {
  const ForkNotificationAlertEveryMessageSwitch({super.key});

  @override
  State<ForkNotificationAlertEveryMessageSwitch> createState() =>
      _ForkNotificationAlertEveryMessageSwitchState();
}

class _ForkNotificationAlertEveryMessageSwitchState
    extends State<ForkNotificationAlertEveryMessageSwitch> {
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final bool enabled = await readForkPushAlertEveryMessage();
    if (mounted) {
      setState(() => _enabled = enabled);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return const SizedBox.shrink();
    }
    final ForkLocalizations l10n = FluxerLocalizations.of(context).fork;
    return FluxerSettingsSwitchItem(
      label: l10n.notificationsAlertEveryMessageLabel,
      description: l10n.notificationsAlertEveryMessageDescription,
      value: _enabled ?? false,
      enabled: _enabled != null,
      onChanged: (bool enabled) {
        setState(() => _enabled = enabled);
        unawaited(writeForkPushAlertEveryMessage(enabled: enabled));
      },
    );
  }
}
