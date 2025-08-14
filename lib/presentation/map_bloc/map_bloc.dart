import 'package:bloc/bloc.dart';

abstract class MapEvent {}
class LoadMapData extends MapEvent {}

class MapState {}

class MapBloc extends Bloc<MapEvent, MapState> {
  MapBloc() : super(MapState()) {
    on<LoadMapData>((event, emit) {
      // no-op placeholder to satisfy dependency; real logic comes later
      emit(MapState());
    });
  }
}
