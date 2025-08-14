import '../../models/tour_point.dart';
import '../repositories/itour_point_repository.dart';

// Caso de uso para obter a lista completa de TourPoints que estão nos favoritos.
class GetFavoriteTourPoints {
  final ITourPointRepository _tourPointRepository;

  GetFavoriteTourPoints(this._tourPointRepository);

  // Este caso de uso recebe os IDs dos favoritos e retorna os objetos TourPoint completos.
  Future<List<TourPoint>> call(List<String> favoriteIds) async {
    if (favoriteIds.isEmpty) {
      return [];
    }
    // Obtém todos os pontos. Em um cenário com API, aqui poderia haver uma otimização
    // para buscar apenas os pontos com os IDs fornecidos.
    final allPoints = await _tourPointRepository.getAll();
    final favoriteIdsSet = favoriteIds.toSet();
    
    return allPoints.where((point) => favoriteIdsSet.contains(point.id)).toList();
  }
}