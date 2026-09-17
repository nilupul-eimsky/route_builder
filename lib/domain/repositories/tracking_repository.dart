import '../entities/tracking_session_entity.dart';

abstract class TrackingRepository {
  Future<List<TrackingSessionEntity>> getSessionsForRoute(String routeId);
  Future<TrackingSessionEntity?> getSession(String id);
  Future<void> saveSession(TrackingSessionEntity session);
  Future<void> deleteSessionsForRoute(String routeId);
  Future<TrackingSessionEntity?> getUnfinishedSession();
}
