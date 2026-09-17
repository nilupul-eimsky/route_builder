import 'package:equatable/equatable.dart';
import '../../../domain/entities/coordinate_entity.dart';

class RouteCreationState extends Equatable {
  final CoordinateEntity? selectedPoint;
  final List<CoordinateEntity> routePoints;
  final String routeName;
  final bool isSaving;
  final String? error;

  const RouteCreationState({
    this.selectedPoint,
    this.routePoints = const [],
    this.routeName = '',
    this.isSaving = false,
    this.error,
  });

  RouteCreationState copyWith({
    CoordinateEntity? selectedPoint,
    bool clearSelectedPoint = false,
    List<CoordinateEntity>? routePoints,
    String? routeName,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return RouteCreationState(
      selectedPoint:
          clearSelectedPoint ? null : (selectedPoint ?? this.selectedPoint),
      routePoints: routePoints ?? this.routePoints,
      routeName: routeName ?? this.routeName,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        selectedPoint,
        routePoints,
        routeName,
        isSaving,
        error,
      ];
}
