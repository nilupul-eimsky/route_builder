import '../../../domain/entities/tracking_session_entity.dart';
import '../../../domain/repositories/tracking_repository.dart';

class GetSessionsForRouteUseCase {
  final TrackingRepository _repository;
  GetSessionsForRouteUseCase(this._repository);

  Future<List<TrackingSessionEntity>> call(String routeId) =>
      _repository.getSessionsForRoute(routeId);
}
