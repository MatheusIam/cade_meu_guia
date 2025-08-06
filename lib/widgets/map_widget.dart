import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapWidget extends StatelessWidget {
  final LatLng location;
  final double zoom;
  final double? width;
  final double? height;

  const MapWidget({
    super.key,
    required this.location,
    this.zoom = 15.0,
    this.width = 300,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: height,
        width: width,
        // O ClipRRect é usado para aplicar as bordas arredondadas ao seu filho (o mapa).
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: FlutterMap(
            options: MapOptions(
              // Coordenadas iniciais do mapa.
              initialCenter: location,
              initialZoom: zoom,
            ),
            children: [
              // Camada de "tiles" que compõem a imagem do mapa.
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'dev.meuapp.guia_turistico',
              ),
              // Camada de marcadores (pins) do mapa.
              MarkerLayer(
                markers: [
                  Marker(
                    point: location,
                    width: 50.0,
                    height: 50.0,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Sombra do pin
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                        // Pin principal
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            Icons.place,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        // Pulso animado (opcional - não vou adicionar aqui para manter simples)
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
