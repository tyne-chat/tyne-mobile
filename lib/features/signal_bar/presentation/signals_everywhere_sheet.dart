import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/media/fluxer_media_url.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/channels/presentation/widgets/channel_icon.dart';
import 'package:fluxer_app/features/channels/providers/channel_providers.dart';
import 'package:fluxer_app/features/channels/utils/navigation/navigate_to_channel_content.dart';
import 'package:fluxer_app/features/chat/providers/channel/channel_message_permissions_provider.dart';
import 'package:fluxer_app/features/dm/domain/dm_conversation.dart';
import 'package:fluxer_app/features/dm/providers/dm_view_model.dart';
import 'package:fluxer_app/features/guilds/domain/guild.dart';
import 'package:fluxer_app/features/guilds/providers/guild_list_view_model.dart';
import 'package:fluxer_app/features/profile/domain/persona_image_urls.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:fluxer_app/features/signal_bar/domain/signal_bar_models.dart';
import 'package:fluxer_app/features/signal_bar/providers/signal_bar_providers.dart';
import 'package:fluxer_app/features/signal_bar/providers/signal_persona_affirmation.dart';
import 'package:fluxer_app/features/ui/avatar/fluxer_avatar.dart';
import 'package:fluxer_app/features/ui/avatar/fluxer_guild_icon_avatar.dart';
import 'package:fluxer_app/features/ui/bottom_sheet/fluxer_bottom_sheet.dart';
import 'package:fluxer_app/features/ui/bottom_sheet/fluxer_confirm_sheet.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/utils/emoji/emoji_image_cache.dart';
import 'package:fluxer_app/shared/utils/fluxer_haptics.dart';
import 'package:fluxer_app/shared/widgets/unicode_emoji_widget.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const double _kRowIconSize = 28;
const double _kRowEmojiSize = 20;
const double _kRowColumnWidth = 24;
const double _kTileSize = 44;
const int _kSignalEmojiFetchSize = 64;

/// Chats listed in the restore confirmation before "+ N more".
const int _kMaxListedChats = 6;

/// A chat as the sheet shows it: a direct message from the DM list, or a
/// community channel from the local database with its community.
@immutable
class SignalChatInfo {
  const SignalChatInfo({
    required this.channelId,
    required this.name,
    required this.place,
    this.guildId,
    this.guild,
    this.channelType,
    this.conversation,
  });

  final String channelId;
  final String name;

  /// The community's name, or "Direct message" / "Group DM".
  final String place;
  final String? guildId;
  final Guild? guild;
  final ChannelType? channelType;
  final DmConversation? conversation;

  bool get isDm => guildId == null;
}

/// Looks a chat up in what the app already holds; null when it does not know
/// it (a community left, a channel deleted). Sends no request.
SignalChatInfo? resolveSignalChat(
  WidgetRef ref,
  String channelId,
  FluxerLocalizations l10n,
) {
  for (final DmConversation conversation
      in ref.watch(dmViewModelProvider).conversations) {
    if (conversation.id == channelId) {
      return SignalChatInfo(
        channelId: channelId,
        name: conversation.displayNameWith(null, l10n: l10n),
        place: conversation.isGroup
            ? l10n.guildNavbarGroupDm
            : l10n.favoritesDirectMessageSubtitle,
        conversation: conversation,
      );
    }
  }
  final Channel? channel = ref.watch(channelByIdProvider(channelId)).value;
  if (channel == null || channel.guildId.isEmpty) {
    return null;
  }
  final Guild? guild = ref
      .watch(guildListViewModelProvider)
      .guilds
      .where((Guild guild) => guild.id == channel.guildId)
      .firstOrNull;
  if (guild == null) {
    return null;
  }
  return SignalChatInfo(
    channelId: channelId,
    name: channel.name,
    place: guild.name,
    guildId: channel.guildId,
    guild: guild,
    channelType: channel.type,
  );
}

/// The signals-everywhere sheet: set a ticked signal in every chat where the
/// account has one on (and the open chat), turn all off, restore; and every
/// such chat, newest first, a tap away.
class SignalsEverywhereSheet {
  SignalsEverywhereSheet._();

