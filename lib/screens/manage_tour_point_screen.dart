import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/permission_helper.dart';
import '../models/tour_point.dart';
import '../data/tour_points_data.dart';
import 'package:provider/provider.dart';
import '../repositories/tour_point_repository.dart';

class ManageTourPointScreen extends StatefulWidget {
  final TourPoint? existing;
  final LatLng? initialCenter;
  final double? initialZoom;
  const ManageTourPointScreen({super.key, this.existing, this.initialCenter, this.initialZoom});

  @override
  State<ManageTourPointScreen> createState() => _ManageTourPointScreenState();
}

class _ManageTourPointScreenState extends State<ManageTourPointScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  late final TextEditingController _photosCtrl;
  final MapController _mapController = MapController();

  double _rating = 0.0;
  String _activityType = 'hiking';
  bool _saving = false;
  late LatLng _current;
  LatLng? _userLocation;
  bool _locating = false;
  bool _permissionDenied = false;
  List<TourPoint> _areas = [];
  bool _loadingAreas = true;

  bool get isEdit => widget.existing != null;

  final List<String> _activityTypes = const [
    'hiking', 'contemplation', 'adventure', 'cultural'
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _latCtrl = TextEditingController();
    _lngCtrl = TextEditingController();
    _photosCtrl = TextEditingController(text: e?.photoCount.toString() ?? '0');
    _rating = e?.rating ?? 0.0;
    _activityType = _mapActivityTypeToKey(e?.activityType ?? 'hiking');
  _current = widget.initialCenter ?? e?.location ?? LatLng(2.8235, -60.6758);
    _latCtrl.text = _current.latitude.toStringAsFixed(6);
    _lngCtrl.text = _current.longitude.toStringAsFixed(6);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadAreas();
      await _getUserLocation(showOnMapOnly: true); // só mostra círculo se disponível
    });
  }

  String _mapActivityTypeToKey(String activityType) {
    switch (activityType) {
      case 'Caminhada':
        return 'hiking';
      case 'Contemplação':
        return 'contemplation';
      case 'Aventura':
        return 'adventure';
      case 'Cultural':
        return 'cultural';
      default:
        return activityType; // assume already english key
    }
  }

  Future<void> _getUserLocation({bool showOnMapOnly = false}) async {
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
        if(!showOnMapOnly){
          _current = latlng;
          _mapController.move(latlng, widget.initialZoom ?? 16);
          _latCtrl.text = latlng.latitude.toStringAsFixed(6);
          _lngCtrl.text = latlng.longitude.toStringAsFixed(6);
        }
        _userLocation = latlng;
      });
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() { _locating = false; });
    }
  }

  Future<void> _loadAreas() async {
    try {
      setState(() => _loadingAreas = true);
      // Usar repositório se disponível via provider
      ITourPointRepository? repo;
      try { repo = context.read<ITourPointRepository>(); } catch (_) {}
      List<TourPoint> list;
      if (repo != null) {
        list = await repo.getMain();
      } else {
        list = await TourPointsData.getAllTourPoints();
      }
      setState(() {
        _areas = list.where((a) => a.isArea && (a.polygon?.length ?? 0) >= 3).toList();
      });
    } finally {
      if (mounted) setState(() => _loadingAreas = false);
    }
  }

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final id = widget.existing?.id ?? const Uuid().v4();
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
      images: widget.existing?.images ?? const [],
    );
    try {
      if (isEdit) {
        await TourPointsData.updateTourPoint(point);
      } else {
        await TourPointsData.addTourPoint(point);
      }
      if (mounted) Navigator.pop(context, point);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (!isEdit) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_point_title'.tr()),
        content: Text('delete_point_question'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr())),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('delete'.tr())),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _saving = true);
    await TourPointsData.deleteTourPoint(widget.existing!.id);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'edit_point'.tr() : 'new_point'.tr()),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _saving ? null : _delete,
              tooltip: 'tooltip_delete'.tr(),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: 'short_name'.tr()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'validation_enter_name'.tr() : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(labelText: 'title_label'.tr()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'validation_enter_title'.tr() : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: InputDecoration(labelText: 'description_label'.tr()),
              maxLines: 4,
              validator: (v) => (v == null || v.trim().length < 10) ? 'validation_desc_too_short'.tr() : null,
            ),
            const SizedBox(height: 12),
            Text('location'.tr(), style: Theme.of(context).textTheme.titleMedium),
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
                        initialZoom: 14,
                        onPositionChanged: (pos, _) {
                          final c = pos.center;
                          setState(() {
                            _current = c;
                            _latCtrl.text = c.latitude.toStringAsFixed(6);
                            _lngCtrl.text = c.longitude.toStringAsFixed(6);
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'dev.meuapp.guia_turistico',
                        ),
                        if (_areas.isNotEmpty)
                          PolygonLayer(
                            polygons: [
                              for (final area in _areas)
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
                    if (_loadingAreas)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              SizedBox(width:14,height:14,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)),
                              SizedBox(width:6),
                              Text('Loading areas...', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    const Center(child: Icon(Icons.location_pin, size: 46, color: Colors.red)),
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
                          options: MapOptions(initialCenter: _current, initialZoom: 17),
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
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Column(children:[
                        FloatingActionButton.small(
                          heroTag: 'manage_locate',
                          onPressed: _locating ? null : _getUserLocation,
                          child: _locating ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.my_location),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'manage_zoom_in',
                          onPressed: () => _mapController.move(_current, _mapController.camera.zoom + 1),
                          child: const Icon(Icons.add),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'manage_zoom_out',
                          onPressed: () => _mapController.move(_current, _mapController.camera.zoom - 1),
                          child: const Icon(Icons.remove),
                        ),
                      ]),
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
                            child: Text('error_location_permission_denied'.tr(), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(children:[
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
                onPressed: () => _mapController.move(_current, _mapController.camera.zoom),
                tooltip: 'tooltip_center'.tr(),
              )
            ]),
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
              validator: (v) => (int.tryParse(v ?? '') == null) ? 'validation_invalid'.tr() : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width:16,height:16,child: CircularProgressIndicator(strokeWidth:2))
                  : const Icon(Icons.save),
              label: Text(_saving ? 'saving'.tr() : (isEdit ? 'save_changes'.tr() : 'create'.tr())),
            ),
          ],
        ),
      ),
    );
  }
}
 
