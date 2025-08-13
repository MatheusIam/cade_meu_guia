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
  // Hierarquia
  final String? parentId; // ponto pai (se este for um sub-ponto)
  final List<String> childPointIds; // ids de sub-pontos desta área
  // Informações detalhadas
  final String history; // história do local
  final String significance; // significado / relevância
  final String purpose; // propósito / por que foi feito
  // Polígono opcional para representar uma área (se for zona e não apenas ponto central)
  final List<LatLng>? polygon; // mínimo de 3 pontos para ser válido

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
  this.parentId,
  this.childPointIds = const [],
  this.history = '',
  this.significance = '',
  this.purpose = '',
  this.polygon,
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
  'parentId': parentId,
  'childPointIds': childPointIds,
  'history': history,
  'significance': significance,
  'purpose': purpose,
    'polygon': polygon
      ?.map((p) => {'lat': p.latitude, 'lng': p.longitude})
      .toList(),
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
  parentId: map['parentId'],
  childPointIds: List<String>.from(map['childPointIds'] ?? []),
  history: map['history'] ?? '',
  significance: map['significance'] ?? '',
  purpose: map['purpose'] ?? '',
    polygon: (map['polygon'] is List)
      ? (map['polygon'] as List)
        .whereType<Map>()
        .map((m) => LatLng(
          (m['lat'] as num?)?.toDouble() ?? 0.0,
          (m['lng'] as num?)?.toDouble() ?? 0.0,
          ))
        .toList()
      : null,
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
    String? parentId,
    List<String>? childPointIds,
    String? history,
    String? significance,
    String? purpose,
  List<LatLng>? polygon,
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
      parentId: parentId ?? this.parentId,
      childPointIds: childPointIds ?? this.childPointIds,
      history: history ?? this.history,
      significance: significance ?? this.significance,
      purpose: purpose ?? this.purpose,
    polygon: polygon ?? this.polygon,
    );
  }

  bool get isArea => (polygon != null && polygon!.length >= 3) || childPointIds.isNotEmpty;
  LatLng get centroid {
    if (polygon == null || polygon!.isEmpty) return location;
    double x = 0, y = 0;
    for (final p in polygon!) { x += p.latitude; y += p.longitude; }
    return LatLng(x / polygon!.length, y / polygon!.length);
  }
}
