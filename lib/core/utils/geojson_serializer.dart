import 'dart:convert';
import '../../domain/entities/route_entity.dart';
import '../../domain/entities/route_stop_entity.dart';
import '../../domain/entities/tracking_session_entity.dart';

class GeoJsonSerializer {
  /// Serialize a RouteEntity to a GeoJSON Feature (LineString).
  /// IMPORTANT: GeoJSON coordinates are [longitude, latitude].
  static Map<String, dynamic> routeToFeature(RouteEntity route) {
    final coordinates = route.coordinates
        .map((c) => [c.longitude, c.latitude])
        .toList();

    return {
      'type': 'Feature',
      'properties': {
        'id': route.id,
        'name': route.name,
        'createdAt': route.createdAt.toUtc().toIso8601String(),
        'pointCount': route.coordinates.length,
      },
      'geometry': {
        'type': 'LineString',
        'coordinates': coordinates,
      },
    };
  }

  /// Serialize a TrackingSessionEntity to a GeoJSON Feature (LineString).
  static Map<String, dynamic> sessionToFeature(TrackingSessionEntity session) {
    final coordinates = session.points
        .map((p) => [p.longitude, p.latitude])
        .toList();

    return {
      'type': 'Feature',
      'properties': {
        'id': session.id,
        'routeId': session.routeId,
        'startedAt': session.startedAt.toUtc().toIso8601String(),
        'endedAt': session.endedAt?.toUtc().toIso8601String(),
        'status': session.status.name,
        'totalDistanceMeters': session.totalDistanceMeters,
        'pointCount': session.points.length,
        'stopCount': session.stops.length,
      },
      'geometry': {
        'type': 'LineString',
        'coordinates': coordinates,
      },
    };
  }

  /// Serialize a RouteStopEntity to a GeoJSON Feature (Point).
  static Map<String, dynamic> stopToFeature(RouteStopEntity stop) {
    return {
      'type': 'Feature',
      'properties': {
        'type': 'stop',
        'id': stop.id,
        'name': stop.name,
        'recordedAt': stop.recordedAt.toUtc().toIso8601String(),
      },
      'geometry': {
        'type': 'Point',
        'coordinates': [stop.longitude, stop.latitude],
      },
    };
  }

  /// Serialize a route and its tracking session to a GeoJSON FeatureCollection.
  /// Stops are included as individual Point features with type="stop".
  static Map<String, dynamic> toFeatureCollection(
    RouteEntity route,
    TrackingSessionEntity? session,
  ) {
    final features = <Map<String, dynamic>>[
      routeToFeature(route),
    ];
    if (session != null) {
      features.add(sessionToFeature(session));
      for (final stop in session.stops) {
        features.add(stopToFeature(stop));
      }
    }
    return {
      'type': 'FeatureCollection',
      'features': features,
    };
  }

  /// Convert a map to pretty-printed JSON string.
  static String toPrettyJson(Map<String, dynamic> data) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  /// Convert a RouteEntity to pretty GeoJSON string.
  static String routeToGeoJsonString(RouteEntity route) {
    return toPrettyJson(routeToFeature(route));
  }

  /// Convert route + session to pretty GeoJSON string.
  static String toFeatureCollectionString(
    RouteEntity route,
    TrackingSessionEntity? session,
  ) {
    return toPrettyJson(toFeatureCollection(route, session));
  }
}
