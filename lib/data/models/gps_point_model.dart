import '../../domain/entities/gps_point_entity.dart';

class GpsPointModel extends GpsPointEntity {
  const GpsPointModel({
    required super.latitude,
    required super.longitude,
    required super.timestamp,
    required super.accuracy,
    required super.speed,
    super.altitude,
  });

  factory GpsPointModel.fromEntity(GpsPointEntity entity) {
    return GpsPointModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      timestamp: entity.timestamp,
      accuracy: entity.accuracy,
      speed: entity.speed,
      altitude: entity.altitude,
    );
  }

  factory GpsPointModel.fromJson(Map<String, dynamic> json) {
    return GpsPointModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      accuracy: (json['accuracy'] as num).toDouble(),
      speed: (json['speed'] as num).toDouble(),
      altitude: json['altitude'] != null
          ? (json['altitude'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'accuracy': accuracy,
      'speed': speed,
      if (altitude != null) 'altitude': altitude,
    };
  }
}
