import 'package:flutter/material.dart';
import 'package:dog_friendly_map/utils/translations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dog_friendly_map/data/mock_places.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool isDarkSaved = prefs.getBool('is_dark') ?? false;
  final String langSaved = prefs.getString('lang') ?? 'ru';

  runApp(MyApp(initialIsDark: isDarkSaved, initialLang: langSaved));
}

// === БЛОК 1: ГЛАВНЫЙ ИСТОЧНИК ДАННЫХ (MYAPP) ===

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

  DogFriendlyPlace? _selectedPlace; 

  // 2. ФУНКЦИЯ ДЛЯ ИКОНОК: Выдает нужную картинку по названию категории
  // НОВАЯ ФУНКЦИЯ ДЛЯ КАСТОМНОГО ПИНА С ЛАПКОЙ
  Widget _buildCustomPin(String category) {
    // 1. Выбираем цвет булавки в зависимости от заведения
    Color pinColor;
    switch (category) {
      case 'cafe': pinColor = Colors.brown; break;
      case 'restaurant': pinColor = Colors.red; break;
      case 'park': pinColor = Colors.green; break;
      case 'playground': pinColor = Colors.blue; break;
      default: pinColor = Colors.grey;
    }

    // 2. Собираем иконку по твоему скетчу через Stack (слои)
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Нижний слой: Большая цветная капля
          Icon(Icons.location_on, color: pinColor, size: 60),
          
          // Верхний слой: Белый кружок с лапкой внутри
          Positioned(
            top: 8, // Сдвигаем кружок ровно в центр "головы" капли
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.pets, // Та самая лапка
                  color: pinColor, // Красим лапку в цвет капли для стиля
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  

  @override
  Widget build(BuildContext context) {
    final isDark = widget.currentThemeMode == ThemeMode.dark;
    final lang = widget.currentLang;

    return Scaffold(
      body: Stack(
        children: [

          // СЛОЙ 1: Реальная интерактивная карта OpenStreetMap
          FlutterMap(
            options: const MapOptions(
              // ⬇️ ИСПРАВЛЕНО: Теперь карта при запуске открывает Киев
              initialCenter: LatLng(50.4501, 30.5234), 
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.dog_friendly_map',
              ),
              
              // Слой с маркерами (теперь динамический!)
              // Слой с маркерами
              // Слой с маркерами
              MarkerLayer(
                markers: mockPlacesList
                    .where((place) => place.category == _selectedCategory)
                    .map((place) => Marker(
                          point: place.coordinates,
                          
                          // 1. ВОЗВРАЩАЕМ СТРОГИЕ РАЗМЕРЫ БУЛАВКИ
                          width: 60,  
                          height: 60, 
                          rotate: true,
                          
                          // 2. НАСТРАИВАЕМ ЯКОРЬ (АНКОР)
                          // Во flutter_map логика якоря часто инвертирована. 
                          // Попробуй Alignment.topCenter. Если булавка все равно уплывает в другую сторону, 
                          // поменяй на Alignment.bottomCenter.
                          // Для идеальной подгонки до миллиметра можно использовать числа: const Alignment(0, -0.8)
                          alignment: Alignment.topCenter, 
                          
                          // 3. Используем Stack с выходом за края
                          child: Stack(
                            clipBehavior: Clip.none, // ⬅️ МАГИЯ: разрешаем тексту вылезать за пределы 60х60!
                            alignment: Alignment.center,
                            children: [
                              
                              // ВСПЛЫВАЮЩИЙ КВАДРАТИК (Сдвигаем его вверх)
                              if (_selectedPlace == place)
                                Positioned(
                                  bottom: 55, // Высота подъема над булавкой
                                  child: Container(
                                    width: 140, // Жестко даем ширину, чтоб длинные тексты влезали
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.grey[800] : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: const [
                                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                                      ],
                                    ),
                                    child: Text(
                                      place.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2, 
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              
                              // САМА БУЛАВКА
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedPlace = _selectedPlace == place ? null : place;
                                  });
                                },
                                child: _buildCustomPin(place.category),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
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