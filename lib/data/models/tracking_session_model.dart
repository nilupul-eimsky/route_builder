import '../../domain/entities/tracking_session_entity.dart';
import 'gps_point_model.dart';
import 'route_stop_model.dart';

class TrackingSessionModel extends TrackingSessionEntity {
  const TrackingSessionModel({
    required super.id,
    required super.routeId,
    required super.startedAt,
    super.endedAt,
    required super.status,
    required super.totalDistanceMeters,
    required super.points,
    super.stops = const [],
  });

  factory TrackingSessionModel.fromEntity(TrackingSessionEntity entity) {
    return TrackingSessionModel(
      id: entity.id,
      routeId: entity.routeId,
      startedAt: entity.startedAt,
      endedAt: entity.endedAt,
      status: entity.status,
      totalDistanceMeters: entity.totalDistanceMeters,
      points: entity.points
          .map((p) => GpsPointModel.fromEntity(p))
          .toList(),
      stops: entity.stops
          .map((s) => RouteStopModel.fromEntity(s))
          .toList(),
    );
  }

  factory TrackingSessionModel.fromJson(Map<String, dynamic> json) {
    final pointsList = (json['points'] as List<dynamic>)
        .map((p) => GpsPointModel.fromJson(p as Map<String, dynamic>))
        .toList();

    final stopsList = (json['stops'] as List<dynamic>? ?? [])
        .map((s) => RouteStopModel.fromJson(s as Map<String, dynamic>))
        .toList();

    return TrackingSessionModel(
      id: json['id'] as String,
      routeId: json['routeId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      status: TrackingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TrackingStatus.completed,
      ),
      totalDistanceMeters: (json['totalDistanceMeters'] as num).toDouble(),
      points: pointsList,
      stops: stopsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routeId': routeId,
      'startedAt': startedAt.toUtc().toIso8601String(),
      'endedAt': endedAt?.toUtc().toIso8601String(),
      'status': status.name,
      'totalDistanceMeters': totalDistanceMeters,
      'points': points
          .map((p) => GpsPointModel.fromEntity(p).toJson())
          .toList(),
      'stops': stops
          .map((s) => RouteStopModel.fromEntity(s).toJson())
          .toList(),
    };
  }
}
