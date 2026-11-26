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
  });

  final String id;
  final String name;
  final String version;
  final String description;
  final String trailerUrl;
  final String directory;
  final int fileCount;
  final int totalBytes;
  final bool hasEngine;
  final bool hasFortniteGame;

  String get sizeLabel => totalBytes >= 1024 * 1024 * 1024
      ? '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} Go'
      : '${(totalBytes / (1024 * 1024)).toStringAsFixed(0)} Mo';

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'version': version, 'description': description,
    'trailerUrl': trailerUrl, 'directory': directory, 'fileCount': fileCount,
    'totalBytes': totalBytes, 'hasEngine': hasEngine, 'hasFortniteGame': hasFortniteGame,
  };

  factory ImportedBuild.fromJson(Map<String, dynamic> json) => ImportedBuild(
    id: json['id'] as String,
    name: json['name'] as String,
    version: json['version'] as String? ?? 'Version inconnue',
    description: json['description'] as String? ?? '',
    trailerUrl: json['trailerUrl'] as String? ?? '',
    directory: json['directory'] as String,
    fileCount: json['fileCount'] as int? ?? 0,
    totalBytes: json['totalBytes'] as int? ?? 0,
    hasEngine: json['hasEngine'] as bool? ?? false,
    hasFortniteGame: json['hasFortniteGame'] as bool? ?? false,
  );

  ImportedBuild copyWith({String? name, String? version, String? description, String? trailerUrl}) => ImportedBuild(
    id: id, name: name ?? this.name, version: version ?? this.version,
    description: description ?? this.description, trailerUrl: trailerUrl ?? this.trailerUrl,
    directory: directory, fileCount: fileCount, totalBytes: totalBytes,
    hasEngine: hasEngine, hasFortniteGame: hasFortniteGame,
  );
}
