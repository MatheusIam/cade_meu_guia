import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import '../models/tour_point.dart';
import '../presentation/map_bloc/map_bloc.dart';
import '../domain/repositories/itour_point_repository.dart';

/// Tela unificada para criar e editar um ponto turístico.
class ManageTourPointScreen extends StatefulWidget {
  final TourPoint? tourPoint;
  final LatLng? initialCenter;
  final double? initialZoom;

  const ManageTourPointScreen({
    super.key,
    this.tourPoint,
    this.initialCenter,
    this.initialZoom,
  });

  bool get isEditMode => tourPoint != null;

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
  late LatLng _currentLocation;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existingPoint = widget.tourPoint;

    _nameCtrl = TextEditingController(text: existingPoint?.name ?? '');
    _titleCtrl = TextEditingController(text: existingPoint?.title ?? '');
    _descCtrl = TextEditingController(text: existingPoint?.description ?? '');
    _photosCtrl = TextEditingController(text: existingPoint?.photoCount.toString() ?? '0');
    
    _currentLocation = widget.initialCenter ?? existingPoint?.location ?? const LatLng(2.8235, -60.6758);
    _latCtrl = TextEditingController(text: _currentLocation.latitude.toStringAsFixed(6));
    _lngCtrl = TextEditingController(text: _currentLocation.longitude.toStringAsFixed(6));
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

    final repo = context.read<ITourPointRepository>();

    try {
      final id = widget.tourPoint?.id ?? const Uuid().v4();
      final point = TourPoint(
        id: id,
        name: _nameCtrl.text.trim(),
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        location: _currentLocation,
        rating: widget.tourPoint?.rating ?? 0.0,
        photoCount: int.tryParse(_photosCtrl.text) ?? 0,
        activityType: widget.tourPoint?.activityType ?? 'Cultural', // Mantém tipo existente ou usa um padrão
        images: widget.tourPoint?.images ?? [],
      );

      if (widget.isEditMode) {
        await repo.update(point);
      } else {
        await repo.add(point);
      }
      
      if (mounted) {
        context.read<MapBloc>().add(LoadMapData()); // Força a atualização da lista na HomeScreen
        Navigator.pop(context, point);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isEditMode ? 'tour_point_updated'.tr() : 'tour_point_added'.tr())),
        );
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_saving'.tr()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
  
  Future<void> _delete() async {
    if (!widget.isEditMode) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_point_title'.tr()),
        content: Text('delete_point_question'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr())),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text('delete'.tr())),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    
    setState(() => _saving = true);
    final repo = context.read<ITourPointRepository>();
    try {
      await repo.delete(widget.tourPoint!.id);
      if (mounted) {
        context.read<MapBloc>().add(LoadMapData());
        Navigator.pop(context, true); // Retorna true para indicar exclusão
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'edit_point'.tr() : 'new_tour_point'.tr()),
        actions: [
          if (widget.isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'delete'.tr(),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: 'short_name'.tr()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'enter_name'.tr() : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(labelText: 'title_label'.tr()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'enter_title'.tr() : null,
            ),
            const SizedBox(height: 16),
             TextFormField(
              controller: _descCtrl,
              decoration: InputDecoration(labelText: 'description_label'.tr()),
              maxLines: 4,
              validator: (v) => (v == null || v.trim().length < 10) ? 'description_too_short'.tr() : null,
            ),
            const SizedBox(height: 16),
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
                        initialCenter: _currentLocation,
                        initialZoom: widget.initialZoom ?? 15,
                        onPositionChanged: (position, hasGesture) {
                          if (hasGesture) {
                            setState(() {
                              _currentLocation = position.center;
                              _latCtrl.text = _currentLocation.latitude.toStringAsFixed(6);
                              _lngCtrl.text = _currentLocation.longitude.toStringAsFixed(6);
                            });
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'dev.meuapp.guia_turistico',
                        ),
                      ],
                    ),
                    const Center(child: Icon(Icons.location_pin, size: 40, color: Colors.red)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
              label: Text(widget.isEditMode ? 'save_changes'.tr() : 'create_point'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

