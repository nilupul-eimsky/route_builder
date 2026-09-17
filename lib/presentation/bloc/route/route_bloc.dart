import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/route_entity.dart';
import '../../../domain/usecases/route/delete_route_usecase.dart';
import '../../../domain/usecases/route/get_all_routes_usecase.dart';
import '../../../domain/usecases/route/get_route_usecase.dart';
import '../../../domain/usecases/route/save_route_usecase.dart';

part 'route_event.dart';
part 'route_state.dart';

class RouteBloc extends Bloc<RouteEvent, RouteState> {
  final GetAllRoutesUseCase _getAllRoutes;
  final GetRouteUseCase _getRoute;
  final SaveRouteUseCase _saveRoute;
  final DeleteRouteUseCase _deleteRoute;

  RouteBloc({
    required GetAllRoutesUseCase getAllRoutes,
    required GetRouteUseCase getRoute,
    required SaveRouteUseCase saveRoute,
    required DeleteRouteUseCase deleteRoute,
  })  : _getAllRoutes = getAllRoutes,
        _getRoute = getRoute,
        _saveRoute = saveRoute,
        _deleteRoute = deleteRoute,
        super(const RouteInitial()) {
    on<LoadRoutes>(_onLoadRoutes);
    on<LoadRoute>(_onLoadRoute);
    on<SaveRoute>(_onSaveRoute);
    on<DeleteRoute>(_onDeleteRoute);
  }

  Future<void> _onLoadRoutes(
      LoadRoutes event, Emitter<RouteState> emit) async {
    emit(const RouteLoading());
    try {
      final routes = await _getAllRoutes();
      emit(RoutesLoaded(routes));
    } catch (e) {
      emit(RouteError(e.toString()));
    }
  }

  Future<void> _onLoadRoute(
      LoadRoute event, Emitter<RouteState> emit) async {
    emit(const RouteLoading());
    try {
      final route = await _getRoute(event.id);
      if (route != null) {
        emit(RouteLoaded(route));
      } else {
        emit(const RouteError('Route not found.'));
      }
    } catch (e) {
      emit(RouteError(e.toString()));
    }
  }

  Future<void> _onSaveRoute(
      SaveRoute event, Emitter<RouteState> emit) async {
    emit(const RouteLoading());
    try {
      await _saveRoute(event.route);
      emit(RouteSaved(event.route));
    } catch (e) {
      emit(RouteError(e.toString()));
    }
  }

  Future<void> _onDeleteRoute(
      DeleteRoute event, Emitter<RouteState> emit) async {
    emit(const RouteLoading());
    try {
      await _deleteRoute(event.routeId);
      emit(RouteDeleted(event.routeId));
    } catch (e) {
      emit(RouteError(e.toString()));
    }
  }
}
