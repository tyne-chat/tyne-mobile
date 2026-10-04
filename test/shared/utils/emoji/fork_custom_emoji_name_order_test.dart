// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/shared/utils/emoji/fork_custom_emoji_name_order.dart';

void main() {
  int byName(String left, String right) =>
      compareCustomEmojiNames(left, '1', right, '1').sign;

  // Each expectation matches the web app's compareEmojisByName, that is
  // localeCompare(..., {numeric: true, sensitivity: 'base'}), checked in Node.
  test('compares names as the web app does', () {
    expect(byName('blob_2', 'blob_10'), -1);
    expect(byName('a_b', 'a1'), -1);
    expect(byName('a1', 'ab'), -1);
    expect(byName('Apple', 'banana'), -1);
    expect(byName('star', 'star2'), -1);
    expect(byName('x9', 'x_'), 1);
    expect(byName('Z', 'a'), 1);
    expect(byName('blob10b', 'blob10a'), 1);
    expect(byName('star', 'Star'), 0);
    expect(byName('e01', 'e1'), 0);
  });

  test('lists emojis whose names differ only by case newest first', () {
    expect(
      compareCustomEmojiNames(
        'star',
        '1500000000000000001',
        'Star',
        '1500000000000000002',
      ),
      greaterThan(0),
    );
    expect(
      compareCustomEmojiNames(
        'Star',
        '1500000000000000002',
        'star',
        '1500000000000000001',
      ),
      lessThan(0),
    );
  });

  test(
    'compares ids as numbers: a 19-digit id is newer than an 18-digit one',
    () {
      expect(
        compareCustomEmojiNames(
          'star',
          '999999999999999999',
          'star',
          '1000000000000000000',
        ),
        greaterThan(0),
      );
    },
  );
}
