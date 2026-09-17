import 'package:flutter_test/flutter_test.dart';
import 'package:route_builder/core/utils/distance_calculator.dart';
import 'package:route_builder/domain/entities/coordinate_entity.dart';

void main() {
  group('DistanceCalculator', () {
    group('betweenCoordinates', () {
      test('returns approximately 0 for same location', () {
        const coord = CoordinateEntity(latitude: 51.5074, longitude: -0.1278);
        final dist = DistanceCalculator.betweenCoordinates(coord, coord);
        expect(dist, closeTo(0.0, 0.001));
      });

      test('calculates distance between London and Paris correctly (~344 km)', () {
        const london = CoordinateEntity(latitude: 51.5074, longitude: -0.1278);
        const paris = CoordinateEntity(latitude: 48.8566, longitude: 2.3522);
        final dist = DistanceCalculator.betweenCoordinates(london, paris);
        // London to Paris is approximately 344 km, allow 5% tolerance
        expect(dist, greaterThan(340000));
        expect(dist, lessThan(360000));
      });

      test('is symmetric (A->B == B->A)', () {
        const a = CoordinateEntity(latitude: 51.5074, longitude: -0.1278);
        const b = CoordinateEntity(latitude: 48.8566, longitude: 2.3522);
        final d1 = DistanceCalculator.betweenCoordinates(a, b);
        final d2 = DistanceCalculator.betweenCoordinates(b, a);
        expect(d1, closeTo(d2, 0.001));
      });
    });

    group('totalDistance', () {
      test('returns 0 for empty list', () {
        final dist = DistanceCalculator.totalDistance([]);
        expect(dist, equals(0.0));
      });

      test('returns 0 for single coordinate', () {
        final dist = DistanceCalculator.totalDistance([
          const CoordinateEntity(latitude: 51.5074, longitude: -0.1278),
        ]);
        expect(dist, equals(0.0));
      });

      test('returns correct total for two coordinates', () {
        const london = CoordinateEntity(latitude: 51.5074, longitude: -0.1278);
        const paris = CoordinateEntity(latitude: 48.8566, longitude: 2.3522);
        final dist = DistanceCalculator.totalDistance([london, paris]);
        // Should be ~344 km
        expect(dist, greaterThan(340000));
        expect(dist, lessThan(360000));
      });

      test('sums distances along a multi-segment path', () {
        const london = CoordinateEntity(latitude: 51.5074, longitude: -0.1278);
        const paris = CoordinateEntity(latitude: 48.8566, longitude: 2.3522);
        const berlin = CoordinateEntity(latitude: 52.5200, longitude: 13.4050);

        final totalDist =
            DistanceCalculator.totalDistance([london, paris, berlin]);
        final londonParis = DistanceCalculator.betweenCoordinates(london, paris);
        final parisBerlin = DistanceCalculator.betweenCoordinates(paris, berlin);

        expect(totalDist, closeTo(londonParis + parisBerlin, 0.001));
      });

      test('total is greater than single segment for triangular path', () {
        const a = CoordinateEntity(latitude: 51.5, longitude: -0.1);
        const b = CoordinateEntity(latitude: 51.6, longitude: -0.1);
        const c = CoordinateEntity(latitude: 51.6, longitude: 0.0);

        final total = DistanceCalculator.totalDistance([a, b, c]);
        final direct = DistanceCalculator.betweenCoordinates(a, c);
        expect(total, greaterThan(direct));
      });
    });

    group('formatDistance', () {
      test('formats meters when < 1000m', () {
        expect(DistanceCalculator.formatDistance(234.0), equals('234 m'));
      });

      test('formats km when >= 1000m', () {
        expect(DistanceCalculator.formatDistance(1500.0), equals('1.5 km'));
      });

      test('formats exactly 1000m as 1.0 km', () {
        expect(DistanceCalculator.formatDistance(1000.0), equals('1.0 km'));
      });

      test('formats 0 as 0 m', () {
        expect(DistanceCalculator.formatDistance(0.0), equals('0 m'));
      });

      test('formats 12345m as 12.3 km', () {
        expect(DistanceCalculator.formatDistance(12345.0), equals('12.3 km'));
      });
    });

    group('betweenLatLng', () {
      test('returns approximately 0 for same coordinates', () {
        final dist = DistanceCalculator.betweenLatLng(
            51.5074, -0.1278, 51.5074, -0.1278);
        expect(dist, closeTo(0.0, 0.001));
      });

      test('matches betweenCoordinates for the same points', () {
        const a = CoordinateEntity(latitude: 51.5074, longitude: -0.1278);
        const b = CoordinateEntity(latitude: 48.8566, longitude: 2.3522);
        final fromLatLng = DistanceCalculator.betweenLatLng(
            a.latitude, a.longitude, b.latitude, b.longitude);
        final fromCoord = DistanceCalculator.betweenCoordinates(a, b);
        expect(fromLatLng, closeTo(fromCoord, 0.001));
      });
    });
  });
}
