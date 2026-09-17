import 'package:equatable/equatable.dart';
import 'coordinate_entity.dart';

class RouteEntity extends Equatable {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<CoordinateEntity> coordinates;

  const RouteEntity({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.coordinates,
  });

  @override
  List<Object?> get props => [id, name, createdAt, coordinates];

  RouteEntity copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    List<CoordinateEntity>? coordinates,
  }) {
    return RouteEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      coordinates: coordinates ?? this.coordinates,
    );
  }

  @override
  String toString() =>
      'RouteEntity(id: $id, name: $name, points: ${coordinates.length})';
}
