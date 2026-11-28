/// Streaming ZIP import. Files are read, inflated and written chunk by chunk, so
/// multi-gigabyte archives never have to fit in memory. Pure Dart (`dart:io`)
/// so it can run in a background isolate and be unit tested.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

enum ZipError {
  notZip,
  corrupted,
  unsafePath,
  encrypted,
  unsupported,
  symlink,
  empty,
  tooLarge,
  notABuild,
  duplicate,
  noSpace,
  cancelled,
  io,
}

class ZipImportException implements Exception {
  const ZipImportException(this.error, [this.detail = '']);

  final ZipError error;
  final String detail;

  @override
  String toString() => 'ZipImportException(${error.name}) $detail';
}

class ZipEntry {
  const ZipEntry({
    required this.name,
    required this.flags,
    required this.method,
    required this.crc32,
    required this.compressedSize,
    required this.size,
    required this.headerOffset,
    required this.isSymlink,
  });

  final String name;
  final int flags;
  final int method;
  final int crc32;
  final int compressedSize;
  final int size;
  final int headerOffset;
  final bool isSymlink;

  bool get isDirectory => name.endsWith('/') || name.endsWith('\\');
}

class ZipImportResult {
  const ZipImportResult({
    required this.version,
    required this.fileCount,
    required this.totalBytes,
    required this.hasEngine,
    required this.hasFortniteGame,
    required this.fingerprint,
  });

  final String version;
  final int fileCount;
  final int totalBytes;
  final bool hasEngine;
  final bool hasFortniteGame;
  final String fingerprint;

  Map<String, Object> toMap() => <String, Object>{
        'version': version,
        'fileCount': fileCount,
        'totalBytes': totalBytes,
        'hasEngine': hasEngine,
        'hasFortniteGame': hasFortniteGame,
        'fingerprint': fingerprint,
      };

  factory ZipImportResult.fromMap(Map<Object?, Object?> map) => ZipImportResult(
        version: map['version']! as String,
        fileCount: map['fileCount']! as int,
        totalBytes: map['totalBytes']! as int,
        hasEngine: map['hasEngine']! as bool,
        hasFortniteGame: map['hasFortniteGame']! as bool,
        fingerprint: map['fingerprint']! as String,
      );
}

const maxZipEntries = 200000;
const maxExtractedBytes = 200 * 1024 * 1024 * 1024;
const _maxDirectoryBytes = 256 * 1024 * 1024;

Future<Uint8List> _readAt(RandomAccessFile file, int offset, int length) async {
  await file.setPosition(offset);
  final bytes = await file.read(length);
  if (bytes.length != length) {
    throw const ZipImportException(ZipError.corrupted, 'unexpected end');
  }
  return bytes;
}

