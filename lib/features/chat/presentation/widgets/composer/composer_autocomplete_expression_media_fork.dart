part of 'package:fluxer_app/features/chat/presentation/widgets/composer/composer_autocomplete_field.dart';

// Fork: stickers and saved media after the emojis in the `:` list, under the
// settings "Show stickers" and "Show saved media in expression autocomplete"
// (tyne-chat/tyne#777); the rules are in fork_expression_autocomplete_media.dart.
// One call from upstream's `_syncEmoji` hands over here. A pick goes out
// through the same handlers as `/sticker` and `/saved` (`onSelectSticker`,
// `onSelectMeme`), after the `:query` is taken out of the composer, so the
// persona tag left there, if any, chooses who sends it.
extension _ForkExpressionMedia on ComposerAutocompleteFieldState {
  /// Adds the matching stickers and saved media to [emojiRows] and shows the
  /// list. False when there are none to add: upstream then shows its emojis.
  Future<bool> _forkWithExpressionMedia(
    ComposerAutocompleteTrigger trigger,
    int generation,
    List<_ComposerRow> emojiRows,
  ) async {
    final ({List<StickerEntry> stickers, List<FavoriteMeme> memes}) media =
        await _forkExpressionMedia(trigger);
    if (generation != _syncGeneration || !mounted) {
      return true;
    }
    if (media.stickers.isEmpty && media.memes.isEmpty) {
      return false;
    }
    final FluxerLocalizations l10n = FluxerLocalizations.of(context);
    final List<_ComposerRow> rows = <_ComposerRow>[...emojiRows];
    void addDivider() {
      if (rows.isNotEmpty) {
        rows.add(_ComposerRow(title: '', onApply: () {}, isDivider: true));
      }
    }

    if (media.stickers.isNotEmpty) {
      addDivider();
      for (final StickerEntry s in media.stickers) {
        rows.add(
          _ComposerRow(
            title: s.name,
            subtitle: l10n.composerAutocompleteStickersHeading,
            onApply: () => _forkApplyExpressionSticker(s),
            mediaPreviewUrl: s.urlForSize(64),
            mediaPreviewCacheKey: s.cacheKeyForSize(64),
          ),
        );
      }
    }
    if (media.memes.isNotEmpty) {
      addDivider();
      for (final FavoriteMeme m in media.memes) {
        rows.add(
          _ComposerRow(
            title: m.name,
            subtitle: l10n.composerAutocompleteMediaHeading,
            onApply: () => _forkApplyExpressionMeme(m),
            mediaPreviewUrl: m.url,
          ),
        );
      }
    }
    final String? heading = emojiRows.isNotEmpty
        ? l10n.composerAutocompleteEmojisHeading
        : media.memes.isEmpty
        ? l10n.composerAutocompleteStickersHeading
        : media.stickers.isEmpty
        ? l10n.composerAutocompleteMediaHeading
        : null;
    _setRows(rows, heading: heading);
    return true;
  }

