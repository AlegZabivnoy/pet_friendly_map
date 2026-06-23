import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:dog_friendly_map/utils/translations.dart';
import 'package:dog_friendly_map/data/mock_places.dart';
import 'package:dog_friendly_map/screens/settings_screen.dart';
import 'package:dog_friendly_map/models/place_model.dart';
import 'package:dog_friendly_map/widgets/compass_cone_painter.dart'; // <-- Подключили отрисовщик луча

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

class _MainMapScreenState extends State<MainMapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  final List<String> _categories = ['cafe', 'restaurant', 'park', 'playground'];
  String _selectedCategory = 'cafe';
  PetFriendlyPlace? _selectedPlace;
  double _sheetExtent = 0.3;
  bool _isPlaceLiked = false;
  String _searchQuery = '';

  LatLng? _currentUserLocation;
  double? _gpsHeading; // <-- Переменная для хранения направления движения
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _startLiveLocationTracking();
  }

  void _startLiveLocationTracking() async {
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

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation, // Максимальная точность для отслеживания курса
        distanceFilter: 0,
      ),
    ).listen((Position position) {
      if (!mounted) return;
      setState(() {
        _currentUserLocation = LatLng(position.latitude, position.longitude);

        // Если GPS передаёт корректный азимут движения, обновляем направление луча
        if (position.heading >= 0 && position.heading <= 360) {
          _gpsHeading = position.heading;
        }
      });
    });
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final double startLat = _mapController.camera.center.latitude;
    final double startLng = _mapController.camera.center.longitude;
    final double startZoom = _mapController.camera.zoom;

    final AnimationController animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    final Animation<double> curveAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.fastOutSlowIn,
    );

    animationController.addListener(() {
      final double currentLat = startLat + (destLocation.latitude - startLat) * curveAnimation.value;
      final double currentLng = startLng + (destLocation.longitude - startLng) * curveAnimation.value;
      final double currentZoom = startZoom + (destZoom - startZoom) * curveAnimation.value;

      _mapController.move(LatLng(currentLat, currentLng), currentZoom);
    });

    animationController.forward().then((_) => animationController.dispose());
  }

  void _goToMyLocation() {
    if (_currentUserLocation != null) {
      _animatedMapMove(_currentUserLocation!, 16.0);
    } else {
      _startLiveLocationTracking();
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

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

    final double gpsButtonBottom = _selectedPlace != null
        ? (screenHeight * _sheetExtent) + 16
        : 32.0;

    return Scaffold(
      body: Stack(
        children: [
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
                urlTemplate: isDark
                    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                    : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.dog_friendly_map',
              ),
              MarkerLayer(
                markers: [
                  // Возвращённый маркер синей точки с красивым лучом направления
                  if (_currentUserLocation != null)
                    Marker(
                      point: _currentUserLocation!,
                      width: 100,
                      height: 100,
                      alignment: Alignment.center,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_gpsHeading != null)
                            Transform.rotate(
                              angle: (_gpsHeading! * (math.pi / 180)),
                              child: SizedBox(
                                width: 100,
                                height: 100,
                                child: CustomPaint(
                                  painter: CompassConePainter(),
                                ),
                              ),
                            ),
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ...mockPlacesList
                      .where((place) {
                    final matchesCategory = place.category == _selectedCategory;
                    final matchesSearch = place.name.toLowerCase().contains(_searchQuery.toLowerCase());
                    return matchesCategory && matchesSearch;
                  })
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
                        _animatedMapMove(place.coordinates, 15.5);
                      },
                      child: _buildCustomPin(place.category),
                    ),
                  ))
                      .toList(),
                ],
              ),
            ],
          ),
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
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
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