import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keeps the Supabase session in the Android Keystore backed storage instead of
/// plain SharedPreferences.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage();

  static const _key = 'revive.supabase.session';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => await accessToken() != null;

  @override
  Future<String?> accessToken() async {
    try {
      return await _storage.read(key: _key);
    } catch (_) {
      // The Keystore key can become unreadable (restored backup, OS update).
      // Drop the session so the user can simply sign in again.
      await _storage.deleteAll();
      return null;
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _key, value: persistSessionString);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _key);
}
