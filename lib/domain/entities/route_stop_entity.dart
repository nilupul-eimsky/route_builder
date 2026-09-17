import 'package:equatable/equatable.dart';

class RouteStopEntity extends Equatable {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final DateTime recordedAt;

  const RouteStopEntity({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
  });

  @override
  List<Object?> get props => [id, name, latitude, longitude, recordedAt];

  RouteStopEntity copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    DateTime? recordedAt,
  }) {
    return RouteStopEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  @override
  String toString() => 'RouteStopEntity(id: $id, name: $name)';
}
