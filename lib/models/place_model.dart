import 'package:latlong2/latlong.dart';

class PetFriendlyPlace {
  final String id;
  final String name;
  final String description;
  final String category;
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

  factory PetFriendlyPlace.fromJson(Map<String, dynamic> json) {
    // Безопасный парсинг чисел (меняем запятую на точку, если таблица на RU/UK)
    double parseCoordinate(dynamic val) {
      if (val == null) return 0.0;
      final str = val.toString().replaceAll(',', '.').trim();
      return double.tryParse(str) ?? 0.0;
    }

    final rawImage = json['image_url']?.toString().trim();

    return PetFriendlyPlace(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: (json['category']?.toString() ?? '').toLowerCase().trim(),
      rating: double.tryParse(
            (json['rating']?.toString() ?? '').replaceAll(',', '.'),
          ) ?? 5.0,
      imageUrl: (rawImage != null && rawImage.isNotEmpty && !rawImage.contains('placeholder.com'))
          ? rawImage
          : null,
      coordinates: LatLng(
        parseCoordinate(json['latitude']),
        parseCoordinate(json['longitude']),
      ),
    );
  }

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