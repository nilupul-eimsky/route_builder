import '../../domain/entities/coordinate_entity.dart';

class CoordinateModel extends CoordinateEntity {
  const CoordinateModel({
    required super.latitude,
    required super.longitude,
  });

  factory CoordinateModel.fromEntity(CoordinateEntity entity) {
    return CoordinateModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
    );
  }

  factory CoordinateModel.fromJson(Map<String, dynamic> json) {
    return CoordinateModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
