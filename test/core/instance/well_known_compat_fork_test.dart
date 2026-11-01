// Fork: tests the fork adds for lib/core/instance/well_known_compat.dart.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/instance/instance_config_snapshot.dart';
import 'package:fluxer_app/core/instance/well_known_compat.dart';

import '../../helpers/well_known_fixture.dart';

void main() {
  Map<String, dynamic> document() {
    final Object encoded = wellKnownFixture(
      media: 'https://chat.example/media',
      staticCdn: 'https://chat.example',
    ).toJson();
    return jsonDecode(jsonEncode(encoded)) as Map<String, dynamic>;
  }

  // tyne-chat/tyne#454: the server sends a list, and the SDK's type is one enum
  // value, so these threw and the app could not connect to any instance by name.
  group('hidden_built_in_guild_badges', () {
    for (final List<String> badges in <List<String>>[
      <String>[],
      <String>['verified', 'partnered'],
    ]) {
      test('a document with $badges parses', () {
        final Map<String, dynamic> json = document()
          ..['hidden_built_in_guild_badges'] = badges;

        expect(parseWellKnownFluxer(json).apiCodeVersion, 1);
        expect(InstanceConfigSnapshot.parseWellKnown(json).apiCodeVersion, 1);
      });
    }

    test('a document without the field parses', () {
      final Map<String, dynamic> json = document()
        ..remove('hidden_built_in_guild_badges');

      expect(parseWellKnownFluxer(json).apiCodeVersion, 1);
    });

    test('leaves the caller map as it was', () {
      final Map<String, dynamic> json = document()
        ..['hidden_built_in_guild_badges'] = <String>[];

      parseWellKnownFluxer(json);

      expect(json['hidden_built_in_guild_badges'], isEmpty);
    });
  });
}
