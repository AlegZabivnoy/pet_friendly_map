import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dog_friendly_map/screens/main_map_screen.dart';
import 'package:dog_friendly_map/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализируем SharedPreferences один раз при старте приложения
  final sharedPrefs = await SharedPreferences.getInstance();
  final settingsService = SettingsService(sharedPrefs);

  runApp(MyApp(settingsService: settingsService));
}

class MyApp extends StatefulWidget {
  final SettingsService settingsService;

  const MyApp({super.key, required this.settingsService});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;
  late String _currentLang;

  @override
  void initState() {
    super.initState();
    // Загружаем сохранённые настройки напрямую через сервис
    _themeMode = widget.settingsService.isDarkMode ? ThemeMode.dark : ThemeMode.light;
    _currentLang = widget.settingsService.currentLang;
  }

  void _toggleTheme() async {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
        widget.settingsService.saveTheme(true); // Сохраняем состояние "тёмная"
      } else {
        _themeMode = ThemeMode.light;
        widget.settingsService.saveTheme(false); // Сохраняем состояние "светлая"
      }
    });
  }

  void _toggleLanguage() async {
    setState(() {
      if (_currentLang == 'ru') {
        _currentLang = 'en';
      } else if (_currentLang == 'en') {
        _currentLang = 'ua';
      } else {
        _currentLang = 'ru';
      }
      widget.settingsService.saveLanguage(_currentLang); // Сохраняем выбранную локаль
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet-Friendly Map',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: MainMapScreen(
        currentThemeMode: _themeMode,
        currentLang: _currentLang,
        onThemeToggle: _toggleTheme,
        onLanguageToggle: _toggleLanguage,
      ),
    );
  }
}