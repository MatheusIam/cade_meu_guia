import 'package:latlong2/latlong.dart';
import '../../data/tour_points_data.dart';
import '../../models/tour_point.dart';
import '../../domain/repositories/itour_point_repository.dart';

/// Implementação baseada no armazenamento local existente (SharedPreferences + lista embutida)
class LocalTourPointRepositoryImpl implements ITourPointRepository {
  @override
  Future<TourPoint> add(TourPoint point) async {
    return await TourPointsData.addTourPoint(point);
  }

  @override
  Future<void> delete(String id) async {
    await TourPointsData.deleteTourPoint(id);
  }

  @override
  Future<List<TourPoint>> getAll() async {
    return await TourPointsData.getAllTourPointsAsync();
  }

  @override
  Future<TourPoint?> getById(String id) async {
    return TourPointsData.getTourPointById(id);
  }

  @override
  Future<List<TourPoint>> getNearby(LatLng location, double radiusKm) async {
    return TourPointsData.getNearbyTourPoints(location, radiusKm);
  }

  @override
  Future<void> update(TourPoint point) async {
    await TourPointsData.updateTourPoint(point);
  }

  @override
  Future<List<TourPoint>> getChildren(String parentId) async {
    return TourPointsData.getChildPoints(parentId);
  }

  @override
  Future<List<TourPoint>> getMain() async {
    return TourPointsData.getMainTourPoints();
  }

  @override
  Future<TourPoint?> getParent(String childId) async {
    return TourPointsData.getParentPoint(childId);
  }
}