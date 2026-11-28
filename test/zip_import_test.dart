import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:revive_launcher/services/zip_import.dart';

void _u16(BytesBuilder out, int value) =>
    out.add(<int>[value & 0xFF, (value >> 8) & 0xFF]);

void _u32(BytesBuilder out, int value) {
  _u16(out, value & 0xFFFF);
  _u16(out, (value >> 16) & 0xFFFF);
}

/// Minimal ZIP writer so the tests control every byte.
List<int> makeZip(
  Map<String, String> files, {
  bool deflate = false,
  bool wrongCrc = false,
  Encoding encoding = utf8,
}) {
  final body = BytesBuilder();
  final directory = BytesBuilder();
  for (final file in files.entries) {
    final name = utf8.encode(file.key);
    final plain = encoding.encode(file.value);
    final data = deflate ? ZLibEncoder(raw: true).convert(plain) : plain;
    final crc = updateCrc32(0, plain) ^ (wrongCrc ? 1 : 0);
    final method = deflate ? 8 : 0;
    final offset = body.length;

    _u32(body, 0x04034b50);
    _u16(body, 20);
    _u16(body, 0);
    _u16(body, method);
    _u32(body, 0);
    _u32(body, crc);
    _u32(body, data.length);
    _u32(body, plain.length);
    _u16(body, name.length);
    _u16(body, 0);
    body.add(name);
    body.add(data);

    _u32(directory, 0x02014b50);
    _u16(directory, 20);
    _u16(directory, 20);
    _u16(directory, 0);
    _u16(directory, method);
    _u32(directory, 0);
    _u32(directory, crc);
    _u32(directory, data.length);
    _u32(directory, plain.length);
    _u16(directory, name.length);
    _u16(directory, 0);
    _u16(directory, 0);
    _u16(directory, 0);
    _u16(directory, 0);
    _u32(directory, 0);
    _u32(directory, offset);
    directory.add(name);
  }
  final directoryOffset = body.length;
  final directoryBytes = directory.takeBytes();
  body.add(directoryBytes);
  _u32(body, 0x06054b50);
  _u16(body, 0);
  _u16(body, 0);
  _u16(body, files.length);
  _u16(body, files.length);
  _u32(body, directoryBytes.length);
  _u32(body, directoryOffset);
  _u16(body, 0);
  return body.takeBytes();
}

Matcher failsWith(ZipError error) => throwsA(
      isA<ZipImportException>().having((e) => e.error, 'error', error),
    );

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('revive_zip_test');
  });

  tearDown(() async {
    await temp.delete(recursive: true);
  });

  Future<ZipImportResult> run(
    List<int> bytes, {
    String name = 'Fortnite-32.11.zip',
    Set<String> known = const <String>{},
  }) async {
    final zip = File('${temp.path}/input.zip');
    await zip.writeAsBytes(bytes);
    return importZipFile(
      zip,
      name,
      Directory('${temp.path}/out'),
      knownFingerprints: known,
    );
  }

  const build = <String, String>{
    'FortniteGame/Content/Paks/data.pak': 'pak content pak content',
    'Engine/readme.txt': 'engine',
  };

  test('CRC-32 matches the reference value', () {
    expect(updateCrc32(0, utf8.encode('123456789')), 0xCBF43926);
  });

  for (final deflate in <bool>[false, true]) {
    test('extracts a build (deflate: $deflate)', () async {
      final result = await run(makeZip(build, deflate: deflate));
      expect(result.version, '32.11');
      expect(result.fileCount, 2);
      expect(result.hasEngine, isTrue);
      expect(result.hasFortniteGame, isTrue);
      expect(
        await File('${temp.path}/out/FortniteGame/Content/Paks/data.pak')
            .readAsString(),
        'pak content pak content',
      );
    });
  }

  test('refuses the same build twice', () async {
    final first = await run(makeZip(build));
    await expectLater(
      run(makeZip(build), known: <String>{first.fingerprint}),
      failsWith(ZipError.duplicate),
    );
  });

  test('refuses paths leaving the target folder', () async {
    await expectLater(
      run(makeZip(<String, String>{'../evil.pak': 'x'})),
      failsWith(ZipError.unsafePath),
    );
    expect(await File('${temp.path}/evil.pak').exists(), isFalse);
  });

  test('refuses a file that is not a ZIP', () async {
    await expectLater(
      run(utf8.encode('this is definitely not a zip archive')),
      failsWith(ZipError.notZip),
    );
  });

  test('refuses an archive without any build', () async {
    await expectLater(
      run(makeZip(<String, String>{'photos/cat.txt': 'meow'})),
      failsWith(ZipError.notABuild),
    );
  });

  test('detects damaged content', () async {
    await expectLater(
      run(makeZip(build, wrongCrc: true)),
      failsWith(ZipError.corrupted),
    );
  });

  test('reads the version written inside a build with a neutral name',
      () async {
    final result = await run(
      makeZip(<String, String>{
        'FortniteGame/Content/Paks/data.pak': 'data',
        'FortniteGame/Binaries/lib.so':
            'abc++Fortnite+Release-12.41-CL-12905909 xyz',
      }, deflate: true),
      name: 'build.zip',
    );
    expect(result.version, '12.41');
  });

  test('finds a UTF-16 version split across chunks', () {
    final bytes = <int>[
      for (final unit in 'x++Fortnite+Release-7.30-Android'.codeUnits)
        ...<int>[unit, 0],
    ];
    for (var cut = 1; cut < bytes.length; cut++) {
      final scanner = VersionScanner()
        ..add(bytes.sublist(0, cut))
        ..add(bytes.sublist(cut))
        ..finish();
      expect(scanner.version, '7.30', reason: 'cut at $cut');
    }
  });

  test('reads the version from an APK inside the ZIP', () async {
    final apk = makeZip(<String, String>{
      'AndroidManifest.xml': '++Fortnite+Release-8.51-Android',
    }, deflate: true);
    final zip = File('${temp.path}/input.zip');
    // Latin-1 keeps every byte of the inner archive unchanged.
    await zip.writeAsBytes(
      makeZip(
        <String, String>{'game.apk': latin1.decode(apk)},
        encoding: latin1,
      ),
    );
    final result = await importZipFile(
      zip,
      'build.zip',
      Directory('${temp.path}/out'),
    );
    expect(result.version, '8.51');
  });

  test('guesses the version without using library folders', () {
    expect(detectVersion('++Fortnite+Release-7.30-Android.zip', []), '7.30');
    expect(
      detectVersion('build.zip', <List<String>>[
        <String>['Fortnite 12.41', 'FortniteGame', 'a.pak'],
      ]),
      '12.41',
    );
    expect(
      detectVersion('build.zip', <List<String>>[
        <String>['Engine', 'Binaries', 'OpenSSL-1.1.1', 'a.so'],
      ]),
      '',
    );
  });
}
