import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:route_builder/core/errors/failures.dart';
import 'package:route_builder/domain/entities/coordinate_entity.dart';
import 'package:route_builder/domain/entities/route_entity.dart';
import 'package:route_builder/domain/repositories/route_repository.dart';
import 'package:route_builder/domain/usecases/route/save_route_usecase.dart';

class MockRouteRepository extends Mock implements RouteRepository {}

void main() {
  late MockRouteRepository mockRepo;
  late SaveRouteUseCase saveRouteUseCase;

  setUp(() {
    mockRepo = MockRouteRepository();
    saveRouteUseCase = SaveRouteUseCase(mockRepo);
  });

  final tCoordinate1 = const CoordinateEntity(latitude: 1.0, longitude: 2.0);
  final tCoordinate2 = const CoordinateEntity(latitude: 3.0, longitude: 4.0);

  RouteEntity buildRoute({
    String name = 'Test Route',
    List<CoordinateEntity>? coords,
  }) {
    return RouteEntity(
      id: 'test-id',
      name: name,
      createdAt: DateTime.utc(2024, 1, 1),
      coordinates: coords ?? [tCoordinate1, tCoordinate2],
    );
  }

  group('SaveRouteUseCase validation', () {
    test('throws ValidationFailure when name is empty', () async {
      final route = buildRoute(name: '');
      expect(
        () => saveRouteUseCase(route),
        throwsA(isA<ValidationFailure>().having(
          (f) => f.message,
          'message',
          contains('empty'),
        )),
      );
      verifyNever(() => mockRepo.saveRoute(any()));
    });

    test('throws ValidationFailure when name is only whitespace', () async {
      final route = buildRoute(name: '   ');
      expect(
        () => saveRouteUseCase(route),
        throwsA(isA<ValidationFailure>()),
      );
      verifyNever(() => mockRepo.saveRoute(any()));
    });

    test('throws ValidationFailure when fewer than 2 coordinates', () async {
      final route = buildRoute(coords: [tCoordinate1]);
      expect(
        () => saveRouteUseCase(route),
        throwsA(isA<ValidationFailure>().having(
          (f) => f.message,
          'message',
          contains('at least 2'),
        )),
      );
      verifyNever(() => mockRepo.saveRoute(any()));
    });

    test('throws ValidationFailure when coordinates list is empty', () async {
      final route = buildRoute(coords: []);
      expect(
        () => saveRouteUseCase(route),
        throwsA(isA<ValidationFailure>()),
      );
      verifyNever(() => mockRepo.saveRoute(any()));
    });

    test('saves successfully when name and coordinates are valid', () async {
      final route = buildRoute(
        name: 'Valid Route',
        coords: [tCoordinate1, tCoordinate2],
      );
      when(() => mockRepo.saveRoute(route)).thenAnswer((_) async {});

      await expectLater(saveRouteUseCase(route), completes);
      verify(() => mockRepo.saveRoute(route)).called(1);
    });

    test('saves successfully with many coordinates', () async {
      final coords = List.generate(
        10,
        (i) => CoordinateEntity(latitude: i.toDouble(), longitude: i.toDouble()),
      );
      final route = buildRoute(name: 'Long Route', coords: coords);
      when(() => mockRepo.saveRoute(route)).thenAnswer((_) async {});

      await expectLater(saveRouteUseCase(route), completes);
      verify(() => mockRepo.saveRoute(route)).called(1);
    });
  });
}
