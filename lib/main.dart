import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dog_friendly_map/screens/main_navigation.dart';
import 'package:dog_friendly_map/services/settings_service.dart';
import 'package:dog_friendly_map/screens/registration_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sharedPrefs = await SharedPreferences.getInstance();
  final settingsService = SettingsService(sharedPrefs);
  final isRegistered = sharedPrefs.getBool('is_registered') ?? false;

  runApp(MyApp(
    settingsService: settingsService,
    isRegistered: isRegistered,
  ));
}

class MyApp extends StatefulWidget {
  final SettingsService settingsService;
  final bool isRegistered;

  const MyApp({
    super.key,
    required this.settingsService,
    required this.isRegistered,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;
  late String _currentLang;
  late bool _isRegistered;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.settingsService.isDarkMode ? ThemeMode.dark : ThemeMode.light;
    _currentLang = widget.settingsService.currentLang;
    _isRegistered = widget.isRegistered;
  }

  void _toggleTheme() async {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
        widget.settingsService.saveTheme(true);
      } else {
        _themeMode = ThemeMode.light;
        widget.settingsService.saveTheme(false);
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
      widget.settingsService.saveLanguage(_currentLang);
    });
  }

  void _completeRegistration() {
    setState(() {
      _isRegistered = true;
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
      home: _isRegistered
          ? MainNavigation(
        currentThemeMode: _themeMode,
        currentLang: _currentLang,
        onThemeToggle: _toggleTheme,
        onLanguageToggle: _toggleLanguage,
      )
          : RegistrationScreen(onComplete: _completeRegistration),
    );
  }
}