import '../../entities/tracking_session_entity.dart';
import '../../repositories/tracking_repository.dart';

class PauseTrackingUseCase {
  final TrackingRepository _repository;

  PauseTrackingUseCase(this._repository);

  Future<TrackingSessionEntity> call(TrackingSessionEntity session) async {
    final paused = session.copyWith(status: TrackingStatus.paused);
    await _repository.saveSession(paused);
    return paused;
  }
}
