import '../../entities/tracking_session_entity.dart';
import '../../repositories/tracking_repository.dart';

class StopTrackingUseCase {
  final TrackingRepository _repository;

  StopTrackingUseCase(this._repository);

  Future<TrackingSessionEntity> call(TrackingSessionEntity session) async {
    final completed = session.copyWith(
      status: TrackingStatus.completed,
      endedAt: DateTime.now().toUtc(),
    );
    await _repository.saveSession(completed);
    return completed;
  }
}
