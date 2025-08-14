import 'package:latlong2/latlong.dart';

/// Constantes globais e de baixo nível da aplicação.
class AppConstants {
  // Informações do app
  static const String appName = 'Cade Meu Guia';
  static const String appVersion = '1.0.0';
  static const String userAgent = 'dev.meuapp.guia_turistico';

  // Coordenadas padrão (Boa Vista - RR) para inicialização do mapa
  static const LatLng defaultLocation = LatLng(2.8235, -60.6758);
  static const double defaultZoom = 13.0;

  // URLs e Endpoints
  static const String mapTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
}
