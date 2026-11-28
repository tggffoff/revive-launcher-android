import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/imported_build.dart';

/// Persists the list of imported builds.
class BuildLibrary {
  static const _key = 'revive_builds';
  static const _backupKey = 'revive_builds_corrupt';

  Future<List<ImportedBuild>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return <ImportedBuild>[];
    try {
      final builds = <ImportedBuild>[];
      for (final item in jsonDecode(raw) as List<dynamic>) {
        builds.add(ImportedBuild.fromJson(item as Map<String, dynamic>));
      }
      return builds;
    } catch (_) {
      // Keep a copy instead of silently destroying the user's library.
      await prefs.setString(_backupKey, raw);
      return <ImportedBuild>[];
    }
  }

  Future<void> save(List<ImportedBuild> builds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(builds.map((build) => build.toJson()).toList()),
    );
  }
}
