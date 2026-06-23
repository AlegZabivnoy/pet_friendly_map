import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dog_friendly_map/screens/main_map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool isDarkSaved = prefs.getBool('is_dark') ?? false;
  final String langSaved = prefs.getString('lang') ?? 'ru';

  runApp(MyApp(initialIsDark: isDarkSaved, initialLang: langSaved));
}

class MyApp extends StatefulWidget {
  final bool initialIsDark;
  final String initialLang;

  const MyApp({
    super.key,
    required this.initialIsDark,
    required this.initialLang,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;
  late String _currentLang;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialIsDark ? ThemeMode.dark : ThemeMode.light;
    _currentLang = widget.initialLang;
  }

  void _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
        prefs.setBool('is_dark', true);
      } else {
        _themeMode = ThemeMode.light;
        prefs.setBool('is_dark', false);
      }
    });
  }

  void _toggleLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_currentLang == 'ru') {
        _currentLang = 'en';
      } else if (_currentLang == 'en') {
        _currentLang = 'ua';
      } else {
        _currentLang = 'ru';
      }
      prefs.setString('lang', _currentLang);
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