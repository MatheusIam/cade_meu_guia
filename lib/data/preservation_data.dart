import '../models/preservation_tip.dart';

/// Dados das dicas de preservação dos pontos turísticos
class PreservationData {
  static final List<PreservationTip> _preservationTips = [
    // Dicas Ambientais
    const PreservationTip(
      id: '1',
      title: 'Não deixe lixo no local',
      description: 'Sempre leve seu lixo com você ou descarte em locais apropriados. Restos de comida, embalagens e cigarros podem prejudicar a fauna e flora local.',
      icon: '🗑️',
      type: PreservationType.environmental,
      priority: 1,
    ),
    const PreservationTip(
      id: '2',
      title: 'Respeite a vida selvagem',
      description: 'Não alimente animais silvestres, mantenha distância segura e não perturbe seus habitats naturais. Isso preserva o comportamento natural dos animais.',
      icon: '🦋',
      type: PreservationType.environmental,
      priority: 1,
    ),
    const PreservationTip(
      id: '3',
      title: 'Use trilhas demarcadas',
      description: 'Siga sempre as trilhas oficiais para evitar erosão do solo e danos à vegetação. Não crie atalhos ou novos caminhos.',
      icon: '🥾',
      type: PreservationType.environmental,
      priority: 1,
    ),
    const PreservationTip(
      id: '4',
      title: 'Economize água',
      description: 'Use a água de forma consciente, especialmente em regiões com escassez. Não desperdice em torneiras, chuveiros ou piscinas.',
      icon: '💧',
      type: PreservationType.environmental,
      priority: 2,
    ),
    const PreservationTip(
      id: '5',
      title: 'Não retire plantas ou pedras',
      description: 'Deixe tudo como encontrou. Plantas, pedras, flores e outros elementos naturais fazem parte do ecossistema local.',
      icon: '🌸',
      type: PreservationType.environmental,
      priority: 1,
    ),

    // Dicas Culturais
    const PreservationTip(
      id: '6',
      title: 'Respeite o patrimônio histórico',
      description: 'Não toque, risque ou danifique monumentos, estátuas, placas históricas ou construções antigas. Elas são patrimônio de todos.',
      icon: '🏛️',
      type: PreservationType.cultural,
      priority: 1,
    ),
    const PreservationTip(
      id: '7',
      title: 'Valorize a cultura local',
      description: 'Conheça e respeite as tradições locais, compre de artesãos da região e valorize a culinária típica.',
      icon: '🎭',
      type: PreservationType.cultural,
      priority: 2,
    ),
    const PreservationTip(
      id: '8',
      title: 'Fotografe com consciência',
      description: 'Ao fotografar pessoas locais, peça sempre permissão. Respeite locais sagrados onde fotos podem ser proibidas.',
      icon: '📸',
      type: PreservationType.cultural,
      priority: 2,
    ),

    // Dicas Sociais
    const PreservationTip(
      id: '9',
      title: 'Apoie o comércio local',
      description: 'Prefira estabelecimentos locais, guias da região e produtos artesanais. Isso fortalece a economia da comunidade.',
      icon: '🏪',
      type: PreservationType.social,
      priority: 2,
    ),
    const PreservationTip(
      id: '10',
      title: 'Seja respeitoso com moradores',
      description: 'Trate os moradores locais com respeito e cordialidade. Você é um visitante na casa deles.',
      icon: '🤝',
      type: PreservationType.social,
      priority: 1,
    ),
    const PreservationTip(
      id: '11',
      title: 'Respeite horários de funcionamento',
      description: 'Siga os horários estabelecidos para visitação e evite fazer barulho excessivo, especialmente em áreas residenciais.',
      icon: '⏰',
      type: PreservationType.social,
      priority: 2,
    ),

    // Dicas Gerais
    const PreservationTip(
      id: '12',
      title: 'Informe-se antes da visita',
      description: 'Pesquise sobre regras específicas do local, taxa de visitação, época ideal para visitar e equipamentos necessários.',
      icon: '📚',
      type: PreservationType.general,
      priority: 2,
    ),
    const PreservationTip(
      id: '13',
      title: 'Viaje em grupos pequenos',
      description: 'Grupos menores causam menos impacto ambiental e permitem uma experiência mais autêntica e respeitosa.',
      icon: '👥',
      type: PreservationType.general,
      priority: 3,
    ),
    const PreservationTip(
      id: '14',
      title: 'Use produtos biodegradáveis',
      description: 'Prefira protetor solar, repelente e produtos de higiene biodegradáveis para não contaminar rios e solo.',
      icon: '🧴',
      type: PreservationType.environmental,
      priority: 2,
    ),
    const PreservationTip(
      id: '15',
      title: 'Eduque outros visitantes',
      description: 'Compartilhe conhecimento sobre preservação com outros turistas. Seja um exemplo positivo de turismo consciente.',
      icon: '🎓',
      type: PreservationType.general,
      priority: 3,
    ),
  ];

  /// Retorna todas as dicas de preservação
  static List<PreservationTip> getAllTips() {
    return List.unmodifiable(_preservationTips);
  }

  /// Retorna dicas filtradas por tipo
  static List<PreservationTip> getTipsByType(PreservationType type) {
    return _preservationTips.where((tip) => tip.type == type).toList();
  }

  /// Retorna dicas de alta prioridade
  static List<PreservationTip> getHighPriorityTips() {
    return _preservationTips.where((tip) => tip.priority == 1).toList();
  }

  /// Retorna dicas ordenadas por prioridade
  static List<PreservationTip> getTipsByPriority() {
    List<PreservationTip> sortedTips = List.from(_preservationTips);
    sortedTips.sort((a, b) => a.priority.compareTo(b.priority));
    return sortedTips;
  }

  /// Retorna dicas específicas para um tipo de atividade
  static List<PreservationTip> getTipsForActivity(String activityType) {
    switch (activityType.toLowerCase()) {
      case 'caminhada':
        return [
          _preservationTips[0], // Não deixe lixo
          _preservationTips[2], // Use trilhas demarcadas
          _preservationTips[4], // Não retire plantas
          _preservationTips[13], // Use produtos biodegradáveis
        ];
      case 'contemplação':
        return [
          _preservationTips[0], // Não deixe lixo
          _preservationTips[1], // Respeite vida selvagem
          _preservationTips[7], // Fotografe com consciência
          _preservationTips[10], // Respeite horários
        ];
      case 'aventura':
        return [
          _preservationTips[0], // Não deixe lixo
          _preservationTips[2], // Use trilhas demarcadas
          _preservationTips[3], // Economize água
          _preservationTips[11], // Informe-se antes
        ];
      case 'cultural':
        return [
          _preservationTips[5], // Respeite patrimônio histórico
          _preservationTips[6], // Valorize cultura local
          _preservationTips[7], // Fotografe com consciência
          _preservationTips[8], // Apoie comércio local
        ];
      default:
        return getHighPriorityTips();
    }
  }

  /// Retorna estatísticas das dicas
  static Map<String, dynamic> getTipsStatistics() {
    Map<PreservationType, int> typeCount = {};
    Map<int, int> priorityCount = {};

    for (var tip in _preservationTips) {
      typeCount[tip.type] = (typeCount[tip.type] ?? 0) + 1;
      priorityCount[tip.priority] = (priorityCount[tip.priority] ?? 0) + 1;
    }

    return {
      'totalTips': _preservationTips.length,
      'typeCount': typeCount,
      'priorityCount': priorityCount,
      'highPriorityCount': priorityCount[1] ?? 0,
    };
  }
}
