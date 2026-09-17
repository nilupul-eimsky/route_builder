import 'package:uuid/uuid.dart';
import '../../entities/tracking_session_entity.dart';
import '../../repositories/tracking_repository.dart';

class StartTrackingUseCase {
  final TrackingRepository _repository;
  final Uuid _uuid;

  StartTrackingUseCase(this._repository, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  Future<TrackingSessionEntity> call(String routeId) async {
    final session = TrackingSessionEntity(
      id: _uuid.v4(),
      routeId: routeId,
      startedAt: DateTime.now().toUtc(),
      endedAt: null,
      status: TrackingStatus.tracking,
      totalDistanceMeters: 0.0,
      points: const [],
    );
    await _repository.saveSession(session);
    return session;
  }
}
