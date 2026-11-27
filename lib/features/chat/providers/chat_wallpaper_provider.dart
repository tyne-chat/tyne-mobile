import 'package:drift/drift.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/chat/data/chat_wallpaper_file_store.dart';
import 'package:fluxer_app/features/chat/wallpaper/chat_wallpaper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_wallpaper_provider.g.dart';

@Riverpod(keepAlive: true)
class ChatWallpaper extends _$ChatWallpaper {
  String? _userId;
  int _forkBuildEpoch = 0;
  final ChatWallpaperFileStore _files = const ChatWallpaperFileStore();

  @override
  ChatWallpaperSnapshot build() {
    // Fork: reset instance fields on rebuild so stale load() completions do not
    // overwrite fresh state (tyne-chat/tyne#946).
    _forkResetForBuild();
    return const ChatWallpaperSnapshot();
  }

  void _forkResetForBuild() {
    _forkBuildEpoch += 1;
    _userId = null;
  }

  Future<void> load(String userId) async {
    _userId = userId;
    final int epoch = _forkBuildEpoch;
    final FluxerDatabase db = ref.read(fluxerDatabaseProvider);
    final UserPreferencesTableData? prefs = await db.userPreferencesDao
        .getPreferences(userId);
    if (!ref.mounted || epoch != _forkBuildEpoch || _userId != userId) {
      return;
    }
    final ChatWallpaperState selection = chatWallpaperFromJson(
      prefs?.chatWallpaperJson,
    );
    final String? customPath = await _files.existingPathForUser(userId);
    if (!ref.mounted || epoch != _forkBuildEpoch || _userId != userId) {
      return;
    }
    ChatWallpaperState next = selection;
    if (selection.kind == ChatWallpaperKind.custom &&
        selection.luminance == null) {
      final double? luminance = await _files.sampleExistingLuminance(userId);
      if (!ref.mounted || epoch != _forkBuildEpoch || _userId != userId) {
        return;
      }
      if (luminance != null) {
        next = selection.copyWith(luminance: luminance);
      }
    }
    state = ChatWallpaperSnapshot(selection: next, customImagePath: customPath);
    if (next.luminance != selection.luminance) {
      await _persist();
    }
  }

  Future<void> setSelection(ChatWallpaperState selection) async {
    final ChatWallpaperState next = selection.kind == ChatWallpaperKind.custom
        ? selection
        : selection.copyWith(clearLuminance: true);
    state = state.copyWith(selection: next);
    await _persist();
  }

  void previewDim(double dim) {
    state = state.copyWith(
      selection: state.selection.copyWith(dim: clampChatWallpaperDim(dim)),
    );
  }

  Future<void> setDim(double dim) async {
    previewDim(dim);
    await _persist();
  }

  Future<bool> setCustomImage(Uint8List bytes) async {
    state = state.copyWith(isProcessingCustom: true);
    try {
      final ChatWallpaperEncodedImage? encoded =
          await prepareChatWallpaperBytes(bytes);
      if (encoded == null) {
        return false;
      }
      String? path;
      final String? userId = _userId;
      if (userId != null) {
        path = await _files.saveForUser(userId: userId, bytes: encoded.bytes);
        if (path == null) {
          return false;
        }
      }
      _setCustomSelection(
        encoded.bytes,
        path: path,
        luminance: encoded.luminance,
      );
      await _persist();
      return true;
    } finally {
      if (state.isProcessingCustom) {
        state = state.copyWith(isProcessingCustom: false);
      }
    }
  }

  void _setCustomSelection(
    Uint8List encoded, {
    required String? path,
    required double luminance,
  }) {
    state = state.copyWith(
      selection: state.selection.copyWith(
        kind: ChatWallpaperKind.custom,
        clearId: true,
        luminance: luminance,
      ),
      customImagePath: path,
      customImageBytes: encoded,
      isProcessingCustom: false,
      clearCustomImagePath: path == null,
    );
  }

  Future<void> _persist() async {
    final String? userId = _userId;
    if (userId == null) {
      return;
    }
    final FluxerDatabase db = ref.read(fluxerDatabaseProvider);
    await db.userPreferencesDao.savePreferences(
      UserPreferencesTableCompanion(
        userId: Value(userId),
        chatWallpaperJson: Value(chatWallpaperToJson(state.selection)),
      ),
    );
  }
}
