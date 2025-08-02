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
                    width: 40.0,
                    height: 40.0,
                    child: Icon(
                      Icons.location_pin,
                      color: Theme.of(context).colorScheme.error, // Using error color for emphasis
                      size: 40.0,
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
