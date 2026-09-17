import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_builder/core/utils/geojson_serializer.dart';
import 'package:route_builder/domain/entities/coordinate_entity.dart';
import 'package:route_builder/domain/entities/route_entity.dart';

void main() {
  final tRoute = RouteEntity(
    id: 'route-001',
    name: 'Test Route',
    createdAt: DateTime.utc(2024, 6, 15, 10, 0, 0),
    coordinates: const [
      CoordinateEntity(latitude: 51.5074, longitude: -0.1278), // London
      CoordinateEntity(latitude: 48.8566, longitude: 2.3522),   // Paris
      CoordinateEntity(latitude: 52.5200, longitude: 13.4050),  // Berlin
    ],
  );

  group('GeoJsonSerializer.routeToFeature', () {
    test('produces a Feature with type Feature', () {
      final feature = GeoJsonSerializer.routeToFeature(tRoute);
      expect(feature['type'], equals('Feature'));
    });

    test('geometry type is LineString', () {
      final feature = GeoJsonSerializer.routeToFeature(tRoute);
      final geometry = feature['geometry'] as Map<String, dynamic>;
      expect(geometry['type'], equals('LineString'));
    });

    test('GeoJSON coordinates are [longitude, latitude] not [latitude, longitude]', () {
      final feature = GeoJsonSerializer.routeToFeature(tRoute);
      final geometry = feature['geometry'] as Map<String, dynamic>;
      final coords = geometry['coordinates'] as List<dynamic>;

      // First coordinate should be [longitude, latitude] = [-0.1278, 51.5074]
      final first = coords[0] as List<dynamic>;
      expect(first[0], closeTo(-0.1278, 0.0001)); // longitude first
      expect(first[1], closeTo(51.5074, 0.0001)); // latitude second

      // Second coordinate
      final second = coords[1] as List<dynamic>;
      expect(second[0], closeTo(2.3522, 0.0001));  // longitude = Paris lng
      expect(second[1], closeTo(48.8566, 0.0001)); // latitude = Paris lat
    });

    test('has correct number of coordinates', () {
      final feature = GeoJsonSerializer.routeToFeature(tRoute);
      final geometry = feature['geometry'] as Map<String, dynamic>;
      final coords = geometry['coordinates'] as List<dynamic>;
      expect(coords.length, equals(3));
    });

    test('properties contain route id and name', () {
      final feature = GeoJsonSerializer.routeToFeature(tRoute);
      final props = feature['properties'] as Map<String, dynamic>;
      expect(props['id'], equals('route-001'));
      expect(props['name'], equals('Test Route'));
    });

    test('output is valid JSON', () {
      final feature = GeoJsonSerializer.routeToFeature(tRoute);
      final jsonString = jsonEncode(feature);
      expect(() => jsonDecode(jsonString), returnsNormally);
    });
  });

  group('GeoJsonSerializer.routeToGeoJsonString', () {
    test('produces a pretty-printed JSON string', () {
      final json = GeoJsonSerializer.routeToGeoJsonString(tRoute);
      expect(json, isA<String>());
      expect(json.contains('\n'), isTrue,
          reason: 'Should be pretty-printed with newlines');
    });

    test('the JSON string can be decoded', () {
      final json = GeoJsonSerializer.routeToGeoJsonString(tRoute);
      expect(() => jsonDecode(json), returnsNormally);
    });

    test('decoded JSON has correct longitude-first coordinates', () {
      final json = GeoJsonSerializer.routeToGeoJsonString(tRoute);
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final geometry = decoded['geometry'] as Map<String, dynamic>;
      final coords = geometry['coordinates'] as List<dynamic>;
      final first = coords[0] as List<dynamic>;
      // Longitude is first in GeoJSON
      expect((first[0] as num).toDouble(), closeTo(-0.1278, 0.0001));
      expect((first[1] as num).toDouble(), closeTo(51.5074, 0.0001));
    });
  });

  group('GeoJsonSerializer.toFeatureCollection', () {
    test('produces a FeatureCollection with one feature when no session', () {
      final fc = GeoJsonSerializer.toFeatureCollection(tRoute, null);
      expect(fc['type'], equals('FeatureCollection'));
      final features = fc['features'] as List<dynamic>;
      expect(features.length, equals(1));
    });

    test('is valid JSON', () {
      final fc = GeoJsonSerializer.toFeatureCollection(tRoute, null);
      final jsonString = jsonEncode(fc);
      expect(() => jsonDecode(jsonString), returnsNormally);
    });
  });
}
