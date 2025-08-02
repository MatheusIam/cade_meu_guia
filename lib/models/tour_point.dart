import 'package:latlong2/latlong.dart';

class TourPoint {
  final String id;
  final String name;
  final String title;
  final String description;
  final LatLng location;
  final double rating;
  final int photoCount;
  final String activityType;
  final List<String> images;

  const TourPoint({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.location,
    required this.rating,
    required this.photoCount,
    required this.activityType,
    this.images = const [],
  });

  // Método para converter para Map (útil para serialização)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'description': description,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'rating': rating,
      'photoCount': photoCount,
      'activityType': activityType,
      'images': images,
    };
  }

  // Método para criar uma instância a partir de um Map
  factory TourPoint.fromMap(Map<String, dynamic> map) {
    return TourPoint(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: LatLng(
        map['latitude']?.toDouble() ?? 0.0,
        map['longitude']?.toDouble() ?? 0.0,
      ),
      rating: map['rating']?.toDouble() ?? 0.0,
      photoCount: map['photoCount']?.toInt() ?? 0,
      activityType: map['activityType'] ?? '',
      images: List<String>.from(map['images'] ?? []),
    );
  }

  // Método copyWith para criar cópias modificadas
  TourPoint copyWith({
    String? id,
    String? name,
    String? title,
    String? description,
    LatLng? location,
    double? rating,
    int? photoCount,
    String? activityType,
    List<String>? images,
  }) {
    return TourPoint(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      photoCount: photoCount ?? this.photoCount,
      activityType: activityType ?? this.activityType,
      images: images ?? this.images,
    );
  }
}
