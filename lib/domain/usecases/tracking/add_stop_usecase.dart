import '../../entities/route_stop_entity.dart';
import '../../entities/tracking_session_entity.dart';
import '../../repositories/tracking_repository.dart';

class AddStopUseCase {
  final TrackingRepository _repository;

  AddStopUseCase(this._repository);

  Future<TrackingSessionEntity> call(
    TrackingSessionEntity session,
    RouteStopEntity stop,
  ) async {
    final updatedStops = List<RouteStopEntity>.from(session.stops)..add(stop);
    final updatedSession = session.copyWith(stops: updatedStops);

    // Persist BEFORE updating UI state
    await _repository.saveSession(updatedSession);
    return updatedSession;
  }
}