/// Reads the central directory, including ZIP64 archives.
Future<List<ZipEntry>> readZipEntries(File zip) async {
  final file = await zip.open();
  try {
    final length = await file.length();
    if (length < 22) throw const ZipImportException(ZipError.notZip);
    final tailLength = min(length, 22 + 65535);
    final tail = await _readAt(file, length - tailLength, tailLength);
    final tailData = ByteData.sublistView(tail);
    var end = -1;
    for (var i = tail.length - 22; i >= 0; i--) {
      if (tailData.getUint32(i, Endian.little) == 0x06054b50) {
        end = i;
        break;
      }
    }
    if (end < 0) throw const ZipImportException(ZipError.notZip);

    var count = tailData.getUint16(end + 10, Endian.little);
    var directorySize = tailData.getUint32(end + 12, Endian.little);
    var directoryOffset = tailData.getUint32(end + 16, Endian.little);
    final endPosition = length - tailLength + end;

    if (count == 0xFFFF ||
        directorySize == 0xFFFFFFFF ||
        directoryOffset == 0xFFFFFFFF) {
      if (endPosition < 20) {
        throw const ZipImportException(ZipError.corrupted, 'zip64 locator');
      }
      final locator = ByteData.sublistView(
        await _readAt(file, endPosition - 20, 20),
      );
      if (locator.getUint32(0, Endian.little) != 0x07064b50) {
        throw const ZipImportException(ZipError.corrupted, 'zip64 locator');
      }
      final recordOffset = locator.getUint64(8, Endian.little);
      if (recordOffset < 0 || recordOffset + 56 > length) {
        throw const ZipImportException(ZipError.corrupted, 'zip64 offset');
      }
      final record = ByteData.sublistView(
        await _readAt(file, recordOffset, 56),
      );
      if (record.getUint32(0, Endian.little) != 0x06064b50) {
        throw const ZipImportException(ZipError.corrupted, 'zip64 record');
      }
      count = record.getUint64(32, Endian.little);
      directorySize = record.getUint64(40, Endian.little);
      directoryOffset = record.getUint64(48, Endian.little);
    }

    if (count < 0 || count > maxZipEntries) {
      throw const ZipImportException(ZipError.tooLarge, 'entry count');
    }
    if (directorySize < 0 ||
        directorySize > _maxDirectoryBytes ||
        directoryOffset < 0 ||
        directoryOffset + directorySize > endPosition) {
      throw const ZipImportException(ZipError.corrupted, 'directory bounds');
    }

    final directory = await _readAt(file, directoryOffset, directorySize);
    final data = ByteData.sublistView(directory);
    final entries = <ZipEntry>[];
    var position = 0;
    for (var index = 0; index < count; index++) {
      if (position + 46 > directory.length ||
          data.getUint32(position, Endian.little) != 0x02014b50) {
        throw const ZipImportException(ZipError.corrupted, 'directory entry');
      }
      final madeBy = data.getUint16(position + 4, Endian.little);
      final flags = data.getUint16(position + 8, Endian.little);
      final method = data.getUint16(position + 10, Endian.little);
      final crc = data.getUint32(position + 16, Endian.little);
      var compressedSize = data.getUint32(position + 20, Endian.little);
      var size = data.getUint32(position + 24, Endian.little);
      final nameLength = data.getUint16(position + 28, Endian.little);
      final extraLength = data.getUint16(position + 30, Endian.little);
      final commentLength = data.getUint16(position + 32, Endian.little);
      final attributes = data.getUint32(position + 38, Endian.little);
      var headerOffset = data.getUint32(position + 42, Endian.little);
      final nameStart = position + 46;
      final next = nameStart + nameLength + extraLength + commentLength;
      if (next > directory.length) {
        throw const ZipImportException(ZipError.corrupted, 'entry bounds');
      }
      final name = utf8.decode(
        Uint8List.sublistView(directory, nameStart, nameStart + nameLength),
        allowMalformed: true,
      );

      var extra = nameStart + nameLength;
      final extraEnd = extra + extraLength;
      while (extra + 4 <= extraEnd) {
        final id = data.getUint16(extra, Endian.little);
        final fieldLength = data.getUint16(extra + 2, Endian.little);
        var field = extra + 4;
        final fieldEnd = field + fieldLength;
        if (fieldEnd > extraEnd) break;
        if (id == 1) {
          int nextValue() {
            if (field + 8 > fieldEnd) {
              throw const ZipImportException(ZipError.corrupted, 'zip64 extra');
            }
            final value = data.getUint64(field, Endian.little);
            field += 8;
            return value;
          }

          if (size == 0xFFFFFFFF) size = nextValue();
          if (compressedSize == 0xFFFFFFFF) compressedSize = nextValue();
          if (headerOffset == 0xFFFFFFFF) headerOffset = nextValue();
        }
        extra = fieldEnd;
      }

      if (size < 0 || compressedSize < 0 || headerOffset < 0) {
        throw const ZipImportException(ZipError.corrupted, 'negative size');
      }
      entries.add(
        ZipEntry(
          name: name,
          flags: flags,
          method: method,
          crc32: crc,
          compressedSize: compressedSize,
          size: size,
          headerOffset: headerOffset,
          isSymlink: (madeBy >> 8) == 3 &&
              ((attributes >> 16) & 0xF000) == 0xA000,
        ),
      );
      position = next;
    }
    return entries;
  } finally {
    await file.close();
  }
}

