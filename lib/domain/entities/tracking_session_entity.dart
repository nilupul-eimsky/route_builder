import 'package:equatable/equatable.dart';
import 'gps_point_entity.dart';
import 'route_stop_entity.dart';

enum TrackingStatus { tracking, paused, completed }

class TrackingSessionEntity extends Equatable {
  final String id;
  final String routeId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final TrackingStatus status;
  final double totalDistanceMeters;
  final List<GpsPointEntity> points;
  final List<RouteStopEntity> stops;

  const TrackingSessionEntity({
    required this.id,
    required this.routeId,
    required this.startedAt,
    this.endedAt,
    required this.status,
    required this.totalDistanceMeters,
    required this.points,
    this.stops = const [],
  });

  @override
  List<Object?> get props => [
        id,
        routeId,
        startedAt,
        endedAt,
        status,
        totalDistanceMeters,
        points,
        stops,
      ];

  TrackingSessionEntity copyWith({
    String? id,
    String? routeId,
    DateTime? startedAt,
    DateTime? endedAt,
    TrackingStatus? status,
    double? totalDistanceMeters,
    List<GpsPointEntity>? points,
    List<RouteStopEntity>? stops,
  }) {
    return TrackingSessionEntity(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      points: points ?? this.points,
      stops: stops ?? this.stops,
    );
  }

  Duration get duration {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  double get averageSpeedMs {
    if (points.isEmpty) return 0.0;
    final validSpeeds = points.where((p) => p.speed >= 0).toList();
    if (validSpeeds.isEmpty) return 0.0;
    final sum = validSpeeds.fold(0.0, (acc, p) => acc + p.speed);
    return sum / validSpeeds.length;
  }

  @override
  String toString() =>
      'TrackingSessionEntity(id: $id, routeId: $routeId, status: $status, points: ${points.length})';
}
