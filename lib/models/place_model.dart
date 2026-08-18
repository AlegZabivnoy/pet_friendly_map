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
    return PetFriendlyPlace(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: (json['category']?.toString() ?? '').toLowerCase().trim(),
      rating: double.tryParse(json['rating']?.toString() ?? '') ?? 5.0,
      imageUrl: json['image_url']?.toString(),
      coordinates: LatLng(
        double.tryParse(json['latitude']?.toString() ?? '') ?? 0.0,
        double.tryParse(json['longitude']?.toString() ?? '') ?? 0.0,
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