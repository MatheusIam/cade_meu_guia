import 'package:latlong2/latlong.dart';
import '../../models/tour_point.dart';

/// Abstração para acesso a dados de TourPoint (local ou backend futuramente)
abstract class ITourPointRepository {
  Future<List<TourPoint>> getAll();
  Future<TourPoint?> getById(String id);
  Future<List<TourPoint>> getNearby(LatLng location, double radiusKm);
  Future<TourPoint> add(TourPoint point);
  Future<void> update(TourPoint point);
  Future<void> delete(String id);
  Future<List<TourPoint>> getChildren(String parentId);
  Future<List<TourPoint>> getMain();
  Future<TourPoint?> getParent(String childId);
}
