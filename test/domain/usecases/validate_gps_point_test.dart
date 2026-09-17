import 'package:flutter_test/flutter_test.dart';
import 'package:route_builder/domain/entities/gps_point_entity.dart';
import 'package:route_builder/domain/usecases/tracking/validate_gps_point_usecase.dart';

void main() {
  late ValidateGpsPointUseCase validateGpsPoint;

  setUp(() {
    validateGpsPoint = ValidateGpsPointUseCase();
  });

  // A GPS point near London
  GpsPointEntity makePoint({
    double lat = 51.5074,
    double lng = -0.1278,
    double accuracy = 10.0,
    double speed = 1.5,
  }) {
    return GpsPointEntity(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now().toUtc(),
      accuracy: accuracy,
      speed: speed,
    );
  }

  group('ValidateGpsPointUseCase', () {
    test('rejects point when accuracy > 50m', () {
      final result = validateGpsPoint(
        newLatitude: 51.5074,
        newLongitude: -0.1278,
        accuracy: 51.0, // > 50m
        lastStoredPoint: null,
        lastRecordedTime: null,
        intervalSeconds: 5,
      );
      expect(result, isFalse);
    });

    test('rejects point when accuracy is exactly 50m boundary exceeded', () {
      final result = validateGpsPoint(
        newLatitude: 51.5074,
        newLongitude: -0.1278,
        accuracy: 50.1,
        lastStoredPoint: null,
        lastRecordedTime: null,
        intervalSeconds: 5,
      );
      expect(result, isFalse);
    });

    test('accepts first point (no last point) with good accuracy', () {
      final result = validateGpsPoint(
        newLatitude: 51.5074,
        newLongitude: -0.1278,
        accuracy: 10.0,
        lastStoredPoint: null,
        lastRecordedTime: null,
        intervalSeconds: 5,
      );
      expect(result, isTrue);
    });

    test('rejects point when interval has not elapsed', () {
      final lastPoint = makePoint();
      final recentTime = DateTime.now().toUtc().subtract(
            const Duration(seconds: 3), // 3s < 5s interval
          );

      final result = validateGpsPoint(
        newLatitude: 51.5200, // far enough away (>5m)
        newLongitude: -0.1000,
        accuracy: 10.0,
        lastStoredPoint: lastPoint,
        lastRecordedTime: recentTime,
        intervalSeconds: 5,
      );
      expect(result, isFalse);
    });

    test('rejects point when movement is less than 5m', () {
      final lastPoint = makePoint(lat: 51.5074, lng: -0.1278);
      final oldTime = DateTime.now().toUtc().subtract(
            const Duration(seconds: 10), // enough time elapsed
          );

      // Very close point - essentially same location
      final result = validateGpsPoint(
        newLatitude: 51.5074, // same lat
        newLongitude: -0.1278, // same lng (< 5m movement)
        accuracy: 10.0,
        lastStoredPoint: lastPoint,
        lastRecordedTime: oldTime,
        intervalSeconds: 5,
      );
      expect(result, isFalse);
    });

    test('accepts point when all conditions are met', () {
      final lastPoint = makePoint(lat: 51.5074, lng: -0.1278);
      final oldTime = DateTime.now().toUtc().subtract(
            const Duration(seconds: 10), // 10s > 5s interval
          );

      final result = validateGpsPoint(
        newLatitude: 51.5084, // ~111m north (> 5m movement)
        newLongitude: -0.1278,
        accuracy: 10.0, // < 50m
        lastStoredPoint: lastPoint,
        lastRecordedTime: oldTime,
        intervalSeconds: 5,
      );
      expect(result, isTrue);
    });

    test('rejects point with poor accuracy even if interval and movement are fine', () {
      final lastPoint = makePoint(lat: 51.5074, lng: -0.1278);
      final oldTime = DateTime.now().toUtc().subtract(
            const Duration(seconds: 10),
          );

      final result = validateGpsPoint(
        newLatitude: 51.5200,
        newLongitude: -0.1000,
        accuracy: 100.0, // > 50m
        lastStoredPoint: lastPoint,
        lastRecordedTime: oldTime,
        intervalSeconds: 5,
      );
      expect(result, isFalse);
    });

    test('accepts point with exactly 50m accuracy', () {
      // The condition is accuracy > maxAccuracy, so exactly 50 should pass
      final result = validateGpsPoint(
        newLatitude: 51.5074,
        newLongitude: -0.1278,
        accuracy: 50.0,
        lastStoredPoint: null,
        lastRecordedTime: null,
        intervalSeconds: 5,
      );
      expect(result, isTrue);
    });

    test('rejects when interval not elapsed even with large movement', () {
      final lastPoint = makePoint(lat: 51.5074, lng: -0.1278);
      final veryRecentTime = DateTime.now().toUtc().subtract(
            const Duration(seconds: 1), // only 1s has passed
          );

      final result = validateGpsPoint(
        newLatitude: 52.0, // huge movement
        newLongitude: -0.1278,
        accuracy: 5.0,
        lastStoredPoint: lastPoint,
        lastRecordedTime: veryRecentTime,
        intervalSeconds: 5,
      );
      expect(result, isFalse);
    });
  });
}
