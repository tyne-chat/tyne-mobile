// Fork: a sticker's preview in the composer's autocomplete shows the whole
// sticker instead of cropping it to the square (tyne-chat/tyne#659); meme
// previews keep upstream's crop. Sticker rows are the ones that give the
// preview a cache key (`StickerEntry.cacheKeyForSize`); meme rows give none.
import 'package:flutter/painting.dart';

/// How the autocomplete fits a media preview with [mediaPreviewCacheKey].
BoxFit forkAutocompleteMediaPreviewFit(String? mediaPreviewCacheKey) =>
    mediaPreviewCacheKey == null ? BoxFit.cover : BoxFit.contain;
