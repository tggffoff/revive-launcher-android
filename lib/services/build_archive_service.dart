import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/imported_build.dart';

class BuildArchiveService {
  static const maxArchiveBytes = 400 * 1024 * 1024;
  static const maxExtractedBytes = 2 * 1024 * 1024 * 1024;
  static const maxEntries = 100000;

  Future<ImportedBuild?> pickAndImportZip() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final picked = result.files.single;
    if (picked.size > maxArchiveBytes) {
      throw Exception('Archive trop volumineuse pour cet import : limite actuelle de 400 Mo.');
    }
    final bytes = picked.bytes;
    if (bytes == null) throw Exception('Android n’a pas pu lire le fichier ZIP sélectionné.');

    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    if (archive.length > maxEntries) {
      throw Exception('Archive refusée : elle contient trop de fichiers.');
    }

    final root = await getApplicationDocumentsDirectory();
    final safeName = p.basenameWithoutExtension(picked.name)
        .replaceAll(RegExp(r'[^A-Za-z0-9._ -]'), '_').trim();
    final folder = safeName.isEmpty ? 'Build-${DateTime.now().millisecondsSinceEpoch}' : safeName;
    final target = Directory(p.join(root.path, 'Revive', 'Builds', folder));
    if (await target.exists()) {
      throw Exception('Ce build existe déjà. Renomme le ZIP avant de le réimporter.');
    }

    var count = 0;
    var total = 0;
    var hasEngine = false;
    var hasGame = false;
    final versionSource = <String>[picked.name];
    await target.create(recursive: true);
    try {
      for (final entry in archive) {
        if (!entry.isFile) continue;
        final normalized = entry.name.replaceAll('\\\\', '/');
        final parts = normalized.split('/');
        if (normalized.startsWith('/') ||
            RegExp(r'^[A-Za-z]:').hasMatch(normalized) ||
            parts.any((part) => part == '..' || part.isEmpty)) {
          throw Exception('Archive refusée : chemin de fichier non sécurisé.');
        }
        final lower = parts.map((part) => part.toLowerCase()).toList();
        if (lower.contains('engine')) hasEngine = true;
        if (lower.contains('fortnitegame')) hasGame = true;
        if (versionSource.length < 100) versionSource.add(normalized);

        final content = entry.content as List<int>;
        total += content.length;
        if (total > maxExtractedBytes) {
          throw Exception('Archive refusée : contenu extrait supérieur à 2 Go.');
        }
        final output = File(p.joinAll([target.path, ...parts]));
        await output.parent.create(recursive: true);
        await output.writeAsBytes(content, flush: false);
        count++;
      }
      if (count == 0) throw Exception('Le ZIP ne contient aucun fichier.');
      final match = RegExp(
        r'(?:^|[^0-9])(?:v|build[ _-]?)?(\d{1,2}\.\d{1,2}(?:\.\d{1,2})?)(?:[^0-9]|$)',
        caseSensitive: false,
      ).firstMatch(versionSource.join(' '));
      final version = match?.group(1) ?? 'Version à identifier';
      return ImportedBuild(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: folder,
        version: version,
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
    }
  }

  Future<void> deleteBuild(ImportedBuild build) async {
    final directory = Directory(build.directory);
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}
