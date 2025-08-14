import '../../models/preservation_tip.dart';
import '../../domain/repositories/ipreservation_repository.dart';
import '../preservation_data.dart';

/// Implementação do repositório de dicas de preservação que utiliza a classe de dados estática existente.
class PreservationRepositoryImpl implements IPreservationRepository {
  @override
  Future<List<PreservationTip>> getAllTips() async {
    return await PreservationData.getAllTips();
  }

  @override
  Future<List<PreservationTip>> getHighPriorityTips() async {
    return await PreservationData.getHighPriorityTips();
  }

  @override
  Future<List<PreservationTip>> getTipsForActivity(String activityType) async {
    return await PreservationData.getTipsForActivity(activityType);
  }

  @override
  Future<List<PreservationTip>> getTipsByType(PreservationType type) async {
    return await PreservationData.getTipsByType(type);
  }

  @override
  void invalidateCache() {
    PreservationData.invalidate();
  }
}
