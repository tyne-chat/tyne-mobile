import 'package:drift/drift.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/settings/domain/default_web_browser.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'default_apps_preferences_provider.g.dart';

@Riverpod(keepAlive: true)
class DefaultAppsPreferences extends _$DefaultAppsPreferences {
  String? _userId;
  int _forkBuildEpoch = 0;

  @override
  DefaultWebBrowser build() {
    // Fork: reset instance fields on rebuild so stale load() completions do not
    // overwrite fresh state (tyne-chat/tyne#946).
    _forkResetForBuild();
    return DefaultWebBrowser.inApp;
  }

  void _forkResetForBuild() {
    _forkBuildEpoch += 1;
    _userId = null;
  }

  Future<void> load(String userId) async {
    _userId = userId;
    final int epoch = _forkBuildEpoch;
    final db = ref.read(fluxerDatabaseProvider);
    final prefs = await db.userPreferencesDao.getPreferences(userId);
    if (!ref.mounted || epoch != _forkBuildEpoch || _userId != userId) {
      return;
    }
    if (prefs == null) {
      return;
    }
    final DefaultWebBrowser browser = DefaultWebBrowser.resolveStored(
      prefs.defaultWebBrowser,
    );
    if (browser == state) {
      return;
    }
    state = browser;
    if (browser.name != prefs.defaultWebBrowser) {
      await _persist();
    }
  }

  Future<void> setDefaultWebBrowser(DefaultWebBrowser value) async {
    if (value == state) {
      return;
    }
    state = value;
    await _persist();
  }

  Future<void> _persist() async {
    final userId = _userId;
    if (userId == null) {
      return;
    }
    final db = ref.read(fluxerDatabaseProvider);
    await db.userPreferencesDao.savePreferences(
      UserPreferencesTableCompanion(
        userId: Value(userId),
        defaultWebBrowser: Value(state.name),
      ),
    );
  }
}
