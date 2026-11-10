// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/core/theme/reaction_chip_colors.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/providers/core/chat_view_model.dart';
import 'package:fluxer_app/features/chat/utils/reactions/own_reactions.dart';
import 'package:fluxer_app/features/profile/domain/persona.dart';
import 'package:fluxer_app/features/profile/domain/persona_image_urls.dart';
import 'package:fluxer_app/features/profile/providers/multi_persona_reactions_provider.dart';
import 'package:fluxer_app/features/profile/providers/persona_providers.dart';
import 'package:fluxer_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:fluxer_app/features/ui/avatar/fluxer_avatar.dart';
import 'package:fluxer_app/features/ui/bottom_sheet/fluxer_bottom_sheet.dart';
import 'package:fluxer_app/features/ui/bottom_sheet/fluxer_sheet_scroll.dart';
import 'package:fluxer_app/features/ui/fullscreen_flow/fluxer_fullscreen_flow.dart';
import 'package:fluxer_app/features/ui/input/fluxer_input.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/utils/emoji/emoji_image_cache.dart';
import 'package:fluxer_app/shared/utils/emoji/emoji_utils.dart';
import 'package:fluxer_app/shared/utils/fluxer_haptics.dart';
import 'package:fluxer_app/shared/widgets/unicode_emoji_widget.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// Fork: the list of the account's own identities for one emoji on one message,
// each with a toggle (tyne-chat/tyne#86). It is the body of two sheets:
//
// - "Your reactions", opened by a tap on a reaction chip one of your identities
//   reacted with. It opens short (who reacted, plus the current identity) and
//   grows to the whole list with "React as someone else…".
// - "React as…", opened from an emoji's menu. It starts with the whole list.
//
// With "React as several personas at once" on, a row toggles that identity's
// reaction and the sheet stays open until Done. With it off only "React as…"
// opens, and a row is a single choice that closes the sheet.
//
// The order of the rows is taken once, when the sheet opens, so a row never
// moves under the finger when it is toggled. The design and the rules are the
// web app's (fluxer_app/src/features/persona/components/reactions in
// tyne-chat/tyne).

/// Opens the "Your reactions" sheet for [emoji] on a message.
Future<void> showOwnReactionsSheet(
  BuildContext context, {
  required String channelId,
  required String messageId,
  required String emoji,
  String? emojiId,
  bool animated = false,
}) => showPersonaReactionSheet(
  context,
  channelId: channelId,
  messageId: messageId,
  emoji: emoji,
  emojiId: emojiId,
  animated: animated,
  reactAs: false,
);

/// Opens the identity list for [emoji] on a message: "React as…" with
/// [reactAs], "Your reactions" without. [onReacted] runs once the sheet has
/// closed, if a reaction was changed in it.
Future<void> showPersonaReactionSheet(
  BuildContext context, {
  required String channelId,
  required String messageId,
  required String emoji,
  required bool reactAs,
  String? emojiId,
  bool animated = false,
  VoidCallback? onReacted,
}) async {
  bool changed = false;
  await FluxerBottomSheet.showScrollable<void>(
    context,
    useRootNavigator: true,
    builder:
        (
          BuildContext sheetContext,
          ScrollController scrollController,
          VoidCallback close,
        ) => PersonaReactionSheetBody(
          scrollController: scrollController,
          onClose: close,
          onChanged: () => changed = true,
          channelId: channelId,
          messageId: messageId,
          emoji: emoji,
          emojiId: emojiId,
          animated: animated,
          reactAs: reactAs,
        ),
  );
  if (changed) {
    onReacted?.call();
  }
}

