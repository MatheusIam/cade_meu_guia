import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/permission_helper.dart';

/// Mapa compacto reutilizável exibindo um ponto e (quando possível) a localização do usuário.
/// Agora suporta exibir ícone de categoria no pin.
class MapWidget extends StatefulWidget {
  final LatLng location;
  final double zoom;
  final double? width;
  final double? height;
  final String? activityType; // chave da atividade (pt ou en)

  const MapWidget({
    super.key,
    required this.location,
    this.zoom = 15.0,
    this.width = 300,
    this.height = 300,
    this.activityType,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  LatLng? _userLocation;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchUserLocation());
  }

  Future<void> _fetchUserLocation() async {
    if (_loading) return;
    _loading = true;
    final allowed = await PermissionHelper.ensurePreciseLocationPermission(context);
    if (!allowed) { _loading = false; return; }
    try {
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
    } catch(_) {
      // ignore
    } finally { _loading = false; }
  }

  IconData _iconForActivity(String? type){
    switch(type){
      case 'Caminhada':
      case 'hiking': return Icons.directions_walk;
      case 'Contemplação':
      case 'contemplation': return Icons.visibility;
      case 'Aventura':
      case 'adventure': return Icons.landscape;
      case 'Cultural':
      case 'cultural': return Icons.museum;
      default: return Icons.place;
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _iconForActivity(widget.activityType);
    return Center(
      child: SizedBox(
        height: widget.height,
        width: widget.width,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: widget.location,
              initialZoom: widget.zoom,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'dev.meuapp.guia_turistico',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.location,
                    width: 50,
                    height: 50,
                    child: _CategoryPin(icon: icon, color: Theme.of(context).colorScheme.primary),
                  ),
                  if(_userLocation!=null)
                    Marker(
                      point: _userLocation!,
                      width: 34,
                      height: 34,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.18),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blueAccent, width: 2),
                        ),
                        child: const Center(child: Icon(Icons.circle, size: 10, color: Colors.blueAccent)),
                      ),
                    )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPin extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _CategoryPin({required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0,4),
              )
            ],
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withOpacity(0.8)],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ],
    );
  }
}
