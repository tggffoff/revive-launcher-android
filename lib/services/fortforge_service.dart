import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

/// One build from the public FortForge API (https://docs.fortforge.co.uk).
class CatalogBuild {
  const CatalogBuild({
    required this.id,
    required this.title,
    required this.version,
    required this.thumbnailUrl,
    required this.tags,
    required this.releaseDate,
    required this.sizeBytes,
    required this.downloadCount,
  });

  final String id;
  final String title;
  final String version;
  final String thumbnailUrl;
  final List<String> tags;
  final String releaseDate;

  /// `0` means unknown.
  final int sizeBytes;
  final int downloadCount;

  factory CatalogBuild.fromJson(Map<String, dynamic> json) {
    String text(String key) {
      final value = json[key];
      return (value is String || value is num) ? '$value' : '';
    }

    int number(String key) {
      final value = json[key];
      return value is num ? value.toInt() : 0;
    }

    final tags = json['tags'];
    final thumbnail = text('thumbnail_url');
    return CatalogBuild(
      id: text('id'),
      title: text('title'),
      version: text('version'),
      thumbnailUrl: thumbnail.startsWith('https://') ? thumbnail : '',
      tags: tags is List ? tags.whereType<String>().toList() : const <String>[],
      releaseDate: text('release_date'),
      sizeBytes: number('file_size_bytes'),
      downloadCount: number('download_count'),
    );
  }
}

class CatalogResult {
  const CatalogResult(this.builds, {this.fromCache = false});

  final List<CatalogBuild> builds;
  final bool fromCache;
}

/// Parses one page of `GET /api/v1/builds`.
({List<Map<String, dynamic>> items, bool hasMore}) parseCatalogPage(
  String body,
) {
  final decoded = jsonDecode(body);
  if (decoded is! Map || decoded['data'] is! List) {
    throw const FormatException('Unexpected catalog response');
  }
  final pagination = decoded['pagination'];
  return (
    items: (decoded['data'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .toList(),
    hasMore: pagination is Map && pagination['has_more'] == true,
  );
}

class FortForgeService {
  static const _cacheKey = 'revive_fortforge_catalog';
  static const _maxPages = 8;

  CatalogResult? _memory;

  Future<CatalogResult> load({bool refresh = false}) async {
    final memory = _memory;
    if (!refresh && memory != null && !memory.fromCache) return memory;
    final prefs = await SharedPreferences.getInstance();
    try {
      final items = <Map<String, dynamic>>[];
      for (var page = 1; page <= _maxPages; page++) {
        final uri = Uri.parse(fortForgeApiUrl).replace(
          queryParameters: <String, String>{
            'platform': 'android',
            'per_page': '100',
            'page': '$page',
          },
        );
        final result = parseCatalogPage(await _get(uri));
        items.addAll(result.items);
        if (!result.hasMore) break;
      }
      await prefs.setString(_cacheKey, jsonEncode(items));
      return _memory = CatalogResult(
        items.map(CatalogBuild.fromJson).toList(),
      );
    } catch (_) {
      final cached = prefs.getString(_cacheKey);
      if (cached == null) rethrow;
      final builds = (jsonDecode(cached) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(CatalogBuild.fromJson)
          .toList();
      return _memory = CatalogResult(builds, fromCache: true);
    }
  }

  Future<String> _get(Uri uri) async {
    const timeout = Duration(seconds: 20);
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 12)
      ..userAgent = 'ReviveLauncherAndroid/$reviveVersion';
    try {
      final request = await client.getUrl(uri).timeout(timeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }
      return await response
          .transform(const Utf8Decoder(allowMalformed: true))
          .join()
          .timeout(timeout);
    } finally {
      client.close(force: true);
    }
  }
}