/// What a tap on a reaction chip does before upstream's toggle: opens "Your
/// reactions" and returns true when one of the account's identities reacted
/// with it, "React as several personas at once" is on and the account has
/// personas. Otherwise returns false, and the tap reacts as it always did.
///
/// It reads the reaction from the open channel, not from the chip: [Reaction]'s
/// equality leaves out who reacted, so the chip's copy can be an older one.
bool openOwnReactionsSheetOnChipTap(
  BuildContext context, {
  required String channelId,
  required String? messageId,
  required Reaction reaction,
}) {
  if (messageId == null || !reaction.hasReacted) {
    return false;
  }
  final ProviderContainer container = ProviderScope.containerOf(
    context,
    listen: false,
  );
  final Reaction? live = _reactionIn(
    container.read(chatViewModelProvider),
    channelId: channelId,
    messageId: messageId,
    emoji: reaction.emoji,
    emojiId: reaction.emojiId,
  );
  if (live == null || ownReactedIds(live).isEmpty) {
    return false;
  }
  if (!opensOwnReactionsSheet(
    live,
    multi: container.read(multiPersonaReactionsProvider),
    hasPersonas:
        container.read(myPersonasProvider).asData?.value.isNotEmpty ?? false,
  )) {
    return false;
  }
  unawaited(
    showOwnReactionsSheet(
      context,
      channelId: channelId,
      messageId: messageId,
      emoji: reaction.emoji,
      emojiId: reaction.emojiId,
      animated: reaction.animated,
    ),
  );
  return true;
}

Reaction? _reactionIn(
  ChatViewState state, {
  required String channelId,
  required String messageId,
  required String emoji,
  required String? emojiId,
}) {
  if (state.channelId != channelId) {
    return null;
  }
  for (final Message message in state.messages) {
    if (message.id == messageId) {
      return findReaction(message.reactions, emoji: emoji, emojiId: emojiId);
    }
  }
  return null;
}

class PersonaReactionSheetBody extends ConsumerStatefulWidget {
  const PersonaReactionSheetBody({
    required this.scrollController,
    required this.onClose,
    required this.channelId,
    required this.messageId,
    required this.emoji,
    required this.reactAs,
    this.onChanged,
    this.emojiId,
    this.animated = false,
    super.key,
  });

  final ScrollController scrollController;
  final VoidCallback onClose;

  /// Called each time a row changes a reaction.
  final VoidCallback? onChanged;
  final String channelId;
  final String messageId;
  final String emoji;
  final String? emojiId;
  final bool animated;

  /// "React as…": the whole list from the start, and a fresh list of personas.
  final bool reactAs;

  @override
  ConsumerState<PersonaReactionSheetBody> createState() =>
      _PersonaReactionSheetBodyState();
}

