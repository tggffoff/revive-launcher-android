class ImportedBuild {
  const ImportedBuild({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    required this.trailerUrl,
    required this.directory,
    required this.fileCount,
    required this.totalBytes,
    required this.hasEngine,
    required this.hasFortniteGame,
    this.fingerprint = '',
  });

  final String id;
  final String name;

  /// Empty when it could not be detected.
  final String version;
  final String description;
  final String trailerUrl;
  final String directory;
  final int fileCount;
  final int totalBytes;
  final bool hasEngine;
  final bool hasFortniteGame;

  /// Content signature used to refuse importing the same build twice.
  final String fingerprint;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'version': version,
        'description': description,
        'trailerUrl': trailerUrl,
        'directory': directory,
        'fileCount': fileCount,
        'totalBytes': totalBytes,
        'hasEngine': hasEngine,
        'hasFortniteGame': hasFortniteGame,
        'fingerprint': fingerprint,
      };

  factory ImportedBuild.fromJson(Map<String, dynamic> json) => ImportedBuild(
        id: json['id'] as String,
        name: json['name'] as String,
        version: json['version'] as String? ?? '',
        description: json['description'] as String? ?? '',
        trailerUrl: json['trailerUrl'] as String? ?? '',
        directory: json['directory'] as String,
        fileCount: json['fileCount'] as int? ?? 0,
        totalBytes: json['totalBytes'] as int? ?? 0,
        hasEngine: json['hasEngine'] as bool? ?? false,
        hasFortniteGame: json['hasFortniteGame'] as bool? ?? false,
        fingerprint: json['fingerprint'] as String? ?? '',
      );

  ImportedBuild copyWith({
    String? name,
    String? version,
    String? description,
    String? trailerUrl,
  }) =>
      ImportedBuild(
        id: id,
        name: name ?? this.name,
        version: version ?? this.version,
        description: description ?? this.description,
        trailerUrl: trailerUrl ?? this.trailerUrl,
        directory: directory,
        fileCount: fileCount,
        totalBytes: totalBytes,
        hasEngine: hasEngine,
        hasFortniteGame: hasFortniteGame,
        fingerprint: fingerprint,
      );
}

String formatBytes(int bytes, String language) {
  final french = language == 'fr';
  const mega = 1024 * 1024;
  const giga = 1024 * mega;
  if (bytes >= giga) {
    return '${(bytes / giga).toStringAsFixed(1)} ${french ? 'Go' : 'GB'}';
  }
  return '${(bytes / mega).toStringAsFixed(0)} ${french ? 'Mo' : 'MB'}';
}
