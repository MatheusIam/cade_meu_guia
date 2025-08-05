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
}

/// Tipos de preservação
enum PreservationType {
  environmental, // Ambiental
  cultural,      // Cultural
  social,        // Social
  general,       // Geral
}
