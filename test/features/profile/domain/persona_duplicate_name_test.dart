// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/profile/domain/persona_duplicate_name.dart';

void main() {
  group('duplicatePersonaName', () {
    test('numbers the first copy 2', () {
      expect(
        duplicatePersonaName('Lyra', <String>['Lyra', 'Wren']),
        'Lyra (2)',
      );
    });

    test('takes the first free number', () {
      expect(
        duplicatePersonaName('Lyra', <String>['Lyra', 'Lyra (2)', 'Lyra (4)']),
        'Lyra (3)',
      );
    });

    test('counts a copy of a copy on from the persona it copied', () {
      expect(
        duplicatePersonaName('Lyra (2)', <String>['Lyra', 'Lyra (2)']),
        'Lyra (3)',
      );
    });

    test('keeps a number in brackets that is part of the name', () {
      expect(
        duplicatePersonaName('Lyra (2026)', <String>['Lyra (2026)']),
        'Lyra (2026) (2)',
      );
      expect(
        duplicatePersonaName('Agent(7)', <String>['Agent(7)']),
        'Agent(7) (2)',
      );
    });

    test('never gives the name itself, even when the list leaves it out', () {
      expect(duplicatePersonaName('Lyra', const <String>[]), 'Lyra (2)');
      expect(duplicatePersonaName('Lyra (2)', <String>['Lyra']), 'Lyra (3)');
    });

    test('compares names trimmed and ignoring case', () {
      expect(
        duplicatePersonaName(' Lyra ', <String>['lyra', 'LYRA (2) ']),
        'Lyra (3)',
      );
    });

    test('shortens a long name so the number fits the 100-character limit', () {
      final String long = 'x' * 100;
      final String copy = duplicatePersonaName(long, <String>[long]);
      expect(copy, '${'x' * 96} (2)');
      expect(copy.length, 100);
    });

    // The API and the name field count UTF-16 code units, where 🌙 is two.
    test('counts the limit as the API does, in UTF-16 code units', () {
      final String moons = '🌙' * 50;
      final String copy = duplicatePersonaName(moons, <String>[moons]);
      expect(copy, '${'🌙' * 48} (2)');
      expect(copy.length, 100);
    });

    test('never cuts a character made of several code points', () {
      const String flag = '🏳️‍🌈';
      expect(
        duplicatePersonaName('${'x' * 92}$flag', const <String>[]),
        '${'x' * 92} (2)',
      );
      const String skin = '👍🏽';
      expect(
        duplicatePersonaName('${'x' * 94}$skin', const <String>[]),
        '${'x' * 94} (2)',
      );
      expect(
        duplicatePersonaName('${'x' * 90}$skin', const <String>[]),
        '${'x' * 90}$skin (2)',
      );
    });
  });
}
