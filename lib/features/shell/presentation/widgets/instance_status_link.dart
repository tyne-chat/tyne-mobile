import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/providers/instance/well_known_provider.dart';
import 'package:fluxer_app/features/ui/text_link/fluxer_text_link.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_dart/export.dart';

// Fork: the instance's own status page instead of Fluxer's (tyne-chat/tyne#134).
//
// Upstream asks fluxerstatus.com for incidents on every start and reconnect,
// and links to it from the splash, reconnecting and login screens of the
// official instance, which in this fork is Tyne's own. Fluxer's status page
// says nothing about a self-hosted instance, so it is used only when the
// instance says Fluxer hosts it (`features.self_hosted` false). Any other
// instance, including one whose `.well-known` has not loaded, links to the
// status page in its own branding settings (`status_page_url`), or to nothing.
// The app keeps the last `.well-known` it loaded, so the link is there during
// an outage too.

/// Whether the active instance says Fluxer hosts it, the only case in which
/// Fluxer's status page is about it.
bool forkInstanceIsFluxerHosted(AsyncValue<WellKnownFluxerResponse> wellKnown) {
  final WellKnownFluxerResponse? response = wellKnown.asData?.value;
  return response != null && !response.features.selfHosted;
}

/// The instance's own status page, or null when it has none.
String? forkInstanceStatusPageUrl(WellKnownFluxerResponse? wellKnown) {
  final String? url = wellKnown?.appPublic.branding.statusPageUrl?.trim();
  return url == null || url.isEmpty ? null : url;
}

bool forkIsSignalGroupLink(String url) =>
    Uri.tryParse(url)?.host.toLowerCase() == 'signal.group';

/// A link to [url], named for a Signal group when it is one.
class ForkInstanceStatusLink extends StatelessWidget {
  const ForkInstanceStatusLink({required this.url, this.style, super.key});

  final String url;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final FluxerLocalizations strings = FluxerLocalizations.of(context);
    return FluxerTextLink(
      text: forkIsSignalGroupLink(url)
          ? strings.fork.instanceStatusSignalLink
          : strings.splashStatusPageLink,
      url: url,
      style: style,
    );
  }
}

/// The instance's status link, or nothing when it has none. Stands in for
/// upstream's `OfficialInstanceStatusPageLink`.
class ForkInstanceStatusPageLink extends ConsumerWidget {
  const ForkInstanceStatusPageLink({this.style, super.key});

  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? url = forkInstanceStatusPageUrl(
      ref.watch(wellKnownProvider).asData?.value,
    );
    if (url == null) {
      return const SizedBox.shrink();
    }
    return ForkInstanceStatusLink(url: url, style: style);
  }
}

/// "Connection issues?" and the instance's status link, or nothing when it has
/// none. Stands in for upstream's `ServiceStatusConnectionFooter`, whose second
/// link (incident history) is left out: an instance's status page is one place.
class ForkInstanceStatusFooter extends ConsumerWidget {
  const ForkInstanceStatusFooter({
    required this.promptStyle,
    required this.linkStyle,
    this.showPrompt = true,
    super.key,
  });

  final TextStyle promptStyle;
  final TextStyle linkStyle;
  final bool showPrompt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? url = forkInstanceStatusPageUrl(
      ref.watch(wellKnownProvider).asData?.value,
    );
    if (url == null) {
      return const SizedBox.shrink();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showPrompt) ...[
          Text(
            FluxerLocalizations.of(context).splashConnectionIssuesPrompt,
            style: promptStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
        ForkInstanceStatusLink(url: url, style: linkStyle),
      ],
    );
  }
}