/// Splits an entry name into safe relative segments ("Zip Slip" protection).
List<String> safeSegments(String name) {
  final normalized = name.replaceAll('\\', '/');
  if (normalized.startsWith('/') ||
      normalized.contains('\u0000') ||
      RegExp(r'^[A-Za-z]:').hasMatch(normalized)) {
    throw ZipImportException(ZipError.unsafePath, name);
  }
  final parts = normalized.split('/');
  if (parts.isNotEmpty && parts.last.isEmpty) parts.removeLast();
  parts.removeWhere((part) => part == '.');
  if (parts.isEmpty || parts.any((part) => part.isEmpty || part == '..')) {
    throw ZipImportException(ZipError.unsafePath, name);
  }
  return parts;
}

final _versionPattern = RegExp(
  r'(?<![\d.])(\d{1,2}\.\d{1,2}(?:\.\d{1,2})?)(?!\.?\d)',
);

/// Best-effort version guess from the ZIP name, then the top folders.
String detectVersion(String zipName, Iterable<List<String>> paths) {
  final stem = zipName.toLowerCase().endsWith('.zip')
      ? zipName.substring(0, zipName.length - 4)
      : zipName;
  final fromName = _versionPattern.firstMatch(stem);
  if (fromName != null) return fromName.group(1)!;
  for (final path in paths) {
    // Only the two first folders: deeper ones hold third-party library versions.
    for (var i = 0; i < path.length - 1 && i < 2; i++) {
      final match = _versionPattern.firstMatch(path[i]);
      if (match != null) return match.group(1)!;
    }
  }
  return '';
}

bool _isBuildMarker(String fileName) {
  final lower = fileName.toLowerCase();
  return lower.endsWith('.pak') ||
      lower.endsWith('.ucas') ||
      lower.endsWith('.utoc') ||
      lower.endsWith('.obb') ||
      lower.endsWith('.apk') ||
      lower == 'libue4.so' ||
      lower == 'libunreal.so';
}

final Uint32List _crcTable = _makeCrcTable();

Uint32List _makeCrcTable() {
  final table = Uint32List(256);
  for (var n = 0; n < 256; n++) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
    table[n] = c;
  }
  return table;
}

