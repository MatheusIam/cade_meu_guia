import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tour_point.dart';
import '../data/tour_points_data.dart';

/// Provider para gerenciar pontos turísticos favoritos
class FavoritesProvider with ChangeNotifier {
  final List<String> _favoriteIds = [];
  bool _isLoaded = false;

  List<String> get favoriteIds => List.unmodifiable(_favoriteIds);

  bool get isLoaded => _isLoaded;

  /// Carrega os favoritos salvos localmente
  Future<void> loadFavorites() async {
    if (_isLoaded) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedFavorites = prefs.getStringList('favorite_tour_points') ?? [];
      _favoriteIds.clear();
      _favoriteIds.addAll(savedFavorites);
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar favoritos: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Salva os favoritos localmente
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorite_tour_points', _favoriteIds);
    } catch (e) {
      debugPrint('Erro ao salvar favoritos: $e');
    }
  }

  bool isFavorite(String tourPointId) {
    return _favoriteIds.contains(tourPointId);
  }

  Future<void> toggleFavorite(TourPoint tourPoint) async {
    if (isFavorite(tourPoint.id)) {
      _favoriteIds.remove(tourPoint.id);
    } else {
      _favoriteIds.add(tourPoint.id);
    }
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> addFavorite(String tourPointId) async {
    if (!isFavorite(tourPointId)) {
      _favoriteIds.add(tourPointId);
      await _saveFavorites();
      notifyListeners();
    }
  }

  Future<void> removeFavorite(String tourPointId) async {
    if (isFavorite(tourPointId)) {
      _favoriteIds.remove(tourPointId);
      await _saveFavorites();
      notifyListeners();
    }
  }

  Future<void> clearAllFavorites() async {
    _favoriteIds.clear();
    await _saveFavorites();
    notifyListeners();
  }

  /// Retorna a lista de pontos turísticos favoritos
  List<TourPoint> getFavoriteTourPoints() {
    final allTourPoints = TourPointsData.getAllTourPoints();
    return allTourPoints.where((point) => isFavorite(point.id)).toList();
  }

  /// Retorna favoritos ordenados por data de adição (mais recentes primeiro)
  List<TourPoint> getFavoriteTourPointsSorted() {
    final favorites = getFavoriteTourPoints();
    // Como não temos data de adição, vamos ordenar por rating decrescente
    favorites.sort((a, b) => b.rating.compareTo(a.rating));
    return favorites;
  }

  /// Verifica se existem favoritos
  bool get hasFavorites => _favoriteIds.isNotEmpty;

  int get favoritesCount => _favoriteIds.length;

  /// Estatísticas dos favoritos
  Map<String, dynamic> getFavoritesStatistics() {
    final favorites = getFavoriteTourPoints();
    if (favorites.isEmpty) {
      return {
        'totalFavorites': 0,
        'averageRating': 0.0,
        'mostCommonActivity': 'Nenhum',
        'activitiesCount': <String, int>{},
      };
    }

    final activitiesCount = <String, int>{};
    double totalRating = 0;

    for (final point in favorites) {
      activitiesCount[point.activityType] = 
          (activitiesCount[point.activityType] ?? 0) + 1;
      totalRating += point.rating;
    }

    final mostCommonActivity = activitiesCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return {
      'totalFavorites': favorites.length,
      'averageRating': totalRating / favorites.length,
      'mostCommonActivity': mostCommonActivity,
      'activitiesCount': activitiesCount,
    };
  }
}
