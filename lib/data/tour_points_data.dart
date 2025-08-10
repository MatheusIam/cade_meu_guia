import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tour_point.dart';

/// Classe responsável por fornecer dados dos pontos turísticos
class TourPointsData {
  static final List<TourPoint> _tourPoints = [
    const TourPoint(
      id: '1',
      name: 'Orla Taumanã',
      title: 'Cartão-postal de Boa Vista',
      description:
          'A Orla Taumanã é um dos principais pontos turísticos de Boa Vista, capital de Roraima. Localizada às margens do Rio Branco, oferece uma vista espetacular e é ideal para caminhadas, contemplação do pôr do sol e atividades de lazer.',
      location: LatLng(2.8136499, -60.6686363),
      rating: 4.7,
      photoCount: 850,
      activityType: 'Caminhada',
      images: [
        'assets/images/orla_taumana_1.jpg',
        'assets/images/orla_taumana_2.jpg',
        'assets/images/orla_taumana_3.jpg',
      ],
    ),
    const TourPoint(
      id: '2',
      name: 'Parque do Rio Branco',
      title: 'Natureza e Lazer',
      description:
          'Um parque urbano que oferece contato direto com a natureza, ideal para famílias e pessoas que buscam um momento de tranquilidade. Possui trilhas ecológicas, playground e áreas para piquenique.',
      location: LatLng(2.81, -60.67),
      rating: 4.5,
      photoCount: 320,
      activityType: 'Contemplação',
      images: [
        'assets/images/parque_rio_branco_1.jpg',
        'assets/images/parque_rio_branco_2.jpg',
      ],
    ),
    const TourPoint(
      id: '3',
      name: 'Memorial dos Pioneiros',
      title: 'História de Roraima',
      description:
          'Memorial que conta a história dos primeiros colonizadores de Roraima. Um local rico em cultura e história, com exposições permanentes e temporárias sobre a região.',
      location: LatLng(2.8136, -60.6689),
      rating: 4.3,
      photoCount: 180,
      activityType: 'Cultural',
      images: [
        'assets/images/memorial_pioneiros_1.jpg',
        'assets/images/memorial_pioneiros_2.jpg',
      ],
    ),
    const TourPoint(
      id: '4',
      name: 'Casa da Cultura',
      title: 'Centro Cultural de Boa Vista',
      description:
          'Espaço dedicado às manifestações culturais locais, com apresentações de dança, teatro, música e exposições de arte. Um importante centro de preservação e difusão da cultura roraimense.',
      // As coordenadas para a Casa da Cultura não puderam ser verificadas com precisão.
      // As coordenadas originais foram mantidas.
      location: LatLng(2.8210, -60.6735),
      rating: 4.4,
      photoCount: 265,
      activityType: 'Cultural',
      images: [
        'assets/images/casa_cultura_1.jpg',
        'assets/images/casa_cultura_2.jpg',
        'assets/images/casa_cultura_3.jpg',
      ],
    ),
    const TourPoint(
      id: '5',
      name: 'Parque Anauá',
      title: 'Maior Parque Urbano',
      description:
          'O maior parque urbano de Boa Vista, oferecendo diversas atividades de lazer e esporte. Possui lagos, trilhas para caminhada, ciclovia, quadras esportivas e uma rica fauna e flora.',
      location: LatLng(2.84, -60.68),
      rating: 4.6,
      photoCount: 1200,
      activityType: 'Aventura',
      images: [
        'assets/images/parque_anaua_1.jpg',
        'assets/images/parque_anaua_2.jpg',
        'assets/images/parque_anaua_3.jpg',
        'assets/images/parque_anaua_4.jpg',
      ],
    ),
    const TourPoint(
      id: '6',
      name: 'Mercado dos Pescadores',
      title: 'Sabores Regionais',
      description:
          'Tradicional mercado onde é possível encontrar peixes frescos da região, além de pratos típicos da culinária local. Uma experiência gastronômica autêntica de Roraima.',
      location: LatLng(2.85, -60.72),
      rating: 4.2,
      photoCount: 145,
      activityType: 'Cultural',
      images: [
        'assets/images/mercado_pescadores_1.jpg',
        'assets/images/mercado_pescadores_2.jpg',
      ],
    ),
    const TourPoint(
      id: '7',
      name: 'Praia Grande',
      title: 'Praia de Água Doce',
      description:
          'Uma das principais praias de água doce de Boa Vista, formada durante o período de seca do Rio Branco. Local popular para banhos e esportes aquáticos.',
      location: LatLng(2.82, -60.65),
      rating: 4.5,
      photoCount: 680,
      activityType: 'Aventura',
      images: [
        'assets/images/praia_grande_1.jpg',
        'assets/images/praia_grande_2.jpg',
        'assets/images/praia_grande_3.jpg',
      ],
    ),
    const TourPoint(
      id: '8',
      name: 'Estádio Flamarion Vasconcelos',
      title: 'Canarinho',
      description:
          'Principal estádio de futebol de Roraima, conhecido carinhosamente como Canarinho. Palco de grandes jogos e eventos esportivos do estado.',
      location: LatLng(2.83, -60.66),
      rating: 4.1,
      photoCount: 95,
      activityType: 'Contemplação',
      images: ['assets/images/estadio_canarinho_1.jpg'],
    ),
  ];

