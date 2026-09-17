import '../../../core/constants/app_constants.dart';
import '../../../core/utils/distance_calculator.dart';
import '../../entities/gps_point_entity.dart';

class ValidateGpsPointUseCase {
  /// Validates whether a new GPS position should be recorded.
  ///
  /// Returns true if the point should be accepted, false if it should be rejected.
  ///
  /// Rejection criteria:
  /// - accuracy > maxAccuracyMeters (50m by default)
  /// - interval since last recorded point has not elapsed
  /// - movement distance from last point < minMovementMeters (configurable, default 100m)
  bool call({
    required double newLatitude,
    required double newLongitude,
    required double accuracy,
    required GpsPointEntity? lastStoredPoint,
    required DateTime? lastRecordedTime,
    required int intervalSeconds,
    double minMovementMeters = AppConstants.minMovementMeters,
  }) {
    // Check accuracy
    if (accuracy > AppConstants.maxAccuracyMeters) {
      return false;
    }

    // If this is the first point, accept it
    if (lastStoredPoint == null || lastRecordedTime == null) {
      return true;
    }

    // Check interval elapsed
    final now = DateTime.now();
    final elapsed = now.difference(lastRecordedTime).inSeconds;
    if (elapsed < intervalSeconds) {
      return false;
    }

    // Check minimum movement
    final distance = DistanceCalculator.betweenLatLng(
      lastStoredPoint.latitude,
      lastStoredPoint.longitude,
      newLatitude,
      newLongitude,
    );
    if (distance < minMovementMeters) {
      return false;
    }

    return true;
  }
}
