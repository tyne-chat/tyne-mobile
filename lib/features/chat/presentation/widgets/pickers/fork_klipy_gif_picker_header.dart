// Fork: the GIF picker header with the "Powered by KLIPY" mark beside it, kept
// visible in every picker view, as KLIPY's attribution guidelines ask for.

import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/domain/gif_selection.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';

const String forkKlipyPoweredByAsset = 'assets/images/klipy-powered-by.svg';

class ForkKlipyGifPickerHeader extends StatelessWidget {
  const ForkKlipyGifPickerHeader({
    required this.provider,
    required this.child,
    super.key,
  });

  final GifProviderKind? provider;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (provider != GifProviderKind.klipy) {
      return child;
    }
    return Row(
      children: [
        Expanded(child: child),
        Padding(
          padding: EdgeInsets.only(right: context.layout.s4),
          child: const ForkKlipyPoweredBy(),
        ),
      ],
    );
  }
}

class ForkKlipyPoweredBy extends StatelessWidget {
  const ForkKlipyPoweredBy({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: FluxerLocalizations.of(context).fork.klipyPoweredBy,
      image: true,
      child: ExcludeSemantics(
        child: SvgPicture.asset(
          forkKlipyPoweredByAsset,
          height: 18,
          theme: SvgTheme(currentColor: context.colors.textTertiary),
        ),
      ),
    );
  }
}