  /// [openChannelId] is the chat whose strip opened the sheet; null from the
  /// profile menu.
  static Future<void> show(
    BuildContext context, {
    String? openChannelId,
    String? openGuildId,
  }) {
    return FluxerBottomSheet.show<void>(
      context,
      useRootNavigator: true,
      builder: (BuildContext sheetContext, VoidCallback close) {
        return FluxerBottomSheetContent(
          child: SignalsEverywhereSheetBody(
            openChannelId: openChannelId,
            openGuildId: openGuildId,
            onClose: close,
            onOpenChat: (SignalChatInfo chat, WidgetRef ref) {
              close();
              if (!context.mounted) {
                return;
              }
              if (chat.isDm) {
                unawaited(
                  navigateToDmChannelContent(
                    context: context,
                    ref: ref,
                    channelId: chat.channelId,
                  ),
                );
              } else {
                unawaited(
                  navigateToChannelContent(
                    context: context,
                    ref: ref,
                    channelId: chat.channelId,
                    guildId: chat.guildId,
                  ),
                );
              }
            },
            onRestore: (WidgetRef ref) {
              close();
              if (context.mounted) {
                unawaited(showSignalsRestoreSheet(context, ref));
              }
            },
          ),
        );
      },
    );
  }
}

class SignalsEverywhereSheetBody extends ConsumerStatefulWidget {
  const SignalsEverywhereSheetBody({
    required this.openChannelId,
    required this.openGuildId,
    required this.onClose,
    required this.onOpenChat,
    required this.onRestore,
    super.key,
  });

  final String? openChannelId;
  final String? openGuildId;
  final VoidCallback onClose;
  final void Function(SignalChatInfo chat, WidgetRef ref) onOpenChat;
  final void Function(WidgetRef ref) onRestore;

  @override
  ConsumerState<SignalsEverywhereSheetBody> createState() =>
      _SignalsEverywhereSheetBodyState();
}

