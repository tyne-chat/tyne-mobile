import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/utils/messages/markdown_timestamp_format.dart';
import 'package:fluxer_app/features/chat/utils/timezone_picker_utils.dart';
import 'package:fluxer_app/features/settings/providers/preferences/time_format_providers.dart';
import 'package:fluxer_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_markdown/fluxer_markdown.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ComposerInlineTimestamp extends ConsumerStatefulWidget {
  const ComposerInlineTimestamp({
    required this.epoch,
    required this.style,
    this.baseStyle,
    this.onTap,
    super.key,
  });

  final int epoch;
  final String style;
  final TextStyle? baseStyle;
  final VoidCallback? onTap;

  @override
  ConsumerState<ComposerInlineTimestamp> createState() =>
      _ComposerInlineTimestampState();
}

class _ComposerInlineTimestampState
    extends ConsumerState<ComposerInlineTimestamp> {
  bool get _isRelative => widget.style == 'R' || widget.style == 'combo';

  @override
  void initState() {
    super.initState();
    if (_isRelative) {
      FluxerRelativeTimeTick.instance
        ..retain()
        ..addListener(_onTick);
    }
  }

  @override
  void didUpdateWidget(covariant ComposerInlineTimestamp oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool wasRelative =
        oldWidget.style == 'R' || oldWidget.style == 'combo';
    final bool isRelative = widget.style == 'R' || widget.style == 'combo';
    if (wasRelative != isRelative) {
      if (wasRelative) {
        FluxerRelativeTimeTick.instance
          ..removeListener(_onTick)
          ..release();
      }
      if (isRelative) {
        FluxerRelativeTimeTick.instance
          ..retain()
          ..addListener(_onTick);
      }
    }
  }

  @override
  void dispose() {
    if (_isRelative) {
      FluxerRelativeTimeTick.instance
        ..removeListener(_onTick)
        ..release();
    }
    super.dispose();
  }

  // What the relative text read at the last build, and what it was built
  // from: a tick rebuilds only when the text changes (tyne-chat/tyne#436), as
  // upstream's FluxerLiveTimestamp does.
  String? _shownRelative;
  FluxerLocalizations? _l10n;
  bool _use12Hour = false;

  String _relative(FluxerLocalizations l10n, bool use12Hour) =>
      formatMarkdownTimestamp(
        DateTime.fromMillisecondsSinceEpoch(widget.epoch * 1000),
        'R',
        l10n,
        use12Hour: use12Hour,
      );

  void _onTick() {
    final FluxerLocalizations? l10n = _l10n;
    if (!mounted || l10n == null) {
      return;
    }
    if (_relative(l10n, _use12Hour) != _shownRelative) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final bool use12Hour = ref.watch(use12HourTimeFormatProvider);
    final String? userTimezone = ref.watch(
      userSettingsViewModelProvider.select((s) => s.timezone),
    );
    final DateTime dt = DateTime.fromMillisecondsSinceEpoch(
      widget.epoch * 1000,
    );
    final DateTime absoluteDt = adjustToViewerTimezone(dt, userTimezone);
    _l10n = l10n;
    _use12Hour = use12Hour;
    _shownRelative = _isRelative ? _relative(l10n, use12Hour) : null;

    final String displayText;
    if (widget.style == 'combo') {
      final String absolute = formatMarkdownTimestamp(
        absoluteDt,
        'f',
        l10n,
        use12Hour: use12Hour,
      );
      final String relative = formatMarkdownTimestamp(
        dt,
        'R',
        l10n,
        use12Hour: use12Hour,
      );
      displayText = '$absolute ($relative)';
    } else if (widget.style == 'R') {
      displayText = formatMarkdownTimestamp(
        dt,
        widget.style,
        l10n,
        use12Hour: use12Hour,
      );
    } else {
      displayText = formatMarkdownTimestamp(
        absoluteDt,
        widget.style,
        l10n,
        use12Hour: use12Hour,
      );
    }

    final TextStyle textStyle =
        (widget.baseStyle ?? context.textStyles.inputText).copyWith(
          color: context.colors.textPrimary,
          fontSize: (widget.baseStyle?.fontSize ?? 14) * 0.9,
        );

    final double maxChipWidth = (MediaQuery.sizeOf(context).width * 0.75).clamp(
      160.0,
      360.0,
    );

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxChipWidth),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
          decoration: BoxDecoration(
            color: context.colors.backgroundTertiary,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: context.colors.borderColor.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                PhosphorIconsBold.clock,
                size: 12,
                color: context.colors.textSecondary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  displayText,
                  style: textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
