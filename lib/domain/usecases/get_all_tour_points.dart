import '../../models/tour_point.dart';
import '../repositories/itour_point_repository.dart';

// Caso de uso para obter todos os pontos turísticos.
class GetAllTourPoints {
  final ITourPointRepository repository;

  GetAllTourPoints(this.repository);

  // Um caso de uso deve ter um método público, geralmente chamado 'call' ou 'execute'.
  Future<List<TourPoint>> call() async {
    return await repository.getAll();
  }
}