class _SignalsEverywhereSheetBodyState
    extends ConsumerState<SignalsEverywhereSheetBody> {
  late final MySignalsNotifier _mySignals;

  @override
  void initState() {
    super.initState();
    _mySignals = ref.read(mySignalsProvider.notifier);
    // One GET each time the sheet opens, so it shows what other devices did.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_mySignals.refresh());
      }
    });
  }

  /// Whether a tile may set a signal in the open chat now.
  bool _canSetInOpenChat() {
    final String? channelId = widget.openChannelId;
    if (channelId == null || channelId.isEmpty) {
      return false;
    }
    final Map<String, List<SignalEntry>> channels = ref.watch(
      channelSignalsProvider,
    );
    if (!ref
        .read(channelSignalsProvider.notifier)
        .isEnabledIn(channels, channelId)) {
      return false;
    }
    return ref
            .watch(channelMessagePermissionsProvider(channelId))
            .value
            ?.canSendMessages ??
        true;
  }

  /// [channelId] is the open chat when a signal may be set there now; worked
  /// out in [build], since a tap must not watch providers.
  void _setEverywhere(SignalBarSignal signal, String? channelId) {
    FluxerHaptics.light();
    unawaited(
      _mySignals.setEverywhere(
        signal.id,
        channelId: channelId,
        personaId: channelId == null
            ? null
            : composerSignalPersona(
                ref.read,
                channelId,
                latchedPersonaId: latchedSignalPersonaId(ref.read, channelId),
              )?.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final MySignalsState state = ref.watch(mySignalsProvider);
    final List<SignalBarSignal> signals = ref
        .watch(signalBarConfigProvider)
        .signals;
    final List<SignalBarSignal> tiles = <SignalBarSignal>[
      for (final SignalBarSignal signal in signals)
        if (signal.everywhere) signal,
    ];
    final List<({UserSignalChat chat, SignalChatInfo info})> chats =
        <({UserSignalChat chat, SignalChatInfo info})>[
          for (final UserSignalChat chat
              in state.summary?.newestFirst ?? const <UserSignalChat>[])
            if (resolveSignalChat(ref, chat.channelId, l10n)
                case final SignalChatInfo info)
              (chat: chat, info: info),
        ];
    final String? setChannelId = _canSetInOpenChat()
        ? widget.openChannelId
        : null;
    final bool openCounts =
        setChannelId != null &&
        !chats.any((c) => c.chat.channelId == setChannelId);
    final int scope = chats.length + (openCounts ? 1 : 0);
    final int columns = chats.fold<int>(
      1,
      (int most, c) => math.max(most, c.chat.signals.length),
    );
    final bool busy = state.busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (tiles.isNotEmpty) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.fork.signalsEverywhereHeading(scope).toUpperCase(),
              style: context.textStyles.categoryName.copyWith(
                color: context.colors.textTertiary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final SignalBarSignal signal in tiles)
                _SignalTile(
                  key: ValueKey<String>('signals-everywhere-tile-${signal.id}'),
                  signal: signal,
                  label: l10n.fork.signalsEverywhereSet(signal.displayLabel),
                  onTap: busy || scope == 0
                      ? null
                      : () => _setEverywhere(signal, setChannelId),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Row(
          spacing: 8,
          children: <Widget>[
            Expanded(
              child: FluxerButton.secondary(
                key: const ValueKey<String>('signals-everywhere-turn-all-off'),
                label: l10n.fork.signalsEverywhereTurnAllOff,
                onPressed: busy || chats.isEmpty
                    ? null
                    : () {
                        FluxerHaptics.light();
                        unawaited(_mySignals.setEverywhere(null));
                      },
              ),
            ),
            Expanded(
              child: FluxerButton.secondary(
                key: const ValueKey<String>('signals-everywhere-restore'),
                label: l10n.fork.signalsEverywhereRestore,
                onPressed: busy || !(state.summary?.restoreAvailable ?? false)
                    ? null
                    : () => widget.onRestore(ref),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: context.colors.backgroundModifierAccent),
        const SizedBox(height: 4),
        if (chats.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              l10n.fork.signalsEverywhereNone,
              style: context.textStyles.bodySmall.copyWith(
                color: context.colors.textTertiary,
              ),
            ),
          )
        else
          for (final c in chats)
            _SignalChatRow(
              key: ValueKey<String>(
                'signals-everywhere-row-${c.info.channelId}',
              ),
              info: c.info,
              signals: <SignalBarSignal>[
                for (final UserSignalRef ref in c.chat.signals)
                  if (signals.where((s) => s.id == ref.signalId).firstOrNull
                      case final SignalBarSignal signal)
                    signal,
              ],
              columns: columns,
              onTap: () => widget.onOpenChat(c.info, ref),
            ),
      ],
    );
  }
}

/// A signal's emoji at [size]: the custom emoji's image or the Unicode text.
class SignalEmoji extends StatelessWidget {
  const SignalEmoji({required this.signal, required this.size, super.key});

  final SignalBarSignal signal;
  final double size;

  @override
  Widget build(BuildContext context) {
    final String? emojiId = signal.emojiId;
    return emojiId != null
        ? CachedEmojiImage(
            emojiId: emojiId,
            animated: false,
            requestSize: _kSignalEmojiFetchSize,
            size: size,
          )
        : UnicodeEmojiWidget(emoji: signal.emojiName, size: size * 0.85);
  }
}

class _SignalTile extends StatelessWidget {
  const _SignalTile({
    required this.signal,
    required this.label,
    required this.onTap,
    super.key,
  });

  final SignalBarSignal signal;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        enabled: onTap != null,
        label: label,
        child: ExcludeSemantics(
          child: Opacity(
            opacity: onTap == null ? 0.5 : 1,
            child: Material(
              color: context.colors.backgroundSecondary,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onTap,
                child: SizedBox(
                  width: _kTileSize,
                  height: _kTileSize,
                  child: Center(child: SignalEmoji(signal: signal, size: 28)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The chat's icon, as in the Quick Switcher: the person in a DM, the
/// community with the channel's type in the corner otherwise.
class SignalChatIcon extends StatelessWidget {
  const SignalChatIcon({required this.info, required this.size, super.key});

  final SignalChatInfo info;
  final double size;

  @override
  Widget build(BuildContext context) {
    final DmConversation? conversation = info.conversation;
    if (conversation != null) {
      if (conversation.isGroup) {
        return ChannelIcon(
          type: ChannelType.groupDm,
          size: size,
          color: context.colors.textPrimaryMuted,
        );
      }
      return FluxerAvatar.user(
        userId: conversation.recipientId,
        imageUrl: FluxerMediaUrl.userAvatar(
          userId: conversation.recipientId,
          hash: conversation.recipientAvatar,
        ),
        fallbackText: info.name,
        size: size,
        showStatus: false,
      );
    }
    final double badge = size * 0.5;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          FluxerGuildIconAvatar(
            name: info.guild?.name ?? info.place,
            imageUrl: info.guild?.iconUrl,
            isCircle: true,
            size: size,
          ),
          PositionedDirectional(
            end: -3,
            bottom: -3,
            child: Container(
              width: badge + 4,
              height: badge + 4,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.backgroundSecondary,
                shape: BoxShape.circle,
              ),
              child: ChannelIcon(
                type: info.channelType ?? ChannelType.guildText,
                size: badge,
                color: context.colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalChatRow extends StatelessWidget {
  const _SignalChatRow({
    required this.info,
    required this.signals,
    required this.columns,
    required this.onTap,
    super.key,
  });

  final SignalChatInfo info;
  final List<SignalBarSignal> signals;
  final int columns;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String label = <String>[
      info.name,
      info.place,
      signals.map((SignalBarSignal s) => s.displayLabel).join(', '),
    ].where((String part) => part.isNotEmpty).join(', ');
    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: context.layout.radiusMd,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: <Widget>[
                  SignalChatIcon(info: info, size: _kRowIconSize),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          info.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        Text(
                          info.place,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.bodySmall.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // The same columns in every row, against the right edge;
                  // each row fills them from the first.
                  SizedBox(
                    key: const ValueKey<String>('signals-everywhere-columns'),
                    width: columns * _kRowColumnWidth,
                    child: Row(
                      children: <Widget>[
                        for (final SignalBarSignal signal in signals)
                          SizedBox(
                            width: _kRowColumnWidth,
                            child: Center(
                              child: SignalEmoji(
                                signal: signal,
                                size: _kRowEmojiSize,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _formatWhen(BuildContext context, int at) {
  final DateTime date = DateTime.fromMillisecondsSinceEpoch(at);
  final DateTime today = DateTime.now();
  final String locale = Localizations.localeOf(context).toString();
  final String time = DateFormat.jm(locale).format(date);
  final bool sameDay =
      date.year == today.year &&
      date.month == today.month &&
      date.day == today.day;
  return sameDay ? time : '${DateFormat.MMMd(locale).format(date)}, $time';
}

/// Loads what Restore would change and asks before doing it: one GET to open,
/// one POST to confirm. When the preview cannot be loaded it says so, with
/// nothing to confirm.
Future<void> showSignalsRestoreSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  // Read before the wait: [ref] may belong to a sheet that has closed by then.
  final FluxerLocalizations l10n = FluxerLocalizations.of(context);
  final MySignalsNotifier notifier = ref.read(mySignalsProvider.notifier);
  final List<SignalBarSignal> signals = ref
      .read(signalBarConfigProvider)
      .signals;
  final UserSignalsRestorePreview? preview = await notifier
      .fetchRestorePreview();
  if (!context.mounted) {
    return;
  }
  if (preview == null || !preview.available) {
    unawaited(notifier.refresh());
    await FluxerConfirmSheet.show(
      context,
      useRootNavigator: true,
      title: l10n.fork.signalsRestoreTitle,
      description: preview == null
          ? l10n.fork.signalsRestoreUnavailable
          : l10n.fork.signalsRestoreNothing,
      confirmLabel: l10n.cancel,
    );
    return;
  }
  final String when = _formatWhen(context, preview.createdAt ?? 0);
  final SignalBarSignal? setSignal = signals
      .where((SignalBarSignal s) => s.id == preview.signalId)
      .firstOrNull;
  final String description = switch (preview.kind) {
    UserSignalsRestoreKind.set when setSignal != null =>
      l10n.fork.signalsRestoreBeforeSet(setSignal.displayLabel, when),
    UserSignalsRestoreKind.restore => l10n.fork.signalsRestoreBeforeRestore(
      when,
    ),
    _ => l10n.fork.signalsRestoreBeforeOff(when),
  };
  await FluxerConfirmSheet.show(
    context,
    useRootNavigator: true,
    title: l10n.fork.signalsRestoreTitle,
    description: description,
    body: _SignalsRestorePreview(preview: preview, signals: signals),
    confirmLabel: l10n.fork.signalsRestoreConfirm,
    cancelLabel: l10n.cancel,
    onConfirm: () => unawaited(notifier.restore()),
  );
}

class _SignalsRestorePreview extends ConsumerWidget {
  const _SignalsRestorePreview({required this.preview, required this.signals});

  final UserSignalsRestorePreview preview;
  final List<SignalBarSignal> signals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final List<({UserSignalsRestoreChat chat, SignalChatInfo info})> rows =
        <({UserSignalsRestoreChat chat, SignalChatInfo info})>[];
    final List<String> leftOut = <String>[];
    for (final UserSignalsRestoreChat chat in preview.chats) {
      final SignalChatInfo? info = resolveSignalChat(ref, chat.channelId, l10n);
      if (info == null) {
        continue;
      }
      if (!chat.available) {
        leftOut.add(info.name);
      } else if (chat.changes) {
        rows.add((chat: chat, info: info));
      }
    }
    final TextStyle heading = context.textStyles.categoryName.copyWith(
      color: context.colors.textTertiary,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (rows.isNotEmpty)
          Table(
            columnWidths: const <int, TableColumnWidth>{
              0: FlexColumnWidth(),
              1: IntrinsicColumnWidth(),
              2: FixedColumnWidth(28),
              3: IntrinsicColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: <TableRow>[
              TableRow(
                children: <Widget>[
                  const SizedBox.shrink(),
                  Text(
                    l10n.fork.signalsRestoreNow.toUpperCase(),
                    style: heading,
                  ),
                  const SizedBox.shrink(),
                  Text(
                    l10n.fork.signalsRestoreAfter.toUpperCase(),
                    style: heading,
                  ),
                ],
              ),
              for (final row in rows.take(_kMaxListedChats))
                TableRow(
                  key: ValueKey<String>(
                    'signals-restore-row-${row.info.channelId}',
                  ),
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: <Widget>[
                          SignalChatIcon(info: row.info, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              row.info.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _SignalRefs(refs: row.chat.now, signals: signals),
                    Center(
                      child: PhosphorIcon(
                        PhosphorIconsBold.arrowRight,
                        size: 14,
                        color: context.colors.textTertiary,
                      ),
                    ),
                    _SignalRefs(refs: row.chat.after, signals: signals),
                  ],
                ),
            ],
          ),
        if (rows.length > _kMaxListedChats)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.fork.signalsRestoreMoreChats(rows.length - _kMaxListedChats),
              style: context.textStyles.bodySmall.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
        if (leftOut.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.fork.signalsRestoreLeftOut(leftOut.join(', ')),
              style: context.textStyles.bodySmall.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

/// Signals with the persona each is shown as.
class _SignalRefs extends ConsumerWidget {
  const _SignalRefs({required this.refs, required this.signals});

  final List<UserSignalRef> refs;
  final List<SignalBarSignal> signals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? userId = ref.watch(currentUserIdProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: <Widget>[
        for (final UserSignalRef item in refs)
          if (signals.where((s) => s.id == item.signalId).firstOrNull
              case final SignalBarSignal signal)
            SizedBox(
              width: 26,
              height: 26,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  SignalEmoji(signal: signal, size: 22),
                  if (userId != null)
                    PositionedDirectional(
                      end: -4,
                      bottom: -4,
                      child: _PersonaBadge(
                        userId: userId,
                        personaId: item.personaId,
                      ),
                    ),
                ],
              ),
            ),
      ],
    );
  }
}

class _PersonaBadge extends ConsumerWidget {
  const _PersonaBadge({required this.userId, required this.personaId});

  final String userId;
  final String? personaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? personaId = this.personaId;
    final persona = personaId == null
        ? null
        : ref
              .watch(myPersonasProvider)
              .value
              ?.where((p) => p.id == personaId)
              .firstOrNull;
    return FluxerAvatar.user(
      userId: userId,
      imageUrl: persona != null
          ? personaImageHash(persona.avatarHash)
          : FluxerMediaUrl.userAvatar(
              userId: userId,
              hash: ref.watch(userSettingsViewModelProvider).avatar,
            ),
      fallbackText: persona?.name ?? '',
      size: 14,
      showStatus: false,
    );
  }
}
