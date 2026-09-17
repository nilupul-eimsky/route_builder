import '../../domain/entities/tracking_session_entity.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../datasources/local/tracking_local_datasource.dart';
import '../models/tracking_session_model.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  final TrackingLocalDatasource _datasource;

  TrackingRepositoryImpl(this._datasource);

  @override
  Future<List<TrackingSessionEntity>> getSessionsForRoute(
      String routeId) async {
    return _datasource.getSessionsForRoute(routeId);
  }

  @override
  Future<TrackingSessionEntity?> getSession(String id) async {
    return _datasource.getSession(id);
  }

  @override
  Future<void> saveSession(TrackingSessionEntity session) async {
    final model = TrackingSessionModel.fromEntity(session);
    await _datasource.saveSession(model);
  }

  @override
  Future<void> deleteSessionsForRoute(String routeId) async {
    await _datasource.deleteSessionsForRoute(routeId);
  }

  @override
  Future<TrackingSessionEntity?> getUnfinishedSession() async {
    return _datasource.getUnfinishedSession();
  }
}
