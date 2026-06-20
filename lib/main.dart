import 'package:flutter/material.dart';
import 'package:dog_friendly_map/utils/translations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dog_friendly_map/data/mock_places.dart';
import 'package:geolocator/geolocator.dart';

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
      home: MainMapScreen(
        currentThemeMode: _themeMode,
        currentLang: _currentLang,
        onThemeToggle: _toggleTheme,
        onLanguageToggle: _toggleLanguage,
      ),
    );
  }
}


// === БЛОК 2: ГЛАВНЫЙ ЭКРАН (КАРТА И ЛОГИКА) ===

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
  final MapController _mapController = MapController();

  void _goToMyLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
    );

    _mapController.move(
        LatLng(position.latitude, position.longitude),
        15.0
    );
  }

  final List<String> _categories = ['cafe', 'restaurant', 'park', 'playground'];
  String _selectedCategory = 'cafe';

  DogFriendlyPlace? _selectedPlace;
  double _sheetExtent = 0.3;
  bool _isPlaceLiked = false;

  Widget _buildCustomPin(String category) {
    Color pinColor;
    switch (category) {
      case 'cafe': pinColor = Colors.brown; break;
      case 'restaurant': pinColor = Colors.red; break;
      case 'park': pinColor = Colors.green; break;
      case 'playground': pinColor = Colors.blue; break;
      default: pinColor = Colors.grey;
    }

    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Icon(Icons.location_on, color: pinColor, size: 60),
          Positioned(
            top: 8,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.pets,
                  color: pinColor,
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

    final double screenHeight = MediaQuery.of(context).size.height;

    // Высчитываем динамический отступ для единственной кнопки
    final double gpsButtonBottom = _selectedPlace != null
        ? (screenHeight * _sheetExtent) + 16
        : 32.0;

    return Scaffold(
      body: Stack(
        children: [

          // СЛОЙ 1: Карта (Самый нижний слой)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(50.4501, 30.5234),
              initialZoom: 13.0,
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
                        _selectedPlace = place;
                        _isPlaceLiked = false;
                        _sheetExtent = 0.3;
                      });
                    },
                    child: _buildCustomPin(place.category),
                  ),
                ))
                    .toList(),
              ),
            ],
          ),

          // СЛОЙ 2: ЕДИНСТВЕННАЯ УМНАЯ КНОПКА GPS (Лежит поверх карты)
          Positioned(
            bottom: gpsButtonBottom,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'gps_btn',
              backgroundColor: isDark ? Colors.grey[850] : Colors.white,
              onPressed: _goToMyLocation,
              child: Icon(
                Icons.my_location,
                color: isDark ? Colors.green[400] : Colors.green,
              ),
            ),
          ),

          // СЛОЙ 3: Динамическое затемнение
          if (_selectedPlace != null)
            IgnorePointer(
              ignoring: _sheetExtent <= 0.3,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPlace = null;
                    _sheetExtent = 0.3;
                  });
                },
                child: Container(
                  color: Colors.black.withOpacity(
                    ((_sheetExtent - 0.3) * 1.2).clamp(0.0, 0.6),
                  ),
                ),
              ),
            ),

          // СЛОЙ 4: Выезжающая шторка карточки места
          if (_selectedPlace != null)
            NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
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
                minChildSize: 0.1,
                maxChildSize: 0.8,
                snap: true,
                snapSizes: const [0.3, 0.8],
                builder: (context, scrollController) {
                  final backgroundColor = isDark ? Colors.grey[900]! : Colors.white;

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
                                    _isPlaceLiked ? Icons.favorite : Icons.favorite_border,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPlaceLiked = !_isPlaceLiked;
                                    });
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
              ),
            ),

          // СЛОЙ 5: Панель поиска и фильтры (Самый верхний слой)
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: Column(
              children: [
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

// === БЛОК 3: ЭКРАН НАСТРОЕК ===
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
      appBar: AppBar(
        title: Text(currentLang == 'en' ? 'Settings' : currentLang == 'ua' ? 'Налаштування' : 'Настройки'),
        backgroundColor: isDark ? Colors.grey[850] : Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
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
          ListTile(
            leading: const Icon(Icons.language, color: Colors.green),
            title: Text(currentLang == 'en' ? 'Language' : currentLang == 'ua' ? 'Мова' : 'Язык'),
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