import 'package:flutter/material.dart';
import '../models/tour_point.dart';

/// Provider para gerenciar pontos turísticos favoritos
class FavoritesProvider with ChangeNotifier {
  final List<String> _favoriteIds = [];

  List<String> get favoriteIds => List.unmodifiable(_favoriteIds);

  bool isFavorite(String tourPointId) {
    return _favoriteIds.contains(tourPointId);
  }

  void toggleFavorite(TourPoint tourPoint) {
    if (isFavorite(tourPoint.id)) {
      _favoriteIds.remove(tourPoint.id);
    } else {
      _favoriteIds.add(tourPoint.id);
    }
    notifyListeners();
  }

  void addFavorite(String tourPointId) {
    if (!isFavorite(tourPointId)) {
      _favoriteIds.add(tourPointId);
      notifyListeners();
    }
  }

  void removeFavorite(String tourPointId) {
    if (isFavorite(tourPointId)) {
      _favoriteIds.remove(tourPointId);
      notifyListeners();
    }
  }

  void clearAllFavorites() {
    _favoriteIds.clear();
    notifyListeners();
  }

  int get favoritesCount => _favoriteIds.length;
}
