import '../../../core/errors/failures.dart';
import '../../entities/route_entity.dart';
import '../../repositories/route_repository.dart';

class SaveRouteUseCase {
  final RouteRepository _repository;

  SaveRouteUseCase(this._repository);

  Future<void> call(RouteEntity route) async {
    if (route.name.trim().isEmpty) {
      throw const ValidationFailure('Route name cannot be empty.');
    }
    await _repository.saveRoute(route);
  }
}
