import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/guild_commands/providers/guild_command_script_preview.dart';
import 'package:fluxer_dart/export.dart';

const Duration _typing = Duration(milliseconds: 500);

class _Server {
  final List<String> asked = <String>[];
  final List<int> runs = <int>[];
  Object? failWith;

  Future<GuildCommandPreviewResponseSchema> fetch({
    required String template,
    required String input,
    required List<String> counterNames,
    required int run,
  }) async {
    asked.add('$template|$input');
    runs.add(run);
    final Object? failure = failWith;
    if (failure != null) {
      throw failure as Exception;
    }
    return GuildCommandPreviewResponseSchema(
      content: 'filled: $template',
      issue: null,
    );
  }
}

void main() {
  test('one request for a burst of typing, with the last text', () {
    fakeAsync((FakeAsync async) {
      final _Server server = _Server();
      final GuildCommandScriptPreview preview = GuildCommandScriptPreview(
        server.fetch,
      );
      addTearDown(preview.dispose);

      for (final String text in <String>['{{ a', '{{ ab', '{{ abc }}']) {
        preview.update(template: text, input: '');
        async.elapse(const Duration(milliseconds: 100));
      }
      expect(server.asked, isEmpty);

      async.elapse(_typing);
      expect(server.asked, <String>['{{ abc }}|']);
      expect(preview.result?.content, 'filled: {{ abc }}');
    });
  });

  test('sends nothing for the same text, or for no script', () {
    fakeAsync((FakeAsync async) {
      final _Server server = _Server();
      final GuildCommandScriptPreview preview = GuildCommandScriptPreview(
        server.fetch,
      );
      addTearDown(preview.dispose);

      preview.update(template: null, input: '');
      async.elapse(_typing);
      expect(server.asked, isEmpty);

      preview.update(template: '{{ a }}', input: 'x');
      async.elapse(_typing);
      preview.update(template: '{{ a }}', input: 'x');
      async.elapse(_typing);
      expect(server.asked, hasLength(1));
    });
  });

  test('asks again when a counter is named, so a script can read it', () {
    fakeAsync((FakeAsync async) {
      final _Server server = _Server();
      final GuildCommandScriptPreview preview = GuildCommandScriptPreview(
        server.fetch,
      );
      addTearDown(preview.dispose);

      preview.update(template: '{{ hugs }}', input: '');
      async.elapse(_typing);
      preview.update(
        template: '{{ hugs }}',
        input: '',
        counterNames: <String>['hugs'],
      );
      async.elapse(_typing);

      expect(server.asked, hasLength(2));
    });
  });

  test('counts up with each Run again, and starts over on an edit', () {
    fakeAsync((FakeAsync async) {
      final _Server server = _Server();
      final GuildCommandScriptPreview preview = GuildCommandScriptPreview(
        server.fetch,
      );
      addTearDown(preview.dispose);

      preview.update(template: '{{ hugs }}', input: '');
      async.elapse(_typing);
      preview
        ..runAgain()
        ..runAgain();
      async.flushMicrotasks();
      preview.update(template: '{{ hugs }}!', input: '');
      async.elapse(_typing);

      expect(server.runs, <int>[1, 2, 3, 1]);
    });
  });

  test('clears the preview when the text stops being a script', () {
    fakeAsync((FakeAsync async) {
      final _Server server = _Server();
      final GuildCommandScriptPreview preview = GuildCommandScriptPreview(
        server.fetch,
      );
      addTearDown(preview.dispose);

      preview.update(template: '{{ a }}', input: '');
      async.elapse(_typing);
      expect(preview.result, isNotNull);

      preview.update(template: null, input: '');
      expect(preview.result, isNull);
    });
  });

  test('a failed request keeps the last preview and is not retried', () {
    fakeAsync((FakeAsync async) {
      final _Server server = _Server();
      final GuildCommandScriptPreview preview = GuildCommandScriptPreview(
        server.fetch,
      );
      addTearDown(preview.dispose);

      preview.update(template: '{{ a }}', input: '');
      async.elapse(_typing);

      server.failWith = Exception('429');
      preview.update(template: '{{ b }}', input: '');
      async.elapse(const Duration(minutes: 1));
      expect(server.asked, hasLength(2));
      expect(preview.result?.content, 'filled: {{ a }}');

      server.failWith = null;
      preview.update(template: '{{ c }}', input: '');
      async.elapse(_typing);
      expect(server.asked, hasLength(3));
      expect(preview.result?.content, 'filled: {{ c }}');
    });
  });

  test('ignores an answer overtaken by a newer edit', () {
    fakeAsync((FakeAsync async) {
      final _Server server = _Server();
      Duration slowness = const Duration(seconds: 2);
      final GuildCommandScriptPreview preview = GuildCommandScriptPreview(({
        required String template,
        required String input,
        required List<String> counterNames,
        required int run,
      }) async {
        await Future<void>.delayed(slowness);
        return server.fetch(
          template: template,
          input: input,
          counterNames: counterNames,
          run: run,
        );
      });
      addTearDown(preview.dispose);

      preview.update(template: '{{ old }}', input: '');
      async.elapse(_typing);
      slowness = Duration.zero;
      preview.update(template: '{{ new }}', input: '');
      async.elapse(const Duration(seconds: 5));

      expect(preview.result?.content, 'filled: {{ new }}');
    });
  });

  test('runs the same preview again at once when asked', () {
    fakeAsync((FakeAsync async) {
      final _Server server = _Server();
      final GuildCommandScriptPreview preview = GuildCommandScriptPreview(
        server.fetch,
      );
      addTearDown(preview.dispose);

      preview.update(template: '{{ a }}', input: '');
      async.elapse(_typing);
      preview.runAgain();
      async.flushMicrotasks();

      expect(server.asked, hasLength(2));
    });
  });

  test('sends nothing after it is closed', () {
    fakeAsync((FakeAsync async) {
      final _Server server = _Server();
      GuildCommandScriptPreview(server.fetch)
        ..update(template: '{{ a }}', input: '')
        ..dispose();
      async.elapse(_typing);

      expect(server.asked, isEmpty);
    });
  });
}
