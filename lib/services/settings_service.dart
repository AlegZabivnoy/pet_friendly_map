import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyIsDark = 'is_dark';
  static const String _keyLang = 'lang';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  bool get isDarkMode => _prefs.getBool(_keyIsDark) ?? false;

  String? get currentLang => _prefs.getString(_keyLang);

  Future<void> saveTheme(bool isDark) async {
    await _prefs.setBool(_keyIsDark, isDark);
  }

  Future<void> saveLanguage(String lang) async {
    await _prefs.setString(_keyLang, lang);
  }
}