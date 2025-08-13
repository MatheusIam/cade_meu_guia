import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../repositories/tour_point_repository.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/permission_helper.dart';
import '../models/tour_point.dart';
import '../data/tour_points_data.dart';

class AddTourPointScreen extends StatefulWidget {
  final LatLng? initialCenter;
  final double? initialZoom;
  const AddTourPointScreen({super.key, this.initialCenter, this.initialZoom});

  @override
  State<AddTourPointScreen> createState() => _AddTourPointScreenState();
}

class _AddTourPointScreenState extends State<AddTourPointScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final MapController _mapController = MapController();
  late LatLng _current; // definido no init
  LatLng? _userLocation; // posição real do usuário para exibir no mapa
  bool _locating = false;
  bool _permissionDenied = false;
  String? _selectedParentAreaId; // área pai opcional
  List<TourPoint> _areas = [];
  bool _loadingAreas = true;

  Future<void> _getUserLocation() async {
    final allowed = await PermissionHelper.ensurePreciseLocationPermission(context);
    if (!allowed) return;
    setState(() { _locating = true; _permissionDenied = false; });
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() { _permissionDenied = true; });
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final latlng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _current = latlng;
  _userLocation = latlng;
        _latCtrl.text = latlng.latitude.toStringAsFixed(6);
        _lngCtrl.text = latlng.longitude.toStringAsFixed(6);
        _mapController.move(latlng, 16);
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() { _locating = false; });
    }
  }
  final _photosCtrl = TextEditingController(text: '0');
  double _rating = 0.0;
  String _activityType = 'hiking';
  bool _saving = false;

  final List<String> _activityTypes = const [
    'hiking',
    'contemplation',
    'adventure',
    'cultural',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _photosCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _current = widget.initialCenter ?? LatLng(2.8235, -60.6758);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadAreas();
  // tenta obter localização só para exibir marcador do usuário
  await _getUserLocation();
    });
  }

  Future<void> _loadAreas() async {
    try {
      setState(() => _loadingAreas = true);
      final repo = context.read<ITourPointRepository>();
      final list = await repo.getMain();
      setState(() {
        // apenas itens considerados área
        _areas = list.where((a) => a.isArea).toList();
      });
    } finally {
      if (mounted) setState(() => _loadingAreas = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final id = const Uuid().v4();
      final lat = double.tryParse(_latCtrl.text) ?? 0.0;
      final lng = double.tryParse(_lngCtrl.text) ?? 0.0;
      final photos = int.tryParse(_photosCtrl.text) ?? 0;
      final point = TourPoint(
        id: id,
        name: _nameCtrl.text.trim(),
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        location: LatLng(lat, lng),
        rating: _rating,
        photoCount: photos,
        activityType: _activityType,
        images: const [],
  parentId: _selectedParentAreaId,
      );
      await TourPointsData.addTourPoint(point);
      if (mounted) {
        Navigator.pop(context, point);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('tour_point_added'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'error_saving'.tr()}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  appBar: AppBar(title: Text('new_tour_point'.tr())),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
      decoration: InputDecoration(labelText: 'short_name'.tr()),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'enter_name'.tr() : null,
            ),
            const SizedBox(height: 12),
            _buildParentAreaDropdown(),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleCtrl,
      decoration: InputDecoration(labelText: 'title_label'.tr()),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'enter_title'.tr() : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
      decoration: InputDecoration(labelText: 'description_label'.tr()),
              maxLines: 4,
      validator: (v) => (v == null || v.trim().length < 10) ? 'description_too_short'.tr() : null,
            ),
            const SizedBox(height: 12),
            Text(
      'select_location_on_map'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _current,
                        initialZoom: widget.initialZoom ?? 14,
                        onPositionChanged: (pos, _) {
                          final center = pos.center;
                          setState(() {
                            _current = center;
                            _latCtrl.text = center.latitude.toStringAsFixed(6);
                            _lngCtrl.text = center.longitude.toStringAsFixed(6);
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'dev.meuapp.guia_turistico',
                        ),
                        // Sobreposição das áreas existentes (contexto visual)
                        if (_areas.any((a) => (a.polygon?.length ?? 0) >= 3))
                          PolygonLayer(
                            polygons: [
                              for (final area in _areas)
                                if ((area.polygon?.length ?? 0) >= 3)
                                  Polygon(
                                    points: area.polygon!,
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                                    borderColor: Theme.of(context).colorScheme.primary.withOpacity(0.35),
                                    borderStrokeWidth: 2,
                                  ),
                            ],
                          ),
                        if (_userLocation != null)
                          MarkerLayer(markers: [
                            Marker(
                              point: _userLocation!,
                              width: 28,
                              height: 28,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.circle, size: 12, color: Colors.blue),
                              ),
                            ),
                          ]),
                      ],
                    ),
                    // Marcador fixo no centro
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.location_pin, size: 46, color: Colors.red),
                        ],
                      ),
                    ),
                    // Lupa (zoom preview) canto superior esquerdo
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: FlutterMap(
                          mapController: MapController(),
                          options: MapOptions(
                            initialCenter: _current,
                            initialZoom: 17,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'dev.meuapp.guia_turistico',
                            ),
                            MarkerLayer(markers:[
                              Marker(point: _current, width: 20, height: 20, child: const Icon(Icons.location_pin, size: 20, color: Colors.red)),
                              if (_userLocation != null)
                                Marker(point: _userLocation!, width: 16, height: 16, child: const Icon(Icons.circle, size: 16, color: Colors.blue)),
                            ])
                          ],
                        ),
                      ),
                    ),
                    // Botões overlay
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Column(
                        children: [
                          FloatingActionButton.small(
                            heroTag: 'locate',
                            onPressed: _locating ? null : _getUserLocation,
                            child: _locating ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.my_location),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton.small(
                            heroTag: 'zoom_in',
                            onPressed: () => _mapController.move(_current, _mapController.camera.zoom + 1),
                            child: const Icon(Icons.add),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton.small(
                            heroTag: 'zoom_out',
                            onPressed: () => _mapController.move(_current, _mapController.camera.zoom - 1),
                            child: const Icon(Icons.remove),
                          ),
                        ],
                      ),
                    ),
                    if (_permissionDenied)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Material(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('location_permission_denied'.tr(), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextFormField(
                  controller: _latCtrl,
                  decoration: InputDecoration(labelText: 'latitude'.tr()),
                  readOnly: true,
                )),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  controller: _lngCtrl,
                  decoration: InputDecoration(labelText: 'longitude'.tr()),
                  readOnly: true,
                )),
                IconButton(
                  icon: const Icon(Icons.my_location),
                  tooltip: 'center_marker'.tr(),
                  onPressed: () {
                    _mapController.move(_current, _mapController.camera.zoom);
                  },
                )
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _activityType,
              decoration: InputDecoration(labelText: 'activity_type'.tr()),
              items: _activityTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.tr())))
                  .toList(),
              onChanged: (v) => setState(() => _activityType = v ?? _activityType),
            ),
            const SizedBox(height: 12),
            Text('${'initial_rating'.tr()}: ${_rating.toStringAsFixed(1)}'),
            Slider(
              value: _rating,
              min: 0,
              max: 5,
              divisions: 50,
              label: _rating.toStringAsFixed(1),
              onChanged: (val) => setState(() => _rating = val),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _photosCtrl,
              decoration: InputDecoration(labelText: 'photos_quantity_hint'.tr()),
              keyboardType: TextInputType.number,
              validator: (v) => (int.tryParse(v ?? '') == null) ? 'invalid_number'.tr() : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_saving ? 'saving'.tr() : 'save'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParentAreaDropdown() {
    if (_loadingAreas) {
      return Row(
        children: [
          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 12),
          Text('loading_areas'.tr()),
        ],
      );
    }
    if (_areas.isEmpty) {
      return Text('no_areas_available'.tr(), style: Theme.of(context).textTheme.bodySmall);
    }
    return DropdownButtonFormField<String?> (
      value: _selectedParentAreaId,
      decoration: InputDecoration(labelText: 'link_to_area'.tr()),
      items: [
        DropdownMenuItem<String?>(value: null, child: Text('no_parent'.tr())),
        ..._areas.map((a) => DropdownMenuItem<String?>(
              value: a.id,
              child: Text(a.name, overflow: TextOverflow.ellipsis),
            )),
      ],
      onChanged: (v) => setState(() => _selectedParentAreaId = v),
    );
  }
}
