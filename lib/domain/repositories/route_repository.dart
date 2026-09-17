import '../entities/route_entity.dart';

abstract class RouteRepository {
  Future<List<RouteEntity>> getAllRoutes();
  Future<RouteEntity?> getRoute(String id);
  Future<void> saveRoute(RouteEntity route);
  Future<void> deleteRoute(String id);
}
