import '../../entities/tracking_session_entity.dart';
import '../../repositories/tracking_repository.dart';

class ResumeTrackingUseCase {
  final TrackingRepository _repository;

  ResumeTrackingUseCase(this._repository);

  Future<TrackingSessionEntity> call(TrackingSessionEntity session) async {
    final resumed = session.copyWith(status: TrackingStatus.tracking);
    await _repository.saveSession(resumed);
    return resumed;
  }
}
