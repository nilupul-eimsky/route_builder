import 'package:geolocator/geolocator.dart';
import '../../domain/entities/coordinate_entity.dart';

class DistanceCalculator {
  /// Returns distance in meters between two coordinates.
  static double betweenCoordinates(
    CoordinateEntity from,
    CoordinateEntity to,
  ) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  /// Returns total distance in meters along a list of coordinates.
  static double totalDistance(List<CoordinateEntity> coordinates) {
    if (coordinates.length < 2) return 0.0;
    double total = 0.0;
    for (int i = 0; i < coordinates.length - 1; i++) {
      total += betweenCoordinates(coordinates[i], coordinates[i + 1]);
    }
    return total;
  }

  /// Returns distance in meters between two lat/lng pairs.
  static double betweenLatLng(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  /// Format distance for display.
  static String formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }
}
