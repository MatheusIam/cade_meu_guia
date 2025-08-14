import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/tour_point.dart';
import '../domain/repositories/itour_point_repository.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/permission_helper.dart';
import '../providers/tour_points_provider.dart';

class EditAreaScreen extends StatefulWidget {
  final TourPoint area;
  const EditAreaScreen({super.key, required this.area});

  @override
  State<EditAreaScreen> createState() => _EditAreaScreenState();
}

class _EditAreaScreenState extends State<EditAreaScreen> {
  late List<LatLng> _vertices;
  int? _draggingIndex;
  bool _snap = true;
  bool _saving = false;
  final _mapController = MapController();
  final double _grid = 0.0002; // ~22m dependendo da latitude
  final double _snapNearbyMeters = 12; // threshold para snap a outro vértice
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _vertices = List<LatLng>.from(widget.area.polygon ?? []);
    _orderByAngle();
  WidgetsBinding.instance.addPostFrameCallback((_) => _loadUserLocation());
  }

  void _orderByAngle() {
    if (_vertices.length < 3) return;
    final c = _centroid();
    _vertices.sort((a,b){
      final angA = math.atan2(a.latitude - c.latitude, a.longitude - c.longitude);
      final angB = math.atan2(b.latitude - c.latitude, b.longitude - c.longitude);
      return angA.compareTo(angB);
    });
  }

  LatLng _centroid(){
    if (_vertices.isEmpty) return widget.area.location;
    double x=0,y=0;for(final v in _vertices){x+=v.latitude;y+=v.longitude;}
    return LatLng(x/_vertices.length, y/_vertices.length);
  }

  LatLng _snapIfNeeded(LatLng p){
    if(!_snap) return p;
    double lat = (p.latitude / _grid).round() * _grid;
    double lng = (p.longitude / _grid).round() * _grid;
    return LatLng(lat,lng);
  }

  void _onMapTap(TapPosition tapPos, LatLng latlng){
    // Add new vertex at end
    setState((){
      _vertices.add(_snapIfNeeded(latlng));
      _orderByAngle();
    });
  }

  void _startDrag(int i){
    setState(()=>_draggingIndex=i);
  }

  void _updateDrag(LatLng p){
    if(_draggingIndex==null) return;
  var candidate = _snapIfNeeded(p);
  candidate = _applySnapToNearby(candidate, _draggingIndex!);
  setState(()=>_vertices[_draggingIndex!] = candidate);
  }

  void _endDrag(){
    setState(()=>_draggingIndex=null);
  }

  Future<void> _loadUserLocation() async {
    final allowed = await PermissionHelper.ensurePreciseLocationPermission(context);
    if(!allowed) return;
    try {
      final pos = await Geolocator.getCurrentPosition();
      if(mounted) setState(()=>_userLocation = LatLng(pos.latitude, pos.longitude));
    } catch(_){ /* ignore */ }
  }

  bool _hasSelfIntersection(){
    if(_vertices.length<4) return false;
    for(int i=0;i<_vertices.length;i++){
      final a1=_vertices[i];
      final a2=_vertices[(i+1)%_vertices.length];
      for(int j=i+1;j<_vertices.length;j++){
        if((j==i)||(j==(i+1)%_vertices.length)||((i==0)&&(j==_vertices.length-1))) continue;
        final b1=_vertices[j];
        final b2=_vertices[(j+1)%_vertices.length];
        if(_segmentsIntersect(a1,a2,b1,b2)) return true;
      }
    }
    return false;
  }

  double _orientation(LatLng a, LatLng b, LatLng c){
    final val=(b.longitude-a.longitude)*(c.latitude-b.latitude)-(b.latitude-a.latitude)*(c.longitude-b.longitude);
    if(val.abs()<1e-15) return 0; // colinear tolerância
    return val>0?1:2;
  }

  bool _onSegment(LatLng a,LatLng b,LatLng p){
    return p.latitude <= math.max(a.latitude,b.latitude)+1e-15 && p.latitude+1e-15 >= math.min(a.latitude,b.latitude) &&
           p.longitude <= math.max(a.longitude,b.longitude)+1e-15 && p.longitude+1e-15 >= math.min(a.longitude,b.longitude);
  }

  bool _segmentsIntersect(LatLng p1,LatLng p2,LatLng p3,LatLng p4){
    final o1=_orientation(p1,p2,p3);final o2=_orientation(p1,p2,p4);final o3=_orientation(p3,p4,p1);final o4=_orientation(p3,p4,p2);
    if(o1!=o2 && o3!=o4) return true;
    // casos colineares
    if(o1==0 && _onSegment(p1,p2,p3)) return true;
    if(o2==0 && _onSegment(p1,p2,p4)) return true;
    if(o3==0 && _onSegment(p3,p4,p1)) return true;
    if(o4==0 && _onSegment(p3,p4,p2)) return true;
    return false;
  }

  Future<void> _save() async {
    if(_vertices.length<3) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('min_vertices_warning'.tr())));
      return;
    }
    if(_hasSelfIntersection()){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('polygon_self_intersection_error'.tr())));
      return;
    }
    setState(()=>_saving=true);
    try{
      final repo=context.read<ITourPointRepository>();
  final tp=context.read<TourPointsProvider>();
      final updated=widget.area.copyWith(
        polygon: List<LatLng>.from(_vertices),
        // location recalculado pelo centro
        location: _centroid(),
      );
      await repo.update(updated);
  await tp.updatePoint(updated);
      if(!mounted) return;
      Navigator.pop(context, updated);
    } catch(e){
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${'error_saving'.tr()}: $e')));
      }
    } finally { if(mounted) setState(()=>_saving=false); }
  }

  void _removeVertex(int index){
    setState(()=>_vertices.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final centroid=_centroid();
    return Scaffold(
      appBar: AppBar(
  // Título explícito para diferenciação de edição de área
  title: Text('edit_area_title'.tr()),
        actions: [
          IconButton(
            icon: Icon(_snap?Icons.grid_on:Icons.grid_off),
            tooltip: 'snap_to_grid'.tr(),
            onPressed: ()=>setState(()=>_snap=!_snap),
          ),
          TextButton(
            onPressed: _saving?null:_save,
            child: _saving ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)) : Text('save'.tr(), style: const TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children:[
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: centroid,
                    initialZoom: 15,
                    onTap: (tapPos, latlng){
                      if(_draggingIndex!=null){
                        _updateDrag(latlng);
                        _endDrag();
                      } else {
                        _onMapTap(tapPos, latlng);
                      }
                    },
                  ),
                  children:[
                    TileLayer(urlTemplate:'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName:'dev.meuapp.guia_turistico'),
                    if(_vertices.length>=2)
                      PolygonLayer(polygons:[Polygon(points:_vertices, color: Theme.of(context).colorScheme.primary.withOpacity(0.25), borderColor: Theme.of(context).colorScheme.primary, borderStrokeWidth:3)]),
                    MarkerLayer(
                      markers:[
                        for(int i=0;i<_vertices.length;i++)
                          Marker(point:_vertices[i],width:40,height:40,child:_buildDraggableHandle(i)),
                        if(_vertices.isNotEmpty)
                          Marker(point: centroid,width:18,height:18,child: Container(decoration: BoxDecoration(color:Colors.red.withOpacity(0.9),shape:BoxShape.circle, border: Border.all(color: Colors.white,width:2)))),
                        if(_userLocation!=null)
                          Marker(point:_userLocation!,width:32,height:32,child: Container(
                            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.18), shape: BoxShape.circle, border: Border.all(color: Colors.blueAccent,width:2)),
                            child: const Center(child: Icon(Icons.circle,size:10,color:Colors.blueAccent)),
                          )),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  left: 12, top: 12, right: 12,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[
                          Text('editing_polygon'.tr(), style: Theme.of(context).textTheme.titleSmall),
                          Text('vertices: ${_vertices.length}', style: Theme.of(context).textTheme.bodySmall),
                          if(_hasSelfIntersection()) Text('polygon_self_intersection_error'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize:11)),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          SizedBox(
            height: 180,
            child: _buildVerticesList(),
          )
        ],
      ),
    );
  }

  Widget _buildDraggableHandle(int i){
    final isDragging = _draggingIndex==i;
    return GestureDetector(
  onLongPressStart: (_){ _startDrag(i); },
  onTapDown: (_){ _startDrag(i); },
  onPanStart: (_){ _startDrag(i); },
      onPanUpdate: (d){
        if(_draggingIndex==null) return;
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
  onPanEnd: (_){ _endDrag(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDragging? Colors.orange : Theme.of(context).colorScheme.primary,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)],
        ),
        child: Center(child: Text('${i+1}', style: const TextStyle(color: Colors.white, fontSize: 12,fontWeight: FontWeight.bold))),
      ),
    );
  }

  Widget _buildVerticesList(){
    return ReorderableListView(
      scrollDirection: Axis.horizontal,
      onReorder: (oldIndex, newIndex){
        setState((){
          if(newIndex>oldIndex) newIndex-=1;
          final v=_vertices.removeAt(oldIndex);
          _vertices.insert(newIndex,v);
          _orderByAngle(); // reordena automaticamente por ângulo após reorder manual
        });
      },
      children:[
        for(int i=0;i<_vertices.length;i++)
          Container(
            key: ValueKey('vert-$i'),
            width: 160,
            margin: const EdgeInsets.all(4),
            child: Card(
              color: _draggingIndex==i? Colors.orange.withOpacity(0.2):null,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:[
                    Text('${'vertex'.tr()} ${i+1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(_vertices[i].latitude.toStringAsFixed(5)),
                    Text(_vertices[i].longitude.toStringAsFixed(5)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:[
                        IconButton(icon: const Icon(Icons.delete_outline), tooltip:'remove_vertex'.tr(), onPressed: ()=>_removeVertex(i)),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  LatLng _applySnapToNearby(LatLng p, int movingIndex){
    if(_vertices.length < 2) return p;
    final distance = Distance();
    for(int i=0;i<_vertices.length;i++){
      if(i==movingIndex) continue;
      final d = distance(p, _vertices[i]);
      if(d <= _snapNearbyMeters){
        return _vertices[i];
      }
    }
    return p;
  }
}
