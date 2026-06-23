import 'package:latlong2/latlong.dart';

class PetFriendlyPlace {
  final String id;
  final String name;
  final String description;
  final String category; // 'cafe', 'restaurant', 'park', 'playground'
  final LatLng coordinates;
  final double rating;
  final String? imageUrl;

  const PetFriendlyPlace({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.coordinates,
    required this.rating,
    this.imageUrl,
  });

  // ВАЖНО: Метод для парсинга из чистого JSON (который прилетит из базы данных)
  factory PetFriendlyPlace.fromJson(Map<String, dynamic> json) {
    return PetFriendlyPlace(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      rating: (json['rating'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      // База данных не знает про класс LatLng из Флаттера, она вернет просто цифры:
      coordinates: LatLng(
        json['latitude'] as double,
        json['longitude'] as double,
      ),
    );
  }

  // Метод на случай, если нам нужно будет отправить данные обратно в базу
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'rating': rating,
      'image_url': imageUrl,
      'latitude': coordinates.latitude,
      'longitude': coordinates.longitude,
    };
  }
}