  static final List<TourPoint> _customTourPoints = []; // adicionados pelo usuário
  static bool _loadedCustom = false;

  static Future<void> _loadCustomPoints() async {
    if (_loadedCustom) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList('custom_tour_points') ?? [];
      for (final jsonStr in stored) {
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
            _customTourPoints.add(TourPoint.fromMap(map));
        } catch (_) {}
      }
    } finally {
      _loadedCustom = true;
    }
  }

  static Future<void> _saveCustomPoints() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _customTourPoints.map((p) => jsonEncode(p.toMap())).toList();
    await prefs.setStringList('custom_tour_points', list);
  }

  static Future<TourPoint> addTourPoint(TourPoint point) async {
    await _loadCustomPoints();
    _customTourPoints.add(point);
    await _saveCustomPoints();
    return point;
  }

  static Future<void> updateTourPoint(TourPoint point) async {
    await _loadCustomPoints();
    final index = _customTourPoints.indexWhere((p) => p.id == point.id);
    if (index != -1) {
      _customTourPoints[index] = point;
      await _saveCustomPoints();
    }
  }

  static Future<void> deleteTourPoint(String id) async {
    await _loadCustomPoints();
    _customTourPoints.removeWhere((p) => p.id == id);
    await _saveCustomPoints();
  }

  static bool isCustomPoint(String id) {
    return _customTourPoints.any((p) => p.id == id);
  }

  /// Retorna todos os pontos turísticos
  static Future<List<TourPoint>> getAllTourPointsAsync() async {
    await _loadCustomPoints();
    return List.unmodifiable([..._tourPoints, ..._customTourPoints]);
  }

  // Mantém compatibilidade síncrona (sem garantir incluir custom imediatamente)
  static List<TourPoint> getAllTourPoints() {
    return List.unmodifiable([..._tourPoints, ..._customTourPoints]);
  }

  /// Busca pontos turísticos por nome ou título
  static List<TourPoint> searchTourPoints(String query) {
    if (query.isEmpty) return getAllTourPoints();

  return getAllTourPoints().where((point) {
      return point.name.toLowerCase().contains(query.toLowerCase()) ||
          point.title.toLowerCase().contains(query.toLowerCase()) ||
          point.description.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  /// Filtra pontos turísticos por tipo de atividade
  static List<TourPoint> filterByActivity(String activityType) {
    if (activityType == 'Todos') return getAllTourPoints();

  return getAllTourPoints().where((point) {
      return point.activityType == activityType;
    }).toList();
  }

  /// Retorna pontos turísticos próximos a uma localização
  static List<TourPoint> getNearbyTourPoints(LatLng location, double radiusKm) {
    const Distance distance = Distance();

  return getAllTourPoints().where((point) {
      double distanceKm = distance.as(
        LengthUnit.Kilometer,
        location,
        point.location,
      );
      return distanceKm <= radiusKm;
    }).toList();
  }

  /// Retorna um ponto turístico por ID
  static TourPoint? getTourPointById(String id) {
    try {
      return getAllTourPoints().firstWhere((point) => point.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Retorna pontos turísticos ordenados por avaliação
  static List<TourPoint> getTourPointsByRating() {
  List<TourPoint> sortedPoints = List.from(getAllTourPoints());
    sortedPoints.sort((a, b) => b.rating.compareTo(a.rating));
    return sortedPoints;
  }

  /// Retorna tipos de atividades únicos
  static List<String> getActivityTypes() {
  Set<String> types = getAllTourPoints().map((point) => point.activityType).toSet();
    types.add('Todos');
    return types.toList()..sort();
  }

  /// Retorna estatísticas dos pontos turísticos
  static Map<String, dynamic> getStatistics() {
    final all = getAllTourPoints();
    if (all.isEmpty) {
      return {
        'totalPoints': 0,
        'averageRating': 0.0,
        'totalPhotos': 0,
        'activityCounts': <String, int>{},
        'highestRated': null,
        'mostPhotos': null,
      };
    }
    double avgRating =
        all.fold(0.0, (sum, point) => sum + point.rating) /
        all.length;
    int totalPhotos = all.fold(
      0,
      (sum, point) => sum + point.photoCount,
    );

    Map<String, int> activityCounts = {};
    for (var point in all) {
      activityCounts[point.activityType] =
          (activityCounts[point.activityType] ?? 0) + 1;
    }

    return {
      'totalPoints': all.length,
      'averageRating': double.parse(avgRating.toStringAsFixed(1)),
      'totalPhotos': totalPhotos,
      'activityCounts': activityCounts,
      'highestRated': all.reduce((a, b) => a.rating > b.rating ? a : b),
      'mostPhotos': all.reduce(
        (a, b) => a.photoCount > b.photoCount ? a : b,
      ),
    };
  }
}