/// Incremental CRC-32. Start with `0`.
int updateCrc32(int crc, List<int> bytes) {
  var c = crc ^ 0xFFFFFFFF;
  for (var i = 0; i < bytes.length; i++) {
    c = _crcTable[(c ^ bytes[i]) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}

const _versionMarker = '++Fortnite+Release-';
final _releaseNumber = RegExp(r'^\d{1,2}\.\d{1,2}(\.\d{1,2})?$');

/// Finds `++Fortnite+Release-X.Y`, written by Unreal inside the build, in a byte
/// stream. Handles ASCII and UTF-16LE and matches split between two chunks.
class VersionScanner {
  /// Longer than the marker plus its number, even in UTF-16.
  static const _overlap = 64;

  String version = '';
  List<int> _tail = const <int>[];

  void add(List<int> chunk) {
    if (version.isNotEmpty || chunk.isEmpty) return;
    final head = chunk.length > _overlap ? chunk.sublist(0, _overlap) : chunk;
    final joint = <int>[..._tail, ...head];
    _search(joint, false);
    _search(chunk, false);
    final rest = chunk.length >= _overlap ? chunk : joint;
    _tail = rest.length > _overlap
        ? rest.sublist(rest.length - _overlap)
        : List<int>.of(rest);
  }

  /// Call at the end of the stream: the number may be the very last bytes.
  void finish() {
    _search(_tail, true);
    _tail = const <int>[];
  }

  void _search(List<int> data, bool atEnd) {
    for (var i = 0; i < data.length && version.isEmpty; i++) {
      if (data[i] != 0x2B) continue; // '+'
      final ascii = _match(data, i, 1, atEnd);
      version = ascii.isNotEmpty ? ascii : _match(data, i, 2, atEnd);
    }
  }

  String _match(List<int> data, int start, int step, bool atEnd) {
    // -1: past the buffer, -2: not an UTF-16 ASCII character.
    int at(int index) {
      final position = start + index * step;
      if (position >= data.length) return -1;
      if (step == 2 &&
          position + 1 < data.length &&
          data[position + 1] != 0) {
        return -2;
      }
      return data[position];
    }

    for (var i = 0; i < _versionMarker.length; i++) {
      if (at(i) != _versionMarker.codeUnitAt(i)) return '';
    }
    final digits = StringBuffer();
    var index = _versionMarker.length;
    var next = at(index);
    while (digits.length < 9 &&
        (next == 0x2E || (next >= 0x30 && next <= 0x39))) {
      digits.writeCharCode(next);
      index++;
      next = at(index);
    }
    // The number may continue in the next chunk.
    if (next == -1 && !atEnd) return '';
    final text = digits.toString();
    return _releaseNumber.hasMatch(text) ? text : '';
  }
}

/// Game data is compressed or encrypted: no version to read there.
final _opaqueFile = RegExp(
  r'\.(pak|ucas|utoc|sig|obb|apk|zip|mp4|bik|png|jpg)$',
);

/// Decoded content of one entry.
Future<Stream<List<int>>> _openEntry(
  File zip,
  RandomAccessFile source,
  int zipLength,
  ZipEntry entry,
) async {
  if (entry.headerOffset + 30 > zipLength) {
    throw ZipImportException(ZipError.corrupted, entry.name);
  }
  final header = ByteData.sublistView(
    await _readAt(source, entry.headerOffset, 30),
  );
  if (header.getUint32(0, Endian.little) != 0x04034b50) {
    throw ZipImportException(ZipError.corrupted, entry.name);
  }
  final start = entry.headerOffset +
      30 +
      header.getUint16(26, Endian.little) +
      header.getUint16(28, Endian.little);
  if (start + entry.compressedSize > zipLength) {
    throw ZipImportException(ZipError.corrupted, entry.name);
  }
  if (entry.compressedSize == 0) return const Stream<List<int>>.empty();
  final raw =
      zip.openRead(start, start + entry.compressedSize).cast<List<int>>();
  return entry.method == 8 ? raw.transform(ZLibDecoder(raw: true)) : raw;
}

/// An APK is itself a ZIP: look in its manifest, then in the game library.
Future<String> _versionInsideApk(File apk) async {
  RandomAccessFile? source;
  try {
    final entries = await readZipEntries(apk);
    final candidates = <ZipEntry>[
      ...entries.where((entry) => entry.name == 'AndroidManifest.xml'),
      ...entries.where(
        (entry) =>
            entry.name.endsWith('/libUE4.so') ||
            entry.name.endsWith('/libUnreal.so'),
      ),
    ];
    source = await apk.open();
    final length = await source.length();
    for (final entry in candidates) {
      if (entry.method != 0 && entry.method != 8) continue;
      final scanner = VersionScanner();
      var read = 0;
      await for (final chunk
          in await _openEntry(apk, source, length, entry)) {
        read += chunk.length;
        if (read > entry.size) break;
        scanner.add(chunk);
        if (scanner.version.isNotEmpty) break;
      }
      scanner.finish();
      if (scanner.version.isNotEmpty) return scanner.version;
    }
  } catch (_) {
    // An unreadable inner APK must not fail the whole import.
  } finally {
    await source?.close();
  }
  return '';
}

class _PlannedFile {
  const _PlannedFile(this.entry, this.segments);

  final ZipEntry entry;
  final List<String> segments;
}

/// Validates the whole archive first, then extracts it into [target].
/// [target] should be a temporary folder: the caller renames it on success and
/// deletes it on failure.
Future<ZipImportResult> importZipFile(
  File zip,
  String zipName,
  Directory target, {
  Set<String> knownFingerprints = const <String>{},
  void Function(int done, int total)? onProgress,
}) async {
  final entries = await readZipEntries(zip);
  final files = <_PlannedFile>[];
  final seen = <String>{};
  var total = 0;
  var hasEngine = false;
  var hasFortniteGame = false;
  var hasMarker = false;

  for (final entry in entries) {
    final segments = safeSegments(entry.name);
    if (entry.isSymlink) {
      throw ZipImportException(ZipError.symlink, entry.name);
    }
    if (entry.isDirectory) continue;
    if (segments.first == '__MACOSX' || segments.last == '.DS_Store') continue;
    if ((entry.flags & 1) != 0) {
      throw ZipImportException(ZipError.encrypted, entry.name);
    }
    if (entry.method != 0 && entry.method != 8) {
      throw ZipImportException(ZipError.unsupported, 'method ${entry.method}');
    }
    if (!seen.add(segments.join('/'))) {
      throw ZipImportException(ZipError.corrupted, 'duplicate ${entry.name}');
    }
    total += entry.size;
    if (entry.size > maxExtractedBytes || total > maxExtractedBytes) {
      throw const ZipImportException(ZipError.tooLarge);
    }
    for (var i = 0; i < segments.length - 1; i++) {
      final folder = segments[i].toLowerCase();
      if (folder == 'engine') hasEngine = true;
      if (folder == 'fortnitegame') hasFortniteGame = true;
    }
    if (_isBuildMarker(segments.last)) hasMarker = true;
    files.add(_PlannedFile(entry, segments));
  }

  if (files.isEmpty) throw const ZipImportException(ZipError.empty);
  if (!hasEngine && !hasFortniteGame && !hasMarker) {
    throw const ZipImportException(ZipError.notABuild);
  }

  final signature = files
      .map((file) => '${file.entry.size}:${file.entry.crc32}')
      .toList()
    ..sort();
  final fingerprint = '${files.length}-$total-'
      '${updateCrc32(0, utf8.encode(signature.join('|')))}';
  if (knownFingerprints.contains(fingerprint)) {
    throw const ZipImportException(ZipError.duplicate);
  }

  var embeddedVersion = '';
  final source = await zip.open();
  try {
    final zipLength = await source.length();
    var done = 0;
    var reported = 0;
    await target.create(recursive: true);
    for (final planned in files) {
      final entry = planned.entry;
      final output = File('${target.path}/${planned.segments.join('/')}');
      await output.parent.create(recursive: true);
      final sink = await output.open(mode: FileMode.write);
      var written = 0;
      var crc = 0;
      final scanner = embeddedVersion.isEmpty &&
              !_opaqueFile.hasMatch(planned.segments.last.toLowerCase())
          ? VersionScanner()
          : null;
      try {
        final stream = await _openEntry(zip, source, zipLength, entry);
        await for (final chunk in stream) {
          written += chunk.length;
          if (written > entry.size) {
            throw ZipImportException(ZipError.corrupted, entry.name);
          }
          crc = updateCrc32(crc, chunk);
          scanner?.add(chunk);
          await sink.writeFrom(chunk);
          done += chunk.length;
          if (done - reported >= 4 * 1024 * 1024) {
            reported = done;
            onProgress?.call(done, total);
          }
        }
      } on FormatException {
        throw ZipImportException(ZipError.corrupted, entry.name);
      } finally {
        await sink.close();
      }
      if (written != entry.size || crc != entry.crc32) {
        throw ZipImportException(ZipError.corrupted, entry.name);
      }
      if (scanner != null) {
        scanner.finish();
        embeddedVersion = scanner.version;
      }
    }
    for (final planned in files) {
      if (embeddedVersion.isNotEmpty) break;
      if (planned.segments.last.toLowerCase().endsWith('.apk')) {
        embeddedVersion = await _versionInsideApk(
          File('${target.path}/${planned.segments.join('/')}'),
        );
      }
    }
    onProgress?.call(total, total);
  } on FileSystemException catch (error) {
    // 28 = ENOSPC.
    throw ZipImportException(
      error.osError?.errorCode == 28 ? ZipError.noSpace : ZipError.io,
      error.message,
    );
  } finally {
    await source.close();
  }

  return ZipImportResult(
    // The version written inside the build wins over file and folder names.
    version: embeddedVersion.isNotEmpty
        ? embeddedVersion
        : detectVersion(zipName, files.map((file) => file.segments)),
    fileCount: files.length,
    totalBytes: total,
    hasEngine: hasEngine,
    hasFortniteGame: hasFortniteGame,
    fingerprint: fingerprint,
  );
}
