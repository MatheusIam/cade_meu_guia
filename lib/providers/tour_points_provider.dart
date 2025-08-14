import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/tour_point.dart';
import '../repositories/tour_point_repository.dart';
import '../data/tour_points_data.dart';

/// Provider reativo para pontos turísticos, centralizando acesso via repositório
class TourPointsProvider with ChangeNotifier {
  final ITourPointRepository _repo;
  TourPointsProvider(this._repo);

  final List<TourPoint> _all = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<TourPoint> get all => List.unmodifiable(_all);
  List<TourPoint> get main => _all.where((p) => p.parentId == null).toList();

  Future<void> load() async {
    if (_isLoaded && _all.isNotEmpty) return;
    final list = await _repo.getAll();
    _all
      ..clear()
      ..addAll(list);
    _isLoaded = true;
    notifyListeners();
  }

  Future<TourPoint> addPoint(TourPoint point) async {
    final added = await _repo.add(point);
    _upsertLocal(added);
    return added;
  }

  Future<void> updatePoint(TourPoint point) async {
    await _repo.update(point);
    _upsertLocal(point);
  }

  Future<void> deletePoint(String id) async {
    await _repo.delete(id);
    _all.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  TourPoint? getById(String id) {
    try {
      return _all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  List<TourPoint> childrenOf(String parentId) {
    final parent = getById(parentId);
    if (parent == null) return const [];
    if (parent.childPointIds.isNotEmpty) {
      final ids = parent.childPointIds.toSet();
      return _all.where((p) => ids.contains(p.id)).toList();
    }
    // fallback: por parentId
    return _all.where((p) => p.parentId == parentId).toList();
  }

  TourPoint? parentOf(String childId) {
    final child = getById(childId);
    if (child == null || child.parentId == null) return null;
    return getById(child.parentId!);
  }

  bool isCustom(String id) => TourPointsData.isCustomPoint(id);

  List<TourPoint> nearby(LatLng location, double radiusKm) {
    const distance = Distance();
    return _all
        .where((p) => distance.as(LengthUnit.Kilometer, location, p.location) <= radiusKm)
        .toList();
  }

  Map<String, dynamic> getStatistics() {
    final list = _all;
    if (list.isEmpty) {
      return {
        'totalPoints': 0,
        'averageRating': 0.0,
        'totalPhotos': 0,
        'activityCounts': <String, int>{},
        'highestRated': null,
        'mostPhotos': null,
      };
    }
    final avg = list.fold<double>(0, (s, p) => s + p.rating) / list.length;
    final totalPhotos = list.fold<int>(0, (s, p) => s + p.photoCount);
    final activityCounts = <String, int>{};
    for (final p in list) {
      activityCounts[p.activityType] = (activityCounts[p.activityType] ?? 0) + 1;
    }
    final highestRated = list.reduce((a, b) => a.rating >= b.rating ? a : b);
    final mostPhotos = list.reduce((a, b) => a.photoCount >= b.photoCount ? a : b);
    return {
      'totalPoints': list.length,
      'averageRating': double.parse(avg.toStringAsFixed(1)),
      'totalPhotos': totalPhotos,
      'activityCounts': activityCounts,
      'highestRated': highestRated,
      'mostPhotos': mostPhotos,
    };
  }

  void _upsertLocal(TourPoint p) {
    final i = _all.indexWhere((e) => e.id == p.id);
    if (i == -1) {
      _all.add(p);
    } else {
      _all[i] = p;
    }
    notifyListeners();
  }
}
