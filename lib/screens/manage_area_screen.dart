import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../domain/repositories/itour_point_repository.dart';
import '../models/tour_point.dart';
import '../providers/tour_points_provider.dart';
import '../utils/permission_helper.dart';

/// Tela unificada para criar e editar uma Área (polígono) de TourPoint
class ManageAreaScreen extends StatefulWidget {
  final TourPoint? existing; // se nulo => criação; senão => edição
  final LatLng? initialCenter;
  final double? initialZoom;

  const ManageAreaScreen({
    super.key,
    this.existing,
    this.initialCenter,
    this.initialZoom,
  });

  bool get isEditMode => existing != null;

  @override
  State<ManageAreaScreen> createState() => _ManageAreaScreenState();
}

class _ManageAreaScreenState extends State<ManageAreaScreen> {
  // Form
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;

  // Map/polygon
  final MapController _mapController = MapController();
  final List<LatLng> _vertices = [];
  int? _movingIndex; // modo mover via toque: seleciona e posiciona no próximo tap
  int? _draggingIndex; // modo arrastar contínuo
  bool _snapGrid = true; // snap em grade (principalmente útil na edição)
  final double _grid = 0.0002; // ~22m (aprox) dependente da latitude
  final double _snapNearbyMeters = 12; // snap em vértice próximo
  bool _showReorder = false;

  // Location helpers
  LatLng? _userLocation;
  bool _locating = false;
  bool _permissionDenied = false;

  // UI state
  bool _saving = false;

  late LatLng _currentCenter;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
    _descCtrl = TextEditingController(text: widget.existing?.description ?? '');

    final initialVertices = widget.existing?.polygon ?? const <LatLng>[];
    _vertices.addAll(initialVertices);

    if (_vertices.isNotEmpty) {
      _orderByAngle();
    }

    _currentCenter = widget.initialCenter ??
        widget.existing?.centroid ??
        const LatLng(2.8235, -60.6758);

    // Após montar a tela, tentar obter localização do usuário (opcional)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getUserLocation();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ---- Polígono helpers ----
  void _orderByAngle() {
    if (_vertices.length < 3) return;
    final c = _centroid();
    _vertices.sort((a, b) {
      final angA = math.atan2(a.latitude - c.latitude, a.longitude - c.longitude);
      final angB = math.atan2(b.latitude - c.latitude, b.longitude - c.longitude);
      return angA.compareTo(angB);
    });
  }

  LatLng _centroid() {
    if (_vertices.isEmpty) return _currentCenter;
    double x = 0, y = 0;
    for (final v in _vertices) {
      x += v.latitude;
      y += v.longitude;
    }
    return LatLng(x / _vertices.length, y / _vertices.length);
  }

  LatLng _snapToGrid(LatLng p) {
    if (!_snapGrid) return p;
    final lat = (p.latitude / _grid).round() * _grid;
    final lng = (p.longitude / _grid).round() * _grid;
    return LatLng(lat, lng);
  }

  LatLng _applySnapToNearby(LatLng p, int movingIndex) {
    if (_vertices.length < 2) return p;
    const distance = Distance();
    for (int i = 0; i < _vertices.length; i++) {
      if (i == movingIndex) continue;
      final d = distance(p, _vertices[i]);
      if (d <= _snapNearbyMeters) {
        return _vertices[i];
      }
    }
    return p;
  }

