import 'dart:io';
import 'dart:isolate';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/imported_build.dart';
import 'zip_import.dart';

class _ImportRequest {
  const _ImportRequest({
    required this.port,
    required this.zipPath,
    required this.zipName,
    required this.stagingPath,
    required this.knownFingerprints,
  });

  final SendPort port;
  final String zipPath;
  final String zipName;
  final String stagingPath;
  final Set<String> knownFingerprints;
}

Future<void> _importWorker(_ImportRequest request) async {
  try {
    final result = await importZipFile(
      File(request.zipPath),
      request.zipName,
      Directory(request.stagingPath),
      knownFingerprints: request.knownFingerprints,
      onProgress: (done, total) =>
          request.port.send(<Object>['progress', done, total]),
    );
    request.port.send(<Object>['done', result.toMap()]);
  } on ZipImportException catch (error) {
    request.port.send(<Object>['error', error.error.name, error.detail]);
  } catch (error) {
    request.port.send(<Object>['error', ZipError.io.name, '$error']);
  }
}

class BuildArchiveService {
  static const _stagingPrefix = '.staging-';

  Isolate? _isolate;
  bool _cancelled = false;

  Future<Directory> _buildsDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    return Directory(p.join(root.path, 'Revive', 'Builds'));
  }

  /// Returns `null` when the user closes the file picker.
  Future<ImportedBuild?> pickAndImportZip({
    required List<ImportedBuild> existing,
    required void Function(double progress) onProgress,
  }) async {
    _cancelled = false;
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const <String>['zip'],
        withData: false,
      );
      if (picked == null || picked.files.isEmpty) return null;
      final file = picked.files.single;
      final path = file.path;
      if (path == null || path.isEmpty) {
        throw const ZipImportException(ZipError.io, 'no readable path');
      }
      return await _import(path, file.name, existing, onProgress);
    } finally {
      // file_picker copies the ZIP into the app cache: free that space.
      try {
        await FilePicker.platform.clearTemporaryFiles();
      } catch (_) {}
    }
  }

  void cancel() {
    _cancelled = true;
    _isolate?.kill(priority: Isolate.immediate);
  }

  Future<ImportedBuild> _import(
    String zipPath,
    String zipName,
    List<ImportedBuild> existing,
    void Function(double progress) onProgress,
  ) async {
    if (_cancelled) throw const ZipImportException(ZipError.cancelled);
    final builds = await _buildsDirectory();
    await builds.create(recursive: true);
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final staging = Directory(p.join(builds.path, '$_stagingPrefix$id'));
    try {
      final result = await _runWorker(
        zipPath,
        zipName,
        staging.path,
        <String>{
          for (final build in existing)
            if (build.fingerprint.isNotEmpty &&
                Directory(build.directory).existsSync())
              build.fingerprint,
        },
        onProgress,
      );

      var name = p
          .basenameWithoutExtension(zipName)
          .replaceAll(RegExp(r'[^A-Za-z0-9._ -]'), '_')
          .trim();
      // A name made only of dots would point outside the builds folder.
      if (name.isEmpty || name.startsWith('.')) name = 'Build-$id';
      var target = Directory(p.join(builds.path, name));
      for (var copy = 2; await target.exists(); copy++) {
        target = Directory(p.join(builds.path, '$name ($copy)'));
      }
      await staging.rename(target.path);

      return ImportedBuild(
        id: id,
        name: p.basename(target.path),
        version: result.version,
        description: '',
        trailerUrl: '',
        directory: target.path,
        fileCount: result.fileCount,
        totalBytes: result.totalBytes,
        hasEngine: result.hasEngine,
        hasFortniteGame: result.hasFortniteGame,
        fingerprint: result.fingerprint,
      );
    } finally {
      if (await staging.exists()) await staging.delete(recursive: true);
    }
  }

  Future<ZipImportResult> _runWorker(
    String zipPath,
    String zipName,
    String stagingPath,
    Set<String> knownFingerprints,
    void Function(double progress) onProgress,
  ) async {
    final port = ReceivePort();
    ZipImportResult? result;
    ZipImportException? failure;
    try {
      _isolate = await Isolate.spawn(
        _importWorker,
        _ImportRequest(
          port: port.sendPort,
          zipPath: zipPath,
          zipName: zipName,
          stagingPath: stagingPath,
          knownFingerprints: knownFingerprints,
        ),
        onError: port.sendPort,
        onExit: port.sendPort,
      );
      if (_cancelled) _isolate?.kill(priority: Isolate.immediate);
      await for (final message in port) {
        if (message == null) break; // The isolate exited.
        final data = message as List<Object?>;
        switch (data.first) {
          case 'progress':
            final done = data[1]! as int;
            final total = data[2]! as int;
            onProgress(total == 0 ? 0 : done / total);
          case 'done':
            result = ZipImportResult.fromMap(data[1]! as Map<Object?, Object?>);
          case 'error':
            failure = ZipImportException(
              ZipError.values.byName(data[1]! as String),
              data[2]! as String,
            );
          default:
            failure = ZipImportException(ZipError.io, '${data.first}');
        }
      }
    } finally {
      port.close();
      _isolate = null;
    }
    if (_cancelled) throw const ZipImportException(ZipError.cancelled);
    if (failure != null) throw failure;
    final value = result;
    if (value == null) {
      throw const ZipImportException(ZipError.io, 'import interrupted');
    }
    return value;
  }

  /// Removes half-extracted folders left behind if the app was killed.
  Future<void> cleanIncompleteImports() async {
    final builds = await _buildsDirectory();
    if (!await builds.exists()) return;
    await for (final entity in builds.list(followLinks: false)) {
      if (entity is Directory &&
          p.basename(entity.path).startsWith(_stagingPrefix)) {
        await entity.delete(recursive: true);
      }
    }
  }

  Future<void> deleteBuild(ImportedBuild build) async {
    final builds = await _buildsDirectory();
    // Never delete anything outside the app's own builds folder.
    if (!p.isWithin(builds.path, build.directory)) return;
    final directory = Directory(build.directory);
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}
