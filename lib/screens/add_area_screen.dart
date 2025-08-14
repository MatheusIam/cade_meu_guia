import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/permission_helper.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../models/tour_point.dart';
import '../domain/repositories/itour_point_repository.dart';
import '../providers/tour_points_provider.dart';

class AddAreaScreen extends StatefulWidget {
  final LatLng? initialCenter;
  final double? initialZoom;
  const AddAreaScreen({super.key, this.initialCenter, this.initialZoom});

  @override
  State<AddAreaScreen> createState() => _AddAreaScreenState();
}

class _AddAreaScreenState extends State<AddAreaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _mapController = MapController();
  final List<LatLng> _vertices = [];
  int? _movingIndex; // índice sendo movido
  bool _saving = false;
  bool _showReorder = false;

  late LatLng _currentCenter;
  LatLng? _userLocation;
  bool _locating = false;
  bool _permissionDenied = false;

  void _addVertex(LatLng p) {
    setState(() => _vertices.add(p));
  }

  void _startMoveVertex(int index) {
    setState(() => _movingIndex = index);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('move_vertex_mode'.tr()), duration: const Duration(seconds: 2)),
    );
  }

  void _setMovedVertex(LatLng p) {
    if (_movingIndex == null) return;
    setState(() {
      _vertices[_movingIndex!] = p;
      _movingIndex = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('vertex_moved'.tr()), duration: const Duration(seconds: 2)),
    );
  }

  void _removeVertex(int index) {
    setState(() => _vertices.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('vertex_removed'.tr()), duration: const Duration(seconds: 2)),
    );
  }

  LatLng _computeCentroid() {
    if (_vertices.isEmpty) return _currentCenter;
    double x = 0, y = 0;
    for (final v in _vertices) { x += v.latitude; y += v.longitude; }
    return LatLng(x / _vertices.length, y / _vertices.length);
  }

  @override
  void initState() {
    super.initState();
    _currentCenter = widget.initialCenter ?? const LatLng(2.8235, -60.6758);
  WidgetsBinding.instance.addPostFrameCallback((_) async { await _getUserLocation(); });
  }

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
        _userLocation = latlng;
        _currentCenter = latlng;
        _mapController.move(latlng, 16);
      });
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() { _locating = false; });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vertices.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('not_enough_vertices'.tr())),
      );
      return;
    }
    if (_hasSelfIntersection()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('polygon_self_intersection_error'.tr())),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = context.read<ITourPointRepository>();
      final tp = context.read<TourPointsProvider>();
      final id = const Uuid().v4();
      final center = _computeCentroid();
      final area = TourPoint(
        id: id,
        name: _nameCtrl.text.trim(),
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        location: center, // centro calculado
        rating: 0,
        photoCount: 0,
        activityType: 'Cultural', // default; poderá ser selecionado em futura iteração
        polygon: List<LatLng>.from(_vertices),
        images: const [],
      );
  await repo.add(area);
  await tp.load(); // garante consistência na memória
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('area_created'.tr())),
      );
      Navigator.pop(context, area);
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
      appBar: AppBar(
        title: Text('new_area'.tr()),
        actions: [
          if (_vertices.length >= 3)
            TextButton(
              onPressed: () {
                setState(() => _showReorder = !_showReorder);
              },
              child: Text(_showReorder ? 'finish_editing'.tr() : 'reorder'.tr(), style: const TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(labelText: 'short_name'.tr()),
                        validator: (v) => (v==null||v.trim().isEmpty) ? 'enter_name'.tr() : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: InputDecoration(labelText: 'title_label'.tr()),
                        validator: (v) => (v==null||v.trim().isEmpty) ? 'enter_title'.tr() : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descCtrl,
                        decoration: InputDecoration(labelText: 'description_label'.tr()),
                        maxLines: 3,
                        validator: (v) => (v==null||v.trim().length<10) ? 'description_too_short'.tr() : null,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('area_polygon_instructions'.tr(), style: Theme.of(context).textTheme.bodySmall),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 300,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _currentCenter,
                              initialZoom: widget.initialZoom ?? 14,
                              onTap: (tapPos, latlng) {
                                if (_movingIndex != null) {
                                  _setMovedVertex(latlng);
                                } else {
                                  _addVertex(latlng);
                                }
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'dev.meuapp.guia_turistico',
                              ),
                              if (_userLocation != null)
                                MarkerLayer(markers:[
                                  Marker(
                                    point: _userLocation!,
                                    width: 28,
                                    height: 28,
                                    child: Container(
                                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.15), shape: BoxShape.circle),
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.circle, size: 12, color: Colors.blue),
                                    ),
                                  ),
                                ]),
                              if (_vertices.length >= 2)
                                PolygonLayer(
                                  polygons: [
                                    Polygon(
                                      points: _vertices,
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
                                      borderStrokeWidth: 3,
                                      borderColor: Theme.of(context).colorScheme.primary,
                                    ),
                                  ],
                                ),
                              MarkerLayer(
                                markers: [
                                  for (int i = 0; i < _vertices.length; i++)
                                    Marker(
                                      point: _vertices[i],
                                      width: 40,
                                      height: 40,
                                      child: GestureDetector(
                                        onTap: () => _startMoveVertex(i),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: (_movingIndex == i)
                                                ? Colors.orange
                                                : Theme.of(context).colorScheme.primary,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${i+1}',
                                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _locating ? null : _getUserLocation,
                            icon: _locating ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.my_location),
                            label: Text('my_location'.tr()),
                          ),
                        ],
                      ),
                      if (_permissionDenied)
                        Padding(
                          padding: const EdgeInsets.only(top:8.0),
                          child: Text('error_location_permission_denied'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ),
                      const SizedBox(height: 12),
                      if (_vertices.length < 3)
                        Text('min_vertices_warning'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      const SizedBox(height: 12),
                      _buildVerticesList(),
                      if (_hasSelfIntersection())
                        Padding(
                          padding: const EdgeInsets.only(top:8.0),
                          child: Text(
                            'polygon_self_intersection_error'.tr(),
                            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2))
                    : const Icon(Icons.save),
                label: Text(_saving ? 'saving'.tr() : 'save'.tr()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticesList() {
    if (_vertices.isEmpty) {
      return Text('tap_to_add_vertices'.tr());
    }
    final listChildren = <Widget>[
      ListTile(
        title: Text('polygon'.tr()),
        subtitle: Text('${_vertices.length} vertices'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_vertices.length >= 3)
              Icon(
                _hasSelfIntersection() ? Icons.warning : Icons.check_circle,
                color: _hasSelfIntersection()
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
      const Divider(height: 0),
    ];
    if (_showReorder) {
      listChildren.add(
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = _vertices.removeAt(oldIndex);
              _vertices.insert(newIndex, item);
            });
          },
          children: [
            for (int i = 0; i < _vertices.length; i++)
              ListTile(
                key: ValueKey('v-$i'),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text('${i + 1}', style: const TextStyle(color: Colors.white)),
                ),
                title: Text('${_vertices[i].latitude.toStringAsFixed(5)}, ${_vertices[i].longitude.toStringAsFixed(5)}'),
                trailing: IconButton(
                  tooltip: 'remove_vertex'.tr(),
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _removeVertex(i),
                ),
              ),
          ],
        ),
      );
    } else {
      for (int i = 0; i < _vertices.length; i++) {
        listChildren.add(
          ListTile(
            dense: true,
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text('${i + 1}', style: const TextStyle(color: Colors.white)),
            ),
            title: Text('${_vertices[i].latitude.toStringAsFixed(5)}, ${_vertices[i].longitude.toStringAsFixed(5)}'),
            trailing: IconButton(
              tooltip: 'remove_vertex'.tr(),
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _removeVertex(i),
            ),
            onTap: () => _startMoveVertex(i),
          ),
        );
      }
    }
    return Card(child: Column(children: listChildren));
  }

  bool _hasSelfIntersection() {
    if (_vertices.length < 4) return false; // triângulo não se cruza
    for (int i = 0; i < _vertices.length; i++) {
      final a1 = _vertices[i];
      final a2 = _vertices[(i + 1) % _vertices.length];
      for (int j = i + 1; j < _vertices.length; j++) {
        if ((j == i) || (j == (i + 1) % _vertices.length) || ((i == 0) && (j == _vertices.length - 1))) continue;
        final b1 = _vertices[j];
        final b2 = _vertices[(j + 1) % _vertices.length];
        if (_segmentsIntersect(a1, a2, b1, b2)) return true;
      }
    }
    return false;
  }

  double _orientation(LatLng a, LatLng b, LatLng c) {
    final val = (b.longitude - a.longitude) * (c.latitude - b.latitude) -
        (b.latitude - a.latitude) * (c.longitude - b.longitude);
    if (val.abs() < 1e-12) return 0; // colinear com tolerância
    return (val > 0) ? 1 : 2;
  }

  bool _onSegment(LatLng a, LatLng b, LatLng p) {
    return p.latitude <= (a.latitude > b.latitude ? a.latitude : b.latitude) + 1e-12 &&
           p.latitude + 1e-12 >= (a.latitude < b.latitude ? a.latitude : b.latitude) &&
           p.longitude <= (a.longitude > b.longitude ? a.longitude : b.longitude) + 1e-12 &&
           p.longitude + 1e-12 >= (a.longitude < b.longitude ? a.longitude : b.longitude);
  }

  bool _segmentsIntersect(LatLng p1, LatLng p2, LatLng p3, LatLng p4) {
    final o1 = _orientation(p1, p2, p3);
    final o2 = _orientation(p1, p2, p4);
    final o3 = _orientation(p3, p4, p1);
    final o4 = _orientation(p3, p4, p2);
    if (o1 != o2 && o3 != o4) return true; // interseção geral
    // Casos colineares
    if (o1 == 0 && _onSegment(p1, p2, p3)) return true;
    if (o2 == 0 && _onSegment(p1, p2, p4)) return true;
    if (o3 == 0 && _onSegment(p3, p4, p1)) return true;
    if (o4 == 0 && _onSegment(p3, p4, p2)) return true;
    return false;
  }
}