  void _addVertex(LatLng p) {
    setState(() {
      final v = _snapToGrid(p);
      _vertices.add(v);
      _orderByAngle();
    });
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
      var candidate = _snapToGrid(p);
      candidate = _applySnapToNearby(candidate, _movingIndex!);
      _vertices[_movingIndex!] = candidate;
      _movingIndex = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('vertex_moved'.tr()), duration: const Duration(seconds: 2)),
    );
  }

  void _startDrag(int i) {
    setState(() => _draggingIndex = i);
  }

  void _updateDrag(LatLng p) {
    if (_draggingIndex == null) return;
    var candidate = _snapToGrid(p);
    candidate = _applySnapToNearby(candidate, _draggingIndex!);
    setState(() => _vertices[_draggingIndex!] = candidate);
  }

  void _endDrag() {
    setState(() => _draggingIndex = null);
  }

  void _removeVertex(int index) {
    setState(() => _vertices.removeAt(index));
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

  // ---- Location ----
  Future<void> _getUserLocation() async {
    final allowed = await PermissionHelper.ensurePreciseLocationPermission(context);
    if (!allowed) return;
    setState(() {
      _locating = true;
      _permissionDenied = false;
    });
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() {
          _permissionDenied = true;
        });
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
      if (mounted) {
        setState(() {
          _locating = false;
        });
      }
    }
  }

  // ---- Save ----
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
      final center = _centroid();

      if (widget.isEditMode) {
        final updated = widget.existing!.copyWith(
          name: _nameCtrl.text.trim(),
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          polygon: List<LatLng>.from(_vertices),
          location: center,
        );
        await repo.update(updated);
        await tp.updatePoint(updated);
        if (!mounted) return;
        Navigator.pop(context, updated);
      } else {
        final id = const Uuid().v4();
        final area = TourPoint(
          id: id,
          name: _nameCtrl.text.trim(),
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          location: center,
          rating: 0,
          photoCount: 0,
          activityType: 'Cultural',
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
    final titleText = widget.isEditMode ? 'edit_area_title'.tr() : 'new_area'.tr();
    final centroid = _vertices.isNotEmpty ? _centroid() : _currentCenter;
    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
        actions: [
          if (_vertices.length >= 3)
            TextButton(
              onPressed: () => setState(() => _showReorder = !_showReorder),
              child: Text(_showReorder ? 'finish_editing'.tr() : 'reorder'.tr(), style: const TextStyle(color: Colors.white)),
            ),
          IconButton(
            icon: Icon(_snapGrid ? Icons.grid_on : Icons.grid_off),
            tooltip: 'snap_to_grid'.tr(),
            onPressed: () => setState(() => _snapGrid = !_snapGrid),
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
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'enter_name'.tr() : null,
                      ),
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
                        maxLines: 3,
                        validator: (v) => (v == null || v.trim().length < 10) ? 'description_too_short'.tr() : null,
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
                              initialCenter: centroid,
                              initialZoom: widget.initialZoom ?? 15,
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
                                      child: _buildDraggableHandle(i),
                                    ),
                                  if (_vertices.isNotEmpty)
                                    Marker(
                                      point: centroid,
                                      width: 18,
                                      height: 18,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.9),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                      ),
                                    ),
                                  if (_userLocation != null)
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
                            icon: _locating
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.my_location),
                            label: Text('my_location'.tr()),
                          ),
                        ],
                      ),
                      if (_permissionDenied)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text('error_location_permission_denied'.tr(),
                              style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ),
                      const SizedBox(height: 12),
                      if (_vertices.length < 3)
                        Text('min_vertices_warning'.tr(),
                            style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      const SizedBox(height: 12),
                      _buildVerticesList(),
                      if (_hasSelfIntersection())
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
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
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(_saving ? 'saving'.tr() : 'save'.tr()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Widgets auxiliares ----
  Widget _buildDraggableHandle(int i) {
    final isDragging = _draggingIndex == i;
    return GestureDetector(
      onLongPressStart: (_) => _startDrag(i),
      onTap: () => _startMoveVertex(i),
      onTapDown: (_) => _startDrag(i),
      onPanStart: (_) => _startDrag(i),
      onPanUpdate: (d) {
        if (_draggingIndex == null) return;
        final current = _vertices[_draggingIndex!];
        final zoom = _mapController.camera.zoom;
        final lat = current.latitude;
        // graus por pixel aproximado
        final worldSize = 256 * math.pow(2, zoom);
        final degreesPerPixelLon = 360 / worldSize;
        final degreesPerPixelLat = degreesPerPixelLon; // aproximação
        final dx = d.delta.dx;
        final dy = d.delta.dy;
        final newLat = current.latitude - dy * degreesPerPixelLat;
        final newLon = current.longitude + dx * degreesPerPixelLon / math.cos(lat * math.pi / 180);
        _updateDrag(LatLng(newLat, newLon));
      },
      onPanEnd: (_) => _endDrag(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDragging ? Colors.orange : Theme.of(context).colorScheme.primary,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)],
        ),
        child: Center(
          child: Text('${i + 1}',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildVerticesList() {
    if (_vertices.isEmpty) {
      return Text('tap_to_add_vertices'.tr());
    }
    if (_showReorder) {
      return Card(
        child: ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = _vertices.removeAt(oldIndex);
              _vertices.insert(newIndex, item);
              _orderByAngle();
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
                title: Text(
                    '${_vertices[i].latitude.toStringAsFixed(5)}, ${_vertices[i].longitude.toStringAsFixed(5)}'),
                trailing: IconButton(
                  tooltip: 'remove_vertex'.tr(),
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _removeVertex(i),
                ),
              ),
          ],
        ),
      );
    }
    // Lista simples com toque para iniciar mover via próximo tap
    return Card(
      child: Column(
        children: [
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
          for (int i = 0; i < _vertices.length; i++)
            ListTile(
              dense: true,
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text('${i + 1}', style: const TextStyle(color: Colors.white)),
              ),
              title: Text(
                  '${_vertices[i].latitude.toStringAsFixed(5)}, ${_vertices[i].longitude.toStringAsFixed(5)}'),
              trailing: IconButton(
                tooltip: 'remove_vertex'.tr(),
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _removeVertex(i),
              ),
              onTap: () => _startMoveVertex(i),
            ),
        ],
      ),
    );
  }
}
