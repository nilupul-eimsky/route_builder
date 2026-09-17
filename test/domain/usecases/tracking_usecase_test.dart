import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:route_builder/domain/entities/tracking_session_entity.dart';
import 'package:route_builder/domain/repositories/tracking_repository.dart';
import 'package:route_builder/domain/usecases/tracking/pause_tracking_usecase.dart';
import 'package:route_builder/domain/usecases/tracking/resume_tracking_usecase.dart';
import 'package:route_builder/domain/usecases/tracking/start_tracking_usecase.dart';
import 'package:route_builder/domain/usecases/tracking/stop_tracking_usecase.dart';

class MockTrackingRepository extends Mock implements TrackingRepository {}

class FakeTrackingSession extends Fake implements TrackingSessionEntity {}

void main() {
  late MockTrackingRepository mockRepo;
  late StartTrackingUseCase startTracking;
  late StopTrackingUseCase stopTracking;
  late PauseTrackingUseCase pauseTracking;
  late ResumeTrackingUseCase resumeTracking;

  setUpAll(() {
    registerFallbackValue(FakeTrackingSession());
  });

  setUp(() {
    mockRepo = MockTrackingRepository();
    startTracking = StartTrackingUseCase(mockRepo);
    stopTracking = StopTrackingUseCase(mockRepo);
    pauseTracking = PauseTrackingUseCase(mockRepo);
    resumeTracking = ResumeTrackingUseCase(mockRepo);
  });

  TrackingSessionEntity makeSession({
    TrackingStatus status = TrackingStatus.tracking,
    DateTime? startedAt,
  }) {
    return TrackingSessionEntity(
      id: 'session-001',
      routeId: 'route-001',
      startedAt: startedAt ?? DateTime.utc(2024, 1, 1, 10, 0, 0),
      endedAt: null,
      status: status,
      totalDistanceMeters: 0.0,
      points: const [],
    );
  }

  group('StartTrackingUseCase', () {
    test('creates a session with status=tracking', () async {
      when(() => mockRepo.saveSession(any())).thenAnswer((_) async {});

      final session = await startTracking('route-001');

      expect(session.status, equals(TrackingStatus.tracking));
      expect(session.routeId, equals('route-001'));
      expect(session.endedAt, isNull);
      expect(session.points, isEmpty);
      expect(session.totalDistanceMeters, equals(0.0));
    });

    test('persists the session to the repository', () async {
      when(() => mockRepo.saveSession(any())).thenAnswer((_) async {});

      await startTracking('route-001');

      verify(() => mockRepo.saveSession(any())).called(1);
    });

    test('generates a unique session id', () async {
      when(() => mockRepo.saveSession(any())).thenAnswer((_) async {});

      final s1 = await startTracking('route-001');
      final s2 = await startTracking('route-001');

      expect(s1.id, isNot(equals(s2.id)));
    });
  });

  group('PauseTrackingUseCase', () {
    test('changes status to paused', () async {
      final session = makeSession(status: TrackingStatus.tracking);
      when(() => mockRepo.saveSession(any())).thenAnswer((_) async {});

      final paused = await pauseTracking(session);

      expect(paused.status, equals(TrackingStatus.paused));
    });

    test('persists the paused session', () async {
      final session = makeSession(status: TrackingStatus.tracking);
      when(() => mockRepo.saveSession(any())).thenAnswer((_) async {});

      await pauseTracking(session);

      verify(() => mockRepo.saveSession(any())).called(1);
    });

    test('retains the session id after pausing', () async {
      final session = makeSession(status: TrackingStatus.tracking);
      when(() => mockRepo.saveSession(any())).thenAnswer((_) async {});

      final paused = await pauseTracking(session);

      expect(paused.id, equals(session.id));
    });
  });

  group('ResumeTrackingUseCase', () {
    test('changes status to tracking', () async {
      final session = makeSession(status: TrackingStatus.paused);
      when(() => mockRepo.saveSession(any())).thenAnswer((_) async {});

      final resumed = await resumeTracking(session);

      expect(resumed.status, equals(TrackingStatus.tracking));
    });

    test('persists the resumed session', () async {
      final session = makeSession(status: TrackingStatus.paused);
      when(() => mockRepo.saveSession(any())).thenAnswer((_) async {});

      await resumeTracking(session);

      verify(() => mockRepo.saveSession(any())).called(1);
    });
  });

  group('StopTrackingUseCase', () {
    test('changes status to completed', () async {
      final session = makeSession(status: TrackingStatus.tracking);
      when(() => mockRepo.saveSession(any())).thenAnswer((_) async {});

      final completed = await stopTracking(session);

      expect(completed.status, equals(TrackingStatus.completed));
    });

    test('sets endedAt timestamp', () async {
      final session = makeSession(status: TrackingStatus.tracking);
      when(() => mockRepo.saveSession(any())).thenAnswer((_) async {});

      final completed = await stopTracking(session);

      expect(completed.endedAt, isNotNull);
      expect(
        completed.endedAt!.difference(DateTime.now().toUtc()).abs().inSeconds,
        lessThan(5),
      );
    });

    test('persists the completed session', () async {
      final session = makeSession(status: TrackingStatus.tracking);
      when(() => mockRepo.saveSession(any())).thenAnswer((_) async {});

      await stopTracking(session);

      verify(() => mockRepo.saveSession(any())).called(1);
    });

    test('full lifecycle: start -> pause -> resume -> stop', () async {
      when(() => mockRepo.saveSession(any())).thenAnswer((_) async {});

      // Start
      final started = await startTracking('route-001');
      expect(started.status, equals(TrackingStatus.tracking));

      // Pause
      final paused = await pauseTracking(started);
      expect(paused.status, equals(TrackingStatus.paused));

      // Resume
      final resumed = await resumeTracking(paused);
      expect(resumed.status, equals(TrackingStatus.tracking));

      // Stop
      final completed = await stopTracking(resumed);
      expect(completed.status, equals(TrackingStatus.completed));
      expect(completed.endedAt, isNotNull);
    });
  });
}
