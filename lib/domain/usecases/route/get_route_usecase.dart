import '../../entities/route_entity.dart';
import '../../repositories/route_repository.dart';

class GetRouteUseCase {
  final RouteRepository _repository;

  GetRouteUseCase(this._repository);

  Future<RouteEntity?> call(String id) async {
    return _repository.getRoute(id);
  }
}
