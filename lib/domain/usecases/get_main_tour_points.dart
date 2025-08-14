import '../../models/tour_point.dart';
import '../repositories/itour_point_repository.dart';

// Caso de uso para obter apenas os pontos turísticos principais (não sub-pontos).
class GetMainTourPoints {
  final ITourPointRepository repository;

  GetMainTourPoints(this.repository);

  Future<List<TourPoint>> call() async {
    return await repository.getMain();
  }
}