class _PersonaReactionSheetBodyState
    extends ConsumerState<PersonaReactionSheetBody>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _searchController;
  AnimationController? _grow;
  String _query = '';
  late bool _expanded;

  // Taken once, when the sheet opens (see the comment at the top).
  late final String? _currentId;
  late final List<String?> _top;
  late final List<String?> _rest;
  late final List<String> _recentIds;

  @override
  void initState() {
    super.initState();
    _expanded = widget.reactAs;
    _searchController = TextEditingController();
    _searchController.addListener(() {
      final String query = _searchController.text.trim();
      if (query != _query) {
        setState(() => _query = query);
      }
    });

    final List<Persona> personas = ref.read(sortedPersonasProvider);
    final String? resolved = ref
        .read(chatViewModelProvider.notifier)
        .resolveEffectiveReactionPersona(
          emoji: widget.emoji,
          emojiId: widget.emojiId,
        );
    _currentId = personas.any((Persona p) => p.id == resolved)
        ? resolved
        : null;
    final ({List<String?> top, List<String?> rest}) split =
        splitIdentitiesForReaction(
          reaction: _reaction(ref.read(chatViewModelProvider)),
          currentId: _currentId,
          personas: personas,
        );
    _top = split.top;
    _rest = split.rest;
    _recentIds = <String>[
      for (final Persona persona in recentPersonas(
        ref.read(rankedPersonasProvider),
        usedHere: ref.read(activePersonaProvider).frecencyUsage.keys.toSet(),
      ))
        persona.id,
    ];

    // One request per opening, and only for "React as…": "Your reactions"
    // opens from the message list, where every tap on a chip would send it.
    if (widget.reactAs) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(ref.read(myPersonasProvider.notifier).reloadSilently());
        }
      });
    }
  }

  @override
  void dispose() {
    _grow?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _expand() {
    setState(() => _expanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _growToFit());
  }

  // Once anything in it has been tapped, upstream's sheet keeps the height it
  // rests at and lays a longer list out below the edge of the screen. So the
  // sheet is grown here by what the list cannot show, as a drag up would grow
  // it, and then left to settle as after a drag.
  void _growToFit() {
    final ScrollController controller = widget.scrollController;
    if (!mounted ||
        controller is! FluxerSheetScrollController ||
        !controller.hasClients) {
      return;
    }
    final double hidden = controller.position.maxScrollExtent;
    if (hidden <= 0) {
      return;
    }
    final FluxerSheetDragTarget target = controller.target;
    final AnimationController grow = _grow ??= AnimationController(vsync: this);
    final Curve curve = context.motion.curve;
    double grown = 0;
    void step() {
      final double next = hidden * curve.transform(grow.value);
      target.dragBy(grown - next);
      grown = next;
    }

    grow
      ..stop()
      ..duration = context.motion.panel
      ..addListener(step);
    grow.forward(from: 0).whenCompleteOrCancel(() {
      grow.removeListener(step);
      if (mounted) {
        target.endDrag(0);
      }
    });
  }

  Reaction? _reaction(ChatViewState state) => _reactionIn(
    state,
    channelId: widget.channelId,
    messageId: widget.messageId,
    emoji: widget.emoji,
    emojiId: widget.emojiId,
  );

  void _onIdentityTap(String? id) {
    FluxerHaptics.light();
    final ChatViewModel viewModel = ref.read(chatViewModelProvider.notifier);
    widget.onChanged?.call();
    if (ref.read(multiPersonaReactionsProvider)) {
      unawaited(
        viewModel.toggleReaction(
          widget.messageId,
          widget.emoji,
          emojiId: widget.emojiId,
          animated: widget.animated,
          personaId: id,
          explicitRoot: id == null,
        ),
      );
      return;
    }
    unawaited(
      viewModel.reactAsOnly(
        widget.messageId,
        widget.emoji,
        emojiId: widget.emojiId,
        animated: widget.animated,
        personaId: id,
      ),
    );
    widget.onClose();
  }

  Widget _emoji(double size) {
    final String? emojiId = widget.emojiId;
    return emojiId != null && emojiId.isNotEmpty
        ? SizedBox(
            width: size,
            height: size,
            child: CachedEmojiImage(
              emojiId: emojiId,
              animated: widget.animated,
              requestSize: kCustomEmojiFetchSize,
              size: size,
            ),
          )
        : UnicodeEmojiWidget(emoji: widget.emoji, size: size);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;
    final ForkLocalizations l10n = FluxerLocalizations.of(context).fork;

    final List<Persona> personas = ref.watch(sortedPersonasProvider);
    final userSettings = ref.watch(userSettingsViewModelProvider);
    // The key, not the reaction: `Reaction ==` leaves out who reacted.
    ref.watch(
      chatViewModelProvider.select(
        (ChatViewState state) => ownReactionKey(_reaction(state)),
      ),
    );
    final Reaction? reaction = _reaction(ref.read(chatViewModelProvider));

    final Map<String, Persona> byId = <String, Persona>{
      for (final Persona persona in personas) persona.id: persona,
    };
    bool exists(String? id) => id == null || byId.containsKey(id);
    final Set<String?> placed = <String?>{..._top, ..._rest};
    final List<String?> top = _top.where(exists).toList();
    // A persona that arrived after the sheet opened goes at the end.
    final List<String?> rest = <String?>[
      ..._rest.where(exists),
      for (final Persona persona in personas)
        if (!placed.contains(persona.id)) persona.id,
    ];

    final String accountName = userSettings.displayName.isNotEmpty
        ? userSettings.displayName
        : userSettings.username;
    final String needle = _query.toLowerCase();
    bool matches(String? id) => id == null
        ? accountName.toLowerCase().contains(needle) ||
              userSettings.username.toLowerCase().contains(needle)
        : personaMatchesQuery(byId[id]!, _query);

    Widget row(String? id) {
      final Persona? persona = id == null ? null : byId[id];
      return _IdentityRow(
        key: ValueKey<String>('persona-reaction-row-${id ?? 'account'}'),
        avatar: persona == null
            ? FluxerAvatar.user(
                userId: userSettings.userId,
                imageUrl: userSettings.avatarUrl,
                avatarColor: userSettings.avatarColor,
                fallbackText: accountName,
                size: 32,
                showStatus: false,
              )
            : FluxerAvatar.user(
                userId: userSettings.userId,
                imageUrl: personaImageHash(persona.avatarHash),
                fallbackText: persona.name,
                size: 32,
                showStatus: false,
              ),
        name: persona?.name ?? accountName,
        currentLabel: id == _currentId ? l10n.personaReactionsCurrent : null,
        accountLabel: id == null ? l10n.personaReactionsAccount : null,
        reacted: reaction?.hasPersonaReacted(id) ?? false,
        emoji: _emoji(18),
        onTap: () => _onIdentityTap(id),
      );
    }

    final List<Widget> rows;
    if (_query.isNotEmpty) {
      final List<String?> found = <String?>[
        ...top,
        ...rest,
      ].where(matches).toList();
      rows = <Widget>[
        if (found.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: layout.s4),
            child: Center(
              child: Text(
                l10n.personaEmptySearch,
                style: textStyles.bodySmall.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ),
          ),
        for (final String? id in found) row(id),
      ];
    } else {
      rows = <Widget>[
        for (final String? id in top) row(id),
        if (rest.isNotEmpty && !_expanded)
          _ExpandRow(label: l10n.personaReactionsSomeoneElse, onTap: _expand),
        if (rest.isNotEmpty && _expanded) ...<Widget>[
          _SectionTitle(l10n.personaReactionsEveryoneElse),
          for (final String? id in rest) row(id),
        ],
      ];
    }

    final List<Persona> recents = <Persona>[
      if (_expanded && _query.isEmpty)
        for (final String id in _recentIds)
          if (byId[id] case final Persona persona) persona,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FluxerBottomSheetHeader(
          title: widget.reactAs ? l10n.chatReactAs : l10n.personaReactionsTitle,
          leading: _emoji(24),
          trailing: FluxerPushPageAction(
            label: l10n.personaReactionsDone,
            onPressed: widget.onClose,
          ),
        ),
        SizedBox(height: layout.s2),
        // One scroll view below the title, so the sheet can measure all of it
        // and grow when the list does. The search stays in view above the rows.
        Expanded(
          child: CustomScrollView(
            controller: widget.scrollController,
            slivers: <Widget>[
              if (_expanded)
                PinnedHeaderSliver(
                  child: ColoredBox(
                    color:
                        Material.maybeOf(context)?.color ??
                        colors.backgroundSecondaryAlt,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        layout.pageGutter,
                        0,
                        layout.pageGutter,
                        layout.s2,
                      ),
                      child: FluxerInput(
                        controller: _searchController,
                        hint: l10n.personaSearchPlaceholder,
                        prefixIcon: const Icon(
                          PhosphorIconsBold.magnifyingGlass,
                          size: 16,
                        ),
                        suffixIcon: _query.isNotEmpty
                            ? const Icon(PhosphorIconsBold.x, size: 16)
                            : null,
                        onSuffixTap: _query.isNotEmpty
                            ? _searchController.clear
                            : null,
                      ),
                    ),
                  ),
                ),
              if (recents.isNotEmpty)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: layout.s2),
                        child: _SectionTitle(l10n.personaRecentHeader),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.fromLTRB(
                          layout.s3,
                          layout.s1,
                          layout.s3,
                          layout.s2,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            for (final Persona persona in recents)
                              _RecentItem(
                                key: ValueKey<String>(
                                  'persona-reaction-recent-${persona.id}',
                                ),
                                avatar: FluxerAvatar.user(
                                  userId: userSettings.userId,
                                  imageUrl: personaImageHash(
                                    persona.avatarHash,
                                  ),
                                  fallbackText: persona.name,
                                  size: 44,
                                  showStatus: false,
                                ),
                                name: persona.name,
                                reacted:
                                    reaction?.hasPersonaReacted(persona.id) ??
                                    false,
                                emoji: _emoji(12),
                                onTap: () => _onIdentityTap(persona.id),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  layout.s2,
                  0,
                  layout.s2,
                  FluxerBottomSheet.scrollBottomPaddingOf(context) + layout.s4,
                ),
                sliver: SliverList.list(children: rows),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    return Padding(
      padding: EdgeInsets.fromLTRB(layout.s2, layout.s3, layout.s2, layout.s1),
      child: Text(
        title,
        style: context.textStyles.label.copyWith(
          color: context.colors.textTertiary,
          fontSize: 11,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

const double _kRowHeight = 52;

class _IdentityRow extends StatelessWidget {
  const _IdentityRow({
    required this.avatar,
    required this.name,
    required this.reacted,
    required this.emoji,
    required this.onTap,
    this.currentLabel,
    this.accountLabel,
    super.key,
  });

  final Widget avatar;
  final String name;
  final bool reacted;
  final Widget emoji;
  final VoidCallback onTap;
  final String? currentLabel;
  final String? accountLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;
    final String? currentLabel = this.currentLabel;
    final String? accountLabel = this.accountLabel;

    return MergeSemantics(
      child: Semantics(
        button: true,
        toggled: reacted,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _kRowHeight),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: layout.s2),
              child: Row(
                children: <Widget>[
                  avatar,
                  SizedBox(width: layout.s3),
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            name,
                            style: textStyles.username.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (currentLabel != null) ...<Widget>[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: colors.backgroundModifierAccent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              currentLabel,
                              style: textStyles.label.copyWith(
                                color: colors.textSecondary,
                                fontSize: 10,
                                letterSpacing: 0.3,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ],
                        if (accountLabel != null) ...<Widget>[
                          const SizedBox(width: 6),
                          Text(
                            accountLabel,
                            style: textStyles.bodySmall.copyWith(
                              color: colors.textTertiary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: layout.s2),
                  _ReactionPill(reacted: reacted, emoji: emoji),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// The emoji is the toggle: dashed and grey with a plus when this identity has
// not reacted, filled with a check when it has.
class _ReactionPill extends StatelessWidget {
  const _ReactionPill({required this.reacted, required this.emoji});

  final bool reacted;
  final Widget emoji;

  static const double _width = 60;
  static const double _height = 34;
  static const double _radius = 10;

  // Luminance weights, alpha untouched.
  static const ColorFilter _greyscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (reacted) {
      final SelectedReactionChipColors chip = selectedReactionChipColors(
        context,
        surface: colors.backgroundSecondaryAlt,
      );
      return Container(
        width: _width,
        height: _height,
        decoration: BoxDecoration(
          color: chip.background,
          border: Border.all(color: chip.border),
          borderRadius: BorderRadius.circular(_radius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            emoji,
            const SizedBox(width: 5),
            Icon(PhosphorIconsBold.check, size: 12, color: chip.foreground),
          ],
        ),
      );
    }
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: colors.textTertiaryMuted,
        radius: _radius,
      ),
      child: SizedBox(
        width: _width,
        height: _height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(PhosphorIconsBold.plus, size: 10, color: colors.textTertiary),
            const SizedBox(width: 5),
            Opacity(
              opacity: 0.45,
              child: ColorFiltered(colorFilter: _greyscale, child: emoji),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double _dash = 3;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final Path outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.5),
          Radius.circular(radius),
        ),
      );
    for (final PathMetric metric in outline.computeMetrics()) {
      for (double start = 0; start < metric.length; start += _dash + _gap) {
        canvas.drawPath(
          metric.extractPath(start, math.min(start + _dash, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

// "React as someone else…": grows the short sheet to the whole list.
class _ExpandRow extends StatelessWidget {
  const _ExpandRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _kRowHeight),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: layout.s2),
            child: Row(
              children: <Widget>[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.backgroundModifierAccent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    PhosphorIconsBold.usersThree,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                ),
                SizedBox(width: layout.s3),
                Expanded(
                  child: Text(
                    label,
                    style: context.textStyles.username.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: layout.s2),
                Icon(
                  PhosphorIconsBold.caretDown,
                  size: 14,
                  color: colors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentItem extends StatelessWidget {
  const _RecentItem({
    required this.avatar,
    required this.name,
    required this.reacted,
    required this.emoji,
    required this.onTap,
    super.key,
  });

  final Widget avatar;
  final String name;
  final bool reacted;
  final Widget emoji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final SelectedReactionChipColors chip = selectedReactionChipColors(
      context,
      surface: colors.backgroundSecondaryAlt,
    );
    // The first word: the strip has room for a short name only.
    final String shortName = name.trim().split(RegExp(r'\s+')).first;

    return MergeSemantics(
      child: Semantics(
        button: true,
        toggled: reacted,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: 64,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: reacted
                              ? colors.brandPrimary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: avatar,
                    ),
                    if (reacted)
                      PositionedDirectional(
                        end: -3,
                        bottom: -3,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: chip.background,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.backgroundSecondaryAlt,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: emoji,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  shortName,
                  style: context.textStyles.label.copyWith(
                    color: reacted ? colors.textPrimary : colors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
