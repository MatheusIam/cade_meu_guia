import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider para gerenciar APENAS os IDs dos pontos turísticos favoritos.
/// A lógica de buscar os dados completos foi movida para um Caso de Uso (GetFavoriteTourPoints).
class FavoritesProvider with ChangeNotifier {
  final List<String> _favoriteIds = [];
  bool _isLoaded = false;

  List<String> get favoriteIds => List.unmodifiable(_favoriteIds);
  bool get isLoaded => _isLoaded;
  bool get hasFavorites => _favoriteIds.isNotEmpty;
  int get favoritesCount => _favoriteIds.length;

  /// Carrega os IDs de favoritos salvos localmente.
  Future<void> loadFavorites() async {
    if (_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedFavorites = prefs.getStringList('favorite_tour_points') ?? [];
      _favoriteIds.clear();
      _favoriteIds.addAll(savedFavorites);
    } catch (e) {
      debugPrint('Erro ao carregar favoritos: $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Salva os IDs de favoritos localmente.
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorite_tour_points', _favoriteIds);
    } catch (e) {
      debugPrint('Erro ao salvar favoritos: $e');
    }
  }

  bool isFavorite(String tourPointId) => _favoriteIds.contains(tourPointId);

  Future<void> toggleFavorite(String tourPointId) async {
    if (isFavorite(tourPointId)) {
      _favoriteIds.remove(tourPointId);
    } else {
      _favoriteIds.add(tourPointId);
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
}
