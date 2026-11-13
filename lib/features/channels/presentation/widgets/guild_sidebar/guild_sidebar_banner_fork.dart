part of 'guild_sidebar.dart';

/// Fork: the sidebar header's banner image (tyne-chat/tyne#622).
///
/// Upstream draws the banner as a `DecorationImage`, whose painter keeps an
/// animated banner running whether or not the header is on screen: it ignores
/// `TickerMode`, which the sidebar drawer turns off for its hidden layer. On a
/// phone, an animated banner of 50 frames a second kept the app drawing about
/// 100 frames a second with the sidebar closed. An `Image` stops listening, and
/// so animating, while `TickerMode` is off. Otherwise it is drawn as before:
/// same fit, alignment and filter quality, and no semantics, as a decoration
/// has none.
Widget _forkGuildBanner(String url) => Image(
  image: CachedNetworkImageProvider(url),
  fit: BoxFit.cover,
  alignment: Alignment.topCenter,
  excludeFromSemantics: true,
);
