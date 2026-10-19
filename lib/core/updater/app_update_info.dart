class AppUpdateInfo {
  const AppUpdateInfo({
    required this.tagName,
    required this.version,
    required this.title,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.fileName,
    required this.fileSizeBytes,
    required this.sha256,
    this.buildNumber,
    this.publishedAt,
  });

  final String tagName;
  final String version;
  final int? buildNumber;
  final String title;
  final String releaseNotes;
  final String downloadUrl;
  final String fileName;
  final int fileSizeBytes;

  /// Lowercase hex SHA-256 of the APK, from the release asset's `digest`.
  final String sha256;
  final DateTime? publishedAt;

  String get formattedFileSize {
    if (fileSizeBytes <= 0) {
      return '';
    }
    final double mb = fileSizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}
