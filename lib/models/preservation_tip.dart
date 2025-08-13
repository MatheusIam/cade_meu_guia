/// Modelo para dicas de preservação ambiental e cultural
class PreservationTip {
  final String id;
  final String title;
  final String description;
  final String icon;
  final PreservationType type;
  final int priority; // 1 = alta, 2 = média, 3 = baixa

  const PreservationTip({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    this.priority = 2,
  });

  factory PreservationTip.fromJson(Map<String, dynamic> json) {
    return PreservationTip(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String? ?? '🌿',
      type: _typeFromString(json['type'] as String),
      priority: (json['priority'] as num?)?.toInt() ?? 2,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'icon': icon,
        'type': type.name,
        'priority': priority,
      };

  static PreservationType _typeFromString(String v) {
    switch (v.toLowerCase()) {
      case 'environmental':
        return PreservationType.environmental;
      case 'cultural':
        return PreservationType.cultural;
      case 'social':
        return PreservationType.social;
      case 'general':
        return PreservationType.general;
      default:
        return PreservationType.general;
    }
  }
}

/// Tipos de preservação
enum PreservationType {
  environmental, // Ambiental
  cultural,      // Cultural
  social,        // Social
  general,       // Geral
}
