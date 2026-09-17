import '../../entities/route_entity.dart';
import '../../repositories/route_repository.dart';

class GetAllRoutesUseCase {
  final RouteRepository _repository;

  GetAllRoutesUseCase(this._repository);

  Future<List<RouteEntity>> call() async {
    final routes = await _repository.getAllRoutes();
    // Sort by creation date descending (newest first)
    routes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return routes;
  }
}
