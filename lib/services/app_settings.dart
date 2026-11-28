import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/strings.dart';

/// Language preference. `auto` follows the phone, with English as fallback.
class AppSettings extends ChangeNotifier with WidgetsBindingObserver {
  AppSettings({String preference = 'auto', this.deviceLanguageOverride})
      : _preference = preference;

  static const _languageKey = 'revive_language';

  /// Only used by tests.
  final String? deviceLanguageOverride;
  String _preference;

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = AppSettings(
      preference: prefs.getString(_languageKey) ?? 'auto',
    );
    WidgetsBinding.instance.addObserver(settings);
    return settings;
  }

  String get preference =>
      supportedLanguages.contains(_preference) ? _preference : 'auto';

  String get language => resolveLanguage(
        _preference,
        deviceLanguageOverride ??
            WidgetsBinding.instance.platformDispatcher.locale.languageCode,
      );

  String tr(String key, [Map<String, Object> args = const <String, Object>{}]) =>
      translate(language, key, args);

  Future<void> setPreference(String value) async {
    _preference = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, value);
  }

  @override
  void didChangeLocales(List<Locale>? locales) => notifyListeners();
}
