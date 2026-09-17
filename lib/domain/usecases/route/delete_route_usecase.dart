import '../../repositories/route_repository.dart';
import '../../repositories/tracking_repository.dart';

class DeleteRouteUseCase {
  final RouteRepository _routeRepository;
  final TrackingRepository _trackingRepository;

  DeleteRouteUseCase(this._routeRepository, this._trackingRepository);

  Future<void> call(String routeId) async {
    // Delete associated tracking sessions first
    await _trackingRepository.deleteSessionsForRoute(routeId);
    // Then delete the route
    await _routeRepository.deleteRoute(routeId);
  }
}
