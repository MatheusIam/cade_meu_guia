import 'package:latlong2/latlong.dart';
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

  /// Retorna todos os pontos turísticos
  static List<TourPoint> getAllTourPoints() {
    return List.unmodifiable(_tourPoints);
  }

  /// Busca pontos turísticos por nome ou título
  static List<TourPoint> searchTourPoints(String query) {
    if (query.isEmpty) return getAllTourPoints();

    return _tourPoints.where((point) {
      return point.name.toLowerCase().contains(query.toLowerCase()) ||
          point.title.toLowerCase().contains(query.toLowerCase()) ||
          point.description.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  /// Filtra pontos turísticos por tipo de atividade
  static List<TourPoint> filterByActivity(String activityType) {
    if (activityType == 'Todos') return getAllTourPoints();

    return _tourPoints.where((point) {
      return point.activityType == activityType;
    }).toList();
  }

  /// Retorna pontos turísticos próximos a uma localização
  static List<TourPoint> getNearbyTourPoints(LatLng location, double radiusKm) {
    const Distance distance = Distance();

    return _tourPoints.where((point) {
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
      return _tourPoints.firstWhere((point) => point.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Retorna pontos turísticos ordenados por avaliação
  static List<TourPoint> getTourPointsByRating() {
    List<TourPoint> sortedPoints = List.from(_tourPoints);
    sortedPoints.sort((a, b) => b.rating.compareTo(a.rating));
    return sortedPoints;
  }

  /// Retorna tipos de atividades únicos
  static List<String> getActivityTypes() {
    Set<String> types = _tourPoints.map((point) => point.activityType).toSet();
    types.add('Todos');
    return types.toList()..sort();
  }

  /// Retorna estatísticas dos pontos turísticos
  static Map<String, dynamic> getStatistics() {
    double avgRating =
        _tourPoints.fold(0.0, (sum, point) => sum + point.rating) /
        _tourPoints.length;
    int totalPhotos = _tourPoints.fold(
      0,
      (sum, point) => sum + point.photoCount,
    );

    Map<String, int> activityCounts = {};
    for (var point in _tourPoints) {
      activityCounts[point.activityType] =
          (activityCounts[point.activityType] ?? 0) + 1;
    }

    return {
      'totalPoints': _tourPoints.length,
      'averageRating': double.parse(avgRating.toStringAsFixed(1)),
      'totalPhotos': totalPhotos,
      'activityCounts': activityCounts,
      'highestRated': _tourPoints.reduce((a, b) => a.rating > b.rating ? a : b),
      'mostPhotos': _tourPoints.reduce(
        (a, b) => a.photoCount > b.photoCount ? a : b,
      ),
    };
  }
}
