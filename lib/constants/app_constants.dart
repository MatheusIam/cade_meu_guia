import 'package:latlong2/latlong.dart';

/// Constantes utilizadas em todo o aplicativo
class AppConstants {
  // Informações do app
  static const String appName = 'Cade Meu Guia';
  static const String appVersion = '1.0.0';
  static const String userAgent = 'dev.meuapp.guia_turistico';

  // Coordenadas padrão (Boa Vista - RR)
  static const LatLng defaultLocation = LatLng(2.8235, -60.6758);
  static const double defaultZoom = 13.0;
  static const double detailZoom = 16.0;
  static const double minZoom = 10.0;
  static const double maxZoom = 18.0;

  // Raios de busca em km
  static const double nearbyRadius = 5.0;
  static const double searchRadius = 10.0;

  // URLs e endpoints
  static const String mapTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  // Configurações de UI
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  static const double defaultBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 20.0;

  // Durações de animação
  static const Duration shortAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 600);

  // Tamanhos de imagem
  static const double markerSize = 40.0;
  static const double iconSize = 24.0;
  static const double largeIconSize = 60.0;

  // Limites
  static const int maxNearbyPoints = 5;
  static const int maxSearchResults = 20;
  static const int maxImageGallerySize = 10;

  // Chaves para SharedPreferences
  static const String themeKey = 'app_theme';
  static const String favoritesKey = 'favorite_points';
  static const String lastLocationKey = 'last_location';

  // Mensagens
  static const String noPointsFound = 'Nenhum ponto turístico encontrado';
  static const String noImagesAvailable = 'Nenhuma imagem disponível';
  static const String locationShared = 'Localização compartilhada!';
  static const String addedToFavorites = 'Adicionado aos favoritos';
  static const String removedFromFavorites = 'Removido dos favoritos';
  static const String openingDirections = 'Abrindo direções...';

  // Categorias de atividades
  static const List<String> activityTypes = [
    'Todos',
    'Caminhada',
    'Contemplação',
    'Aventura',
    'Cultural',
  ];

  // Assets paths (para quando as imagens forem adicionadas)
  static const String assetsPath = 'assets/images/';
  static const String iconsPath = 'assets/icons/';
}
