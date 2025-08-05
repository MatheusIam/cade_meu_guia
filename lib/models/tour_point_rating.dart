/// Modelo para representar uma avaliação de ponto turístico
class TourPointRating {
  final String id;
  final String tourPointId;
  final String userId;
  final double overallRating;
  final double accessibilityRating;
  final double cleanlinessRating;
  final double infrastructureRating;
  final double safetyRating;
  final double experienceRating;
  final String? comment;
  final DateTime dateCreated;
  final bool isRecommended;

  const TourPointRating({
    required this.id,
    required this.tourPointId,
    required this.userId,
    required this.overallRating,
    required this.accessibilityRating,
    required this.cleanlinessRating,
    required this.infrastructureRating,
    required this.safetyRating,
    required this.experienceRating,
    this.comment,
    required this.dateCreated,
    required this.isRecommended,
  });

  /// Calcula a média das avaliações por categoria
  double get averageRating {
    return (accessibilityRating + 
            cleanlinessRating + 
            infrastructureRating + 
            safetyRating + 
            experienceRating) / 5;
  }

  /// Converte o modelo para Map (para salvar em SharedPreferences ou API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tourPointId': tourPointId,
      'userId': userId,
      'overallRating': overallRating,
      'accessibilityRating': accessibilityRating,
      'cleanlinessRating': cleanlinessRating,
      'infrastructureRating': infrastructureRating,
      'safetyRating': safetyRating,
      'experienceRating': experienceRating,
      'comment': comment,
      'dateCreated': dateCreated.toIso8601String(),
      'isRecommended': isRecommended,
    };
  }

  /// Cria uma instância a partir de um Map
  factory TourPointRating.fromJson(Map<String, dynamic> json) {
    return TourPointRating(
      id: json['id'],
      tourPointId: json['tourPointId'],
      userId: json['userId'],
      overallRating: json['overallRating'].toDouble(),
      accessibilityRating: json['accessibilityRating'].toDouble(),
      cleanlinessRating: json['cleanlinessRating'].toDouble(),
      infrastructureRating: json['infrastructureRating'].toDouble(),
      safetyRating: json['safetyRating'].toDouble(),
      experienceRating: json['experienceRating'].toDouble(),
      comment: json['comment'],
      dateCreated: DateTime.parse(json['dateCreated']),
      isRecommended: json['isRecommended'],
    );
  }

  /// Cria uma cópia com alterações
  TourPointRating copyWith({
    String? id,
    String? tourPointId,
    String? userId,
    double? overallRating,
    double? accessibilityRating,
    double? cleanlinessRating,
    double? infrastructureRating,
    double? safetyRating,
    double? experienceRating,
    String? comment,
    DateTime? dateCreated,
    bool? isRecommended,
  }) {
    return TourPointRating(
      id: id ?? this.id,
      tourPointId: tourPointId ?? this.tourPointId,
      userId: userId ?? this.userId,
      overallRating: overallRating ?? this.overallRating,
      accessibilityRating: accessibilityRating ?? this.accessibilityRating,
      cleanlinessRating: cleanlinessRating ?? this.cleanlinessRating,
      infrastructureRating: infrastructureRating ?? this.infrastructureRating,
      safetyRating: safetyRating ?? this.safetyRating,
      experienceRating: experienceRating ?? this.experienceRating,
      comment: comment ?? this.comment,
      dateCreated: dateCreated ?? this.dateCreated,
      isRecommended: isRecommended ?? this.isRecommended,
    );
  }

  @override
  String toString() {
    return 'TourPointRating(id: $id, tourPointId: $tourPointId, overallRating: $overallRating, averageRating: $averageRating)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TourPointRating && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
