import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/services/composer_autocomplete_trigger.dart';

// Fork: built-in names carry their slash, so `//` used to search for `/` and
// list every command (tyne-chat/tyne#278).
void main() {
  group('command trigger', () {
    for (final String text in <String>['/', '/h', '/hug', '  /hug']) {
      test('opens the list for "$text"', () {
        expect(
          ComposerAutocompleteTrigger.detect(text)?.kind,
          ComposerAutocompleteTriggerKind.command,
        );
      });
    }

    test('searches for the text after the slash', () {
      expect(ComposerAutocompleteTrigger.detect('/hu')?.matchedText, 'hu');
    });

    for (final String text in <String>[
      '//',
      '///',
      '//hug',
      '/a/b',
      '/usr/bin',
      '  //',
    ]) {
      test('leaves "$text" as ordinary text', () {
        expect(ComposerAutocompleteTrigger.detect(text), isNull);
      });
    }

    test('still finds a mention after two slashes', () {
      expect(
        ComposerAutocompleteTrigger.detect('// ask @ali')?.kind,
        ComposerAutocompleteTriggerKind.mention,
      );
    });

    test('leaves the command arguments alone', () {
      expect(
        ComposerAutocompleteTrigger.detect('/kick ali')?.kind,
        ComposerAutocompleteTriggerKind.commandArg,
      );
    });
  });
}
