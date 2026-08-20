import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dog_friendly_map/utils/translations.dart';
import 'package:dog_friendly_map/data/mock_places.dart';
import 'package:dog_friendly_map/screens/settings_screen.dart';
import 'package:dog_friendly_map/models/place_model.dart';
import 'package:dog_friendly_map/widgets/compass_cone_painter.dart';
import 'package:dog_friendly_map/services/place_service.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:dog_friendly_map/services/favorites_service.dart';
import 'package:dog_friendly_map/utils/navigation_helper.dart';

class MainMapScreen extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final String currentLang;
  final VoidCallback onThemeToggle;
  final VoidCallback onLanguageToggle;
  final VoidCallback onOpenProfile;

  const MainMapScreen({
    super.key,
    required this.currentThemeMode,
    required this.currentLang,
    required this.onThemeToggle,
    required this.onLanguageToggle,
    required this.onOpenProfile,
  });

  @override
  State<MainMapScreen> createState() => _MainMapScreenState();
}

class _MainMapScreenState extends State<MainMapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  final List<String> _categories = ['cafe', 'restaurant', 'park', 'playground'];
  String _selectedCategory = 'cafe';
  PetFriendlyPlace? _selectedPlace;
  double _sheetExtent = 0.3;
  bool _isPlaceLiked = false;
  String _searchQuery = '';

  List<PetFriendlyPlace> _places = mockPlacesList;

  LatLng? _currentUserLocation;
  double? _gpsHeading;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _startLiveLocationTracking();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    final fetched = await PlaceService.fetchPlaces();
    if (mounted && fetched.isNotEmpty) {
      setState(() {
        _places = fetched;
      });
    }
  }

  void _startLiveLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).listen((Position position) {
      if (!mounted) return;
      setState(() {
        _currentUserLocation = LatLng(position.latitude, position.longitude);
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
      case 'cafe':
        pinColor = Colors.brown;
        break;
      case 'restaurant':
        pinColor = Colors.red;
        break;
      case 'park':
        pinColor = Colors.green;
        break;
      case 'playground':
        pinColor = Colors.blue;
        break;
      default:
        pinColor = Colors.grey;
    }

    return Transform.translate(
      offset: const Offset(0, 6),
      child: SizedBox(
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
      ),
    );
  }

  bool _isCategoryMatch(String placeCat, String selectedCat) {
    final p = placeCat.toLowerCase().trim();
    final s = selectedCat.toLowerCase().trim();
    if (p == s) return true;

    if (s == 'cafe') return p.contains('cafe') || p.contains('кафе') || p.contains('кав');
    if (s == 'restaurant') return p.contains('rest') || p.contains('рест');
    if (s == 'park') return p.contains('park') || p.contains('парк') || p.contains('гай') || p.contains('сквер');
    if (s == 'playground') return p.contains('play') || p.contains('площ') || p.contains('майдан');

    return false;
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
              minZoom: 4.0,
              maxZoom: 18.0,
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
              if (_currentUserLocation != null)
                MarkerLayer(
                  markers: [
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
                  ],
                ),
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 45,
                  size: const Size(44, 44),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(50),
                  markers: _places
                      .where((place) {
                    final matchesCategory = _isCategoryMatch(place.category, _selectedCategory);
                    final matchesSearch = place.name.toLowerCase().contains(_searchQuery.toLowerCase());
                    return matchesCategory && matchesSearch;
                  })
                      .map((place) => Marker(
                    point: place.coordinates,
                    width: 60,
                    height: 60,
                    rotate: true,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () async {
                        final isFav = await FavoritesService.isFavorite(place.id);
                        setState(() {
                          _selectedPlace = place;
                          _isPlaceLiked = isFav;
                          _sheetExtent = 0.3;
                        });
                        _animatedMapMove(place.coordinates, 15.5);
                      },
                      child: _buildCustomPin(place.category),
                    ),
                  ))
                      .toList(),
                  builder: (context, markers) {
                    return Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2E7D32) : const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${markers.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  },
                ),
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
                controller: _sheetController,
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
                                width: 40,
                                height: 5,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  borderRadius: BorderRadius.circular(10),
                                ),
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
                                Padding(
                                  padding: const EdgeInsets.only(top: 5.0),
                                  child: Row(
                                    children: List.generate(5, (index) {
                                      return Icon(
                                        index < 4 ? Icons.star : Icons.star_border,
                                        size: 20,
                                        color: Colors.orange,
                                      );
                                    }),
                                  ),
                                ),
                                Transform.translate(
                                  offset: const Offset(8, -8),
                                  child: IconButton(
                                    icon: Icon(
                                      _isPlaceLiked ? Icons.favorite : Icons.favorite_border,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () async {
                                      if (_selectedPlace != null) {
                                        final updated = await FavoritesService.toggleFavorite(_selectedPlace!.id);
                                        setState(() {
                                          _isPlaceLiked = updated;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              AppTranslations.tr(_selectedPlace!.category, lang).toUpperCase(),
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
                                Expanded(
                                  child: Text(
                                    _selectedPlace!.description,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (_selectedPlace != null) {
                                    NavigationHelper.openNavigationSheet(context, _selectedPlace!.coordinates);
                                  }
                                },
                                icon: const Icon(Icons.near_me_rounded, color: Colors.white, size: 22),
                                label: Text(
                                  AppTranslations.tr('build_route', lang),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? const Color(0xFF2E7D32) : const Color(0xFF4CAF50),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
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
                    textInputAction: TextInputAction.search,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: AppTranslations.tr('search_hint', lang),
                      hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey),
                      prefixIcon: IconButton(
                        icon: Icon(Icons.person, color: isDark ? Colors.green[400] : Colors.green),
                        onPressed: widget.onOpenProfile,
                      ),
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
                          label: Text(AppTranslations.tr(category, lang)),
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
                if (_searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                    ),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      children: _places
                          .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                          .map((place) => ListTile(
                        leading: const Icon(Icons.location_on, color: Colors.redAccent),
                        title: Text(
                          place.name,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        ),
                        subtitle: Text(
                          AppTranslations.tr(place.category, lang),
                          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                        onTap: () async {
                          FocusScope.of(context).unfocus();
                          final isFav = await FavoritesService.isFavorite(place.id);
                          setState(() {
                            _selectedPlace = place;
                            _isPlaceLiked = isFav;
                            _searchQuery = '';
                          });
                          _animatedMapMove(place.coordinates, 15.5);
                        },
                      ))
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}