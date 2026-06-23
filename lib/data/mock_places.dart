import 'package:latlong2/latlong.dart';
import 'package:dog_friendly_map/models/place_model.dart'; // <-- Импортируем новую модель

const List<PetFriendlyPlace> mockPlacesList = [
  PetFriendlyPlace(
    id: 'cafe_1',
    name: 'Кафе "Пёс и Кофе"',
    description: 'Уютное место, где вашей собаке всегда рады. Есть миски с водой и бесплатные вкусняшки.',
    category: 'cafe',
    coordinates: LatLng(50.4501, 30.5234),
    rating: 4.8,
    imageUrl: 'https://via.placeholder.com/150',
  ),
  PetFriendlyPlace(
    id: 'rest_1',
    name: 'Ресторан "Хвост"',
    description: 'Просторный зал,Chef-меню для питомцев. Разрешено нахождение с крупными собаками.',
    category: 'restaurant',
    coordinates: LatLng(50.4545, 30.5290),
    rating: 4.9,
    imageUrl: 'https://via.placeholder.com/150',
  ),
  PetFriendlyPlace(
    id: 'park_1',
    name: 'Парк "Зелёный Гай"',
    description: 'Огромная ограждённая зона для выгула без поводков. Есть снаряды для тренировок.',
    category: 'park',
    coordinates: LatLng(50.4420, 30.5120),
    rating: 4.5,
    imageUrl: 'https://via.placeholder.com/150',
  ),
  PetFriendlyPlace(
    id: 'play_1',
    name: 'Площадка на Подоле',
    description: 'Чистая тренировочная зона со свежим покрытием и урнами для уборки.',
    category: 'playground',
    coordinates: LatLng(50.4620, 30.5180),
    rating: 4.2,
    imageUrl: 'https://via.placeholder.com/150',
  ),
];