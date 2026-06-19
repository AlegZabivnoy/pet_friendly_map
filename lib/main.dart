import 'package:flutter/material.dart';
import 'package:dog_friendly_map/utils/translations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const MyApp());
}

// === БЛОК 1: ГЛАВНЫЙ ИСТОЧНИК ДАННЫХ (MYAPP) ===

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  String _currentLang = 'ru'; // ИСПРАВЛЕНО: Язык теперь живет на самом верху!

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _toggleLanguage() {
    setState(() {
      if (_currentLang == 'ru') {
        _currentLang = 'en';
      } else if (_currentLang == 'en') {
        _currentLang = 'ua';
      } else {
        _currentLang = 'ru';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog-Friendly Map',
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
      // Передаем вниз НА ГЛАВНЫЙ ЭКРАН вообще всё: и тему, и язык, и обе функции
      home: MainMapScreen(
        currentThemeMode: _themeMode,
        currentLang: _currentLang,
        onThemeToggle: _toggleTheme,
        onLanguageToggle: _toggleLanguage,
      ),
    );
  }
}


// === БЛОК 2: ГЛАВНЫЙ ЭКРАН (ЧИСТАЯ КАРТА И ПОИСК) ===

class MainMapScreen extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final String currentLang;
  final VoidCallback onThemeToggle;
  final VoidCallback onLanguageToggle;

  const MainMapScreen({
    super.key,
    required this.currentThemeMode,
    required this.currentLang,
    required this.onThemeToggle,
    required this.onLanguageToggle,
  });

  @override
  State<MainMapScreen> createState() => _MainMapScreenState();
}

class _MainMapScreenState extends State<MainMapScreen> {
  final List<String> _categories = ['cafe', 'restaurant', 'park', 'playground'];
  String _selectedCategory = 'cafe';

  @override
  Widget build(BuildContext context) {
    final isDark = widget.currentThemeMode == ThemeMode.dark;
    final lang = widget.currentLang;

    return Scaffold(
      body: Stack(
        children: [

          // СЛОЙ 1: Заглушка под будущую карту
          // Реальная интерактивная карта
          FlutterMap(
            options: const MapOptions(
              // Начальные координаты центра карты (это Киев, можешь вбить свой город)
              initialCenter: LatLng(50.4501, 30.5234),
              initialZoom: 13.0,
            ),
            children: [
              // Слой, который скачивает картинки карты из интернета
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.dog_friendly_map',
              ),
              
              // Слой, где будут лежать наши маркеры-лапки café
              MarkerLayer(
                markers: [
                  Marker(
                    point: const LatLng(50.4501, 30.5234), // Координаты маркера
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.pets, // Иконка лапки
                      color: Colors.green,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // СЛОЙ 2: Верхняя панель управления
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Строка поиска
                Card(
                  elevation: 4,
                  color: isDark ? Colors.grey[850] : Colors.white,
                  child: TextField(
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: AppTranslations.data[lang]!['search_hint']!,
                      hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey),
                      prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey[400] : Colors.grey),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.settings, color: isDark ? Colors.grey[400] : Colors.grey),
                        onPressed: () {
                          // НАВИГАЦИЯ: Открываем экран настроек и передаем пропсы дальше
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingsScreen(
                                currentThemeMode: widget.currentThemeMode,
                                currentLang: widget.currentLang,
                                onThemeToggle: widget.onThemeToggle,
                                onLanguageToggle: widget.onLanguageToggle,
                              ),
                            ),
                          );
                        },
                      ),

                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Горизонтальный список фильтров
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(AppTranslations.data[lang]![category]!),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}


// === БЛОК 3: НОВЫЙ ЭКРАН НАСТРОЕК (ПОЯВЛЯЕТСЯ ПРИ КЛИКЕ НА ШЕСТЕРЕНКУ) ===

class SettingsScreen extends StatelessWidget {
  final ThemeMode currentThemeMode;
  final String currentLang;
  final VoidCallback onThemeToggle;
  final VoidCallback onLanguageToggle;

  const SettingsScreen({
    super.key,
    required this.currentThemeMode,
    required this.currentLang,
    required this.onThemeToggle,
    required this.onLanguageToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = currentThemeMode == ThemeMode.dark;

    return Scaffold(
      // Верхняя панель экрана с кнопкой "Назад" (Flutter рисует стрелочку сам!)
      appBar: AppBar(
        title: Text(currentLang == 'en' ? 'Settings' : currentLang == 'ua' ? 'Налаштування' : 'Настройки'),
        backgroundColor: isDark ? Colors.grey[850] : Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [

          // ПУНКТ 1: Смена Темы
          ListTile(
            leading: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: Colors.green),
            title: Text(currentLang == 'en' ? 'Dark Mode' : currentLang == 'ua' ? 'Темна тема' : 'Темная тема'),
            trailing: Switch(
              value: isDark,
              onChanged: (bool value) {
                onThemeToggle();
              },
            ),
          ),

          const Divider(),

          // ПУНКТ 2: Смена Языка
          ListTile(
            leading: const Icon(Icons.language, color: Colors.green),
            title: Text(currentLang == 'en' ? 'Language' : currentLang == 'ua' ? 'Мова' : 'Язык'),
            // Кнопка, отображающая текущий язык
            trailing: ElevatedButton(
              onPressed: onLanguageToggle,
              child: Text(currentLang.toUpperCase()),
            ),
          ),

        ],
      ),
    );
  }
}