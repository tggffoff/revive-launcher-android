import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImportedBuild {
  const ImportedBuild({
    required this.name,
    required this.version,
    required this.directory,
    required this.fileCount,
    required this.totalBytes,
    required this.hasEngine,
    required this.hasFortniteGame,
  });

  final String name;
  final String version;
  final String directory;
  final int fileCount;
  final int totalBytes;
  final bool hasEngine;
  final bool hasFortniteGame;

  String get sizeLabel => totalBytes >= 1024 * 1024 * 1024
      ? '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} Go'
      : '${(totalBytes / (1024 * 1024)).toStringAsFixed(0)} Mo';

  Map<String, dynamic> toJson() => {
        'name': name,
        'version': version,
        'directory': directory,
        'fileCount': fileCount,
        'totalBytes': totalBytes,
        'hasEngine': hasEngine,
        'hasFortniteGame': hasFortniteGame,
      };

  factory ImportedBuild.fromJson(Map<String, dynamic> json) => ImportedBuild(
        name: json['name'] as String,
        version: json['version'] as String? ?? 'Version à identifier',
        directory: json['directory'] as String,
        fileCount: json['fileCount'] as int? ?? 0,
        totalBytes: json['totalBytes'] as int? ?? 0,
        hasEngine: json['hasEngine'] as bool? ?? false,
        hasFortniteGame: json['hasFortniteGame'] as bool? ?? false,
      );
}

class BuildArchiveService {
  Future<ImportedBuild?> pickAndImportZip() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.single;
    final bytes = picked.bytes;
    if (bytes == null) throw Exception('Impossible de lire cette archive ZIP.');

    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    final docs = await getApplicationDocumentsDirectory();
    final safeName = p.basenameWithoutExtension(picked.name)
        .replaceAll(RegExp(r'[^A-Za-z0-9._ -]'), '_')
        .trim();
    final folderName = safeName.isEmpty
        ? 'Build-${DateTime.now().millisecondsSinceEpoch}'
        : safeName;
    final target = Directory(p.join(docs.path, 'Revive', 'Builds', folderName));
    if (await target.exists()) {
      throw Exception('Un build portant déjà ce nom est importé. Renomme le fichier ZIP puis réessaie.');
    }
    await target.create(recursive: true);

    var count = 0;
    var totalBytes = 0;
    var hasEngine = false;
    var hasFortniteGame = false;
    final versionSources = <String>[picked.name];

    try {
      for (final entry in archive) {
        if (!entry.isFile) continue;
        final normalized = entry.name.replaceAll('\\\\', '/');
        final segments = normalized.split('/');
        if (normalized.startsWith('/') ||
            RegExp(r'^[A-Za-z]:').hasMatch(normalized) ||
            segments.any((part) => part == '..' || part.isEmpty)) {
          throw Exception('Archive refusée : chemin de fichier non autorisé.');
        }

        final lower = segments.map((part) => part.toLowerCase()).toList();
        if (lower.contains('engine')) hasEngine = true;
        if (lower.contains('fortnitegame')) hasFortniteGame = true;
        if (versionSources.length < 120) versionSources.add(normalized);

        final outFile = File(p.join(target.path, ...segments));
        await outFile.parent.create(recursive: true);
        final raw = entry.content;
        final data = raw is List<int> ? raw : (raw as dynamic).toList().cast<int>();
        await outFile.writeAsBytes(data, flush: false);
        count++;
        totalBytes += data.length;
      }

      if (count == 0) {
        throw Exception('Cette archive ne contient aucun fichier exploitable.');
      }

      final versionMatch = RegExp(
        r'(?:Release[-_ ]?)?(\d{1,2}\.\d{1,2}(?:\.\d{1,2})?)',
        caseSensitive: false,
      ).firstMatch(versionSources.join(' '));

      return ImportedBuild(
        name: folderName,
        version: versionMatch?.group(1) ?? 'Version à identifier',
        directory: target.path,
        fileCount: count,
        totalBytes: totalBytes,
        hasEngine: hasEngine,
        hasFortniteGame: hasFortniteGame,
      );
    } catch (_) {
      if (await target.exists()) await target.delete(recursive: true);
      rethrow;
    }
  }

  Future<void> deleteBuild(ImportedBuild build) async {
    final directory = Directory(build.directory);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}
