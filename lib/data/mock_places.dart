// Импортируем LatLng, так как мы используем координаты
import 'package:latlong2/latlong.dart';

// Наша модель данных
class DogFriendlyPlace {
  final String name;
  final String category;
  final LatLng coordinates;

  DogFriendlyPlace({
    required this.name,
    required this.category,
    required this.coordinates,
  });
}

// Глобальная переменная со списком-заглушкой (чтобы брать её откуда угодно)
final List<DogFriendlyPlace> mockPlacesList = [
  DogFriendlyPlace(
    name: 'Хлібний (Крещатик)',
    category: 'cafe',
    coordinates: const LatLng(50.4495, 30.5225),
  ),
  DogFriendlyPlace(
    name: 'Blur Coffee',
    category: 'cafe',
    coordinates: const LatLng(50.4354, 30.5298),
  ),
  DogFriendlyPlace(
    name: 'Любчик (Воздвиженка)',
    category: 'restaurant',
    coordinates: const LatLng(50.4612, 30.5105),
  ),
  // ... можешь оставить остальные места тут
];