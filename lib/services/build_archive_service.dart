import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/imported_build.dart';

class BuildArchiveService {
  static const maxEntries = 100000;
  static const maxExtractedBytes = 20 * 1024 * 1024 * 1024;

  Future<ImportedBuild?> pickAndImportZip() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.single;
    final sourcePath = picked.path;
    if (sourcePath == null || sourcePath.isEmpty) {
      throw Exception('Android n’a pas fourni de chemin lisible pour ce ZIP.');
    }

    final root = await getApplicationDocumentsDirectory();
    final safeName = p.basenameWithoutExtension(picked.name)
        .replaceAll(RegExp(r'[^A-Za-z0-9._ -]'), '_')
        .trim();
    final folder = safeName.isEmpty
        ? 'Build-${DateTime.now().millisecondsSinceEpoch}'
        : safeName;
    final target = Directory(p.join(root.path, 'Revive', 'Builds', folder));
    if (await target.exists()) {
      throw Exception('Ce build existe déjà. Renomme le ZIP avant de le réimporter.');
    }

    final input = InputFileStream(sourcePath);
    try {
      final archive = ZipDecoder().decodeStream(input, verify: true);
      if (archive.length > maxEntries) {
        throw Exception('Archive refusée : elle contient trop de fichiers.');
      }

      var count = 0;
      var total = 0;
      var hasEngine = false;
      var hasGame = false;
      final versionSource = <String>[picked.name];

      for (final entry in archive) {
        if (entry.isSymbolicLink) {
          throw Exception('Archive refusée : les liens symboliques ne sont pas autorisés.');
        }
        if (!entry.isFile) continue;
        final normalized = entry.name.replaceAll('\\\\', '/');
        final parts = normalized.split('/');
        if (normalized.startsWith('/') ||
            RegExp(r'^[A-Za-z]:').hasMatch(normalized) ||
            parts.any((part) => part == '..' || part.isEmpty)) {
          throw Exception('Archive refusée : chemin de fichier non sécurisé.');
        }
        total += entry.size;
        if (total > maxExtractedBytes) {
          throw Exception('Archive refusée : le contenu extrait dépasse 20 Go.');
        }
        final lower = parts.map((part) => part.toLowerCase()).toList();
        if (lower.contains('engine')) hasEngine = true;
        if (lower.contains('fortnitegame')) hasGame = true;
        if (versionSource.length < 100) versionSource.add(normalized);
        count++;
      }

      if (count == 0) throw Exception('Le ZIP ne contient aucun fichier exploitable.');

      await target.create(recursive: true);
      await extractArchiveToDisk(archive, target.path);

      final match = RegExp(
        r'(?:^|[^0-9])(?:v|build[ _-]?)?(\\d{1,2}\\.\\d{1,2}(?:\\.\\d{1,2})?)(?:[^0-9]|$)',
        caseSensitive: false,
      ).firstMatch(versionSource.join(' '));

      return ImportedBuild(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: folder,
        version: match?.group(1) ?? 'Version à identifier',
        description: 'Build Fortnite Android importé dans Revive Launcher.',
        trailerUrl: '',
        directory: target.path,
        fileCount: count,
        totalBytes: total,
        hasEngine: hasEngine,
        hasFortniteGame: hasGame,
      );
    } catch (_) {
      if (await target.exists()) await target.delete(recursive: true);
      rethrow;
    } finally {
      await input.close();
    }
  }

  Future<void> deleteBuild(ImportedBuild build) async {
    final directory = Directory(build.directory);
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}
