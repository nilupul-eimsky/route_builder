import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/coordinate_entity.dart';
import '../../../domain/entities/route_entity.dart';
import '../../../domain/usecases/route/save_route_usecase.dart';
import 'route_creation_state.dart';

class RouteCreationCubit extends Cubit<RouteCreationState> {
  final SaveRouteUseCase _saveRouteUseCase;
  final Uuid _uuid;

  RouteCreationCubit({
    required SaveRouteUseCase saveRouteUseCase,
    Uuid? uuid,
  })  : _saveRouteUseCase = saveRouteUseCase,
        _uuid = uuid ?? const Uuid(),
        super(const RouteCreationState());

  void selectPoint(CoordinateEntity coordinate) {
    emit(state.copyWith(selectedPoint: coordinate, clearError: true));
  }

  void addPoint(CoordinateEntity coordinate) {
    final updatedPoints = List<CoordinateEntity>.from(state.routePoints)
      ..add(coordinate);
    emit(state.copyWith(
      routePoints: updatedPoints,
      clearSelectedPoint: true,
      clearError: true,
    ));
  }

  void addSelectedPoint() {
    final point = state.selectedPoint;
    if (point != null) {
      addPoint(point);
    }
  }

  void undoLast() {
    if (state.routePoints.isEmpty) return;
    final updatedPoints = List<CoordinateEntity>.from(state.routePoints)
      ..removeLast();
    emit(state.copyWith(routePoints: updatedPoints, clearError: true));
  }

  void clearAll() {
    emit(const RouteCreationState());
  }

  void setRouteName(String name) {
    emit(state.copyWith(routeName: name, clearError: true));
  }

  Future<RouteEntity?> saveRoute() async {
    emit(state.copyWith(isSaving: true, clearError: true));

    try {
      final route = RouteEntity(
        id: _uuid.v4(),
        name: state.routeName.trim(),
        createdAt: DateTime.now().toUtc(),
        coordinates: List.from(state.routePoints),
      );

      await _saveRouteUseCase(route);
      emit(state.copyWith(isSaving: false));
      return route;
    } on ValidationFailure catch (e) {
      emit(state.copyWith(isSaving: false, error: e.message));
      return null;
    } catch (e) {
      emit(state.copyWith(
          isSaving: false, error: 'Failed to save route: ${e.toString()}'));
      return null;
    }
  }
}
