import '../../domain/entities/route_stop_entity.dart';

class RouteStopModel extends RouteStopEntity {
  const RouteStopModel({
    required super.id,
    required super.name,
    required super.latitude,
    required super.longitude,
    required super.recordedAt,
  });

  factory RouteStopModel.fromEntity(RouteStopEntity entity) {
    return RouteStopModel(
      id: entity.id,
      name: entity.name,
      latitude: entity.latitude,
      longitude: entity.longitude,
      recordedAt: entity.recordedAt,
    );
  }

  factory RouteStopModel.fromJson(Map<String, dynamic> json) {
    return RouteStopModel(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'recordedAt': recordedAt.toUtc().toIso8601String(),
    };
  }
}
