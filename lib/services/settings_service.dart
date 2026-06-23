import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyIsDark = 'is_dark';
  static const String _keyLang = 'lang';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  // Получить сохранённую тему (если настроек нет — по дефолту светлая, то есть false)
  bool get isDarkMode => _prefs.getBool(_keyIsDark) ?? false;

  // Получить сохранённый язык (если настроек нет — по дефолту 'ru')
  String get currentLang => _prefs.getString(_keyLang) ?? 'ru';

  // Сохранить настройку темы в память телефона
  Future<void> saveTheme(bool isDark) async {
    await _prefs.setBool(_keyIsDark, isDark);
  }

  // Сохранить настройку языка в память телефона
  Future<void> saveLanguage(String lang) async {
    await _prefs.setString(_keyLang, lang);
  }
}