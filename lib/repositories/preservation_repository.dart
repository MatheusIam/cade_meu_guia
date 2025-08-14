import '../models/preservation_tip.dart';

/// Contrato (Abstração) para acesso a dados de dicas de preservação.
abstract class IPreservationRepository {
  /// Retorna todas as dicas de preservação, ordenadas por prioridade.
  Future<List<PreservationTip>> getAllTips();

  /// Retorna dicas filtradas por um tipo específico.
  Future<List<PreservationTip>> getTipsByType(PreservationType type);

  /// Retorna dicas de alta prioridade.
  Future<List<PreservationTip>> getHighPriorityTips();

  /// Retorna dicas relevantes para um determinado tipo de atividade.
  Future<List<PreservationTip>> getTipsForActivity(String activityType);
}