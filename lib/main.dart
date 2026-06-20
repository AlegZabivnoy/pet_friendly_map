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
  // Следилка за высотой вытягивания карточки (начинаем с 30%)
  double _sheetExtent = 0.3;

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
            options: MapOptions(
              initialCenter: const LatLng(50.4501, 30.5234), 
              initialZoom: 13.0,
              
              // 2. onTap теперь находится строго ВНУТРИ скобок MapOptions!
              onTap: (tapPosition, point) {
                if (_selectedPlace != null) {
                  setState(() {
                    _selectedPlace = null;
                    _sheetExtent = 0.3;
                  });
                }
              },
            ),
            
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.dog_friendly_map',
              ),
            
              // Слой с маркерами
              MarkerLayer(
                markers: mockPlacesList
                    .where((place) => place.category == _selectedCategory)
                    .map((place) => Marker(
                          point: place.coordinates,
                          width: 60,  
                          height: 60, 
                          rotate: true,
                          alignment: Alignment.bottomCenter, 
                          
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPlace = place; // Запоминаем, что открыли
                                _sheetExtent = 0.3;     // Выезжает на 30%
                              });
                            },
                            child: _buildCustomPin(place.category),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),

          // 1. УМНОЕ ДИНАМИЧЕСКОЕ ЗАТЕМНЕНИЕ
          if (_selectedPlace != null)
            IgnorePointer(
              // МАГИЯ 1: Пока карточка маленькая (<= 30%), сквозь затемнение можно 
              // свободно скроллить и двигать карту!
              ignoring: _sheetExtent <= 0.3, 
              child: GestureDetector(
                onTap: () {
                  // Если карточка большая и мы кликнули по темному фону - скрываем её
                  setState(() {
                    _selectedPlace = null;
                    _sheetExtent = 0.3;
                  });
                },
                child: Container(
                  // МАГИЯ 2: Чем выше тянем, тем темнее фон. Математика плавно переводит 
                  // высоту от 0.3 до 0.8 в прозрачность от 0.0 (невидимо) до 0.6 (темно).
                  color: Colors.black.withOpacity(
                    ((_sheetExtent - 0.3) * 1.2).clamp(0.0, 0.6),
                  ),
                ),
              ),
            ),

          // 2. ВЫЕЗЖАЮЩАЯ КАРТОЧКА (Теперь встроена в экран)
          if (_selectedPlace != null)
            NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                // Если тянем карточку ниже 0.2 (20% экрана), считаем, что мы её "смахнули" вниз
                if (notification.extent < 0.2) {
                  setState(() {
                    _selectedPlace = null;
                    _sheetExtent = 0.3;
                  });
                } else {
                  setState(() {
                    _sheetExtent = notification.extent;
                  });
                }
                return true;
              },
              child: DraggableScrollableSheet(
                initialChildSize: 0.3,
                minChildSize: 0.1, // Разрешаем тянуть вниз для закрытия
                maxChildSize: 0.8,
                snap: true, // <--- МАГИЯ ПРИЛИПАНИЯ
                snapSizes: const [0.3, 0.8], // <--- ТОЧКИ, ГДЕ ОНА ОСТАНАВЛИВАЕТСЯ
                builder: (context, scrollController) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  final backgroundColor = isDark ? Colors.grey[900]! : Colors.white;

                  // ВЫНОСИМ ПЕРЕМЕННУЮ СЮДА: она будет сохраняться при перетаскивании
                  bool isLiked = false; 

                  return StatefulBuilder(
                    builder: (context, setLocalState) {
                      return Container(
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                        ),
                        child: Stack(
                          children: [
                            ListView(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              children: [
                                Center(
                                  child: Container(
                                    width: 40, height: 5,
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _selectedPlace!.name,
                                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(5, (index) {
                                        return Icon(
                                          index < 4 ? Icons.star : Icons.star_border,
                                          size: 20,
                                          color: Colors.orange,
                                        );
                                      }),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isLiked ? Icons.favorite : Icons.favorite_border,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () {
                                        // Используем setLocalState, чтобы перерисовать только кнопку
                                        setLocalState(() => isLiked = !isLiked);
                                      },
                                    ),
                                  ],
                                ),
                                Text(
                                  _selectedPlace!.category.toUpperCase(),
                                  style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(12),
                                        image: const DecorationImage(
                                          image: NetworkImage('https://via.placeholder.com/150'),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Expanded(
                                      child: Text(
                                        'Здесь будет детальное описание места. Мы добавили фото-плейсхолдер и полноценную шкалу рейтинга. Теперь карточка выглядит профессионально и её удобно листать!',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 100),
                              ],
                            ),
                            // Градиент для плавного перехода
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: 80,
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        backgroundColor.withOpacity(0),
                                        backgroundColor.withOpacity(1),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
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