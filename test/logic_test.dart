import 'package:flutter_test/flutter_test.dart';
import 'package:revive_launcher/l10n/strings.dart';
import 'package:revive_launcher/models/auth_profile.dart';
import 'package:revive_launcher/models/imported_build.dart';
import 'package:revive_launcher/services/fortforge_service.dart';
import 'package:revive_launcher/services/zip_import.dart';
import 'package:revive_launcher/widgets/artwork.dart';

void main() {
  test('every text exists in the three languages', () {
    for (final entry in translations.entries) {
      expect(entry.value, hasLength(3), reason: entry.key);
      expect(entry.value.any((text) => text.isEmpty), isFalse);
    }
    for (final error in ZipError.values) {
      expect(translations, contains('zip_${error.name}'));
    }
  });

  test('language: manual choice, then phone, then English', () {
    expect(resolveLanguage('fr', 'es'), 'fr');
    expect(resolveLanguage('auto', 'es'), 'es');
    expect(resolveLanguage('auto', 'de'), 'en');
  });

  test('profile prefers the edited nickname', () {
    final profile = AuthProfile.fromMetadata(<String, dynamic>{
      'pseudo': 'Rex',
      'custom_claims': <String, dynamic>{'global_name': 'Discord Rex'},
      'avatar_url': 'https://cdn.discordapp.com/a.png',
    });
    expect(profile.pseudo, 'Rex');
    expect(profile.discordName, 'Discord Rex');
    expect(profile.avatarUrl, startsWith('https://'));
  });

  test('imported build survives serialisation', () {
    const build = ImportedBuild(
      id: '1',
      name: 'Build',
      version: '32.11',
      description: '',
      trailerUrl: '',
      directory: '/tmp/build',
      fileCount: 2,
      totalBytes: 10,
      hasEngine: true,
      hasFortniteGame: false,
      fingerprint: 'abc',
    );
    expect(ImportedBuild.fromJson(build.toJson()).toJson(), build.toJson());
  });

  test('catalog page follows the documented FortForge format', () {
    final page = parseCatalogPage(
      '{"data":[{"id":"a","title":"Chapter 5","version":"32.11",'
      '"thumbnail_url":null,"tags":["android"],"file_size_bytes":1048576}],'
      '"pagination":{"has_more":false}}',
    );
    expect(page.hasMore, isFalse);
    final build = CatalogBuild.fromJson(page.items.single);
    expect(build.version, '32.11');
    expect(build.thumbnailUrl, isEmpty);
    expect(build.sizeBytes, 1048576);
  });

  test('season artwork is chosen from the version', () {
    expect(seasonFromVersion('32.11'), 32);
    expect(seasonFromVersion('7.30'), 7);
    expect(seasonFromVersion('99.0'), isNull);
    expect(seasonFromVersion(''), isNull);
  });
}
