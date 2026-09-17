import '../../domain/entities/route_entity.dart';
import '../../domain/repositories/route_repository.dart';
import '../datasources/local/route_local_datasource.dart';
import '../models/route_model.dart';

class RouteRepositoryImpl implements RouteRepository {
  final RouteLocalDatasource _datasource;

  RouteRepositoryImpl(this._datasource);

  @override
  Future<List<RouteEntity>> getAllRoutes() async {
    return _datasource.getAllRoutes();
  }

  @override
  Future<RouteEntity?> getRoute(String id) async {
    return _datasource.getRoute(id);
  }

  @override
  Future<void> saveRoute(RouteEntity route) async {
    final model = RouteModel.fromEntity(route);
    await _datasource.saveRoute(model);
  }

  @override
  Future<void> deleteRoute(String id) async {
    await _datasource.deleteRoute(id);
  }
}