  Future<({List<StickerEntry> stickers, List<FavoriteMeme> memes})>
  _forkExpressionMedia(ComposerAutocompleteTrigger trigger) async {
    const ({List<StickerEntry> stickers, List<FavoriteMeme> memes}) none = (
      stickers: <StickerEntry>[],
      memes: <FavoriteMeme>[],
    );
    final ChatPreferencesState prefs = ref.read(chatPreferencesProvider);
    final bool wantStickers =
        prefs.showStickersInExpressionAutocomplete &&
        widget.onSelectSticker != null;
    final bool wantMemes =
        prefs.showMemesInExpressionAutocomplete && widget.onSelectMeme != null;
    if ((!wantStickers && !wantMemes) || !_forkExpressionDraftIsFree(trigger)) {
      return none;
    }
    final String query = trigger.matchedText;
    List<StickerEntry> stickers = const <StickerEntry>[];
    if (wantStickers) {
      // Local data only: the stickers come from the database, the recently
      // used ones from the stored usage. A provider nobody listens to is
      // paused and would not deliver a first value to a bare read, so each is
      // listened to while it is read (upstream listens to the custom emojis
      // for the same reason, `_warmCustomEmoji`).
      final void Function() stopStickers = ref
          .listenManual(allGuildStickersForPickerProvider, (_, _) {})
          .close;
      final void Function() stopFrecent = ref
          .listenManual(frecentStickersProvider, (_, _) {})
          .close;
      final List<StickerEntry> all;
      final List<StickerEntry> frecent;
      try {
        all = await ref.read(allGuildStickersForPickerProvider.future);
        frecent = await ref.read(frecentStickersProvider.future);
      } finally {
        stopStickers();
        stopFrecent();
      }
      if (!mounted) {
        return none;
      }
      final bool hasChannel = _channelId.isNotEmpty;
      final String? activeGuildId = ref.read(contextualGuildIdProvider);
      // Which stickers can be sent here, as the sticker picker decides.
      final Map<Guild, List<StickerEntry>> usable =
          guildStickerEntriesForPicker(
            guilds: ref.read(guildListViewModelProvider).guilds,
            stickers: all,
            activeGuildId: activeGuildId,
            isPremium: ref.read(
              instanceFeatureEnabledProvider(
                LimitKeys.featureGlobalExpressions,
              ),
            ),
            canUseExternalStickers:
                !hasChannel ||
                readChannelMessagePermissionsForComposer(
                  ref,
                  _channelId,
                ).canUseExternalStickers,
          );
      stickers = forkExpressionStickerMatches(
        query: query,
        available: <StickerEntry>[
          for (final List<StickerEntry> list in usable.values) ...list,
        ],
        frecent: frecent,
        activeGuildId: activeGuildId,
      );
    }
    List<FavoriteMeme> memes = const <FavoriteMeme>[];
    if (wantMemes) {
      // Local data only: the saved media list as the database holds it.
      final void Function() stopMemes = ref
          .listenManual(favoriteMemesProvider, (_, _) {})
          .close;
      final List<FavoriteMeme> all;
      try {
        all = await ref.read(favoriteMemesProvider.future);
      } finally {
        stopMemes();
      }
      if (!mounted) {
        return none;
      }
      memes = forkExpressionMemeMatches(query: query, memes: all);
    }
    return (stickers: stickers, memes: memes);
  }

  bool _forkExpressionDraftIsFree(ComposerAutocompleteTrigger trigger) {
    final List<Persona> personas =
        ref.read(myPersonasProvider).asData?.value ?? const <Persona>[];
    return forkExpressionMediaDraftIsFree(
      text: widget.controller.text,
      matchStart: trigger.matchStart,
      matchEnd: trigger.matchEnd,
      personas: personas,
      latchedPersonaId: ref
          .read(activePersonaProvider)
          .latchedIdFor(_channelId),
    );
  }

  /// Takes the `:query` out of the composer before a pick is sent, so only
  /// what the send uses up is left there. False, and nothing changed, when the
  /// composer now holds other text: then nothing is sent.
  bool _forkTakeExpressionQuery() {
    final ComposerAutocompleteTrigger? trigger = _autocompleteTriggerForApply(
      ComposerAutocompleteTriggerKind.emoji,
    );
    if (trigger == null || !_forkExpressionDraftIsFree(trigger)) {
      return false;
    }
    final String text = widget.controller.text;
    final String before = text.substring(0, trigger.matchStart);
    widget.controller.value = TextEditingValue(
      text: before + text.substring(trigger.matchEnd),
      selection: TextSelection.collapsed(offset: before.length),
    );
    return true;
  }

  void _forkApplyExpressionSticker(StickerEntry sticker) {
    if (!_forkTakeExpressionQuery()) {
      _closeMenu();
      return;
    }
    _applySticker(sticker);
  }

  void _forkApplyExpressionMeme(FavoriteMeme meme) {
    if (!_forkTakeExpressionQuery()) {
      _closeMenu();
      return;
    }
    _applyMeme(meme);
  }
}
