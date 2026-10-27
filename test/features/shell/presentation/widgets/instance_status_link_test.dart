import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/instance/well_known_compat.dart';
import 'package:fluxer_app/core/providers/well_known_provider.dart';
import 'package:fluxer_app/features/shell/presentation/widgets/instance_status_link.dart';
import 'package:fluxer_app/features/shell/presentation/widgets/service_status_connection_footer.dart';
import 'package:fluxer_app/features/shell/providers/service_status_incident_provider.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_dart/export.dart';
import 'package:riverpod/src/framework.dart' show Override;

import '../../../../helpers/pump_fluxer_app.dart';
import '../../../../helpers/test_l10n.dart';
import '../../../../helpers/well_known_fixture.dart';

const String _signalUrl = 'https://signal.group/#CjQKIExample';

WellKnownFluxerResponse _wellKnown({
  required bool selfHosted,
  String? statusPageUrl,
}) {
  final Map<String, dynamic> json =
      jsonDecode(
            jsonEncode(
              wellKnownFixture(
                media: 'https://chat.example/media',
                staticCdn: 'https://chat.example/static',
                selfHosted: selfHosted,
              ).toJson(),
            ),
          )
          as Map<String, dynamic>;
  (json['app_public'] as Map<String, dynamic>)['branding']
        as Map<String, dynamic>
    ..['status_page_url'] = statusPageUrl
    ..['status_page_incident_history_url'] = statusPageUrl;
  return parseWellKnownFluxer(json);
}

class _LoadedWellKnown extends WellKnown {
  _LoadedWellKnown(this._response);

  final WellKnownFluxerResponse _response;

  @override
  Future<WellKnownFluxerResponse> build() async => _response;
}

class _PendingWellKnown extends WellKnown {
  @override
  Future<WellKnownFluxerResponse> build() =>
      Completer<WellKnownFluxerResponse>().future;
}

/// Counts the HTTP clients Dio opens, and refuses every connection.
class _CountingHttpOverrides extends HttpOverrides {
  int clientsCreated = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    clientsCreated++;
    throw const SocketException('network disabled in this test');
  }
}

Future<int> _clientsOpenedByIncidentRefresh(Override wellKnown) async {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[wellKnown],
  );
  addTearDown(container.dispose);
  container.listen(wellKnownProvider, (_, _) {});
  await Future<void>.delayed(Duration.zero);
  final _CountingHttpOverrides http = _CountingHttpOverrides();
  await HttpOverrides.runWithHttpOverrides(
    () => container.read(serviceStatusIncidentReadProvider.notifier).refresh(),
    http,
  );
  expect(container.read(serviceStatusIncidentReadProvider), isNull);
  return http.clientsCreated;
}

Future<void> _pumpFooter(
  WidgetTester tester,
  WellKnownFluxerResponse wellKnown, {
  bool showPrompt = true,
}) async {
  await tester.pumpWidget(
    pumpFluxerApp(
      overrides: <Override>[
        wellKnownProvider.overrideWith(() => _LoadedWellKnown(wellKnown)),
      ],
      child: Scaffold(
        body: ServiceStatusConnectionFooter(
          promptStyle: const TextStyle(),
          linkStyle: const TextStyle(),
          showPrompt: showPrompt,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('forkIsSignalGroupLink', () {
    test('matches signal.group links only', () {
      expect(forkIsSignalGroupLink(_signalUrl), isTrue);
      expect(forkIsSignalGroupLink('https://SIGNAL.GROUP/#abc'), isTrue);
      expect(forkIsSignalGroupLink('https://status.example.com'), isFalse);
      expect(forkIsSignalGroupLink('https://signal.group.example/'), isFalse);
      expect(forkIsSignalGroupLink('not a url'), isFalse);
    });
  });

  group('forkInstanceStatusPageUrl', () {
    test('trims the URL and treats blank as none', () {
      expect(
        forkInstanceStatusPageUrl(
          _wellKnown(selfHosted: true, statusPageUrl: '  $_signalUrl '),
        ),
        _signalUrl,
      );
      expect(
        forkInstanceStatusPageUrl(
          _wellKnown(selfHosted: true, statusPageUrl: '   '),
        ),
        isNull,
      );
      expect(forkInstanceStatusPageUrl(_wellKnown(selfHosted: true)), isNull);
      expect(forkInstanceStatusPageUrl(null), isNull);
    });
  });

  group("incident refresh asks Fluxer's status page", () {
    test('never for a self-hosted instance', () async {
      final int clients = await _clientsOpenedByIncidentRefresh(
        wellKnownProvider.overrideWith(
          () => _LoadedWellKnown(_wellKnown(selfHosted: true)),
        ),
      );
      expect(clients, 0);
    });

    test('never while the instance is unknown', () async {
      final int clients = await _clientsOpenedByIncidentRefresh(
        wellKnownProvider.overrideWith(_PendingWellKnown.new),
      );
      expect(clients, 0);
    });

    test('for an instance Fluxer hosts, once, and a failure ends it', () async {
      final int clients = await _clientsOpenedByIncidentRefresh(
        wellKnownProvider.overrideWith(
          () => _LoadedWellKnown(_wellKnown(selfHosted: false)),
        ),
      );
      expect(clients, 1);
    });
  });

  group('status footer on a self-hosted instance', () {
    testWidgets('names a Signal group link as the Signal chat', (tester) async {
      await _pumpFooter(
        tester,
        _wellKnown(selfHosted: true, statusPageUrl: _signalUrl),
      );
      expect(find.text(testL10n.splashConnectionIssuesPrompt), findsOneWidget);
      expect(find.text(testL10n.fork.instanceStatusSignalLink), findsOneWidget);
      expect(find.text(testL10n.splashStatusPageLink), findsNothing);
      expect(find.text(testL10n.splashIncidentHistory), findsNothing);
    });

    testWidgets('names any other link as the status page', (tester) async {
      await _pumpFooter(
        tester,
        _wellKnown(
          selfHosted: true,
          statusPageUrl: 'https://status.example.com',
        ),
      );
      expect(find.text(testL10n.splashStatusPageLink), findsOneWidget);
      expect(find.text(testL10n.fork.instanceStatusSignalLink), findsNothing);
    });

    testWidgets('shows nothing without a status page', (tester) async {
      await _pumpFooter(tester, _wellKnown(selfHosted: true));
      expect(find.text(testL10n.splashConnectionIssuesPrompt), findsNothing);
      expect(find.text(testL10n.splashStatusPageLink), findsNothing);
    });

    testWidgets('leaves the prompt out when asked', (tester) async {
      await _pumpFooter(
        tester,
        _wellKnown(selfHosted: true, statusPageUrl: _signalUrl),
        showPrompt: false,
      );
      expect(find.text(testL10n.splashConnectionIssuesPrompt), findsNothing);
      expect(find.text(testL10n.fork.instanceStatusSignalLink), findsOneWidget);
    });
  });

  testWidgets("login status link uses the instance's page", (tester) async {
    await tester.pumpWidget(
      pumpFluxerApp(
        overrides: <Override>[
          wellKnownProvider.overrideWith(
            () => _LoadedWellKnown(
              _wellKnown(selfHosted: true, statusPageUrl: _signalUrl),
            ),
          ),
        ],
        child: const Scaffold(body: OfficialInstanceStatusPageLink()),
      ),
    );
    await tester.pump();
    expect(find.text(testL10n.fork.instanceStatusSignalLink), findsOneWidget);
    expect(find.text(testL10n.splashViewOnStatusPage), findsNothing);
  });
}
