import '../../domain/entities/route_entity.dart';
import 'coordinate_model.dart';

class RouteModel extends RouteEntity {
  const RouteModel({
    required super.id,
    required super.name,
    required super.createdAt,
    required super.coordinates,
  });

  factory RouteModel.fromEntity(RouteEntity entity) {
    return RouteModel(
      id: entity.id,
      name: entity.name,
      createdAt: entity.createdAt,
      coordinates: entity.coordinates
          .map((c) => CoordinateModel.fromEntity(c))
          .toList(),
    );
  }

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    final coordsList = (json['coordinates'] as List<dynamic>)
        .map((c) => CoordinateModel.fromJson(c as Map<String, dynamic>))
        .toList();
    return RouteModel(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      coordinates: coordsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'coordinates': coordinates
          .map((c) => CoordinateModel.fromEntity(c).toJson())
          .toList(),
    };
  }
}
