// Fork: the instance's server list buttons (`community.server_list_buttons` in
// /.well-known/fluxer), which the fork adds to the runtime config so the server
// list hides the buttons the instance turns off. Kept out of upstream's
// instance_runtime_config_test.dart so that file stays as upstream has it.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/instance/instance_runtime_config.dart';
import 'package:fluxer_app/core/instance/well_known_compat.dart';
import 'package:fluxer_dart/export.dart';

import '../../helpers/well_known_fixture.dart';

/// upstream's well-known fixture, with [community] merged into its
/// `community` block and [branding] into `app_public.branding`.
WellKnownFluxerResponse _wellKnown({
  Map<String, Object?> community = const <String, Object?>{},
  Map<String, Object?> branding = const <String, Object?>{},
}) {
  final Map<String, dynamic> json =
      jsonDecode(
            jsonEncode(
              wellKnownFixture(
                media: 'https://chat.example/media',
                staticCdn: 'https://chat.example/static',
              ).toJson(),
            ),
          )
          as Map<String, dynamic>;
  (json['community'] as Map<String, dynamic>).addAll(community);
  ((json['app_public'] as Map<String, dynamic>)['branding']
          as Map<String, dynamic>)
      .addAll(branding);
  return parseWellKnownFluxer(json);
}

void main() {
  group('server list buttons from the instance', () {
    test('show every button when the instance says nothing about them', () {
      final InstanceRuntimeConfig config = InstanceRuntimeConfig.fromWellKnown(
        _wellKnown(),
      );

      expect(config.serverListButtons, InstanceServerListButtons.defaults);
      expect(
        InstanceRuntimeConfig.defaults.serverListButtons,
        InstanceServerListButtons.defaults,
      );
    });

    test('hide the buttons the instance turns off', () {
      final InstanceRuntimeConfig config = InstanceRuntimeConfig.fromWellKnown(
        _wellKnown(
          community: <String, Object?>{
            'server_list_buttons': <String, Object?>{
              'favorites': false,
              'explore': true,
              'create_join': false,
              'download': true,
              'help': false,
            },
          },
        ),
      );

      final InstanceServerListButtons buttons = config.serverListButtons;
      expect(buttons.favorites, isFalse);
      expect(buttons.explore, isTrue);
      expect(buttons.createJoin, isFalse);
      expect(buttons.download, isTrue);
      expect(buttons.help, isFalse);
    });

    test('count in whether two configs are the same', () {
      final InstanceRuntimeConfig allShown =
          InstanceRuntimeConfig.fromWellKnown(_wellKnown());
      final InstanceRuntimeConfig noHelp = InstanceRuntimeConfig.fromWellKnown(
        _wellKnown(
          community: <String, Object?>{
            'server_list_buttons': <String, Object?>{'help': false},
          },
        ),
      );

      expect(noHelp, isNot(allShown));
      expect(
        InstanceRuntimeConfig.fromWellKnown(_wellKnown()),
        allShown,
        reason: 'the same well-known gives an equal config',
      );
      expect(
        InstanceRuntimeConfig.fromWellKnown(_wellKnown()).hashCode,
        allShown.hashCode,
      );
    });
  });

  group('InstanceServerListButtons', () {
    test('reads a missing map as every button shown', () {
      expect(
        InstanceServerListButtons.fromJson(null),
        InstanceServerListButtons.defaults,
      );
    });

    test('shows a button the map leaves out or sends as null', () {
      final InstanceServerListButtons buttons =
          InstanceServerListButtons.fromJson(const <String, dynamic>{
            'explore': false,
            'download': null,
          });

      expect(buttons.favorites, isTrue);
      expect(buttons.explore, isFalse);
      expect(buttons.createJoin, isTrue);
      expect(buttons.download, isTrue);
      expect(buttons.help, isTrue);
    });

    test('writes the wire names and reads them back unchanged', () {
      const InstanceServerListButtons buttons = InstanceServerListButtons(
        favorites: false,
        createJoin: false,
        help: false,
      );

      final Map<String, dynamic> json = buttons.toJson();

      expect(json, <String, dynamic>{
        'favorites': false,
        'explore': true,
        'create_join': false,
        'download': true,
        'help': false,
      });
      expect(InstanceServerListButtons.fromJson(json), buttons);
      expect(
        InstanceServerListButtons.fromJson(json).hashCode,
        buttons.hashCode,
      );
    });

    test('are equal only when every button matches', () {
      const InstanceServerListButtons all = InstanceServerListButtons.defaults;
      for (final InstanceServerListButtons other in <InstanceServerListButtons>[
        const InstanceServerListButtons(favorites: false),
        const InstanceServerListButtons(explore: false),
        const InstanceServerListButtons(createJoin: false),
        const InstanceServerListButtons(download: false),
        const InstanceServerListButtons(help: false),
      ]) {
        expect(other, isNot(all));
      }
      expect(
        InstanceServerListButtons.fromJson(const <String, dynamic>{
          'help': false,
        }),
        const InstanceServerListButtons(help: false),
      );
      expect(all, isNot(Object()));
    });
  });

  group('branding addresses', () {
    test('trim surrounding space and drop blank ones', () {
      final InstanceRuntimeConfig config = InstanceRuntimeConfig.fromWellKnown(
        _wellKnown(
          branding: <String, Object?>{
            'icon_url': '  https://chat.example/icon.png  ',
            'symbol_url': '   ',
            'logo_url': null,
            'wordmark_url': '',
            'theme_color': ' #5865F2 ',
          },
        ),
      );

      expect(config.iconUrl, 'https://chat.example/icon.png');
      expect(config.symbolUrl, isNull);
      expect(config.logoUrl, isNull);
      expect(config.wordmarkUrl, isNull);
      expect(config.themeColorHex, '#5865F2');
      expect(config.compactMarkUrl, 'https://chat.example/icon.png');
    });
  });
}
