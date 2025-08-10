import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tour_point_rating.dart';

/// Provider para gerenciar avaliações de pontos turísticos
class RatingsProvider with ChangeNotifier {
  final List<TourPointRating> _ratings = [];
  bool _isLoaded = false;
  final Set<String> _visitedTourPoints = {}; // IDs de pontos marcados como visitados

  List<TourPointRating> get ratings => List.unmodifiable(_ratings);
  bool get isLoaded => _isLoaded;
  List<String> get visitedTourPointIds => List.unmodifiable(_visitedTourPoints);
  int get visitedCount => _visitedTourPoints.length;
  bool isTourPointVisited(String id) => _visitedTourPoints.contains(id);

  /// Carrega as avaliações salvas localmente
  Future<void> loadRatings() async {
    if (_isLoaded) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
  final ratingsJson = prefs.getStringList('tour_point_ratings') ?? [];
  final visitedIds = prefs.getStringList('visited_tour_points') ?? [];
      
      _ratings.clear();
      for (final ratingStr in ratingsJson) {
        try {
          final ratingMap = jsonDecode(ratingStr);
          final rating = TourPointRating.fromJson(ratingMap);
          _ratings.add(rating);
        } catch (e) {
          debugPrint('Erro ao carregar avaliação: $e');
        }
      }
      _visitedTourPoints
        ..clear()
        ..addAll(visitedIds);
      
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar avaliações: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Salva as avaliações localmente
  Future<void> _saveRatings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ratingsJson = _ratings
          .map((rating) => jsonEncode(rating.toJson()))
          .toList();
      await prefs.setStringList('tour_point_ratings', ratingsJson);
  await prefs.setStringList('visited_tour_points', _visitedTourPoints.toList());
    } catch (e) {
      debugPrint('Erro ao salvar avaliações: $e');
    }
  }

  /// Adiciona uma nova avaliação
  Future<void> addRating(TourPointRating rating) async {
    // Remove avaliação anterior do mesmo usuário para o mesmo ponto, se existir
    _ratings.removeWhere((r) => 
        r.tourPointId == rating.tourPointId && r.userId == rating.userId);
    
    _ratings.add(rating);
  // Marca o ponto como visitado ao avaliar (irreversível)
  _visitedTourPoints.add(rating.tourPointId);
    await _saveRatings();
    notifyListeners();
  }

  /// Remove uma avaliação
  Future<void> removeRating(String ratingId) async {
    _ratings.removeWhere((rating) => rating.id == ratingId);
    await _saveRatings();
    notifyListeners();
  }

  /// Obtém todas as avaliações de um ponto turístico
  List<TourPointRating> getRatingsForTourPoint(String tourPointId) {
    return _ratings.where((rating) => rating.tourPointId == tourPointId).toList();
  }

  /// Obtém a avaliação de um usuário específico para um ponto turístico
  TourPointRating? getUserRatingForTourPoint(String tourPointId, String userId) {
    try {
      return _ratings.firstWhere(
        (rating) => rating.tourPointId == tourPointId && rating.userId == userId
      );
    } catch (e) {
      return null;
    }
  }

  /// Verifica se um usuário já avaliou um ponto turístico
  bool hasUserRatedTourPoint(String tourPointId, String userId) {
    return getUserRatingForTourPoint(tourPointId, userId) != null;
  }

  /// Calcula a média geral das avaliações de um ponto turístico
  double getAverageRatingForTourPoint(String tourPointId) {
    final tourPointRatings = getRatingsForTourPoint(tourPointId);
    if (tourPointRatings.isEmpty) return 0.0;

    final totalRating = tourPointRatings
        .map((rating) => rating.overallRating)
        .reduce((a, b) => a + b);
    
    return totalRating / tourPointRatings.length;
  }

  /// Obtém estatísticas detalhadas de um ponto turístico
  Map<String, dynamic> getTourPointStatistics(String tourPointId) {
    final tourPointRatings = getRatingsForTourPoint(tourPointId);
    
    if (tourPointRatings.isEmpty) {
      return {
        'totalRatings': 0,
        'averageOverall': 0.0,
        'averageAccessibility': 0.0,
        'averageCleanliness': 0.0,
        'averageInfrastructure': 0.0,
        'averageSafety': 0.0,
        'averageExperience': 0.0,
        'recommendationPercentage': 0.0,
        'ratingDistribution': <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      };
    }

    final totalRatings = tourPointRatings.length;
    final ratingDistribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    
    double totalOverall = 0;
    double totalAccessibility = 0;
    double totalCleanliness = 0;
    double totalInfrastructure = 0;
    double totalSafety = 0;
    double totalExperience = 0;
    int recommendedCount = 0;

    for (final rating in tourPointRatings) {
      totalOverall += rating.overallRating;
      totalAccessibility += rating.accessibilityRating;
      totalCleanliness += rating.cleanlinessRating;
      totalInfrastructure += rating.infrastructureRating;
      totalSafety += rating.safetyRating;
      totalExperience += rating.experienceRating;
      
      if (rating.isRecommended) recommendedCount++;
      
      // Distribui por estrelas (arredonda para int)
      final starRating = rating.overallRating.round().clamp(1, 5);
      ratingDistribution[starRating] = (ratingDistribution[starRating] ?? 0) + 1;
    }

    return {
      'totalRatings': totalRatings,
      'averageOverall': totalOverall / totalRatings,
      'averageAccessibility': totalAccessibility / totalRatings,
      'averageCleanliness': totalCleanliness / totalRatings,
      'averageInfrastructure': totalInfrastructure / totalRatings,
      'averageSafety': totalSafety / totalRatings,
      'averageExperience': totalExperience / totalRatings,
      'recommendationPercentage': (recommendedCount / totalRatings) * 100,
      'ratingDistribution': ratingDistribution,
    };
  }

  /// Obtém as avaliações mais recentes (limitado a um número específico)
  List<TourPointRating> getRecentRatings({int limit = 10}) {
    final sortedRatings = List<TourPointRating>.from(_ratings);
    sortedRatings.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
    return sortedRatings.take(limit).toList();
  }

  /// Limpa todas as avaliações
  Future<void> clearAllRatings() async {
    _ratings.clear();
  // Não limpamos visitas porque visita é irreversível
    await _saveRatings();
    notifyListeners();
  }

  /// Obtém estatísticas gerais do app
  Map<String, dynamic> getGeneralStatistics() {
    if (_ratings.isEmpty) {
      return {
        'totalRatings': 0,
        'averageAppRating': 0.0,
        'totalTourPointsRated': 0,
        'mostRatedTourPointId': null,
  'visitedTourPoints': _visitedTourPoints.length,
      };
    }

    final tourPointRatingsCount = <String, int>{};
    double totalRating = 0;

    for (final rating in _ratings) {
      tourPointRatingsCount[rating.tourPointId] = 
          (tourPointRatingsCount[rating.tourPointId] ?? 0) + 1;
      totalRating += rating.overallRating;
    }

    final mostRatedEntry = tourPointRatingsCount.entries
        .reduce((a, b) => a.value > b.value ? a : b);

    return {
      'totalRatings': _ratings.length,
      'averageAppRating': totalRating / _ratings.length,
      'totalTourPointsRated': tourPointRatingsCount.length,
      'mostRatedTourPointId': mostRatedEntry.key,
      'mostRatedTourPointCount': mostRatedEntry.value,
  'visitedTourPoints': _visitedTourPoints.length,
    };
  }
}
